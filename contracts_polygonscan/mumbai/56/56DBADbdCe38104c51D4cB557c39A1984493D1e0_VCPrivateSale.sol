/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

pragma solidity ^0.8.0;


// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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
    function transferFrom(
        address sender,
        address recipient,
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


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
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


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)
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


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)
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


contract VCPrivateSale is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /* the maximum amount of tokens to be sold */
	uint256 public constant maxGoal = 2350000 * (10**18);
	/* how much has been raised by retail investors (in USDC) */
	uint256 public amountRaisedUSDC;
	/* how much has been raised by retail investors (in #DG) */
	uint256 public amountRaisedDG;

	/* the start & end date of the private sale */
	uint256 public startTime;
	uint256 public endTime;
	uint256 public lockTime;

	/* the price per #DG (in USDC) */
	/* there are different prices in different time intervals */
	uint256 public constant firstPrice = 7 * 10**5;
	uint256 public constant secondPrice = 9 * 10**5;
	uint256 public constant thirdPrice = 11 * 10**5;

	address private USDC_ADDRESS;

	/* the address of the token contract */
	IERC20 private tokenReward;
	/* the address of the usdc token */
	IERC20 private usdc;

	/* indicates if the private sale has been closed already */
	bool public presaleClosed = false;
	/* the balances (in USDC) of all investors */
	mapping(address => uint256) public balanceOfUSDC;
	/* the balances (in #DG) of all investors */
	mapping(address => uint256) public balanceOfDG;
	/* the total balances (in #DG) of all investors */
	mapping(address => uint256) public totalBalanceOfDG;
	/* notifying transfers and the success of the private sale*/
	mapping(uint256 => address) public investers;
	uint256 public invester_count;
	event GoalReached(address beneficiary, uint256 amountRaisedUSDC);
	event FundTransfer(address backer, uint256 amountDG, uint256 amountUSDC, bool isContribution, uint256 amountRaisedUSDC, uint256 amountRaisedDG);

    /*  initialization, set the token address */
    constructor(IERC20 _token, uint256 _startTime, uint256 _endTime, address _USDC_ADDRESS) {
        tokenReward = _token;
		startTime = _startTime;
		endTime = _endTime;
		lockTime = _endTime + 600;
		USDC_ADDRESS = _USDC_ADDRESS;
		usdc = IERC20(USDC_ADDRESS);
		invester_count = 0;
    }

	function checkFunds(address addr) external view returns (uint256) {
		return balanceOfUSDC[addr];
	}

	function checkDataGenFunds(address addr) external view returns (uint256) {
		return balanceOfDG[addr];
	}

	function checkDataGenTotalFunds(address addr) external view returns (uint256) {
		return totalBalanceOfDG[addr];
	}

    /* make an investment
     * only callable if the private sale started and hasn't been closed already and the maxGoal wasn't reached yet.
     * the current token price is looked up and the corresponding number of tokens is transfered to the receiver.
     * the sent value is directly forwarded to a safe multisig wallet.
     * this method allows to purchase tokens in behalf of another address. 
     */
    function invest(uint256 amountDG) external {
		require(presaleClosed == false && block.timestamp >= startTime && block.timestamp < endTime, "Presale is closed");
		require(amountDG >= 20000 * (10 ** 18), "Fund is less than 20.000,00 DGT");
		require(amountDG <= 2350000 * (10 ** 18), "Fund is more than 2.350.000,00 DGT");

		uint256 amountUSDC;
		
		/* the amount of the first discounted tokens */
		uint256 discountLimit1 = 300000 * (10**18);

		/* the amount of the first discounted tokens */
		uint256 discountLimit2 = 1300000 * (10**18);

		if (amountRaisedDG + amountDG <= discountLimit1) {
			amountUSDC = amountDG.mul(firstPrice).div(10**18);
		} else if (amountRaisedDG >= discountLimit2) {
			amountUSDC = amountDG.mul(thirdPrice).div(10**18);
		} else if (amountRaisedDG >= discountLimit1 && amountRaisedDG + amountDG <= discountLimit2) {
			amountUSDC = amountDG.mul(secondPrice).div(10**18);
		} else if (amountRaisedDG <= discountLimit1 && amountRaisedDG + amountDG <= discountLimit2) {
			uint256 amountSecondPrice = (amountRaisedDG + amountDG) - discountLimit1;
			uint256 amountFirstPrice = (amountDG - amountSecondPrice).mul(firstPrice).div(10**18);
			amountSecondPrice = amountSecondPrice.mul(secondPrice).div(10**18);
			amountUSDC = amountSecondPrice + amountFirstPrice;
		} else if (amountRaisedDG >= discountLimit1 && amountRaisedDG <= discountLimit2) {
			uint256 amountThirdPrice = (amountRaisedDG + amountDG) - discountLimit2;
			uint256 amountSecondPrice = (amountDG - amountThirdPrice).mul(secondPrice).div(10**18);
			amountThirdPrice = amountThirdPrice.mul(thirdPrice).div(10**18);
			amountUSDC = amountSecondPrice + amountThirdPrice;
		} else if (amountRaisedDG <= discountLimit1 && amountDG >= discountLimit2) {
			uint256 amountThirdPrice = (amountRaisedDG + amountDG) - discountLimit2;
			uint256 amountSecondPrice = (10**24);
			uint256 amountFirstPrice = (amountDG - amountRaisedDG - amountThirdPrice - amountSecondPrice).mul(firstPrice).div(10**18);

			amountSecondPrice = amountSecondPrice.mul(secondPrice).div(10**18);
			amountThirdPrice = amountThirdPrice.mul(thirdPrice).div(10**18);
			amountUSDC = amountFirstPrice + amountSecondPrice + amountThirdPrice;
		}

		usdc.transferFrom(msg.sender, address(this), amountUSDC);

		if( totalBalanceOfDG[msg.sender] == 0 ) {
			investers[invester_count] = msg.sender;
			invester_count++;
		}

		balanceOfUSDC[msg.sender] = balanceOfUSDC[msg.sender].add(amountUSDC);
		amountRaisedUSDC = amountRaisedUSDC.add(amountUSDC);

		balanceOfDG[msg.sender] = balanceOfDG[msg.sender].add(amountDG);
		totalBalanceOfDG[msg.sender] = balanceOfDG[msg.sender];
		amountRaisedDG = amountRaisedDG.add(amountDG);

		if (amountRaisedDG >= maxGoal) {
			presaleClosed = true;
			emit GoalReached(msg.sender, amountRaisedUSDC);
		}
		
        emit FundTransfer(msg.sender, amountDG, amountUSDC, true, amountRaisedUSDC, amountRaisedDG);
    }

    modifier afterClosed() {
        require(block.timestamp >= endTime, "Distribution is off.");
        _;
    }

	function claimDataGen() external afterClosed nonReentrant onlyOwner {
		for( uint256 i = 0; i < invester_count; i++ ) {
			address invester = investers[i];
			if( totalBalanceOfDG[invester] <= 0 ) continue;

			uint256 epochs = 0;
			uint256 amount = 0;
			uint256 maxAmount = 0;
			if (block.timestamp < lockTime) {
				maxAmount = totalBalanceOfDG[invester].div(10);
				amount = maxAmount.sub(totalBalanceOfDG[invester].sub(balanceOfDG[invester]));
			} else {
				epochs = block.timestamp.sub(lockTime).div(600).add(1);
				if (epochs > 10) epochs = 10;
				
				maxAmount = (totalBalanceOfDG[invester] - totalBalanceOfDG[invester].div(10)).mul(epochs).div(10);
				amount = maxAmount.sub((totalBalanceOfDG[invester] - totalBalanceOfDG[invester].div(10)).sub(balanceOfDG[invester]));
			}
			
		
			uint256 balance = tokenReward.balanceOf(address(this));
			if( balance < amount ) continue;

			balanceOfDG[invester] = balanceOfDG[invester].sub(amount);
			tokenReward.transfer(invester, amount);
		}
	}

	function withdrawUSDC() external onlyOwner {
		uint256 balance = usdc.balanceOf(address(this));
		require(balance > 0, "Balance is zero.");
		usdc.transfer(owner(), balance);
	}

	function withdrawDataGen() external onlyOwner afterClosed{
		uint256 balance = tokenReward.balanceOf(address(this));
		require(balance > 0, "Balance is zero.");
		tokenReward.transfer(owner(), balance);
	}
}