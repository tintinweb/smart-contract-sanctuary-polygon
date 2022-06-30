/**
 *Submitted for verification at polygonscan.com on 2022-06-29
*/

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
    address public _treasury;
    address public _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);

      _marketing = 0xa63cf83F0ed51e93D746A923795C382b0C4491C4; //account 2
      _treasury = 0x894762C3f2607f5aBC8441E11Cfe29DCc28F8863; //acccount 3
      _owners = 0x06aFaa4595e38587Ad2a336023F54C3b72551e0f; // account 4
    }

    /**
    * @dev Returns the address of the current owner.
    */
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

contract BarrelMine is Context, Ownable {
    using SafeMath for uint256;

    uint256 private OIL_TO_HATCH_1MINERS = 1080000;// Secounds
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private marketingSVal = 2;//at time for buy 
    uint256 private marketingBVal =2; //at time for buy 
    uint256 private treasurySVal = 5; //at time for sell Treasury 
    uint256 private treasuryBval = 10;//at time for buy Treasury 
    uint256 private ownerVal = 6;// at time of buy 
    bool private initialized = false;
    address payable private treasAdd;
    address payable private marketingAdd;
    address payable private RecAdd;
    address payable private OwnersAdd;
    
    mapping (address => uint256) private oilMiners;
    mapping (address => uint256) private claimedBarrel;
    mapping (address => uint256) private lastHarvest;
    mapping (address => address) private referrals;
    uint256 private marketBarrels;
    
    constructor() { 
        treasAdd = payable(_treasury);
        marketingAdd = payable(_marketing);
        OwnersAdd = payable(_owners);
        RecAdd=payable(msg.sender);
    }
    
    function harvestBarrels(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 barrelsUsed = getMyBarrels(msg.sender);
        uint256 newMiners = SafeMath.div(barrelsUsed,OIL_TO_HATCH_1MINERS);
        oilMiners[msg.sender] = SafeMath.add(oilMiners[msg.sender],newMiners);
        claimedBarrel[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        
        //send referral barrels
        claimedBarrel[referrals[msg.sender]] = SafeMath.add(claimedBarrel[referrals[msg.sender]],SafeMath.div(barrelsUsed,8));
        
        //boost market to nerf miners hoarding
        marketBarrels=SafeMath.add(marketBarrels,SafeMath.div(barrelsUsed,5));
    }
    
    function sellBarrels() public {
        require(initialized);
        uint256 hasBarrels = getMyBarrels(msg.sender);
        uint256 oilValue = calculateBarrelSell(hasBarrels);
        uint256 fee1 = marketingS(oilValue);
        uint256 fee2 = treasuryS(oilValue);
        
        claimedBarrel[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketBarrels = SafeMath.add(marketBarrels,hasBarrels);
        treasAdd.transfer(fee1);
        marketingAdd.transfer(fee2);        
        payable (msg.sender).transfer(oilValue);

    }
    
    function oilRewards(address adr) public view returns(uint256) {
        uint256 hasBarrels = getMyBarrels(adr);
        uint256 oilValue = calculateBarrelSell(hasBarrels);
        return oilValue;
    }
    
    function buyBarrels(address ref) public payable {
        require(initialized);
        uint256 barrelsBought = calculateBarrelBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
      
        barrelsBought = SafeMath.sub(barrelsBought,marketingB(barrelsBought));
        barrelsBought = SafeMath.sub(barrelsBought,treasuryB(barrelsBought));
        barrelsBought = SafeMath.sub(barrelsBought,ownerFee(barrelsBought));

       
        uint256 fee1 = marketingB(msg.value);
        uint256 fee2 = treasuryB(msg.value);
        uint256 fee3 = ownerFee(msg.value);
        treasAdd.transfer(fee1);
        marketingAdd.transfer(fee2);
        OwnersAdd.transfer(fee3);
        

        claimedBarrel[msg.sender] = SafeMath.add(claimedBarrel[msg.sender],barrelsBought);
        harvestBarrels(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateBarrelSell(uint256 barrels) public view returns(uint256) {
        return calculateTrade(barrels,marketBarrels,address(this).balance);
    }
    
    function calculateBarrelBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketBarrels);
    }
    
    function calculateBarrelBuySimple(uint256 eth) public view returns(uint256) {
        eth=eth*10**18;
        return calculateBarrelBuy(eth,address(this).balance);
    }
    
    function marketingS(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingSVal),100);
    }

    function marketingB(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,marketingBVal),100);
    }
    
    function treasuryS(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,treasurySVal),100);
    }

    function ownerFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,ownerVal),100);
    }

    function treasuryB(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,treasuryBval),100);
    }

  

    function openMines() public payable onlyOwner {
        require(marketBarrels == 0);
        initialized = true;
        marketBarrels = 108000000000;
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return oilMiners[adr];
    }
    
    function getMyBarrels(address adr) public view returns(uint256) {
        return SafeMath.add(claimedBarrel[adr],getBarrelsSinceLastHarvest(adr));
    }
    
    function getBarrelsSinceLastHarvest(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(OIL_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastHarvest[adr]));
        return SafeMath.mul(secondsPassed,oilMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}