// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Lottery {
    using SafeMath for uint256;
    
    struct holder {
        address holderAddress;
        uint256 mintPrice;
    }

    mapping(uint16 => holder) public holderInfo;  // tokenid ---> holder addr & holder mint price

    uint16[] public roundPlayersLeft;

    mapping(uint8 => uint16[]) public roundWinners;

    mapping(uint8 => mapping(uint16 => uint256)) public roundPrizes;

    uint256 public nonce = 0;
    
    uint8 public currentCritRound = 1;
    uint256 public totalusdcInPot;

    event PrizeDraw(
        uint256 indexed critRound,
        uint256 indexed prizeCategory,
        address indexed winner,
        uint16 tokenId,
        uint256 mintPrice,
        uint256 multiplierPercentage, 
        uint256 prizeAmount
    );

    event PrizeTransferred(
        uint256 indexed critRound,
        address indexed winner,
        uint256 tokenId,
        uint256 prizeAmount
    );

    IERC20 public usdc;

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() {
        usdc = IERC20(0xE097d6B3100777DC31B34dC2c58fB524C2e76921);
        owner = msg.sender;
    }


    function setHolderInfoMapping(uint16[] memory tokenIds, address[] memory holderAddress, uint256[] memory mintPrices) external onlyOwner {
        require(tokenIds.length == holderAddress.length, "Invalid inputs");
        require(tokenIds.length == mintPrices.length, "Invalid inputs");
     
        for (uint16 i = 0; i < tokenIds.length; i++) {
            holderInfo[tokenIds[i]] = holder(holderAddress[i], mintPrices[i]);
        }
    }

    uint256 randomNumber = 123;

    // Tipsy Prize
    function drawTipsyPrize(uint16[] memory tokenIds) external onlyOwner {
        
        uint256 numWinners = tokenIds.length.mul(22).div(100); 
        uint256 boundary = numWinners.mul(3).div(4);
        uint16 tokenId;
        address winner;
        uint256 mintPrice;
        uint256 multiplierPercentage;
        uint256 prizeAmount;

        roundPlayersLeft = tokenIds;

        // uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, nonce)));

        for (uint256 j = 0; j < numWinners; j++) {
            if (j < boundary) {
                (tokenId, multiplierPercentage) = getRandomNum(15, 20);
            } else {
                (tokenId, multiplierPercentage) = getRandomNum(20, 35);
            }
            // get winner address
            winner = holderInfo[tokenId].holderAddress;
            // get win price
            mintPrice = holderInfo[tokenId].mintPrice;
            prizeAmount = mintPrice.mul(multiplierPercentage).div(100);
            
            roundWinners[currentCritRound].push(tokenId);
            roundPrizes[currentCritRound][tokenId] = prizeAmount;
            emit PrizeDraw(currentCritRound, 0, winner, tokenId, mintPrice, multiplierPercentage, prizeAmount);
        }

    }

   
    function transferPrize(uint8 _currentCritRound, uint16 start, uint16 end) external onlyOwner {
        uint16 tokenId;
        address winner;
        uint256 prizeAmount;


        for (uint256 i = start; i < end; i++) {
            tokenId = roundWinners[_currentCritRound][i];
            winner = holderInfo[tokenId].holderAddress;
            prizeAmount = roundPrizes[_currentCritRound][tokenId];

            usdc.transfer(winner, prizeAmount);
            roundPrizes[_currentCritRound][tokenId] = 0;

            emit PrizeTransferred(_currentCritRound, winner, tokenId, prizeAmount);
            
            totalusdcInPot = totalusdcInPot.sub(prizeAmount);
        }      
        // currentCritRound++;   

    }

    function getRandomNum(uint256 min, uint256 max) internal returns (uint16, uint256) {
        // uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, nonce)));
        uint256 randomIndex = randomNumber.mod(roundPlayersLeft.length);
        uint16 tokenId = roundPlayersLeft[randomIndex];
        uint256 multiplierPercentage = randomNumber.mod(max.sub(min)).add(min);
        removeWinners(randomIndex);
        nonce++;
        return (tokenId, multiplierPercentage);
    }

    function removeWinners(uint256 randomIndex) internal {
        // 检查索引是否有效
        uint256 namesLength = roundPlayersLeft.length;
        require(randomIndex < namesLength, "Index out of range.");

        // 使用数组的最后一个元素覆盖要删除的元素
        
        uint16 lastElement = roundPlayersLeft[namesLength - 1];
        roundPlayersLeft[randomIndex] = lastElement;

        // 删除最后一个元素并减小数组长度
        roundPlayersLeft.pop();
    }

    function withdrawusdc(address _to, uint256 _amount) public onlyOwner{
        require(usdc.balanceOf(address(this)) >= _amount, "Insufficient usdc balance in contract");
        require(usdc.transfer(_to, _amount), "Failed to transfer usdc from contract");
        // totalusdcInPot -= _amount;
    }

    function getusdcBalance() public onlyOwner returns (uint256) {
        totalusdcInPot = usdc.balanceOf(address(this));
        return totalusdcInPot;
    }

    function getRoundPlayersLeft() public view returns (uint16[] memory) {
        return roundPlayersLeft;
    }


    function getRoundWinners(uint8 _currentCritRound) public view returns (uint16[] memory) {
        return roundWinners[_currentCritRound];
    }

}