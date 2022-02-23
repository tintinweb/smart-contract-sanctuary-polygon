/**
 *Submitted for verification at polygonscan.com on 2022-02-22
*/

// SPDX-License-Identifier: none
pragma solidity ^0.8.11;
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
interface AggregatorV3Interface {

  function decimals() external view returns (uint);
  function description() external view returns (string memory);
  function version() external view returns (uint);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint roundId,
      uint answer,
      uint startedAt,
      uint updatedAt,
      uint answeredInRound
    );

}

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    constructor() {
        priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada); // Mainnet MATIC/USD 
    }

    function getThePrice() public view returns (uint) {
        (
            uint roundID, 
            uint price,
            uint startedAt,
            uint timeStamp,
            uint answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }
}

interface BEP20 {
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



contract AnheraPOLY is Ownable {  
    PriceConsumerV3 priceConsumerV3 = new PriceConsumerV3();
    uint public priceOfMATIC = priceConsumerV3.getThePrice();

    uint public tokenPrice         = 45;
    uint public tokenPriceDecimal  = 2;
    address public tokenAddr       = 0xE1B7eaDE23ee96c5111c099C9BE7F018be048E6C;
    BEP20 token; 
    address contractAddress = address(this);
    constructor() {
        token = BEP20(tokenAddr);
    }
    using SafeMath for uint256;       
    event DepositAt(address user, uint tariff, uint amount);    

    function buyToken(uint _token) public payable {        
        require(msg.value > 0, "Zero value");     
        emit DepositAt(msg.sender, 0, _token);
    }

    function withdrawalToAddress(address payable _to, address _token, uint _amount) external{
        require(msg.sender == owner);
        require(_amount != 0, "Zero amount error");
        BEP20 tokenObj;
        uint amount   = _amount * 10**18;
        tokenObj = BEP20(_token);
        tokenObj.transfer(_to, amount);
    }
    // Only owner can withdraw from contract
    function withdrawMatic(address payable _to, uint _amount) public {
        require(msg.sender == owner, "Only owner");
        require(_amount != 0, "Zero withdrawal");
        _to.transfer(_amount);
    }
    function tokenInMATIC(uint amount) public view returns (uint) {
        uint tokenVal = ( amount * priceOfMATIC* 10**tokenPriceDecimal) /(tokenPrice*100000000);
        return tokenVal;
    } 
    /*
    like tokenPrice = 0.05
    setBuyPrice = 5
    tokenPriceDecimal= 2
    */
    // Set buy price  
    function setBuyPrice(uint _price, uint _decimal) public {
      require(msg.sender == owner, "Only owner");
      tokenPrice        = _price;
      tokenPriceDecimal = _decimal;
    }
    function updateLiveMaticPrice() public returns(bool) {
        priceOfMATIC = priceConsumerV3.getThePrice();
        return true;
    } 
    function transferOwnership(address _to) public {
        require(msg.sender == owner, "Only owner");
        address oldOwner  = owner;
        owner = _to;
        emit OwnershipTransferred(oldOwner,_to);
    }
}