// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.8.0 < 0.9.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// 0xbF21C40CE1B84fd9Fc45067B058AF3EDc3a8D58a,1,0xACc41777c64434D6e0b6A69257481fD626819EDb,1,360000

contract TrueContract{
    address public owner;
    mapping(uint256=>ticket) public Tickets;
    uint256[] public Ids;
    uint256 private randNonce = 0;
    mapping(address=>uint256) public reward;
    address public rewardContract;
    uint256 public rewardAmount;
    uint256 private TrueTokens;

    event TicketCreated(
        uint256 indexed Id,
        uint256 timestamp,
        uint256 expireDate,
        address indexed sender,
        uint256 senderBalance,
        address senderAddr,
        uint256 receiverBalance,
        address receiverAddr
    );
    event TransactionProccessed(
         uint256 indexed Id,
        uint256 timestamp,
        address indexed receiver
    );

    event Refunded(
       uint256 indexed Id,
        uint256 timestamp,
        address indexed sender
    );
    
    event Rewarded(
       uint256 indexed Id,
        uint256 timestamp,
        uint256 reward,
        address indexed sender,
        address indexed receiver
    );

    event RewardGetted(
uint256 timestamp, 
address indexed sender, 
uint256 amount
    );

    struct ticket {
        uint256 Id;
        uint256 timestamp;
        uint256 expireDate;
        address sender;
        uint256 senderBalance;
        address senderAddr;
        address receiver;
        uint256 receiverBalance;
        address receiverAddr;
        bool exist;
        bool expired;
    }


    constructor(address con, uint256 amount){
        owner = msg.sender;
        rewardContract = con;
        rewardAmount = amount;
    } 

    modifier ownerRequire(){
        require(msg.sender == owner);
        _;
    }


     
     
// 60* m*h* d
    function createTicket(address senderAddr,uint256 senderBalance, address receiverAddr, uint256 receiverBalance, uint256 _expireDate ) public payable{
        require(msg.sender != address(0));
        uint256 rnum = randMod();
        ticket storage tk = Tickets[rnum];
        tk.Id = rnum;
        tk.sender = msg.sender;
        tk.timestamp = block.timestamp;
        tk.senderAddr = senderAddr;
        tk.senderBalance = senderBalance;
        tk.receiverAddr = receiverAddr;
        tk.receiverBalance = receiverBalance; 
        tk.expireDate = _expireDate + block.timestamp;

        // token deposite
        IERC20(senderAddr).transferFrom(msg.sender, address(this), senderBalance);
        tk.exist = true;
        Ids.push(rnum);

         emit TicketCreated(
        tk.Id,
        tk.timestamp,
        tk.expireDate,
        tk.sender,
        tk.senderBalance,
        tk.senderAddr,
        tk.receiverBalance,
        tk.receiverAddr
    );
    }

    function TransactionProccess(uint256 _id) public payable{
        ticket storage tk = Tickets[_id];
        require(msg.sender != address(0));
        require(tk.exist, "Please Check Your IdNumber");
        require((block.timestamp < tk.expireDate), "Contract IdNumber is Expired");
        require(!tk.expired, "IdNumber is expired");
         // token deposite
        IERC20(tk.receiverAddr).transferFrom(msg.sender, address(this), tk.receiverBalance);
        IERC20(tk.receiverAddr).transfer(tk.sender, tk.receiverBalance);
        IERC20(tk.senderAddr).transfer(msg.sender, tk.senderBalance);
        tk.receiver = msg.sender;
        tk.expired = true;
  reward[msg.sender] += rewardAmount;
    reward[tk.sender] += rewardAmount;
         TrueTokens -= 2 * rewardAmount;
          emit TransactionProccessed(
         _id,
        block.timestamp,
        msg.sender
    );

    emit Rewarded(_id,block.timestamp,rewardAmount, tk.sender,msg.sender);
    }

       function Refund(uint256 _id) public payable{
            ticket storage tk = Tickets[_id];
            require((block.timestamp > tk.expireDate), "Please wait untill Contract is not  Expiring");
           require(msg.sender == tk.sender, "Only Creator can refund Tokens");
            require(tk.receiver == address(0), "It is already completed");
           require(!tk.expired, "It is already refunded");
            IERC20(tk.senderAddr).transfer(tk.sender,tk.senderBalance);
            tk.expired = true;
         
           emit Refunded(_id, block.timestamp, msg.sender);
       } 


    // a random number
    function randMod() internal returns(uint256)
    {
    // increase nonce
    randNonce++; 
    return uint256(keccak256(abi.encodePacked(block.timestamp,
        msg.sender,randNonce)));
    }

    function withdrawReward(uint256 amount) public payable{
         require(reward[msg.sender] >= amount," you have not any reward" );
       IERC20(rewardContract).transfer(msg.sender, amount);
        reward[msg.sender] -= amount;
        emit RewardGetted(block.timestamp, msg.sender, amount);
    }

    function addReward(uint256 amount) public payable ownerRequire{
        IERC20(rewardContract).transferFrom(msg.sender, address(this), amount);
        TrueTokens += amount;
    }

    
    function checkTokens() view public  ownerRequire returns(uint256){
        return TrueTokens;
    }

    function checkReward() view public returns(uint256){
        uint256 rewards = reward[msg.sender];
        return rewards;
    }

    function changeRewardAmount(uint256 amount) public ownerRequire{
        rewardAmount = amount;
    }

    function getAllIds() view public returns(uint256[] memory){
        uint256[] memory ticketIds;
        for(uint256 i=0;i<Ids.length;i++){
           ticketIds[i] = Ids[i];
        }
        return ticketIds;
    }

    
    
     function getMyAllTickets() view public returns(ticket[] memory){
         ticket[] memory tks = new ticket[](Ids.length);
        uint256 k = 0;
        for(uint i=0;i<Ids.length;i++){
            if(msg.sender == Tickets[Ids[i]].sender || msg.sender == Tickets[Ids[i]].receiver){
                ticket storage tk = Tickets[Ids[i]];
                tks[k] = tk;
                k++;
            }
        }
        return tks;
    }


    function getAllTickets() view public returns(ticket[] memory){
        ticket[] memory tks = new ticket[](Ids.length);
        for(uint256 i=0;i<Ids.length;i++){
            ticket storage tk = Tickets[Ids[i]];
            tks[i] = tk;
        }
        return tks;
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