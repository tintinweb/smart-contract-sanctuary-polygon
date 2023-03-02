/**
 *Submitted for verification at polygonscan.com on 2023-03-01
*/

/**
 *Submitted for verification at polygonscan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// File: metamastermlm_flat.sol




// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
pragma solidity ^0.8.0;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.0;


contract MetaMaster is Ownable {

    using SafeMath for uint256;
    
    address public creator;

    uint256 public depositCount;
    uint256 public lastWithdrawal;
    uint256 public withdrawalInterval = 15 days;


	uint256[] public REFERRAL_PERCENTS = [200, 100, 50, 30, 20, 15, 15, 15, 15, 15, 10, 10, 10, 10, 10];
	uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public oneTimeCommissionPercent = 50;
    uint256 constant public depositTax = 20;
    uint256 constant public withdrawTax = 50;

    struct Deposit {
        uint256 depositID;
        address userAddress;
        uint256 depositAmount;
        uint256 depositedTimeStamp;
        uint256 maxRewardLimit;
    }

    struct User {
		Deposit[] deposits;
		address referrer;
		uint256[15] levels;
		uint256 bonus;
        uint256 directIncome;
	}

    struct Referral {
        address referrer;
        address userAddress;
        uint256 amountDeposited;
    }

	mapping (address => User) public users;
    mapping (address => uint256) public amountWithdrawn;
    mapping (address => Referral[]) public userTeams;
    mapping (address => Deposit[]) public userDeposit;

    address constant public USDTAddress = 0xd64cb49E1DBFcCE67ba6Cd528083d2522aFB1B8B;

    constructor(address _creator) {
        creator = _creator;
    }

    function deposit(uint256 _USDTAmount, address _referrer) public {
        require(_USDTAmount % 50000000 == 0 && _USDTAmount >= 50000000 && _USDTAmount <= 5000000000 , "Invalid USDT Amount");
        depositCount = depositCount + 1;
        uint256 maxLimit = 2000;
        User storage user = users[msg.sender];

		if (user.referrer == address(0)) {        
			if (users[_referrer].deposits.length > 0 && _referrer != msg.sender) {
				user.referrer = _referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 15; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
            userTeams[_referrer].push(Referral(_referrer, msg.sender, _USDTAmount));
			for (uint256 i = 0; i < 15; i++) {
				if (upline != address(0)) {
					uint256 amount = _USDTAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

        if(userTeams[user.referrer].length ==4){
            getRefund(user.referrer);
        }

		uint256 maxRewardLimit = _USDTAmount.mul(maxLimit).div(PERCENTS_DIVIDER);
		user.deposits.push(Deposit(depositCount, msg.sender, _USDTAmount, block.timestamp, maxRewardLimit));
        // Deposit token
        uint256 creatorTax = _USDTAmount.mul(depositTax).div(PERCENTS_DIVIDER);
        uint256 depositAmount = _USDTAmount.sub(creatorTax);

        IERC20(USDTAddress).transferFrom(msg.sender, address(this), depositAmount);
        IERC20(USDTAddress).transferFrom(msg.sender, creator, creatorTax);
    }

    function getRefund(address _userAddress) public {
        User memory user = users[_userAddress];
        //require
        // require(msg.sender == _userAddress, "Caller should be the owner of account");
        if (user.deposits[0].depositedTimeStamp <= user.deposits[0].depositedTimeStamp + 20 minutes && userTeams[_userAddress].length == 4 && user.referrer != address(0)){
            IERC20(USDTAddress).transfer(_userAddress, user.deposits[0].depositAmount);
            }
    }

    //daily roi
    function getUserTotalROI(address _userAddress) public view returns(uint256){
        uint256 dailyRewardPercentage = 5;
        uint256 percentageDivider = 1000;
        uint256 totalReward = 0;
        for(uint8 i = 0; i < users[_userAddress].deposits.length; i++) {
            uint256 reward;
            uint256 numberOfDays = block.timestamp.sub(users[_userAddress].deposits[i].depositedTimeStamp).div(1 minutes);
            uint256 dailyrewardAmount = users[_userAddress].deposits[i].depositAmount.mul(dailyRewardPercentage).div(percentageDivider);
            reward = numberOfDays * dailyrewardAmount;
            if(reward >= users[_userAddress].deposits[i].maxRewardLimit) {
                reward = users[_userAddress].deposits[i].maxRewardLimit;
            }
            totalReward = totalReward + reward; 
        }
        return totalReward;
    }


    function withdraw(address _userAddress, uint256 _amount) public {
        // uint256 getTime = block.timestamp;
        require(msg.sender == _userAddress, "Caller should be the owner of withdraw account");
        require(balanceAfterWithdrawal(_userAddress) >= _amount,"Amount is greater than withdrawal balance amount");
        require(_amount >= 10,"The Amount should be greater than 10 USDT");
        // require(getTime >= lastWithdrawal + withdrawalInterval, "Cannot withdraw before the interval has passed."   );
        
        // lastWithdrawal = getTime;
        
        amountWithdrawn[_userAddress] += _amount;
        
        // uint256 creatorTax = _amount.mul(withdrawTax).div(PERCENTS_DIVIDER);
        // uint256 withdrawAmount = _amount.sub(creatorTax);

        IERC20(USDTAddress).transfer(msg.sender, _amount);
        // IERC20(USDTAddress).transfer(creator, creatorTax);
    }

    function getUserTotalDeposit(address _userAddress) public view returns(uint256) {
        User memory user = users[_userAddress];
        uint256 userTotalDeposit;
        for(uint256 i = 0; i < user.deposits.length; i++) {
            userTotalDeposit = userTotalDeposit + user.deposits[i].depositAmount;
        }
        return userTotalDeposit;
    }

    function getUserTotalLevelIncome(address _userAddress) public view returns(uint256) {
        User memory user = users[_userAddress];
        return user.bonus;
    }

    function getUserTeamCount(address _userAddress) public view returns(uint256) {
        return userTeams[_userAddress].length;
    }

    // function getUserDirectIncome(address _userAddress) public view returns(uint256) {
    //     User memory user = users[_userAddress];
    //     return user.directIncome;
    // }
    
    function getUserTotalEarning(address _userAddress) public view returns(uint256){
        return getUserTotalLevelIncome(_userAddress) + getUserTotalReturns(_userAddress);
    }

    function balanceAfterWithdrawal(address _userAddress) public view returns(uint256){
        return getUserTotalEarning(_userAddress).sub(amountWithdrawn[_userAddress]);
    }

    function getUserPendingBonus(address _userAddress) public view returns(uint256){
        uint256 maxLimit = 2000;
        return (getUserTotalDeposit(_userAddress).mul(maxLimit).div(PERCENTS_DIVIDER)).sub(getUserTotalReturns(_userAddress));
    }

    function userFirstDeposit(address _userAddress) public view returns(uint256,uint256){
        User memory user = users[_userAddress];
        return (user.deposits[0].depositedTimeStamp,user.deposits[0].depositAmount);
    }

    function getUserTotalReturns(address _userAddress) public view returns(uint256){
        // User memory user = users[_userAddress];
        uint256 reward;
        for(uint8 i = 0; i < users[_userAddress].deposits.length; i++) {
            reward = getUserTotalROI(_userAddress).add(getUserTotalLevelIncome(_userAddress));
            if(reward >= users[_userAddress].deposits[i].maxRewardLimit) {
                // reward = users[_userAddress].deposits[i].maxRewardLimit;
                reward = getUserTotalROI(_userAddress).add(getUserTotalLevelIncome(_userAddress));
            }
        }
        return reward;
    }
}