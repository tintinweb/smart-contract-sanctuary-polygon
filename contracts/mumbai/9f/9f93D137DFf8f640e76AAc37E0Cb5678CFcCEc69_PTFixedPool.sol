// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IFixLender.sol";
import "../interfaces/IToken.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IVixPremineRewards as Premining } from "../vix-premining/IVixPremineRewards.sol";

/**
 * @title Fixed Lender Pool contract for Polytrade
 * @author 0vix
 * @notice Users can deposit in predefined fixed lender pool during deposit period and withdraw their
 * Principal stable amount with its stable and bonus rewards based on APR and Rate. Bonus rewards can be redeemed before
 * locking duration ends
 * @dev The contract is in development stage
 */
contract PTFixedPool is OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IToken;

    //Contract variables
    IFixLender private ptFIPool;
    IToken private stableToken;
    IToken private bonusToken;
    Premining public premining;
    uint256 private _preminingRate;
    uint8 private _stableDecimal;
    uint8 private _bonusDecimal;
    bool private withdrawn;
    uint256 private constant YEAR = 365 days;

    //Lender struct & mapping
    struct Lender {
        uint256 totalDeposit;
        uint256 pendingStableReward;
        uint256 pendingBonusReward;
        uint256 pendingPreminingReward;
        uint256 lastUpdateDate;
    }
    mapping(address => Lender) public lenders;

    //Events
    event Deposited(address indexed lender, uint256 amount);
    event Withdrawn(
        address indexed lender,
        uint256 amount,
        uint256 bonusReward
    );
    event BonusClaimed(address indexed lender, uint256 bonusReward);

    modifier hasDeposit() {
        require(
            lenders[msg.sender].totalDeposit != 0,
            "You have not deposited."
        );
        _;
    }

    /**
     * @dev Initialized the contract. Sets the values for , polytradeFixedContract, stableToken, bonusToken, stableApr, bonusRate, bonusRate, lock duration
     * and withdrawn state
     * @param _ptFIPoolAddr Polytrade fixed pool contract address
     */
    function initialize(address _ptFIPoolAddr, address _premining, uint256 preminingRate_)
        external
        initializer
    {
        __Ownable_init();
        require(
            AddressUpgradeable.isContract(_ptFIPoolAddr) &&
                AddressUpgradeable.isContract(_premining),
            "Invalid address: not a contract"
        );
        ptFIPool = IFixLender(_ptFIPoolAddr);
        premining = Premining(_premining);
        stableToken = IToken(getStableToken());
        bonusToken = IToken(getBonusToken());
        _stableDecimal = stableToken.decimals();
        _bonusDecimal = bonusToken.decimals();
        _preminingRate = preminingRate_ * (10**(18 - _stableDecimal));
        withdrawn = false;
    }

    /**
     * @notice `deposit` Deposits a stable amount to the polytrade fixed pool
     * @param _amount The amount to be depositted
     * Emits {Deposited} event
     */
    function deposit(uint256 _amount) external whenNotPaused {
        require(
            block.timestamp < getDepositEndDate(),
            "Funds cannot be deposited past deposit deadline"
        );
        require(
            getPoolSize() + _amount <= getMaxPoolSize(),
            "Pool has reached its limit"
        );
        require(
            _amount >= getMinDeposit(),
            "Amount below the minimum deposit requirement"
        );
        stableToken.safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_amount);
        if (lenders[msg.sender].lastUpdateDate == 0) {
            lenders[msg.sender].lastUpdateDate = block.timestamp;
        }
        Lender memory lenderData = lenders[msg.sender];
        uint256 currentDeposit = lenderData.totalDeposit;
        uint256 pendingStableReward = lenderData.pendingStableReward;
        uint256 pendingBonusReward = lenderData.pendingBonusReward;
        uint256 pendingPreminingReward = lenderData.pendingPreminingReward;
        uint256 poolStartDate = getPoolStartDate();
        uint256 lastUpdateDate = poolStartDate;
        if (block.timestamp > poolStartDate) {
            (uint256 stableReward, uint256 bonusReward, uint256 premineReward) = getRewards(
                msg.sender
            );
            pendingStableReward = pendingStableReward + stableReward;
            pendingBonusReward = pendingBonusReward + bonusReward;
            pendingPreminingReward = pendingPreminingReward + premineReward;
            lastUpdateDate = block.timestamp;
        }
        lenders[msg.sender] = Lender(
            currentDeposit + _amount,
            pendingStableReward,
            pendingBonusReward,
            pendingPreminingReward,
            lastUpdateDate
        );
        emit Deposited(msg.sender, _amount);
    }

    /**
     * @notice `claimBonus` Calls the claimBonus() function on the polytrade pool and transfers TRADE token to the user
     * based on their claimable bonus
     * Emits {BonusClaimed} event
     */
    function claimBonus() external whenNotPaused hasDeposit {
        require(
            block.timestamp > getPoolStartDate(),
            "Pool has not started yet"
        );
        ptFIPool.claimBonus();
        (uint256 stableReward, uint256 bonusReward, uint256 premineRewards) = getRewards(msg.sender);
        Lender storage lenderData = lenders[msg.sender];
        lenderData.pendingStableReward =
            lenderData.pendingStableReward +
            stableReward;
        uint256 claimableBonus = bonusReward + lenderData.pendingBonusReward;
        uint256 premineBonus = premineRewards + lenderData.pendingPreminingReward;
        lenderData.pendingBonusReward = 0;
        lenderData.pendingPreminingReward = 0;
        uint256 poolEndDate = getPoolEndDate();
        lenderData.lastUpdateDate = block.timestamp > poolEndDate
            ? poolEndDate
            : block.timestamp;
        uint256 balance = bonusToken.balanceOf(address(this));
        uint256 claimAmount;
        addPreminingRewards(msg.sender, premineBonus);
        if (claimableBonus >= balance) {
            claimAmount = balance;
            bonusToken.safeTransfer(msg.sender, claimAmount);
        } else {
            claimAmount = claimableBonus;
            bonusToken.safeTransfer(msg.sender, claimAmount);
        }
        emit BonusClaimed(msg.sender, claimAmount);
    }

    /**
     * @notice `withdraw` Calls the withdraw() function on the polytrade pool, which returns the deposit back to the user
     * along with stable and bonus rewards that they are entitled to.
     * Emits {Withdrawn} event
     */
    function withdraw() external whenNotPaused hasDeposit {
        require(
            block.timestamp > getPoolEndDate(),
            "Funds cannot be withdrawn before end of locking duration"
        );
        _withdraw();
        (uint256 stableReward, uint256 bonusReward, uint256 preminingRewards) = getRewards(msg.sender);
        Lender memory lenderData = lenders[msg.sender];
        uint256 totalDeposit = lenderData.totalDeposit;
        uint256 stableAmount = stableReward +
            lenderData.pendingStableReward +
            totalDeposit;
        uint256 bonusAmount = bonusReward + lenderData.pendingBonusReward;
        uint256 preminingAmount = preminingRewards + lenderData.pendingPreminingReward;
        delete lenders[msg.sender];
        addPreminingRewards(msg.sender, preminingAmount);
        (uint256 stableWithdrawn, uint256 bonusWithdrawn) = handleTransfer(
            stableAmount,
            bonusAmount
        );
        emit Withdrawn(msg.sender, stableWithdrawn, bonusWithdrawn);
    }

    /**
     * @notice Returns the totalDeposit for a given lender
     */
    function getLenderTotalDeposit(address _lender)
        external
        view
        returns (uint256)
    {
        return lenders[_lender].totalDeposit;
    }

    /**
     * @notice Returns the pending Bonus rewards for a given lender
     */
    function getLenderBonusRewards(address _lender)
        external
        view
        returns (uint256)
    {
        uint256 bonusReward;
        uint256 poolStartDate = getPoolStartDate();
        if (block.timestamp > poolStartDate) {
            (, bonusReward,) = getRewards(_lender);
            bonusReward = bonusReward + lenders[_lender].pendingBonusReward;
        }
        return bonusReward;
    }

    /**
     * @notice Returns the pending Bonus rewards for a given lender
     */
    function getLenderPreminingRewards(address _lender)
        external
        view
        returns (uint256)
    {
        uint256 preminingReward;
        uint256 poolStartDate = getPoolStartDate();
        if (block.timestamp > poolStartDate) {
            (, , preminingReward) = getRewards(_lender);
            preminingReward = preminingReward + lenders[_lender].pendingBonusReward;
        }
        return preminingReward;
    }

    /**
     * @notice Returns the pending stable rewards for a given lender
     */
    function getLenderStableRewards(address _lender)
        external
        view
        returns (uint256)
    {
        uint256 stableReward;
        uint256 poolStartDate = getPoolStartDate();
        if (block.timestamp > poolStartDate) {
            (stableReward, ,) = getRewards(_lender);
            stableReward = stableReward + lenders[_lender].pendingStableReward;
        }
        return stableReward;
    }

    /**
     * @notice Returns the minimum Deposit
     */
    function getMinDeposit() public view returns (uint256) {
        return ptFIPool.getMinDeposit();
    }

    function getStableToken() public view returns (address) {
        return ptFIPool.stableToken();
    }

    function getBonusToken() public view returns (address) {
        return ptFIPool.bonusToken();
    }

    function getPtFIPool() public view returns (address) {
        return address(ptFIPool);
    }

    /**
     * @notice Returns the Deposit end date for the Polytrade fixed pool
     */
    function getDepositEndDate() public view returns (uint256) {
        return ptFIPool.getDepositEndDate();
    }

    /**
     * @notice Returns the stable APR
     */
    function getApr() public view returns (uint256) {
        return ptFIPool.getApr();
    }

    /**
     * @notice Returns the Bonus rate
     */
    function getBonusRate() public view returns (uint256) {
        return ptFIPool.getBonusRate();
    }

    /**
     * @notice Returns the Pre mining rate
     */
    function getPreminingRate() public view returns (uint256) {
        return _preminingRate / (10**(18 - _stableDecimal));
    }

    /**
     * @notice Returns the locking duration for the Polytrade fixed pool
     */
    function getLockingDuration() public view returns (uint256) {
        return ptFIPool.getLockingDuration();
    }

    /**
     * @notice Returns the startDate for the Polytrade fixed pool
     */
    function getPoolStartDate() public view returns (uint256) {
        return ptFIPool.getPoolStartDate();
    }

    /**
     * @notice Returns the Polytrade fixed pool size
     */
    function getPoolSize() public view returns (uint256) {
        return ptFIPool.getPoolSize();
    }

    /**
     * @notice returns the pool maximum size that once reached lender can not deposit
     */
    function getMaxPoolSize() public view returns (uint256) {
        return ptFIPool.getMaxPoolSize();
    }

    /**
     * @notice Returns the total amount deposited by 0vix on the respective polytrade fixed pool
     */
    function getTotalDeposit() external view returns (uint256) {
        return ptFIPool.getTotalDeposit(address(this));
    }

    /**
     * @notice Returns the total bonus rewards pending for 0vix on the respective polytrade fixed pool
     */
    function getBonusRewards() external view returns (uint256) {
        return ptFIPool.getBonusRewards(address(this));
    }

    /**
     * @notice Returns the total stable rewards pending for 0vix on the respective polytrade fixed pool
     */
    function getStableRewards() external view returns (uint256) {
        return ptFIPool.getStableRewards(address(this));
    }

    /**
     * @notice Returns the end date for the polytrade fixed pool
     * @dev Update this function once Polytrade creates a getter for the end date
     */
    function getPoolEndDate() public view returns (uint256) {
        return getPoolStartDate() + (getLockingDuration() * 1 days);
    }

    function getWithdrawPenaltyPercent() public view returns (uint256) {
        return ptFIPool.getWithdrawPenaltyPercent();
    }

    /**
     * @notice Returns the total pending bonus and stable rewards for a given lender
     * @param _lender the lender address
     * @return pendingStableReward since last updated
     * @return pendingBonusReward since last updated
     */
    function getRewards(address _lender)
        private
        view
        returns (uint256, uint256, uint256)
    {
        Lender memory lenderData = lenders[_lender];
        uint256 poolEndDate = getPoolEndDate();
        uint256 endDate = block.timestamp > poolEndDate
            ? poolEndDate
            : block.timestamp;
        uint256 diff = endDate - lenderData.lastUpdateDate;
        uint256 totalDeposit = lenderData.totalDeposit;
        uint256 stableApr = getApr();
        uint256 bonusRate = getBonusRate() *
            (10**(_bonusDecimal - _stableDecimal));
        return (
            calculateFormula(totalDeposit, diff, stableApr) / 1E2,
            calculateFormula(totalDeposit, diff, bonusRate),
            calculateFormula(totalDeposit, diff, _preminingRate)
        );
    }

    /**
     * @notice Returns the total pending stable reward
     * @param _amount the total deposit amount for the lender
     * @param _duration the time difference between the current timestamp and lastUpdateDate
     * @param _rate the stable APR
     * @return pendingStableReward since last updated
     */
    function calculateFormula(
        uint256 _amount,
        uint256 _duration,
        uint256 _rate
    ) private pure returns (uint256) {
        return ((_amount * _duration * _rate) / 1E2) / YEAR;
    }

    //************   INTERNAL   ************//

    function addPreminingRewards(address _user, uint256 amount) internal {
        premining.ptAddRewards(_user, amount);
    }

    function _deposit(uint256 _amount) internal {
        stableToken.safeApprove(address(ptFIPool), _amount);
        ptFIPool.deposit(_amount);
    }

    function _withdraw() internal {
        if (!withdrawn) {
            ptFIPool.withdraw();
            withdrawn = true;
        }
    }

    function handleTransfer(uint256 stableAmount, uint256 bonusAmount)
        internal
        returns (uint256 stableWithdrawn, uint256 bonusWithdrawn)
    {
        uint256 sBal = stableToken.balanceOf(address(this));
        uint256 bBal = bonusToken.balanceOf(address(this));
        if (stableAmount > sBal) {
            uint256 diff = stableAmount - sBal;
            require(diff <= 3, "diff > 3");
            stableWithdrawn = sBal;
            stableToken.safeTransfer(msg.sender, stableWithdrawn);
        } else {
            stableWithdrawn = stableAmount;
            stableToken.safeTransfer(msg.sender, stableWithdrawn);
        }

        if (bonusAmount > bBal) {
            uint256 diff = bonusAmount - bBal;
            require(diff <= 3, "diff > 3");
            bonusWithdrawn = bBal;
            bonusToken.safeTransfer(msg.sender, bonusWithdrawn);
        } else {
            bonusWithdrawn = bonusAmount;
            bonusToken.safeTransfer(msg.sender, bonusWithdrawn);
        }
    }

    //************   ONLY OWNER   ************//

    /**
     * @notice Updates the Polytrade fixed pool address
     * @param _ptFIPoolAddr the new pool address
     */
    function setPTFixPool(address _ptFIPoolAddr) external onlyOwner {
        ptFIPool = IFixLender(_ptFIPoolAddr);
    }

    /**
     * @notice Emergency withdraw all funds deposited by 0vix
     */
    function emergencyWithdraw() external onlyOwner {
        ptFIPool.emergencyWithdraw();
    }

    /**
     * @notice Pause the contrace
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contrace
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function callExt(address _target, bytes memory _data)
        external
        onlyOwner
        returns (bytes memory)
    {
        (bool success, bytes memory result) = _target.call(_data);
        require(success, "Ext: Call failed");
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title IFixLender
 * @author Polytrade
 */
interface IFixLender {
    struct Lender {
        uint256 totalDeposit;
        uint256 pendingStableReward;
        uint256 pendingBonusReward;
        uint256 lastUpdateDate;
    }

    error UnsupportedInterface();
    error NotVerified();
    error NoDeposit();

    /**
     * @notice Emits when new fund is deposited to the Lender Pool
     * @param lender is the address of the 'lender'
     * @param amount is the stable tokens deposited by the lender
     */
    event Deposited(address indexed lender, uint256 amount);

    /** 
    * @notice Emits when deposited funds withdrawn from the Lender Pool 
    * @param lender is the address of the 'lender' 
    * @param amount is the principal stable amount of deposit + stable  
    Reward lender received based on APR
    * @param bonusReward is the remaining Bonus rewards lender received based on the Rate 
    */
    event Withdrawn(
        address indexed lender,
        uint256 amount,
        uint256 bonusReward
    );

    /**
     * @notice Emits when lender claims Bonus rewards
     * @param lender is the address of the 'lender'
     * @param bonusReward is the accumulated Bonus rewards lender received based on the Rate
     */
    event BonusClaimed(address indexed lender, uint256 bonusReward);

    /**
     * @notice Emits when a lender tries to withdraw from pool before pool end date
     * @param lender is the address of the 'lender'
     * @param amount is the amount that withdrawn by lender
     * @param bonusReward is the accumulated bonus rewards that withdrawn by lender
     */
    event WithdrawnEmergency(
        address indexed lender,
        uint256 amount,
        uint256 bonusReward
    );

    /**
     * @notice Emits when an admin changes the rate for the emergency withdraw fee
     * @param oldRate is the old withdraw rate
     * @param newRate is the new withdraw rate
     */
    event WithdrawRateChanged(uint256 oldRate, uint256 newRate);

    /**
     * @notice Emits when new verification contract is used
     * @dev Emitted when switchVerification function is called by owner
     * @param oldVerification is the old verification contract Address
     * @param newVerification is the new verification contract Address
     */
    event VerificationSwitched(
        address oldVerification,
        address newVerification
    );

    /**
     * @notice Emitted when staking strategy is switched
     * @dev Emitted when switchStrategy function is called by owner
     * @param oldStrategy is the address of the old staking strategy
     * @param newStrategy is the address of the new staking strategy
     */
    event StrategySwitched(address oldStrategy, address newStrategy);

    /**
     * @notice Emitted when penalty fees is withdrawn
     * @dev Emitted when withdrawFees function is called by owner
     * @param amount is the total amount of accumulated emergency penalty withdraw fees
     */
    event PenaltyFeeWithdrawn(uint256 amount);

    /**
     * @notice Emitted when client portal withdraws
     * @dev Emitted when clientPortalWithdraw function is called by client portal
     * @param amount is the amount of stable token to withdraw from strategy
     */
    event ClientPortalWithdrawal(uint256 amount);

    /**
     * @notice Deposits an amount of stable token for a fixed lender pool
     * @dev It transfers the approved stable tokens from msg.sender to lender pool
     * @param amount Represents the amount of stable tokens to deposit
     * Requirements:
     * - 'amount' should be greater than zero
     * - 'amount' must be approved from the stable token contract for the LenderPool
     * - It should be called before Deposit End Date
     * Emits {Deposited} event
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Claims the Bonus rewards to the lender based on the Rate
     * @dev 'claimReward' transfers all the accumulated Bonus bonus rewards to 'msg.sender'
     * Requirements :
     * - 'LenderPool' should have Bonus tokens more than or equal to lender accumulated bonus rewards
     * Emits {Claimed} event
     */
    function claimBonus() external;

    /**
     * @notice Withdraws principal deposited tokens + Stable rewards + remaining Bonus rewards for locking period
     * Requirements:
     * - 'LenderPool' should have stable tokens more than or equal to lender stable rewards + principal amount
     * - 'LenderPool' should have Bonus tokens more than or equal to lender accumulated bonus rewards
     * Emits {Withdrawn} event
     */
    function withdraw() external;

    /**
     * @notice Withdraws principal total deposit minus fee that is a percentage of total deposit
     * Requirements:
     * - Should be called before pool end date
     * - 'msg.sender' should have deposit
     * - Lender should have enough stable token to transfer
     * Emits {WithdrawnEmergency} event
     */
    function emergencyWithdraw() external;

    /**
     * @notice Changes the withdraw rate for emergency withdraw
     * @dev withdraw rate is in percentage with 2 decimals
     * @param newRate is the new withdraw rate with 2 decimals
     * Emits {WithdrawRateChanged} event
     */
    function setWithdrawRate(uint256 newRate) external;

    /**
     * @dev Changes the Verification contract that has been used for checking verification of lenders
     * @param _newVerification is the address of the new verification contract
     * Emits {VerificationSwitched} event
     */
    function switchVerification(address _newVerification) external;

    /**
     * @dev Changes the Strategy contract used for managing funds in defi protocols
     * @param _newStrategy is the address of the new strategy contract
     * Emits {StrategySwitched} event
     */
    function switchStrategy(address _newStrategy) external;

    /**
     * @dev Withdraws the amount of stable tokens by client portal to fund invoices
     * Emits {ClientPortalWithdrawal} event
     */
    function clientPortalWithdraw(uint256 amount) external;

    /**
     * @dev Withdraws accumulated penalty emergency withdraw fees to owner
     * Emits {PenaltyFeeWithdrawn} event
     */
    function withdrawFees() external;

    /**
     * @dev returns the deposited amount of a specific lender
     * @param _lender Represents the address of lender
     */
    function getTotalDeposit(address _lender) external view returns (uint256);

    /**
     * @dev returns the available Bonus rewards to claim for a specific lender
     * @param _lender Represents the address of lender
     */
    function getBonusRewards(address _lender) external view returns (uint256);

    /**
     * @dev returns the accumulated amount of stable rewards for a specific lender
     * @param _lender Represents the address of lender
     */
    function getStableRewards(address _lender) external view returns (uint256);

    /**
     * @dev returns the APR in percentage without decimals
     */
    function getApr() external view returns (uint256);

    /**
     * @dev returns the Rate of bonus reward with 2 decimals
     */
    function getBonusRate() external view returns (uint256);

    /**
     * @dev returns the duration of locking period in days
     */
    function getLockingDuration() external view returns (uint256);

    /**
     * @dev returns pool start date for which the reward calculation begins
     */
    function getPoolStartDate() external view returns (uint256);

    /**
     * @dev returns the end deposit date after which users can not deposit
     */
    function getDepositEndDate() external view returns (uint256);

    /**
     * @dev returns the current pool size
     */
    function getPoolSize() external view returns (uint256);

    /**
     * @dev returns the pool maximum size that once reached lender can not deposit
     */
    function getMaxPoolSize() external view returns (uint256);

    /**
     * @dev returns the minimum stable tokens required for depositing
     */
    function getMinDeposit() external view returns (uint256);

    /**
     * @dev returns accumulated emergency penalty withdraw fees
     */
    function getTotalPenaltyFee() external view returns (uint256);

    /**
     * @dev returns emergency withdraw penalty percentage with 2 decimals
     */
    function getWithdrawPenaltyPercent() external view returns (uint256);

    /**
     * @dev returns the address of Stable Token
     */
    function stableToken() external view returns (address);

    /**
     * @dev returns the address of Bonus Token
     */
    function bonusToken() external view returns (address);

    /**
     * @dev returns the address of verification contract
     */
    function verification() external view returns (address);

    /**
     * @dev returns the address of strategy contract
     */
    function strategy() external view returns (address);

    /**
     * @dev returns the required verification status of lender pool
     */
    function getVerificationStatus() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IToken is IERC20Upgradeable {
    function mint(address to, uint amount) external;

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IVixPremineRewards {
   
    struct User {
        address userAddress;
        uint256 rewardsThisEpoch;
    }
    struct Market {
        address marketAddress;
        uint256 rewardsThisEpoch;
    }

    //************ * ฅ^•ﻌ•^ฅ  USERS INTERACTION  ฅ^•ﻌ•^ฅ * ************//
    function claimVixReward() external;

    //************ * ฅ^•ﻌ•^ฅ  ONLY OWNER  ฅ^•ﻌ•^ฅ * ************//

    function addRewards(User[] memory _userAmounts, uint256 _epoch) external;

    function ptAddRewards(address user, uint256 amount) external;

    ///@dev Careful this will replace user amounts
    function editRewards(User[] memory _editedUserAmounts) external;

    //************ * ฅ^•ﻌ•^ฅ  VIEW  ฅ^•ﻌ•^ฅ * ************//

    function getAllMarketRewards() external view returns (Market[] memory);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}