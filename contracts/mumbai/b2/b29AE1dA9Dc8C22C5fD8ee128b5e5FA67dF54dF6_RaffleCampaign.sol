// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/// @title EarningCycle contract interface
interface IEarningCycle {
    struct User {
        uint256 deposits;
        uint256 reward;
        uint256 lastTime;
        address referrer;
        uint256 referrerDeposits;
        uint256 bonus;
        WithdrawnNum withdrawnNum;
        LevelStatus levelStatus;
    }

    struct WithdrawnNum {
        uint256 level1WithdrawnNum;
        uint256 level2WithdrawnNum;
        uint256 level3WithdrawnNum;
        uint256 level4WithdrawnNum;
        uint256 level5WithdrawnNum;
    }

    struct LevelStatus {
        bool deposited;
        bool upgraded2;
        bool upgraded3;
        bool upgraded4;
        bool upgraded5;
    }

    function users(address _address) external returns (User memory);
}

/// @title RaffleCampaign
contract RaffleCampaign is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    /// @dev declare earningCycle of IEarningCycle interface
    IEarningCycle earningCycle;
    address public e2e;
    uint public totalTickets = 50;

    struct RafflePrice {
        uint raffle1Price;
        uint raffle2Price;
        uint raffle3Price;
        uint raffle4Price;
    }

    struct RafflePrize {
        uint raffle1Prize;
        uint raffle2Prize;
        uint raffle3Prize;
        uint raffle4Prize;
    }

    RafflePrice public rafflePrice;
    RafflePrize public rafflePrize;

    struct DrawnTicket {
        uint drawnTicketNum1;
        uint drawnTicketNum2;
        uint drawnTicketNum3;
        uint drawnTicketNum4;
    }

    struct CurrentRaffle {
        uint currentRaffle1Id;
        uint currentRaffle2Id;
        uint currentRaffle3Id;
        uint currentRaffle4Id;
    }

    DrawnTicket public drawnTicket;
    CurrentRaffle public currentRaffle;

    /// @dev specified mappings of this contract
    mapping (uint => address) public ticket1Owner;
    mapping (address => uint) public ownerTicket1Count;
    mapping (uint => uint[]) public tickets1;
    mapping (uint => bool) public raffle1Status;

    mapping (uint => address) public ticket2Owner;
    mapping (address => uint) public ownerTicket2Count;
    mapping (uint => uint[]) public tickets2;
    mapping (uint => bool) public raffle2Status;

    mapping (uint => address) public ticket3Owner;
    mapping (address => uint) public ownerTicket3Count;
    mapping (uint => uint[]) public tickets3;
    mapping (uint => bool) public raffle3Status;

    mapping (uint => address) public ticket4Owner;
    mapping (address => uint) public ownerTicket4Count;
    mapping (uint => uint[]) public tickets4;
    mapping (uint => bool) public raffle4Status;


    /// @dev Events of each function
    event CreateCampaign(address _owner);

    event boughtTicket1(uint ticketNum);
    event boughtTicket2(uint ticketNum);
    event boughtTicket3(uint ticketNum);
    event boughtTicket4(uint ticketNum);

    event raffle1Started(uint raffleId);
    event raffle2Started(uint raffleId);
    event raffle3Started(uint raffleId);
    event raffle4Started(uint raffleId);

    event raffle1Ended(uint raffleId);
    event raffle2Ended(uint raffleId);
    event raffle3Ended(uint raffleId);
    event raffle4Ended(uint raffleId);

    event drawnTicket1AndRewarded(uint _ticketId, uint _drawnTicketNum, address _drawnTickerOwner);
    event drawnTicket2AndRewarded(uint _ticketId, uint _drawnTicketNum, address _drawnTickerOwner);
    event drawnTicket3AndRewarded(uint _ticketId, uint _drawnTicketNum, address _drawnTickerOwner);
    event drawnTicket4AndRewarded(uint _ticketId, uint _drawnTicketNum, address _drawnTickerOwner);


    /// @notice this contract constructor
    /// @param _earningCycle is EarningCycle contract address.
    constructor(address _earningCycle, address _e2e) {
        rafflePrice.raffle1Price = 50 * 1e18;
        rafflePrice.raffle2Price = 100 * 1e18;
        rafflePrice.raffle3Price = 200 * 1e18;
        rafflePrice.raffle4Price = 1000 * 1e18;

        rafflePrize.raffle1Prize = 16000 * 1e18;
        rafflePrize.raffle2Prize = 32000 * 1e18;
        rafflePrize.raffle3Prize = 64000 * 1e18;
        rafflePrize.raffle4Prize = 320000 * 1e18;

        earningCycle = IEarningCycle(_earningCycle);
        e2e = _e2e;

        // emit CreateCampaign event
        emit CreateCampaign(msg.sender);
    }


    /**
    @notice function to buy a ticket.
    @dev only users not owner.
    @param _ticketNum is ticket's number to be bought by user.
    */
    function buyTicket1(uint _ticketNum) public nonReentrant {
        require(ticket1Owner[_ticketNum] == address(0), "One ticket can't be sold more than twice.");
        require(owner() != msg.sender, "Owner can't buy ticket.");
        require(raffle1Status[currentRaffle.currentRaffle1Id], "This raffle is closed.");
        require(tickets1[currentRaffle.currentRaffle1Id].length < totalTickets, "All the tickets were sold.");
        require(earningCycle.users(msg.sender).levelStatus.upgraded2 || 
                earningCycle.users(msg.sender).levelStatus.upgraded3 || 
                earningCycle.users(msg.sender).levelStatus.upgraded4 || 
                earningCycle.users(msg.sender).levelStatus.upgraded5, "You can't participate in this raffle.");

        IERC20(e2e).transferFrom(address(msg.sender), address(this), rafflePrice.raffle1Price);
        
        tickets1[currentRaffle.currentRaffle1Id].push(_ticketNum);
        ticket1Owner[_ticketNum] = msg.sender;
        ownerTicket1Count[msg.sender] = ownerTicket1Count[msg.sender].add(1);

        // emit boughtTicket1 event
        emit boughtTicket1(_ticketNum);
    }

    function buyTicket2(uint _ticketNum) public nonReentrant {
        require(ticket2Owner[_ticketNum] == address(0), "One ticket can't be sold more than twice.");
        require(owner() != msg.sender, "Owner can't buy ticket.");
        require(raffle2Status[currentRaffle.currentRaffle2Id], "This raffle is closed.");
        require(tickets2[currentRaffle.currentRaffle2Id].length < totalTickets, "All the tickets were sold.");
        require(earningCycle.users(msg.sender).levelStatus.upgraded3 || 
                earningCycle.users(msg.sender).levelStatus.upgraded4 || 
                earningCycle.users(msg.sender).levelStatus.upgraded5, "You can't participate in this raffle.");

        IERC20(e2e).transferFrom(address(msg.sender), address(this), rafflePrice.raffle2Price);
        
        tickets2[currentRaffle.currentRaffle2Id].push(_ticketNum);
        ticket2Owner[_ticketNum] = msg.sender;
        ownerTicket2Count[msg.sender] = ownerTicket2Count[msg.sender].add(1);

        // emit boughtTicket2 event
        emit boughtTicket2(_ticketNum);
    }

    function buyTicket3(uint _ticketNum) public nonReentrant {
        require(ticket3Owner[_ticketNum] == address(0), "One ticket can't be sold more than twice.");
        require(owner() != msg.sender, "Owner can't buy ticket.");
        require(raffle3Status[currentRaffle.currentRaffle3Id], "This raffle is closed.");
        require(tickets3[currentRaffle.currentRaffle3Id].length < totalTickets, "All the tickets were sold.");
        require(earningCycle.users(msg.sender).levelStatus.upgraded4 || 
                earningCycle.users(msg.sender).levelStatus.upgraded5, "You can't participate in this raffle.");

        IERC20(e2e).transferFrom(address(msg.sender), address(this), rafflePrice.raffle3Price);
        
        tickets3[currentRaffle.currentRaffle3Id].push(_ticketNum);
        ticket3Owner[_ticketNum] = msg.sender;
        ownerTicket3Count[msg.sender] = ownerTicket3Count[msg.sender].add(1);

        // emit boughtTicket3 event
        emit boughtTicket3(_ticketNum);
    }

    function buyTicket4(uint _ticketNum) public nonReentrant {
        require(ticket4Owner[_ticketNum] == address(0), "One ticket can't be sold more than twice.");
        require(owner() != msg.sender, "Owner can't buy ticket.");
        require(raffle4Status[currentRaffle.currentRaffle4Id], "This raffle is closed.");
        require(tickets4[currentRaffle.currentRaffle4Id].length < totalTickets, "All the tickets were sold.");
        require(earningCycle.users(msg.sender).levelStatus.upgraded5, "You can't participate in this raffle.");

        IERC20(e2e).transferFrom(address(msg.sender), address(this), rafflePrice.raffle4Price);
        
        tickets4[currentRaffle.currentRaffle4Id].push(_ticketNum);
        ticket4Owner[_ticketNum] = msg.sender;
        ownerTicket4Count[msg.sender] = ownerTicket4Count[msg.sender].add(1);

        // emit boughtTicket4 event
        emit boughtTicket4(_ticketNum);
    }


    /**
    @notice function to start raffle.
    @dev only owner.
    */
    function startRaffle1() public onlyOwner {
        currentRaffle.currentRaffle1Id = currentRaffle.currentRaffle1Id.add(1);
        raffle1Status[currentRaffle.currentRaffle1Id] = true;

        // emit raffle1Started event
        emit raffle1Started(currentRaffle.currentRaffle1Id);
    }

    function startRaffle2() public onlyOwner {
        currentRaffle.currentRaffle2Id = currentRaffle.currentRaffle2Id.add(1);
        raffle2Status[currentRaffle.currentRaffle2Id] = true;

        // emit raffle2Started event
        emit raffle2Started(currentRaffle.currentRaffle2Id);
    }

    function startRaffle3() public onlyOwner {
        currentRaffle.currentRaffle3Id = currentRaffle.currentRaffle3Id.add(1);
        raffle3Status[currentRaffle.currentRaffle3Id] = true;

        // emit raffle3Started event
        emit raffle3Started(currentRaffle.currentRaffle3Id);
    }

    function startRaffle4() public onlyOwner {
        currentRaffle.currentRaffle4Id = currentRaffle.currentRaffle4Id.add(1);
        raffle4Status[currentRaffle.currentRaffle4Id] = true;

        // emit raffle4Started event
        emit raffle4Started(currentRaffle.currentRaffle4Id);
    }


    /**
    @notice function to end raffle.
    @dev only owner.
    */
    function endRaffle1() public onlyOwner {
        raffle1Status[currentRaffle.currentRaffle1Id] = false;

        // emit raffle1Ended event
        emit raffle1Ended(currentRaffle.currentRaffle1Id);
    }

    function endRaffle2() public onlyOwner {
        raffle2Status[currentRaffle.currentRaffle2Id] = false;

        // emit raffle2Ended event
        emit raffle2Ended(currentRaffle.currentRaffle2Id);
    }

    function endRaffle3() public onlyOwner {
        raffle3Status[currentRaffle.currentRaffle3Id] = false;

        // emit raffle3Ended event
        emit raffle3Ended(currentRaffle.currentRaffle3Id);
    }

    function endRaffle4() public onlyOwner {
        raffle4Status[currentRaffle.currentRaffle4Id] = false;

        // emit raffle4Ended event
        emit raffle4Ended(currentRaffle.currentRaffle4Id);
    }


    /**
    @notice function to draw a ticket randomly and reward raffle winner.
    @dev only owner.
    */
    function drawnTicket1AndReward() public onlyOwner nonReentrant {
        require(tickets1[currentRaffle.currentRaffle1Id].length == totalTickets, "Total tickets haven't been sold yet.");
        uint id = _randomTicket1Id();
        drawnTicket.drawnTicketNum1 = tickets1[currentRaffle.currentRaffle1Id][id];

        IERC20(e2e).transfer(ticket1Owner[drawnTicket.drawnTicketNum1], rafflePrize.raffle1Prize);

        // emit drawnTicket1AndRewarded event
        emit drawnTicket1AndRewarded(id, drawnTicket.drawnTicketNum1, ticket1Owner[drawnTicket.drawnTicketNum1]);
    }

    function drawnTicket2AndReward() public onlyOwner nonReentrant {
        require(tickets2[currentRaffle.currentRaffle2Id].length == totalTickets, "Total tickets haven't been sold yet.");
        uint id = _randomTicket2Id();
        drawnTicket.drawnTicketNum2 = tickets2[currentRaffle.currentRaffle2Id][id];

        IERC20(e2e).transfer(ticket2Owner[drawnTicket.drawnTicketNum2], rafflePrize.raffle2Prize);

        // emit drawnTicket2AndRewarded event
        emit drawnTicket2AndRewarded(id, drawnTicket.drawnTicketNum2, ticket2Owner[drawnTicket.drawnTicketNum2]);
    }

    function drawnTicket3AndReward() public onlyOwner nonReentrant {
        require(tickets3[currentRaffle.currentRaffle3Id].length == totalTickets, "Total tickets haven't been sold yet.");
        uint id = _randomTicket3Id();
        drawnTicket.drawnTicketNum3 = tickets3[currentRaffle.currentRaffle3Id][id];

        IERC20(e2e).transfer(ticket3Owner[drawnTicket.drawnTicketNum3], rafflePrize.raffle3Prize);

        // emit drawnTicket3AndRewarded event
        emit drawnTicket3AndRewarded(id, drawnTicket.drawnTicketNum3, ticket3Owner[drawnTicket.drawnTicketNum3]);
    }

    function drawnTicket4AndReward() public onlyOwner nonReentrant {
        require(tickets4[currentRaffle.currentRaffle4Id].length == totalTickets, "Total tickets haven't been sold yet.");
        uint id = _randomTicket4Id();
        drawnTicket.drawnTicketNum4 = tickets4[currentRaffle.currentRaffle4Id][id];

        IERC20(e2e).transfer(ticket4Owner[drawnTicket.drawnTicketNum4], rafflePrize.raffle4Prize);

        // emit drawnTicket4AndRewarded event
        emit drawnTicket4AndRewarded(id, drawnTicket.drawnTicketNum4, ticket4Owner[drawnTicket.drawnTicketNum4]);
    }


    /// @notice internal function to get a random ticket index.
    function _randomTicket1Id() internal view returns (uint) {
        uint idx = _random().mod(tickets1[currentRaffle.currentRaffle1Id].length);
        return idx;
    }

    function _randomTicket2Id() internal view returns (uint) {
        uint idx = _random().mod(tickets2[currentRaffle.currentRaffle2Id].length);
        return idx;
    }

    function _randomTicket3Id() internal view returns (uint) {
        uint idx = _random().mod(tickets3[currentRaffle.currentRaffle3Id].length);
        return idx;
    }

    function _randomTicket4Id() internal view returns (uint) {
        uint idx = _random().mod(tickets4[currentRaffle.currentRaffle4Id].length);
        return idx;
    }


    /// @notice internal function to get a random number using block number.
    function _random() internal view returns (uint) {
        uint seed = block.number;

        uint a = 1103515245;
        uint c = 12345;
        uint m = 2 ** 32;

        return (a * seed + c) % m;
    }


    /// @notice public function to get a raffle info.
    function getRaffle1Info(address _owner) public view returns (address, uint, uint, uint, uint, uint) {
        address currentWinnerAddress = ticket1Owner[drawnTicket.drawnTicketNum1];
        uint ownerTicketsPrice = rafflePrice.raffle1Price.mul(ownerTicket1Count[_owner]);
        uint boughtTicketsCount = tickets1[currentRaffle.currentRaffle1Id].length;
        uint remainTickets = totalTickets.sub(tickets1[currentRaffle.currentRaffle1Id].length);
        uint boughtTicketsPrice = rafflePrice.raffle1Price.mul(tickets1[currentRaffle.currentRaffle1Id].length);
        uint totalTicketsPrice = rafflePrice.raffle1Price.mul(totalTickets);

        return (currentWinnerAddress, ownerTicketsPrice, boughtTicketsCount, remainTickets, boughtTicketsPrice, totalTicketsPrice);
    }

    function getRaffle2Info(address _owner) public view returns (address, uint, uint, uint, uint, uint) {
        address currentWinnerAddress = ticket2Owner[drawnTicket.drawnTicketNum2];
        uint ownerTicketsPrice = rafflePrice.raffle2Price.mul(ownerTicket2Count[_owner]);
        uint boughtTicketsCount = tickets2[currentRaffle.currentRaffle2Id].length;
        uint remainTickets = totalTickets.sub(tickets2[currentRaffle.currentRaffle2Id].length);
        uint boughtTicketsPrice = rafflePrice.raffle2Price.mul(tickets2[currentRaffle.currentRaffle2Id].length);
        uint totalTicketsPrice = rafflePrice.raffle2Price.mul(totalTickets);
        
        return (currentWinnerAddress, ownerTicketsPrice, boughtTicketsCount, remainTickets, boughtTicketsPrice, totalTicketsPrice);
    }

    function getRaffle3Info(address _owner) public view returns (address, uint, uint, uint, uint, uint) {
        address currentWinnerAddress = ticket3Owner[drawnTicket.drawnTicketNum3];
        uint ownerTicketsPrice = rafflePrice.raffle3Price.mul(ownerTicket3Count[_owner]);
        uint boughtTicketsCount = tickets3[currentRaffle.currentRaffle3Id].length;
        uint remainTickets = totalTickets.sub(tickets3[currentRaffle.currentRaffle3Id].length);
        uint boughtTicketsPrice = rafflePrice.raffle3Price.mul(tickets3[currentRaffle.currentRaffle3Id].length);
        uint totalTicketsPrice = rafflePrice.raffle3Price.mul(totalTickets);
        
        return (currentWinnerAddress, ownerTicketsPrice, boughtTicketsCount, remainTickets, boughtTicketsPrice, totalTicketsPrice);
    }

    function getRaffle4Info(address _owner) public view returns (address, uint, uint, uint, uint, uint) {
        address currentWinnerAddress = ticket4Owner[drawnTicket.drawnTicketNum4];
        uint ownerTicketsPrice = rafflePrice.raffle4Price.mul(ownerTicket4Count[_owner]);
        uint boughtTicketsCount = tickets4[currentRaffle.currentRaffle4Id].length;
        uint remainTickets = totalTickets.sub(tickets4[currentRaffle.currentRaffle4Id].length);
        uint boughtTicketsPrice = rafflePrice.raffle4Price.mul(tickets4[currentRaffle.currentRaffle4Id].length);
        uint totalTicketsPrice = rafflePrice.raffle4Price.mul(totalTickets);
        
        return (currentWinnerAddress, ownerTicketsPrice, boughtTicketsCount, remainTickets, boughtTicketsPrice, totalTicketsPrice);
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