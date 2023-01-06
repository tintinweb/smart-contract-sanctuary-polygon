// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lottery is Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;    
        
    struct Syndicate {
        string name;
        uint256 lotteryType;
        uint256 ticketPrice;
        uint256 multiplier;
        uint256 tableFee;
        uint256 expiryTime;
        uint256[] winningNumbers;
        address[] players;
        mapping (address => uint256[]) ticketsByPlayer;
        mapping (uint256 => uint256[]) ticketDetails;
        Counters.Counter _ticketCount;
    }
        
    mapping (uint256 => Syndicate) public syndicateDetails;        
    Counters.Counter public _syndicateCount;
    IERC20 GOLD;

    constructor(address _kjl) {
	    setGold(_kjl);
	}    

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function setGold(address _gold) public onlyOwner {
        GOLD = IERC20(_gold);
    }

    function addSyndicate(string memory _name, uint256 _lotteryType, uint256 _ticketPrice, uint256 _multiplier, uint256 _tableFee, uint256 _expiryTime) public onlyOwner {
        require(keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")), "The syndicate name can't be blank." );
        require(_lotteryType >= 2 && _lotteryType <= 5, "Lottery types should be one 2 to 5." );
        require(_ticketPrice != 0, "Ticket Price can't be 0." );
        require(_multiplier != 0, "Multipler can't be 0." );
        require(_tableFee != 0, "Table Fee can't be 0." );

        uint256 totalSyndicatesCount = _syndicateCount.current();
        Syndicate storage _syndicate = syndicateDetails[totalSyndicatesCount];
        
        _syndicate.name = _name;
        _syndicate.lotteryType = _lotteryType;
        _syndicate.ticketPrice = _ticketPrice;
        _syndicate.multiplier = _multiplier;
        _syndicate.tableFee = _tableFee;
        _syndicate.expiryTime = _expiryTime;

        _syndicateCount.increment();
    }

    function joinSyndicate(uint256 _syndicateId, uint256[] memory _numbers) public {
        uint256 totalSyndicatesCount = _syndicateCount.current();
        require(_syndicateId < totalSyndicatesCount, "This syndicate doesn't exist." );

        Syndicate storage _syndicate = syndicateDetails[_syndicateId];
        require(_syndicate.lotteryType == _numbers.length, "The numbers count should be the same." );
        
        require(_syndicate.expiryTime > block.timestamp, "This syndicate is finished already." );

        uint256 balance = GOLD.balanceOf(msg.sender);
        require(balance >= _syndicate.ticketPrice, "Insufficient balance for buying a ticket.");
        GOLD.transferFrom(msg.sender, address(this), _syndicate.ticketPrice);

        if(_syndicate.ticketsByPlayer[msg.sender].length == 0) {
            _syndicate.players.push(msg.sender);            
        }

        uint256 totalTicketsCount = _syndicate._ticketCount.current();
        _syndicate.ticketsByPlayer[msg.sender].push(totalTicketsCount);
        for (uint256 i = 0; i < _numbers.length; i++) {
            _syndicate.ticketDetails[totalTicketsCount].push(_numbers[i]);
        }
        _syndicate._ticketCount.increment();
    }

    function setWinningTicketNumbers(uint256 _syndicateId, uint256[] memory _numbers) public onlyOwner {
        uint256 totalSyndicatesCount = _syndicateCount.current();
        require(_syndicateId < totalSyndicatesCount, "This syndicate doesn't exist." );

        Syndicate storage _syndicate = syndicateDetails[_syndicateId];
        require(_syndicate.lotteryType == _numbers.length, "The numbers count should be the same." );

        for (uint256 i = 0; i < _numbers.length; i++) {
            _syndicate.winningNumbers.push(_numbers[i]);
        }
    }

    function finishSyndicate(uint256 _syndicateId) public onlyOwner {
        uint256 totalSyndicatesCount = _syndicateCount.current();
        require(_syndicateId < totalSyndicatesCount, "This syndicate doesn't exist." );

        Syndicate storage _syndicate = syndicateDetails[_syndicateId];        
        require(_syndicate.winningNumbers.length > 0, "No winning ticket is inputed." );

        uint256 _ticketCount = _syndicate._ticketCount.current();
        for(uint256 i = 0; i < _ticketCount; i++) {
            uint256[] storage ticket = _syndicate.ticketDetails[i];
            uint256 sameNumbersCount = 0;

            for(uint256 j = 0; j < _syndicate.winningNumbers.length; j++) {
                if(ticket[j] == _syndicate.winningNumbers[j]) {
                    sameNumbersCount++;
                }                
            }
            
            if(sameNumbersCount == _syndicate.winningNumbers.length) { // winner
                uint256 totalWinningSum = _syndicate.multiplier * _syndicate.ticketPrice;
                for(uint256 j = 0; j < _syndicate.players.length; j++) {
                    address player = _syndicate.players[j];
                    uint256 tableFee = ( totalWinningSum * _syndicate.tableFee ) / 100;
                    uint256 rewardAmount = _syndicate.ticketsByPlayer[player].length * ( totalWinningSum - tableFee ) / _ticketCount;
                    GOLD.transfer(player, rewardAmount);
                }
            }
        }
    }    

    function getSyndicateName(uint256 _syndicateId) public view returns(string memory) {
        return syndicateDetails[_syndicateId].name;
    }

    function getSyndicateLotteryType(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId].lotteryType;
    }

    function getSyndicateTicketPrice(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId].ticketPrice;
    }

    function getSyndicateMultiplier(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId].multiplier;
    }

    function getSyndicateTableFee(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId].tableFee;
    }

    function getSyndicateExpiryTime(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId].expiryTime;
    }

    function getSyndicateWinningNumbers(uint256 _syndicateId) public view returns(uint256[] memory) {
        return syndicateDetails[_syndicateId].winningNumbers;
    }

    function getSyndicatePlayers(uint256 _syndicateId) public view returns(address[] memory) {
        return syndicateDetails[_syndicateId].players;
    }

    function getSyndicateTicketsByPlayer(uint256 _syndicateId, address player) public view returns(uint256[] memory) {
        return syndicateDetails[_syndicateId].ticketsByPlayer[player];
    }

    function getSyndicateTicketDetails(uint256 _syndicateId, uint256 _ticketId) public view returns(uint256[] memory) {
        return syndicateDetails[_syndicateId].ticketDetails[_ticketId];
    }

    function getSyndicateTicketsCount(uint256 _syndicateId) public view returns(uint256) {
        return syndicateDetails[_syndicateId]._ticketCount.current();
    }

    function withdrawAllTokens(address _address) public onlyOwner {
        uint256 balance = GOLD.balanceOf(address(this));
        require(balance > 0);
        GOLD.transfer(_address, balance);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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