pragma solidity 0.8.11;

import "./dependencies/Ownable.sol";
import "./dependencies/SafeERC20.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/solidly/IBaseV1Voter.sol";
import "./interfaces/solidly/IGauge.sol";
import "./interfaces/solidly/IBribe.sol";
import "./interfaces/solidly/IVotingEscrow.sol";
import "./interfaces/solidex/IFeeDistributor.sol";
import "./interfaces/solidex/ISolidexToken.sol";
import "./interfaces/solidex/ILpDepositToken.sol";
import "./interfaces/solidex/IVeDepositor.sol";


contract LpDepositor is Ownable {

    using SafeERC20 for IERC20;

    // solidly contracts
    IERC20 public immutable SOLID;
    IVotingEscrow public immutable votingEscrow;
    IBaseV1Voter public immutable solidlyVoter;

    // solidex contracts
    ISolidexToken public SEX;
    IVeDepositor public SOLIDsex;
    IFeeDistributor public feeDistributor;
    address public stakingRewards;
    address public tokenWhitelister;
    address public depositTokenImplementation;

    uint256 public tokenID;

    struct Amounts {
        uint256 solid;
        uint256 sex;
    }

    // pool -> gauge
    mapping(address => address) public gaugeForPool;
    // pool -> bribe
    mapping(address => address) public bribeForPool;
    // pool -> solidex deposit token
    mapping(address => address) public tokenForPool;
    // user -> pool -> deposit amount
    mapping(address => mapping(address => uint256)) public userBalances;
    // pool -> total deposit amount
    mapping(address => uint256) public totalBalances;
    // pool -> integrals
    mapping(address => Amounts) public rewardIntegral;
    // user -> pool -> integrals
    mapping(address => mapping(address => Amounts)) public rewardIntegralFor;
    // user -> pool -> claimable
    mapping(address => mapping(address => Amounts)) claimable;

    // internal accounting to track SOLID fees for SOLIDsex stakers and SEX lockers
    uint256 unclaimedSolidBonus;

    event RewardAdded(address indexed rewardsToken, uint256 reward);
    event Deposited(address indexed user, address indexed pool, uint256 amount);
    event Withdrawn(address indexed user, address indexed pool, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event TransferDeposit(address indexed pool, address indexed from, address indexed to, uint256 amount);

    constructor(
        IERC20 _solid,
        IVotingEscrow _votingEscrow,
        IBaseV1Voter _solidlyVoter

    ) {
        SOLID = _solid;
        votingEscrow = _votingEscrow;
        solidlyVoter = _solidlyVoter;
    }

    function setAddresses(
        ISolidexToken _sex,
        IVeDepositor _solidsex,
        address _solidexVoter,
        IFeeDistributor _feeDistributor,
        address _stakingRewards,
        address _tokenWhitelister,
        address _depositToken
    ) external onlyOwner {
        SEX = _sex;
        SOLIDsex = _solidsex;
        feeDistributor = _feeDistributor;
        stakingRewards = _stakingRewards;
        tokenWhitelister = _tokenWhitelister;
        depositTokenImplementation = _depositToken;

        SOLID.approve(address(_solidsex), type(uint256).max);
        _solidsex.approve(address(_feeDistributor), type(uint256).max);
        votingEscrow.setApprovalForAll(_solidexVoter, true);
        votingEscrow.setApprovalForAll(address(_solidsex), true);

        renounceOwnership();
    }

    /**
        @dev Ensure SOLID, SEX and SOLIDsex are whitelisted
     */
    function whitelistProtocolTokens() external {
        require(tokenID != 0, "No initial NFT deposit");
        if (!solidlyVoter.isWhitelisted(address(SOLID))) {
            solidlyVoter.whitelist(address(SOLID), tokenID);
        }
        if (!solidlyVoter.isWhitelisted(address(SOLIDsex))) {
            solidlyVoter.whitelist(address(SOLIDsex), tokenID);
        }
        if (!solidlyVoter.isWhitelisted(address(SEX))) {
            solidlyVoter.whitelist(address(SEX), tokenID);
        }
    }

    /**
        @notice Get pending SOLID and SEX rewards earned by `account`
        @param account Account to query pending rewards for
        @param pools List of pool addresses to query rewards for
        @return pending Array of tuples of (SOLID rewards, SEX rewards) for each item in `pool`
     */
    function pendingRewards(
        address account,
        address[] calldata pools
    )
        external
        view
        returns (Amounts[] memory pending)
    {
        pending = new Amounts[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            address pool = pools[i];
            pending[i] = claimable[account][pool];
            uint256 balance = userBalances[account][pool];
            if (balance == 0) continue;

            Amounts memory integral = rewardIntegral[pool];
            uint256 total = totalBalances[pool];
            if (total > 0) {
                uint256 delta = IGauge(gaugeForPool[pool]).earned(address(SOLID), address(this)); // solidly integration
                delta -= delta * 15 / 100;
                integral.solid += 1e18 * delta / total;
                integral.sex += 1e18 * (delta * 10000 / 42069) / total;
            }

            Amounts storage integralFor = rewardIntegralFor[account][pool];
            if (integralFor.solid < integral.solid) {
                pending[i].solid += balance * (integral.solid - integralFor.solid) / 1e18;
                pending[i].sex += balance * (integral.sex - integralFor.sex) / 1e18;
            }
        }
        return pending;
    }

    /**
        @notice Deposit Solidly LP tokens into a gauge via this contract
        @dev Each deposit is also represented via a new ERC20, the address
             is available by querying `tokenForPool(pool)`
        @param pool Address of the pool token to deposit
        @param amount Quantity of tokens to deposit
     */
    function deposit(address pool, uint256 amount) external {
        require(tokenID != 0, "Must lock SOLID first");
        require(amount > 0, "Cannot deposit zero");

        address gauge = gaugeForPool[pool];
        uint256 total = totalBalances[pool];
        uint256 balance = userBalances[msg.sender][pool];

        if (gauge == address(0)) {
            gauge = solidlyVoter.gauges(pool);
            if (gauge == address(0)) {
                gauge = solidlyVoter.createGauge(pool);
            }
            gaugeForPool[pool] = gauge;
            bribeForPool[pool] = solidlyVoter.bribes(gauge);
            tokenForPool[pool] = _deployDepositToken(pool); // deploying pool i guess
            IERC20(pool).approve(gauge, type(uint256).max);
        } else {
            _updateIntegrals(msg.sender, pool, gauge, balance, total);
        }

        IERC20(pool).transferFrom(msg.sender, address(this), amount);
        IGauge(gauge).deposit(amount, tokenID); // depositing into gauge

        userBalances[msg.sender][pool] = balance + amount;
        totalBalances[pool] = total + amount;
        IDepositToken(tokenForPool[pool]).mint(msg.sender, amount);
        emit Deposited(msg.sender, pool, amount);
    }

    /**
        @notice Withdraw Solidly LP tokens
        @param pool Address of the pool token to withdraw
        @param amount Quantity of tokens to withdraw
     */
    function withdraw(address pool, uint256 amount) external {
        address gauge = gaugeForPool[pool];
        uint256 total = totalBalances[pool];
        uint256 balance = userBalances[msg.sender][pool];

        require(gauge != address(0), "Unknown pool");
        require(amount > 0, "Cannot withdraw zero");
        require(balance >= amount, "Insufficient deposit");

        _updateIntegrals(msg.sender, pool, gauge, balance, total);

        userBalances[msg.sender][pool] = balance - amount;
        totalBalances[pool] = total - amount;

        IDepositToken(tokenForPool[pool]).burn(msg.sender, amount);
        IGauge(gauge).withdraw(amount);
        IERC20(pool).transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, pool, amount);
    }

    /**
        @notice Claim SOLID and SEX rewards earned from depositing LP tokens
        @dev An additional 5% of SEX is also minted for `StakingRewards`
        @param pools List of pools to claim for
     */
    function getReward(address[] calldata pools) external {
        Amounts memory claims;
        for (uint256 i = 0; i < pools.length; i++) {
            address pool = pools[i];
            address gauge = gaugeForPool[pool];
            uint256 total = totalBalances[pool];
            uint256 balance = userBalances[msg.sender][pool];
            _updateIntegrals(msg.sender, pool, gauge, balance, total);
            claims.solid += claimable[msg.sender][pool].solid;
            claims.sex += claimable[msg.sender][pool].sex;
            delete claimable[msg.sender][pool];
        }
        if (claims.solid > 0) {
            SOLID.transfer(msg.sender, claims.solid);
            emit RewardPaid(msg.sender, address(SOLID), claims.solid);
        }
        if (claims.sex > 0) {
            SEX.mint(msg.sender, claims.sex);
            emit RewardPaid(msg.sender, address(SEX), claims.sex);
            // mint an extra 5% for SOLIDsex stakers
            SEX.mint(address(stakingRewards), claims.sex * 100 / 95 - claims.sex);
            emit RewardPaid(address(stakingRewards), address(SEX), claims.sex * 100 / 95 - claims.sex);
        }
    }

    /**
        @notice Claim incentive tokens from gauge and/or bribe contracts
                and transfer them to `FeeDistributor`
        @dev This method is unguarded, anyone can claim any reward at any time.
             Claimed tokens are streamed to SEX lockers starting at the beginning
             of the following epoch week.
        @param pool Address of the pool token to claim for
        @param gaugeRewards List of incentive tokens to claim for in the pool's gauge
        @param bribeRewards List of incentive tokens to claim for in the pool's bribe contract
     */
    function claimLockerRewards(
        address pool,
        address[] calldata gaugeRewards,
        address[] calldata bribeRewards
    ) external {
        // claim pending gauge rewards for this pool to update `unclaimedSolidBonus`
        address gauge = gaugeForPool[pool];
        require(gauge != address(0), "Unknown pool");
        _updateIntegrals(address(0), pool, gauge, 0, totalBalances[pool]);

        address distributor = address(feeDistributor);
        uint256 amount;

        // fetch gauge rewards and push to the fee distributor
        if (gaugeRewards.length > 0) {
            IGauge(gauge).getReward(address(this), gaugeRewards);
            for (uint i = 0; i < gaugeRewards.length; i++) {
                IERC20 reward = IERC20(gaugeRewards[i]);
                require(reward != SOLID, "!SOLID as gauge reward");
                amount = IERC20(reward).balanceOf(address(this));
                if (amount == 0) continue;
                if (reward.allowance(address(this), distributor) == 0) {
                    reward.safeApprove(distributor, type(uint256).max);
                }
                IFeeDistributor(distributor).depositFee(address(reward), amount);
            }
        }

        // fetch bribe rewards and push to the fee distributor
        if (bribeRewards.length > 0) {
            uint256 solidBalance = SOLID.balanceOf(address(this));
            IBribe(bribeForPool[pool]).getReward(tokenID, bribeRewards);
            for (uint i = 0; i < bribeRewards.length; i++) {
                IERC20 reward = IERC20(bribeRewards[i]);
                if (reward == SOLID) {
                    // when SOLID is received as a bribe, add it to the balance
                    // that will be converted to SOLIDsex prior to distribution
                    uint256 newBalance = SOLID.balanceOf(address(this));
                    unclaimedSolidBonus += newBalance - solidBalance;
                    solidBalance = newBalance;
                    continue;
                }
                amount = reward.balanceOf(address(this));
                if (amount == 0) continue;
                if (reward.allowance(address(this), distributor) == 0) {
                    reward.safeApprove(distributor, type(uint256).max);
                }
                IFeeDistributor(distributor).depositFee(address(reward), amount);
            }
        }

        amount = unclaimedSolidBonus;
        if (amount > 0) {
            // lock 5% of earned SOLID and distribute SOLIDsex to SEX lockers
            uint256 lockAmount = amount / 3;
            SOLIDsex.depositTokens(lockAmount);
            IFeeDistributor(distributor).depositFee(address(SOLIDsex), lockAmount);

            // distribute 10% of earned SOLID to SOLIDsex stakers
            amount -= lockAmount;
            SOLID.transfer(address(stakingRewards), amount);
            unclaimedSolidBonus = 0;
        }
    }

    // External guarded functions - only callable by other protocol contracts ** //

    function transferDeposit(address pool, address from, address to, uint256 amount) external returns (bool) {
        require(msg.sender == tokenForPool[pool], "Unauthorized caller");
        require(amount > 0, "Cannot transfer zero");

        address gauge = gaugeForPool[pool];
        uint256 total = totalBalances[pool];

        uint256 balance = userBalances[from][pool];
        require(balance >= amount, "Insufficient balance");
        _updateIntegrals(from, pool, gauge, balance, total);
        userBalances[from][pool] = balance - amount;

        balance = userBalances[to][pool];
        _updateIntegrals(to, pool, gauge, balance, total - amount);
        userBalances[to][pool] = balance + amount;
        emit TransferDeposit(pool, from, to, amount);
        return true;
    }

    function whitelist(address token) external returns (bool) {
        require(msg.sender == tokenWhitelister, "Only whitelister");
        require(votingEscrow.balanceOfNFT(tokenID) > solidlyVoter.listing_fee(), "Not enough veSOLID");
        solidlyVoter.whitelist(token, tokenID);
        return true;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenID,
        bytes calldata
    )external returns (bytes4) {
        // VeDepositor transfers the NFT to this contract so this callback is required
        require(_operator == address(SOLIDsex));

        if (tokenID == 0) {
            tokenID = _tokenID;
        }

        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    // ** Internal functions ** //
// solidly integration 
    function _deployDepositToken(address pool) internal returns (address token) {
        // taken from https://solidity-by-example.org/app/minimal-proxy/
        bytes20 targetBytes = bytes20(depositTokenImplementation);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            token := create(0, clone, 0x37)
        }
        IDepositToken(token).initialize(pool);
        return token;
    }

    function _updateIntegrals(
        address user,
        address pool,
        address gauge,
        uint256 balance,
        uint256 total
    ) internal {
        Amounts memory integral = rewardIntegral[pool];
        if (total > 0) {
            uint256 delta = SOLID.balanceOf(address(this));
            address[] memory rewards = new address[](1);
            rewards[0] = address(SOLID);
            IGauge(gauge).getReward(address(this), rewards);
            delta = SOLID.balanceOf(address(this)) - delta;
            if (delta > 0) {
                uint256 fee = delta * 15 / 100;
                delta -= fee;
                unclaimedSolidBonus += fee;

                integral.solid += 1e18 * delta / total;
                integral.sex += 1e18 * (delta * 10000 / 42069) / total;
                rewardIntegral[pool] = integral;
            }
        }
        if (user != address(0)) {
            Amounts memory integralFor = rewardIntegralFor[user][pool];
            if (integralFor.solid < integral.solid) {
                Amounts storage claims = claimable[user][pool];
                claims.solid += balance * (integral.solid - integralFor.solid) / 1e18;
                claims.sex += balance * (integral.sex - integralFor.sex) / 1e18;
                rewardIntegralFor[user][pool] = integral;
            }
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
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
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity 0.8.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

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

pragma solidity 0.8.11;

interface IBaseV1Voter {
    function bribes(address gauge) external view returns (address bribe);
    function gauges(address pool) external view returns (address gauge);
    function poolForGauge(address gauge) external view returns (address pool);
    function createGauge(address pool) external returns (address);
    function vote(uint tokenId, address[] calldata pools, int256[] calldata weights) external;
    function whitelist(address token, uint tokenId) external;
    function listing_fee() external view returns (uint256);
    function _ve() external view returns (address);
    function isWhitelisted(address pool) external view returns (bool);
}

pragma solidity 0.8.11;

interface IGauge {
    function deposit(uint amount, uint tokenId) external;
    function withdraw(uint amount) external;
    function getReward(address account, address[] memory tokens) external;
    function earned(address token, address account) external view returns (uint256);
}

pragma solidity 0.8.11;

interface IBribe {
    function getReward(uint tokenId, address[] memory tokens) external;
}

pragma solidity 0.8.11;

interface IVotingEscrow {
    function increase_amount(uint256 tokenID, uint256 value) external;
    function increase_unlock_time(uint256 tokenID, uint256 duration) external;
    function merge(uint256 fromID, uint256 toID) external;
    function locked(uint256 tokenID) external view returns (uint256 amount, uint256 unlockTime);
    function setApprovalForAll(address operator, bool approved) external;
    function transferFrom(address from, address to, uint256 tokenID) external;
    function safeTransferFrom(address from, address to, uint tokenId) external;
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOfNFT(uint tokenId) external view returns (uint);
    function isApprovedOrOwner(address, uint) external view returns (bool);
}

pragma solidity 0.8.11;

interface IFeeDistributor {
    function depositFee(address _token, uint256 _amount) external returns (bool);
}

pragma solidity 0.8.11;

import "../IERC20.sol";

interface ISolidexToken is IERC20 {
    function mint(address _to, uint256 _value) external returns (bool);
}

pragma solidity 0.8.11;

interface IDepositToken {
    function pool() external view returns (address);
    function initialize(address pool) external returns (bool);
    function mint(address to, uint256 value) external returns (bool);
    function burn(address from, uint256 value) external returns (bool);
}

pragma solidity 0.8.11;

import "../IERC20.sol";

interface IVeDepositor is IERC20 {
    function depositTokens(uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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