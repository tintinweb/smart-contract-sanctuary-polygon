// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EscrowTrade is Ownable, ReentrancyGuard{
    using SafeMath for uint;
    using Counters for Counters.Counter;
    Counters.Counter public totalTrades;

    enum Status{
        pending,processing,shipped,cancelled,completed,disputed,waiting
    }

    struct Trade {
        address buyer;
        address seller;
        address tokenAddress;
        uint amount;
        uint createdAt;
        uint updatedAt;
        Status status;
        string offerId;
    }

    mapping (uint => Trade) public trades;

    uint public feeInPercent = 25;
    uint public percentFraction = 1000;

    uint minimumWaitingPeriod = uint(7 days);

    event TradeCreated(
        uint tradeID,
        address seller,
        address buyer,
        uint amount,
        address tokenContractAddress
    );

    event TradeUpdated(
        uint indexed tradeID,
        Status status
    );


    // Public functions
    
    // Seller : Who sells items for ETH or ERC20 token   
    // Buyer : Who Buys items by ETH or ERC20 token


    constructor () {}


    // @ Method :Trade create
    // @ Description: Seller will create a trade for a buyer
    // @ Params : Buyer Address, Amount (token amount * decimals) , token contract Address

    function createTrade(
        string memory _offerID,
        address _buyer,
        uint _amount,
        address _tokenAddress
    ) external {
        require(_amount > 0,"Amount must be greater than zero");
        require(_buyer != address(0), "Buyer must be an valid address");
        totalTrades.increment();
        uint currentID = totalTrades.current();
        trades[currentID] = Trade({
                buyer : _buyer,
                seller : msg.sender,
                tokenAddress : _tokenAddress,
                amount : _amount,
                createdAt : block.timestamp,
                updatedAt : block.timestamp,
                offerId : _offerID,
                status : Status.pending
            });

        emit TradeCreated(currentID, msg.sender, _buyer, _amount, _tokenAddress);
    }

    // Buyer will deposit and create the trade

    function createTradeByBuyer(
        string memory _offerID,
        address _seller,
        uint _amount,
        address _tokenAddress
    ) external payable {
        require(_amount > 0,"Amount must be greater than zero");
        require(_seller != address(0), "Seller must be an valid address");


        if(_tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(_tokenAddress).transferFrom(msg.sender,address(this),_amount);
        }else{
            // transfer ether to this contract
            require(msg.value >= _amount, "msg.value is less than the actual amount");
        }

        totalTrades.increment();
        uint currentID = totalTrades.current();

         trades[currentID] = Trade({
                buyer : msg.sender,
                seller : _seller,
                tokenAddress : _tokenAddress,
                amount : _amount,
                createdAt : block.timestamp,
                updatedAt : block.timestamp,
                offerId : _offerID,
                status : Status.processing
            });
        emit TradeCreated(currentID, _seller, msg.sender, _amount, _tokenAddress);
        emit TradeUpdated(currentID, Status.processing);
    }

    // Start Trade by Buyer , if seller created the a trade.

    function startTradeByBuyer(
        uint _tradeID
    ) external payable {

        Trade memory trade = trades[_tradeID];

        require(trade.amount > 0,"Amount must be greater than zero");
        require(trade.buyer == msg.sender, "You are not buyer");
        require(trade.status == Status.pending, "Trade is not pending");

        if(trade.tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(trade.tokenAddress).transferFrom(msg.sender,address(this),trade.amount);
        }else{
            // transfer ether to this contract
            require(msg.value >= trade.amount, "msg.value is less than the actual amount");
        }

        trades[_tradeID].status = Status.processing;
        trades[_tradeID].updatedAt = block.timestamp;
        emit TradeUpdated(_tradeID, Status.processing);
    }


    // Mark as Shipped / Delivered , Seller should call this function to mark the order as shipped

    function markAsShipped(uint _tradeID) external {
        Trade memory trade = trades[_tradeID];

        require(trade.seller == msg.sender, "You are not seller");
        require(trade.status == Status.processing, "Trade is not in processing");

        trades[_tradeID].status = Status.shipped;
        trades[_tradeID].updatedAt = block.timestamp;

        emit TradeUpdated(
            _tradeID,
            Status.shipped
        );
    }


    // Complete the trade by buyer 

    function completeTradeByBuyer(uint _tradeID) external nonReentrant {
        Trade memory trade = trades[_tradeID];
        require(trade.buyer == msg.sender, "You are not buyer");
        require(trade.status == Status.processing || trade.status == Status.shipped, "Trade is not started or shipped");

        trades[_tradeID].status = Status.completed;
        trades[_tradeID].updatedAt = block.timestamp;

        // Calculate the seller amount and fee

        uint fee = escrowFee(trade.amount);
        uint sellerAmount = trade.amount - fee;

        if(trade.tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(trade.tokenAddress).transfer(trade.seller,sellerAmount);
            IERC20(trade.tokenAddress).transfer(owner(),fee);

        }else{
            payable(trade.seller).transfer(sellerAmount);
            payable(owner()).transfer(fee);
        }

        emit TradeUpdated(_tradeID, Status.completed);
    }


    function dispute(uint _tradeID) external {
        Trade memory trade = trades[_tradeID];
        require(trade.status == Status.processing || trade.status == Status.shipped, "Trade is not processing nor shipped");
        require(trade.buyer == msg.sender || trade.seller == msg.sender, "You are not buyer nor seller");
        trades[_tradeID].status = Status.disputed;
        trades[_tradeID].updatedAt = block.timestamp;

        emit TradeUpdated(_tradeID, Status.disputed);
    }


    function cancelByAdmin(uint _tradeID) external nonReentrant {
        Trade memory trade = trades[_tradeID];
        require(trade.status == Status.disputed, "Trade is not disputed");
        trades[_tradeID].status = Status.cancelled;
        trades[_tradeID].updatedAt = block.timestamp;

        // Back the amount to buyer 

        if(trade.tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(trade.tokenAddress).transfer(trade.buyer,trade.amount);
        }else{
            payable(trade.buyer).transfer(trade.amount);
        }

        emit TradeUpdated(_tradeID, Status.cancelled);
    }

    function completeByAdmin(uint _tradeID) external nonReentrant {
        Trade memory trade = trades[_tradeID];
        require(trade.status == Status.disputed, "Trade is not disputed");
        trades[_tradeID].status = Status.completed;
        trades[_tradeID].updatedAt = block.timestamp;

        // Calculate the seller amount and fee

        uint fee = escrowFee(trade.amount);
        uint sellerAmount = trade.amount - fee;

        // Transfer the amount to seller

        if(trade.tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(trade.tokenAddress).transfer(trade.seller,sellerAmount);
            IERC20(trade.tokenAddress).transfer(owner(),fee);

        }else{
            payable(trade.seller).transfer(sellerAmount);
            payable(owner()).transfer(fee);
        }
        emit TradeUpdated(_tradeID, Status.completed);
    }

    function cancelByBuyer(uint _tradeID) external nonReentrant {
        Trade memory trade = trades[_tradeID];
        require(trade.status == Status.processing, "Trade is not processing");
        require(trade.updatedAt + minimumWaitingPeriod <= block.timestamp, "Minimum waiting period not passed");
        trades[_tradeID].status = Status.cancelled;
        // Back the amount to buyer 
        if(trade.tokenAddress != address(0)) {
            // transfer erc20 token to this contract
            IERC20(trade.tokenAddress).transfer(trade.buyer,trade.amount);
        }else{
            payable(trade.buyer).transfer(trade.amount);
        }

        emit TradeUpdated(_tradeID, Status.cancelled);
    }

    function escrowFee(uint256 amount)
        private view returns(uint256) {
        uint256 x = amount.mul(feeInPercent);
        uint256 adminFee = x.div(percentFraction);
        return adminFee;
    }
    
    
    // Admin function 
    function changeFee(uint fee, uint fraction)
        external onlyOwner() 
    {
        feeInPercent = fee;
        percentFraction = fraction;
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