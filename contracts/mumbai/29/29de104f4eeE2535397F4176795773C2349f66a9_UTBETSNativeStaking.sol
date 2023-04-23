// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract UTBETSNativeStaking is Ownable {

    uint256 public immutable STARTDATE;
    uint256 public immutable ENDDATE;
    // Info of each pool instance when a new pool is created.
    struct PoolInfo {
        uint256 LastUpdateTime; //last update time of pool
        uint256 RewardPerSec; // amount of UTBETS token for reward per sec on this pool
        uint256 PoolRewardRate; // rate of reward token per each lp token : updated each time when user stake or unstake.
        uint256 TotalStakedAmount; // total tokens staked by all users
    }

    //stake info
    struct StakeInfo {
        uint256 RewardRate; //reward token amount per one lp token for a specified time interval when start to stake
        uint256 DepositAmount; // deposit lp token amount
        uint256 ClaimableAmount; // claimable UTBETS token amount
    }

    event Stake(address _holder, uint256 _amount);
    event UnStake(address _holder, uint256 _amount);
    event Claim(address _holder, uint256 _amount);

    PoolInfo Pool;
    mapping(address => StakeInfo) StakeOfAddress; // stake info of address

    address public LPToken;
    address public UTBETS;

    constructor(address lptoken, address utbets, uint256 startDate) {
        LPToken = lptoken;
        UTBETS = utbets;
        STARTDATE = startDate;
        ENDDATE = startDate + 365 days;
        createPool();
    }

    function createPool() internal {
        Pool = PoolInfo(0, 0.396 ether, 0, 0);
    }

    function setUTBETS(address _utbets) public onlyOwner {
        UTBETS = _utbets;
    }

    function setLPToken(address _lptoken) public onlyOwner {
        LPToken = _lptoken;
    }

    function stake(uint256 _amount) public {
        require(block.timestamp >= STARTDATE, "Wait...");
        require(block.timestamp <= ENDDATE, "Pool is down for now!");
        require(
            IERC20(LPToken).balanceOf(msg.sender) >= _amount,
            "You don't have enough lp token for staking."
        );
        require(
            IERC20(LPToken).allowance(msg.sender, address(this)) >= _amount,
            "Not enough allowance!"
        );
        IERC20(LPToken).transferFrom(msg.sender, address(this), _amount);

        StakeOfAddress[msg.sender].DepositAmount += _amount;
        StakeOfAddress[msg.sender].ClaimableAmount = claimableAmount(msg.sender);

        updatePoolRewardRate();
        StakeOfAddress[msg.sender].RewardRate = Pool.PoolRewardRate;

        Pool.TotalStakedAmount += _amount;

        emit Stake(msg.sender, _amount);
    }

    function updatePoolRewardRate() internal {
        Pool.LastUpdateTime = Pool.LastUpdateTime == 0
            ? block.timestamp
            : Pool.LastUpdateTime;

        uint256 rewardRate = poolNewRewardRate();
        Pool.PoolRewardRate += rewardRate;
        Pool.LastUpdateTime = block.timestamp > ENDDATE ? ENDDATE : block.timestamp;
    }

    function poolNewRewardRate() public view returns (uint256) {
        uint256 claimTime = block.timestamp > ENDDATE ? ENDDATE : block.timestamp;
        uint256 poolRewardTime = claimTime - Pool.LastUpdateTime;
        uint256 poolReward = poolRewardTime * Pool.RewardPerSec;
        uint256 rewardRate = Pool.TotalStakedAmount == 0
            ? 0
            : poolReward / Pool.TotalStakedAmount;
        return rewardRate;
    }

    function unStake(uint256 _amount) public {
        uint256 amount = StakeOfAddress[msg.sender].DepositAmount;
        require(_amount <= amount, "You don't have enough LP to unstake.");
        claim();
        Pool.LastUpdateTime = block.timestamp;
        Pool.TotalStakedAmount -= amount;
        IERC20(LPToken).transfer(msg.sender, amount);
        StakeOfAddress[msg.sender].DepositAmount -= _amount;
        emit UnStake(msg.sender, amount);
    }

    function claim() public {
        require(
            StakeOfAddress[msg.sender].DepositAmount > 0,
            "You have no stake with that id"
        );
        uint256 claimAmount = claimableAmount(msg.sender);
        updatePoolRewardRate();
        StakeOfAddress[msg.sender].RewardRate = Pool.PoolRewardRate;
        StakeOfAddress[msg.sender].ClaimableAmount = 0;

        IERC20(UTBETS).transfer(msg.sender, claimAmount);

        emit Claim(msg.sender, claimAmount);
    }

    function claimableAmount(address _holder) public view returns (uint256) {
        uint256 rewardRate = Pool.PoolRewardRate +
            poolNewRewardRate() -
            StakeOfAddress[_holder].RewardRate;
        return StakeOfAddress[_holder].ClaimableAmount + rewardRate * StakeOfAddress[_holder].DepositAmount;
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