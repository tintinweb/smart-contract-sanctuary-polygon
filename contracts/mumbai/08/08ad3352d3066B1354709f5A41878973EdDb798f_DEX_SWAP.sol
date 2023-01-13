/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

pragma solidity 0.5.4;
contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface IBEP20 {
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
   
contract DEX_SWAP is Ownable {
  using SafeMath for uint256;
  uint public MaticRate = 1*1e14;    //0.0001 BNB
  uint public DAIRate = 1*1e15;    //0.001 BUSD
  uint public  MINIMUM_BUY = 10 ;
  uint public  MAXIMUM_BUY = 1000 ;
   address public owner;
    
    event buyToken(string userAddress, string member_user_id, uint total_token, uint trxRate,uint usdtRate,string tr_type);
 
   IBEP20 private DAI; 
   event onBuy(address buyer , uint256 amount);

    constructor(address ownerAddress,IBEP20 _DAI) public 
    {
                 
        owner = ownerAddress;
        DAI = _DAI;
        Ownable.initialize(msg.sender);
    }
 
    function withdrawLostFromBalance() public 
    {
        require(msg.sender == owner, "onlyOwner");
        msg.sender.transfer(address(this).balance);
    }
    
	 function SwapWithMatic(string memory userAddress,string memory member_user_id,uint tokenQty,string memory swaptype) public payable {
					
		require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");
		require(tokenQty<=MAXIMUM_BUY,"Invalid maximum quatity");
		uint256 matic_amt= tokenQty*MaticRate;
		require(msg.value>=matic_amt,"Invalid buy amount");
        address(uint160(owner)).transfer(msg.value);
		emit buyToken(userAddress,member_user_id, tokenQty, MaticRate,DAIRate,swaptype);	
	
	}
	 
	 function SwapWithDAI(string memory userAddress,string memory member_user_id,uint tokenQty,string memory swaptype) public payable {
  	 require(tokenQty>=MINIMUM_BUY,"Invalid minimum quatity");
		uint256 Dai_amt= tokenQty*DAIRate;
		DAI.transferFrom(msg.sender,owner,Dai_amt);
		emit buyToken(userAddress,member_user_id, tokenQty, MaticRate,DAIRate,swaptype);	
	
	}
	 
    function token_setting(uint min_buy, uint256 _DaiRate,uint256 _MaticRate) public payable
    {
        require(msg.sender==owner,"Only Owner");
        MINIMUM_BUY = min_buy ;
        MaticRate=_MaticRate;
        DAIRate=_DaiRate;
    }
       
		function withdrawLostTokenFromBalance(uint256 tokenQty) public payable
		{
        require(msg.sender == owner, "onlyOwner");
        DAI.transfer(owner,tokenQty);
    	}
   
    }