/**
 *Submitted for verification at polygonscan.com on 2022-09-10
*/

pragma solidity >=0.6.0 <0.9.0;

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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
//File: "@openzeppelin/contracts/access/Ownable.sol";
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
    abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
*  Smart contract enabling funding and swapping of SEEDX/USDT pair.
*  The rate is defined by the owner of the contract.
*  The price of token in USDT is 1/rate. Eg for 1 USDT the sender will get rate number of tokens.
*/
contract SeedxSwap is Ownable {
  using SafeMath for uint256;

  uint public creationTime = block.timestamp;
  uint public buy_rate = uint256(1000).mul(1e18).div(1e3); // 1 token for 1 USDT
  uint public sell_rate = uint256(750).mul(1e18).div(1e3); // 1 token for 0.75 USDT
  IERC20 private SeedX;
  IERC20 private USDT;

  event BuyToken(address user, uint amount, uint usdtAmount, uint balance);
  event SellToken(address user, uint amount, uint usdtAmount, uint balance);
  event WithdrawSeedX(address from, address to, uint256 seedxAmount);
  event WithdrawUSDT(address from, address to, uint256 usdtAmount);


  /**
  * constructor
  */
  constructor(address seedxContract, address usdtContract) {
    SeedX = IERC20(seedxContract);
    USDT = IERC20(usdtContract);
  }

  /**
  * Sender requests to buy [amount] of tokens from the contract.
  * Sender needs to send enough USDT to buy the tokens at a price of amount / rate
  */
  function buyToken(uint amount) public returns (bool success) {
    // ensure enough tokens are owned by the depositor
    uint usdtAmount = amount.mul(buy_rate).div(1e30);
    require(USDT.balanceOf(msg.sender) >= usdtAmount,"Address: Insufficient usdt to buy seedx.");
    require(SeedX.balanceOf(address(this)) >= amount,"Contract: Insufficient Seedx balance.");
    require(USDT.transferFrom(msg.sender,address(this), usdtAmount));
    require(SeedX.transfer(msg.sender,amount));

    emit BuyToken(msg.sender, amount, usdtAmount, SeedX.balanceOf(msg.sender));

    return true;
  }

  /**
  *  Sender requests to sell [amount] of tokens to the contract in return of Eth.
  */
  function sellToken(uint amount) public returns (bool success) {
    // ensure enough funds
    uint usdtAmount = amount.mul(sell_rate).div(1e30);
    require(USDT.balanceOf(address(this)) >= usdtAmount,"Contract: Insufficient usdt balance.");
    require(SeedX.balanceOf(msg.sender) >= amount,"Address: Insufficient seedx balance.");
    require(SeedX.transferFrom(msg.sender,address(this),amount));
    require(USDT.transfer(msg.sender, usdtAmount));

    emit SellToken(msg.sender, amount, usdtAmount, SeedX.balanceOf(msg.sender));

    return true;
  }
/**
  *  Sender must be owner to requests to withdraw all [totalUsdt,totalSeedX] of tokens from the contract.
  */
  function withdrawUsdt() public onlyOwner {
    uint256 totalUsdt = USDT.balanceOf(address(this));
    require(totalUsdt > 0, "No USDT present in swap contract");
    require(USDT.transfer(msg.sender,totalUsdt), "Failed to withdraw USDT");

    emit WithdrawUSDT(address(this), msg.sender, totalUsdt);
  }

  /**
  *  Sender must be owner to requests to withdraw all [totalUsdt,totalSeedX] of tokens from the contract.
  */
  function withdrawSeedx() public onlyOwner {
    uint256 totalSeedX = SeedX.balanceOf(address(this));
    require(totalSeedX > 0, "No Seedx present in swap contract");
    require(SeedX.transfer(msg.sender,totalSeedX), "Failed to withdraw SeedX");

    emit WithdrawSeedX(address(this), msg.sender, totalSeedX);
  }

  /**
  *  To update the buy and sell rate there need to multiple new rate with 1000
  *  then send it in below updating methods 
  *  LIKE: 
  *       Want to set buy rate 2 then multiple it with 1000 and then pass in updateBuyRate(2*1000).
  *       Same like for updateSellRate(1.5*1000).
  */


  function updateBuyRate(uint newRate) onlyOwner public returns (bool success) {
    // make sure buy rate is never less than zero
    require(newRate >= 0,"new buy rate can't be zero");
    buy_rate = newRate.mul(1e18).div(1e3);
    return true;
  }
  function updateSellRate(uint newRate) onlyOwner public returns (bool success) {
    // make sure sell rate is never less than zero
    require(newRate >= 0,"new sell rate can't be zero");
    sell_rate = newRate.mul(1e18).div(1e3);
    return true;
  }
}