/**
 *Submitted for verification at polygonscan.com on 2022-10-16
*/

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

interface _ERC20 {
  function total_liquidity() external returns(uint256);
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
      
     
    struct User {
        uint id;
        address referrer;
        uint256 programCount;
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        uint256 currentPercent;
        uint256 airdropReward;
    }
    
    
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;
    uint256 public tokenPrice=2e17;
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
    _ERC20 private EPC_Contract;  

    constructor(address ownerAddress, ERC20 _EPCToken, _ERC20 _EPC_Contract) public 
    {
        owner = ownerAddress;
        epcToken = _EPCToken;
        EPC_Contract = _EPC_Contract;

        
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
    
function getPrice() public returns(uint256)
    {
        uint256 holdPrice = EPC_Contract.total_liquidity();
        return holdPrice/1e9;
    
    }

    function deposit_matic() public  payable{
        require(msg.value==0, "Amount Must Be Grater Then 0");
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
	     uint256 buy_amt=(tokenQty/1e18)*getPrice();
	     
	     epcToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, getPrice(), buy_amt);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable
	{
	     require(sellOn,"Sell Stopped.");
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_SELL,"Invalid minimum quantity");
	     epcToken.transferFrom(msg.sender,address(this),tokenQty);
	     uint256 busd_amt=(tokenQty/1e18)*getPrice();
         msg.sender.transfer(busd_amt);
         total_token_sell=total_token_sell+tokenQty;
         emit TokenDistribution(address(this), msg.sender, tokenQty, getPrice(), busd_amt);					
	 } 

	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
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
    

    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}