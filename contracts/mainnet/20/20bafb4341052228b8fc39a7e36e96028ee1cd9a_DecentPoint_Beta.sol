/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: decentpoint.sol



pragma solidity ^0.8.9;

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DecentPoint_Beta{
    address public owner;

    constructor() {       
        owner = msg.sender;
    }


struct Log {
  uint TimeStamp;
  uint Project_ID;
  address Performer;
  uint Action; 
  // 1 deposit, 2 withdraw, 3 spent point, 4 admin withdraw, 5 burn, 6 mint,   99 change
  uint AmountCurrency;
  uint Unit; // 1 point , 2 busd, 3 usdt, 0 no unit
}

Log[] public logs;

address public Admin1; 
address public ShareAddr;




    modifier OnlyRightAddress {
        require((msg.sender == owner)||(msg.sender==Admin1));
        _;
    }  

    function SetAdmin1(address _Admin1) OnlyRightAddress public {
        Admin1 = _Admin1;
    }

IERC20 public BUSD; //18 decimals for polygon network from uniswapV3
IERC20 public USDT; // 6 decimals for polygon network


//Admin input contract address of BUSD and USDT
function setCurrencyContract(address _busd, address _usdt)OnlyRightAddress public {
        BUSD = IERC20(_busd);
        USDT = IERC20(_usdt);
    }




uint [] public projectID;
uint public rate;
uint public projectNum = 0;

mapping(string=>uint) public projectExchangeRate;
mapping(uint=>uint) public specialAuthorized;
mapping(uint=>uint) public projectQuota;

mapping(uint=>uint) public projectExRate;

mapping(uint=>address) public projectOwner;

mapping(uint=>address) public projectDestiWallet;

mapping(uint=>uint) public projectWithdrawnFee;

 mapping(uint=>uint) public projectPointRemain;

mapping(uint=>uint) public projectPointInSystem;

mapping(address=>mapping(uint => bool)) projectUserAuthorize;

mapping(address=>mapping(uint => uint)) projectUserPointRemain;

uint BUSDfeeWithdrawAble = 0;
uint USDTfeeWithdrawAble = 0;


uint defaultFee = 3; // 3% withdraw fee

//owner create his/her project
function createProject(uint _rate)public {
      projectExRate[projectNum]= _rate;
      projectOwner[projectNum]= msg.sender;
      projectWithdrawnFee[projectNum] = defaultFee;
      projectDestiWallet[projectNum] = msg.sender;
      projectPointRemain[projectNum] = 0;
      specialAuthorized[projectNum]=0;
      projectQuota[projectNum]=0;
      projectPointInSystem[projectNum]=0;
      projectID.push(projectNum);
      projectNum++;
}



//to get all parameters of project
function getProjectDetails(uint _projectID)public view returns(uint, address, uint,address,uint,uint){
    return (projectExRate[_projectID], projectOwner[_projectID], 
    projectWithdrawnFee[_projectID],projectDestiWallet[_projectID],
    projectPointRemain[_projectID],projectPointInSystem[_projectID]);

}

function getProjectDetailsSpecialty(uint _projectID)OnlyRightAddress public view returns(uint, uint){
   return (specialAuthorized[_projectID],projectQuota[_projectID] );
}

//admin can set fee for any project.
function setFeeForAnyProject(uint _projectID, uint _fee)OnlyRightAddress public{
   projectWithdrawnFee[_projectID] = _fee; //% of withdraw
}

//admin can set destiny wallet for sending fee to share holder contract
function setShareAddress(address _shareAddr)OnlyRightAddress public{
    ShareAddr = _shareAddr;
}

//admin can set special authorization.
function setSpecialty(uint _projectID, uint _quota)OnlyRightAddress public{
      specialAuthorized[_projectID]=1;
      projectQuota[_projectID]=_quota*10**18;
}

//fee withdrawable checking-->return value of BUSD and USDT that Admin can withdraw.
function viewFeeWithdrawableRemain()public view returns(uint,uint){
    return(BUSDfeeWithdrawAble,USDTfeeWithdrawAble);
}

//anyone can view money collected in smart contract. -->return BUSD and USDT
function viewAllCurrencyInContract()public view returns(uint,uint){
    return(BUSD.balanceOf(address(this)),USDT.balanceOf(address(this)));
}

//Admin send revenue to shared contract
function withdrawFee(address _currency, uint _amount)OnlyRightAddress public noReentrant{
   
   uint Action_time = block.timestamp;

   if(IERC20(_currency)== BUSD){
       uint Amount  = _amount*10**18;
    require(BUSDfeeWithdrawAble>Amount);
    BUSD.transfer(ShareAddr, Amount);
    BUSDfeeWithdrawAble -= Amount;
    logs.push(Log(Action_time,9999999,msg.sender,4,_amount,2));
    }

    if(IERC20(_currency)==USDT){
        uint Amount  = _amount*10**6;
    require(USDTfeeWithdrawAble>=Amount);
    USDT.transfer(ShareAddr, Amount);
    USDTfeeWithdrawAble -=Amount;
    logs.push(Log(Action_time,9999999,msg.sender,4,_amount,3));
    }
    
    

}



//project owner can change their destiny wallet or into destiny contract address
function ChangeDestiWallet(uint _projectID,address _desti)public {
    require(projectOwner[_projectID]== msg.sender);
    uint Action_time = block.timestamp;
    projectDestiWallet[_projectID] = _desti;
    logs.push(Log(Action_time,_projectID,_desti,99,0,0));

}

//user deposit busd, usdt (only integer) and we return point in blockchain to user
function userDeposit(uint _projectID, address _currency, uint _amount)public {
    rate = projectExRate[_projectID];
    uint mintAmount = rate*_amount*10**18;
    uint Action_time = block.timestamp; 

    if(IERC20(_currency)==BUSD){
    //BUSD.approve(address(this),_amount*10**18);
    BUSD.transferFrom(msg.sender, address(this),_amount*10**18);
    logs.push(Log(Action_time,_projectID,msg.sender,1,_amount,2));
    }

    if(IERC20(_currency)==USDT){
    //USDT.approve(address(this),_amount*10**18);    
    USDT.transferFrom(msg.sender, address(this),_amount*10**6);
    logs.push(Log(Action_time,_projectID,msg.sender,1,_amount,3));
    }

    projectUserPointRemain[msg.sender][_projectID]+= mintAmount;

    projectPointInSystem[_projectID] +=mintAmount;
    logs.push(Log(Action_time,_projectID,msg.sender,6,mintAmount,1));


   
}

//view point of user for any project
function viewPointofUserRemain(uint _projectID, address _userAddr)public view returns(uint){
    return projectUserPointRemain[_userAddr][_projectID];
}

bool internal locked;
modifier noReentrant(){
require(!locked,"No re-entrancy");
locked = true;
_;
locked = false;
}


//users of any project can return point into BUSD/USDT and send back to their wallet
function UserWithdraw(uint _projectID, uint _pointAmount, address _currency)public noReentrant{
    require(projectUserPointRemain[msg.sender][_projectID]>=_pointAmount*10**18);
    
    uint currencyBack = (_pointAmount*10**18)/projectExRate[_projectID];
    uint fee = currencyBack*projectWithdrawnFee[_projectID]/100;
    projectPointInSystem[_projectID] -=_pointAmount*10**18;
     uint Action_time = block.timestamp; 
    currencyBack -= fee;

     if(IERC20(_currency)==BUSD){
     BUSDfeeWithdrawAble += fee;    
    BUSD.transfer(msg.sender,currencyBack);
    logs.push(Log(Action_time,_projectID,msg.sender,2,currencyBack,2));
    }

    if(IERC20(_currency)==USDT){
     USDTfeeWithdrawAble += fee/(10**12);   
    USDT.transfer(msg.sender,currencyBack/(10**12));
    logs.push(Log(Action_time,_projectID,msg.sender,2,currencyBack/(10**12),3));
    }
   
    projectUserPointRemain[msg.sender][_projectID]-= _pointAmount*10**18;
    logs.push(Log(Action_time,_projectID,msg.sender,5,_pointAmount*10**18,1));


}

//if user use point in platform, point will be sent to project owner
function userUsePoint_inPlatform (uint _projectID, uint _pointAmount)public{
     require(projectUserPointRemain[msg.sender][_projectID]>= _pointAmount*10**18);
      uint Action_time = block.timestamp; 
      projectPointRemain[_projectID] +=  _pointAmount*10**18;
      
      projectUserPointRemain[msg.sender][_projectID]-= _pointAmount*10**18;   
      logs.push(Log(Action_time,_projectID,msg.sender,3,_pointAmount*10**18,1));
}

//Project owner withdraw usd based on point remaining in project.
function projectOwnerWithdrawUSD(uint _projectID, address _currency, uint _pointAmount)public noReentrant{
      require(projectOwner[_projectID]==msg.sender);
      require(projectPointRemain[_projectID]>=_pointAmount*10**18);
       projectPointInSystem[_projectID] -=_pointAmount*10**18;

    uint currencyBack = (_pointAmount*10**18)/projectExRate[_projectID];
    uint fee = currencyBack*projectWithdrawnFee[_projectID]/100;
    uint Action_time = block.timestamp; 
    currencyBack -= fee;
      //to burn point 
  
   projectPointRemain[_projectID] -=_pointAmount*10**18; 
   logs.push(Log(Action_time,_projectID,msg.sender,5,_pointAmount*10**18,1));

      if(IERC20(_currency)==BUSD){
          BUSDfeeWithdrawAble += fee;    
          BUSD.transfer(projectDestiWallet[_projectID],currencyBack);
          logs.push(Log(Action_time,_projectID,msg.sender,3,currencyBack,2));
      }

      if(IERC20(_currency)==USDT){
         USDTfeeWithdrawAble += fee/(10**12);   
         USDT.transfer(projectDestiWallet[_projectID],currencyBack/(10**12));
         logs.push(Log(Action_time,_projectID,msg.sender,3,currencyBack/(10**12),3));
      }
     
   

}

function mintPointByProjectOwner(uint _projectID,uint amount) public noReentrant{

         require(specialAuthorized[_projectID]==1);
         require(projectOwner[_projectID]==msg.sender);         
         require(projectQuota[_projectID]>=amount*10**18);
         amount = amount*10**18;
         uint Action_time = block.timestamp;
         projectQuota[_projectID] -= amount; 
         projectPointRemain[_projectID]+= amount;
         //projectPointInSystem[_projectID] -= amount;
         logs.push(Log(Action_time,9999999,msg.sender,5,amount,1));
        //projectUserPointRemain[msg.sender][_projectID]=projectUserPointRemain[msg.sender][_projectID]+amount;
    }

   function promotionPointByProjectOwner(uint _projectID, address _user, uint _amount)public noReentrant{
        require(specialAuthorized[_projectID]==1);
        require(projectOwner[_projectID]==msg.sender);         
        require(projectQuota[_projectID]>=_amount*10**18);
         uint Action_time = block.timestamp;
        uint amount = _amount*10**18;
         projectQuota[_projectID] -= amount; 
         projectPointRemain[_projectID]-= amount;       
         projectUserPointRemain[_user][_projectID] += amount;
         logs.push(Log(Action_time,9999999,_user,6,_amount,1));

   }


   function viewLogs(uint _index)public view returns(uint, uint, address, uint, uint, uint){
      
      return (logs[_index].TimeStamp, logs[_index].Project_ID,
      logs[_index].Performer, logs[_index].Action, logs[_index].AmountCurrency,
      logs[_index].Unit) ;
   }

  
  function numLog()public view returns(uint){
      uint Numlog = logs.length;
      return Numlog;
  }




}