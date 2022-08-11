/**
 *Submitted for verification at polygonscan.com on 2022-08-10
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: Moneyline_Bets.sol

//team_total contract after intitalized by manager

pragma solidity ^0.8;

//import"https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";



contract  basketballBets {
  
    using SafeMath for uint;
    address public Manager;
    // uint256 public Starttime;
    // uint256 public Endtime;
    // uint256 public Maxlimit;
    // uint256 public Betstep; // to increase per bet amount 
    // address public Betcreator;

    constructor( //uint256 starttime ,
                //  uint256 endtime,
                //  uint256 amount ,
                  address manager 
                //  address betowner,
                //  uint256 betstep
    ){
         Manager = manager;
        // // Starttime  = starttime;
        // // Endtime = endtime;
        // // Manager = manager;
        // Betcreator = betowner;
        // // Maxlimit = amount;
        // Betstep = betstep;
        
    }

    // modifier onlymanager(){
    //     require(msg.sender == Manager);
    //     _;
    // }
    // modifier onlycreator(){
    //     require(msg.sender== Betcreator);
    //     _;
    // }
    // modifier checkbalance(){
    //     require(msg.value >= Betstep,"please check minimum bet value");
    //     _;
    //}
enum state{stake,win,lost}
struct userBet{
    uint256 betid;
    address user;
    uint256 amount; // betting amount
    uint8 betOption; // bet option "0 or 1"
    uint256 bettime; // user betting time 
    uint256 rewardamount; // user winning amount 
    string bettype;
    uint256 betlimit;
    uint256 dailyuserlimit;
    uint256 payoutOdds;
    bool winner;
    state _state;

}
Bet[] public betlist;
userBet[] public userlist;
IERC20 public usdt;
function setusdt(address _usdt)public{
 usdt= IERC20(_usdt);
}
uint256 minBetamount = 0;

    function updatebet(uint256 odd)public pure returns(uint256[2] memory){
        uint256[2] memory PayoutOdds = [odd, 1]; //change for different odd 
        return PayoutOdds;
    }
    function getuserlist(uint256 i)external view returns (userBet memory ){
        return userlist[i];
    }
struct Bet{
 
    uint256 eventid;
    address creator;
    uint256 betvalue;
    uint256 betStarttime;
    uint256 betEndtime;
    uint256 losslimit;
    uint256 dailylosslimit;
  
}
//["1","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","12","1658988719","1658988719","20000","20000"]

function CreateBet(Bet memory _a)public{
    // creating a with 0 or 1 
 //  require(block.timestamp < _a.betStarttime,"start time cannot be less then current time");
  //  require(_a.betStarttime < _a.betEndtime,"endtime is not bigger then start time");
    betlist.push(_a);
}

//"1","123","0","home","120"

function placebet( uint256 _id,uint _amount ,uint8 option,string memory bettype , uint256 oddvalue)    public{
    //check for user balance for that particular 
    //savetime when user place bet via block.timestamp.now
    //save option user choose for prop bet which is yes or no 
    uint256[2] memory newodd = updatebet(oddvalue);
    uint256 temp= calculateBetPayoutAmount(_amount, newodd);
    userBet memory createuser = userBet(
        _id,
        msg.sender,
       _amount, 
        option,
        block.timestamp,
        temp,
        bettype,
        betlist[0].losslimit,
        betlist[0].dailylosslimit,
        oddvalue,
        false,
        state.stake);
    userlist.push(createuser);
    
    
    //  transfer token to contract 
    // update user register 
    // update endtime;
    }
    function withdraw()  public {
    uint256 balance = address(this).balance;
      if (balance > 0) {
            payable(msg.sender).transfer(balance);
        }
        //token.transfer(owner(), token.balanceOf(address(this)));
    } //only manager.

    function bet_logic(uint8 _winner) public {

    if(_winner ==0){
        for(uint8 i=0 ; i<userlist.length; i++){
            if(userlist[i].betOption  == 0 && uint(userlist[i]._state) == 0){
                userlist[i].winner = true;
                userlist[i]._state = state.win;
                
                }
                else{
                    userlist[i].winner = false;
                    userlist[i]._state = state.lost;
                }
             
                }
    }
    else if(_winner ==1){
        for(uint8 i=0;i<userlist.length;i++){
            if(userlist[i].betOption ==1 && uint256(userlist[i]._state)==0){
            userlist[i].winner = true;
            userlist[i]._state = state.win;
            }
            else{
                    userlist[i].winner = false;
                    userlist[i]._state = state.lost;
                }
        }
    }
    else {
        revert("please enter a valid winner");
    }

    } 

    uint256[2] public staticPayoutOdds = [1, 1];
    function calculateBetPayoutAmount(uint256 amount,uint256[2] memory a)pure public returns(uint256) {
        // Since Solidity does not support fixed point numbers, a scale factor is used to scale up the
        // payout odd factors when calculating the payout amount
        uint scaleFactor = 1000000;
        uint payoutMultiplier = SafeMath.div((a[0] * scaleFactor), a[1]);
        uint256 betProfit = uint(amount.mul(payoutMultiplier) / scaleFactor);
        return betProfit;
      }



    //create modifier only player
function claimpayout(address _user) public {
    // _user will get to claim his money 
    // reward is calculated in other function
    for(uint256 i = 0 ; i < userlist.length;i++){
    if(userlist[i].user == _user){  
    require(userlist[i]._state == state.win,"not winner");
    require(userlist[i].winner == true);
    uint256 amount = userlist[i].rewardamount;
    usdt.transfer(_user,amount);
    }
    else{
        revert("not a user");
    }
    }


} // for player only 
 // custom logic
function user_info () public {}

}     
//placebet() //