/**
 *Submitted for verification at polygonscan.com on 2022-03-30
*/

// Sources flattened with hardhat v2.8.1 https://hardhat.org

// File @openzeppelin/contracts/utils/math/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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


// File @openzeppelin/contracts/utils/math/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]



pragma solidity ^0.8.2;




/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal initializer {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]



pragma solidity ^0.8.0;


/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal initializer {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal initializer {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}


// File contracts/IAssemblyCore.sol


pragma solidity 0.8.11;

interface IAssemblyCore {
    enum TallyStatus {
        ProvisionalNotApproved,
        ProvisionalApproved,
        NotApproved,
        Approved,
        Enacted
    }

    enum TallyPhase {
        Deliberation,
        Revocation,
        Ended
    }

    struct Tally {
        uint256 proposalId;
        uint256 submissionTime;
        uint256 revocationStartTime;
        uint256 votingEndTime;
        uint256 delegatedYays;
        uint256 citizenYays;
        uint256 citizenNays;
        uint256 citizenCount;
        TallyStatus status;
    }

    enum VoteStatus {
        NotVoted,
        Yay,
        Nay
    }

    function getCreator() external view returns (address);

    function isHuman(address account) external view returns (bool);

    function isCitizen(address human) external view returns (bool);

    function isDelegate(address delegate) external view returns (bool);

    function getCitizenCount() external view returns (uint256);

    function getDelegateCount() external view returns (uint256);

    function getAppointedDelegate() external view returns (address);

    function getAppointmentCount(address delegate) external view returns (uint256);

    function getVotingPercentThreshold() external view returns (uint256);

    function getSeatCount() external view returns (uint256);

    function getQuorum() external view returns (uint256);

    function getTallyDuration() external view returns (uint256);

    function getDelegateSeats() external view returns (address[] memory);

    function isTrusted(address account) external view returns (bool);

    function getDelegateVote(uint256 tallyId) external view returns (bool);

    function getCitizenVote(uint256 tallyId) external view returns (VoteStatus);

    function getTally(uint256 tallyId) external view returns (Tally memory);

    function getTallyPhase(uint256 tallyId) external view returns (TallyPhase);

    function getTallyCount() external view returns (uint256);

    function applyForCitizenship() external;

    function applyForDelegation() external;

    function appointDelegate(address delegate) external;

    function claimSeat(uint256 seatNumber) external returns (uint256);

    function createTally(uint256 proposalId) external returns (uint256);

    function castDelegateVote(uint256 tallyId, bool yay) external;

    function castCitizenVote(uint256 tallyId, bool yay) external;

    function tallyUp(uint256 tallyId) external;

    function enact(uint256 tallyId) external returns (bool);

    function distrust(address account) external;

    function expel(address account) external;

    function setVotingPercentThreshold(uint256 newVotingPercentThreshold) external;

    function setSeatCount(uint256 newSeatCount) external;

    function setQuorum(uint256 newCitizenCountQuorum) external;

    function setTallyDuration(uint256 newTallyDuration) external;
}


// File contracts/IProofOfHumanity.sol


pragma solidity 0.8.11;

interface IProofOfHumanity {
    /** @dev Return true if the submission is registered and not expired.
     *  @param _submissionID The address of the submission.
     *  @return Whether the submission is registered or not.
     */
    function isRegistered(address _submissionID) external view returns (bool);

    /** @dev Return the number of submissions irrespective of their status.
     *  @return The number of submissions.
     */
    function submissionCounter() external view returns (uint256);
}


// File contracts/IWallet.sol


pragma solidity 0.8.11;

interface IWallet {
    function getProposalCount() external view returns (uint256);

    function executeProposal(uint256 transactionId) external returns (bool success);
}


// File contracts/Wallet.sol


pragma solidity 0.8.11;





/// @title A contract that can, on behalf of the DAO, call any contract function, thus being able to e.g. store any asset and transfer it.
/// @dev The DAO collectively controls the Wallet contract. The Wallet contract can call any contract function through blockchain transactions. These transactions need to be first submitted to the Wallet contract in the form of transaction proposals. The DAO then approves (or not) the execution of the proposal through a voting. Any member of the DAO can submit transaction proposals unless the member has been distrusted.
contract Wallet is UUPSUpgradeable, ReentrancyGuardUpgradeable, IWallet {
    IAssemblyCore private _assembly;
    bool private _initialized;

    struct Proposal {
        address destination; // Receiver of the transaction.
        uint256 value; // Number of coins to transfer.
        bytes data; // The transaction function call data.
        bool executed; // Whether or not the transaction was executed.
    }

    uint256 private _proposalCount;
    mapping(uint256 => Proposal) private _proposals;

    //
    // Events
    //

    event Submitted(uint256 indexed proposalId); // A new transaction proposal was submitted.
    event Executed(uint256 indexed proposalId); // The proposed transaction was executed.
    event ExecutedFail(uint256 indexed proposalId); // The transaction could not be executed.
    event Deposited(address indexed sender, uint256 value); // Coins have been deposited into the Wallet.
    event Called(bool indexed result, bytes indexed resultMem); // The Wallet has performed an external call of a function.

    //
    // Modifiers
    //

    modifier onlyAssembly() {
        require(msg.sender == address(_assembly), "Only the Assembly can perform this operation");
        _;
    }

    modifier onlyMe() {
        require(msg.sender == address(this), "You are not allowed to do this");
        _;
    }

    modifier isInitialized() {
        require(address(_assembly) != address(0), "Contract has not yet been initialized");
        _;
    }

    modifier isExistingProposal(uint256 proposalId) {
        require(proposalId < _proposalCount, "Wrong proposal id");
        _;
    }

    modifier notYetExecuted(uint256 proposalId) {
        require(!_proposals[proposalId].executed, "Proposed transaction was already executed");
        _;
    }

    //
    // Test functions (to be overriden for testing purposes only).
    //

    function isTestMode() public view virtual returns (bool) {
        return false;
    }

    function setTestMode(bool testMode) external virtual {}

    //
    // Functions
    //

    function getAssembly() external view returns (address) {
        return address(_assembly);
    }

    function initialize(address assembly_) external {
        require(!_initialized, "Contract has already been initialized");
        require(assembly_ != address(0), "Assembly contract address cannot be zero");
        _assembly = IAssemblyCore(assembly_);
        _initialized = true;
    }

    function getProposal(uint256 id) external view isExistingProposal(id) returns (Proposal memory) {
        return _proposals[id];
    }

    /// @return Returns the number of proposals ever submitted.
    function getProposalCount() external view override returns (uint256) {
        return _proposalCount;
    }

    /// @dev Submit a transaction proposal. Only addresses allowed by the DAO can perform this operation.
    ///         Because this function can be abused in several ways, only trusted addresses can call it.
    /// @param destination The transaction destination.
    /// @param value The transaction value.
    /// @param data The transaction data.
    /// @return The new transaction's id.
    function submitProposal(
        address destination,
        uint256 value,
        bytes memory data
    ) external isInitialized returns (uint256) {
        if (!isTestMode()) require(_assembly.isTrusted(msg.sender), "You are not trusted to perform this operation");
        uint256 proposalId = _proposalCount;
        _proposals[proposalId] = Proposal({destination: destination, value: value, data: data, executed: false});
        _proposalCount += 1;
        emit Submitted(proposalId);
        return proposalId;
    }

    /// @dev Execute a submitted transaction. Only the operator can do this operation.
    /// @param proposalId The id of the proposal to execute.
    /// @return Whether the transaction was succesfully executed.
    function executeProposal(uint256 proposalId) external override isInitialized onlyAssembly isExistingProposal(proposalId) notYetExecuted(proposalId) nonReentrant returns (bool) {
        Proposal storage txn = _proposals[proposalId];
        if (externalCall(txn.destination, txn.value, txn.data)) {
            emit Executed(proposalId);
            txn.executed = true;
            return true;
        } else {
            emit ExecutedFail(proposalId);
            return false;
        }
    }

    function externalCall(
        address destination,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        bool result;
        bytes memory resultMem;
        (result, resultMem) = destination.call{value: value}(data);
        emit Called(result, resultMem);
        return result;
    }

    /// @dev Emit an event when coins are received, regarless of msg.data
    fallback() external payable {
        if (msg.value > 0) emit Deposited(msg.sender, msg.value);
    }

    //
    // Upgrade
    //

    function _authorizeUpgrade(address newImplementation) internal override onlyMe {
        require(newImplementation != address(0), "New implementation contract address cannot be zero");
    }
}


// File contracts/AssemblyCore.sol


pragma solidity 0.8.11;






/// @title Assembly contract implementing a semi-direct democracy and on-chain tallying.
/// @dev This contract manages citizen and delegate registration, voting, tallying and execution of transaction proposals. In conjunction with the Wallet contract, this contract implements a democratic (not "tokencratic") Decentralized Autonomous Organization (DAO) consisting of a semi-direct democracy following the 1-human-1-vote principle, optional vote delegation and on-chain tallying. The only prerrequisite to register in the DAO is to prove to be a human, which is done through Proof-of-Humanity. Humans can participate in the DAO as citizens and as delegates. Proposals, which are chain transactions, need to be approved by a majority, determined by a certain threshold percentage, to be executed. Delegates voting power is proportional to the amount of citizens. A quorum is needed to approve proposals. DAO members can be flagged as distrusted by the DAO. Members whose humanity proof is no longer valid or have become distrusted can be expelled from the DAO.
///
/// The voting process consist of the following steps:
/// 1. Transaction submission: A transaction proposal is submitted to the Wallet contract.
/// 2. Creation of a tally: A tally to vote on the proposal is created.
/// 3. Voting: Delegates (and optionally citizens) cast their votes. The voting period is divided into 2 phases: deliberation and revocation.
///
/// | ------------------- tallyDuration-------------------- |
/// | -- Deliberation phase -- | -- Revocation phase -- ... | --- Enaction ...
/// | -- Delegates can vote -- | 
/// | -- Citizens can vote -------------------------------- | 
/// | ------------------------------------------------------------------------ > time
///
/// Citizens can cast their votes during either phase whereas delegates can only during the deliberation phase. This phase is intended to enable citizens the possibility of revoking any proposal that might have been approved by the delegates against the actual preference of their appointed citizens, as a citizen's majority superseds a delegate's majority.
/// 4. Tallying up and enaction: Votes are counted and, if the proposal is approved, the transaction is executed
contract AssemblyCore is UUPSUpgradeable, ReentrancyGuardUpgradeable, IERC20, IAssemblyCore {
    IProofOfHumanity private _poh;
    IWallet private _wallet;
    address private _owner; // for practical purposes, owner and wallet are defined using different variables although they have the same value as the Wallet contract is the owner of the Assembly contract
    bool private _initialized;
    address private _creator;

    //
    // Population
    //

    uint256 internal _citizenCount;
    mapping(address => bool) internal _isInCitizenCount;

    uint256 private _delegateCount;
    mapping(address => bool) internal _isInDelegateCount;
    mapping(address => address) private _appointments; // citizen => delegate
    mapping(address => uint256) private _appointmentCount; // delegate => no. of citizens

    address[] private _delegateSeats; // the addresses of the delegates seating
    mapping(address => bool) private _isSeated;
    mapping(address => uint256) private _delegateSeat;

    mapping(address => bool) private _isDistrusted;

    //
    // Voting
    //

    mapping(uint256 => Tally) internal _tallies;
    uint256 private _tallyCount;

    mapping(uint256 => mapping(address => bool)) private _delegateVotes;
    mapping(uint256 => mapping(address => VoteStatus)) private _citizenVotes;

    //
    // Parameters
    //

    uint256 public constant DEFAULT_THRESHOLD = 50;

    uint256 private _votingPercentThreshold;
    uint256 private _seatCount;
    uint256 private _citizenCountQuorum;
    uint256 private _tallyDuration;

    //
    // Events
    //

    // population
    event CitizenApplication(address indexed citizen, uint256 numCitizens);
    event DelegateApplication(address indexed delegate, uint256 numDelegates);
    event Distrust(address indexed account);
    event Expelled(address indexed member);

    // evolution
    event AppointDelegate(address indexed delegate, address indexed citizen);
    event DelegateSeatUpdate(uint256 indexed seatNumber, address indexed delegate);
    event NewTally(uint256 indexed tallyId);
    event DelegateVote(uint256 indexed tallyId, bool yay, address indexed delegate);
    event CitizenVote(uint256 indexed tallyId, bool yay, address indexed citizen);
    event Tallied(uint256 indexed tallyId);
    event Enacted(uint256 indexed tallyId);

    // configuration
    event VotingPercentThreshold(uint256 votingPercentThreshold);
    event SeatCount(uint256 seatCount);
    event Quorum(uint256 citizenCountQuorum);
    event TallyDuration(uint256 tallyDuration);

    //
    // Modifiers
    //

    modifier isInitialized() {
        require(_initialized, "Contract has not yet been initialized");
        _;
    }

    modifier onlyOwner() {
        require((_owner == msg.sender) || isTestMode(), "You are not allowed to do this");
        _;
    }

    /// @dev To be used on functions prone to be abused otherwise.
    modifier onlyTrusted() {
        require(isTrusted(msg.sender), "You are not trusted to perform this operation");
        _;
    }

    //
    // Test functions (to be n for testing purposes only).
    //

    function isTestMode() public view virtual returns (bool) {
        return false;
    }

    function setTestMode(bool testMode) external virtual {}

    //
    // Functions
    //

    function getCreator() external view returns (address) {
        return _creator;
    }

    function setCreator(address newCreator) external {
        require(msg.sender == _creator, "You are not allowed to do this");
        require(newCreator != _creator, "The new address must be different");
        require(newCreator != address(0), "Creator address cannot be zero");

        _creator = newCreator;
    }

    function getPoh() external view returns (address) {
        return address(_poh);
    }

    function getWallet() external view returns (address) {
        return address(_wallet);
    }

    function getOwner() external view returns (address) {
        return address(_owner);
    }

    function isHuman(address account) public view isInitialized returns (bool) {
        return account == _creator || _poh.isRegistered(account); // the creator's humanity proof is not required
    }

    function isCitizen(address _human) external view returns (bool) {
        return _isInCitizenCount[_human];
    }

    function isDelegate(address _delegate) external view returns (bool) {
        return _isInDelegateCount[_delegate];
    }

    function getCitizenCount() external view returns (uint256) {
        return _citizenCount;
    }

    function getDelegateCount() external view returns (uint256) {
        return _delegateCount;
    }

    function getAppointedDelegate() external view returns (address) {
        return _appointments[msg.sender];
    }

    function getAppointmentCount(address _delegate) external view returns (uint256) {
        return _appointmentCount[_delegate];
    }

    function getVotingPercentThreshold() external view returns (uint256) {
        return _votingPercentThreshold;
    }

    function getSeatCount() external view returns (uint256) {
        return _seatCount;
    }

    function getQuorum() external view returns (uint256) {
        return _citizenCountQuorum;
    }

    function getTallyDuration() external view returns (uint256) {
        return _tallyDuration;
    }

    function getDelegateSeats() external view returns (address[] memory) {
        return _delegateSeats;
    }

    function isDelegateSeated(address _delegate) external view returns (bool) {
        return _isSeated[_delegate];
    }

    function getDelegateSeat(address _delegate) external view returns (uint256) {
        return _delegateSeat[_delegate];
    }

    function getDelegateSeatAppointmentCounts() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory ret;

        if (_delegateSeats.length > 0) {
            ret = new uint256[](_delegateSeats.length);
            for (uint256 i = 0; i < _delegateSeats.length; i++) ret[i] = _appointmentCount[_delegateSeats[i]];
        }

        return (_delegateSeats, ret);
    }

    function isTrusted(address account) public view returns (bool) {
        return isHuman(account) && !_isDistrusted[account];
    }

    /// @param tallyId The id of the tally.
    /// @return Vote sign that the sender cast as a delegate.
    function getDelegateVote(uint256 tallyId) external view returns (bool) {
        require(_isInDelegateCount[msg.sender], "You are not a delegate");
        return _delegateVotes[tallyId][msg.sender];
    }

    /// @param tallyId The id of the tally.
    /// @return Vote sign that the sender cast as a citizen.
    function getCitizenVote(uint256 tallyId) external view returns (VoteStatus) {
        require(_isInCitizenCount[msg.sender], "You are not a citizen");
        return _citizenVotes[tallyId][msg.sender];
    }

    /// @param tallyId The id of the tally.
    /// @return The tally struct.
    function getTally(uint256 tallyId) external view returns (Tally memory) {
        return _tallies[tallyId];
    }

    /// @param tallyId The id of the tally.
    /// @return The phase which the tally is on.
    function getTallyPhase(uint256 tallyId) public view returns (TallyPhase) {
        Tally storage t = _tallies[tallyId];

        if (block.timestamp < t.revocationStartTime) return TallyPhase.Deliberation;
        else if (block.timestamp < t.votingEndTime) return TallyPhase.Revocation;
        return TallyPhase.Ended;
    }

    /// @return The total number of tallies ever created.
    function getTallyCount() external view returns (uint256) {
        return _tallyCount;
    }

    /// @dev The contract needs to be initialized before use.
    /// @param poh The contract implementing the Proof-of-Humanity interface.
    /// @param owner The address of the Wallet contract.
    /// @param wallet The address of the Wallet contract.
    /// @param seatCount Number of seats to be sat by delegates.
    /// @param citizenCountQuorum Smallest number of citizens registered to approve a proposal.
    /// @param tallyDuration Total duration of each tally.
    function _initialize(
        address poh,
        address owner,
        address wallet,
        uint256 seatCount,
        uint256 citizenCountQuorum,
        uint256 tallyDuration
    ) internal {
        require(!_initialized, "Contract has already been initialized");
        require(poh != address(0), "PoH contract address cannot be zero");
        require(owner != address(0), "Owner address cannot be zero");
        require(wallet != address(0), "Wallet contract address cannot be zero");
        require(seatCount > 0, "Invalid number of seats");

        _poh = IProofOfHumanity(address(poh));
        _owner = owner;
        _wallet = IWallet(address(wallet));

        _votingPercentThreshold = DEFAULT_THRESHOLD;
        _seatCount = seatCount;
        _citizenCountQuorum = citizenCountQuorum;
        _tallyDuration = tallyDuration;

        _creator = msg.sender;
        _initialized = true;
    }

    //
    // Population
    //

    function applyForCitizenship() external isInitialized {
        require(isHuman(msg.sender), "You are not a human");
        require(!_isDistrusted[msg.sender], "You are not trusted");
        require(!_isInCitizenCount[msg.sender], "You are a citizen already");

        _isInCitizenCount[msg.sender] = true;
        _citizenCount++;

        emit CitizenApplication(msg.sender, _citizenCount);
    }

    /// @dev Any human can apply for delegation.
    function applyForDelegation() external isInitialized {
        require(isHuman(msg.sender), "You are not a human");
        require(!_isDistrusted[msg.sender], "You are not trusted");
        require(!_isInDelegateCount[msg.sender], "You are a delegate already");

        _isInDelegateCount[msg.sender] = true;
        _delegateCount++;

        emit DelegateApplication(msg.sender, _delegateCount);
    }

    /// @dev Citizens can optionally appoint a delegate they trust.
    /// @param delegate The address of the delegate to appoint to.
    function appointDelegate(address delegate) external isInitialized {
        require(_isInCitizenCount[msg.sender], "You are not a citizen");
        require(_isInDelegateCount[delegate], "The address does not belong to a delegate");
        require(_appointments[msg.sender] != delegate, "You already appointed this delegate");

        if (_appointments[msg.sender] != address(0)) _appointmentCount[_appointments[msg.sender]]--;
        _appointments[msg.sender] = delegate;
        _appointmentCount[delegate]++;

        emit AppointDelegate(delegate, msg.sender);
    }

    /// @dev Delegates can opt in to take a seat under 2 conditions:
    ///         - The seat is empty.
    ///         - The number of citizen appointments of the delegate currently sitting in the seat is lower than the new delegate's.
    ///         Note: Seat reallocation is not triggered automatically after a new appointment but instead it needs to be executed on demand by calling this function by the beneficiary delegate. This is needed to start accruing delegation reward tokens.
    /// @param seatNumber The number of the seat to claim.
    /// @return The seat number on wich the delegate seats now.
    function claimSeat(uint256 seatNumber) external isInitialized onlyTrusted returns (uint256) {
        require(seatNumber < _seatCount, "Wrong seat number");
        require(_isInDelegateCount[msg.sender], "You are not a delegate");
        require(!_isSeated[msg.sender], "You are already seated");

        bool seated;

        if (seatNumber >= _delegateSeats.length) {
            _delegateSeats.push(msg.sender);
            seatNumber = _delegateSeats.length - 1;
            seated = true;
        } else if (!_isInDelegateCount[_delegateSeats[seatNumber]]) {
            _isSeated[_delegateSeats[seatNumber]] = false;
            seated = true;
        } else {
            require(_appointmentCount[msg.sender] > _appointmentCount[_delegateSeats[seatNumber]], "Not enought citizens support the delegate");
            _isSeated[_delegateSeats[seatNumber]] = false;
            seated = true;
        }

        if (seated) {
            _delegateSeats[seatNumber] = msg.sender;
            _isSeated[msg.sender] = true;
            _delegateSeat[msg.sender] = seatNumber;
            emit DelegateSeatUpdate(seatNumber, msg.sender);
            return seatNumber;
        } else revert("Did not update seats");
    }

    //
    // Voting
    //

    /// @param proposalId The id of the proposed transaction.
    /// @return The id of the new tally.
    function createTally(uint256 proposalId) external isInitialized onlyTrusted returns (uint256) {
        require(proposalId < _wallet.getProposalCount(), "Wrong proposal id");

        Tally memory t;

        t.proposalId = proposalId;
        t.status = TallyStatus.ProvisionalNotApproved;
        t.submissionTime = block.timestamp;
        t.revocationStartTime = t.submissionTime + _tallyDuration / 2;
        t.votingEndTime = t.submissionTime + _tallyDuration;
        t.citizenCount = _citizenCount;

        uint256 tallyId = _tallyCount;
        _tallies[tallyId] = t;
        emit NewTally(tallyId);
        _tallyCount++;
        return tallyId;
    }

    function castDelegateVote(uint256 tallyId, bool yay) external isInitialized {
        require(tallyId < _tallyCount, "Wrong tally id");
        require(_isInDelegateCount[msg.sender], "You are not a delegate");
        TallyPhase phase = getTallyPhase(tallyId);
        require(phase != TallyPhase.Ended, "The voting has ended");
        require(phase != TallyPhase.Revocation, "Delegates cannot vote during the revocation phase");
        require(_delegateVotes[tallyId][msg.sender] != yay, "That is your current vote already");

        _delegateVotes[tallyId][msg.sender] = yay;
        emit DelegateVote(tallyId, yay, msg.sender);
    }

    function castCitizenVote(uint256 tallyId, bool yay) external isInitialized {
        require(tallyId < _tallyCount, "Wrong tally id");
        require(_isInCitizenCount[msg.sender], "You are not a citizen");
        TallyPhase phase = getTallyPhase(tallyId);
        require(phase != TallyPhase.Ended, "The voting has ended");

        VoteStatus previousVoteStatus = _citizenVotes[tallyId][msg.sender];
        VoteStatus newVoteStatus = yay ? VoteStatus.Yay : VoteStatus.Nay;

        if (previousVoteStatus == newVoteStatus) revert("That is your current vote already");

        Tally storage t = _tallies[tallyId];
        if (previousVoteStatus == VoteStatus.Yay) t.citizenYays--;
        if (previousVoteStatus == VoteStatus.Nay) t.citizenNays--;
        if (newVoteStatus == VoteStatus.Yay) t.citizenYays++;
        if (newVoteStatus == VoteStatus.Nay) t.citizenNays++;
        _citizenVotes[tallyId][msg.sender] = newVoteStatus;
        emit CitizenVote(tallyId, yay, msg.sender);
    }

    /// @dev Require a quorum, i.e. the smallest number of citizens that need to be registered in the DAO in order to finalize a voting.
    ///         A quorum is required to lower the risk of centralization, i.e. avoid critical votings being controled by a small minority with a common goal against the general interest of the DAO. This risk is higher soon after the DAO's creation, when its population has not grown enough yet.
    /// @return Returns true if the number of citizens fulfills the quorum or if the sender is the creator.
    function isQuorumReached() public view isInitialized returns (bool) {
        if (isTestMode()) return true;
        return _citizenCount >= _citizenCountQuorum;
    }

    /// @dev Counts the votes of a tally and updates its status accordingly.
    ///         Note that delegates could effectively not having any approval power if not enough citizens appoint delegates.
    /// @param tallyId The id of the tally whose votes to count.
    function tallyUp(uint256 tallyId) public isInitialized {
        require(tallyId < _tallyCount, "Wrong tally id number");
        Tally storage t = _tallies[tallyId];
        require(t.status == TallyStatus.ProvisionalNotApproved || t.status == TallyStatus.ProvisionalApproved, "The tally cannot be changed");
        t.citizenCount = _citizenCount;
        uint256 voteThreshold = (_citizenCount * _votingPercentThreshold) / 100;
        bool finalNayOrYay;

        // Delegate voting
        uint256 yays;
        for (uint256 i = 0; i < _delegateSeats.length; i++) {
            if (_delegateVotes[tallyId][_delegateSeats[i]]) yays += _appointmentCount[_delegateSeats[i]];
        }
        t.delegatedYays = yays;
        finalNayOrYay = yays > voteThreshold ? true : false;

        // Citizen voting
        // If there are enough citizen votes, the citizen voting s the delegate voting.
        if (t.citizenYays > voteThreshold || t.citizenNays > voteThreshold) {
            finalNayOrYay = t.citizenYays > t.citizenNays ? true : false;
        }

        // Result
        if (getTallyPhase(tallyId) == TallyPhase.Ended) {
            // As it may take long to reach a quorum, the DAO's creator can circumvent the quorum restriction.
            if (!isQuorumReached() && msg.sender != _creator) revert("Tally cannot be ended as quorum is not reached");
            t.status = finalNayOrYay ? TallyStatus.Approved : TallyStatus.NotApproved;
        } else {
            t.status = finalNayOrYay ? TallyStatus.ProvisionalApproved : TallyStatus.ProvisionalNotApproved;
        }

        emit Tallied(tallyId);
    }

    /// @dev Executes (enacts) a transaction if approved.
    /// @param tallyId The id of the tally to enact.
    /// @return True if the transacion was executed, false otherwise.
    function enact(uint256 tallyId) public nonReentrant returns (bool) {
        require(tallyId < _tallyCount, "Wrong tally id number");

        Tally storage t = _tallies[tallyId];
        require(t.status == TallyStatus.Approved, "The proposal was not approved or was already enacted");

        if (_wallet.executeProposal(t.proposalId)) {
            t.status = TallyStatus.Enacted;
            emit Enacted(tallyId);
            return true;
        }
        return false;
    }

    /// @dev Flags an address as distrusted by the DAO.
    /// @param account The address to distrust
    function distrust(address account) external onlyOwner {
        require(!_isDistrusted[account], "The address is already distrusted");

        _isDistrusted[account] = true;
        emit Distrust(account);
    }

    /// @dev Expels a member of the DAO. Reasons for this can be a no longer valid humanity proof or becoming distrusted.
    /// @param account The address to expel.
    function expel(address account) external isInitialized onlyOwner {
        bool expelled = !isHuman(account) || _isDistrusted[account];

        if (!expelled) revert("Cannot be expelled");

        if (_isInDelegateCount[account]) {
            // Citizens who appointed this delegate can appoint another delegate.
            _isInDelegateCount[account] = false;
            _delegateCount--;
        }

        if (_isInCitizenCount[account]) {
            _isInCitizenCount[account] = false;
            _citizenCount--;

            if (_appointments[account] != address(0)) {
                _appointmentCount[_appointments[account]]--;
                _appointments[account] = address(0);
            }
        }

        emit Expelled(account);
    }

    //
    // Parameters
    //

    /// @dev Proposals are approved if the total percentage of citizen votes (delegated or not) is positive. Simple majority is never enough to approve a proposal, absolute majority is always needed.
    /// @param newVotingPercentThreshold The new voting percentage threshold.
    function setVotingPercentThreshold(uint256 newVotingPercentThreshold) external isInitialized onlyOwner {
        require(_votingPercentThreshold != newVotingPercentThreshold, "The new parameter value must be different");
        require(newVotingPercentThreshold <= 100 && newVotingPercentThreshold >= 50, "Invalid parameter value");
        _votingPercentThreshold = newVotingPercentThreshold;
        emit VotingPercentThreshold(_votingPercentThreshold);
    }

    /// @dev Creates empty new seats.
    /// @param newSeatCount The new total number of seats.
    function setSeatCount(uint256 newSeatCount) external isInitialized onlyOwner {
        require(_seatCount != newSeatCount, "The new parameter value must be different");
        require(_seatCount < newSeatCount, "Decreasing the number of seats is not supported");

        _seatCount = newSeatCount;
        emit SeatCount(_seatCount);
    }

    function setQuorum(uint256 newCitizenCountQuorum) external isInitialized onlyOwner {
        require(_citizenCountQuorum != newCitizenCountQuorum, "The new parameter value must be different");
        _citizenCountQuorum = newCitizenCountQuorum;
        emit Quorum(_citizenCountQuorum);
    }

    function setTallyDuration(uint256 newTallyDuration) external isInitialized onlyOwner {
        require(_tallyDuration != newTallyDuration, "The new parameter value must be different");
        require(newTallyDuration > 0, "Invalid parameter value");
        _tallyDuration = newTallyDuration;
        emit TallyDuration(_tallyDuration);
    }

    //
    // Upgrade
    //

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {
        require(newImplementation != address(0), "New implementation contract address cannot be zero");
    }

    // ERC20 interface implementation for Snapshot

    function balanceOf(address delegate) external view returns (uint256) {
        require(_isInDelegateCount[delegate], "Address is not a delegate");

        return _appointmentCount[delegate];
    }

    function totalSupply() external view returns (uint256) {
        return _citizenCount;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return false;
    }

    function allowance(address owner, address spender) external view returns (uint256) {}

    function approve(address spender, uint256 amount) external returns (bool) {
        return false;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        return false;
    }
}


// File contracts/IAssemblyIncentives.sol


pragma solidity 0.8.11;

interface IAssemblyIncentives {
    function getRewardBalance(address account) external view returns (uint256);

    function claimRewards() external;

    function getDelegationRewardRate() external view returns (uint256);

    function setDelegationRewardRate(uint256 delegationRewardRate) external;

    function getLastSnapshotTimestamp() external view returns (uint256);

    function distributeDelegationReward() external;

    function getExecRewardExponentMax() external view returns (uint256);

    function setExecRewardExponentMax(uint256 execRewardExponentMax) external;

    function execute(uint256 tallyId) external returns (bool);

    function getReferralRewardParams() external view returns (uint256, uint256);

    function isReferredClaimed(address referred) external view returns (bool);

    function claimReferralReward(address referrer) external;
}


// File @openzeppelin/contracts/token/ERC777/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}


// File contracts/Faucet.sol


pragma solidity 0.8.11;


/// @title A recipient to store DAO's tokens and spend them automatically without the need for a voting.
/// @dev This contract is intended to store a *small* number of tokens. The tokens are used to pay for delegation, tally counting, execution of approved transactions and referral rewards. The DAO periodically refills this contract with more tokens through a voting as needed.
contract Faucet is UUPSUpgradeable {
    IERC777 private _token;
    address private _assembly;
    address private _wallet;
    address private _upgrader;
    bool private _initialized;

    /// modifiers

    modifier onlyAssemblyOrWallet() {
        require(msg.sender == _assembly || msg.sender == _wallet, "You are not allowed to do this");
        _;
    }

    modifier onlyUpgrader() {
        require(msg.sender == _upgrader, "You are not the upgrader");
        _;
    }

    /// getters

    modifier isInitialized() {
        require(_initialized, "Contract has not yet been initialized");
        _;
    }

    function getAssembly() external view returns (address) {
        return _assembly;
    }

    function getWallet() external view returns (address) {
        return _wallet;
    }

    function getToken() external view returns (address) {
        return address(_token);
    }

    function getUpgrader() external view returns (address) {
        return _upgrader;
    }

    /// @dev The contract must be initialized before use.
    /// @param assembly_ The address of the Assembly contract.
    /// @param wallet The address of the Wallet contract.
    /// @param token The address of the Token contract.
    /// @param upgrader The address of the upgrader, which should be the Wallet contract address.
    function initialize(
        address assembly_,
        address wallet,
        address token,
        address upgrader
    ) external {
        require(!_initialized, "Contract has already been initialized");
        require(assembly_ != address(0), "Assembly contract address cannot be zero");
        require(wallet != address(0), "Wallet contract address cannot be zero");
        require(token != address(0), "Token contract address cannot be zero");
        require(upgrader != address(0), "Upgrader address cannot be zero");

        _token = IERC777(token);
        _assembly = assembly_;
        _wallet = wallet;
        _upgrader = upgrader;
        _initialized = true;
    }

    /// @dev Send tokens from this contract to a recipient address with attached data. This function can be called only by the Assembly or the Wallet contracts.
    /// @param recipient The recipient of the tokens.
    /// @param amount The number of tokens.
    /// @param data The data attached to the transaction.
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external isInitialized onlyAssemblyOrWallet {
        _token.send(recipient, amount, data);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyUpgrader {
        require(newImplementation != address(0), "New implementation contract address cannot be zero");
    }
}


// File contracts/Assembly.sol


pragma solidity 0.8.11;





/// @title Assembly contract with economic incentives.
/// @dev This contract, together with the Token and Faucet contracts, implements the economic incentive mechanisms needed for the DAO to operate fully and that AssemblyCore lacks of, such as paying tokens for delegation, tally counting and execution of approved transactions, in addition to a simple referral scheme. The use of a Faucet contract has been added so that the reward payments do not require a DAO voting to be made but instead they can be performed upon the token receiver's request.
///
/// - Delegation: Delegates get paid tokens for the time they sit on a *seat*. This creates an incentive to seek for appointments from citizens, as only the delegates with the most appointments are eligible for a seat.
/// - Tallying and enacting: It refers to the execution of a approved transaction. The number of tokens to be paid as enaction reward increases exponentially as time passes until a maximum is reached, thus the price of the transaction is automatically determined by the market.
/// - Referral: DAO members can refer other humans to join the DAO. Both the referrer and the referred humans get a reward if the referred human joins the DAO.
///
/// Rewarded addresses can claim their tokens by calling the corresponding functions. This triggers a transfer of tokens from the Faucet contract. The DAO refills the Faucet balance periodically through a voting.
contract Assembly is AssemblyCore, IAssemblyIncentives {

    Faucet private _faucet;
    mapping(address => uint256) private _rewardBalances; // rewarded => reward

    //
    // Delegation
    //

    uint256 private _delegationRewardRate; // token/sec to distribute among seated delegates
    uint256 private _lastSnapshotTimestamp;
    address[] private _lastDelegates;
    uint256[] private _lastCitizenCounts;
    uint256 private _lastCitizenCount;

    //
    // Tallying and execution
    //

    uint256 private _execRewardExponentMax;

    //
    // Referrals
    //

    mapping(address => bool) private _referredClaimed; // referrer => referred
    uint256 private _referredAmount;
    uint256 private _referrerAmount;

    //
    // Events
    //

    event DelegationReward(uint256 totalReward);
    event ExecutionReward(address executor, uint256 reward);
    event ReferralReward(address rewarded, uint256 reward);

    //
    // Functions
    //

    /// @dev The contract needs to be initialized before use.
    /// @param poh The contract implementing the Proof-of-Humanity interface.
    /// @param owner The address of the Wallet contract.
    /// @param wallet The address of the Wallet contract.
    /// @param seatCount Number of seats to be sat by delegates.
    /// @param citizenCountQuorum Smallest number of citizens registered to approve a proposal.
    /// @param tallyDuration Total duration of each tally.
    /// @param faucet A token container for automated payments that do not require a DAO's voting.
    /// @param delegationRewardRate Tokens per second to be distributed among seated delegates as a reward.
    /// @param referralReward Tokens to pay as referral reward.
    /// @param execRewardExponentMax Maximum value of the exponent of the formula that determines the execution reward.
    function initialize(
        address poh,
        address owner,
        address wallet,
        uint256 seatCount,
        uint256 citizenCountQuorum,
        uint256 tallyDuration,
        address faucet,
        uint256 delegationRewardRate,
        uint256 referralReward,
        uint256 execRewardExponentMax
    ) external {
        super._initialize(poh, owner, wallet, seatCount, citizenCountQuorum, tallyDuration);

        require(faucet != address(0), "Faucet address cannot be zero");

        _faucet = Faucet(address(faucet));

        _delegationRewardRate = delegationRewardRate;
        _referredAmount = referralReward;
        _referrerAmount = referralReward;
        _execRewardExponentMax = execRewardExponentMax;
    }

    function getFaucet() external view returns (address) {
        return address(_faucet);
    }

    function getRewardBalance(address account) external view returns (uint256) {
        return _rewardBalances[account];
    }

    /// @dev The caller receives tokens earned for delegation or tallying/execution tasks.
    function claimRewards() external isInitialized {
        require(_rewardBalances[msg.sender] > 0, "Your reward balance is zero");

        bytes memory foo;
        _faucet.send(msg.sender, _rewardBalances[msg.sender], foo);
        _rewardBalances[msg.sender] = 0;
    }

    ///
    /// Delegation
    ///

    function getDelegationRewardRate() external view returns (uint256) {
        return _delegationRewardRate;
    }

    function setDelegationRewardRate(uint256 delegationRewardRate) external isInitialized onlyOwner {
        require(_delegationRewardRate != delegationRewardRate, "The new parameter value must be different");

        _delegationRewardRate = delegationRewardRate;
    }

    /// @return Timestamp of the last state of the delegation seats
    function getLastSnapshotTimestamp() external view returns (uint256) {
        return _lastSnapshotTimestamp;
    }

    /// @dev Stores a copy ("snapshot") of the addresses of the seated delegates and their number of citizen appointments.
    function _takeDelegationSnapshot() internal {
        (address[] memory lastDelegates, uint256[] memory lastCitizenCount) = super.getDelegateSeatAppointmentCounts();
        _lastDelegates = lastDelegates;
        _lastCitizenCounts = lastCitizenCount;
        _lastCitizenCount = _citizenCount;
        _lastSnapshotTimestamp = block.timestamp;
    }

    /// @dev A number of tokens per second are allocated among all the seated delegates proportionally to their share of citizen appointments. The distribution calculation is done by taking a snapshot of the appointment distribution. This snapshot is performed on-demand by a delegate whenever it is in his/her interest, that is, when winning a seat or increasing the share of appointments. Tokens are allocated when the next snapshot is invoked.
    function distributeDelegationReward() external {
        if (_lastCitizenCount == 0) {
            // this is first time to take a snapshot, therefore there is no previous snapshot to compute.
            _takeDelegationSnapshot();
            return;
        }

        uint256 totalReward = (block.timestamp - _lastSnapshotTimestamp) * _delegationRewardRate;

        for (uint256 i = 0; i < _lastCitizenCounts.length; i++) {
            _rewardBalances[_lastDelegates[i]] += (totalReward * _lastCitizenCounts[i]) / _lastCitizenCount;
        }

        _takeDelegationSnapshot();
        emit DelegationReward(totalReward);
    }

    ///
    /// Execution
    ///

    function getExecRewardExponentMax() external view returns (uint256) {
        return _execRewardExponentMax;
    }

    /// @dev Sets the maximum value of the exponent, which is the number of seconds passed from the proposal's endting time, of the exponential formula that that determines the number of execution reward tokens.
    /// @param execRewardExponentMax The maximum value of the exponent.
    function setExecRewardExponentMax(uint256 execRewardExponentMax) external isInitialized onlyOwner {
        require(execRewardExponentMax != _execRewardExponentMax, "The new parameter value must be different");

        _execRewardExponentMax = execRewardExponentMax;
    }

    /// @dev Tries to tally up and execute a proposed transaction for tokens as a reward.
    /// @param tallyId The tally whose associated proposed transaction can be executed.
    /// @return True if the proposed transaction was succesfully executed.
    function execute(uint256 tallyId) external returns (bool) {
        Tally storage t = _tallies[tallyId];
        if (t.status == TallyStatus.ProvisionalNotApproved || t.status == TallyStatus.ProvisionalApproved) super.tallyUp(tallyId);

        if (super.enact(tallyId)) {
            uint256 reward = 2**Math.min(block.timestamp - t.votingEndTime, _execRewardExponentMax);
            _rewardBalances[msg.sender] += reward;
            emit ExecutionReward(msg.sender, reward);
            return true;
        }
        return false;
    }

    ///
    /// Referrals
    ///

    function getReferralRewardParams() external view returns (uint256, uint256) {
        return (_referredAmount, _referrerAmount);
    }

    /// @param referredAmount Number of tokens to reward the referred human
    /// @param referrerAmount Number of tokens to reward the referrer human
    function setReferralRewardParams(uint256 referredAmount, uint256 referrerAmount) external isInitialized onlyOwner {
        require(_referredAmount != referredAmount || _referrerAmount != referrerAmount, "The new parameter value must be different");

        _referredAmount = referredAmount;
        _referrerAmount = referrerAmount;
    }

    /// @dev Referred humans can only claim their referred reward tokens once.
    /// @param referred The address of the referred human.
    /// @return Whether or not the human claimed his or her referred reward tokens.
    function isReferredClaimed(address referred) external view returns (bool) {
        return _referredClaimed[referred];
    }

    /// @dev Sends a referral reward in tokens to both the referrer and the referred humans. This function must be called by the referred human.
    /// @param referrer The address of the referrer.
    function claimReferralReward(address referrer) external isInitialized {
        require(referrer != msg.sender, "Referrers cannot refer themselves");
        require(_isInCitizenCount[msg.sender] || _isInDelegateCount[msg.sender], "To be referred, first you must become a citizen or a delegate");
        require(_isInCitizenCount[referrer] || _isInDelegateCount[referrer], "Your referrer must be a citizen or a delegate");
        require(_referredClaimed[msg.sender] == false, "You have already claimed your referred amount");
        require(_referredAmount > 0 || _referrerAmount > 0, "There are no referral rewards currently");

        bytes memory foo;
        if (_referredAmount > 0) _faucet.send(msg.sender, _referredAmount, foo);
        emit ReferralReward(msg.sender, _referredAmount);
        if (_referrerAmount > 0) _faucet.send(referrer, _referrerAmount, foo);
        emit ReferralReward(referrer, _referrerAmount);
        _referredClaimed[msg.sender] = true;
    }
}