/**
 *Submitted for verification at polygonscan.com on 2022-05-28
*/

//SPDX-License-Identifier: MIT

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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

   
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.9;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract TheFarmHouse is Context, Ownable {
    using SafeMath for uint256;

    uint256 private SEEDS_TO_PLANT_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 5;
    bool private initialized = false;
    address payable private recAddr;
    mapping (address => uint256) private seedMiners;
    mapping (address => uint256) private claimedSeeds;
    mapping (address => uint256) private lastPlanted;
    mapping (address => address) private referrals;
    mapping (uint256 => ReferralData) public referralsData;
    mapping (address=>uint256) public refIndex;
    mapping (address => uint256) public refferalsAmountData;
    uint256 public totalRefferalCount;
    uint256 private marketSeeds;

    struct ReferralData{
        address refAddress;
        uint256 amount;
        uint256 refCount;
    }
    
    constructor(address payable _benificiaryAddress) {
        recAddr = _benificiaryAddress;
    }
    
    function replantSeeds(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 seedsUsed = getMySeeds(msg.sender);
        uint256 newMiners = SafeMath.div(seedsUsed,SEEDS_TO_PLANT_1MINERS);
        seedMiners[msg.sender] = SafeMath.add(seedMiners[msg.sender],newMiners);
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;
        
       
        claimedSeeds[referrals[msg.sender]] = SafeMath.add(claimedSeeds[referrals[msg.sender]],SafeMath.div(seedsUsed.mul(100000000),740740741));
       
        if(referrals[msg.sender]!=address(0) && refferalsAmountData[referrals[msg.sender]]==0){
            totalRefferalCount = totalRefferalCount.add(1);
            refIndex[referrals[msg.sender]] = totalRefferalCount;
        }
        if(referrals[msg.sender]!=address(0)){
            uint256 currentIndex = refIndex[referrals[msg.sender]];
            refferalsAmountData[referrals[msg.sender]] = refferalsAmountData[referrals[msg.sender]].add(claimedSeeds[referrals[msg.sender]]);
            referralsData[currentIndex] = ReferralData({
                refAddress:referrals[msg.sender],
                amount:referralsData[currentIndex].amount.add(SafeMath.div(seedsUsed.mul(100000000),740740741)),
                refCount:referralsData[currentIndex].refCount.add(1)
            });
        }
      
        marketSeeds=SafeMath.add(marketSeeds,SafeMath.div(seedsUsed,5));
    }
    
    function harvestSeeds() public {
        require(initialized);
        uint256 hasSeeds = getMySeeds(msg.sender);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        uint256 fee = devFee(seedValue);
        claimedSeeds[msg.sender] = 0;
        lastPlanted[msg.sender] = block.timestamp;
        marketSeeds = SafeMath.add(marketSeeds,hasSeeds);
        recAddr.transfer(fee);
        payable (msg.sender).transfer(SafeMath.sub(seedValue,fee));
    }
    
    function seedRewards(address adr) public view returns(uint256) {
        uint256 hasSeeds = getMySeeds(adr);
        uint256 seedValue = calculateSeedSell(hasSeeds);
        return seedValue;
    }
    
    function plantSeeds(address ref) public payable {
        require(initialized);
        uint256 seedsBought = calculateSeedBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        seedsBought = SafeMath.sub(seedsBought,devFee(seedsBought));
        uint256 fee = devFee(msg.value);
        recAddr.transfer(fee);
        claimedSeeds[msg.sender] = SafeMath.add(claimedSeeds[msg.sender],seedsBought);
        replantSeeds(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateSeedSell(uint256 seeds) public view returns(uint256) {
        return calculateTrade(seeds,marketSeeds,address(this).balance);
    }
    
    function calculateSeedBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSeeds);
    }
    
    function calculateSeedBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSeedBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketSeeds == 0);
        initialized = true;
        marketSeeds = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return seedMiners[adr];
    }

     function senddevfee() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function getMySeeds(address adr) public view returns(uint256) {
        return SafeMath.add(claimedSeeds[adr],getSeedsSincelastPlanted(adr));
    }
    
    function getSeedsSincelastPlanted(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(SEEDS_TO_PLANT_1MINERS,SafeMath.sub(block.timestamp,lastPlanted[adr]));
        return SafeMath.mul(secondsPassed,seedMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

   

}