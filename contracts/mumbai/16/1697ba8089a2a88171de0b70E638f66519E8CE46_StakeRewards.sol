// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Deposit.sol";
import "./IStakeRewards.sol";
import "./StakePlanContext.sol";

contract StakeRewards is
    ReentrancyGuard,
    Ownable,
    Pausable,
    StakePlanContext,
    IStakeRewards
{
    /**
     * @dev Emitted when a deposit is created by calling the `stake()` function.
     * @param _beneficiary The caller of the stake function. [indexed]
     * @param _tokenContractAddress ERC20 token used for the deposit. [indexed]
     * @param _depositContractAddress Address of the deposit contract. [indexed]
     * @param _stakePlan The stake plan that will define the stake plan metadata used for the deployed `Deposit`.
     * @param _amount The initial deposit amount.
     */
    event DepositCreated(
        address indexed _beneficiary,
        address indexed _tokenContractAddress,
        address indexed _depositContractAddress,
        StakePlan _stakePlan,
        uint256 _amount,
        bool _autoRestake
    );

    /**
     * @dev The token used for staking. Any new deployed `Deposit` contract will use this token as the staked token.
     */
    IERC20 public token;

    /**
     * @dev Maps the `StakePlan` enum with all the configurable values found in the `StakePlanMetadata`.
     */
    mapping(StakePlan => StakePlanMetadata) public stakePlans;

    /**
     * @dev How much can an account stake for the `PRESALE_ONE_YEAR_PLAN`.
     */
    mapping(address => uint256) public presaleAllowance;

    mapping(address => bool) public isDeposit;

    /**
     * @dev The rate that will compute the burned tokens if the user will unstake.
     * Expressed in basis points: for example 0.40% is 40bp and 100% is 1000bp.
     */
    uint256 public unstakePenaltyRate;

    /**
     * @dev After claiming the user can withdraw the amount after this period.
     */
    uint256 public unstakeCoolingTime;

    /**
     * @dev Manages the presale whitelist.
     */
    address public presaleAdminAddress;

    /**
     * @dev After this date, presale plans can no longer be staked.
     */
    uint256 public presaleCloseTime;

    /**
     * @dev Sets the token address this staking contract operates with. Part of initial contract setup.
     * @dev When changing the token all ongoing deposits will still use the old ERC20 token.
     * @param _tokenAddress address of the ERC20 token. (implements IERC20 interface).
     */
    function setERC20Token(address _tokenAddress)
        external
        onlyOwner
        whenNotPaused
    {
        token = IERC20(_tokenAddress);
    }

    /**
     * @param _presaleCloseTime Unit timestamp that marks the closing of the presale.
     */
    function setPresaleCloseTime(uint256 _presaleCloseTime)
        external
        onlyOwner
        whenNotPaused
    {
        presaleCloseTime = _presaleCloseTime;
    }

    /**
     * @dev Deployer should include this as part of the deployment script. Duration is directly inferred from `StakePlan` type.
     * Owner can later change plans but it won't affect existing `Deposit` contracts.
     * @param _interestRate is expressed in basis points. ex: 0.40% is 40bp. 100% is 1000bp.
     */
    function setStakePlan(StakePlan _stakePlan, uint256 _interestRate)
        external
        onlyOwner
        whenNotPaused
    {
        uint256 _duration;
        if (_stakePlan == StakePlan.THREE_MONTH_PLAN) {
            _duration = THREE_MONTHS;
        } else if (_stakePlan == StakePlan.SIX_MONTH_PLAN) {
            _duration = SIX_MONTHS;
        } else {
            _duration = ONE_YEAR;
        }
        stakePlans[_stakePlan] = StakePlanMetadata(
            _interestRate,
            _duration,
            _stakePlan
        );
    }

    /**
     * @dev This is an owner function used for overriding @param _duration of a specific Stakeplan.
     * Introduced in order to facilitate testing.
     * @param _duration is expressed in seconds.
     */
    function overrideStakePlanDuration(StakePlan _stakePlan, uint256 _duration)
        external
        onlyOwner
        whenNotPaused
    {
        stakePlans[_stakePlan].duration = _duration;
    }

    /**
     * @dev Sets the rate that will compute the burned tokens if the user will unstake.
     */
    function setUnstakePenaltyRate(uint256 _unstakePenaltyRate)
        external
        onlyOwner
        whenNotPaused
    {
        unstakePenaltyRate = _unstakePenaltyRate;
    }

    /**
     * @dev Sets the time after claiming when the user can withdraw the staked amount.
     */
    function setUnstakeCoolingTime(uint256 _unstakeCoolingTime)
        external
        onlyOwner
        whenNotPaused
    {
        unstakeCoolingTime = _unstakeCoolingTime;
    }

    /**
     * @dev Changes the address allowed to whitelist users available for presale plan.
     */
    function setPresaleAdminAddress(address _presaleAdminAddress)
        external
        onlyOwner
    {
        presaleAdminAddress = _presaleAdminAddress;
    }

    /**
     * @dev This requires the caller to first approve this contract address to spend tokens in callers behalf.
     * In order to do this, the `approve()` function of the ERC20 contract should be called by the caller before executing this with at least the @param _amount value.
     * Example:
     * approve(contractAddress, `amount`); // Where contractAddress should be address(this).
     */
    function stake(
        uint256 _amount,
        StakePlan _stakePlan,
        bool _autoRestake
    ) external whenNotPaused nonReentrant {
        require(address(token) != address(0), "SR: Token address is not set");

        require(_amount > 0, "SR: Cannot stake when amount is ZERO");

        if (_stakePlan == StakePlan.PRESALE_ONE_YEAR_PLAN) {
            require(
                presaleAllowance[msg.sender] > 0,
                "SR: Address not eligible for this stake plan"
            );
            require(
                presaleCloseTime > block.timestamp,
                "SR: Presale already closed"
            );
            presaleAllowance[msg.sender] -= _amount;
            require(presaleAllowance[msg.sender] >= 0);
        }

        require(
            token.allowance(msg.sender, address(this)) >= _amount,
            "SR: Allowance should be greater than the amount staked"
        );

        require(
            !_autoRestake ||
                (_stakePlan != StakePlan.ONE_YEAR_PLAN &&
                    _stakePlan != StakePlan.PRESALE_ONE_YEAR_PLAN),
            "SR: Can not create deposit with this stake plan and the auto-restake option"
        );

        Deposit _deposit = new Deposit(
            owner(),
            address(this),
            address(token),
            msg.sender,
            _amount,
            unstakePenaltyRate,
            unstakeCoolingTime,
            _autoRestake,
            stakePlans[_stakePlan]
        );
        token.transferFrom(msg.sender, address(_deposit), _amount);
        token.approve(address(_deposit), MAX_SUPPLY);
        isDeposit[address(_deposit)] = true;
        require(
            token.balanceOf(address(_deposit)) == _amount,
            "SR: Deposit address did not receive expected funds"
        );
        emit DepositCreated(
            msg.sender,
            address(token),
            address(_deposit),
            _stakePlan,
            _amount,
            _autoRestake
        );
    }

    /**
     * @dev Adds a set of accounts to the presale whitelist enabling them to stake for the StakePlan.PRESALE_ONE_YEAR_PLAN.
     * The function can be executed only by an owner.
     */
    function changePresaleAllowance(
        address[] memory _accounts,
        uint256[] memory _allowedAmounts
    ) external onlyPresaleAdmin whenNotPaused {
        for (uint256 index = 0; index < _accounts.length; index++) {
            presaleAllowance[_accounts[index]] = _allowedAmounts[index];
        }
    }

    /**
     * @dev Called only by deposit contract.
     * @param _amount Unclaimed amount.
     */
    function didUnclaim(address _account, uint256 _amount)
        external
        override
        onlyDeposit
    {
        presaleAllowance[_account] += _amount;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev informs the caller if this contract is paused.
     */
    function isPaused() external view override returns (bool) {
        return paused();
    }

    /**
     * @dev Allows the function to be executed only if the caller is the presale admin.
     */
    modifier onlyPresaleAdmin() {
        require(
            msg.sender == presaleAdminAddress,
            "SR: Only presale admin can call this function"
        );
        _;
    }

    /**
     * @dev Allows the function to be executed only if the caller is a deposit.
     */
    modifier onlyDeposit() {
        require(
            isDeposit[msg.sender],
            "SR: Only a deposit can call this function"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakePlanContext {

    uint256 constant THREE_MONTHS = 3 * (30 days);
    uint256 constant SIX_MONTHS = 6 * (30 days);
    uint256 constant ONE_YEAR = 12 * (30 days);
    uint256 constant MAX_SUPPLY = 2**256 - 1;

    /**
     * @dev All stake plans. Used in the stakePlans mapping.
     */
    enum StakePlan {
        THREE_MONTH_PLAN,
        SIX_MONTH_PLAN,
        ONE_YEAR_PLAN,
        PRESALE_ONE_YEAR_PLAN
    }

    /**
     * @dev Stake plan metadata containing all stake plan config variables.
     * @param duration is auto-initialized based on the stake plan.
     */
    struct StakePlanMetadata {
        uint256 interestRate;
        uint256 duration;
        StakePlan stakePlan;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakeRewards {
    /**
     * @dev informs the caller if this contract is paused.
     */
    function isPaused() external view returns (bool);

    /**
     * @dev Called only by deposit contract.
     * @param _amount Unclaimed amount.
     */
    function didUnclaim(address _account, uint256 _amount) external;
        
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Burnable is IERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IStakeRewards.sol";
import "./IERC20Burnable.sol";
import "./StakePlanContext.sol";

contract Deposit is ReentrancyGuard, StakePlanContext {
    uint256 constant BASIS_POINTS_10000 = 10000;

    /**
     * @dev Emitted when a deposit is claimed.
     * @param _amount The claimed amount (deposit + interest).
     * @param _payoutDate The date after the user can execute the payout.
     */
    event PayoutCreated(uint256 _amount, uint256 _payoutDate);

    /**
     * Emitted only when a deposit is reverted by the owner of the stake rewards. The new beneficiary will only get the initial deposit amount.
     * @param _beneficiary Address that will receive the initial stake amount.
     */
    event DepositReverted(address _beneficiary);

    /**
     * @dev Emitted when a payout has been executed.
     */
    event PayoutExecuted(uint256 _amount);

    /**
     * @dev Emitted when the user opts-out from auto re-stake. Once auto re-stake has
     * been cancelled, this option can no longer be activated.
     * @param _duration New deposit duration.
     * @param _interestMultiplier New deposit interest multiplier.
     */
    event AutoRestakeCancelled(uint256 _duration, uint256 _interestMultiplier);

    /**
     * @dev Emitted when an user unstaked this deposit.
     * @param _payoutAmount The tokens the user will get back.
     * @param _penalty The tokens that will be burned.
     */
    event Unstake(uint256 _payoutAmount, uint256 _penalty);

    /**
     * @dev Holds the payout information
     */
    struct Payout {
        uint256 amount;
        uint256 payoutDate;
    }

    /**
     * @dev Parent stake rewards contract that initially deployed this contract
     */
    IStakeRewards public stakeRewards;

    /**
     * @dev Owner of the deposit.
     */
    address public beneficiary;

    /**
     * @dev ERC20 smart contract to manage funds transfers.
     */
    IERC20Burnable public token;

    /**
     * @dev Deposited amount.
     */
    uint256 public amount;

    /**
     * @dev Deposit creation date. Same value as contract creation date.
     */
    uint256 public depositDate;

    /**
     * @dev The minimum amount of time the user can wait in order to claim without penalties. The claimed amount is the sum of the initial deposited
     * amount plus the interest.
     */
    uint256 public duration;

    /**
     * @dev The rate that will compute the burned tokens if the user will unstake.
     * Expressed in basis points: for example 0.40% is 40bp and 100% is 1000bp.
     */
    uint256 public unstakePenaltyRate;

    /**
     * @dev After claiming the user can withdraw the amount after this period.
     */
    uint256 public unstakeCoolingTime;

    /**
     * @dev After the `stakeDuration` time passes, the claimer will receive the initial amount plus amount*interestRate/1000.
     * Expressed in basis points: for example 0.40% is 40bp and 100% is 1000bp.
     */
    uint256 public interestRate;

    /**
     * @dev Defines the current stake plan for this deposit.
     */
    StakePlan public stakePlan;

    /**
     * @dev Reference to the pending payout. Only one payout can exist.
     */
    Payout public payout;

    /**
     * @dev For stakes of 3 months the user can re-stake the same amount 3 more times.
     * @dev For stakes of 6 months the user can re-stake the same amount 1 more time.
     */
    bool public autoRestake;

    /**
     * @dev How many times the same plan has been restaked.
     */
    uint256 public interestMultiplier = 1;

    /**
     * Stake rewards owner.
     */
    address public owner;

    /**
     * @param _beneficiary The owner of the deposit that can use the claim function.
     */
    constructor(
        address _owner,
        address _stakeRewardsContract,
        address _tokenAddress,
        address _beneficiary,
        uint256 _amount,
        uint256 _unstakePenaltyRate,
        uint256 _unstakeCoolingTime,
        bool _autoRestake,
        StakePlanMetadata memory _stakePlanMetadata
    ) {
        owner = _owner;
        stakeRewards = IStakeRewards(_stakeRewardsContract);
        token = IERC20Burnable(_tokenAddress);
        beneficiary = _beneficiary;
        amount = _amount;
        autoRestake = _autoRestake;
        unstakePenaltyRate = _unstakePenaltyRate;
        unstakeCoolingTime = _unstakeCoolingTime;
        stakePlan = _stakePlanMetadata.stakePlan;
        duration = _stakePlanMetadata.duration;
        interestRate = _stakePlanMetadata.interestRate;
        depositDate = block.timestamp;
        token.approve(address(_stakeRewardsContract), MAX_SUPPLY);
    }

    /**
     * @dev Callbable only by owner.
     * Will mark the amount as zero and will return all available funds to the @param _beneficiary.
     */
    function revertFundsTo(address _beneficiary) public nonReentrant {
        require(msg.sender == owner, "D: Only owner can call this");
        token.transfer(_beneficiary, amount);
        amount = 0;
        emit DepositReverted(_beneficiary);
    }

    /**
     * @dev Computes the entitled amount the user can claim. For actual claiming use the `claim()` function.
     * Transfers the actual amount or zero if the caller has no funds available for claiming. (nothing left or before maturity)
     * Reverts transaction if the computed claim amount is zero.
     * On success performs the actual ERC20 transfer from this contract address to the caller only after payout execution.
     * Does not execute transaction if the parent stake rewards contract is paused.
     */
    function claim()
        public
        onlyBeneficiary
        pausableOnlyIfStakeRewardsIsPaused
        nonReentrant
    {
        uint256 _interest = interest();
        uint256 _claimedAmount = amount + _interest;

        require(_claimedAmount > 0, "D: There is nothing left to claim");
        token.transferFrom(address(stakeRewards), address(this), _interest);
        payout = Payout(_claimedAmount, block.timestamp);
        amount = 0;
        emit PayoutCreated(payout.amount, payout.payoutDate);
    }

    /**
     * @dev Called only before maturity.
     * On 3 month plan unstaking is not possible:
     * On presale no penalties are applied.
     * Half of penalty is burned and half is returned to stake rewards.
     */
    function unstake()
        external
        onlyBeneficiary
        pausableOnlyIfStakeRewardsIsPaused
        nonReentrant
    {
        (
            uint256 _amount,
            uint256 _penalty,
            uint256 _interest
        ) = unstakeAmount();

        if (interestMultiplier != 0) {
            token.transferFrom(address(stakeRewards), address(this), _interest);
        }

        payout = Payout(_amount, block.timestamp + unstakeCoolingTime);
        if (stakePlan == StakePlan.PRESALE_ONE_YEAR_PLAN) {
            stakeRewards.didUnclaim(beneficiary, amount);
        }
        amount = 0;
        uint256 _halfOfPenalty = _penalty / 2;
        token.burn(_penalty - _halfOfPenalty);
        token.transfer(address(stakeRewards), _halfOfPenalty);
        emit Unstake(payout.amount, _penalty);
        emit PayoutCreated(payout.amount, payout.payoutDate);
    }

    /**
     * @dev Once a deposit is marked as non-auto-restakeable, this operation can not be reverted.
     * This will also alter the maturity date.
     */
    function cancelAutoRestake()
        external
        onlyBeneficiary
        pausableOnlyIfStakeRewardsIsPaused
        nonReentrant
    {
        require(
            autoRestake,
            "D: Cancel can only be called on deposits with auto-restake option"
        );
        if (firstMaturityDate() >= block.timestamp) {
            interestMultiplier = 1;
        } else {
            uint256 timeSinceCreation = block.timestamp - depositDate;
            if (stakePlan == StakePlan.THREE_MONTH_PLAN) {
                interestMultiplier = (timeSinceCreation / THREE_MONTHS) + 1;
            } else {
                interestMultiplier = (timeSinceCreation / SIX_MONTHS) + 1;
            }
            duration = duration * interestMultiplier;
        }
        autoRestake = false;
        emit AutoRestakeCancelled(duration, interestMultiplier);
    }

    /**
     * @dev Function to execute a pending payout. Will transfer the amount only if past the payout date.
     */
    function executePayout() external nonReentrant {
        require(payout.amount > 0, "D: Payout amount is zero.");
        require(
            payout.payoutDate <= block.timestamp,
            "D: Payout is still in cooling time."
        );
        token.transfer(beneficiary, payout.amount);
        emit PayoutExecuted(payout.amount);
        delete payout;
    }

    /**
     * @dev Returns the maturity date of the deposit considering the initial stake plan.
     * Does not account for auto-restake option.
     */
    function firstMaturityDate() internal view returns (uint256) {
        return depositDate + duration;
    }

    /**
     * @dev gets the interest the user can get additional to the deposit amount.
     * Does not take into account the current block time or auto restake.
     */
    function baseInterest() internal view returns (uint256) {
        return (amount * interestRate) / BASIS_POINTS_10000;
    }

    /**
     * @dev This is the computed interest the user would receive if he would call the `claim()` function.
     * @dev Does account for block.timestamp, calling this before deposit maturity will render an error if called from smart contracts or will
     * simply return 0 if external called.
     */
    function interest() public view returns (uint256) {
        require(!isAlreadyClaimedOrUnstaked(), "D: Deposited amount is zero");
        require(
            firstMaturityDate() <= block.timestamp,
            "D: Deposit did not reach maturity"
        );

        uint256 _timeDiff = block.timestamp - depositDate;
        uint256 _baseInterest = baseInterest();
        if (stakePlan == StakePlan.THREE_MONTH_PLAN && autoRestake) {
            require(
                _timeDiff >= THREE_MONTHS * 4,
                "D: Auto restake is active. Funds can be claimed only after 1 year"
            );
            return _baseInterest * 4;
        }
        if (stakePlan == StakePlan.SIX_MONTH_PLAN && autoRestake) {
            require(
                _timeDiff >= SIX_MONTHS * 2,
                "D: Auto restake is active. Funds can be claimed only after 1 year"
            );
            return _baseInterest * 2;
        }

        return _baseInterest * interestMultiplier;
    }

    /**
     * @dev This is the computed amount that can be unstaked. The amount might be different from the amount initially staked.
     * This is caused by the `_penalty` and `_interest` computed.
     * @dev Does account for block.timestamp, calling this after deposit maturity will render an error if called from smart contracts or will
     * simply return 0 for all 3 return types if external called.
     */
    function unstakeAmount()
        public
        view
        returns (
            uint256 _amount,
            uint256 _penalty,
            uint256 _interest
        )
    {
        require(
            stakePlan != StakePlan.THREE_MONTH_PLAN,
            "D: Can not unstake for this stake plan"
        );
        require(
            firstMaturityDate() > block.timestamp || autoRestake,
            "D: Can not unstake for an already mature plan without auto restake"
        );
        if (stakePlan == StakePlan.SIX_MONTH_PLAN) {
            uint256 timeDiff = block.timestamp - depositDate;
            require(
                timeDiff < SIX_MONTHS * 2,
                "D: Can not unstake for an already mature plan with auto restake"
            );
            _penalty = (amount * unstakePenaltyRate) / BASIS_POINTS_10000;
            if (timeDiff < SIX_MONTHS) {
                _interest = 0;
            } else {
                _interest = baseInterest();
            }
        } else {
            _penalty = (amount * unstakePenaltyRate) / BASIS_POINTS_10000;
            _interest = 0;
        }

        _amount = amount - _penalty + _interest;
    }

    /**
     * @dev Returns if this deposit is already consumed.
     */
    function isAlreadyClaimedOrUnstaked() public view returns (bool) {
        return amount == 0;
    }

    /**
     * @dev Executes only if the parent stake rewards contract is NOT paused.
     */
    modifier pausableOnlyIfStakeRewardsIsPaused() {
        require(
            !stakeRewards.isPaused(),
            "D: Can not perform action if stake rewards is paused"
        );
        _;
    }

    /**
     * @dev Can only be called by the beneficiary.
     */
    modifier onlyBeneficiary() {
        require(
            beneficiary == msg.sender,
            "D: Only the beneficiary can call this"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}