// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
interface IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
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
    uint256[49] private __gap;
}

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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

library ERC1155ERC721Helper {
    bytes32 private constant base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;

    uint256 public constant CREATOR_OFFSET_MULTIPLIER = uint256(2)**(256 - 160);
    uint256 public constant IS_NFT_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1);
    uint256 public constant CHAIN_INDEX_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 8);
    uint256 public constant PACK_ID_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40);
    uint256 public constant PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER = uint256(2)**(256 - 160 - 1 - 32 - 40 - 12);
    uint256 public constant NFT_INDEX_OFFSET = 63;

    uint256 public constant IS_NFT = 0x0000000000000000000000000000000000000000800000000000000000000000;
    uint256 public constant NOT_IS_NFT = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;
    uint256 public constant NFT_INDEX = 0x0000000000000000000000000000000000000000007FFFFF8000000000000000;
    uint256 public constant NOT_NFT_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8000007FFFFFFFFFFFFFFF;
    uint256 public constant URI_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFFFFF800;
    uint256 public constant PACK_ID = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000007FFFFFFFFF800000;
    uint256 public constant PACK_INDEX = 0x00000000000000000000000000000000000000000000000000000000000007FF;
    uint256 public constant PACK_NUM_FT_TYPES = 0x00000000000000000000000000000000000000000000000000000000007FF800;
    uint256 public constant CHAIN_INDEX = 0x00000000000000000000000000000000000000007F8000000000000000000000;
    uint256 public constant NOT_CHAIN_INDEX = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF807FFFFFFFFFFFFFFFFFFFFF;

    uint256 public constant MAX_SUPPLY = uint256(2)**32 - 1;
    uint256 public constant MAX_PACK_SIZE = uint256(2)**11;
    uint256 public constant MAX_NUM_FT = uint256(2)**12;

    function toFullURI(bytes32 hash, uint256 id) external pure returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybei", hash2base32(hash), "/", uint2str(id & PACK_INDEX), ".json"));
    }

    // solium-disable-next-line security/no-assign-params
    function hash2base32(bytes32 hash) public pure returns (string memory _uintAsString) {
        uint256 _i = uint256(hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    // solium-disable-next-line security/no-assign-params
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + uint8(_i % 10)));
            _i /= 10;
        }

        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/utils/Address.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155Receiver.sol";
import "../common/interfaces/IAssetERC721.sol";
import "../common/Libraries/ObjectLib32.sol";
import "../common/BaseWithStorage/WithSuperOperators.sol";
import "../asset/libraries/ERC1155ERC721Helper.sol";

// solhint-disable max-states-count
abstract contract AssetBaseERC1155 is WithSuperOperators, IERC1155 {
    using Address for address;
    using ObjectLib32 for ObjectLib32.Operations;
    using ObjectLib32 for uint256;

    bytes4 private constant ERC1155_IS_RECEIVER = 0x4e2312e0;
    bytes4 private constant ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 private constant ERC1155_BATCH_RECEIVED = 0xbc197c81;

    mapping(address => uint256) private _numNFTPerAddress; // erc721
    mapping(uint256 => uint256) private _owners; // erc721
    mapping(address => mapping(uint256 => uint256)) private _packedTokenBalance; // erc1155
    mapping(address => mapping(address => bool)) private _operatorsForAll; // erc721 and erc1155
    mapping(uint256 => address) private _erc721operators; // erc721
    mapping(uint256 => bytes32) internal _metadataHash; // erc721 and erc1155
    mapping(uint256 => bytes) internal _rarityPacks; // rarity configuration per packs (2 bits per Asset) *DEPRECATED*
    mapping(uint256 => uint32) private _nextCollectionIndex; // extraction

    // @note : Deprecated.
    mapping(address => address) private _creatorship; // creatorship transfer // deprecated

    mapping(address => bool) private _bouncers; // the contracts allowed to mint

    // @note : Deprecated.
    mapping(address => bool) private _metaTransactionContracts;

    address private _bouncerAdmin;

    bool internal _init;

    bytes4 internal constant ERC165ID = 0x01ffc9a7;

    uint256 internal _initBits;
    address internal _predicate; // used in place of polygon's `PREDICATE_ROLE`

    uint8 internal _chainIndex; // modify this for l2

    address internal _trustedForwarder;

    IAssetERC721 public _assetERC721;

    uint256[20] private __gap;
    // solhint-enable max-states-count

    event BouncerAdminChanged(address indexed oldBouncerAdmin, address indexed newBouncerAdmin);
    event Bouncer(address indexed bouncer, bool indexed enabled);
    event Extraction(uint256 indexed id, uint256 indexed newId);
    event AssetERC721Set(IAssetERC721 indexed assetERC721);

    function init(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        IAssetERC721 assetERC721,
        uint8 chainIndex
    ) public {
        // one-time init of bitfield's previous versions
        _checkInit(1);
        _admin = admin;
        _bouncerAdmin = bouncerAdmin;
        _assetERC721 = assetERC721;
        __ERC2771Handler_initialize(trustedForwarder);
        _chainIndex = chainIndex;
    }

    /// @notice Change the minting administrator to be `newBouncerAdmin`.
    /// @param newBouncerAdmin address of the new minting administrator.
    function changeBouncerAdmin(address newBouncerAdmin) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        require(newBouncerAdmin != address(0), "AssetBaseERC1155: new bouncer admin can't be zero address");
        emit BouncerAdminChanged(_bouncerAdmin, newBouncerAdmin);
        _bouncerAdmin = newBouncerAdmin;
    }

    /// @notice Enable or disable the ability of `bouncer` to mint tokens (minting bouncer rights).
    /// @param bouncer address that will be given/removed minting bouncer rights.
    /// @param enabled set whether the address is enabled or disabled as a minting bouncer.
    function setBouncer(address bouncer, bool enabled) external {
        require(_msgSender() == _bouncerAdmin, "!BOUNCER_ADMIN");
        _bouncers[bouncer] = enabled;
        emit Bouncer(bouncer, enabled);
    }

    /// @notice Transfers `value` tokens of type `id` from  `from` to `to`  (with safety call).
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param id the token type transfered.
    /// @param value amount of token transfered.
    /// @param data aditional data accompanying the transfer.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        bool success = _transferFrom(from, to, id, value);
        if (success) {
            require(_checkOnERC1155Received(_msgSender(), from, to, id, value, data), "1155_TRANSFER_REJECTED");
        }
    }

    /// @notice Transfers `values` tokens of type `ids` from  `from` to `to` (with safety call).
    /// @dev call data should be optimized to order ids so packedBalance can be used efficiently.
    /// @param from address from which tokens are transfered.
    /// @param to address to which the token will be transfered.
    /// @param ids ids of each token type transfered.
    /// @param values amount of each token type transfered.
    /// @param data aditional data accompanying the transfer.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "MISMATCHED_ARR_LEN");
        require(to != address(0), "TO==0");
        require(from != address(0), "FROM==0");
        address msgSender = _msgSender();
        bool authorized = from == msgSender || isApprovedForAll(from, msgSender);

        _batchTransferFrom(from, to, ids, values, authorized);
        emit TransferBatch(msgSender, from, to, ids, values);
        require(_checkOnERC1155BatchReceived(msgSender, from, to, ids, values, data), "1155_TRANSFER_REJECTED");
    }

    /// @notice Enable or disable approval for `operator` to manage all `sender`'s tokens.
    /// @dev used for Meta Transaction (from metaTransactionContract).
    /// @param sender address which grant approval.
    /// @param operator address which will be granted rights to transfer all token owned by `sender`.
    /// @param approved whether to approve or revoke.
    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external {
        require(sender == _msgSender() || _superOperators[_msgSender()], "!AUTHORIZED");
        _setApprovalForAll(sender, operator, approved);
    }

    /// @notice Enable or disable approval for `operator` to manage all of the caller's tokens.
    /// @param operator address which will be granted rights to transfer all tokens of the caller.
    /// @param approved whether to approve or revoke
    function setApprovalForAll(address operator, bool approved) external override(IERC1155) {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /// @notice Returns the current administrator in charge of minting rights.
    /// @return the current minting administrator in charge of minting rights.
    function getBouncerAdmin() external view returns (address) {
        return _bouncerAdmin;
    }

    /// @notice check whether address `who` is given minting bouncer rights.
    /// @param who The address to query.
    /// @return whether the address has minting rights.
    function isBouncer(address who) public view returns (bool) {
        return _bouncers[who];
    }

    /// @notice Get the balance of `owners` for each token type `ids`.
    /// @param owners the addresses of the token holders queried.
    /// @param ids ids of each token type to query.
    /// @return the balance of each `owners` for each token type `ids`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        override
        returns (uint256[] memory)
    {
        require(owners.length == ids.length, "ARG_LENGTH_MISMATCH");
        uint256[] memory balances = new uint256[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            balances[i] = balanceOf(owners[i], ids[i]);
        }
        return balances;
    }

    /// @notice A descriptive name for the collection of tokens in this contract.
    /// @return _name the name of the tokens.
    function name() external pure returns (string memory _name) {
        return "Sandbox's ASSETs";
    }

    /// @notice An abbreviated name for the collection of tokens in this contract.
    /// @return _symbol the symbol of the tokens.
    function symbol() external pure returns (string memory _symbol) {
        return "ASSET";
    }

    /// @notice Query if a contract implements interface `id`.
    /// @param id the interface identifier, as specified in ERC-165.
    /// @return `true` if the contract implements `id`.
    function supportsInterface(bytes4 id) external pure override returns (bool) {
        return
            id == 0x01ffc9a7 || //ERC165
            id == 0xd9b67a26 || // ERC1155
            id == 0x0e89341c || // ERC1155 metadata
            id == 0x572b6c05; // ERC2771
    }

    /// Collection methods for ERC721s extracted from an ERC1155 -----------------------------------------------------

    /// @notice Gives the collection a specific token belongs to.
    /// @param id the token to get the collection of.
    /// @return the collection the NFT is part of.
    function collectionOf(uint256 id) public view returns (uint256) {
        require(doesHashExist(id), "INVALID_ID"); // Note: doesHashExist must track ERC721s
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        require(doesHashExist(collectionId), "UNMINTED_COLLECTION");
        return collectionId;
    }

    /// @notice Return wether the id is a collection
    /// @param id collectionId to check.
    /// @return whether the id is a collection.
    function isCollection(uint256 id) external view returns (bool) {
        uint256 collectionId = id & ERC1155ERC721Helper.NOT_NFT_INDEX & ERC1155ERC721Helper.NOT_IS_NFT;
        return doesHashExist(collectionId);
    }

    /// @notice Gives the index at which an NFT was minted in a collection : first of a collection get the zero index.
    /// @param id the token to get the index of.
    /// @return the index/order at which the token `id` was minted in a collection.
    function collectionIndexOf(uint256 id) external view returns (uint256) {
        collectionOf(id); // this check if id and collection indeed was ever minted
        return uint24((id & ERC1155ERC721Helper.NFT_INDEX) >> ERC1155ERC721Helper.NFT_INDEX_OFFSET);
    }

    /// end collection methods ---------------------------------------------------------------------------------------

    /// @notice Whether or not an ERC1155 or ERC721 tokenId has a valid structure and the metadata hash exists.
    /// @param id the token to check.
    /// @return bool whether a given id has a valid structure.
    /// @dev if IS_NFT > 0 then PACK_NUM_FT_TYPES may be 0
    function doesHashExist(uint256 id) public view returns (bool) {
        return (((id & ERC1155ERC721Helper.PACK_INDEX) <=
            ((id & ERC1155ERC721Helper.PACK_NUM_FT_TYPES) / ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER)) &&
            _metadataHash[id & ERC1155ERC721Helper.URI_ID] != 0);
    }

    /// @notice A distinct Uniform Resource Identifier (URI) for a given ERC1155 asset.
    /// @param id ERC1155 token to get the uri of.
    /// @return URI string
    function uri(uint256 id) public view returns (string memory) {
        require(doesHashExist(id), "INVALID_ID"); // prevent returning invalid uri
        return ERC1155ERC721Helper.toFullURI(_metadataHash[id & ERC1155ERC721Helper.URI_ID], id);
    }

    /// @notice Get the balance of `owner` for the token type `id`.
    /// @param owner The address of the token holder.
    /// @param id the token type of which to get the balance of.
    /// @return the balance of `owner` for the token type `id`.
    function balanceOf(address owner, uint256 id) public view override returns (uint256) {
        require(doesHashExist(id), "INVALID_ID");
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        return _packedTokenBalance[owner][bin].getValueInBin(index);
    }

    /// @notice Extracts an EIP-721 Asset from an EIP-1155 Asset.
    /// @dev Extraction is limited to bouncers.
    /// @param sender address which own the token to be extracted.
    /// @param id the token type to extract from.
    /// @param to address which will receive the token.
    /// @return newId the id of the newly minted NFT.
    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256) {
        require(sender == _msgSender() || isApprovedForAll(sender, _msgSender()), "!AUTHORIZED");
        require(isBouncer(_msgSender()), "!BOUNCER");
        require(to != address(0), "TO==0");
        require(id & ERC1155ERC721Helper.IS_NFT == 0, "UNIQUE_ERC1155");
        uint24 tokenCollectionIndex = uint24(_nextCollectionIndex[id]) + 1;
        _nextCollectionIndex[id] = tokenCollectionIndex;
        string memory metaData = uri(id);
        uint256 newId =
            id +
                ERC1155ERC721Helper.IS_NFT_OFFSET_MULTIPLIER + // newId is always an NFT; IS_NFT is 1
                (tokenCollectionIndex) *
                2**ERC1155ERC721Helper.NFT_INDEX_OFFSET; // uint24 nft index
        _burnFT(sender, id, 1);
        _assetERC721.mint(to, newId, bytes(abi.encode(metaData)));
        emit Extraction(id, newId);
        return newId;
    }

    /// @notice Set the ERC721 contract.
    /// @param assetERC721 the contract address to set the ERC721 contract to.
    /// @return true if the operation completes successfully.
    function setAssetERC721(IAssetERC721 assetERC721) external returns (bool) {
        require(_admin == _msgSender(), "!AUTHORIZED");
        _assetERC721 = assetERC721;
        emit AssetERC721Set(assetERC721);
        return true;
    }

    /// @notice Queries the approval status of `operator` for owner `owner`.
    /// @param owner the owner of the tokens.
    /// @param operator address of authorized operator.
    /// @return isOperator true if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(IERC1155)
        returns (bool isOperator)
    {
        require(owner != address(0), "OWNER==0");
        require(operator != address(0), "OPERATOR==0");
        return _operatorsForAll[owner][operator] || _superOperators[operator];
    }

    /// @notice Queries the chainIndex that a token was minted on originally.
    /// @param id the token id to query.
    /// @return chainIndex the chainIndex that the token was minted on originally.
    /// @dev take care not to confuse chainIndex with chain ID.
    function getChainIndex(uint256 id) external pure returns (uint256) {
        return uint8((id & ERC1155ERC721Helper.CHAIN_INDEX) / ERC1155ERC721Helper.CHAIN_INDEX_OFFSET_MULTIPLIER);
    }

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

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

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _setApprovalForAll(
        address sender,
        address operator,
        bool approved
    ) internal {
        require(sender != address(0), "SENDER==0");
        require(sender != operator, "SENDER==OPERATOR");
        require(operator != address(0), "OPERATOR==0");
        require(!_superOperators[operator], "APPR_EXISTING_SUPEROPERATOR");
        _operatorsForAll[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /* solhint-disable code-complexity */
    function _batchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bool authorized
    ) internal {
        uint256 numItems = ids.length;
        uint256 bin;
        uint256 index;
        uint256 balFrom;
        uint256 balTo;

        uint256 lastBin;
        require(authorized, "OPERATOR_!AUTH");

        for (uint256 i = 0; i < numItems; i++) {
            if (from == to) {
                _checkEnoughBalance(from, ids[i], values[i]);
            } else if (values[i] > 0) {
                (bin, index) = ids[i].getTokenBinIndex();
                if (lastBin == 0) {
                    lastBin = bin;
                    balFrom = ObjectLib32.updateTokenBalance(
                        _packedTokenBalance[from][bin],
                        index,
                        values[i],
                        ObjectLib32.Operations.SUB
                    );
                    balTo = ObjectLib32.updateTokenBalance(
                        _packedTokenBalance[to][bin],
                        index,
                        values[i],
                        ObjectLib32.Operations.ADD
                    );
                } else {
                    if (bin != lastBin) {
                        _packedTokenBalance[from][lastBin] = balFrom;
                        _packedTokenBalance[to][lastBin] = balTo;
                        balFrom = _packedTokenBalance[from][bin];
                        balTo = _packedTokenBalance[to][bin];
                        lastBin = bin;
                    }

                    balFrom = balFrom.updateTokenBalance(index, values[i], ObjectLib32.Operations.SUB);
                    balTo = balTo.updateTokenBalance(index, values[i], ObjectLib32.Operations.ADD);
                }
            }
        }

        if (bin != 0 && from != to) {
            _packedTokenBalance[from][bin] = balFrom;
            _packedTokenBalance[to][bin] = balTo;
        }
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        require(amount > 0 && amount <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
        _burnFT(from, id, uint32(amount));
        emit TransferSingle(_msgSender(), from, address(0), id, amount);
    }

    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        address operator = _msgSender();
        for (uint256 i = 0; i < ids.length; i++) {
            require(amounts[i] > 0 && amounts[i] <= ERC1155ERC721Helper.MAX_SUPPLY, "INVALID_AMOUNT");
            _burnFT(from, ids[i], uint32(amounts[i]));
        }
        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    function _burnFT(
        address from,
        uint256 id,
        uint32 amount
    ) internal {
        (uint256 bin, uint256 index) = (id).getTokenBinIndex();
        _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.SUB
        );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint16 offset = 0;
        while (offset < amounts.length) {
            _mintPack(offset, amounts, to, ids);
            offset += 8;
        }
        _completeBatchMint(_msgSender(), to, ids, amounts, data);
    }

    function _mintPack(
        uint16 offset,
        uint256[] memory supplies,
        address owner,
        uint256[] memory ids
    ) internal {
        (uint256 bin, uint256 index) = ids[offset].getTokenBinIndex();
        for (uint256 i = 0; i < 8 && offset + i < supplies.length; i++) {
            uint256 j = offset + i;
            if (supplies[j] > 0) {
                _packedTokenBalance[owner][bin] = _packedTokenBalance[owner][bin].updateTokenBalance(
                    index + i,
                    supplies[j],
                    ObjectLib32.Operations.ADD
                );
            }
        }
    }

    function _transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal returns (bool) {
        address sender = _msgSender();
        bool authorized = from == sender || isApprovedForAll(from, sender);

        require(authorized, "OPERATOR_!AUTH");
        if (value > 0) {
            (uint256 bin, uint256 index) = id.getTokenBinIndex();
            _packedTokenBalance[from][bin] = _packedTokenBalance[from][bin].updateTokenBalance(
                index,
                value,
                ObjectLib32.Operations.SUB
            );
            _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin].updateTokenBalance(
                index,
                value,
                ObjectLib32.Operations.ADD
            );
        }

        emit TransferSingle(sender, from, to, id, value);
        return true;
    }

    function _mint(
        address operator,
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        _packedTokenBalance[account][bin] = _packedTokenBalance[account][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.REPLACE
        );

        emit TransferSingle(operator, address(0), account, id, amount);
        require(_checkOnERC1155Received(operator, address(0), account, id, amount, data), "TRANSFER_REJECTED");
    }

    function _mintBatches(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        for (uint256 i = 0; i < amounts.length; i++) {
            if (amounts[i] > 0) {
                (uint256 bin, uint256 index) = ids[i].getTokenBinIndex();
                _packedTokenBalance[to][bin] = _packedTokenBalance[to][bin].updateTokenBalance(
                    index,
                    amounts[i],
                    ObjectLib32.Operations.REPLACE
                );
            }
        }
        _completeBatchMint(_msgSender(), to, ids, amounts, data);
    }

    function _mintDeficit(
        address account,
        uint256 id,
        uint256 amount
    ) internal {
        address sender = _msgSender();
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        _packedTokenBalance[account][bin] = _packedTokenBalance[account][bin].updateTokenBalance(
            index,
            amount,
            ObjectLib32.Operations.ADD
        );

        emit TransferSingle(sender, address(0), account, id, amount);
        require(_checkOnERC1155Received(sender, address(0), account, id, amount, ""), "TRANSFER_REJECTED");
    }

    /// @dev Allows the use of a bitfield to track the initialized status of the version `v` passed in as an arg.
    /// If the bit at the index corresponding to the given version is already set, revert.
    /// Otherwise, set the bit and return.
    /// @param v The version of this contract.
    function _checkInit(uint256 v) internal {
        require((_initBits >> v) & uint256(1) != 1, "ALREADY_INITIALISED");
        _initBits = _initBits | (uint256(1) << v);
    }

    function _completeBatchMint(
        address operator,
        address owner,
        uint256[] memory ids,
        uint256[] memory supplies,
        bytes memory data
    ) internal {
        emit TransferBatch(operator, address(0), owner, ids, supplies);
        require(_checkOnERC1155BatchReceived(operator, address(0), owner, ids, supplies, data), "TRANSFER_REJECTED");
    }

    function _checkEnoughBalance(
        address from,
        uint256 id,
        uint256 value
    ) internal view {
        (uint256 bin, uint256 index) = id.getTokenBinIndex();
        require(_packedTokenBalance[from][bin].getValueInBin(index) >= value, "BALANCE_TOO_LOW");
    }

    function _checkOnERC1155Received(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }

        return IERC1155Receiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_RECEIVED;
    }

    function _checkOnERC1155BatchReceived(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal returns (bool) {
        if (!to.isContract()) {
            return true;
        }
        bytes4 retval = IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, values, data);
        return (retval == ERC1155_BATCH_RECEIVED);
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev minimal ERC2771 handler to keep bytecode-size down
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/metatx/ERC2771Context.sol
/// with an initializer for proxies and a mutable forwarder
/// @dev same as ERC2771Handler.sol but with gap

contract ERC2771HandlerUpgradeable {
    address internal _trustedForwarder;
    uint256[49] private __gap;

    function __ERC2771Handler_initialize(address forwarder) internal {
        _trustedForwarder = forwarder;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function getTrustedForwarder() external view returns (address trustedForwarder) {
        return _trustedForwarder;
    }

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

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

contract WithAdmin {
    address internal _admin;

    /// @dev Emits when the contract administrator is changed.
    /// @param oldAdmin The address of the previous administrator.
    /// @param newAdmin The address of the new administrator.
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    modifier onlyAdmin() {
        require(msg.sender == _admin, "ADMIN_ONLY");
        _;
    }

    /// @dev Get the current administrator of this contract.
    /// @return The current administrator of this contract.
    function getAdmin() external view returns (address) {
        return _admin;
    }

    /// @dev Change the administrator to be `newAdmin`.
    /// @param newAdmin The address of the new administrator.
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _admin, "ADMIN_ACCESS_DENIED");
        emit AdminChanged(_admin, newAdmin);
        _admin = newAdmin;
    }
}

//SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

import "./WithAdmin.sol";

contract WithSuperOperators is WithAdmin {
    mapping(address => bool) internal _superOperators;

    event SuperOperator(address indexed superOperator, bool indexed enabled);

    /// @notice Enable or disable the ability of `superOperator` to transfer tokens of all (superOperator rights).
    /// @param superOperator address that will be given/removed superOperator right.
    /// @param enabled set whether the superOperator is enabled or disabled.
    function setSuperOperator(address superOperator, bool enabled) external {
        require(msg.sender == _admin, "only admin is allowed to add super operators");
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

library ObjectLib32 {
    enum Operations {ADD, SUB, REPLACE}
    // Constants regarding bin or chunk sizes for balance packing
    uint256 internal constant TYPES_BITS_SIZE = 32; // Max size of each object
    uint256 internal constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256
    uint256 internal constant TYPE_ELIMINATOR = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFFFFFFFFFFF;

    //
    // Objects and Tokens Functions
    //

    /// @dev Return the bin number and index within that bin where ID is
    /// @param tokenId Object type
    /// @return bin Bin number.
    /// @return index ID's index within that bin.
    function getTokenBinIndex(uint256 tokenId) internal pure returns (uint256 bin, uint256 index) {
        uint256 id = tokenId & TYPE_ELIMINATOR;
        unchecked {bin = (id * TYPES_BITS_SIZE) / 256;}
        index = tokenId % TYPES_PER_UINT256;
        return (bin, index);
    }

    /**
     * @dev update the balance of a type provided in binBalances
     * @param binBalances Uint256 containing the balances of objects
     * @param index Index of the object in the provided bin
     * @param amount Value to update the type balance
     * @param operation Which operation to conduct :
     *     Operations.REPLACE : Replace type balance with amount
     *     Operations.ADD     : ADD amount to type balance
     *     Operations.SUB     : Substract amount from type balance
     */
    function updateTokenBalance(
        uint256 binBalances,
        uint256 index,
        uint256 amount,
        Operations operation
    ) internal pure returns (uint256 newBinBalance) {
        uint256 objectBalance = 0;
        if (operation == Operations.ADD) {
            objectBalance = getValueInBin(binBalances, index);
            newBinBalance = writeValueInBin(binBalances, index, objectBalance + amount);
        } else if (operation == Operations.SUB) {
            objectBalance = getValueInBin(binBalances, index);
            require(objectBalance >= amount, "can't substract more than there is");
            newBinBalance = writeValueInBin(binBalances, index, objectBalance - amount);
        } else if (operation == Operations.REPLACE) {
            newBinBalance = writeValueInBin(binBalances, index, amount);
        } else {
            revert("Invalid operation"); // Bad operation
        }

        return newBinBalance;
    }

    /*
     * @dev return value in binValue at position index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index index at which to retrieve value
     * @return Value at given index in bin
     */
    function getValueInBin(uint256 binValue, uint256 index) internal pure returns (uint256) {
        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 rightShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue >> rightShift) & mask;
    }

    /**
     * @dev return the updated binValue after writing amount at index
     * @param binValue uint256 containing the balances of TYPES_PER_UINT256 types
     * @param index Index at which to retrieve value
     * @param amount Value to store at index in bin
     * @return Value at given index in bin
     */
    function writeValueInBin(
        uint256 binValue,
        uint256 index,
        uint256 amount
    ) internal pure returns (uint256) {
        require(amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

        // Mask to retrieve data for a given binData
        uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

        // Shift amount
        uint256 leftShift = 256 - TYPES_BITS_SIZE * (index + 1);
        return (binValue & ~(mask << leftShift)) | (amount << leftShift);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract FxBaseChildTunnelUpgradeable is FxBaseChildTunnel, Initializable {
    // solhint-disable-next-line no-empty-blocks
    constructor() FxBaseChildTunnel(address(0)) {}

    function __FxBaseChildTunnelUpgradeable_initialize(address _fxChild) internal onlyInitializing {
        fxChild = _fxChild;
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Base} from "./IERC721Base.sol";

interface IAssetERC721 is IERC721Base {
    function setTokenURI(uint256 id, string memory uri) external;

    function tokenURI(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ExtendedToken} from "./IERC721ExtendedToken.sol";

interface IERC721Base is IERC721Upgradeable {
    function mint(address to, uint256 id) external;

    function mint(
        address to,
        uint256 id,
        bytes calldata metaData
    ) external;

    function approveFor(
        address from,
        address operator,
        uint256 id
    ) external;

    function setApprovalForAllFor(
        address from,
        address operator,
        bool approved
    ) external;

    function burnFrom(address from, uint256 id) external;

    function burn(uint256 id) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function exists(uint256 tokenId) external view returns (bool);

    function supportsInterface(bytes4 id) external view override returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address trustedForwarder);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IERC721ExtendedToken {
    function approveFor(
        address sender,
        address operator,
        uint256 id
    ) external;

    function batchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        bytes calldata data
    ) external;

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function burn(uint256 id) external;

    function burnFrom(address from, uint256 id) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {IAssetERC721} from "./IAssetERC721.sol";

interface IPolygonAssetERC1155 {
    function changeBouncerAdmin(address newBouncerAdmin) external;

    function setBouncer(address bouncer, bool enabled) external;

    function setPredicate(address predicate) external;

    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        address owner,
        bytes calldata data
    ) external returns (uint256 id);

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function mintDeficit(
        address account,
        uint256 id,
        uint256 amount
    ) external;

    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids);

    // fails on non-NFT or nft who do not have collection (was a mistake)
    function collectionOf(uint256 id) external view returns (uint256);

    function balanceOf(address owner, uint256 id) external view returns (uint256);

    // return true for Non-NFT ERC1155 tokens which exists
    function isCollection(uint256 id) external view returns (bool);

    function collectionIndexOf(uint256 id) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;

    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function getBouncerAdmin() external view returns (address);

    function extractERC721From(
        address sender,
        uint256 id,
        address to
    ) external returns (uint256 newId);

    function isBouncer(address who) external view returns (bool);

    function creatorOf(uint256 id) external view returns (address);

    function doesHashExist(uint256 id) external view returns (bool);

    function isSuperOperator(address who) external view returns (bool);

    function isApprovedForAll(address owner, address operator) external view returns (bool isOperator);

    function setApprovalForAllFor(
        address sender,
        address operator,
        bool approved
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external returns (uint256[] memory);

    function name() external returns (string memory _name);

    function symbol() external returns (string memory _symbol);

    function supportsInterface(bytes4 id) external returns (bool);

    function uri(uint256 id) external returns (string memory);

    function setAssetERC721(IAssetERC721 assetERC721) external;

    function exists(uint256 tokenId) external view returns (bool);

    function setTrustedForwarder(address trustedForwarder) external;

    function isTrustedForwarder(address forwarder) external returns (bool);

    function getTrustedForwarder() external returns (address);

    function metadataHash(uint256 id) external returns (bytes32);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

interface IChildToken {
    function deposit(address user, bytes calldata depositData) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../../assetERC1155/AssetBaseERC1155.sol";
import "../../../common/interfaces/pos-portal/child/IChildToken.sol";

/// @title This contract is for AssetERC1155 which can be minted by a minter role.
/// @dev AssetERC1155 will be minted only on L2 and can be transferred to L1 and not minted on L1.
/// @dev This contract supports meta transactions.
/// @dev This contract is final, don't inherit from it.
contract PolygonAssetERC1155 is AssetBaseERC1155, IChildToken {
    address public _childChainManager;

    function initialize(
        address trustedForwarder,
        address admin,
        address bouncerAdmin,
        address childChainManager,
        IAssetERC721 polygonAssetERC721,
        uint8 chainIndex
    ) external {
        require(address(childChainManager) != address(0), "PolygonAssetERC1155Tunnel: childChainManager can't be zero");
        init(trustedForwarder, admin, bouncerAdmin, polygonAssetERC721, chainIndex);
        _childChainManager = childChainManager;
    }

    /// @notice Mint a token type for `creator` on slot `packId`.
    /// @dev For this function it is not required to provide data.
    /// @param creator address of the creator of the token.
    /// @param packId unique packId for that token.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of the token type in the file 0.json.
    /// @param supply number of tokens minted for that token type.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return id the id of the newly minted token type.
    function mint(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256 supply,
        address owner,
        bytes calldata data
    ) external returns (uint256 id) {
        require(hash != 0, "HASH==0");
        require(isBouncer(_msgSender()), "!BOUNCER");
        require(owner != address(0), "TO==0");
        id = _generateTokenId(creator, supply, packId, supply == 1 ? 0 : 1, 0);
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
        _metadataHash[uriId] = hash;
        _mint(_msgSender(), owner, id, supply, data);
    }

    /// @notice Creates `amount` tokens of token type `id`, and assigns them to `account`.
    /// @dev Should be used only by PolygonAssetERC1155Tunnel.
    /// @dev This function can be called when the token ID exists on another layer.
    /// @dev Encoded bytes32 metadata hash must be provided as data.
    /// @param owner address that will receive the tokens.
    /// @param id the id of the newly minted token.
    /// @param supply number of tokens minted for that token type.
    /// @param data token metadata.
    function mint(
        address owner,
        uint256 id,
        uint256 supply,
        bytes calldata data
    ) external {
        require(isBouncer(_msgSender()), "!BOUNCER");
        require(data.length > 0, "METADATA_MISSING");
        require(owner != address(0), "TO==0");
        uint256 uriId = id & ERC1155ERC721Helper.URI_ID;
        require(uint256(_metadataHash[uriId]) == 0, "ID_TAKEN");
        _metadataHash[uriId] = abi.decode(data, (bytes32));
        _mint(_msgSender(), owner, id, supply, data);
    }

    /// @notice Mint multiple token types for `creator` on slot `packId`.
    /// @dev For this function it is not required to provide data.
    /// @param creator address of the creator of the tokens.
    /// @param packId unique packId for the tokens.
    /// @param hash hash of an IPFS cidv1 folder that contains the metadata of each token type in the files: 0.json, 1.json, 2.json, etc...
    /// @param supplies number of tokens minted for each token type.
    /// @param rarityPack rarity power of each token types packed into 2 bits each.
    /// @param owner address that will receive the tokens.
    /// @param data extra data to accompany the minting call.
    /// @return ids the ids of each newly minted token types.
    function mintMultiple(
        address creator,
        uint40 packId,
        bytes32 hash,
        uint256[] calldata supplies,
        bytes calldata rarityPack,
        address owner,
        bytes calldata data
    ) external returns (uint256[] memory ids) {
        require(hash != 0, "HASH==0");
        require(isBouncer(_msgSender()), "!BOUNCER");
        require(owner != address(0), "TO==0");
        ids = _allocateIds(creator, supplies, rarityPack, packId, hash);
        _mintBatch(owner, ids, supplies, data);
    }

    /// @notice function to be called by tunnel to mint deficit of minted tokens
    /// @dev This mint calls for add instead of replace in packedTokenBalance
    /// @param account address of the ownerof tokens.
    /// @param id id of the token to be minted.
    /// @param amount quantity of the token to be minted.
    function mintDeficit(
        address account,
        uint256 id,
        uint256 amount
    ) external {
        require(isBouncer(_msgSender()), "!BOUNCER");
        _mintDeficit(account, id, amount);
    }

    /// @notice Burns `amount` tokens of type `id`.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burn(uint256 id, uint256 amount) external {
        _burn(_msgSender(), id, amount);
    }

    /// @notice Burns `amount` tokens of type `id` from `from`.
    /// @param from address whose token is to be burnt.
    /// @param id token type which will be burnt.
    /// @param amount amount of token to burn.
    function burnFrom(
        address from,
        uint256 id,
        uint256 amount
    ) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "!AUTHORIZED");
        _burn(from, id, amount);
    }

    /// @notice This function is called when a token is deposited to the root chain.
    /// @dev Should be callable only by ChildChainManager.
    /// @dev Should handle deposit by minting the required tokenId(s) for user.
    /// @dev Minting can also be done by other functions.
    /// @param user user address for whom deposit is being done.
    /// @param depositData abi encoded tokenIds. Batch deposit also supported.
    function deposit(address user, bytes calldata depositData) external override {
        require(_msgSender() == _childChainManager, "!DEPOSITOR");
        require(user != address(0), "INVALID_DEPOSIT_USER");
        (uint256[] memory ids, uint256[] memory amounts, bytes memory data) =
            abi.decode(depositData, (uint256[], uint256[], bytes));

        _mintBatches(user, ids, amounts, data);
    }

    /// @notice called when user wants to withdraw single token back to root chain.
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain.
    /// @param id id to withdraw.
    /// @param amount amount to withdraw.
    function withdrawSingle(uint256 id, uint256 amount) external {
        _burn(_msgSender(), id, amount);
    }

    /// @notice called when user wants to batch withdraw tokens back to root chain.
    /// @dev Should burn user's tokens. This transaction will be verified when exiting on root chain.
    /// @param ids ids to withdraw.
    /// @param amounts amounts to withdraw.
    function withdrawBatch(uint256[] calldata ids, uint256[] calldata amounts) external {
        _burnBatch(_msgSender(), ids, amounts);
    }

    function metadataHash(uint256 id) external view returns (bytes32) {
        return _metadataHash[id & ERC1155ERC721Helper.URI_ID];
    }

    function _allocateIds(
        address creator,
        uint256[] memory supplies,
        bytes memory rarityPack,
        uint40 packId,
        bytes32 hash
    ) internal returns (uint256[] memory ids) {
        require(supplies.length > 0, "SUPPLIES<=0");
        require(supplies.length <= ERC1155ERC721Helper.MAX_PACK_SIZE, "BATCH_TOO_BIG");
        ids = _generateTokenIds(creator, supplies, packId);

        require(uint256(_metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID]) == 0, "ID_TAKEN");
        _metadataHash[ids[0] & ERC1155ERC721Helper.URI_ID] = hash;
        _rarityPacks[ids[0] & ERC1155ERC721Helper.URI_ID] = rarityPack;
    }

    function _generateTokenIds(
        address creator,
        uint256[] memory supplies,
        uint40 packId
    ) internal view returns (uint256[] memory) {
        uint16 numTokenTypes = uint16(supplies.length);
        uint256[] memory ids = new uint256[](numTokenTypes);
        uint16 numNFTs = 0;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            if (numNFTs == 0) {
                if (supplies[i] == 1) {
                    numNFTs = uint16(numTokenTypes - i);
                }
            } else {
                require(supplies[i] == 1, "NFTS_MUST_BE_LAST");
            }
        }
        uint16 numFTs = numTokenTypes - numNFTs;
        for (uint16 i = 0; i < numTokenTypes; i++) {
            ids[i] = _generateTokenId(creator, supplies[i], packId, numFTs, i);
        }
        return ids;
    }

    function _generateTokenId(
        address creator,
        uint256 supply,
        uint40 packId,
        uint16 numFTs,
        uint16 packIndex
    ) internal view returns (uint256) {
        require(supply > 0 && supply <= ERC1155ERC721Helper.MAX_SUPPLY, "SUPPLY_OUT_OF_BOUNDS");
        require(numFTs >= 0 && numFTs <= ERC1155ERC721Helper.MAX_NUM_FT, "NUM_FT_OUT_OF_BOUNDS");
        return
            uint256(uint160(creator)) *
            ERC1155ERC721Helper.CREATOR_OFFSET_MULTIPLIER + // CREATOR uint160
            (supply == 1 ? uint256(1) * ERC1155ERC721Helper.IS_NFT_OFFSET_MULTIPLIER : 0) + // minted as NFT(1)|FT(0), 1 bit
            uint256(_chainIndex) *
            ERC1155ERC721Helper.CHAIN_INDEX_OFFSET_MULTIPLIER + // mainnet = 0, polygon = 1, uint8
            uint256(packId) *
            ERC1155ERC721Helper.PACK_ID_OFFSET_MULTIPLIER + // packId (unique pack), uint40
            numFTs *
            ERC1155ERC721Helper.PACK_NUM_FT_TYPES_OFFSET_MULTIPLIER + // number of fungible token in the pack, 12 bits
            packIndex; // packIndex (position in the pack), 11 bits
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "../../../common/fx-portal/FxBaseChildTunnelUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "../../../common/interfaces/IPolygonAssetERC1155.sol";
import "../../common/ERC1155Receiver.sol";
import "../../../common/BaseWithStorage/ERC2771/ERC2771HandlerUpgradeable.sol";

import "./PolygonAssetERC1155.sol";

/// @title ASSETERC1155 bridge on L2
contract PolygonAssetERC1155Tunnel is
    Initializable,
    FxBaseChildTunnelUpgradeable,
    ERC1155Receiver,
    ERC2771HandlerUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable
{
    IPolygonAssetERC1155 public childToken;
    uint256 public maxTransferLimit;
    bool private fetchingAssets;
    bytes4 internal constant ERC165ID = 0x01ffc9a7;
    bytes4 internal constant ERC1155_IS_RECEIVER = 0x4e2312e0;

    event SetTransferLimit(uint256 limit);
    event Deposit(address indexed user, uint256 indexed id, uint256 value, bytes data);
    event Withdraw(address indexed user, uint256 indexed id, uint256 value, bytes data);

    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(
        address _fxChild,
        IPolygonAssetERC1155 _childToken,
        address trustedForwarder,
        uint256 _maxTransferLimit
    ) public initializer {
        require(address(_childToken) != address(0), "PolygonAssetERC1155Tunnel: _childToken can't be zero");
        require(_fxChild != address(0), "PolygonAssetERC1155Tunnel: _fxChild can't be zero");
        require(trustedForwarder != address(0), "PolygonAssetERC1155Tunnel: trustedForwarder can't be zero");
        require(_maxTransferLimit > 0, "PolygonAssetERC1155Tunnel: _maxTransferLimit invalid");
        childToken = _childToken;
        maxTransferLimit = _maxTransferLimit;
        __Ownable_init();
        __Pausable_init();
        __ERC2771Handler_initialize(trustedForwarder);
        __FxBaseChildTunnelUpgradeable_initialize(_fxChild);
    }

    function setTransferLimit(uint256 _maxTransferLimit) external onlyOwner {
        require(_maxTransferLimit > 0, "PolygonAssetERC1155Tunnel: _maxTransferLimit invalid");
        maxTransferLimit = _maxTransferLimit;
        emit SetTransferLimit(_maxTransferLimit);
    }

    function batchWithdrawToRoot(
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) external whenNotPaused {
        require(to != address(0), "PolygonAssetERC1155Tunnel: to can't be zero");
        require(ids.length > 0, "MISSING_TOKEN_IDS");
        require(ids.length <= maxTransferLimit, "EXCEEDS_TRANSFER_LIMIT");
        bytes32[] memory metadataHashes = new bytes32[](ids.length);
        fetchingAssets = true;
        for (uint256 i = 0; i < ids.length; i++) {
            bytes32 metadataHash = childToken.metadataHash(ids[i]);
            metadataHashes[i] = metadataHash;
            bytes memory metadata = abi.encode(metadataHash);
            childToken.safeTransferFrom(_msgSender(), address(this), ids[i], values[i], abi.encode(metadataHash));
            emit Withdraw(to, ids[i], values[i], metadata);
        }
        fetchingAssets = false;
        _sendMessageToRoot(abi.encode(to, ids, values, abi.encode(metadataHashes)));
    }

    /// @dev Change the address of the trusted forwarder for meta-TX
    /// @param trustedForwarder The new trustedForwarder
    function setTrustedForwarder(address trustedForwarder) external onlyOwner {
        require(trustedForwarder != address(0), "PolygonAssetERC1155Tunnel: trustedForwarder can't be zero");
        _trustedForwarder = trustedForwarder;
    }

    /// @dev Pauses all token transfers across bridge
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @dev Unpauses all token transfers across bridge
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    function _processMessageFromRoot(
        uint256, /* stateId */
        address sender,
        bytes memory data
    ) internal override validateSender(sender) {
        _syncDeposit(data);
    }

    function _syncDeposit(bytes memory syncData) internal {
        (address to, uint256[] memory ids, uint256[] memory values, bytes memory data) =
            abi.decode(syncData, (address, uint256[], uint256[], bytes));
        bytes32[] memory metadataHashes = abi.decode(data, (bytes32[]));
        for (uint256 i = 0; i < ids.length; i++) {
            bytes memory metadata = abi.encode(metadataHashes[i]);
            if (childToken.doesHashExist(ids[i])) {
                _depositMinted(to, ids[i], values[i], metadata);
            } else {
                childToken.mint(to, ids[i], values[i], metadata);
            }
            emit Deposit(to, ids[i], values[i], metadata);
        }
    }

    function _depositMinted(
        address to,
        uint256 id,
        uint256 value,
        bytes memory data
    ) internal {
        uint256 balance = childToken.balanceOf(address(this), id);
        if (balance >= value) {
            childToken.safeTransferFrom(address(this), to, id, value, data);
        } else {
            if (balance > 0) childToken.safeTransferFrom(address(this), to, id, balance, data);
            childToken.mintDeficit(to, id, (value - balance));
        }
    }

    function _msgSender()
        internal
        view
        override(ContextUpgradeable, ERC2771HandlerUpgradeable)
        returns (address sender)
    {
        return ERC2771HandlerUpgradeable._msgSender();
    }

    function _msgData() internal view override(ContextUpgradeable, ERC2771HandlerUpgradeable) returns (bytes calldata) {
        return ERC2771HandlerUpgradeable._msgData();
    }

    function onERC1155Received(
        address, /*_operator*/
        address, /*_from*/
        uint256, /*_id*/
        uint256, /*_value*/
        bytes calldata /*_data*/
    ) external view override returns (bytes4) {
        require(fetchingAssets == true, "PolygonAssetERC1155Tunnel: can't directly send Assets");
        return this.onERC1155Received.selector; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address, /*_operator*/
        address, /*_from*/
        uint256[] calldata, /*_ids*/
        uint256[] calldata, /*_values*/
        bytes calldata /*_data*/
    ) external view override returns (bytes4) {
        require(fetchingAssets == true, "PolygonAssetERC1155Tunnel: can't directly send Assets");
        return this.onERC1155BatchReceived.selector; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }

    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == ERC1155_IS_RECEIVER || interfaceId == ERC165ID;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-0.8/token/ERC1155/IERC1155Receiver.sol";

abstract contract ERC1155Receiver is IERC1155Receiver {
    function onERC1155Received(
        address, /* operator */
        address, /* from */
        uint256, /* id */
        uint256, /* value */
        bytes calldata /* data */
    ) external view virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address, /* operator */
        address, /* from */
        uint256[] calldata, /* ids */
        uint256[] calldata, /* values */
        bytes calldata /* data */
    ) external view virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}