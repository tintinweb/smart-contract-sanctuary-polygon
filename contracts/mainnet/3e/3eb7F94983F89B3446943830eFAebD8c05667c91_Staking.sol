/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/CallerStaking.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



contract Staking is Ownable {
    address token;

    uint256 constant public BASE_RATE_ACCURACY = 100;
    uint256 public BASE_RATE = 1;
    uint256 public TIME_RATE = 60;
	// Tue Mar 18 2031 17:46:47 GMT+0000
	uint256 public END = 1931622407;
    mapping(address => uint256) staked;
    mapping(address => uint256) public rewards;
	mapping(address => uint256) public lastUpdate;
    uint256 public availablePool;

    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _token) {
        token = _token;
    }

    function changeBaseRate(uint256 newBaseRate) public onlyOwner {
        BASE_RATE = newBaseRate;
    }

    function changeTimeRate(uint256 newTimeRate) public onlyOwner {
        TIME_RATE = newTimeRate;
    }

    function changeEndTime(uint256 newEndTime) public onlyOwner {
        END = newEndTime;
    }

    function fillUpPool(uint256 amount) public onlyOwner {
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        availablePool += amount;
    }
    
    function userBalance(address _user) public view returns (uint256) {
        return IERC20(token).balanceOf(_user) + staked[_user];
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

    function getNewReward(address _user) internal view returns (uint256) {
        uint256 time = min(block.timestamp, END);
		uint256 timerUser = lastUpdate[_user];
		uint256 result = 0;
        if (timerUser > 0)
			result = rewards[_user] + staked[_user] * BASE_RATE * ((time - timerUser) / (TIME_RATE)) / BASE_RATE_ACCURACY;
        else
            result = rewards[_user];
        result = min(availablePool, result);
        return result;
    }

    function userUnstakeBalance(address _user) public view returns (uint256) {
        return getNewReward(_user) + staked[_user];
    }

    function calculateNewReward(address _user) public{
		uint256 time = min(block.timestamp, END);
        rewards[_user] = getNewReward(_user);
		lastUpdate[_user] = time;
	}


	function unstake() external {
        calculateNewReward(msg.sender);
		uint256 reward = rewards[msg.sender];
		if (reward > 0) {
            require(availablePool >= reward, "Not enough tokens in pool");
            availablePool -= reward;
			rewards[msg.sender] = 0;
		}
        uint256 toUnstake = staked[msg.sender] + reward;
        staked[msg.sender] = 0;

        require(IERC20(token).transferFrom(address(this), msg.sender, toUnstake));
        
	}

    function stake(uint256 amount) external{
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "Transfer failed");
        staked[msg.sender] += amount;
        calculateNewReward(msg.sender);
    } 

}