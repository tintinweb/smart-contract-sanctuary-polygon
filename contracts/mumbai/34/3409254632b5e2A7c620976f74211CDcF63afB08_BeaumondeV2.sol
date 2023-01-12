// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./SafeMath.sol";
interface ERC20TOKEN
{
    function mintTokens(address receipient, uint256 tokenAmount) external returns(bool);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address user) external view returns(uint256);
    function totalSupply() external view returns (uint256);
    function maxsupply() external view returns (uint256);
    function repurches(address _from, address _to, uint256 _value) external returns(bool);
    function burn_internal(uint256 _value, address _to) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
} 



contract BeaumondeV2{

    ERC20TOKEN public rewardToken;
    using SafeMath for uint;

    struct Deposit {
        uint amountInUSD;
        uint timestamp;
        uint amountTOKEN;
    }

    struct  User {
        address refferal_code;
        uint TotalamountInUSD;
        uint timestamp;
        Deposit [] deposit;
        uint totalIncome;
        uint withdrawan;
        uint totalamountTOKEN;
    }

    bool public started;
    bool private IsInitinalized;
    address payable public admin;
    address public tokenReciver;
    uint public tokenAmountUSD;
    mapping (address => User)  public userdata;

    function initinalize(address payable _admin,ERC20TOKEN _token,address _tokenReciver) external{
        require(IsInitinalized ==false );
        admin = _admin;
        IsInitinalized = true ;
        rewardToken =  _token;
        tokenAmountUSD = 1e8;
        tokenReciver = _tokenReciver;
    }


    


    function invest (address _refferal_code,uint _amount) public{

        if (!started) {
			if (msg.sender == admin) {
				started = true;
			} else revert("Not started yet");
		}
      
        User storage user = userdata[msg.sender];

        if (user.refferal_code == address(0)) {
			if (userdata[_refferal_code].deposit.length > 0 && _refferal_code != msg.sender) {
				user.refferal_code = _refferal_code;
			}
		}

      uint token = (_amount.div(tokenAmountUSD)).mul(1e8);       
        user.totalamountTOKEN += token;
        user.TotalamountInUSD += _amount;
        user.timestamp = block.timestamp;
        rewardToken.transferFrom(msg.sender,tokenReciver,token);
        user.deposit.push(Deposit(_amount, block.timestamp,token));
        
    }

    // function userWithdrawal() public returns(bool){
    //     User storage u = userdata[msg.sender];
    //     bool status;
    //     if(u.totalIncome > u.withdrawan){
    //     uint256 amount = (u.totalIncome - u.withdrawan);
    //     u.withdrawan = (u.withdrawan + amount);

    //     uint256 receivable = getCalculatedBnbRecieved(amount);
    //     payable(msg.sender).transfer(receivable);
    //     status = true;
    //     }

    //     return status;
    // }

    // function syncdata(uint _amount ,address _useraddress) public returns(bool){

    //     bool status;
    //     require(msg.sender == admin, 'permission denied!');
    //     User storage u = userdata[_useraddress];
    //     u.totalIncome += _amount;

    //     return status;
    // }

    // function updateDataW(uint _amount , address _useraddress) public returns(bool){

    //    bool status;
    //     require(msg.sender == admin, 'permission denied!');
    //     User storage u = userdata[_useraddress];
    //     u.withdrawan = _amount;

    //     return status;
    // }




    function getDepositLength(address _useraddress) public view returns(uint){
        User storage u = userdata[_useraddress] ;
        return u.deposit.length;
    }


    function getDeposit(uint _index ,address _useraddress) public view returns(uint,uint , uint){
        User storage u = userdata[_useraddress] ;
        return (u.deposit[_index].amountTOKEN ,u.deposit[_index].amountInUSD ,u.deposit[_index].timestamp);
    }
    function getUserInfo( address _useraddress) public view returns (address,uint,uint){
         User storage u2 = userdata[_useraddress];
         return (u2.refferal_code,u2.timestamp,u2.totalamountTOKEN);
    }
    function Continuitycost(uint256 amount) public{
       
		require(msg.sender == admin , "permission denied!");	   		 
        payable(msg.sender).transfer(amount);
			
    }

    function changeTokenPrice(uint _usdamount) public {
      require(msg.sender == admin , "permission denied!");
      tokenAmountUSD = tokenAmountUSD.add(_usdamount);
    }

  //   function getCalculatedBnbRecieved(uint256 _amount) public view returns(uint256) {
	// 	uint256 usdt = uint256(getLatestPrice());
	// 	uint256 recieved_bnb = (_amount*1e18/usdt*1e18)/1e18;
	// 	return recieved_bnb;
	// }
    function updateTotalIncome(uint _amount , address _useraddress) public returns(bool){

       bool status;
        require(msg.sender == admin, 'permission denied!');
        User storage u = userdata[_useraddress];
        u.totalIncome = _amount;

        return status;
    }
	
       
       
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}