/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

pragma solidity ^0.4.26; // solhint-disable-line
/*
Grow Avocado Hass- The Matic pool with the finest daily return and highest referral reward
*/

contract GrowAvocadoHass{
    //uint256 SEEDS_PER_MINERS_PER_SECOND=1;
    uint256 public SEEDS_TO_HATCH_1MINERS=864000;//for final version should be seconds in a day
    uint256 PSN=10000;
    uint256 PSNH=5000;
    bool public initialized=false;
    address public ceoAddress;
    mapping (address => uint256) public hatcheryMiners;
    mapping (address => uint256) public claimedSeeds;
    mapping (address => uint256) public lastHatch;
    mapping (address => address) public referrals;
    uint256 public marketSeeds;
    constructor() public{
        ceoAddress=msg.sender;
    }
    function replantAvocado(address ref) public{
        require(initialized);
        if(ref == msg.sender || ref == address(0) || hatcheryMiners[ref] == 0) {
            ref = ceoAddress;
        }
        if(referrals[msg.sender] == address(0)){
            referrals[msg.sender] = ref;
        }
        uint256 seedsUsed=getMySeeds();
        uint256 newMiners=SafeMath.div(seedsUsed,SEEDS_TO_HATCH_1MINERS);
        hatcheryMiners[msg.sender]=SafeMath.add(hatcheryMiners[msg.sender],newMiners);
        claimedSeeds[msg.sender]=0;
        lastHatch[msg.sender]=now;

        //send referral seeds
        claimedSeeds[referrals[msg.sender]]=SafeMath.add(claimedSeeds[referrals[msg.sender]],SafeMath.div(SafeMath.mul(seedsUsed,15),100));

        //boost market to nerf miners hoarding
        marketSeeds=SafeMath.add(marketSeeds,SafeMath.div(seedsUsed,5));
    }
    function eatAvocado() public{
        require(initialized);
        uint256 hasSeeds=getMySeeds();
        uint256 seedValue=calculateSeedSell(hasSeeds);
        uint256 fee=devFee(seedValue);
        claimedSeeds[msg.sender]=0;
        lastHatch[msg.sender]=now;
        marketSeeds=SafeMath.add(marketSeeds,hasSeeds);
        ceoAddress.transfer(fee);
        msg.sender.transfer(SafeMath.sub(seedValue,fee));
    }
    function plantAvocado(address ref) public payable{
        require(initialized);
        uint256 seedsBought=calculateSeedBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        seedsBought=SafeMath.sub(seedsBought,devFee(seedsBought));
        uint256 fee=devFee(msg.value);
        ceoAddress.transfer(fee);
        claimedSeeds[msg.sender]=SafeMath.add(claimedSeeds[msg.sender],seedsBought);
        replantAvocado(ref);
    }

    //magic trade balancing algorithm
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256){
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    function calculateSeedSell(uint256 seeds) public view returns(uint256){
        return calculateTrade(seeds,marketSeeds,address(this).balance);
    }
    function calculateSeedBuy(uint256 eth,uint256 contractBalance) public view returns(uint256){
        return calculateTrade(eth,contractBalance,marketSeeds);
    }
    function calculateSeedBuySimple(uint256 eth) public view returns(uint256){
        return calculateSeedBuy(eth,address(this).balance);
    }
    function devFee(uint256 amount) public pure returns(uint256){
        return SafeMath.div(SafeMath.mul(amount,7),100);
    }
    function openKitchen() public payable{
        require(msg.sender == ceoAddress, 'invalid call');
        require(marketSeeds==0);
        initialized=true;
        marketSeeds=86400000000;
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
    function getMyMiners() public view returns(uint256){
        return hatcheryMiners[msg.sender];
    }
    function getMySeeds() public view returns(uint256){
        return SafeMath.add(claimedSeeds[msg.sender],getSeedsSinceLastHatch(msg.sender));
    }
    function getSeedsSinceLastHatch(address adr) public view returns(uint256){
        uint256 secondsPassed=min(SEEDS_TO_HATCH_1MINERS,SafeMath.sub(now,lastHatch[adr]));
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