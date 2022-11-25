/**
 *Submitted for verification at polygonscan.com on 2022-11-25
*/

pragma solidity ^0.4.17;

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

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract token { function transfer(address receiver, uint amount){  } }
contract FLINTCrowdsale {
  using SafeMath for uint256;

  address public wallet;
  address public addressOfTokenUsedAsReward;

  token tokenReward;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function FLINTCrowdsale() {
    wallet = 0x81723063ead5c32c64ed419a95dc916d6b71aada;
    addressOfTokenUsedAsReward = 0x7f30cc218f7f27b94070cbd35821ce17b2818dfe;

    tokenReward = token(addressOfTokenUsedAsReward);
   
    startTime = now + 30 * 1 minutes;
    endTime = startTime + 35*24*60 * 1 minutes;
  }

  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint price;

    if(weiRaised < 222*10**18){
      price = 600;
    }else if(weiRaised < 35777*10**18){
      price = 450;
    }else{
      price = 300;
    }

    uint256 tokens = (weiAmount) * price;

    weiRaised = weiRaised.add(weiAmount);

    tokenReward.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function forwardFunds() internal {
    if (!wallet.send(msg.value)) {
      throw;
    }
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }

  function withdrawTokens(uint256 _amount) {
    if(msg.sender!=wallet) throw;
    tokenReward.transfer(wallet,_amount);
     
  }
}