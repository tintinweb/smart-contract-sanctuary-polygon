// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';

interface IOwnable is IOwnableInternal, IERC173 {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from '../../interfaces/IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {
    error Ownable__NotOwner();
    error Ownable__NotTransitiveOwner();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { IOwnable } from './IOwnable.sol';
import { OwnableInternal } from './OwnableInternal.sol';

/**
 * @title Ownership access control based on ERC173
 */
abstract contract Ownable is IOwnable, OwnableInternal {
    /**
     * @inheritdoc IERC173
     */
    function owner() public view virtual returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address account) public virtual onlyOwner {
        _transferOwnership(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173 } from '../../interfaces/IERC173.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using AddressUtils for address;

    modifier onlyOwner() {
        if (msg.sender != _owner()) revert Ownable__NotOwner();
        _;
    }

    modifier onlyTransitiveOwner() {
        if (msg.sender != _transitiveOwner())
            revert Ownable__NotTransitiveOwner();
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transitiveOwner() internal view virtual returns (address owner) {
        owner = _owner();

        while (owner.isContract()) {
            try IERC173(owner).owner() returns (address transitiveOwner) {
                owner = transitiveOwner;
            } catch {
                break;
            }
        }
    }

    function _transferOwnership(address account) internal virtual {
        _setOwner(account);
    }

    function _setOwner(address account) internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, account);
        l.owner = account;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return contract owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IProxy {
    error Proxy__ImplementationIsNotContract();

    fallback() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "@solidstate/contracts/utils/AddressUtils.sol";

import "./CollectionProxyStorage.sol";
import "./Proxy.sol";

bytes4 constant SELECTOR_FACET_ADDRESS = bytes4(
    keccak256("facetAddress(bytes4)")
);
bytes4 constant SELECTOR_SUPPORTS_INTERFACE = bytes4(
    keccak256("supportsInterface(bytes4)")
);
bytes4 constant SELECTOR_GET_SUPPORTED_INTERFACE = bytes4(
    keccak256("getSupportedInterface(bytes4)")
);

error CollectionProxyAlreadyInitialized();
error ImplementationAddressNotFound();

/**
 * @title A Startrail NFT Collection proxy contract.
 * @author Chris Hatch - <[email protected]>
 * @dev Collection contracts are CollectionProxy’s that lookup implementation
 *      contracts at a shared FeatureRegistry. The shared registry, which is
 *      essentially a Beacon to multiple implementation contracts, enables
 *      all proxies to be upgraded at the same time.
 */
contract CollectionProxy is Proxy {
    using AddressUtils for address;
    using CollectionProxyStorage for CollectionProxyStorage.Layout;

    function __CollectionProxy_initialize(address _featureRegistry) external {
        CollectionProxyStorage.Layout storage layout = CollectionProxyStorage
            .layout();
        if (layout.featureRegistry != address(0)) {
            revert CollectionProxyAlreadyInitialized();
        }
        layout.setFeatureRegistry(_featureRegistry);
    }

    /**
     * @dev Static calls supportsInterface(bytes4) on the FeatureRegistry
     *      to lookup it's registry (in storage) of interfaces supported.
     *
     *      An alternative would be to store that information in each proxy
     *      however storing it in the FeatureRegistry one time is a cheaper
     *      option.
     */
    function staticcallSupportsInterfaceOnFeatureRegistry() private view {
        address featureRegistry = CollectionProxyStorage
            .layout()
            .featureRegistry;

        // First 4 bytes will be the interfaceId to query
        bytes4 interfaceId = abi.decode(msg.data[4:], (bytes4));

        // FeatureRegistry.getSupportedInterface(interfaceId)
        (bool success, ) = featureRegistry.staticcall(
            abi.encodeWithSelector(
                SELECTOR_GET_SUPPORTED_INTERFACE,
                interfaceId
            )
        );

        // Inspect and handle the response
        assembly {
            returndatacopy(0, 0, returndatasize())
            switch success
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable override {
        // Special case: for supportsInterface() the information to query
        //   is in the storage of the FeatureRegistry. So for this call alone
        //   we don't delegatecall, but instead do a static call.
        if (msg.sig == SELECTOR_SUPPORTS_INTERFACE) {
            staticcallSupportsInterfaceOnFeatureRegistry();
        } else {
            // All other functions (msg.sig's) use the normal proxy mechanism
            super.handleFallback();
        }
    }

    receive() external payable {}

    /**
     * @dev Query FeatureRegistry.facetAddress() to get the implementation
     *   contract for the incoming function signature (msg.sig).
     *
     *   facetAddress() will lookup the registry of 4 bytes function signatures
     *   to implementation addresses. See the FeatureRegistry for details.
     */
    function _getImplementation()
        internal
        view
        override
        returns (address implementationAddress)
    {
        address featureRegistry = CollectionProxyStorage
            .layout()
            .featureRegistry;
        (bool success, bytes memory returnData) = featureRegistry.staticcall(
            abi.encodeWithSelector(SELECTOR_FACET_ADDRESS, msg.sig)
        );
        if (success) {
            implementationAddress = address(bytes20(bytes32(returnData) << 96));
        } else {
            revert ImplementationAddressNotFound();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library CollectionProxyStorage {
    struct Layout {
        address featureRegistry;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.CollectionProxy");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setFeatureRegistry(Layout storage l, address featureRegistry)
        internal
    {
        l.featureRegistry = featureRegistry;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "./features/ERC721FeatureV01.sol";
import "./features/OwnableFeatureV01.sol";
import "./CollectionProxy.sol";

/**
 * @title Registry of Startrail NFT Collection contracts
 * @author Chris Hatch - <[email protected]>
 */
contract CollectionRegistry {
    error OnlyCollectionFactory();

    mapping(address => bool) public registry;

    address public collectionFactory;

    constructor(address collectionFactory_) {
        collectionFactory = collectionFactory_;
    }

    function addCollection(address collectionAddress) external {
        if (msg.sender != collectionFactory) {
            revert OnlyCollectionFactory();
        }
        registry[collectionAddress] = true;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

error TokenNotExists();
error TokenAlreadyExists();

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.13;

import "./ERC721TokenReceiver.sol";
import "./LibERC721Events.sol";
import "./LibERC721Storage.sol";

/// @notice A forked version of Solmate ERC721 that uses a storage struct for use in a Diamond or similar proxy pattern.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721UpgradeableBase {
    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory) {
        return LibERC721Storage.layout().name;
    }

    function symbol() external view returns (string memory) {
        return LibERC721Storage.layout().symbol;
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require(
            (owner = LibERC721Storage.layout().ownerOf[id]) != address(0),
            "NOT_MINTED"
        );
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return LibERC721Storage.layout().balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL GETTERS
    //////////////////////////////////////////////////////////////*/

    function getApproved(uint256 tokenId) public view returns (address) {
        return LibERC721Storage.layout().getApproved[tokenId];
    }

    function isApprovedForAll(
        address owner,
        address operator
    ) public view returns (bool) {
        return LibERC721Storage.layout().isApprovedForAll[owner][operator];
    }

    /*//////////////////////////////////////////////////////////////
                               INITIALIZER
    //////////////////////////////////////////////////////////////*/

    function __ERC721_init(
        string memory _name,
        string memory _symbol
    ) internal {
        LibERC721Storage.Layout storage layout = LibERC721Storage.layout();
        layout.name = _name;
        layout.symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        LibERC721Storage.Layout storage layout = LibERC721Storage.layout();

        address owner = layout.ownerOf[id];

        require(
            msg.sender == owner || layout.isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

        layout.getApproved[id] = spender;

        emit LibERC721Events.Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        LibERC721Storage.layout().isApprovedForAll[msg.sender][
            operator
        ] = approved;

        emit LibERC721Events.ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        LibERC721Storage.Layout storage layout = LibERC721Storage.layout();

        require(from == layout.ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from ||
                layout.isApprovedForAll[from][msg.sender] ||
                msg.sender == layout.getApproved[id],
            "NOT_AUTHORIZED"
        );

        LibERC721Storage._transferFrom(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);
        safeTransferFromReceivedCheck(msg.sender, from, to, id, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);
        safeTransferFromReceivedCheck(msg.sender, from, to, id, data);
    }

    function safeTransferFromReceivedCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) internal {
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    operator,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(
        bytes4 interfaceId
    ) external view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

library LibERC721Events {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../erc721/ERC721Errors.sol";
import "../erc721/ERC721TokenReceiver.sol";
import "../erc721/LibERC721Events.sol";

library LibERC721Storage {
    /*//////////////////////////////////////////////////////////////
                            STORAGE STRUCT
    //////////////////////////////////////////////////////////////*/

    struct Layout {
        // Metadata
        string name;
        string symbol;
        // Balance/Owner
        mapping(uint256 => address) ownerOf;
        mapping(address => uint256) balanceOf;
        // Approval
        mapping(uint256 => address) getApproved;
        mapping(address => mapping(address => bool)) isApprovedForAll;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.ERC721");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function exists(uint256 tokenId) internal view returns (bool) {
        return layout().ownerOf[tokenId] != address(0);
    }

    function onlyExistingToken(uint256 tokenId) internal view {
        if (!exists(tokenId)) {
            revert TokenNotExists();
        }
    }

    function onlyNonExistantToken(uint256 tokenId) internal view {
        if (exists(tokenId)) {
            revert TokenAlreadyExists();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        require(to != address(0), "INVALID_RECIPIENT");

        require(layout_.ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            layout_.balanceOf[to]++;
        }

        layout_.ownerOf[id] = to;

        emit LibERC721Events.Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        address owner = layout_.ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            layout_.balanceOf[owner]--;
        }

        delete layout_.ownerOf[id];

        delete layout_.getApproved[id];

        emit LibERC721Events.Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    address(0),
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    function _transferFrom(address from, address to, uint256 id) internal {
        LibERC721Storage.Layout storage layout_ = LibERC721Storage.layout();

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            layout_.balanceOf[from]--;

            layout_.balanceOf[to]++;
        }

        layout_.ownerOf[id] = to;

        delete layout_.getApproved[id];

        emit LibERC721Events.Transfer(from, to, id);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./erc721/ERC721UpgradeableBase.sol";
import "./erc721/LibERC721Storage.sol";
import "./interfaces/IERC721FeatureV01.sol";
import "./interfaces/ILockExternalTransferFeatureV01.sol";
import "./shared/LibFeatureCommon.sol";

error ERC721FeatureAlreadyInitialized();

contract ERC721FeatureV01 is IERC721FeatureV01, ERC721UpgradeableBase {
    /**
     * @inheritdoc IERC721FeatureV01
     */
    function __ERC721Feature_initialize(
        string memory name_,
        string memory symbol_
    ) external {
        LibERC721Storage.Layout storage layout = LibERC721Storage.layout();
        if (
            bytes(layout.name).length != 0 && bytes(layout.symbol).length != 0
        ) {
            revert ERC721FeatureAlreadyInitialized();
        }
        __ERC721_init(name_, symbol_);
    }

    /**
     * @inheritdoc IERC721FeatureV01
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return LibERC721Storage.exists(tokenId);
    }

    /**
     * @inheritdoc ERC721UpgradeableBase
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        LibFeatureCommon.onlyExternalTransferUnlocked(id);
        ERC721UpgradeableBase.transferFrom(from, to, id);
    }

    /**
     * @inheritdoc ERC721UpgradeableBase
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        LibFeatureCommon.onlyExternalTransferUnlocked(tokenId);
        ERC721UpgradeableBase.transferFrom(from, to, tokenId);
    }

    /**
     * @inheritdoc ERC721UpgradeableBase
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) public virtual override {
        LibFeatureCommon.onlyExternalTransferUnlocked(tokenId);
        ERC721UpgradeableBase.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @inheritdoc ERC721UpgradeableBase
     */
    function approve(address spender, uint256 tokenId) public override {
        LibFeatureCommon.onlyExternalTransferUnlocked(tokenId);
        ERC721UpgradeableBase.approve(spender, tokenId);
    }

    /**
     * @inheritdoc IERC721FeatureV01
     */
    function transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external override {
        LibFeatureCommon.onlyExternalTransferUnlocked(tokenId);

        address tokenOwner = ownerOf(tokenId);
        address sender = LibFeatureCommon.msgSender();

        // Not using a custom error here to be consistent with how
        // ERC721UpgradeableBase handles these errors. In this way
        // clients can expect all these checks to return
        // NOT_AUTHORIZED.
        require(sender == tokenOwner, "NOT_AUTHORIZED");

        LibFeatureCommon.logProvenance(
            tokenId,
            tokenOwner,
            to,
            historyMetadataHash,
            customHistoryId,
            isIntermediary
        );
        LibERC721Storage._transferFrom(tokenOwner, to, tokenId);
        ERC721UpgradeableBase.safeTransferFromReceivedCheck(
            sender,
            tokenOwner,
            to,
            tokenId,
            ""
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IERC721FeatureV01 {
    /**
     * @dev ERC721 initializer to set the name and symbol
     */
    function __ERC721Feature_initialize(
        string memory name,
        string memory symbol
    ) external;

    /**
     * @dev See if token with given id exists
     * Externalize this for other feature contracts to verify token existance.
     * @param tokenId NFT id
     * @return true if token exists
     */
    function exists(uint256 tokenId) external view returns (bool);

    /**
     * @dev Safely transfers ownership of a token and logs Provenance.
     * The external transfer log is checked also.
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param historyMetadataHash string of the history metadata digest or cid
     * @param customHistoryId to map with custom history
     * @param isIntermediary bool flag of the intermediary default is false
     */
    function transferFromWithProvenance(
        address to,
        uint256 tokenId,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

/**
 * @dev Flag enabling standard ERC721 transfer methods to be disabled for a
 * given token.
 */
interface ILockExternalTransferFeatureV01 {
    error OnlyIssuerOrCollectionOwner();

    /**
     * @dev Set the lock flag for the given tokenId
     * @param tokenId NFT id
     * @param flag bool of the flag to disable standard ERC721 transfer methods
     */
    function setLockExternalTransfer(uint256 tokenId, bool flag) external;

    /**
     * @dev Get the flag setting for a given token id
     * @param tokenId NFT id
     * @return Flag value
     */
    function getLockExternalTransfer(
        uint256 tokenId
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IOwnableFeatureV01 {
    error ZeroAddress();

    /**
     * @dev Ownable initializer
     */
    function __OwnableFeature_initialize(address initialOwner) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";
import {IOwnable} from "@solidstate/contracts/access/ownable/IOwnable.sol";
import {Ownable} from "@solidstate/contracts/access/ownable/Ownable.sol";
import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";

import "./interfaces/IOwnableFeatureV01.sol";
import "./shared/LibFeatureCommon.sol";

error OwnableFeatureAlreadyInitialized();

/**
 * @dev OwnableFeature that is an ERC173 compatible Ownable implementation.
 *
 * It adds an initializer function to set the owner.
 */
contract OwnableFeatureV01 is IOwnable, IOwnableFeatureV01, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    /**
     * @inheritdoc IOwnableFeatureV01
     */
    function __OwnableFeature_initialize(address initialOwner) external {
        if (OwnableStorage.layout().owner != address(0)) {
            revert OwnableFeatureAlreadyInitialized();
        }
        OwnableStorage.layout().owner = initialOwner;
    }

    /**
     * @inheritdoc IERC173
     */
    function owner() public view override returns (address) {
        return _owner();
    }

    /**
     * @inheritdoc IERC173
     */
    function transferOwnership(address newOwner) external override {
        LibFeatureCommon.onlyTrustedForwarder();
        LibFeatureCommon.onlyCollectionOwner();

        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        _transferOwnership(newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {OwnableStorage} from "@solidstate/contracts/access/ownable/OwnableStorage.sol";

import "../../../common/INameRegistry.sol";
import "../../registry/interfaces/IStartrailCollectionFeatureRegistry.sol";
import "../../shared/LibEIP2771.sol";
import "../../CollectionProxyStorage.sol";
import "../erc721/ERC721Errors.sol";
import "../storage/LibLockExternalTransferStorage.sol";
import "../storage/LibSRRMetadataStorage.sol";
import {LibERC721Storage} from "../erc721/LibERC721Storage.sol";
import "./LibSRRProvenanceEvents.sol";

library LibFeatureCommon {
    error NotAdministrator();
    error NotCollectionOwner();
    error OnlyIssuerOrArtistOrAdministrator();
    error OnlyIssuerOrArtistOrCollectionOwner();
    error ERC721ExternalTransferLocked();

    function getNameRegistry() internal view returns (address) {
        return
            IStartrailCollectionFeatureRegistry(
                CollectionProxyStorage.layout().featureRegistry
            ).getNameRegistry();
    }

    function getAdministrator() internal view returns (address) {
        return INameRegistry(getNameRegistry()).administrator();
    }

    function onlyCollectionOwner() internal view {
        if (msgSender() != OwnableStorage.layout().owner) {
            revert NotCollectionOwner();
        }
    }

    function getCollectionOwner() internal view returns (address) {
        return OwnableStorage.layout().owner;
    }

    function onlyAdministrator() internal view {
        if (msgSender() != getAdministrator()) {
            revert NotAdministrator();
        }
    }

    function onlyLicensedUser() internal view {
        return
            LibEIP2771.onlyLicensedUser(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    function onlyExternalTransferUnlocked(uint256 tokenId) internal view {
        if (
            LibLockExternalTransferStorage.layout().tokenIdToLockFlag[tokenId]
        ) {
            revert ERC721ExternalTransferLocked();
        }
    }

    function logProvenance(
        uint256 tokenId,
        address from,
        address to,
        string memory historyMetadataHash,
        uint256 customHistoryId,
        bool isIntermediary
    ) internal {
        string memory historyMetadataURI = LibSRRMetadataStorage.buildTokenURI(
            historyMetadataHash
        );

        if (customHistoryId != 0) {
            emit LibSRRProvenanceEvents.Provenance(
                tokenId,
                from,
                to,
                customHistoryId,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        } else {
            emit LibSRRProvenanceEvents.Provenance(
                tokenId,
                from,
                to,
                historyMetadataHash,
                historyMetadataURI,
                isIntermediary
            );
        }
    }

    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    /****************************************************************
     *
     * EIP2771 related functions
     *
     ***************************************************************/

    function isTrustedForwarder() internal view returns (bool) {
        return
            LibEIP2771.isTrustedForwarder(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    function onlyTrustedForwarder() internal view {
        return
            LibEIP2771.onlyTrustedForwarder(
                CollectionProxyStorage.layout().featureRegistry
            );
    }

    /**
     * @dev return the sender of this call.
     *
     * This should be used in the contract anywhere instead of msg.sender.
     *
     * If the call came through our trusted forwarder, return the EIP2771
     * address that was appended to the calldata. Otherwise, return `msg.sender`.
     */
    function msgSender() internal view returns (address ret) {
        return
            LibEIP2771.msgSender(
                CollectionProxyStorage.layout().featureRegistry
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

library LibSRRProvenanceEvents {
    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );

    event Provenance(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to,
        uint256 customHistoryId,
        string historyMetadataHash,
        string historyMetadataURI,
        bool isIntermediary
    );
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibLockExternalTransferStorage {
    struct Layout {
        // tokenId => on|off
        mapping(uint256 => bool) tokenIdToLockFlag;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.LockExternalTransfer");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

library LibSRRMetadataStorage {
    error SRRMetadataNotEmpty();

    struct Layout {
        // tokenId => metadataCID (string of ipfs cid)
        mapping(uint256 => string) srrs;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("startrail.storage.SRR.Metadata");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function buildTokenURI(
        string memory metadataCID
    ) internal pure returns (string memory) {
        return string(abi.encodePacked("ipfs://", metadataCID));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IProxy} from "@solidstate/contracts/proxy/IProxy.sol";
import {AddressUtils} from "@solidstate/contracts/utils/AddressUtils.sol";

/**
 * @title Base proxy contract modified from the @solidstate/contracts Proxy.sol
 *
 * Modification simply moves the body of the fallback() into a separate
 * internal function called handleFallback. This enables the child contract to
 * call it with super.
 */
abstract contract Proxy is IProxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    function handleFallback() internal virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            "Proxy: implementation must be contract"
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    fallback() external payable virtual {
        return handleFallback();
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

interface IStartrailCollectionFeatureRegistry {
    /**
     * @dev Get the EIP2771 trusted forwarder address
     * @return the trusted forwarder
     */
    function getEIP2771TrustedForwarder() external view returns (address);

    /**
     * @dev Get the NameRegistry contract address
     * @return NameRegistry address
     */
    function getNameRegistry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../../common/INameRegistry.sol";
import "../registry/interfaces/IStartrailCollectionFeatureRegistry.sol";

interface ILUM {
    function isActiveWallet(address walletAddress) external view returns (bool);
}

// Copied this key value from Contracts.sol because it can't be imported and
// used. This is because:
//  - libraries can't inherit from other contracts
//  - keys in Contracts.sol are `internal` so not accessible if not inherited
uint8 constant NAME_REGISTRY_KEY_LICENSED_USER_MANAGER = 3;

library LibEIP2771 {
    error NotLicensedUser();
    error NotTrustedForwarder();

    function isTrustedForwarder(
        address featureRegistryAddress
    ) internal view returns (bool) {
        return
            msg.sender ==
            IStartrailCollectionFeatureRegistry(featureRegistryAddress)
                .getEIP2771TrustedForwarder();
    }

    function onlyTrustedForwarder(
        address featureRegistryAddress
    ) internal view {
        if (!isTrustedForwarder(featureRegistryAddress)) {
            revert NotTrustedForwarder();
        }
    }

    function onlyLicensedUser(address featureRegistryAddress) internal view {
        if (
            !ILUM(
                INameRegistry(
                    IStartrailCollectionFeatureRegistry(featureRegistryAddress)
                        .getNameRegistry()
                ).get(NAME_REGISTRY_KEY_LICENSED_USER_MANAGER)
            ).isActiveWallet(msgSender(featureRegistryAddress))
        ) {
            revert NotLicensedUser();
        }
    }

    /**
     * @dev return the sender of this call.
     *
     * This should be used in the contract anywhere instead of msg.sender.
     *
     * If the call came through our trusted forwarder, return the EIP2771
     * address that was appended to the calldata. Otherwise, return `msg.sender`.
     */
    function msgSender(
        address featureRegistryAddress
    ) internal view returns (address ret) {
        if (
            msg.data.length >= 24 && isTrustedForwarder(featureRegistryAddress)
        ) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

interface INameRegistry {
    function get(uint8 key) external view returns (address);
    function set(uint8 key, address value) external;
    function administrator() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

/**
 * @title SignatureDecoder - Decodes signatures that are encoded as bytes
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 * @author Richard Meissner - <[email protected]>
 * @dev From Gnosis safe. Changes made:
 *  - removed unused recoveryKey function (used in StateChannelModule in Gnosis safe)
 */
contract SignatureDecoder {
  /**
   * @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
   * @notice Make sure to peform a bounds check for @param pos, to avoid out of bounds access on @param signatures
   * @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
   * @param signatures concatenated rsv signatures
   */
  function signatureSplit(
    bytes memory signatures,
    uint256 pos
  )
    internal
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
    // The signature format is a compact form of:
    //   {bytes32 r}{bytes32 s}{uint8 v}
    // Compact means, uint8 is not padded to 32 bytes.
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      let signaturePos := mul(0x41, pos)
      r := mload(add(signatures, add(signaturePos, 0x20)))
      s := mload(add(signatures, add(signaturePos, 0x40)))
      // Here we are loading the last 32 bytes, including 31 bytes
      // of 's'. There is no 'mload8' to do this.
      //
      // 'byte' is not working due to the Solidity parser, so lets
      // use the second best option, 'and'
      v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
    }
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./IMetaTxRequest.sol";

/**
 * @title Meta transaction forwarding interface.
 */
interface IMetaTxForwarderV2 is IMetaTxRequest {
  /**
   * @dev Execute a meta-tx request given request details and a list of
   *      signatures for a Licensed User Wallet (LUW). Asks the 
   *      LicensedUserManager (LUM) if the signatures of the request are valid.
   *      This includes a multisig threshold check.
   * @param _request ExecutionRequest - transaction details
   * @param _signatures List of signatures authorizing the transaction.
   * @return success Success or failure
   */
  function executeTransactionLUW(
    ExecutionRequest calldata _request,
    bytes calldata _signatures
  )
    external
    returns (bool success);

  /**
   * @dev Execute a meta-tx request given request details and a single 
   *      signature signed by an EOA.
   * @param _request ExecutionRequest - transaction details
   * @param _signature Flattened signature of hash of encoded meta-tx details.
   * @return success Success or failure
   */
  function executeTransactionEOA(
    ExecutionRequest calldata _request,
    bytes calldata _signature
  )
    external
    returns (bool success);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title Meta transaction ExecutionRequest structure.
 */
interface IMetaTxRequest {  
  
  struct ExecutionRequest {
    // MetaTxRequest type hash - see MetaTxRequestManager.sol
    bytes32 typeHash; 

    // EOA address if executeTransactionEOA called
    // Licensed User wallet (LUW) address if executeTransactionLUW called
    address from;
    
    // 2d nonce packed - see ReplayProtection.sol
    uint256 nonce;

    // EIP712 encodeStruct of the MetaTx specific arguments
    // This is used when encoding the full EIP712 message to
    // check the signatures.
    bytes suffixData;

    // (OPTIONAL) calldata is required if the MetaTx type has arguments of
    // type bytes, string or array. This is because the ABI encoding differs
    // from the EIP712 encodeData encoding rules when there are properties of
    // these types.
    //
    // We make it optional to save a little gas for those MetaTx request types
    // that don't contain argument with these types. Currently the majority of
    // requests do not.
    bytes callData;
  }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import {IERC173} from "@solidstate/contracts/interfaces/IERC173.sol";

import "../collection/CollectionRegistry.sol";
import "../common/SignatureDecoder.sol";
import "../name/Contracts.sol";

import "./IMetaTxRequest.sol";
import "./IMetaTxForwarderV2.sol";
import "./MetaTxRequestManager.sol";
import "./replayProtection/ReplayProtection.sol";
import "./TransactionExecutor.sol";

interface ILicensedUserManager {
    function isValidSignatureSet(
        address _walletAddress,
        bytes32 _hash,
        bytes calldata _signatures
    ) external returns (bytes4);
}

error DestinationNotACollectionProxy();

/**
 * @title MetaTxForwarder - forward meta tx requests to destination contracts.
 * @author Chris Hatch - <[email protected]>
 * @dev A meta-tx forwarding contract using EIP2771 to forward the sender address.
 */
contract MetaTxForwarderV3 is
    Contracts,
    IMetaTxForwarderV2,
    SignatureDecoder,
    TransactionExecutor,
    ReplayProtection,
    MetaTxRequestManager
{
    error ZeroAddress();

    // Valid signature check response (use EIP1271 style response)
    // Value is the function signature of isValidSignatureSet
    // Also defined in LicensedUserManager.sol which returns this value.
    bytes4 internal constant IS_VALID_SIG_SUCCESS = 0x9878440b;

    address public collectionRegistry;

    //
    // Initializer
    //

    /**
     * @dev Setup the contract
     * @param _nameRegistry NameRegistry address.
     */
    function initialize(address _nameRegistry) external initializer {
        if (_nameRegistry == address(0)) {
            revert ZeroAddress();
        }
        MetaTxRequestManager.__MTRM_initialize(_nameRegistry);
    }

    //
    // Proxy / Execute Transaction Functions
    //

    /**
     * @dev Execute a meta-tx request given request details and a list of
     *      signatures for a Licensed User Wallet (LUW). Asks the
     *      LicensedUserManager (LUM) if the signatures of the request are valid.
     *      This includes a multisig threshold check.
     * @param _request ExecutionRequest - transaction details
     * @param _signatures List of signatures authorizing the transaction.
     * @return success Success or failure
     */
    function executeTransactionLUW(
        ExecutionRequest calldata _request,
        bytes calldata _signatures
    )
        external
        override
        requestTypeRegistered(_request.typeHash)
        returns (bool success)
    {
        return executeTransactionInternal(_request, _signatures, false);
    }

    /**
     * @dev Execute a meta-tx request given request details and a single
     *      signature signed by an EOA.
     * @param _request ExecutionRequest - transaction details
     * @param _signature Flattened signature of hash of encoded meta-tx details.
     * @return success Success or failure
     */
    function executeTransactionEOA(
        ExecutionRequest calldata _request,
        bytes calldata _signature
    )
        external
        override
        requestTypeRegistered(_request.typeHash)
        returns (bool success)
    {
        return executeTransactionInternal(_request, _signature, true);
    }

    /**
     * @dev Execute a meta-tx request given request details and signature(s).
     *      This internal function handles validation of signatures from either
     *      an EOA or a LicensedUser wallet.
     * @param _request ExecutionRequest - transaction details
     * @param _signatures Flattened signature of hash of encoded meta-tx details.
     * @return success Success or failure
     */
    function executeTransactionInternal(
        ExecutionRequest calldata _request,
        bytes calldata _signatures,
        bool isEOASignature
    ) internal requestTypeRegistered(_request.typeHash) returns (bool success) {
        require(
            checkAndUpdateNonce(_request.from, _request.nonce),
            "Invalid nonce"
        );

        bytes memory txHashEncoded = encodeRequest(_request);
        bytes32 txHash = keccak256(txHashEncoded);

        if (isEOASignature) {
            uint8 v;
            bytes32 r;
            bytes32 s;
            (v, r, s) = signatureSplit(_signatures, 0);
            require(
                ecrecover(txHash, v, r, s) == _request.from,
                "Signer verification failed"
            );
        } else {
            require(
                ILicensedUserManager(
                    INameRegistry(nameRegistryAddress).get(
                        Contracts.LICENSED_USER_MANAGER
                    )
                ).isValidSignatureSet(_request.from, txHash, _signatures) ==
                    IS_VALID_SIG_SUCCESS,
                "isValidSignatureSet check failed"
            );
        }

        // Determine the destination contract
        address destination = requestTypes[_request.typeHash].destination;
        bool destinationInRequest = destination == address(0x0);
        if (destinationInRequest) {
            // If the registered destination address is 0 than it's assumed that the
            // first request parameter is the destination address and that it is a
            // Collection address
            destination = address(
                bytes20(bytes32(_request.suffixData[:32]) << 96)
            );

            // Verify it's a registered CollectionProxy address
            if (!CollectionRegistry(collectionRegistry).registry(destination)) {
                revert DestinationNotACollectionProxy();
            }
        }

        bytes memory callData;

        // If callData provided then use it as is
        if (_request.callData.length > 0) {
            callData = _request.callData;
        } else {
            // If callData NOT provided build it using the EIP712 encoding
            // and strip out the destination if it's there.
            // This method can't be used for requests with bytes, strings or
            // arrays. In these cases the request must define a separate prop
            // 'callData'.
            callData = abi.encodePacked(
                requestTypes[_request.typeHash].functionSignature,
                destinationInRequest
                    ? _request.suffixData[32:]
                    : _request.suffixData
            );
        }

        // Append the sender (EIP-2771)
        callData = abi.encodePacked(callData, _request.from);

        success = executeCall(destination, callData, txHash);
    }

    function setCollectionRegistry(
        address _registry
    ) external onlyAdministrator {
        if (_registry == address(0)) {
            revert ZeroAddress();
        }
        collectionRegistry = _registry;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "../proxy/utils/InitializableWithGap.sol";
import "../common/INameRegistry.sol";
import "./IMetaTxRequest.sol";

/**
 * @title MetaTxRequestManager - a register of Startrail MetaTx request types
 * @dev This contract maintains a register of all Startrail meta transaction
 * request types.
 *
 * Each request is registered with an EIP712 typeHash. The type hash and
 * corresponding type string are emitted with event RequestTypeRegistered
 * at registration time.
 *
 * All request types share a common set of parameters defined by
 * GENERIC_PARAMS.
 *
 * The function encodeRequest is provided to build a an EIP712 signature
 * encoding for a given request type and inputs.
 * @author Chris Hatch - <[email protected]>
 */
contract MetaTxRequestManager is InitializableWithGap, IMetaTxRequest {
    //
    // Types
    //

    struct MetaTxRequestType {
        address destination;
        bytes4 functionSignature;
    }

    //
    // Events
    //

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);
    event RequestTypeUnregistered(bytes32 indexed typeHash);

    //
    // Constants
    //

    string public constant DOMAIN_NAME = "Startrail";
    string public constant DOMAIN_VERSION = "1";
    bytes32 public constant DOMAIN_SEPARATOR_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    string public constant GENERIC_PARAMS = "address from,uint256 nonce";

    //
    // State
    //

    // register of request types
    mapping(bytes32 => bool) public typeHashes;

    // each request type typeHash maps to details
    mapping(bytes32 => MetaTxRequestType) public requestTypes;

    bytes32 public domainSeparator;

    address public nameRegistryAddress;

    //
    // Modifiers
    //

    modifier requestTypeRegistered(bytes32 _typeHash) {
        require(typeHashes[_typeHash] == true, "request type not registered");
        _;
    }

    modifier onlyAdministrator() {
        require(
            INameRegistry(nameRegistryAddress).administrator() == msg.sender,
            "Caller is not the Startrail Administrator"
        );
        _;
    }

    //
    // Functions
    //

    /**
     * @dev Setup the contract - build the domain separator with chain id
     */
    function __MTRM_initialize(address _nameRegistryAddress)
        internal
        initializer
    {
        uint256 chainId;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            chainId := chainid()
        }

        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                chainId,
                this // verifyingContract
            )
        );

        nameRegistryAddress = _nameRegistryAddress;
    }

    /**
     * @dev Add a new request type to the register.
     *
     * _typeSuffix defines the parameters that follow the GENERIC_PARAMS
     * (defined above). The format should follow the EIP712 spec.
     *
     * Where the full type hash is:
     *
     *   name ‖ "(" ‖ member₁ ‖ "," ‖ member₂ ‖ "," ‖ … ‖ memberₙ ")"
     *
     * _typeSuffix format can be defined as:
     *
     *   memberₘ ‖ "," ‖ … ‖ memberₙ
     *
     * @param _typeName Request type name
     * @param _typeSuffix Defines parameters specific to the request
     * @param _destinationContract Single fixed destination of this request
     * @param _functionSignature 4 byte Solidity function signature to call
     */
    function registerRequestType(
        string calldata _typeName,
        string calldata _typeSuffix,
        address _destinationContract,
        bytes4 _functionSignature
    ) external onlyAdministrator {
        // Check the name doesn't have '(' or ')' inside it
        for (uint256 i = 0; i < bytes(_typeName).length; i++) {
            bytes1 c = bytes(_typeName)[i];
            require(c != "(" && c != ")", "invalid typename");
        }

        string memory requestType = string(
            abi.encodePacked(
                _typeName,
                "(",
                GENERIC_PARAMS,
                ",",
                _typeSuffix,
                ")"
            )
        );
        bytes32 requestTypeHash = keccak256(bytes(requestType));
        require(
            typeHashes[requestTypeHash] == false,
            "Already registered type with this typeHash"
        );

        typeHashes[requestTypeHash] = true;
        requestTypes[requestTypeHash] = MetaTxRequestType(
            _destinationContract,
            _functionSignature
        );
        emit RequestTypeRegistered(requestTypeHash, string(requestType));
    }

    /**
     * @dev Remove a new request type from the register.
     * @param _typeHash Request type hash
     */
    function unregisterRequestType(bytes32 _typeHash)
        external
        requestTypeRegistered(_typeHash)
        onlyAdministrator
    {
        // remove typeHash - using delete instead of assigning false here is
        // slightly cheaper (measured 121 gas difference) and both get a small
        // refund:
        delete typeHashes[_typeHash];

        // remove type details
        delete requestTypes[_typeHash];

        emit RequestTypeUnregistered(_typeHash);
    }

    /**
     * @dev Encodes request details into EIP712 spec encoding format.
     * @param _request ExecutionRequest - transaction details
     * @return Transaction hash bytes.
     */
    function encodeRequest(ExecutionRequest calldata _request)
        public
        view
        requestTypeRegistered(_request.typeHash)
        returns (bytes memory)
    {
        //
        // EIP712 spec:
        //
        //   hashStruct(s : 𝕊) = keccak256(
        //     typeHash ‖
        //     encodeData(s)
        //   )
        //
        bytes memory encodedStructPrefix = abi.encodePacked(
            _request.typeHash,
            abi.encode(_request.from, _request.nonce)
        );
        bytes memory encodedStructSuffix = (_request.callData.length > 0)
            ? abi.encodePacked(
                keccak256(_request.callData),
                _request.suffixData
            )
            : abi.encodePacked(_request.suffixData);

        bytes32 txHash = keccak256(
            abi.encodePacked(encodedStructPrefix, encodedStructSuffix)
        );

        //
        // EIP712 spec:
        //
        //   encode(domainSeparator : 𝔹²⁵⁶, message : 𝕊) =
        //     "\x19\x01" ‖
        //     domainSeparator ‖
        //     hashStruct(message)
        //   )
        //
        return
            abi.encodePacked(
                bytes1(0x19),
                bytes1(0x01),
                domainSeparator,
                txHash
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title Replay protection for wallet meta transactions using a 2-dimensional nonce.
 *
 * @dev A 2-dimensional nonce enables more flexible submission of transactions
 * because they don't need to be processed in order. By using the "channel"
 * which is the first dimension of the nonce, senders can send multiple 
 * separate streams / channels of transactions independent of each other.
 *
 * This implementation is based on the one presented in EIP-2585 and implemented
 * at: https://github.com/wighawag/eip-2585
 */
interface IReplayProtection {
  /**
   * @dev Get next nonce given the signer address and channel (1st dimension of nonce)
   * @param _signer Signer of the meta-tx
   * @param _channel Channel of 2d nonce to look up next nonce
   * @return Next nonce
   */
  function getNonce(
    address _signer,
    uint128 _channel
  ) external view returns (uint128);

  /**
   * @dev Packs channel and nonce with in channel into a single uint256.
   *
   * Clients send the 2D nonce packed into a single uint256.
   *
   * This function is a helper to pack the nonce.
   *
   * It can also of course be done client side. For example with ethers.BigNumber:
   * 
   * ```
   *  nonce = ethers.BigNumber.from(channel).
   *            shl(128).
   *            add(ethers.BigNumber.from(nonce))
   * ```
   *
   * @param _channel Channel of 2D nonce
   * @param _nonce Nonce with in channel of 2D nonce
   * @return noncePacked Packed uint256 nonce
   */
  function packNonce(
    uint128 _channel,
    uint128 _nonce
  )
    external
    pure
    returns (uint256 noncePacked);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

import "./IReplayProtection.sol";

/**
 * @title Replay protection for wallet meta transactions using a 2-dimensional nonce.
 *
 * @dev A 2-dimensional nonce enables more flexible submission of transactions
 * because they don't need to be processed in order. By using a "channel"
 * which is the first dimension of the 2d nonce, senders can send multiple
 * separate streams / channels of transactions independent of each other.
 *
 * This implementation is based on the one presented in EIP-2585 and implemented
 * at: https://github.com/wighawag/eip-2585
 */
contract ReplayProtection is IReplayProtection {
  // Small gas saving by setting up this constant
  uint256 constant UINT_128_SHIFT = 2**128;
  
  /*
   * 2D nonce per wallet:
   *   wallet => 
   *     channel => nonce
   */
  mapping(address => mapping(uint128 => uint128)) nonces;

  /**
   * @dev Get next nonce given the wallet and channel.
   * 
   * The contract stores a 2D nonce per wallet:
   *   wallet => 
   *     channel => nonce
   *
   * Transaction sender should first choose the value of channel. In most
   * cases this can be 0. However if sending multiple streams of transactions
   * in parallel then another channel will be chosen for the additional
   * parallel streams of transactions.
   *
   * Nonce will simply be the next available nonce in the mapping from channel.

   * @param _wallet Wallet to look up nonce for
   * @param _channel Channel of 2d nonce to look up next nonce
   * @return Next nonce
   */
  function getNonce(
    address _wallet,
    uint128 _channel
  )
    external
    override
    view
    returns (uint128)
  {
    return nonces[_wallet][_channel];
  }

  /**
   * @dev Check provided nonce is correct for the given wallet.
   *
   * Channel and nonce are packed into a single uint256. Channel is packed
   * in the higher 128bits and the nonce with in the channel the lower 128bits.
   *
   * @param _wallet Wallet nonce is applicable to
   * @param _packedNonce Packed 2D nonce
   * @return success Success or failure
   */
  function checkAndUpdateNonce(
    address _wallet,
    uint256 _packedNonce
  )
    internal
    returns (bool)
  {
    uint128 channel = uint128(_packedNonce >> 128);
    uint128 nonce = uint128(_packedNonce % UINT_128_SHIFT);

    uint128 currentNonce = nonces[_wallet][channel];
    if (nonce == currentNonce) {
      nonces[_wallet][channel] = currentNonce + 1;
      return true;
    }

    return false;
  }

  /**
   * @dev Packs channel and nonce with in channel into a single uint256.
   *
   * Clients send the 2D nonce packed into a single uint256.
   *
   * This function is a helper to pack the nonce.
   *
   * It can also of course be done client side. For example with ethers.BigNumber:
   * 
   * ```
   *  nonce = ethers.BigNumber.from(channel).
   *            shl(128).
   *            add(ethers.BigNumber.from(nonce))
   * ```
   *
   * @param _channel Channel of 2D nonce
   * @param _nonce Nonce with in channel of 2D nonce
   * @return noncePacked Packed uint256 nonce
   */
  function packNonce(
    uint128 _channel,
    uint128 _nonce
  )
    external
    pure
    override
    returns (uint256 noncePacked)
  {
    noncePacked = (uint256(_channel) << 128) + _nonce;
  }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.13;

/**
 * @title TransactionExecutor - execute transaction for a wallet
 * @author Chris Hatch - <[email protected]>
 */
contract TransactionExecutor {
    event ExecutionSuccess(bytes32 txHash);

    string internal constant EXECUTE_FAILED_WITHOUT_REASON =
        "Proxied transaction failed without a reason string";

    /**
     * @dev Execute a call.
     * @param _to Call destination address
     * @param _data Call data to send
     * @param _txHash Hash of transaction request
     * @return True if call succeeded, false if failed
     */
    function executeCall(
        address _to,
        bytes memory _data,
        bytes32 _txHash
    ) internal returns (bool) {
        (bool success, ) = _to.call(_data);
        if (success) {
            emit ExecutionSuccess(_txHash);
            return success;
        }

        assembly {
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

contract Contracts {
    uint8 internal constant ADMINISTRATOR = 1;
    uint8 internal constant ADMIN_PROXY = 2;
    uint8 internal constant LICENSED_USER_MANAGER = 3;
    uint8 internal constant STARTRAIL_REGISTRY = 4;
    uint8 internal constant BULK_ISSUE = 5;
    uint8 internal constant META_TX_FORWARDER = 6;
    uint8 internal constant BULK_TRANSFER = 7;
    uint8 internal constant BULK = 8;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * Startrail contracts were deployed with an older version of
 * Initializable.sol from the package {at}openzeppelin/contracts-ethereum-package.
 * It was a version from the semver '^3.0.0'. 
 * 
 * That older version contained a storage gap however the new
 * {at}openzeppelin/contracts-upgradeable version does not.
 * 
 * This contract inserts the storage gap so that storage aligns in the
 * contracts that used that older version. 
 */
abstract contract InitializableWithGap is Initializable {
    uint256[50] private ______gap;   
}