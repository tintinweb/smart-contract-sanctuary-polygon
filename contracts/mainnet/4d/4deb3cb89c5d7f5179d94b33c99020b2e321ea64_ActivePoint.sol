/**
 *Submitted for verification at polygonscan.com on 2022-12-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;






interface ImetaRelation {
    function getInvList(address addr_)
        external
        view
        returns (address[] memory _addrsList);

    function invListLength(address addr_) external view returns (uint256);

    function Inviter(address _addr) external view returns (address);
}

interface IMetaAuth {
    function validUser(address _addr) external view returns (bool);

    function getValidUserCount(address _addr) external view returns (uint256);

    function isTrande(address _addr) external view returns (bool);
}

interface IMetaRecord {
    function setAboutRecord(
        address _addr,
        string memory _stype,
        string memory _source,
        address _user,
        uint256 _token,
        bool _isAdd,
        bool _isValid,
        string memory _remark
    ) external;
}

library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}


library SafeMathUpgradeable {
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


library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
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

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}


contract AdminRoleUpgrade {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
 
    EnumerableSetUpgradeable.AddressSet private _admins;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    // constructor() {
    //     _addAdmin(msg.sender);
    // }

    modifier onlyAdmin() {
        require(
            isAdmin(msg.sender),
            "AdminRole: caller does not have the Admin role"
        );
        _;
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins.contains(account);
    }

    function allAdmins() public view returns (address[] memory admins) {
        admins = new address[](_admins.length());
        for (uint256 i = 0; i < _admins.length(); i++) {
            admins[i] = _admins.at(i);
        }
    }

    function batchAddAdmin(address[] memory amounts) public onlyAdmin{
        for(uint256 i=0; i < amounts.length; i++){
            addAdmin(amounts[i]);
        }
    }

    function addAdmin(address account) public onlyAdmin {
        _addAdmin(account);
    }

    function removeAdmin(address account) public onlyAdmin {
        _removeAdmin(account);
    }

    function renounceAdmin() public {
        _removeAdmin(msg.sender);
    }

    function _addAdmin(address account) internal {
        _admins.add(account);
        emit AdminAdded(account);
    }
    
    function _removeAdmin(address account) internal {
        _admins.remove(account);
        emit AdminRemoved(account);
    }
}



// 活跃点收藏值
contract ActivePoint is AdminRoleUpgrade, Initializable {
    using SafeMathUpgradeable for uint256;

    ImetaRelation metaRation;
    bytes32 public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    // 活跃点
    struct Point {
        // 自身产生的活跃点
        uint256 ownerActivePoint;
        // 小区活跃点
        uint256 teamActivePoint;
        // 团队活跃度
        uint256 totalChildActivePoint;
    }

    // 转入转出比例，默认分母是100，如果是转入1:1， 那么intoRatio 就是100
    uint256 public intoRatio;
    uint256 public outRatio;
    uint256 public dividendRatio;

    // 自身拥有的活跃点
    mapping(address => Point) public ownerPointMap;

    // 收藏值
    mapping(address => uint256) public favoriteValueMap;

    IMetaAuth metaAuth;
    // 无效的活跃点
    mapping(address => uint256) public onwerInvalidActivePoint;
    // 给一代的无效收藏值
    mapping(address => uint256) public ownerParentInvalidFV;
    // 给二代的无效收藏值
    mapping(address => uint256) public ownerGrandparentsInvalidFV;
    // 下级给自己的无效收藏值
    mapping(address => uint256) public ownerInvalidFV;

    IMetaRecord metaRecord;

    function initialize() public initializer {
        // metaRation = ImetaRelation(_relationAddr);
        _addAdmin(msg.sender);

        // 转入碎片是1.5倍, 转出是1倍
        intoRatio = 150;
        outRatio = 100;
        dividendRatio = 70;
    }

    // 这个需要线上设置
    function setMetaAuth(address _metaAuthAddr) external onlyAdmin {
        metaAuth = IMetaAuth(_metaAuthAddr);
    }

    function setAboutAddress(address _metaAuthAddr, address _metaRecordAddr)
        external
        onlyAdmin
    {
        metaAuth = IMetaAuth(_metaAuthAddr);
        metaRecord = IMetaRecord(_metaRecordAddr);
    }

    function setIntoRatio(uint256 ratio) external onlyAdmin {
        intoRatio = ratio;
    }

    function setOutRatio(uint256 ratio) external onlyAdmin {
        outRatio = ratio;
    }

    function updateFavoriteAndPointWithMCPT(
        address _addr,
        uint256 subFavoritetValue,
        uint256 addFavoriteValue,
        uint256 actionPoint,
        bool isAddPoint
    ) external onlyAdmin {
        updateFavoriteValue(_addr, subFavoritetValue, false);
        updateFavoriteValue(_addr, addFavoriteValue, true);
        updateParentFavoriteValue(_addr, addFavoriteValue);
        updateParentActivePoint(_addr, actionPoint, isAddPoint);
        if (addFavoriteValue > 0) {
            metaRecord.setAboutRecord(
                _addr,
                "favorite",
                "mcpt",
                _addr,
                addFavoriteValue,
                true,
                true,
                ""
            );
        }
    }

    // 地址，减少的收藏值， 增加的收藏值，
    function updateFavoriteAndPoint(
        address _addr,
        uint256 subFavoritetValue,
        uint256 addFavoriteValue,
        uint256 actionPoint,
        bool isAddPoint
    ) external onlyAdmin {
        updateFavoriteValue(_addr, subFavoritetValue, false);
        updateFavoriteValue(_addr, addFavoriteValue, true);
        updateParentFavoriteValue(_addr, addFavoriteValue);
        updateParentActivePoint(_addr, actionPoint, isAddPoint);
        if (addFavoriteValue > 0) {
            metaRecord.setAboutRecord(
                _addr,
                "favorite",
                "openStake",
                _addr,
                addFavoriteValue,
                true,
                true,
                ""
            );
        }
    }

    // 判断交易是转出还是转入得到收藏值
    function setTradingFavorite(
        address _addr,
        uint256 _value,
        bool isInto
    ) external onlyAdmin {
        uint256 value = getRatioFavorite(_value, isInto);
        updateFavoriteValue(_addr, value, isInto);
    }

    // 利益分红，增加收藏值
    function batchFavoriteValue(address[] memory _addrs, uint256 _value)
        external
        onlyAdmin
    {
        uint256 value = _value.mul(dividendRatio).div(100);
        for (uint256 i = 0; i < _addrs.length; i++) {
            updateFavoriteValue(_addrs[i], value, true);
        }
    }

    function getRatioFavorite(uint256 _value, bool isInto)
        public
        view
        returns (uint256)
    {
        uint256 ratio = isInto ? intoRatio : outRatio;
        return _value.mul(ratio).div(100);
    }

    // 更新自身及以上50代数据
    function updateParentActivePointWithValid(address _addr) public {
        address sender = _addr;
        for (uint256 i = 0; i < 60; i++) {
            sender = getParent(sender);
            if (sender == address(0)) {
                break;
            }
            addActionPoint(sender);
        }
    }

    // 获取自身的活跃点 小区活跃点  团队活跃点  无效活跃点
    function getPoint(address _addr)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            ownerPointMap[_addr].ownerActivePoint,
            ownerPointMap[_addr].teamActivePoint,
            ownerPointMap[_addr].totalChildActivePoint,
            onwerInvalidActivePoint[_addr]
        );
    }

    // 活跃点 30代  更新还是减少
    // 自身活跃点的增加或者减少，影响的是上级的小区活跃点，所以需要更新
    function updateParentActivePoint(
        address addr,
        uint256 _point,
        bool isAdd
    ) public onlyAdmin {
        // 默认值是调用者
        address sender = addr;
        if(_point > 0){
            Point storage point = ownerPointMap[sender];

            if (isAdd) {
                point.ownerActivePoint += _point;
            } else {
                point.ownerActivePoint -= _point;
            }
            updateParentActivePointWithValid(sender);
        }
        
    }

    function updateOwnActionPoint(address _sender) external {
        addActionPoint(_sender);
    }

    function addActionPoint(address _sender) internal {
        Point storage point = ownerPointMap[_sender];
        // 小区活跃点
        // point.teamActivePoint = updateTeamPoint(_sender);
        (
            uint256 totalPoint,
            uint256 teamPoint,
            uint256 invalidPoint
        ) = updateTeamPoint(_sender);
        if(point.teamActivePoint != teamPoint){
            point.teamActivePoint = teamPoint;
        }
        
        if(point.totalChildActivePoint != totalPoint){
            point.totalChildActivePoint = totalPoint;
        }
        
        if( onwerInvalidActivePoint[_sender] != invalidPoint){
            onwerInvalidActivePoint[_sender] = invalidPoint;
        }
        
        
    }

    // 更新自身的小区活跃点
    function updateTeamPoint(address _sender)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address[] memory childs = getChildMembers(_sender);
        uint256 maxActivePoint = 0;
        uint256 totalActivePoint = 0;
        uint256 childinvalidActivePoint = 0;
        for (uint256 i = 0; i < childs.length; i++) {
            address child = childs[i];
            Point memory point = ownerPointMap[child];

            // 有效活跃度往上级传递
            uint256 childTotalPoint = point.totalChildActivePoint;
            // 判断自身是否是有效用户，如果是，则有效团队活跃度就是 下级的团队活跃度+自身活跃度，否则则放入到无效活跃度里面
            if (metaAuth.validUser(child)) {
                childTotalPoint += point.ownerActivePoint;
            } else {
                
                childinvalidActivePoint += point.ownerActivePoint;
            }
            maxActivePoint = (
                childTotalPoint > maxActivePoint
                    ? childTotalPoint
                    : maxActivePoint
            );
            totalActivePoint += childTotalPoint;
            childinvalidActivePoint += onwerInvalidActivePoint[child];
        }

        return (
            totalActivePoint,
            totalActivePoint - maxActivePoint,
            childinvalidActivePoint
        );
    }

    // 收藏值
    function updateFavoriteValue(
        address _addr,
        uint256 _value,
        bool _isAdd
    ) public onlyAdmin {
        if (_value > 0) {
            if (_isAdd) {
                favoriteValueMap[_addr] += _value;
            } else {
                favoriteValueMap[_addr] -= _value;
            }
        }
    }

    // 判断自身是否是有效用户，如果是有效用户，那么需要把收藏值给上级
    function updateParentFavoriteValueWithValid(address _addr) public {
        if (metaAuth.validUser(_addr) && ownerParentInvalidFV[_addr] > 0) {
            // 把收藏值给一代二代
            favoriteValueMap[getParent(_addr)] += ownerParentInvalidFV[_addr];
            favoriteValueMap[
                getParent(getParent(_addr))
            ] += ownerGrandparentsInvalidFV[_addr];

            // 处理异常
            if (
                ownerInvalidFV[getParent(_addr)] -
                    ownerParentInvalidFV[_addr] >=
                0
            ) {
                ownerInvalidFV[getParent(_addr)] -= ownerParentInvalidFV[_addr];
            } else {
                ownerInvalidFV[getParent(_addr)] = 0;
            }

            if (
                ownerInvalidFV[getParent(getParent(_addr))] -
                    ownerGrandparentsInvalidFV[_addr] >=
                0
            ) {
                ownerInvalidFV[
                    getParent(getParent(_addr))
                ] -= ownerGrandparentsInvalidFV[_addr];
            } else {
                ownerInvalidFV[getParent(getParent(_addr))] = 0;
            }

            ownerGrandparentsInvalidFV[_addr] = 0;
            ownerParentInvalidFV[_addr] = 0;
        }
    }

    // 给父级加收藏值
    function updateParentFavoriteValue(address _addr, uint256 _value)
        public
        onlyAdmin
    {
        if (_value > 0) {
            (uint256 value1, uint256 value2) = updateSuperFavorite(_value);
            if (metaAuth.validUser(_addr)) {
                favoriteValueMap[getParent(_addr)] += value1;
                favoriteValueMap[getParent(getParent(_addr))] += value2;
                metaRecord.setAboutRecord(
                    getParent(_addr),
                    "favorite",
                    "first",
                    _addr,
                    value1,
                    true,
                    true,
                    ""
                );
                metaRecord.setAboutRecord(
                    getParent(getParent(_addr)),
                    "favorite",
                    "second",
                    _addr,
                    value2,
                    true,
                    true,
                    ""
                );
                updateParentFavoriteValueWithValid(_addr);
            } else {
                // 无效用户时，先保存需要给一代、二代的收藏值
                ownerParentInvalidFV[_addr] += value1;
                ownerGrandparentsInvalidFV[_addr] += value2;

                // 下级给自己的无效收藏值
                ownerInvalidFV[getParent(_addr)] += value1;
                ownerInvalidFV[getParent(getParent(_addr))] += value2;

                metaRecord.setAboutRecord(
                    getParent(_addr),
                    "favorite",
                    "first",
                    _addr,
                    value1,
                    true,
                    false,
                    ""
                );
                metaRecord.setAboutRecord(
                    getParent(getParent(_addr)),
                    "favorite",
                    "second",
                    _addr,
                    value2,
                    true,
                    false,
                    ""
                );
            }
        }
    }

    function updateSuperFavorite(uint256 _value)
        internal
        pure
        returns (uint256, uint256)
    {
        return (_value.mul(3).div(100), _value.mul(2).div(100));
    }

    // 设置
    function setMetaRation(address _addr) external onlyAdmin {
        metaRation = ImetaRelation(_addr);
    }

    function getParent(address _addr) public view returns (address) {
        return metaRation.Inviter(_addr);
    }

    function getMemberCount() public view returns (uint256) {
        return metaRation.invListLength(msg.sender);
    }

    function getChildMembers(address _addr)
        public
        view
        returns (address[] memory)
    {
        return metaRation.getInvList(_addr);
    }




    function batchUpdateData(address[] memory addrs, uint256[] memory favoriteValueMaps, uint256[] memory onwerInvalidActivePoints, uint256[] memory ownerParentInvalidFVs, uint256[] memory ownerGrandparentsInvalidFVs, uint256[] memory ownerInvalidFVs) external onlyAdmin{
        for(uint256 i=0; i< addrs.length; i++){
            address addr = addrs[i];
            favoriteValueMap[addr] = favoriteValueMaps[i];
            onwerInvalidActivePoint[addr] = onwerInvalidActivePoints[i];
            ownerParentInvalidFV[addr] = ownerParentInvalidFVs[i];
            ownerGrandparentsInvalidFV[addr] = ownerGrandparentsInvalidFVs[i];
            ownerInvalidFV[addr] = ownerInvalidFVs[i];
        }
    }



    function batchUpdatePoint(address[] memory addrs, Point[] memory points) external onlyAdmin{
         for(uint256 i=0; i< addrs.length; i++){
            address addr = addrs[i];
            ownerPointMap[addr] = points[i];
         }
    }
}