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