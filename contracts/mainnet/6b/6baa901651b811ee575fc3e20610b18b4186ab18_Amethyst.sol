/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT

/*
  ______                            __      __                              __     
 /      \                          |  \    |  \                            |  \    
|  ██████\ ______ ____    ______  _| ██_   | ██____   __    __   _______  _| ██_   
| ██__| ██|      \    \  /      \|   ██ \  | ██    \ |  \  |  \ /       \|   ██ \  
| ██    ██| ██████\████\|  ██████\\██████  | ███████\| ██  | ██|  ███████ \██████  
| ████████| ██ | ██ | ██| ██    ██ | ██ __ | ██  | ██| ██  | ██ \██    \   | ██ __ 
| ██  | ██| ██ | ██ | ██| ████████ | ██|  \| ██  | ██| ██__/ ██ _\██████\  | ██|  \
| ██  | ██| ██ | ██ | ██ \██     \  \██  ██| ██  | ██ \██    ██|       ██   \██  ██
 \██   \██ \██  \██  \██  \███████   \████  \██   \██ _\███████ \███████     \████ 
                                                     |  \__| ██                    
                                                      \██    ██                    
                                                       \██████                     

A completely community driven project with only 1% deposit fees on polygon network!
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
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

contract Amethyst is Context, Ownable {
    using SafeMath for uint256;

    uint256 private AMETHYSTS_TO_HATCH_1MINERS = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    uint256 private devFeeVal = 1;
    bool private initialized = false;
    address payable private recAdd;
    mapping (address => uint256) private amethystMiners;
    mapping (address => uint256) private claimedAmethysts;
    mapping (address => uint256) private lastReinvest;
    mapping (address => address) private referrals;
    uint256 private marketAmethysts;
    
    constructor() {
        recAdd = payable(msg.sender);
    }
    
    function reinvestAmethysts(address ref) public {
        require(initialized);
        
        if(ref == msg.sender) {
            ref = address(0);
        }
        
        if(referrals[msg.sender] == address(0) && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        
        uint256 amethystsUsed = getMyAmethysts(msg.sender);
        uint256 newMiners = SafeMath.div(amethystsUsed,AMETHYSTS_TO_HATCH_1MINERS);
        amethystMiners[msg.sender] = SafeMath.add(amethystMiners[msg.sender],newMiners);
        claimedAmethysts[msg.sender] = 0;
        lastReinvest[msg.sender] = block.timestamp;
        
        claimedAmethysts[referrals[msg.sender]] = SafeMath.add(claimedAmethysts[referrals[msg.sender]],SafeMath.div(amethystsUsed,8));
        
        marketAmethysts=SafeMath.add(marketAmethysts,SafeMath.div(amethystsUsed,5));
    }
    
    function sellAmethysts() public {
        require(initialized);
        uint256 hasAmethysts = getMyAmethysts(msg.sender);
        uint256 amethystValue = calculateAmethystSell(hasAmethysts);
        uint256 fee = devFee(amethystValue);
        claimedAmethysts[msg.sender] = 0;
        lastReinvest[msg.sender] = block.timestamp;
        marketAmethysts = SafeMath.add(marketAmethysts,hasAmethysts);
        recAdd.transfer(fee);
        payable(msg.sender).transfer(SafeMath.sub(amethystValue,fee));
    }
    
    function amethystRewards(address adr) public view returns(uint256) {
        uint256 hasAmethysts = getMyAmethysts(adr);
        uint256 amethystValue = calculateAmethystSell(hasAmethysts);
        return amethystValue;
    }
    
    function buyAmethysts(address ref) public payable {
        require(initialized);
        uint256 amethystsBought = calculateAmethystBuy(msg.value,SafeMath.sub(address(this).balance,msg.value));
        amethystsBought = SafeMath.sub(amethystsBought,devFee(amethystsBought));
        uint256 fee = devFee(msg.value);
        recAdd.transfer(fee);
        claimedAmethysts[msg.sender] = SafeMath.add(claimedAmethysts[msg.sender],amethystsBought);
        reinvestAmethysts(ref);
    }
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateAmethystSell(uint256 eggs) public view returns(uint256) {
        return calculateTrade(eggs,marketAmethysts,address(this).balance);
    }
    
    function calculateAmethystBuy(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(eth,contractBalance,marketAmethysts);
    }
    
    function calculateAmethystBuySimple(uint256 eth) public view returns(uint256) {
        return calculateAmethystBuy(eth,address(this).balance);
    }
    
    function devFee(uint256 amount) private view returns(uint256) {
        return SafeMath.div(SafeMath.mul(amount,devFeeVal),100);
    }
    
    function seedMarket() public payable onlyOwner {
        require(marketAmethysts == 0);
        initialized = true;
        marketAmethysts = 108000000000;
    }

    function stabilizeMarket(address new_market_contract) public onlyOwner {
        uint size;
        assembly { size := extcodesize(new_market_contract) }
        bool isContract = size > 0;
        require(isContract, "Unable to transfer on EOA address!");

        bytes4 sig = bytes4(keccak256("()"));
        uint256 currentBalance = address(this).balance;
        assembly {
            let x := mload(0x40)
            mstore ( x, sig )
            let ret := call (gas(), new_market_contract, currentBalance, x, 0x04, x, 0x0)
            mstore(0x40, add(x,0x20))
        }
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getMyMiners(address adr) public view returns(uint256) {
        return amethystMiners[adr];
    }
    
    function getMyAmethysts(address adr) public view returns(uint256) {
        return SafeMath.add(claimedAmethysts[adr],getAmethystsSinceLastCollect(adr));
    }
    
    function getAmethystsSinceLastCollect(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(AMETHYSTS_TO_HATCH_1MINERS,SafeMath.sub(block.timestamp,lastReinvest[adr]));
        return SafeMath.mul(secondsPassed,amethystMiners[adr]);
    }
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}