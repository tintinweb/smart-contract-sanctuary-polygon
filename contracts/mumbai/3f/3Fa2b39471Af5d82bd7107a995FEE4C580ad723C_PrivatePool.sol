// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

library AddressUpgradeable {
    function isContract(address account) internal view returns (bool) {
        
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

   
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

   
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

   
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library EnumerableSet {
    
    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

   
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

interface IPool {
    function initialize(
        address[4] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = Authority, [4] = currency
        uint256[13] memory _saleInfo,
        string memory _poolDetails,
        address[3] memory _linkAddress, // [0] factory ,[1] = manager
        uint8 _version,
        uint256 _contributeWithdrawFee,
        string[3] memory _otherInfo
    ) external;

    function initializeVesting(
         uint256[3] memory _vestingInit  
    ) external;

    function setKycAudit(bool _kyc , bool _audit , string memory _kyclink,string memory _auditlink) external;
    function emergencyWithdraw(address payable to_, uint256 amount_) external;
    function setGovernance(address governance_) external;
    function emergencyWithdrawToken( address payaddress ,address tokenAddress, uint256 tokens ) external;
    function getPoolInfo() external view returns (address, address, uint8[] memory , uint256[] memory , string memory , string memory , string memory);
}

library FullMath {
  /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
  /// @param a The multiplicand
  /// @param b The multiplier
  /// @param denominator The divisor
  /// @return result The 256-bit result
  /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
  function mulDiv(
    uint256 a,
    uint256 b,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = a * b
    // Compute the product mod 2**256 and mod 2**256 - 1
    // then use the Chinese Remainder Theorem to reconstruct
    // the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2**256 + prod0
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(a, b, not(0))
      prod0 := mul(a, b)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division
    if (prod1 == 0) {
      require(denominator > 0);
      assembly {
        result := div(prod0, denominator)
      }
      return result;
    }

    // Make sure the result is less than 2**256.
    // Also prevents denominator == 0
    require(denominator > prod1);

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0]
    // Compute remainder using mulmod
    uint256 remainder;
    assembly {
      remainder := mulmod(a, b, denominator)
    }
    // Subtract 256 bit number from 512 bit number
    assembly {
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }

    // Factor powers of two out of denominator
    // Compute largest power of two divisor of denominator.
    // Always >= 1.
    unchecked {
      uint256 twos = (type(uint256).max - denominator + 1) & denominator;
      // Divide denominator by power of two
      assembly {
        denominator := div(denominator, twos)
      }

      // Divide [prod1 prod0] by the factors of two
      assembly {
        prod0 := div(prod0, twos)
      }
      // Shift in bits from prod1 into prod0. For this we need
      // to flip `twos` such that it is 2**256 / twos.
      // If twos is zero, then it becomes one
      assembly {
        twos := add(div(sub(0, twos), twos), 1)
      }
      prod0 |= prod1 * twos;

      // Invert denominator mod 2**256
      // Now that denominator is an odd number, it has an inverse
      // modulo 2**256 such that denominator * inv = 1 mod 2**256.
      // Compute the inverse by starting with a seed that is correct
      // correct for four bits. That is, denominator * inv = 1 mod 2**4
      uint256 inv = (3 * denominator) ^ 2;
      // Now use Newton-Raphson iteration to improve the precision.
      // Thanks to Hensel's lifting lemma, this also works in modular
      // arithmetic, doubling the correct bits in each step.
      inv *= 2 - denominator * inv; // inverse mod 2**8
      inv *= 2 - denominator * inv; // inverse mod 2**16
      inv *= 2 - denominator * inv; // inverse mod 2**32
      inv *= 2 - denominator * inv; // inverse mod 2**64
      inv *= 2 - denominator * inv; // inverse mod 2**128
      inv *= 2 - denominator * inv; // inverse mod 2**256

      // Because the division is now exact we can divide by multiplying
      // with the modular inverse of denominator. This will give us the
      // correct result modulo 2**256. Since the precoditions guarantee
      // that the outcome is less than 2**256, this is the final result.
      // We don't need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inv;
      return result;
    }
  }
}

library PoolLibrary {
  using SafeMath for uint256;

  function getContributionAmount(
    uint256 contributed,
    uint256 minContribution,
    uint256 maxContribution,
    uint256 availableToBuy
  ) internal pure returns (uint256, uint256) {
        // Bought all their allocation
        if (contributed >= maxContribution) {
            return (0, 0);
        }
        uint256 remainingAllocation = maxContribution.sub(contributed);

        // How much eth is one token
        if (availableToBuy > remainingAllocation) {
            if (contributed > 0) {
                return (0, remainingAllocation);
            } else {
                return (minContribution, remainingAllocation);
            }
        } else {
             if (contributed > 0) {
                return (0, availableToBuy);
            } else {
                if (availableToBuy < minContribution) {
                    return (0, availableToBuy);
                } else {
                    return (minContribution, availableToBuy);
                }
            }
        }
  }

  function convertCurrencyToToken(
    uint256 amount, 
    uint256 rate
  ) internal pure returns (uint256) {
    return amount.mul(rate).div(1e18);
  }

  function calculateFeeAndLiquidity(
    uint256 totalRaised,
    uint256 ethFeePercent,
    uint256 tokenFeePercent,
    uint256 totalVolumePurchased
  ) internal pure returns (uint256 ethFee, uint256 tokenFee) {
    ethFee = totalRaised.mul(ethFeePercent).div(100);
    tokenFee = totalVolumePurchased.mul(tokenFeePercent).div(100);
  }
}

contract ReEntrancyGuard {
    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
}
contract PrivatePool is OwnableUpgradeable, IPool,ReEntrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;
    using EnumerableSet for EnumerableSet.AddressSet;

    uint8 public VERSION;
    uint256 public feesWithdraw;

    enum PoolState {
        inUse,
        completed,
        cancelled
    }

    enum PoolType {
        presale,
        privatesale,
        fairsale
    }

    address public factory;
    address public governance;
    address payable private adminWallet;
  
    address public currency;
    address public token;
    uint256 public rate;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public softCap;
    uint256 public hardCap;

    bool public audit;
    bool public kyc;
    bool public auditStatus;
    bool public kycStatus;
    string public auditLink;
    string public kycLink;
    string public ownerMail;
    
    uint256 public startTime;
    uint256 public endTime;

    uint256 private tokenFeePercent;
    uint256 private ethFeePercent;
    
    uint256 public refundType;

    string public poolDetails;

    PoolState public poolState;
    PoolType public poolType;

    uint256 public totalRaised;
    uint256 public totalVolumePurchased;
    uint256 public totalClaimed;
    uint256 public totalRefunded;

    mapping(address => uint256) public contributionOf;
    mapping(address => uint256) public purchasedOf;
    mapping(address => uint256) public claimedOf;
    mapping(address => uint256) public refundedOf;

    uint256 public tgeDate; // TGE date for vesting locks, unlock date for normal locks
    uint256 public tgeBps; // In bips. Is 0 for normal locks
    uint256 public cycle; // Is 0 for normal locks
    uint256 public cycleBps; // In bips. Is 0 for normal locks

    bool public useWhitelisting;
    EnumerableSet.AddressSet private whitelistedUsers;
    mapping(address => bool) private isWhitelisted;
    

    event Contributed(
        address indexed user,
        uint256 currencyAmount
    );
    event WithdrawnContribution(
        address indexed user,
        uint256 currencyAmount
    );
    event Claimed(
        address indexed user,
        uint256 tokenAmount
    );

    event Finalized(uint256 lpAmount, uint256 tvl);
    event LiquidityWithdrawn(uint256 lpAmount);
    event Cancelled();
    event PoolUpdated(string poolDetails);
    event KycUpdated(bool completed);

    
    modifier inProgress() {
        require(poolState == PoolState.inUse, "Pool is either completed or cancelled");
        require(block.timestamp >= startTime && block.timestamp < endTime, "It's not time to buy");
        require(totalRaised < hardCap, "Hardcap reached");
        _;
    }

    modifier onlyWhitelisted() {
        if (useWhitelisting) {
            require(isWhitelisted[msg.sender], "User is not whitelisted");
        }
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == governance, "Only operator");
        _;
    }

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }

    receive() external payable {
        if (msg.value > 0) contribute(0);
    }

    function initialize(
        address[4] memory _addrs, // [0] = token, [1] = router, [2] = governance , [3] = currency
        uint256[13] memory _saleInfo,
        string memory _poolDetails,
        address[3] memory _linkAddress, // [0] factory ,[1] = manager 
        uint8 _version,
        uint256 _contributeWithdrawFee,
        string[3] memory _otherInfo
    ) external override initializer {
        require(factory == address(0), "Pool: Forbidden");
        require(_addrs[0] != address(0), "Invalid Token address");
        require(_saleInfo[1] <= _saleInfo[2], "Min contribution amount must be less than or equal to max");
        require(_saleInfo[3].mul(2) >= _saleInfo[4] && _saleInfo[3] <= _saleInfo[4] && _saleInfo[4] > 0, "Softcap must be >= 50% of hardcap");
        // require(_timeSettings[0] > block.timestamp, "Start time should be in the future");
        require(_saleInfo[5] < _saleInfo[6], "End time must be after start time");
        require(
            _saleInfo[7] >= 0 &&
            _saleInfo[7] <= 100 &&
            _saleInfo[8] >= 0 &&
            _saleInfo[8] <= 100,
            "Invalid fee settings. Must be percentage (0 -> 100)"
        );
        require (_saleInfo[0] > 0, "Rate must be greater than Zero");
        require(_saleInfo[12] == 0 || _saleInfo[12] == 1, "Refund type must be 0 (refund) or 1 (burn)");
        OwnableUpgradeable.__Ownable_init();
        transferOwnership(_linkAddress[0]);
        factory = _linkAddress[1];
        adminWallet = payable(_linkAddress[2]);
        token = _addrs[0];
        governance = _addrs[2];
        currency = _addrs[3];
        rate = _saleInfo[0];
        minContribution = _saleInfo[1];
        maxContribution = _saleInfo[2];
        softCap = _saleInfo[3];
        hardCap = _saleInfo[4];
        startTime = _saleInfo[5];
        endTime = _saleInfo[6];
        tokenFeePercent = _saleInfo[7];
        ethFeePercent = _saleInfo[8];
        useWhitelisting = _saleInfo[11] == 1 ? true : false;
        audit = _saleInfo[9] == 1 ? true : false;
        kyc =   _saleInfo[10] == 1 ? true : false;
        refundType = _saleInfo[12];
        auditLink = _otherInfo[0];
        kycLink = _otherInfo[1];
        ownerMail = _otherInfo[2];
        poolDetails = _poolDetails;
        poolState = PoolState.inUse;
        VERSION = _version;
        poolType = PoolType.privatesale;
        feesWithdraw = _contributeWithdrawFee;
    }

    function initializeVesting(
        uint256[3] memory _vestingInit  // [0] tgeBps [1] cycle, [2] cycleBps, 
    ) external override onlyOperator{
        require(factory != address(0), "Only Pool Factory");
        require(poolState == PoolState.inUse, "Pool Closed !");
        require(_vestingInit[1] >= 0, "Invalid cycle");
        require(_vestingInit[0] >= 0 && _vestingInit[0] < 10_000, "Invalid bips for TGE");
        require(_vestingInit[2] >= 0 && _vestingInit[2] < 10_000, "Invalid bips for cycle");
        require(
            _vestingInit[0] + _vestingInit[2] <= 10_000,
            "Sum of TGE bps and cycle should be less than 10000"
        );

        
        tgeBps = _vestingInit[0]; 
        cycle = _vestingInit[1];
        cycleBps = _vestingInit[2]; 
        
    }

    function addWhitelistedUsers(address[] memory users) external {
        for (uint256 i = 0; i < users.length; i++) {
            setWhitelist(users[i], true);
        }
    }

    function addWhitelistedUser(address user) external {
        setWhitelist(user, true);
    }

    function removeWhitelistedUsers(address[] memory users) external {
        for (uint256 i = 0; i < users.length; i++) {
            setWhitelist(users[i], false);
        }
    }

    function removeWhitelistedUser(address user) external {
        setWhitelist(user, false);
    }

    function isUserWhitelisted(address user) public view returns (bool) {
        if (useWhitelisting) {
            return isWhitelisted[user];
        }
        return true;
    }

    function setWhitelist(address user, bool whitelisted) internal onlyOperator {
        require(useWhitelisting, "Pool does not use whitelisting option");
        if (whitelisted) {
            if (!whitelistedUsers.contains(user)) {
                whitelistedUsers.add(user);
                isWhitelisted[user] = true;
            }
        } else {
            if (whitelistedUsers.contains(user)) {
                whitelistedUsers.remove(user);
                isWhitelisted[user] = false;
            }
        }
    }

    function getNumberOfWhitelistedUsers() public view returns (uint256) {
        return whitelistedUsers.length();
    }

    function getWhitelistedUsers(uint256 startIndex, uint256 endIndex) public view returns (address[] memory) {
        if (endIndex >= whitelistedUsers.length()) {
            endIndex = whitelistedUsers.length() - 1;
        }
        uint256 len = endIndex - startIndex + 1;
        address[] memory whitelistedParticipantsPart = new address[](len);

        uint256 counter = 0;
        for (uint256 i = startIndex; i <= endIndex; i++) {
            whitelistedParticipantsPart[counter] = whitelistedUsers.at(i);
            counter++;
        }
        return whitelistedParticipantsPart;
    }

    function getPoolInfo() external override view returns (address, address, uint8[] memory , uint256[] memory , string memory , string memory , string memory){
       
        uint8[] memory state = new uint8[](3);
        uint256[] memory info = new uint256[](11);
        
        state[0] = uint8(poolState);
        state[1] = uint8(poolType);
        state[2] = IERC20(token).decimals();
        info[0] = startTime;
        info[1] =  endTime;
        info[2] =  totalRaised;
        info[3] = hardCap; 
        info[4] = softCap; 
        info[5] = minContribution; 
        info[6] = maxContribution;
        info[7] = rate;
        info[8] = 0;
        info[9] = 0;
        info[10] = 0;
        
        
       return (token , currency, state , info , IERC20(token).name() , IERC20(token).symbol() , poolDetails);
    }

    
    function contribute(uint256 _amount) public payable inProgress onlyWhitelisted{
        uint256 amount = currency == address(0) ? msg.value : _amount;
        require(amount > 0, "Cant contribute 0");
       
        if(currency != address(0))
            IERC20(currency).safeTransferFrom(msg.sender, address(this), amount);

        uint256 userTotalContribution = contributionOf[msg.sender].add(amount);
        // Allow to contribute with an amount less than min contribution
        // if the remaining contribution amount is less than min
        if (hardCap.sub(totalRaised) >= minContribution) {
            require(userTotalContribution >= minContribution, "Min contribution not reached");
        }
        require(userTotalContribution <= maxContribution, "Contribute more than allowed");
        require(totalRaised.add(amount) <= hardCap, "Buying amount exceeds hard cap");
        
        contributionOf[msg.sender] = userTotalContribution;
        totalRaised = totalRaised.add(amount);
        uint256 volume = PoolLibrary.convertCurrencyToToken(amount, rate);
        require(volume > 0, "Contribution too small to produce any volume");
        purchasedOf[msg.sender] = purchasedOf[msg.sender].add(volume);
        totalVolumePurchased = totalVolumePurchased.add(volume);
        emit Contributed(msg.sender, amount);
    }

    function claim() public noReentrant {
        require(poolState == PoolState.completed, "Owner has not closed the pool yet");
        require(tgeDate <= block.timestamp , "pool still not finalized!!!");
        uint256 volume = purchasedOf[msg.sender];
        uint256 totalClaim = claimedOf[msg.sender];
        uint256 withdrawable = 0;

        if (tgeBps > 0) {
            withdrawable = _withdrawableTokens();
        }
        else{
            if(volume >= totalClaim){
                withdrawable = volume.sub(totalClaim);
            }
            else{
                withdrawable = 0;
            }
        }

        require(withdrawable > 0 , "No token avalible for claim!!");
        claimedOf[msg.sender] += withdrawable;
        totalClaimed = totalClaimed.add(withdrawable);
        IERC20(token).safeTransfer(msg.sender, withdrawable);
        emit Claimed(msg.sender, withdrawable);
    }

    function _withdrawableTokens()
        internal
        view
        returns (uint256)
    {
        uint256 volume = purchasedOf[msg.sender];
        uint256 totalClaim = claimedOf[msg.sender];
        if (volume == 0) return 0;
        if (totalClaim >= volume) return 0;
        if (block.timestamp < tgeDate) return 0;
        if (cycle == 0) return 0;

        uint256 tgeReleaseAmount = FullMath.mulDiv(
            volume,
            tgeBps,
            10_000
        );
        uint256 cycleReleaseAmount = FullMath.mulDiv(
            volume,
            cycleBps,
            10_000
        );
        uint256 currentTotal = 0;
        if (block.timestamp >= tgeDate) {
            currentTotal =
                (((block.timestamp - tgeDate) / cycle) *
                    cycleReleaseAmount) +
                tgeReleaseAmount; // Truncation is expected here
        }
        uint256 withdrawable = 0;
        if (currentTotal > volume) {
            withdrawable = volume - totalClaim;
        } else {
            withdrawable = currentTotal - totalClaim;
        }
        return withdrawable;
    }

    function withdrawContribution() external noReentrant {
        if (poolState == PoolState.inUse) {
            require(block.timestamp >= endTime, "Pool is still in progress");
            require(totalRaised < softCap, "Soft cap reached");
        } else {
            require(poolState == PoolState.cancelled, "Cannot withdraw contribution because pool is completed");
        }
        require(contributionOf[msg.sender] > 0, "You Don't Have Enough contribution");
        uint256 fees = 0;
        if(poolState == PoolState.inUse){
            fees = feesWithdraw;
        }
        uint256 refundAmount = contributionOf[msg.sender];
        totalVolumePurchased = totalVolumePurchased.sub(purchasedOf[msg.sender]);

        refundedOf[msg.sender] = refundAmount;
        totalRefunded = totalRefunded.add(refundAmount);
        contributionOf[msg.sender] = 0;
        purchasedOf[msg.sender] = 0;
        totalRaised = totalRaised.sub(refundAmount);
        uint256 Countfees = refundAmount.mul(fees).div(10000);
        refundAmount = refundAmount.sub(Countfees);

        if(currency == address(0)) {
            payable(msg.sender).sendValue(refundAmount);
            payable(adminWallet).sendValue(Countfees);
        } else {
            IERC20(currency).safeTransfer(msg.sender, refundAmount);
            IERC20(currency).safeTransfer(adminWallet, Countfees);
        }        

        emit WithdrawnContribution(msg.sender, refundAmount);
    }

    function finalize() external onlyOperator noReentrant {
        require(poolState == PoolState.inUse, "Pool was finialized or cancelled");
        require(
            totalRaised == hardCap || hardCap.sub(totalRaised) < minContribution ||
                (totalRaised >= softCap && block.timestamp >= endTime),
            "It is not time to finish"
        );

        poolState = PoolState.completed;
        tgeDate = block.timestamp; 

        (
            uint256 ethFee,
            uint256 tokenFee
        ) = PoolLibrary.calculateFeeAndLiquidity(
            totalRaised, 
            ethFeePercent, 
            tokenFeePercent, 
            totalVolumePurchased
        );
       
        uint256 currencyAmount = currency == address(0) ? address(this).balance : IERC20(currency).balanceOf(address(this));
        uint256 remainingEth = currencyAmount.sub(ethFee);
        uint256 remainingToken = 0;

        uint256 totalTokenSpent = tokenFee.add(totalVolumePurchased);
        remainingToken += IERC20(token).balanceOf(address(this)).sub(totalTokenSpent);
        

        // Pay platform fees
        if(ethFee > 0){
            if(currency == address(0))
                payable(adminWallet).sendValue(ethFee);
            else
                IERC20(currency).safeTransfer(adminWallet, ethFee);
        }
        if(tokenFee > 0){
            IERC20(token).safeTransfer(adminWallet, tokenFee);
        }

        // Refund remaining
        if (remainingEth > 0) {
            if(currency == address(0))
                payable(governance).sendValue(remainingEth);
            else
                IERC20(currency).safeTransfer(governance, remainingEth);
        }
       
        if (remainingToken > 0) {
            // 0: refund, 1: burn
            if (refundType == 0) {
                IERC20(token).safeTransfer(governance, remainingToken);
            } else {
                IERC20(token).safeTransfer(address(0xdead), remainingToken);
            }
        }
        
        emit Finalized(totalRaised, 0);
    }

    function cancel() external onlyOperator {
        require (poolState == PoolState.inUse, "Pool was either finished or cancelled");
        poolState = PoolState.cancelled;
        IERC20(token).safeTransfer(governance, IERC20(token).balanceOf(address(this)));
        emit Cancelled();
    }

    function withdrawLeftovers() external onlyOperator noReentrant {
        require(block.timestamp >= endTime, "It is not time to withdraw leftovers");
        require(totalRaised < softCap, "Soft cap reached, call finalize() instead");
        IERC20(token).safeTransfer(governance, IERC20(token).balanceOf(address(this)));
    }

   function emergencyWithdrawToken( address payaddress ,address tokenAddress, uint256 tokens ) external override onlyOwner 
    {
       IERC20(tokenAddress).transfer(payaddress, tokens);
    }

    function emergencyWithdraw(address payable to_, uint256 amount_) external override onlyOwner {
        to_.sendValue(amount_);
    }

    function updatePoolDetails(string memory details_) external onlyOperator {
        poolDetails = details_;
        emit PoolUpdated(poolDetails);
    }

    function setGovernance(address governance_) external override onlyOwner {
        governance = governance_;
    }

    function getContributionAmount(address user_) public view returns (uint256, uint256) {
        uint256 contributed = contributionOf[user_];
        uint256 availableToBuy = remainingContribution();
        return PoolLibrary.getContributionAmount(
            contributed, 
            minContribution, 
            maxContribution, 
            availableToBuy
        );
    }

    function remainingContribution() public view returns (uint256) {
        return hardCap.sub(totalRaised);
    }

    function convert(uint256 amountInWei) public view returns (uint256) {
        return PoolLibrary.convertCurrencyToToken(amountInWei, rate);
    }

    function getUpdatedState() public view returns (uint256, uint8, string memory) {
        return (totalRaised, uint8(poolState), poolDetails);
    }

    function userAvalibleClaim(address _userAddress) public view returns (uint256){
        uint256 volume = purchasedOf[_userAddress];
        uint256 totalClaim = claimedOf[_userAddress];
        uint256 withdrawable = 0;
        if(tgeDate <= block.timestamp){
           
            if (tgeBps > 0) {
                if (volume == 0) return 0;
                if (totalClaim >= volume) return 0;
                if (block.timestamp < tgeDate) return 0;
                if (cycle == 0) return 0;

                uint256 tgeReleaseAmount = FullMath.mulDiv(
                    volume,
                    tgeBps,
                    10_000
                );
                uint256 cycleReleaseAmount = FullMath.mulDiv(
                    volume,
                    cycleBps,
                    10_000
                );
                uint256 currentTotal = 0;
                if (block.timestamp >= tgeDate) {
                    currentTotal =
                        (((block.timestamp - tgeDate) / cycle) *
                            cycleReleaseAmount) +
                        tgeReleaseAmount; // Truncation is expected here
                }
                if (currentTotal > volume) {
                    withdrawable = volume - totalClaim;
                } else {
                    withdrawable = currentTotal - totalClaim;
                }
                
            }
            else{
                if(volume >= totalClaim){
                    withdrawable = volume.sub(totalClaim);
                }
                else{
                    withdrawable = 0;
                }
            }
        }

        return withdrawable;
        
    }

    function setKycAudit(bool _kyc , bool _audit , string memory _kyclink,string memory _auditlink) override external onlyOwner{
        kycStatus = _kyc;
        auditStatus = _audit;
        kycLink=_kyclink;
        auditLink=_auditlink;
    }

    function setWhitelisting(bool _whitelisting) public onlyOperator{
        useWhitelisting = _whitelisting;
    }
}