// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Utils/SafeTransfer.sol";
import "./OpenZeppelin/math/SafeMath.sol";
import "./OpenZeppelin/utils/Context.sol";

contract RedeemToken is SafeTransfer, Context {
  using SafeMath for uint256;

  struct Item {
    uint256 amount;
    uint256 unlockTime;
    uint256 userIndex;
    address owner;
  }

  /// @notice tracking assets belonging to a particular user
  struct UserInfo {
    mapping(address => mapping(address => uint256[])) lockToItems;
  }

  mapping(address => UserInfo) users;
  /// @notice id number of the vault deposit
  uint256 public depositId;
  /// @notice an array of all the deposit Ids
  uint256[] public allDepositIds;
  /// @notice mapping from item Id to the Item struct
  mapping(uint256 => Item) public lockedItem;

  event onLock(address tokenAddress, address user, uint256 amount);
  event onUnlock(address tokenAddress, uint256 amount);

  /**
   * @notice Locking tokens in the vault
   * @param _tokenAddress Address of the token locked
   * @param _amount Number of tokens locked
   * @param _unlockTime Timestamp number marking when tokens get unlocked
   * @param _withdrawer Address where tokens can be withdrawn after unlocking
   */
  function lockTokens(
    address _tokenAddress,
    address _privateSaleAddress,
    uint256 _amount,
    uint256 _unlockTime,
    address _withdrawer
  )
    public returns (uint256 _id)
  {
    require(_amount > 0, "RedeemToken: token amount is Zero");
    require(_unlockTime < 10000000000, "ReddemToken: timestamp should be in seconds");
    require(_withdrawer != address(0), "ReddemToken: withdrawer is zero address");
    _safeTransferFrom(_tokenAddress, _msgSender(), _amount);

    _id = ++depositId;

    lockedItem[_id].amount = _amount;
    lockedItem[_id].unlockTime = _unlockTime;
    lockedItem[_id].owner = _withdrawer;

    allDepositIds.push(_id);

    UserInfo storage userItem = users[_withdrawer];
    userItem.lockToItems[_tokenAddress][_privateSaleAddress].push(_id);
    uint256 userIndex = userItem.lockToItems[_tokenAddress][_privateSaleAddress].length - 1;
    lockedItem[_id].userIndex = userIndex;

    emit onLock(_tokenAddress, _msgSender(), lockedItem[_id].amount);
  }

  /**
   * @notice Withdrawing tokens from the vault
   * @param _tokenAddress Address of the token to withdraw
   * @param _index Index number of the list with Ids
   * @param _id Id number
   * @param _amount Number of tokens to withdraw
   */
  function withdrawTokens(
    address _tokenAddress,
    address _privateSaleAddress,
    uint256 _index,
    uint256 _id,
    uint256 _amount,
    address _recipient
  ) external {
    require(_amount > 0, "RedeemToken: token amount is zero");
    uint256 id = users[_recipient].lockToItems[_tokenAddress][_privateSaleAddress][_index];
    Item storage userItem = lockedItem[id];
    require(id == _id && userItem.owner == _recipient, "RedeemToken: not found");
    require(userItem.unlockTime < block.timestamp, "RedeemToken: not unlocked yet");
    userItem.amount = userItem.amount.sub(_amount);

    _safeTransfer(_tokenAddress, _recipient, _amount);
    emit onUnlock(_tokenAddress, _amount);
  }

  /**
   * @notice Retrieve data from the item under user index number
   * @param _index Index number of the list with item ids
   * @param _tokenAddress Address of the token corresponding to this item
   * @param _user User address
   * @return Items token amount number, Items unlock timestamp, Items owner address, Items Id number
   */
  function getItemAtUserIndex(
    uint256 _index,
    address _tokenAddress,
    address _privateSaleAddress,
    address _user
  )
    external view returns (uint256, uint256, address, uint256)
  {
    uint256 id = users[_user].lockToItems[_tokenAddress][_privateSaleAddress][_index];
    Item storage item = lockedItem[id];
    return (item.amount, item.unlockTime, item.owner, id);
  }

  /**
   * @notice Retrieve all the data from Item struct under given Id.
   * @param _id Id number.
   * @return All the data for this Id (token amount number, unlock time number, owner address and user index number)
   */
  function getLockedItemAtId(uint256 _id) external view returns (uint256, uint256, address, uint256, uint256) {
      Item storage item = lockedItem[_id];
      return (item.amount, item.unlockTime, item.owner, item.userIndex, _id);
  }

  /**
   * @notice Get locked item's ids of the specified user
   * @param _user User address
   * @param _tokenAddress Address token
   */
  function getLockedItemIdsOfUser(address _user, address _tokenAddress, address _privateSaleAddress) external view returns (uint256[] memory) {
    UserInfo storage user = users[_user];
    return user.lockToItems[_tokenAddress][_privateSaleAddress];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeTransfer {

    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _safeTokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _safeTransferETH(_to,_amount );
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }
    
    function _tokenPayment(
        address _token,
        address payable _to,
        uint256 _amount
    ) internal {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            _safeTransfer(_token, _to, _amount);
        }
    }
    
    function _safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }
    
    function _safeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal virtual {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(0xa9059cbb, to, amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(
        address token,
        address from,
        uint256 amount
    ) internal virtual {
        (bool success, bytes memory data) =
            token.call(
                abi.encodeWithSelector(0x23b872dd, from, address(this), amount)
            );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: cannot transfer");
    }

    function _safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function _safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }

}

// SPDX-License-Identifier: MIT

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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a + b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}