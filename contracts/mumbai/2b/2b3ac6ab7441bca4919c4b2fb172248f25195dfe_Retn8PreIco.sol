/**
 *Submitted for verification at polygonscan.com on 2022-07-01
*/

pragma solidity ^0.4.16;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }
}

/**
 * @title Token
 * @dev API interface for interacting with the WILD Token contract 
 */
interface Token {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address _owner) constant returns (uint256 balance);
}

contract Retn8PreIco is Ownable {

  using SafeMath for uint256;

  Token token;

  uint256 public constant START = 1656637172; // 10/25/2017 @ 12:00pm (UTC)
  uint256 public constant DAYS = 21; 
  uint public creationTime;
  uint256 public constant initialTokens = 15000 * 10**9; // Initial number of tokens available
  bool public initialized = false;
  uint256 public raisedAmount = 0;

  event BoughtTokens(address indexed to, uint256 value, uint256 priceValue);

  modifier whenSaleIsActive() {
    // Check if sale is active
    require(isActive());

    _;
  }

  function Retn8PreIco(address _tokenAddr) {
      require(_tokenAddr != address(0));
      token = Token(_tokenAddr);
  }
  
  function initialize() onlyOwner {
      require(initialized == false); // Can only be initialized once
      require(tokensAvailable() >= initialTokens); // Must have enough tokens allocated
      initialized = true;
      creationTime = now;
  }

  function isActive() constant returns (bool) {
    return (
        initialized == true &&
        now >= START && // Must be after the START date
        now <= START.add(DAYS * 1 days) && // Must be before the end date
        tokensAvailable() > 0 // Tokens should be available
    );
  }

  function goalReached() constant returns (bool) {
    return (initialized == true && tokensAvailable() == 0);
  }

  function () payable {
    buyTokens();
  }

  /**
  * @dev function that sells available tokens
  */
  function buyTokens() payable whenSaleIsActive {
    // Calculate tokens to sell
    uint256 weiAmount = msg.value;
    uint256 rate = getRate();
    uint256 tokens = weiAmount.mul(rate);
    require(tokensAvailable() >= tokens);
    BoughtTokens(msg.sender, tokens, weiAmount);

    // Increment raised amount
    raisedAmount = raisedAmount.add(msg.value);
    
    // Send tokens to buyer
    token.transfer(msg.sender, tokens);
    
    // Send money to owner
    owner.transfer(msg.value);
  }

  /**
   * @dev returns the number of tokens allocated to this contract
   */
  function tokensAvailable() constant returns (uint256) {
    return token.balanceOf(this);
  }

  /**
   * @dev returns the number of tokens purchased by an address
   */
  function tokenbalanceOf(address from) constant returns (uint256) {
    return token.balanceOf(from);
  }

  function drain() onlyOwner {
  require(!isActive());

    // Transfer tokens back to owner
    uint256 balance = token.balanceOf(this);
    require(balance > 0);
    owner.transfer(this.balance);
    token.transfer(owner, balance);
  }

  /**
   * @notice Get bonus rates
   */
  function getRate() constant returns(uint) {
    if (creationTime + 1 weeks >= now) {
            return 1684; //number of tokens in week 1
    } else if (creationTime + 2 weeks >= now) {
            return 1588; //number of tokens in week 2
    } else if (creationTime + 3 weeks >= now) {
            return 1504; //number of tokens in week 3
    } else {
            return 1203;
    }
  }

}