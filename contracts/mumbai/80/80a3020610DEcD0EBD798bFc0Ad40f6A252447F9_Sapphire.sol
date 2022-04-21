/**
 *Submitted for verification at polygonscan.com on 2022-04-20
*/

// SPDX-License-Identifier: UNLICENSED

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
    address public _marketing;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
      _marketing = 0x7f6997dB9143244498501E48a30223Adec3cA86D;
      
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

contract Sapphire is Context, Ownable {
    using SafeMath for uint256;

    uint256 private SAPPHIRE_TO_HATCH_1MINERS = 1080000;//for final version should be seconds in a day
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    uint256 private marketingFeeVal = 3;
    bool private initialized = false;
    address payable private recAdd;
    address payable private marketingAdd;
    mapping (address => uint256) private sapphireMiners;
    mapping (address => uint256) private claimedSapphire;
    mapping (address => uint256) private lastHarvest;
    mapping (address => address) private referrals;
    uint256 private marketSapphires;
    
    constructor() { 
        recAdd = payable(msg.sender);
        marketingAdd = payable(_marketing);
        
    }
    
    function harvestSapphires(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 sapphiresUsed = getMySapphires(msg.sender);
        uint256 newMiners = SafeMath.div(sapphiresUsed,SAPPHIRE_TO_HATCH_1MINERS);
        sapphireMiners[msg.sender] = SafeMath.add(sapphireMiners[msg.sender],newMiners);
        claimedSapphire[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        
        //send referral sapphires
        claimedSapphire[referrals[msg.sender]] = SafeMath.add(claimedSapphire[referrals[msg.sender]],SafeMath.div(sapphiresUsed,8));
        
        //boost market to nerf miners hoarding
        marketSapphires=SafeMath.add(marketSapphires,SafeMath.div(sapphiresUsed,5));
    }
    
    function sellSapphires() public {
        require(initialized);
        uint256 hasSapphires = getMySapphires(msg.sender);
        uint256 sapphireValue = calculateSapphireSell(hasSapphires);
        uint256 fee1 = devFee(sapphireValue);
        uint256 fee2 = marketingFee(sapphireValue);
        claimedSapphire[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketSapphires = SafeMath.add(marketSapphires,hasSapphires);
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);        
        payable (msg.sender).transfer(SafeMath.sub(sapphireValue,fee1));

    }
    
    function sapphireRewards(address adr) public view returns(uint256) {
        uint256 hasSapphires = getMySapphires(adr);
        uint256 sapphireValue = calculateSapphireSell(hasSapphires);
        return sapphireValue;
    }
    
    function buySapphires(address ref) public payable {
        require(initialized);
        uint256 sapphiresBought = calculateSapphireBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        sapphiresBought = SafeMath.sub(sapphiresBought,devFee(sapphiresBought));
        sapphiresBought = SafeMath.sub(sapphiresBought,marketingFee(sapphiresBought));
        

        uint256 fee1 = devFee(msg.value);
        uint256 fee2 = marketingFee(msg.value);
        
        recAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        

        claimedSapphire[msg.sender] = SafeMath.add(claimedSapphire[msg.sender],sapphiresBought);
        harvestSapphires(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateSapphireSell(uint256 sapphires) public view returns(uint256) {
        return calculateTrade(sapphires,marketSapphires,address(this).balance);
    }
    
    function calculateSapphireBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketSapphires);
    }
    
    function calculateSapphireBuySimple(uint256 eth) public view returns(uint256) {
        return calculateSapphireBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }

    function marketingFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingFeeVal),100);
    }
    

    function openMines() public payable onlyOwner {
        require(marketSapphires == 0);
        initialized = true;
        marketSapphires = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return sapphireMiners[adr];
    }
    
    function getMySapphires(address adr) public view returns(uint256) {
        return SafeMath.add(claimedSapphire[adr],getSapphiresSinceLastHarvest(adr));
    }
    
    function getSapphiresSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(SAPPHIRE_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,sapphireMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}