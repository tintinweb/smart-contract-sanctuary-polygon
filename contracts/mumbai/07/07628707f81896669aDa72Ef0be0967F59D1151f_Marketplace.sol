// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./MarketplaceStorage.sol";
import "../interfaces/IAccessManager.sol";

contract Marketplace is MarketplaceStorage, ERC2771Context {

  using Address for address;
  
  bytes4 public immutable ERC721_INTERFACE_ID = type(IERC721).interfaceId;
  bytes4 public immutable ERC1155_INTERFACE_ID = type(IERC1155).interfaceId; 

  address private _owner;
  address private _trustedForwarder;

  constructor(address trustedForwarder) ERC2771Context(trustedForwarder) {
    _owner = msg.sender;
  }

  /**
   * @dev Used for setting new trusted forwarder address
   * @param trustedForwarder New trusted forwarder address
   */
  function setTrustedForwarded(address trustedForwarder) public {
    require(msg.sender == _owner, "Marketplace: Only owner can set trusted forwarder");
    _trustedForwarder = trustedForwarder;
  }

  /**
   * @dev Used to transfer ownership
   */
  function transferOwnership(address newOwner) public {
    require(msg.sender == _owner, "Marketplace: Only owner can transfer ownership");
    _owner = newOwner;
  }

  /**
   * @dev Used for creating a new order in the marketplace
   * @param collectionAddress The ERC721 or ERC1155 contract address
   * @param tokenId The tokenId of the NFT that is listed
   * @param amount The number of NFTs of the specified tokenId that are listed. Important in case of ERC1155, 1 for ERC721
   * @param acceptedTokens Array of all the accepted tokens for processing the order. Nulladdress signify native currency
   * @param prices Array of price required for each accepted token. The index of the price in this array should match the index of the accepted token in the acceptedTokens array
   * @param expiresAt Timestamp after which the order will expire
   * @param accessManager Address of the smart contract to be used for AccessManagement
   * @param benefitType Type of benefit to be provided to the whitelisted accounts (0: No benefit, 1: Discount, 2: Whitelist Access Only)
   * @param whitelistDiscount Percentage discount to be provided to the whitelisted accounts (if benefitType is 1)
   */
  function createOrder(
    address collectionAddress,
    uint256 tokenId,
    uint256 amount,
    address[] memory acceptedTokens,
    uint256[] memory prices,
    uint256 expiresAt,
    address accessManager,
    uint8 benefitType,
    uint256 whitelistDiscount
  ) public {
    _createOrder(collectionAddress, tokenId, amount, acceptedTokens, prices, expiresAt, accessManager, WhitelistBenefitType(benefitType), whitelistDiscount);
  }

  function _createOrder(
    address collectionAddress,
    uint256 tokenId,
    uint256 amount,
    address[] memory acceptedTokens,
    uint256[] memory prices,
    uint256 expiresAt,
    address accessManager,
    WhitelistBenefitType benefitType,
    uint256 whitelistDiscount
  ) internal {
    require(collectionAddress.isContract(), "Marketplace: Invalid collection address");

    address sender = _msgSender();
    AssetType assetType = _getAssetType(collectionAddress);
    _checkApproval(collectionAddress, tokenId, amount, sender, assetType);
    require(acceptedTokens.length > 0 && prices.length > 0, "Marketplace: Atleast one accepted token must be specified");
    require(acceptedTokens.length == prices.length, "Marketplace: Price for each token must be specified");

    bytes32 orderId = keccak256(abi.encodePacked(block.timestamp, sender, tokenId, collectionAddress, acceptedTokens, prices));
    _openOrder(orderId, tokenId, sender, collectionAddress, assetType, amount, acceptedTokens, prices, expiresAt, accessManager, benefitType, whitelistDiscount);
  }

  /**
   * @dev Cancel an already placed order
   * @param orderId The id of the order to be cancelled
   */
  function cancelOrder(bytes32 orderId) public returns(Order memory) {
    return _cancelOrder(orderId);
  }

  /**
   * @dev This function is called by the buyer to process a particular transaction
   * @param orderId The id of the order to be processed
   * @param acceptedTokenIndex The index of accepted token to be used for processing the order
   * @param signature The signature provided by the seller. Needed incase of whitelisting, otherwise can be null
   */
  function executeOrder(bytes32 orderId, uint256 acceptedTokenIndex, bytes calldata signature) public payable {
    _executeOrder(orderId, acceptedTokenIndex, signature);
  }

  /**
   * @dev Check if the passed buyer can participate in the specified order based on the provided signature
   * @param buyer The address of the concerned buyer
   * @param orderId The id of the order for which access is to be checked
   * @param signature The signature provided to the buyer by the seller
   */
  function canParticipateInTrade(address buyer, bytes32 orderId, bytes calldata signature) public view returns(bool) {
    if(orderByOrderId[orderId].whitelistingDetails.benefitType == WhitelistBenefitType.ONLY_ACCESS && !_isWhitelisted(buyer, orderId, signature)) return false;
    return true;
  }

  function _getAssetType(address collectionAddress) internal view returns(AssetType) {
    // Use the interface ID to check if the collection is ERC721 or ERC1155
    if(IERC165(collectionAddress).supportsInterface(ERC721_INTERFACE_ID)) return AssetType.ERC721;
    else if(IERC165(collectionAddress).supportsInterface(ERC1155_INTERFACE_ID)) return AssetType.ERC1155;
    else revert("Marketplace: Unknown Asset Type");
  }

  // Check if the required approvals are provided or not
  function _checkApproval(address collectionAddress, uint256 tokenId, uint256 amount, address sender, AssetType assetType) internal view {
    if(assetType == AssetType.ERC721) {
      require(IERC721(collectionAddress).ownerOf(tokenId) == sender, "Marketplace: Not owner of the token");
      require(IERC721(collectionAddress).getApproved(tokenId) == address(this), "Marketplace: Not approved to transfer token");
      require(amount == 1, "Marketplace: Invalid amount for ERC721");
    } else if(assetType == AssetType.ERC1155) {
      require(IERC1155(collectionAddress).isApprovedForAll(sender, address(this)), "Marketplace: Not approved to transfer token");
      require(IERC1155(collectionAddress).balanceOf(sender, tokenId) >= amount, "Marketplace: Insufficient balance");
    }
  }

  function _cancelOrder(bytes32 orderId) internal returns(Order memory) {
    Order memory order = orderByOrderId[orderId];
    address sender = _msgSender();
    require(sender == order.seller || order.seller == sender, "Marketplace: Not owner or seller of the order");
    _closeOrder(orderId);
    return order;
  }

  function _executeOrder(bytes32 orderId, uint256 acceptedTokenIndex, bytes calldata signature) internal {
    address buyer = _msgSender();
    Order memory order = orderByOrderId[orderId];

    require(canParticipateInTrade(buyer, orderId, signature), "Marketplace: Not whitelisted");

    address seller = order.seller;
    address usedToken = order.acceptedTokens[acceptedTokenIndex];
    uint256 price = order.prices[acceptedTokenIndex];
    uint256 expiresAt = order.expiresAt;
    WhitelistingDetails memory whitelistingDetails = order.whitelistingDetails;

    if(whitelistingDetails.benefitType == WhitelistBenefitType.DISCOUNT && _isWhitelisted(buyer, orderId, signature)) {
      uint256 discount = (price * whitelistingDetails.discountPercentage) / DISCOUNT_PERCENTAGE_DENOMINATOR;
      price = price - discount;
    }

    require(seller != buyer, "Marketplace: Seller cannot buy own order");
    require(expiresAt > block.timestamp, "Marketplace: Order expired");

    if(order.assetType == AssetType.ERC721) _executeERC721Order(order, buyer, usedToken, price);
    else if(order.assetType == AssetType.ERC1155) _executeERC1155Order(order, buyer, usedToken, price);

    _completeOrder(orderId, usedToken, price, buyer);
  }

  function _executeERC721Order(Order memory order, address buyer, address usedToken, uint256 price) internal {
    // Check if royalty exists
    (address royaltyReceiver, uint256 royaltyAmount) = IERC2981(order.collectionAddress).royaltyInfo(order.tokenId, price);
    if(royaltyReceiver == address(0)) {
      _executeERC721OrderWithoutRoyalty(order, buyer, usedToken, price);
    } else {
      _executeERC721OrderWithRoyalty(order, buyer, usedToken, price, royaltyReceiver, royaltyAmount);
    }
  }

  function _executeERC1155Order(Order memory order, address buyer, address usedToken, uint256 price) internal {
    if(usedToken == address(0)) {
      require(msg.value == price, "Marketplace: Invalid amount sent");
      IERC1155(order.collectionAddress).safeTransferFrom(order.seller, buyer, order.tokenId, order.amount, "");
      _transferNativeToken(order.seller, price);
    } else {
      // TODO: Transfer ERC20 tokens
    }
  }

  // Transfer native tokens from this smart contract to the specified address
  function _transferNativeToken(address to, uint256 amount) internal {
    Address.sendValue(payable(to), amount);
  }

  function _executeERC721OrderWithoutRoyalty(Order memory order, address buyer, address usedToken, uint256 price) internal {
    if(usedToken == address(0)) {
      require(msg.value == price, "Marketplace: Invalid amount sent");
      IERC721(order.collectionAddress).safeTransferFrom(order.seller, buyer, order.tokenId);
      _transferNativeToken(order.seller, price);
    } else {
      // TODO: Transfer ERC20 tokens
    }
  }

  function _executeERC721OrderWithRoyalty(Order memory order, address buyer, address usedToken, uint256 price, address royaltyReceiver, uint256 royaltyAmount) internal {
    uint256 sellerAmount = price - royaltyAmount;

    if(usedToken == address(0)) {
      require(msg.value == price, "Marketplace: Invalid amount sent");
      IERC721(order.collectionAddress).safeTransferFrom(order.seller, buyer, order.tokenId);
      _transferNativeToken(order.seller, sellerAmount);
      _transferNativeToken(royaltyReceiver, royaltyAmount);
    } else {}
  }

  function _isWhitelisted(address userAddress, bytes32 orderId, bytes calldata signature) internal view returns(bool) {
    address accessManager = orderByOrderId[orderId].whitelistingDetails.accessManager;
    address seller = orderByOrderId[orderId].seller;
    return IAccessManager(accessManager).isWhitelistedBy(userAddress, seller, orderId, signature);
  }

  function versionRecipient() external pure returns (string memory) {
    return "1";
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MarketplaceStorage {

  // The different types of asset that can be listed in the Marketplace Contract
  enum AssetType {
    ERC721,
    ERC1155
  }

  // The different types of Whitelisting benefits can be provided by the seller
  enum WhitelistBenefitType {
    NO_WHITE_LISTING,    // No whitelisting
    DISCOUNT,            // Whitelisted accounts get discount
    ONLY_ACCESS         // Only whitelisted individuals can participate in trade
  }

  uint256 public constant DISCOUNT_PERCENTAGE_DENOMINATOR = 10000;

  struct WhitelistingDetails {
    address accessManager;
    WhitelistBenefitType benefitType;
    uint256 discountPercentage;
  }

  struct Order {
    uint256 tokenId;
    // Owner of the NFT
    address seller;
    // NFT Contract address
    address collectionAddress;
    // Tyep of Asset
    AssetType assetType;
    // Number of asset
    uint256 amount;
    // ERC20 Token address to receive payment
    // address(0) means native token
    address[] acceptedTokens;
    // Price (in ERC20 Token)
    uint256[] prices;
    // Time when this sale ends
    uint256 expiresAt;
    // Whitelisting details
    WhitelistingDetails whitelistingDetails;
  }

  mapping(bytes32 => Order) public orderByOrderId;

  // EVENTS
  event OrderCreated(
      bytes32 indexed id,
      uint256 indexed tokenId,
      address indexed seller,
      address collectionAddress,
      AssetType assetType,
      uint256 amount,
      address[] acceptedTokens,
      uint256[] prices,
      uint256 expiresAt,
      address accessManager,
      WhitelistBenefitType benefitType,
      uint256 whitelistDiscount
  );

  event OrderSuccessful(
      bytes32 id,
      uint256 indexed tokenId,
      address collectionAddress,
      address usedToken,
      uint256 pricePaid,
      uint256 amount,
      address indexed seller,
      address indexed buyer
  );

  event OrderCancelled(
      bytes32 id,
      uint256 indexed tokenId,
      address indexed seller,
      address collectionAddress
  );

  function _openOrder(
    bytes32 _id,
    uint256 _tokenId,
    address _seller,
    address _collectionAddress,
    AssetType _assetType,
    uint256 _amount,
    address[] memory _acceptedTokens,
    uint256[] memory _prices,
    uint256 _expiresAt,
    address _accessManager,
    WhitelistBenefitType _benefitType,
    uint256 _whitelistDiscount
  ) internal {
    WhitelistingDetails memory _whitelistingDetails = WhitelistingDetails(_accessManager, _benefitType, _whitelistDiscount);
    orderByOrderId[_id] = Order({
      tokenId: _tokenId,
      seller: _seller,
      collectionAddress: _collectionAddress,
      assetType: _assetType,
      amount: _amount,
      acceptedTokens: _acceptedTokens,
      prices: _prices,
      expiresAt: _expiresAt,
      whitelistingDetails: _whitelistingDetails
    });
    emit OrderCreated(_id, _tokenId, _seller, _collectionAddress, _assetType, _amount, _acceptedTokens, _prices, _expiresAt, _accessManager, _benefitType, _whitelistDiscount);
  }

  function _closeOrder(bytes32 _orderId) internal {
    Order memory order = orderByOrderId[_orderId];
    uint256 tokenId = order.tokenId;
    address seller = order.seller;
    address collectionAddress = order.collectionAddress;
    delete orderByOrderId[_orderId];
    emit OrderCancelled(_orderId, tokenId, seller, collectionAddress);
  }

  function _completeOrder(bytes32 _orderId, address usedToken, uint256 pricePaid, address buyer) internal {
    Order memory order = orderByOrderId[_orderId];
    uint256 tokenId = order.tokenId;
    address seller = order.seller;
    address collectionAddress = order.collectionAddress;
    uint256 amount = order.amount;
    delete orderByOrderId[_orderId];
    emit OrderSuccessful(_orderId, tokenId, collectionAddress, usedToken, pricePaid, amount, seller, buyer);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAccessManager{
  function isWhitelistedBy(address userAddress, address seller, bytes32 orderId, bytes calldata signature) external view returns(bool);
}