/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.7;


interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
           
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract testPolygon{
  
    event Multisended(uint256 value , address indexed sender);
  	event Registration(address indexed  investor, string  referralId,string referral,uint investment);
    event LevelUpgrade(string  investorId,uint256 investment,address indexed investor,string levelNAme);
    event WithDraw(string  investorId,address indexed  investor,uint256 WithAmt);
    event MemberPayment(uint256  investorId,address indexed  investor,uint256 WithAmt,uint netAmt);
    event Payment(uint256 NetQty);
    
    using SafeMath for uint256;
    IERC20 private MATIC; 
    address public owner;   
   
   
    constructor(address ownerAddress,IERC20 _MATIC)
    {
        owner = ownerAddress;  
        MATIC = _MATIC;
    }
    
    function NewRegistration(string memory referralId,string memory referral,uint256 investment) public payable
	{
		require(MATIC.balanceOf(msg.sender)>=investment);
		require(MATIC.allowance(msg.sender,address(this))>=investment,"Approve Your Token First");
	  MATIC.transferFrom(msg.sender ,owner, investment);
		emit Registration(msg.sender, referralId,referral,investment);
	}

	function UpgradeLevel(string memory investorId,uint256 investment,string memory levelNAme) public payable
	{
	  require(MATIC.balanceOf(msg.sender)>=investment);
		require(MATIC.allowance(msg.sender,address(this))>=investment,"Approve Your Token First");
		MATIC.transferFrom(msg.sender ,owner,investment);
		emit LevelUpgrade( investorId,investment,msg.sender,levelNAme);
	}

    function multisendMATIC(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
       
    }
    
    function multisendToken(address payable[]  memory  _contributors, uint256[] memory _balances, uint256 totalQty,uint256[] memory NetAmt,uint256[]  memory  _investorId) public payable {
    	uint256 total = totalQty;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i]);
            total = total.sub(_balances[i]);
            MATIC.transferFrom(msg.sender, _contributors[i], _balances[i]);
		  emit MemberPayment( _investorId[i], _contributors[i],_balances[i],NetAmt[i]);
      }
		emit Payment(totalQty);
        
    }
    
	function multisendWithdraw(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
    	require(msg.sender == owner, "onlyOwner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
              MATIC.transfer(_contributors[i], _balances[i]);
        }   
    } 
    
    function withdrawLostMATICFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
    
    function withdrawincome(string memory investorId,address payable _userAddress,uint256 WithAmt) public {
        require(msg.sender == owner, "onlyOwner");
        MATIC.transferFrom(msg.sender,_userAddress, WithAmt);
        emit WithDraw(investorId,_userAddress,WithAmt);
    }
     
	function withdrawLostTokenFromBalance(uint QtyAmt) public 
	{
        require(msg.sender == owner, "onlyOwner");
        MATIC.transfer(owner,QtyAmt);
	}
	
}