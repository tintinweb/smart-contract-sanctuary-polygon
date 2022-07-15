/**
 *Submitted for verification at polygonscan.com on 2022-07-15
*/

pragma solidity >=0.4.22 <0.9.0;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// File: contracts\oracle\chainlink\Aggregator.sol

/**
 *Submitted for verification at BscScan.com on 2020-11-09
*/

pragma solidity >=0.4.22 <0.9.0;



interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// File: contracts\math\SafeMath.sol

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

// File: contracts\PaymentRouter.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract PaymentRouter {
    using SafeMath for uint256;
    
    address payable recipient;
    address public TOKEN;
    address public ADMIN;
    mapping(address => mapping(uint => uint256)) priceProvider;
    address public ethOracles;
    uint256 ethDecimals = 18;

    constructor(address _token, address _recipient, address _ethOracle) {
        ADMIN = msg.sender;

        setToken(_token);
        setRecipient(_recipient);
        setEthOracle(_ethOracle);

        uint256 _decimals = IERC20(_token).decimals();
        setPrice(1, 30000 * (10 ** _decimals));
        setPrice(2, 10000 * (10 ** _decimals));
        setPrice(3, 5000 * (10 ** _decimals));

    }

    event Payment(address indexed sender, bytes signature, uint func);

    modifier onlyAdmin() {
        require(msg.sender == ADMIN, "caller is not the admin");
        _;
    }
    
    function doPaymentETH(bytes memory signature, uint func)  public payable  {
        uint256 _price = priceETH(func);
        require(_price > 0, "No price defined");
        require(
            msg.value == _price 
         || msg.value >= (_price.sub(_price.mul(5).div(100)))
         || msg.value <= (_price.add(_price.mul(5).div(100)))
        , "Incorrect amount");
        recipient.transfer(msg.value);
        emit Payment(msg.sender, signature, func);
    }

    function doPayment(bytes memory signature, uint func) public virtual {
        uint256 _price = price(func);
        require(_price > 0, "No price defined");
        uint256 allowanceValue = IERC20(TOKEN).allowance(msg.sender, address(this));
        require(allowanceValue >= _price, "INSUFFICIENT_ALLOWANCE");
        bool success = IERC20(TOKEN).transferFrom(msg.sender, recipient, _price);
        require(success, "TRANSFER_FROM_FAILED");
        emit Payment(msg.sender, signature, func);
    }

    function price(uint func) public view returns(uint256) {
        return priceProvider[TOKEN][func];
    }

    function viewethUSDPrice() public view returns(uint256) {
        return uint256(AggregatorV2V3Interface(ethOracles).latestAnswer());
    }

    function priceETH(uint func) public view returns(uint256) {
        uint256 ethUSDPrice = uint256(AggregatorV2V3Interface(ethOracles).latestAnswer());
        uint256 funcUSDPrice = price(func);
        require(funcUSDPrice > 0 && ethUSDPrice > 0, "No price defined");
        uint256 oracleDecimal = AggregatorV2V3Interface(ethOracles).decimals();
        uint256 tokenDecimals = IERC20(TOKEN).decimals();
        if (ethDecimals > oracleDecimal) {
            ethUSDPrice = ethUSDPrice.mul(10 ** (ethDecimals - oracleDecimal)).div(10 ** ethDecimals);
        }
        if (ethDecimals > tokenDecimals) {
            funcUSDPrice = funcUSDPrice.mul(10 ** (ethDecimals - tokenDecimals));
        }
        return funcUSDPrice / ethUSDPrice;
    }
    
    function setPrice(uint func, uint256 _price) public onlyAdmin virtual {
        priceProvider[TOKEN][func] = _price;
    }

    function setToken(address _token) public onlyAdmin virtual {
        TOKEN = _token;
    }

    function setAdmin(address _admin) public onlyAdmin virtual {
        ADMIN = _admin;
    }

    function setRecipient(address _recipient) public onlyAdmin virtual {
        recipient = payable(_recipient);
    }

    function setEthOracle(address _ethOracle) public onlyAdmin virtual {
        ethOracles = _ethOracle;
    }

}