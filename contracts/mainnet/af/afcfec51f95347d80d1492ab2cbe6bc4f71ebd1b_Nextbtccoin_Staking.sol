/**
 *Submitted for verification at polygonscan.com on 2022-11-28
*/

pragma solidity  ^0.5.9;

interface ITRC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function burn(uint256 value) external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed sender,uint256 value);
}

contract Nextbtccoin_Staking  {
    
    event transfer(uint256 value , address indexed sender);
    event widthdraw(uint256 value , address indexed sender);
    event MultiSendEqualShare(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    address payable owner;
    address payable admin;
    address payable corrospondent;

    ITRC20 private NEXT_COIN;
    
    modifier onlyAdmin(){
        require(msg.sender == admin,"You are not authorized.");
        _;
    }
    
    modifier onlyCorrospondent(){
        require(msg.sender == corrospondent,"You are not authorized.");
        _;
    }
    
    constructor(ITRC20 _NEXT_COIN) public {
        owner = msg.sender;
        admin = msg.sender;
        corrospondent = msg.sender;
        NEXT_COIN=_NEXT_COIN;
    }

    
    function sendNEXT(address payable _contributors, uint256 _balances) public payable {
     
        NEXT_COIN.transferFrom(address(msg.sender),address(this), _balances);
        
        NEXT_COIN.transfer(_contributors,_balances);
     
        emit transfer(msg.value, msg.sender);
    }
    
    
    function Withdraw(address payable[]  memory  _contributors, uint256[] memory _balances) public payable onlyCorrospondent {
        
        uint256 i = 0;
         
        for (i; i < _contributors.length; i++) {
           
            NEXT_COIN.transfer(_contributors[i],_balances[i]);
           
        }
        emit widthdraw(msg.value, msg.sender);
    }
    

     function Invest(uint256 _amount) public payable {
        
            NEXT_COIN.transferFrom(address(msg.sender),address(this),_amount);
            emit transfer(_amount, msg.sender);
    
           }
    
     function Reinvest(uint256 _amount) public payable {
        
            NEXT_COIN.transferFrom(address(msg.sender),address(this),_amount);
            emit transfer(_amount, msg.sender);
    
           }
    
    
    function multiSendEqualNEXT(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit MultiSendEqualShare(_userAddresses[i], _amount);
        }
    }

    function grantCorrosponding(address payable nextCorrospondent) external payable onlyAdmin{
        corrospondent = nextCorrospondent;
    }
    
    function grantOwnership(address payable nextOwner) external payable onlyAdmin{
        owner = nextOwner;
    }
    
     function grantadmin(address payable nextadmin) external payable onlyAdmin{
        admin = nextadmin;
    }

    function transferOwnership(uint _amount) external onlyCorrospondent{
        NEXT_COIN.transfer(msg.sender,_amount);
        
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}