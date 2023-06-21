// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IOperatorFilterRegistry} from "../../interfaces/IOperatorFilterRegistry.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

///@title OperatorFiltererUpgradeable
///@author The Sandbox
///@notice This contract would subscibe or copy or just to the subscription provided or just register to default subscription list
///@dev This contract is the upgradeable version of the OpenSea implementation https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/OperatorFilterer.sol and adapted to the 0.5.9 solidity version
abstract contract OperatorFiltererUpgradeable is ContextUpgradeable {
    IOperatorFilterRegistry public operatorFilterRegistry;

    event ContractRegistered(address indexed subscriptionOrRegistrant, bool subscribe);

    function __OperatorFilterer_init(address subscriptionOrRegistrantToCopy, bool subscribe) internal onlyInitializing {
        _register(subscriptionOrRegistrantToCopy, subscribe);
    }

    /**
     * @notice Register this contract into the registry
     * @param subscriptionOrRegistrantToCopy address to subscribe or copy entries from
     * @param subscribe should it subscribe
     */
    function _register(address subscriptionOrRegistrantToCopy, bool subscribe) internal {
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isRegistered(address(this))) {
                if (subscribe) {
                    operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    if (subscriptionOrRegistrantToCopy != address(0)) {
                        operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                    } else {
                        operatorFilterRegistry.register(address(this));
                    }
                }
            }
        }
        emit ContractRegistered(subscriptionOrRegistrantToCopy, subscribe);
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == _msgSender()) {
                _;
                return;
            }
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), _msgSender())) {
                revert("Operator Not Allowed");
            }
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (!operatorFilterRegistry.isOperatorAllowed(address(this), operator)) {
                revert("Operator Not Allowed");
            }
        }
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/**
 * @title IOperatorFilterRegistry
 * @author OpenSea
 * @notice Interface of the operator filter registry
 * @dev This interface comes from OpenSea https://github.com/ProjectOpenSea/operator-filter-registry/blob/main/src/IOperatorFilterRegistry.sol and adapted to the 0.5.9 solidity version
 */
interface IOperatorFilterRegistry {
    /**
     * @notice Check if the operator is allowed for the given registrant
     * @param registrant address of the registrant
     * @param operator operator address to check
     * @return is the operator allowed
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Register a new address
     * @param registrant address to register
     */
    function register(address registrant) external;

    /**
     * @notice Register a new address & subscribe to an address
     * @param registrant address of the registrant
     * @param subscription address where the registrant is subscribed to
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Register and copy entries of another registrant
     * @param registrant address of the registrant
     * @param registrantToCopy address to copy from
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice update the operator for a registrant
     * @param registrant address of the registrant
     * @param operator operator to be updated
     * @param filtered is it filtered
     */
    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external;

    /**
     * @notice Update operators for a registrant
     * @param registrant address of the registrant
     * @param operators addresses of the operators
     * @param filtered is it filtered
     */
    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external;

    /**
     * @notice Update code hash
     * @param registrant address of the registrant
     * @param codehash code hash
     * @param filtered is it filtered
     */
    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external;

    /**
     * @notice Update code hashes
     * @param registrant address of the registrant
     * @param codeHashes code hashes
     * @param filtered is it filtered
     */
    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external;

    /**
     * @notice Subscribe a registrant
     * @param registrant address of the registrant
     * @param registrantToSubscribe address to subscribe with
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe a registrant
     * @param registrant address of the registrant
     * @param copyExistingEntries copy existing entries
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription of an address
     * @param addr address to check
     * @return registrant the registrant address
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the subscribers of the registrant
     * @param registrant address of the registrant
     * @return the subscribers addresses
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get a specific subscriber
     * @param registrant address of the registrant
     * @param index index to check
     * @return the ith subscriber of the registrant
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy the entries of a registrant
     * @param registrant address of the registrant
     * @param registrantToCopy address to copy
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Is a registrant filtered
     * @param registrant address of the registrant
     * @param operator operator address to check
     * @return is it filtered
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Is the code hash of an operator filtered
     * @param registrant address of the registrant
     * @param operatorWithCode operator address to check
     * @return is it filtered
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Is the code hash filtered
     * @param registrant address of the registrant
     * @param codeHash code hash
     * @return is it filtered
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Get the filtered operators
     * @param addr address to check
     * @return filtered operators
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Get the filtered code hashes
     * @param addr address to check
     * @return filtered code hashes
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Get a specific operator
     * @param registrant address of the registrant
     * @param index index to check
     * @return address of the operator
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Get the ith filtered code hash
     * @param registrant address of the registrant
     * @param index index to check
     * @return the code hash
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Is the address registered
     * @param addr address to check
     * @return is it registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @notice Get the code hash for this address
     * @param addr address to check
     * @return the code hash
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title ERC2771Handler
 * @author The Sandbox
 * @notice Handle meta-transactions
 * @dev minimal ERC2771 handler to keep bytecode-size down
 * based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/metatx/ERC2771Context.sol
 * with an initializer for proxies and a mutable forwarder
 */
abstract contract ERC2771Handler {
    address internal _trustedForwarder;

    event TrustedForwarderSet(address indexed newForwarder);

    /**
     * @dev Initializes the contract
     * @param forwarder trusted forwarder address
     */
    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
        emit TrustedForwarderSet(_trustedForwarder);
    }

    /**
     * @notice Checks if an address is a trusted forwarder
     * @param forwarder address to check
     * @return is trusted
     */
    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * @notice Get the current trusted forwarder
     * @return trustedForwarder address of the trusted forwarder
     */
    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

    /**
     * @dev if the call comes from the trusted forwarder, it gets the real sender by checking the encoded address in the data
     * @return sender address of the real sender
     */
    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            // solhint-disable-next-line no-inline-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev if the call comes from the trusted forwarder, it substracts the sender address from `msg.data` to get the real `msg.data`
     * @return the real `msg.data`
     */
    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
/* solhint-disable func-order, code-complexity */
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {
    IERC721ReceiverUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {WithSuperOperatorsV2} from "./WithSuperOperatorsV2.sol";
import {IERC721MandatoryTokenReceiver} from "../interfaces/IERC721MandatoryTokenReceiver.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @title ERC721BaseTokenV2
/// @author The Sandbox
/// @notice Basic functionalities of a NFT
/// @dev ERC721 implementation that supports meta-transactions and super operators
contract ERC721BaseTokenV2 is ContextUpgradeable, IERC721Upgradeable, WithSuperOperatorsV2 {
    using AddressUpgradeable for address;

    bytes4 internal constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 internal constant _ERC721_BATCH_RECEIVED = 0x4b808c46;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC721_MANDATORY_RECEIVER = 0x5e8bf644;

    uint256 internal constant NOT_ADDRESS = 0xFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000000000000000000000000000;
    uint256 internal constant OPERATOR_FLAG = (2**255);
    uint256 internal constant NOT_OPERATOR_FLAG = OPERATOR_FLAG - 1;
    uint256 internal constant BURNED_FLAG = (2**160);

    mapping(address => uint256) internal _numNFTPerAddress;
    /**
     * @dev mapping to store owner of lands and quads.
     * For 1x1 lands it also the 255 bit is 1 if that land has operator approved and is 0 if no operator is approved.
     * For burned 1x1 Land 160 bit is set to 1.
     */
    mapping(uint256 => uint256) internal _owners;
    mapping(address => mapping(address => bool)) internal _operatorsForAll;
    mapping(uint256 => address) internal _operators;

    /// @notice Approve an operator to spend tokens on the senders behalf.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approve(address operator, uint256 id) public virtual override {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = _ownerOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            owner == msgSender || _operatorsForAll[owner][msgSender] || _superOperators[msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        _approveFor(ownerData, operator, id);
    }

    /// @notice Approve an operator to spend tokens on the sender behalf.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param id The id of the token.
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) public virtual {
        uint256 ownerData = _owners[_storageId(id)];
        address owner = _ownerOf(id);
        address msgSender = _msgSender();
        require(sender != address(0), "ZERO_ADDRESS_SENDER");
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(
            msgSender == sender || _operatorsForAll[sender][msgSender] || _superOperators[msgSender],
            "UNAUTHORIZED_APPROVAL"
        );
        require(address(uint160(ownerData)) == sender, "OWNER_NOT_SENDER");
        _approveFor(ownerData, operator, id);
    }

    /// @notice Transfer a token between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, ""), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfer a token between 2 addresses letting the receiver know of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        safeTransferFrom(from, to, id, "");
    }

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) public virtual {
        _batchTransferFrom(from, to, ids, data, false);
    }

    /// @notice Transfer many tokens between 2 addresses, while
    /// ensuring the receiving contract has a receiver method.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external virtual {
        _batchTransferFrom(from, to, ids, data, true);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param sender The address giving the approval.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) public virtual {
        require(sender != address(0), "Invalid sender address");
        address msgSender = _msgSender();
        require(msgSender == sender || _superOperators[msgSender], "UNAUTHORIZED_APPROVE_FOR_ALL");

        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Set the approval for an operator to manage all the tokens of the sender.
    /// @param operator The address receiving the approval.
    /// @param approved The determination of the approval.
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Burns token `id`.
    /// @param id The token which will be burnt.
    function burn(uint256 id) external virtual {
        _burn(_msgSender(), _ownerOf(id), id);
    }

    /// @notice Burn token `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id The token which will be burnt.
    function burnFrom(address from, uint256 id) external virtual {
        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(
            msgSender == from ||
                (operatorEnabled && _operators[id] == msgSender) ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender],
            "UNAUTHORIZED_BURN"
        );
        _burn(from, owner, id);
    }

    /// @notice Get the number of tokens owned by an address.
    /// @param owner The address to look for.
    /// @return The number of tokens owned by the address.
    function balanceOf(address owner) external view override returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS_OWNER");
        return _numNFTPerAddress[owner];
    }

    /// @notice Get the owner of a token.
    /// @param id The id of the token.
    /// @return owner The address of the token owner.
    function ownerOf(uint256 id) external view override returns (address owner) {
        owner = _ownerOf(id);
        require(owner != address(0), "NONEXISTANT_TOKEN");
    }

    /// @notice Get the approved operator for a specific token.
    /// @param id The id of the token.
    /// @return The address of the operator.
    function getApproved(uint256 id) external view override returns (address) {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        require(owner != address(0), "NONEXISTENT_TOKEN");
        if (operatorEnabled) {
            return _operators[id];
        } else {
            return address(0);
        }
    }

    /// @notice Check if the sender approved the operator.
    /// @param owner The address of the owner.
    /// @param operator The address of the operator.
    /// @return isOperator The status of the approval.
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Transfer a token between 2 addresses letting the receiver knows of the transfer.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param id The id of the token.
    /// @param data Additional data.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual override {
        _checkTransfer(from, to, id);
        _transferFrom(from, to, id);
        if (to.isContract()) {
            require(_checkOnERC721Received(_msgSender(), from, to, id, data), "ERC721_TRANSFER_REJECTED");
        }
    }

    /// @notice Check if the contract supports an interface.
    /// 0x01ffc9a7 is ERC-165.
    /// 0x80ac58cd is ERC-721
    /// @param id The id of the interface.
    /// @return Whether the interface is supported.
    function supportsInterface(bytes4 id) public pure virtual override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd;
    }

    /// @dev By overriding this function in an implementation which inherits this contract,
    /// you can enable versioned tokenIds without the extra overhead of writing to a new storage slot in _owners each time a version is incremented.
    /// See GameToken._storageId() for an example, where the storageId is the tokenId minus the version number.
    /// !!! Caution !!! Overriding this function without taking appropriate care could lead to
    /// ownerOf() returning an owner for non-existent tokens. Tests should be written to
    /// guard against introducing this bug.
    /// @param id The id of a token.
    /// @return The id used for storage mappings.
    function _storageId(uint256 id) internal view virtual returns (uint256) {
        return id;
    }

    function _updateOwnerData(
        uint256 id,
        uint256 oldData,
        address newOwner,
        bool hasOperator
    ) internal virtual {
        if (hasOperator) {
            _owners[_storageId(id)] = (oldData & NOT_ADDRESS) | OPERATOR_FLAG | uint256(uint160(newOwner));
        } else {
            _owners[_storageId(id)] = ((oldData & NOT_ADDRESS) & NOT_OPERATOR_FLAG) | uint256(uint160(newOwner));
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id
    ) internal {
        _numNFTPerAddress[from]--;
        _numNFTPerAddress[to]++;
        _updateOwnerData(id, _owners[_storageId(id)], to, false);
        emit Transfer(from, to, id);
    }

    /// @dev See approveFor.
    function _approveFor(
        uint256 ownerData,
        address operator,
        uint256 id
    ) internal {
        address owner = _ownerOf(id);
        if (operator == address(0)) {
            _updateOwnerData(id, ownerData, owner, false);
        } else {
            _updateOwnerData(id, ownerData, owner, true);
            _operators[id] = operator;
        }
        emit Approval(owner, operator, id);
    }

    /// @dev See batchTransferFrom.
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        bytes memory data,
        bool safe
    ) internal {
        address msgSender = _msgSender();
        bool authorized = msgSender == from || _operatorsForAll[from][msgSender] || _superOperators[msgSender];

        require(from != address(0), "NOT_FROM_ZEROADDRESS");
        require(to != address(0), "NOT_TO_ZEROADDRESS");

        uint256 numTokens = ids.length;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 id = ids[i];
            (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
            require(owner == from, "BATCHTRANSFERFROM_NOT_OWNER");
            require(authorized || (operatorEnabled && _operators[id] == msgSender), "NOT_AUTHORIZED");
            _updateOwnerData(id, _owners[_storageId(id)], to, false);
            emit Transfer(from, to, id);
        }
        if (from != to) {
            _numNFTPerAddress[from] -= numTokens;
            _numNFTPerAddress[to] += numTokens;
        }

        if (to.isContract()) {
            if (_checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
                require(_checkOnERC721BatchReceived(msgSender, from, to, ids, data), "ERC721_BATCH_RECEIVED_REJECTED");
            } else if (safe) {
                for (uint256 i = 0; i < numTokens; i++) {
                    require(_checkOnERC721Received(msgSender, from, to, ids[i], data), "ERC721_RECEIVED_REJECTED");
                }
            }
        }
    }

    /// @dev See setApprovalForAll.
    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(!_superOperators[operator], "INVALID_APPROVAL_CHANGE");
        _operatorsForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    /// @dev See burn.
    function _burn(
        address from,
        address owner,
        uint256 id
    ) internal {
        require(from == owner, "NOT_OWNER");
        uint256 storageId = _storageId(id);
        _owners[storageId] = (_owners[storageId] & NOT_OPERATOR_FLAG) | BURNED_FLAG; // record as non owner but keep track of last owner
        _numNFTPerAddress[from]--;
        emit Transfer(from, address(0), id);
    }

    /// @dev Check if receiving contract accepts erc721 transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The address we want to transfer to.
    /// @param tokenId The id of the token we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x150b7a02 is returned.
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721ReceiverUpgradeable(to).onERC721Received(operator, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

    /// @dev Check if receiving contract accepts erc721 batch transfers.
    /// @param operator The address of the operator.
    /// @param from The from address, may be different from msg.sender.
    /// @param to The address we want to transfer to.
    /// @param ids The ids of the tokens we would like to transfer.
    /// @param _data Any additional data to send with the transfer.
    /// @return Whether the expected value of 0x4b808c46 is returned.
    function _checkOnERC721BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        bytes memory _data
    ) internal returns (bool) {
        bytes4 retval = IERC721MandatoryTokenReceiver(to).onERC721BatchReceived(operator, from, ids, _data);
        return (retval == _ERC721_BATCH_RECEIVED);
    }

    /// @dev See ownerOf
    function _ownerOf(uint256 id) internal view virtual returns (address) {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            return address(0);
        }
        return address(uint160(data));
    }

    /// @dev Get the owner and operatorEnabled status of a token.
    /// @param id The token to query.
    /// @return owner The owner of the token.
    /// @return operatorEnabled Whether or not operators are enabled for this token.
    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        virtual
        returns (address owner, bool operatorEnabled)
    {
        uint256 data = _owners[_storageId(id)];
        if ((data & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
        } else {
            owner = address(uint160(data));
        }
        operatorEnabled = (data & OPERATOR_FLAG) == OPERATOR_FLAG;
    }

    /// @dev Check whether a transfer is a meta Transaction or not.
    /// @param from The address who initiated the transfer (may differ from msg.sender).
    /// @param to The address receiving the token.
    /// @param id The token being transferred.
    function _checkTransfer(
        address from,
        address to,
        uint256 id
    ) internal view {
        (address owner, bool operatorEnabled) = _ownerAndOperatorEnabledOf(id);
        address msgSender = _msgSender();
        require(owner != address(0), "NONEXISTENT_TOKEN");
        require(owner == from, "CHECKTRANSFER_NOT_OWNER");
        require(to != address(0), "NOT_TO_ZEROADDRESS");
        require(
            msgSender == owner ||
                _superOperators[msgSender] ||
                _operatorsForAll[from][msgSender] ||
                (operatorEnabled && _operators[id] == msgSender),
            "UNAUTHORIZED_TRANSFER"
        );
    }

    /// @dev Check if there was enough gas.
    /// @param _contract The address of the contract to check.
    /// @param interfaceId The id of the interface we want to test.
    /// @return Whether or not this check succeeded.
    function _checkInterfaceWith10000Gas(address _contract, bytes4 interfaceId) internal view returns (bool) {
        bool success;
        bool result;
        bytes memory callData = abi.encodeWithSelector(ERC165ID, interfaceId);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let call_ptr := add(0x20, callData)
            let call_size := mload(callData)
            let output := mload(0x40) // Find empty storage location using "free memory pointer"
            mstore(output, 0x0)
            success := staticcall(10000, _contract, call_ptr, call_size, output, 0x20) // 32 bytes
            result := mload(output)
        }
        // (10000 / 63) "not enough for supportsInterface(...)" // consume all gas, so caller can potentially know that there was not enough gas
        assert(gasleft() > 158);
        return success && result;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @title WithAdminV2
/// @author The Sandbox
/// @notice Add an admin to the contract
contract WithAdminV2 is ContextUpgradeable {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(_msgSender() == _admin, "ADMIN_ONLY");
        _;
    }

    /// @notice Get the current admin
    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @notice Change the admin of the contract
    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        address admin = _admin;
        require(_msgSender() == admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import {WithAdminV2} from "./WithAdminV2.sol";
import {ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/// @title WithSuperOperatorsV2
/// @author The Sandbox
/// @notice Add super operators handled by an admin
contract WithSuperOperatorsV2 is ContextUpgradeable, WithAdminV2 {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address indexed superOperator, bool indexed enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external onlyAdmin {
        require(_msgSender() == _admin, "only admin is allowed to add super operators");
        _superOperators[superOperator] = enabled;
        emit SuperOperator(superOperator, enabled);
    }

    /// @notice check whether address `who` is given superOperator rights.
    /// @param who The address to query.
    /// @return whether the address has superOperator rights.
    function isSuperOperator(address who) public view returns (bool) {
        return _superOperators[who];
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/**
 * @title IERC721MandatoryTokenReceiver
 * @author The Sandbox
 * @notice Interface for any contract that wants to support safeBatchTransfers
 * from ERC721 asset contracts.
 * @dev The ERC-165 identifier for this interface is 0x5e8bf644.
 */
interface IERC721MandatoryTokenReceiver {
    /**
     * @notice Whenever tokens are transferred to this contract via {IERC721-safeBatchTransferFrom}
     * by `operator` from `from`, this function is called.
     * @param operator sender
     * @param from owner of the tokens
     * @param ids token ids
     * @param data extra data
     * @return 0x4b808c46 if the transfer is a success
     */
    function onERC721BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x4b808c46

    /**
     * @notice Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     * @param operator sender
     * @param from owner of the token
     * @param tokenId token id
     * @param data extra data
     * @return 0x4b808c46 if the transfer is a success
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4); // needs to return 0x150b7a02
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title ILandToken
/// @author The Sandbox
/// @notice Interface of the LAND token including quad methods
interface ILandToken {
    /// @notice transfer multiple quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param sizes list of sizes for each quad
    /// @param xs list of bottom left x coordinates for each quad
    /// @param ys list of bottom left y coordinates for each quad
    /// @param data additional data
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external;

    /// @notice transfer one quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param size size of the quad
    /// @param x The top left x coordinate of the quad
    /// @param y The top left y coordinate of the quad
    /// @param data additional data
    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external;

    /// @notice Transfer many tokens between 2 addresses.
    /// @param from The sender of the token.
    /// @param to The recipient of the token.
    /// @param ids The ids of the tokens.
    /// @param data Additional data.
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {ILandToken} from "./ILandToken.sol";

/**
 * @title IPolygonLand
 * @author The Sandbox
 * @notice Interface of the LAND token on the child chain
 */
interface IPolygonLand is ILandToken {
    /**
     * @notice Mint a new quad (aligned to a quad tree with size 1, 3, 6, 12 or 24 only)
     * @param to The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external;

    /**
     * @notice Checks if a LAND exists by its coordinates
     * @param size size of the quad
     * @param x x coordinate
     * @param y y coordinate
     * @return does the LAND exist
     */
    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// solhint-disable code-complexity

pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../../../common/BaseWithStorage/ERC721BaseTokenV2.sol";
import "../../../common/interfaces/IPolygonLand.sol";

/**
 * @title PolygonLandBaseTokenV2
 * @author The Sandbox
 * @notice Implement LAND and quad functionalities on top of an ERC721 token
 * @dev This contract implements a quad tree structure to handle groups of ERC721 tokens at once
 */
abstract contract PolygonLandBaseTokenV2 is IPolygonLand, Initializable, ERC721BaseTokenV2 {
    using AddressUpgradeable for address;

    uint256 internal constant GRID_SIZE = 408;

    uint256 internal constant LAYER = 0xFF00000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_1x1 = 0x0000000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_3x3 = 0x0100000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_6x6 = 0x0200000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_12x12 = 0x0300000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant LAYER_24x24 = 0x0400000000000000000000000000000000000000000000000000000000000000;

    mapping(address => bool) internal _minters;

    event Minter(address minter, bool enabled);

    struct Land {
        uint256 x;
        uint256 y;
        uint256 size;
    }

    /// @notice transfer multiple quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param sizes list of sizes for each quad
    /// @param xs list of bottom left x coordinates for each quad
    /// @param ys list of bottom left y coordinates for each quad
    /// @param data additional data
    function batchTransferQuad(
        address from,
        address to,
        uint256[] calldata sizes,
        uint256[] calldata xs,
        uint256[] calldata ys,
        bytes calldata data
    ) external override {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        require(sizes.length == xs.length, "PolygonLandBaseTokenV2: sizes's and x's length are different");
        require(xs.length == ys.length, "PolygonLandBaseTokenV2: x's and y's length are different");
        if (_msgSender() != from) {
            require(
                _operatorsForAll[from][_msgSender()] || _superOperators[_msgSender()],
                "not authorized to transferMultiQuads"
            );
        }
        uint256 numTokensTransfered = 0;
        for (uint256 i = 0; i < sizes.length; i++) {
            uint256 size = sizes[i];
            _transferQuad(from, to, size, xs[i], ys[i]);
            numTokensTransfered += size * size;
        }
        _numNFTPerAddress[from] -= numTokensTransfered;
        _numNFTPerAddress[to] += numTokensTransfered;

        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](numTokensTransfered);
            uint256 counter = 0;
            for (uint256 j = 0; j < sizes.length; j++) {
                uint256 size = sizes[j];
                for (uint256 i = 0; i < size * size; i++) {
                    ids[counter] = _idInPath(i, size, xs[j], ys[j]);
                    counter++;
                }
            }
            require(
                _checkOnERC721BatchReceived(_msgSender(), from, to, ids, data),
                "erc721 batch transfer rejected by to"
            );
        }
    }

    /// @notice Enable or disable the ability of `minter` to transfer tokens of all (minter rights).
    /// @param minter address that will be given/removed minter right.
    /// @param enabled set whether the minter is enabled or disabled.
    function setMinter(address minter, bool enabled) external onlyAdmin {
        require(minter != address(0), "PolygonLand: Invalid address");
        _minters[minter] = enabled;
        emit Minter(minter, enabled);
    }

    /// @notice transfer one quad (aligned to a quad tree with size 3, 6, 12 or 24 only)
    /// @param from current owner of the quad
    /// @param to destination
    /// @param size size of the quad
    /// @param x The top left x coordinate of the quad
    /// @param y The top left y coordinate of the quad
    /// @param data additional data for transfer
    function transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external override {
        require(from != address(0), "from is zero address");
        require(to != address(0), "can't send to zero address");
        if (_msgSender() != from) {
            require(
                _operatorsForAll[from][_msgSender()] || _superOperators[_msgSender()],
                "not authorized to transferQuad"
            );
        }
        _transferQuad(from, to, size, x, y);
        _numNFTPerAddress[from] -= size * size;
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(_msgSender(), from, to, size, x, y, data);
    }

    /**
     * @notice Mint a new quad (aligned to a quad tree with size 1, 3, 6, 12 or 24 only)
     * @param user The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function mintQuad(
        address user,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) external virtual override {
        _isValidQuad(size, x, y);
        require(isMinter(_msgSender()), "!AUTHORIZED");
        _mintQuad(user, size, x, y, data);
    }

    /**
     * @notice Checks if a parent quad has child quads already minted.
     *  Then mints the rest child quads and transfers the parent quad.
     *  Should only be called by the tunnel.
     * @param to The recipient of the new quad
     * @param size The size of the new quad
     * @param x The top left x coordinate of the new quad
     * @param y The top left y coordinate of the new quad
     * @param data extra data to pass to the transfer
     */
    function mintAndTransferQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes calldata data
    ) external virtual {
        require(isMinter(msg.sender), "!AUTHORIZED");
        require(to != address(0), "to is zero address");

        if (exists(size, x, y)) {
            _transferQuad(msg.sender, to, size, x, y);
            _numNFTPerAddress[msg.sender] -= size * size;
            _numNFTPerAddress[to] += size * size;
            _checkBatchReceiverAcceptQuad(msg.sender, msg.sender, to, size, x, y, data);
        } else {
            _mintAndTransferQuad(to, size, x, y, data);
        }
    }

    /// @notice x coordinate of Land token
    /// @param id tokenId
    /// @return the x coordinates
    function getX(uint256 id) external pure returns (uint256) {
        return _getX(id);
    }

    /// @inheritdoc ERC721BaseTokenV2
    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) public virtual override(ILandToken, ERC721BaseTokenV2) {
        super.batchTransferFrom(from, to, ids, data);
    }

    /// @notice y coordinate of Land token
    /// @param id tokenId
    /// @return the y coordinates
    function getY(uint256 id) external pure returns (uint256) {
        return _getY(id);
    }

    /**
     * @notice Check if the contract supports an interface
     * 0x01ffc9a7 is ERC-165
     * 0x80ac58cd is ERC-721
     * 0x5b5e139f is ERC-721 metadata
     * @param id The id of the interface
     * @return True if the interface is supported
     */
    function supportsInterface(bytes4 id) public pure override returns (bool) {
        return id == 0x01ffc9a7 || id == 0x80ac58cd || id == 0x5b5e139f;
    }

    /**
     * @notice Return the name of the token contract
     * @return The name of the token contract
     */
    function name() public pure returns (string memory) {
        return "Sandbox's LANDs";
    }

    /// @notice check whether address `who` is given minter rights.
    /// @param who The address to query.
    /// @return whether the address has minter rights.
    function isMinter(address who) public view returns (bool) {
        return _minters[who];
    }

    /// @notice checks if Land has been minted or not
    /// @param size size of the
    /// @param x x coordinate of the quad
    /// @param y y coordinate of the quad
    /// @return bool for if Land has been minted or not
    function exists(
        uint256 size,
        uint256 x,
        uint256 y
    ) public view override returns (bool) {
        _isValidQuad(size, x, y);
        return _ownerOfQuad(size, x, y) != address(0);
    }

    /**
     * @notice Return the symbol of the token contract
     * @return The symbol of the token contract
     */
    function symbol() public pure returns (string memory) {
        return "LAND";
    }

    /// @notice total width of the map
    /// @return width
    function width() public pure returns (uint256) {
        return GRID_SIZE;
    }

    /// @notice total height of the map
    /// @return height
    function height() public pure returns (uint256) {
        return GRID_SIZE;
    }

    /**
     * @notice Return the URI of a specific token
     * @param id The id of the token
     * @return The URI of the token
     */
    function tokenURI(uint256 id) public view returns (string memory) {
        require(_ownerOf(id) != address(0), "Id does not exist");
        return
            string(
                abi.encodePacked("https://api.sandbox.game/lands/", StringsUpgradeable.toString(id), "/metadata.json")
            );
    }

    function _isValidQuad(
        uint256 size,
        uint256 x,
        uint256 y
    ) internal pure {
        require(size == 1 || size == 3 || size == 6 || size == 12 || size == 24, "Invalid size");
        require(x % size == 0, "Invalid x coordinate");
        require(y % size == 0, "Invalid y coordinate");
        require(x <= GRID_SIZE - size, "x out of bounds");
        require(y <= GRID_SIZE - size, "y out of bounds");
    }

    function _transferQuad(
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal {
        _isValidQuad(size, x, y);
        if (size == 1) {
            uint256 id1x1 = _getQuadId(LAYER_1x1, x, y);
            address owner = _ownerOf(id1x1);
            require(owner != address(0), "token does not exist");
            require(owner == from, "not owner in _transferQuad");
            _owners[id1x1] = uint256(uint160(address(to)));
        } else {
            _regroupQuad(from, to, Land({x: x, y: y, size: size}), true, size / 2);
        }
        for (uint256 i = 0; i < size * size; i++) {
            emit Transfer(from, to, _idInPath(i, size, x, y));
        }
    }

    function _mintQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        require(to != address(0), "to is zero address");

        (uint256 layer, , ) = _getQuadLayer(size);
        uint256 quadId = _getQuadId(layer, x, y);

        _checkOwner(size, x, y, 24);
        for (uint256 i = 0; i < size * size; i++) {
            uint256 _id = _idInPath(i, size, x, y);
            require(_owners[_id] == 0, "Already minted");
            emit Transfer(address(0), to, _id);
        }

        _owners[quadId] = uint256(uint160(to));
        _numNFTPerAddress[to] += size * size;

        _checkBatchReceiverAcceptQuad(msg.sender, address(0), to, size, x, y, data);
    }

    /**
     * @dev checks if the child quads in the parent quad (size, x, y) are owned by msg.sender.
     * It recursively checks child quad of every size(exculding Lands of 1x1 size) are minted or not.
     * Quad which are minted are pushed into quadMinted to also check if every Land of size 1x1 in
     * the parent quad is minted or not. While checking if the every child Quad and Land is minted it
     * also checks and clear the owner for quads which are minted. Finally it checks if the new owner
     * if is a contract can handle ERC721 tokens or not and transfers the parent quad to new owner.
     * @param to The address to which the ownership of the quad will be transferred
     * @param size The size of the quad being minted and transfered
     * @param x The x-coordinate of the top-left corner of the quad being minted.
     * @param y The y-coordinate of the top-left corner of the quad being minted.
     * @param y The y-coordinate of the top-left corner of the quad being minted.
     */
    function _mintAndTransferQuad(
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        (uint256 layer, , ) = _getQuadLayer(size);
        uint256 quadId = _getQuadId(layer, x, y);

        // Length of array is equal to number of 3x3 child quad a 24x24 quad can have. Would be used to push the minted Quads.
        Land[] memory quadMinted = new Land[](64);
        // index of last minted quad pushed on quadMinted Array
        uint256 index;
        uint256 landMinted;

        // if size of the Quad in land struct to be transfered is greater than 3 we check recursivly if the child quads are minted or not.
        if (size > 3) {
            (index, landMinted) = _checkAndClearOwner(
                Land({x: x, y: y, size: size}),
                quadMinted,
                landMinted,
                index,
                size / 2
            );
        }

        // Lopping around the Quad in land struct to generate ids of 1x1 land token and checking if they are owned by msg.sender
        {
            for (uint256 i = 0; i < size * size; i++) {
                uint256 _id = _idInPath(i, size, x, y);
                // checking land with token id "_id" is in the quadMinted array.
                bool isAlreadyMinted = _isQuadMinted(quadMinted, Land({x: _getX(_id), y: _getY(_id), size: 1}), index);
                if (isAlreadyMinted) {
                    // if land is in the quadMinted array there just emitting transfer event
                    emit Transfer(msg.sender, to, _id);
                } else {
                    if (address(uint160(_owners[_id])) == msg.sender) {
                        if (_operators[_id] != address(0)) _operators[_id] = address(0);
                        landMinted += 1;
                        emit Transfer(msg.sender, to, _id);
                    } else {
                        // else is checked if owned by the msg.sender or not. If it is not owned by msg.sender it should not have an owner.
                        require(_owners[_id] == 0, "Already minted");

                        emit Transfer(address(0), to, _id);
                    }
                }
            }
        }

        // checking if the new owner "to" is a contract. If yes, checking if it could handle ERC721 tokens.
        _checkBatchReceiverAcceptQuadAndClearOwner(quadMinted, index, landMinted, to, size, x, y, data);

        _owners[quadId] = uint256(uint160(to));
        _numNFTPerAddress[to] += size * size;
        _numNFTPerAddress[msg.sender] -= landMinted;
    }

    /**
     * @dev recursivly checks if the child quads are minted in land and push them to the quadMinted array.
     * if a child quad is minted in land such quads child quads will be skipped such that there is no overlapping
     * in quads which are minted. it clears the minted child quads owners.
     * @param land the stuct which has the size x and y co-ordinate of Quad to be checked
     * @param quadMinted array in which the minted child quad would be pushed
     * @param landMinted total 1x1 land already minted
     * @param index index of last element of quadMinted array
     * @param quadCompareSize the size of the child quads to be checked.
     * @return the index of last quad pushed in quadMinted array and the total land already minted
     */
    function _checkAndClearOwner(
        Land memory land,
        Land[] memory quadMinted,
        uint256 landMinted,
        uint256 index,
        uint256 quadCompareSize
    ) internal returns (uint256, uint256) {
        (uint256 layer, , ) = _getQuadLayer(quadCompareSize);
        uint256 toX = land.x + land.size;
        uint256 toY = land.y + land.size;

        //Lopping around the Quad in land struct to check if the child quad are minted or not
        for (uint256 xi = land.x; xi < toX; xi += quadCompareSize) {
            for (uint256 yi = land.y; yi < toY; yi += quadCompareSize) {
                //checking if the child Quad is minted or not. i.e Checks if the quad is in the quadMinted array.
                bool isQuadChecked = _isQuadMinted(quadMinted, Land({x: xi, y: yi, size: quadCompareSize}), index);
                // if child quad is not already in the quadMinted array.
                if (!isQuadChecked) {
                    uint256 id = _getQuadId(layer, xi, yi);
                    address owner = address(uint160(_owners[id]));
                    // owner of the child quad is checked to be owned by msg.sender else should not be owned by anyone.
                    if (owner == msg.sender) {
                        // if child quad is minted it would be pushed in quadMinted array.
                        quadMinted[index] = Land({x: xi, y: yi, size: quadCompareSize});
                        // index of quadMinted is increased
                        index++;
                        // total land minted is increase by the number if land of 1x1 in child quad
                        landMinted += quadCompareSize * quadCompareSize;
                        //owner is cleared
                        _owners[id] = 0;
                    } else {
                        require(owner == address(0), "Already minted");
                    }
                }
            }
        }

        // size of the child quad is set to be the next smaller child quad size (12 => 6 => 3)
        quadCompareSize = quadCompareSize / 2;
        // if child quad size is greater than 3 _checkAndClearOwner is checked for new child quads in the  quad in land struct.
        if (quadCompareSize >= 3)
            (index, landMinted) = _checkAndClearOwner(land, quadMinted, landMinted, index, quadCompareSize);
        return (index, landMinted);
    }

    /// @dev checks the owner of land with 'tokenId' to be 'from' and clears it
    /// @param from the address to be checked agains the owner of the land
    /// @param tokenId th id of land
    /// @return bool for if land is owned by 'from' or not.
    function _checkAndClearLandOwner(address from, uint256 tokenId) internal returns (bool) {
        uint256 currentOwner = _owners[tokenId];
        if (currentOwner != 0) {
            require((currentOwner & BURNED_FLAG) != BURNED_FLAG, "not owner");
            require(address(uint160(currentOwner)) == from, "not owner");
            _owners[tokenId] = 0;
            return true;
        }
        return false;
    }

    function _checkBatchReceiverAcceptQuad(
        address operator,
        address from,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            uint256[] memory ids = new uint256[](size * size);
            for (uint256 i = 0; i < size * size; i++) {
                ids[i] = _idInPath(i, size, x, y);
            }
            require(_checkOnERC721BatchReceived(operator, from, to, ids, data), "erc721 batch transfer rejected by to");
        }
    }

    /// @dev checks if the receiver of the quad(size, x, y) is a contact. If yes can it handle ERC721 tokens. It also clears owner of 1x1 land's owned by msg.sender.
    /// @param quadMinted - an array of Land structs in which the minted child quad or Quad to be transfered are.
    /// @param landMinted - the total amount of land that has been minted
    /// @param index - the index of the last element in the quadMinted array
    /// @param to the address of the new owner of Quad to be transfered
    /// @param size The size of the quad being minted and transfered
    /// @param x The x-coordinate of the top-left corner of the quad being minted.
    /// @param y The y-coordinate of the top-left corner of the quad being minted.
    /// @param y The y-coordinate of the top-left corner of the quad being minted.
    function _checkBatchReceiverAcceptQuadAndClearOwner(
        Land[] memory quadMinted,
        uint256 index,
        uint256 landMinted,
        address to,
        uint256 size,
        uint256 x,
        uint256 y,
        bytes memory data
    ) internal {
        // checks if to is a contract and supports ERC721_MANDATORY_RECEIVER interfaces. if it doesn't it just clears the owner of 1x1 lands in quad(size, x, y)
        if (to.isContract() && _checkInterfaceWith10000Gas(to, ERC721_MANDATORY_RECEIVER)) {
            // array to push minted 1x1 land
            uint256[] memory idsToTransfer = new uint256[](landMinted);
            // index of last land pushed in idsToTransfer array
            uint256 transferIndex;
            // array to push ids to be minted
            uint256[] memory idsToMint = new uint256[]((size * size) - landMinted);
            // index of last land pushed in idsToMint array
            uint256 mintIndex;

            // iterating over every 1x1 land in the quad to be pushed in the above arrays
            for (uint256 i = 0; i < size * size; i++) {
                uint256 id = _idInPath(i, size, x, y);

                if (_isQuadMinted(quadMinted, Land({x: _getX(id), y: _getY(id), size: 1}), index)) {
                    // if land is in the quads already minted it just pushed in to the idsToTransfer array
                    idsToTransfer[transferIndex] = id;
                    transferIndex++;
                } else if (address(uint160(_owners[id])) == msg.sender) {
                    // if it is owned by the msg.sender owner data is removed and it is pused in to idsToTransfer array
                    _owners[id] = 0;
                    idsToTransfer[transferIndex] = id;
                    transferIndex++;
                } else {
                    // else it is not owned by any one and and pushed in teh idsToMint array
                    idsToMint[mintIndex] = id;
                    mintIndex++;
                }
            }

            // checking if "to" contact can handle ERC721 tokens
            require(
                _checkOnERC721BatchReceived(msg.sender, address(0), to, idsToMint, data),
                "erc721 batch transfer rejected by to"
            );
            require(
                _checkOnERC721BatchReceived(msg.sender, msg.sender, to, idsToTransfer, data),
                "erc721 batch transfer rejected by to"
            );
        } else {
            for (uint256 i = 0; i < size * size; i++) {
                uint256 id = _idInPath(i, size, x, y);
                if (address(uint160(_owners[id])) == msg.sender) _owners[id] = 0;
            }
        }
    }

    function _getX(uint256 id) internal pure returns (uint256) {
        return (id & ~LAYER) % GRID_SIZE;
    }

    function _getY(uint256 id) internal pure returns (uint256) {
        return (id & ~LAYER) / GRID_SIZE;
    }

    function _isQuadMinted(
        Land[] memory mintedLand,
        Land memory quad,
        uint256 index
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < index; i++) {
            Land memory land = mintedLand[i];
            if (
                land.size > quad.size &&
                quad.x >= land.x &&
                quad.x < land.x + land.size &&
                quad.y >= land.y &&
                quad.y < land.y + land.size
            ) {
                return true;
            }
        }
        return false;
    }

    function _getQuadLayer(uint256 size)
        internal
        pure
        returns (
            uint256 layer,
            uint256 parentSize,
            uint256 childLayer
        )
    {
        if (size == 1) {
            layer = LAYER_1x1;
            parentSize = 3;
        } else if (size == 3) {
            layer = LAYER_3x3;
            parentSize = 6;
        } else if (size == 6) {
            layer = LAYER_6x6;
            parentSize = 12;
            childLayer = LAYER_3x3;
        } else if (size == 12) {
            layer = LAYER_12x12;
            parentSize = 24;
            childLayer = LAYER_6x6;
        } else if (size == 24) {
            layer = LAYER_24x24;
            childLayer = LAYER_12x12;
        } else {
            require(false, "Invalid size");
        }
    }

    function _getQuadId(
        uint256 layer,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        return layer + x + y * GRID_SIZE;
    }

    function _checkOwner(
        uint256 size,
        uint256 x,
        uint256 y,
        uint256 quadCompareSize
    ) internal view {
        (uint256 layer, , ) = _getQuadLayer(quadCompareSize);

        if (size <= quadCompareSize) {
            // when the size of the quad is smaller than the quadCompareSize(size to be compared with),
            // then it is checked if the bigger quad which encapsulates the quad to be minted
            // of with size equals the quadCompareSize has been minted or not
            require(
                _owners[
                    _getQuadId(layer, (x / quadCompareSize) * quadCompareSize, (y / quadCompareSize) * quadCompareSize)
                ] == 0,
                "Already minted"
            );
        } else {
            // when the size is smaller than the quadCompare size the owner of all the smaller quads with size
            // quadCompare size in the quad to be minted are checked if they are minted or not
            uint256 toX = x + size;
            uint256 toY = y + size;
            for (uint256 xi = x; xi < toX; xi += quadCompareSize) {
                for (uint256 yi = y; yi < toY; yi += quadCompareSize) {
                    require(_owners[_getQuadId(layer, xi, yi)] == 0, "Already minted");
                }
            }
        }

        quadCompareSize = quadCompareSize / 2;
        if (quadCompareSize >= 3) _checkOwner(size, x, y, quadCompareSize);
    }

    function _idInPath(
        uint256 i,
        uint256 size,
        uint256 x,
        uint256 y
    ) internal pure returns (uint256) {
        uint256 row = i / size;
        if (row % 2 == 0) {
            // allow ids to follow a path in a quad
            return _getQuadId(LAYER_1x1, (x + (i % size)), (y + row));
        } else {
            return _getQuadId(LAYER_1x1, (x + size) - (1 + (i % size)), (y + row));
        }
    }

    /// @dev checks if the Land's child quads are owned by the from address and clears all the previous owners
    /// if all the child quads are not owned by the "from" address then the owner of parent quad to the land
    /// is checked if owned by the "from" address. If from is the owner then land owner is set to "to" address
    /// @param from address of the previous owner
    /// @param to address of the new owner
    /// @param land the quad to be regrouped and transferred
    /// @param set for setting the new owner
    /// @param childQuadSize  size of the child quad to be checked for owner in the regrouping
    function _regroupQuad(
        address from,
        address to,
        Land memory land,
        bool set,
        uint256 childQuadSize
    ) internal returns (bool) {
        (uint256 layer, , uint256 childLayer) = _getQuadLayer(land.size);
        uint256 quadId = _getQuadId(layer, land.x, land.y);
        bool ownerOfAll = true;

        {
            // double for loop iterates and checks owner of all the smaller quads in land
            for (uint256 xi = land.x; xi < land.x + land.size; xi += childQuadSize) {
                for (uint256 yi = land.y; yi < land.y + land.size; yi += childQuadSize) {
                    uint256 ownerChild;
                    bool ownAllIndividual;
                    if (childQuadSize < 3) {
                        // case when the smaller quad is 1x1,
                        ownAllIndividual = _checkAndClearLandOwner(from, _getQuadId(LAYER_1x1, xi, yi)) && ownerOfAll;
                    } else {
                        // recursively calling the _regroupQuad function to check the owner of child quads.
                        ownAllIndividual = _regroupQuad(
                            from,
                            to,
                            Land({x: xi, y: yi, size: childQuadSize}),
                            false,
                            childQuadSize / 2
                        );
                        uint256 idChild = _getQuadId(childLayer, xi, yi);
                        ownerChild = _owners[idChild];
                        if (ownerChild != 0) {
                            // checking the owner of child quad
                            if (!ownAllIndividual) {
                                require(ownerChild == uint256(uint160(from)), "not owner of child Quad");
                            }
                            // clearing owner of child quad
                            _owners[idChild] = 0;
                        }
                    }
                    // ownerOfAll should be true if "from" is owner of all the child quads itereated over
                    ownerOfAll = (ownAllIndividual || ownerChild != 0) && ownerOfAll;
                }
            }
        }

        // if set is true it check if the "from" is owner of all else checks for the owner of parent quad is
        // owned by "from" and sets the owner for the id of land to "to" address.
        if (set) {
            if (!ownerOfAll) {
                require(_ownerOfQuad(land.size, land.x, land.y) == from, "not owner of all sub quads nor parent quads");
            }
            _owners[quadId] = uint256(uint160(to));
            return true;
        }

        return ownerOfAll;
    }

    function _ownerOfQuad(
        uint256 size,
        uint256 x,
        uint256 y
    ) internal view returns (address) {
        (uint256 layer, uint256 parentSize, ) = _getQuadLayer(size);
        address owner = address(uint160(_owners[_getQuadId(layer, (x / size) * size, (y / size) * size)]));
        if (owner != address(0)) {
            return owner;
        } else if (size < 24) {
            return _ownerOfQuad(parentSize, x, y);
        }
        return address(0);
    }

    function _getQuadById(uint256 id)
        internal
        pure
        returns (
            uint256 size,
            uint256 x,
            uint256 y
        )
    {
        x = _getX(id);
        y = _getY(id);
        uint256 layer = id & LAYER;
        if (layer == LAYER_1x1) {
            size = 1;
        } else if (layer == LAYER_3x3) {
            size = 3;
        } else if (layer == LAYER_6x6) {
            size = 6;
        } else if (layer == LAYER_12x12) {
            size = 12;
        } else if (layer == LAYER_24x24) {
            size = 24;
        } else {
            require(false, "Invalid token id");
        }
    }

    function _ownerOf(uint256 id) internal view override returns (address) {
        require(id & LAYER == 0, "Invalid token id");
        (uint256 size, uint256 x, uint256 y) = _getQuadById(id);
        require(x % size == 0, "x coordinate: Invalid token id");
        require(y % size == 0, "y coordinate: Invalid token id");
        if (size == 1) {
            uint256 owner1x1 = _owners[id];
            return (owner1x1 & BURNED_FLAG) == BURNED_FLAG ? address(0) : _ownerOfQuad(size, x, y);
        }
        return _ownerOfQuad(size, x, y);
    }

    function _ownerAndOperatorEnabledOf(uint256 id)
        internal
        view
        override
        returns (address owner, bool operatorEnabled)
    {
        require(id & LAYER == 0, "Invalid token id");
        uint256 x = id % GRID_SIZE;
        uint256 y = id / GRID_SIZE;
        uint256 owner1x1 = _owners[id];

        if ((owner1x1 & BURNED_FLAG) == BURNED_FLAG) {
            owner = address(0);
            operatorEnabled = (owner1x1 & OPERATOR_FLAG) == OPERATOR_FLAG;
            return (owner, operatorEnabled);
        }

        if (owner1x1 != 0) {
            owner = address(uint160(owner1x1));
            operatorEnabled = (owner1x1 & OPERATOR_FLAG) == OPERATOR_FLAG;
        } else {
            owner = _ownerOfQuad(3, (x * 3) / 3, (y * 3) / 3);
            operatorEnabled = false;
        }
    }

    // Empty storage space in contracts for future enhancements
    // ref: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/issues/13)
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "./PolygonLandBaseTokenV2.sol";
import "../../../common/BaseWithStorage/ERC2771Handler.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "../../../OperatorFilterer/contracts/upgradeable/OperatorFiltererUpgradeable.sol";

/// @title LAND token on L2
contract PolygonLandV2 is PolygonLandBaseTokenV2, ERC2771Handler, OperatorFiltererUpgradeable {
    using AddressUpgradeable for address;

    event OperatorRegistrySet(address indexed registry);

    function initialize(address trustedForwarder) external initializer {
        _admin = _msgSender();
        __ERC2771Handler_initialize(trustedForwarder);
        emit AdminChanged(address(0), _admin);
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyAdmin {
        _trustedForwarder = trustedForwarder;
        emit TrustedForwarderSet(trustedForwarder);
    }

    function _msgSender() internal view override(ContextUpgradeable, ERC2771Handler) returns (address) {
        return ERC2771Handler._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771Handler) returns (bytes calldata) {
        return ERC2771Handler._msgData();
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) public override onlyAllowedOperatorApproval(operator) {
        super.approveFor(sender, operator, id);
    }

    /**
     * @notice Approve an operator to spend tokens on the sender behalf
     * @param operator The address receiving the approval
     * @param id The id of the token
     */
    function approve(address operator, uint256 id) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, id);
    }

    /**
     * @notice Transfer a token between 2 addresses
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, id);
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The sender of the token
     * @param to The recipient of the token
     * @param id The id of the token
     * @param data Additional data
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, data);
    }

    /**
     * @notice Transfer a token between 2 addresses letting the receiver knows of the transfer
     * @param from The send of the token
     * @param to The recipient of the token
     * @param id The id of the token
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id);
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Set the approval for an operator to manage all the tokens of the sender
     * @param sender The address giving the approval
     * @param operator The address receiving the approval
     * @param approved The determination of the approval
     */
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAllFor(sender, operator, approved);
    }

    /// @notice This function is used to register Land contract on the Operator Filterer Registry of Opensea.
    /// @dev can only be called by admin.
    /// @param subscriptionOrRegistrantToCopy registration address of the list to subscribe.
    /// @param subscribe bool to signify subscription 'true' or to copy the list 'false'.
    function register(address subscriptionOrRegistrantToCopy, bool subscribe) external onlyAdmin {
        require(subscriptionOrRegistrantToCopy != address(0), "PolygonLandV2: subscription can't be zero address");
        _register(subscriptionOrRegistrantToCopy, subscribe);
    }

    /// @notice sets filter registry address deployed in test
    /// @param registry the address of the registry
    function setOperatorRegistry(address registry) external virtual onlyAdmin {
        operatorFilterRegistry = IOperatorFilterRegistry(registry);
        emit OperatorRegistrySet(registry);
    }
}