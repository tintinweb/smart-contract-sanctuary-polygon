// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./SBT.sol";

contract Event is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    SBT public sbt;

    string public nameEvent;

    uint32 public maxTickets;
    uint32 public ticketsAvailable; 
    uint64 public ticketPrice;
    uint128 public globalScore; 
    uint256 public totalEarned; 

    mapping(address => mapping(uint256 =>SBT.Soul)) private soldTickets; //address => tickets SBT
    
    mapping(uint256 => SBT.Soul) public canceledTickets; //Tickets that have been canceled
    mapping(address => uint256) private allowedToBuyTicket;

    event PurchasedTicket();
    event SoldTicket(address indexed buyer, uint256 score);
    event ResellTicket(address indexed oldOwner, address indexed buyer, uint256 score);
    event CanceledTicket(address indexed buyer, uint256 score);
    event validatedTicket(address indexed buyer);

    constructor(
        uint32 _maxTickets,
        uint16 _ticketPrice,
        string memory _nameEvent,
        string memory _symbolEvent
    ){
        maxTickets = _maxTickets;
        ticketPrice = _ticketPrice;
        ticketsAvailable = _maxTickets;
        globalScore = 0;
        nameEvent = _nameEvent;        
        sbt = new SBT(_nameEvent, _symbolEvent);
    }
     
    function buyTickets(address buyer, uint256 quantity) public payable nonReentrant {
        require(quantity > 0, "Quantity must be greater than zero");
        require(allowedToBuyTicket[buyer] >= quantity, "You have to pay the previous ticket first");
        require(ticketsAvailable >= quantity, "Not enough tickets available");
        
        for (uint256 i = 0; i < quantity;) {
            buyTicket(buyer);
            unchecked {
                i++;
            }
        }
    }

    function buyTicket(address _buyer) public payable nonReentrant {
        require(msg.sender == _buyer, "You can only buy tickets for yourself");
        require(allowedToBuyTicket[_buyer] != 0, "You have to pay the previous ticket first");
        require( ticketsAvailable != 0, "Not enough tickets available");

        sbt.mint(_buyer, SBT.Soul({
            id: nameEvent,
            url: "",
            score: ++globalScore, //Contador de entradas
            timestamp: block.timestamp,
            owner: _buyer,
            available: false // If a ticket its put on resall mode, it will be available again
        }));

        soldTickets[_buyer][globalScore] = SBT.Soul({
            id: nameEvent,
            url: "",
            score: globalScore, //Contador de entradas
            timestamp: block.timestamp,
            owner: _buyer,
            available: false // If a ticket its put on resall mode, it will be available again
        });

        --allowedToBuyTicket[_buyer];
        --ticketsAvailable;

        emit SoldTicket(_buyer, globalScore);
    }
   

    //You can get refund if you cancel your tickets X time before the eventq
    function cancelTickets(uint256[] memory _scores) external nonReentrant {
        require(_scores.length > 0, "Not enough tickets to cancel");
        
        for(uint256 i = 0; i < _scores.length; i++) {
            _cancelTicket(_scores[i], msg.sender);
        }
    }

    function _cancelTicket(uint256 _score, address _buyer) internal {
        ///@dev: Is checked that the ticket with that score exists?
        require(soldTickets[_buyer][_score].owner == _buyer, "You are not the owner of this ticket");
        require(soldTickets[_buyer][_score].available == false, "The ticket is not on resell mode");
        
        canceledTickets[_score] = soldTickets[_buyer][_score];
        delete soldTickets[_buyer][_score];

        sbt.burn(msg.sender); //burn se debería hacer solo por contratos autorizados
    
        (bool sent, ) = payable(_buyer).call{value: ticketPrice}("");
        require(sent, "Failed to send Ether");
        
        emit CanceledTicket(msg.sender, _score);
        
    }

    function resellTicket(uint256 _score, address _buyer, address newOwner) internal {
        require(soldTickets[_buyer][_score].owner == _buyer, "You are not the owner of this ticket");
        require(soldTickets[_buyer][_score].available == false, "The ticket is not on resell mode");
        require(newOwner != address(0), "You can't sell a ticket to address 0");

        canceledTickets[_score] = soldTickets[_buyer][_score];
        delete soldTickets[_buyer][_score];

        sbt.burn(msg.sender); 

        sbt.mint(newOwner, SBT.Soul({
            id: nameEvent,
            url: "",
            score: _score, //Contador de entradas
            timestamp: block.timestamp,
            owner: newOwner,
            available: false // If a ticket its put on resall mode, it will be available again
        }));

        emit ResellTicket(msg.sender, newOwner, _score);
        
    }

    ///@dev when user pays for a ticket, he can mint the tickets
    function allowToBuyTickets(address _buyer, uint256 _quantity) external payable {
        require(_quantity != 0, "Quantity must be greater than zero");
        require(ticketsAvailable >= _quantity, "Not enough tickets available");
        require(msg.value == automaticTicketPrice() *_quantity, "No se ha enviado suficiente ETH");

        totalEarned += msg.value;
        allowedToBuyTicket[_buyer] = _quantity;

        emit PurchasedTicket();
    }

    ///@dev called by frontend to get the price of the ticket
    function automaticTicketPrice() public view returns(uint256) {
        require(maxTickets != 0 &&
                ticketsAvailable != 0, "Theres no tickets available");

        uint256 initialPrice = ticketPrice;
        uint256 maxPrice = initialPrice * 3;
        uint256 soldPercentage = (globalScore * 100) / maxTickets;
        uint256 priceIncrement = (soldPercentage * (maxPrice - initialPrice)) / 100;

        return initialPrice + priceIncrement;
    }

/*     function automaticTicketPrice() public view returns(uint256) {
    assembly {
        // Load values from storage
        let maxTickets := sload(maxTickets_slot)
        let ticketsAvailable := sload(ticketsAvailable_slot)
        let ticketPrice := sload(ticketPrice_slot)
        let globalScore := sload(globalScore_slot)
        
        // Check if there are available tickets
        if iszero(and(iszero(maxTickets), iszero(ticketsAvailable))) {
            // Return error message if no tickets available
            revert(0, 0)
        }
        
        // Calculate intermediate values
        let initialPrice := ticketPrice
        let maxPrice := mul(initialPrice, 3)
        let soldPercentage := div(mul(globalScore, 100), maxTickets)
        let priceIncrement := div(mul(soldPercentage, sub(maxPrice, initialPrice)), 100)
        
        // Calculate and return the final price
        mstore(0, add(initialPrice, priceIncrement))
        return(0, 32)
    } 
}*/

    function validateTicket() public returns(bool){
        bool soul = sbt.hasSoul(msg.sender);
        if(soul){
            sbt.burn(msg.sender);
            emit validatedTicket(msg.sender);
            return soul;
        }
        return false;
    }
    function modifiedSetMaxTickets(uint32 _maxTickets) external onlyOwner {
        require(_maxTickets >  maxTickets, "You can't reduce the number of tickets");
        maxTickets = _maxTickets;
    }

    function modifiedSetTicketPrice(uint16 _ticketPrice) external onlyOwner {
        ticketPrice = _ticketPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SBT {

    struct Soul {
        string id;
        string url;
        uint256 score;
        uint256 timestamp;
        address owner;
        bool available;
    }

    mapping (address => Soul) public souls;

    string public name;
    string public description;
    address public operator;
    bytes32 private zeroHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    
    event Mint(address _soul);
    event Burn(address _soul);
    event Update(address _soul);

    constructor(string memory _name, string memory _description) {
        name = _name;
        description = _description;
        operator = msg.sender;
    }

    function mint(address _soul, Soul memory _soulData) external {
        require(keccak256(bytes(souls[_soul].id)) == zeroHash, "Soul already exists");
        require(msg.sender == operator, "Only operator can mint new souls");
        souls[_soul] = _soulData;
        emit Mint(_soul);
    }

    function burn(address _soul) external {
        require(msg.sender == _soul || msg.sender == operator, "Only users and issuers have rights to delete their data");
        delete souls[_soul];
        emit Burn(_soul);
    }
    

    function update(address _soul, Soul memory _soulData) external {
        require(msg.sender == operator, "Only operator can update soul data");
        require(keccak256(bytes(souls[_soul].id)) != zeroHash, "Soul does not exist");
        souls[_soul] = _soulData;
        emit Update(_soul);
    }

    function hasSoul(address _soul) external view returns (bool) {
        if (keccak256(bytes(souls[_soul].id)) == zeroHash) {
            return false;
        } else {
            return true;
        }
    }

    function getSoul(address _soul) external view returns (Soul memory) {
        return souls[_soul];
    }
    
}