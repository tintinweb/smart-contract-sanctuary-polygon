// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./uniERC20.sol";
import "./I1InchExchange.sol";

contract OneInchOrderProxy {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using UniERC20 for IERC20;

    enum State {
        Pending,
        Fulfilled,
        Refunded
    }
    struct Order {
        IERC20 srcToken;
        IERC20 dstToken;
        uint256 srcAmount;
        uint256 minReturnAmount;
        uint256 execReward;
        uint256 expiration;
        address payable beneficiary;
        State state;
    }

    IOneInchExchange public oneInchExchange;

    Order[] public orders;

    event Create(
        uint256 indexed id,
        address srcToken,
        address dstToken,
        uint256 srcAmount,
        uint256 execReward,
        uint256 minReturnAmount,
        uint256 expiration
    );
    // event Update(
    //     uint256 indexed id,
    //     uint256 minReturnAmount,
    //     uint256 expiration
    // );
    event Execute(uint256 indexed id);
    event Refund(uint256 indexed id);

    // address public _dstReceiver;
    // uint256 public _guaranteedAmount;
    // uint256 public _minReturnAmount;

    constructor(address _oneInchAddr) {
        oneInchExchange = IOneInchExchange(_oneInchAddr);
    }

    //   function create(
    //     address srcTokenAddr,
    //     address dstTokenAddr,
    //     uint256 srcAmount,
    //     uint256 minReturnAmount,
    //     uint256 period
    //   ) external payable {
    //     uint256 expiration = block.timestamp + period;
    //     require(expiration > block.timestamp, "Order: Expiration is before current datetime");

    //     IERC20 srcToken = IERC20(srcTokenAddr);
    //     IERC20 dstToken = IERC20(dstTokenAddr);

    //     require(
    //       msg.value > (srcToken.isETH() ? srcAmount : 0),
    //       "Tx impossible: Not enough funds to pay reward"
    //     );
    //     uint256 execReward = srcToken.isETH() ? msg.value.sub(srcAmount) : msg.value;

    //     if (!srcToken.isETH()) {
    //       srcToken.safeTransferFrom(msg.sender, address(this), srcAmount);
    //       srcToken.uniApprove(address(oneInchExchange), srcAmount);
    //     }

    //     Order memory order = Order(
    //       srcToken,
    //       dstToken,
    //       srcAmount,
    //       minReturnAmount,
    //       execReward,
    //       expiration,
    //       msg.sender,
    //       State.Pending
    //     );
    //     uint256 orderId = orders.length;
    //     orders.push(order);

    //     emit Create(orderId, srcTokenAddr, dstTokenAddr, srcAmount, execReward, minReturnAmount, expiration);
    //   }

    //   function update(
    //     uint256 orderId,
    //     uint256 minReturnAmount,
    //     uint256 period
    //   ) external {
    //     uint256 expiration = block.timestamp + period;
    //     require(expiration > block.timestamp, "Order: Expiration is before current datetime");

    //     Order storage order = orders[orderId];

    //     require(order.state == State.Pending, "Order: Can update only pending orders");
    //     require(msg.sender == order.beneficiary, "Wrong msg.sender");

    //     order.minReturnAmount = minReturnAmount;
    //     order.expiration = expiration;

    //     emit Update(orderId, order.minReturnAmount, order.expiration);
    //   }

    function execute(
        uint256 orderId,
        bytes calldata oneInchCallData,
        address srcTokenAddr,
        address dstTokenAddr,
        uint256 srcAmount,
        uint256 minReturnAmount,
        uint256 period
    ) external payable {
        Order storage order = orders[orderId];

        IERC20 srcToken = IERC20(srcTokenAddr);
        IERC20 dstToken = IERC20(dstTokenAddr);

        require(
            msg.value > (srcToken.isETH() ? srcAmount : 0),
            "Tx impossible: Not enough funds to pay reward"
        );
        uint256 execReward = srcToken.isETH()
            ? msg.value.sub(srcAmount)
            : msg.value;

        uint256 expiration = block.timestamp + period;
        require(
            expiration > block.timestamp,
            "Order: Expiration is before current datetime"
        );

        require(
            order.state == State.Pending,
            "Order: Can execute only pending orders"
        );
        require(
            order.expiration >= block.timestamp,
            "Order: Cannot execute an expired order"
        );

        (
            IOneInchCaller caller,
            IOneInchExchange.SwapDescription memory desc,
            IOneInchCaller.CallDescription[] memory calls
        ) = abi.decode(
                oneInchCallData[4:],
                (
                    IOneInchCaller,
                    IOneInchExchange.SwapDescription,
                    IOneInchCaller.CallDescription[]
                )
            );

        require(
            desc.guaranteedAmount >= order.minReturnAmount,
            "desc.guaranteedAmount is less than order.minReturnAmount"
        );

        require(
            address(desc.srcToken) == address(order.srcToken) &&
                address(desc.dstToken) == address(order.dstToken) &&
                desc.dstReceiver == order.beneficiary,
            "Calldata is not correct"
        );

        uint256 msgValue = order.srcToken.isETH() ? order.srcAmount : 0;

        if (!srcToken.isETH()) {
            srcToken.safeTransferFrom(msg.sender, address(this), srcAmount);
            srcToken.uniApprove(address(oneInchExchange), srcAmount);
        }

        uint256 returnAmount = oneInchExchange.swap{value: msgValue}(
            caller,
            desc,
            calls
        );

        require(
            returnAmount >= order.minReturnAmount,
            "returnAmount is less than order.minReturnAmount"
        );
        order.state = State.Fulfilled;

        payable(msg.sender).transfer(order.execReward);

        // Order memory ORder = Order(
        //     srcToken,
        //     dstToken,
        //     srcAmount,
        //     minReturnAmount,
        //     execReward,
        //     expiration,
        //     payable(msg.sender),
        //     State.Pending
        // );

        uint256 orderId = orders.length;
        orders.push(order);

        // emit Create( orderId,srcTokenAddr,dstTokenAddr,srcAmount,execReward,minReturnAmount,expiration );
        // emit Execute(orderId);
    }

    function refund(uint256 orderId) external {
        Order storage order = orders[orderId];

        require(
            order.state == State.Pending,
            "Order: Can refund only pending orders"
        );
        require(msg.sender == order.beneficiary, "Wrong msg.sender");

        if (order.srcToken.isETH()) {
            order.srcToken.uniTransfer(
                payable(msg.sender),
                order.srcAmount.add(order.execReward)
            );
        } else {
            order.srcToken.uniTransfer(payable(msg.sender), order.srcAmount);
            payable(msg.sender).transfer(order.execReward);
        }

        order.state = State.Refunded;
        emit Refund(orderId);
    }

    /**
     * @dev - Return number of all created orders.
     */
    function countOrders() external view returns (uint256) {
        return orders.length;
    }

    //function _decode_(bytes calldata oneInchCallData) external {
    //(,IOneInchExchange.SwapDescription memory desc,) = abi
    //.decode(oneInchCallData[4:], (IOneInchCaller, IOneInchExchange.SwapDescription, IOneInchCaller.CallDescription[]));

    //_dstReceiver = desc.dstReceiver;
    //_guaranteedAmount = desc.guaranteedAmount;
    //_minReturnAmount = desc.minReturnAmount;
    //}

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./SafeERC20.sol";

library UniERC20 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;           

  IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

  function isETH(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
  }

  function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
    if (isETH(token)) {
      return account.balance;
    } else {
      return token.balanceOf(account);
    }
  }

  function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
    if (amount > 0) {
      if (isETH(token)) {
        to.transfer(amount);
      } else {
        token.safeTransfer(to, amount);
      }
    }
  }

  function uniApprove(IERC20 token, address to, uint256 amount) internal {
    require(!isETH(token), "Approve called on ETH");

    if (amount == 0) {
      token.safeApprove(to, 0);
    } else {
      uint256 allowance = token.allowance(address(this), to);
      if (allowance < amount) {
        if (allowance > 0) {
          token.safeApprove(to, 0);
        }
        token.safeApprove(to, amount);
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/**
* @dev Library to perform safe calls to standard method for ERC20 tokens.
*
* Why Transfers: transfer methods could have a return value (bool), throw or revert for insufficient funds or
* unathorized value.
*
* Why Approve: approve method could has a return value (bool) or does not accept 0 as a valid value (BNB token).
* The common strategy used to clean approvals.
*
* We use the Solidity call instead of interface methods because in the case of transfer, it will fail
* for tokens with an implementation without returning a value.
* Since versions of Solidity 0.4.22 the EVM has a new opcode, called RETURNDATASIZE.
* This opcode stores the size of the returned data of an external call. The code checks the size of the return value
* after an external call and reverts the transaction in case the return data is shorter than expected
*/
library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        if (prevBalance < _value) {
            // Insufficient funds
            return false;
        }

        address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        // Fail if the new balance its not equal than previous balance sub _value
        return prevBalance - _value == _token.balanceOf(address(this));
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _token erc20 The address of the ERC20 contract
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool)
    {
        uint256 prevBalance = _token.balanceOf(_from);

        if (
          prevBalance < _value || // Insufficient funds
          _token.allowance(_from, address(this)) < _value // Insufficient allowance
        ) {
            return false;
        }

        address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value)
        );

        // Fail if the new balance its not equal than previous balance sub _value
        return prevBalance - _value == _token.balanceOf(_from);
    }

   /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return bool whether the approve was successful or not
   */
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        address(_token).call(
            abi.encodeWithSignature("approve(address,uint256)",_spender, _value)
        );

        // Fail if the new allowance its not equal than _value
        return _token.allowance(address(this), _spender) == _value;
    }

   /**
   * @dev Clear approval
   * Note that if 0 is not a valid value it will be set to 1.
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   */
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            success = safeApprove(_token, _spender, 1);
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IChi is IERC20 {
  function mint(uint256 value) external;
  function free(uint256 value) external returns (uint256 freed);
  function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);
}

interface ISafeERC20Extension {
  function safeApprove(IERC20 token, address spender, uint256 amount) external;
  function safeTransfer(IERC20 token, address payable target, uint256 amount) external;
}

interface IGasDiscountExtension {
  function calculateGas(uint256 gasUsed, uint256 flags, uint256 calldataLength) external pure returns (IChi, uint256);
}

interface IOneInchCaller is ISafeERC20Extension, IGasDiscountExtension {
  struct CallDescription {
    uint256 targetWithMandatory;
    uint256 gasLimit;
    uint256 value;
    bytes data;
  }

  function makeCall(CallDescription memory desc) external;
  function makeCalls(CallDescription[] memory desc) external payable;
}

interface IOneInchExchange {
  struct SwapDescription {
    IERC20 srcToken;
    IERC20 dstToken;
    address srcReceiver;
    address dstReceiver;
    uint256 amount;
    uint256 minReturnAmount;
    uint256 guaranteedAmount;
    uint256 flags;
    address referrer;
    bytes permit;
  }

  function swap(
    IOneInchCaller caller,
    SwapDescription calldata desc,
    IOneInchCaller.CallDescription[] calldata calls
  ) external payable returns (uint256);
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