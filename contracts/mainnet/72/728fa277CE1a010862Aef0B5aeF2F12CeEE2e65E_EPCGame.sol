/**
 *Submitted for verification at polygonscan.com on 2022-10-18
*/

/**
 *Submitted for verification at polygonscan.com on 2022-09-26
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

contract EPCGame{
     using SafeMath for uint256;
    ERC20 testToken;

    address public owner; 
    address payable public devAddress; 
    
    event onWithdraw(address  _user, uint256 amount);
    event BuyGameSlot(address  _user, uint256 gameSize, uint256 isAddedd);

    constructor(address ownerAddress, address payable _devAddress, ERC20 testToken_) public 
    {
        owner = ownerAddress;
        devAddress=_devAddress; 
        testToken=testToken_;
    } 
    

    function withdrawBalance(uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner!");
        msg.sender.transfer(amt);
    }  

    function withdrawToken(ERC20 token,uint256 amt) public 
    {
        require(msg.sender == owner, "onlyOwner");
        token.transfer(msg.sender,amt);       
    } 

    function buyGameSlot(uint256 amount) payable public 
    {
        require(amount>1e18, "Insufficient Amount!"); 
        uint256 gameSize=amount/1e18;            
        testToken.transferFrom(msg.sender,owner,amount); 
        emit BuyGameSlot(msg.sender, gameSize,0);
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function transferOwnerShip(address newOwner) public
    {
        require(msg.sender == owner, "onlyOwner");
        owner = newOwner;
    }
}