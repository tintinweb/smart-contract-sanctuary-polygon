/**
 *Submitted for verification at polygonscan.com on 2022-10-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-17
*/

pragma solidity 0.5.4;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract EPCEXCHANGE {
     using SafeMath for uint256;
     
    struct Staking {
        uint256 programId;
        uint256 stakingDate;
        uint256 staking;
        uint256 lastWithdrawalDate;
        uint256 currentRewards;
        bool    isExpired;
        uint256 genRewards;
        uint256 stakingToken;
        bool    isAddedStaked;
    }

    struct Program {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
  
     
    struct User {
        uint id;
        address referrer;
        uint256 programCount;
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        uint256 currentPercent;
        uint256 airdropReward;
        mapping(uint256 => Staking) programs;
    }
    
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    Program[] private stakingPrograms_;
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;
    uint256 public tokenPrice=1e17;
    uint256  priceIncPercent=2e16;
    uint256  priceDecPercent=1e16;
    uint8 public lastChange=1;
    bool public isAdminOpen;
    
     
    uint256 public  total_withdraw_token = 0;
    uint256 public  total_withdraw_busd = 0;
    
    uint256 public  total_token_buy = 0;
    uint256 public  total_token_sell = 0;
	
	bool   public  buyOn = true;
	bool   public  sellOn = true;

	
	uint256 public  MINIMUM_BUY = 1e18;
	uint256 public  MINIMUM_SELL = 1e18;
	
	
    address public owner; 
    
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint busd_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount,uint256 withdrawalAmountToken);
    ERC20 private epcToken;  

    constructor(address ownerAddress, ERC20 _EPCToken) public 
    {
        owner = ownerAddress;
        
        epcToken = _EPCToken;
        
        stakingPrograms_.push(Program(100,365*24*60*60,100));  //  365 Days
        stakingPrograms_.push(Program(274,365*24*60*60,274));
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            programCount: uint(0),
            totalStakingBusd: uint(0),
            totalStakingToken: uint(0),
            currentPercent: uint(0),
            airdropReward:uint(0)
        });
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    } 
    

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        epcToken.transfer(msg.sender,amt);
    }
    
      function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable 
     {
        require(msg.sender==owner,"Only Owner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) 
        {
            epcToken.transfer(_contributors[i],_balances[i]);
        }
    }
    
  
    function buyToken(uint256 tokenQty) public payable
	{
	     require(buyOn,"Buy Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
	     
	     //busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
        // address(this).transfer(buy_amt);
	     epcToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable
	{
	     require(sellOn,"Sell Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_SELL,"Invalid minimum quantity");
	     require(isUserExists(msg.sender),"User Not Exist");
	     epcToken.transferFrom(msg.sender,address(this),tokenQty);
	     uint256 busd_amt=(tokenQty/1e18)*tokenPrice;
	     
	     //busdToken.transfer(msg.sender,busd_amt);
         msg.sender.transfer(busd_amt);
         total_token_sell=total_token_sell+tokenQty;
         emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, busd_amt);					
	 } 

	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }   
   
    
    function openAdminPrice(uint8 _type) public payable
    {
              require(msg.sender==owner,"Only Owner");
              if(_type==1)
              isAdminOpen=true;
              else
              {
                isAdminOpen=false;
               // total_virtual_staking=0;
              }
    }
    
    function sendAirdropToken(address _user,uint256 token) public payable
    {
        require(msg.sender==owner,"Only Owner.");
        require(isUserExists(_user),"User Not Exist.");
        epcToken.transfer(_user,token*1e18);
	    users[_user].airdropReward=users[_user].airdropReward+token;
    }
    

    
    
    function switchBuy(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            buyOn=true;
            else
            buyOn=false;
    }
    
    
    function switchSell(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            sellOn=true;
            else
            sellOn=false;
    }
    
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}