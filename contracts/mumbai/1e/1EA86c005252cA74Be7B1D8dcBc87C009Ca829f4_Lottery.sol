// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;


contract LotteryData {

    struct LotteryInfo{
        uint256 lotteryId;
        uint256 ticketPrice;
        uint256 curPrizePool;
        uint256 lotPrice;
        address[] tickets;
        address winner;
        bool isFinished;
    }
    mapping(uint256 => LotteryInfo) public lotteries;

    uint256[] public allLotteries;

    

    address private manager;
    bool private isLotteryContractSet;
    address private lotteryContract;

    constructor(){
        manager = msg.sender;
    }

    error lotteryNotFound();
    error onlyLotteryManagerAllowed();
    error actionNotAllowed();

    modifier onlyManager(){
        if(msg.sender != manager) revert onlyLotteryManagerAllowed();
        _;
    }

    modifier onlyLoterryContract(){
        if(!isLotteryContractSet) revert actionNotAllowed();
        if(msg.sender != lotteryContract) revert onlyLotteryManagerAllowed();
        _;
    }

    function updateLotteryContract(address _lotteryContract) external onlyManager{
        isLotteryContractSet = true;
        lotteryContract = _lotteryContract;
    }

    function getAllLotteryIds() external view returns(uint256[] memory){
        return allLotteries;
    }


    function addLotteryData(uint256 _lotteryId, uint256 _lotteryTicketPrice, uint256 _lotPrice) external onlyLoterryContract{
        LotteryInfo memory lottery = LotteryInfo({
            lotteryId: _lotteryId,
            ticketPrice: _lotteryTicketPrice,
            curPrizePool: 0,
            lotPrice: _lotPrice,
            tickets: new address[](0),
            winner: address(0),
            isFinished: false
        });
        lotteries[_lotteryId] = lottery;
        allLotteries.push(_lotteryId);
    }

    function addPlayerToLottery(uint256 _lotteryId, uint256 _updatedPricePool, address _player) external onlyLoterryContract{
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.tickets.push(_player);
        lottery.curPrizePool = _updatedPricePool;
    }


    function getLotteryTickets(uint256 _lotteryId) public view returns(address[] memory) {
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
        if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.tickets;
    }

    function isLotteryFinished(uint256 _lotteryId) public view returns(bool){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.isFinished;
    }

    function getLotteryPlayerLength(uint256 _lotteryId) public view returns(uint256){
        LotteryInfo memory tmpLottery = lotteries[_lotteryId];
         if(tmpLottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        return tmpLottery.tickets.length;
    }

    function getLotteries() external view returns (LotteryInfo[] memory) {
        LotteryInfo[] memory result = new LotteryInfo[](allLotteries.length);
        
        for (uint i = 1 ; i <= allLotteries.length; i++) {
            result[i-1] = lotteries[i];
        }
        return result;
    }

    function getLottery(uint256 _lotteryId) external view returns(
        uint256,
        uint256,
        uint256 ,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            LotteryInfo memory tmpLottery = lotteries[_lotteryId];
            if(tmpLottery.lotteryId == 0){
                revert lotteryNotFound();
            }
            return (
                tmpLottery.lotteryId,
                tmpLottery.ticketPrice,
                tmpLottery.curPrizePool,
                tmpLottery.lotPrice,
                tmpLottery.tickets,
                tmpLottery.winner,
                tmpLottery.isFinished
            );
    }

    function setWinnerForLottery(uint256 _lotteryId, uint256 _winnerIndex) external onlyLoterryContract {
        LotteryInfo storage lottery = lotteries[_lotteryId];
        if(lottery.lotteryId == 0){
            revert lotteryNotFound();
        }
        lottery.isFinished = true;
        lottery.winner = lottery.tickets[_winnerIndex];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./LotteryData.sol";


error Raffle__TransferFailed();
error Raffle__SendMoreToEnterRaffle();
error Raffle__RaffleNotOpen();

contract Lottery is Ownable {

    using SafeMath for uint256;
    LotteryData LOTTERY_DATA;
    using Counters for Counters.Counter;
    Counters.Counter private lotteryId;

    uint256 public  MAX_TICKETS;
    uint256 public  TICKET_PRICE;

    

    // mapping(address => uint256) public ticketsBought;
    // address[] public ticketHolders;
    // bool public isLotteryClosed;

    event TicketPurchased(address indexed buyer, uint256 ticketsBought);
    event LotteryWinner(address indexed winner);
    event LotteryCreated(uint256);


    //custom Errors
    error invalidValue();
    error invalidFee();
    error lotteryNotActive();
    error lotteryFull();
    error alreadyEntered();
    error lotteryEnded();
    error playersNotFound();
    error onlyLotteryManagerAllowed();

    constructor( address _lotteryData) {
        lotteryId.increment();  
        LOTTERY_DATA = LotteryData(_lotteryData);
    }

    function getAllLotteryIds() public view returns(uint256[] memory){
        return LOTTERY_DATA.getAllLotteryIds();
    }

    function startLottery(uint256 _TICKET_PRICE, uint256 _LOT_PRICE) public payable onlyOwner {
        // isLotteryClosed = false;

        
        // TICKET_PRICE = 1 ether * _TICKET_PRICE ;

        LOTTERY_DATA.addLotteryData(lotteryId.current(), _TICKET_PRICE, _LOT_PRICE);
        lotteryId.increment();
        emit LotteryCreated(lotteryId.current());
    }

    function buyTickets(uint256 _lotteryId, uint256 _numTickets) public payable {


        (uint256 lId, 
        uint256 ticketPrice, 
        uint256 curPrizePool,
        uint lotPrice,
        address[] memory tickets, 
        address winner, 
        bool isFinished) = LOTTERY_DATA.getLottery(_lotteryId);



        require(!isFinished, "Lottery is closed");
        // if(isFinished) revert lotteryNotActive();

        MAX_TICKETS = lotPrice / ticketPrice;

        if(tickets.length >= MAX_TICKETS) revert lotteryFull();

        require(_numTickets > 0 && _numTickets <= MAX_TICKETS.sub(tickets.length), "Invalid number of tickets");
        
        require(msg.value == _numTickets.mul(ticketPrice * 1 ether), "Incorrect amount sent");

        uint256  updatedPricePool = curPrizePool + msg.value;
        
        for (uint256 i = 0; i < _numTickets; i++) {
            // ticketHolders.push(msg.sender);
            LOTTERY_DATA.addPlayerToLottery(_lotteryId, updatedPricePool, msg.sender);
        }

        // ticketsBought[msg.sender] = ticketsBought[msg.sender].add(_numTickets);

        emit TicketPurchased(msg.sender, _numTickets);
    }

    // function closeLottery() public onlyOwner {
    //     isLotteryClosed = true;
    // }

    function pickWinner(uint256 _lotteryId) public onlyOwner {
        // require(LOTTERY_DATA.isLotteryFinished(_lotteryId), "Lottery is still open");
         if(LOTTERY_DATA.isLotteryFinished(_lotteryId)) revert lotteryEnded();

        address[] memory p = LOTTERY_DATA.getLotteryTickets(_lotteryId);

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % p.length;
        LOTTERY_DATA.setWinnerForLottery(_lotteryId, winnerIndex);
        
        address winner = p[winnerIndex];

        // nftContract.safeTransferFrom(address(this), winner, nftTokenId);
        (bool success, ) = winner.call{value: address(this).balance}("");

        if (!success) {
            revert Raffle__TransferFailed();
        }

        emit LotteryWinner(winner);
    }

    function withdrawFunds() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
    //     return this.onERC721Received.selector;
    // }

    // --------------------------------------------------------------------------------------------------
    // Getters

    function getLotteryDetails(uint256 _lotteryId) public view returns(
        uint256,
        uint256,
        uint256 ,
        uint256 ,
        address[] memory,
        address ,
        bool
        ){
            return LOTTERY_DATA.getLottery(_lotteryId);
    }

    // function getIsLotteryIsClosed() public view returns (bool) {
    //     return isLotteryClosed;
    // }

//     function getMaxTicketCount() public view returns (uint) {
//         return MAX_TICKETS;
//     }

//     function getTicketPrice() public view returns (uint) {
//         return TICKET_PRICE;
//     }

//     function getTicketsCount(address owner) public view returns (uint) {
// //         for (uint i; i<ticketsBought.length; i++) {}
//         return ticketsBought[owner];
//     }

//     function getOwner() public view returns (address) {
//         return owner();
//     }

//     function getTicketOwner(uint ticket) public view returns (address) {
//         return ticketHolders[ticket];
//     }



}