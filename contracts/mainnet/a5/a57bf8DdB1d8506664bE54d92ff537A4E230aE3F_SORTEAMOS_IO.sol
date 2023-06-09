/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;



/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// File: @openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// File: SORTEAMOS_IO.sol



pragma solidity 0.8.19;







contract SORTEAMOS_IO is
    ERC1155,
    ERC1155Supply,
    Ownable,
    ERC1155Pausable,
    ReentrancyGuard
{
    // Variables
    string public constant name = "SORTEAMOS.IO";
    string public constant symbol = "SORT";

    // Oracle
    address private constant aggregator =
        0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
    AggregatorV3Interface internal priceOracle;

    // Metadata
    string private scURI =
        "https://bafybeiha7265s6zs6hv7g44oyxwsohfwst6kou5lj2xbvlhdmufp65kivy.ipfs.nftstorage.link/scmeta.json";

    uint256 public constant ID_V6 = 0;
    uint256 public constant ID_V8 = 1;
    uint256 public constant ID_VSPEC = 2;

    struct Stage {
        uint256 collectionId;
        uint256 end;
        uint256 price;
        string uri;
    }

    struct Collection {
        uint256 max;
        uint256 actual;
        Stage[] stages;
    }

    Collection private V6;
    Collection private V8;
    Collection private VSPEC;

    // Payments
    address payable private payments;

    // Royalty
    address payable public royaltyRecipient;
    uint256 public royaltyPercentage;

    mapping(address => bool) public whitelist;
    bool public whitelistEnabled = true;
    bool private preminted = false;

    // constructor
    constructor(address paymentAddress, uint256 royaltyPoints) ERC1155("") {
        require(paymentAddress != address(0), "Payment address incorrecta.");
        require(royaltyPoints > 0, "Royalty points incorrectos.");
        priceOracle = AggregatorV3Interface(aggregator);

        // Inicializar V6
        V6.max = 900;
        V6.actual = 0;

        V6.stages.push(
            Stage({
                collectionId: 1,
                end: 450,
                price: 165,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V6_1.json"
            })
        );
        V6.stages.push(
            Stage({
                collectionId: 2,
                end: 700,
                price: 175,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V6_2.json"
            })
        );
        V6.stages.push(
            Stage({
                collectionId: 3,
                end: 900,
                price: 195,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V6_3.json"
            })
        );

        // Inicializar V8
        V8.max = 475;
        V8.actual = 0;

        V8.stages.push(
            Stage({
                collectionId: 4,
                end: 250,
                price: 275,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V8_1.json"
            })
        );
        V8.stages.push(
            Stage({
                collectionId: 5,
                end: 375,
                price: 285,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V8_2.json"
            })
        );
        V8.stages.push(
            Stage({
                collectionId: 6,
                end: 475,
                price: 305,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/V8_3.json"
            })
        );

        // Inicializar VSPEC
        VSPEC.max = 7;
        VSPEC.actual = 0;

        VSPEC.stages.push(
            Stage({
                collectionId: 7,
                end: 7,
                price: 1086,
                uri: "https://bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy.ipfs.nftstorage.link/ipfs/bafybeib4jolzr5yov2bolkl4lenjuaduymqvhtyi2hvpmwfrhxatrrbovy/VSPEC.json"
            })
        );

        // Pagos y royalties
        payments = payable(paymentAddress);
        royaltyRecipient = payable(
            address(0x3A7cEED33aa8D5fEdefbdeEc1aF5B5B1318ef5f8)
        );
        royaltyPercentage = royaltyPoints;
    }

    // -------------------------------------------------
    // ----------------- Modifiers ---------------------
    // -------------------------------------------------
    modifier isValidCollection(uint256 collection) {
        require(
            (collection == ID_V6) ||
                (collection == ID_V8) ||
                (collection == ID_VSPEC),
            "Colleccion no valida."
        );
        _;
    }

    modifier isValidIdCollection(uint256 collectionId) {
        require(
            (collectionId >= 1) && (collectionId <= 7),
            "Collection ID no valido."
        );
        _;
    }

    // -------------------------------------------------
    // ----------------- Functions ---------------------
    // -------------------------------------------------

    function execPremint() external onlyOwner {
        require(!preminted, "El premint ya fue ejecutado.");
        // Premint + collabs
        internalMint(ID_V6, 150, 0xd1e5bCaAc9f79064dd49cD5c78101C557886eCd1);
        internalMint(ID_V8, 100, 0xd1e5bCaAc9f79064dd49cD5c78101C557886eCd1);
        preminted = true;
    }

    function toggleWhitelist() external onlyOwner {
        whitelistEnabled = !whitelistEnabled;
    }

    function bulkWhitelist(
        address[] calldata _addresses,
        bool _whitelist
    ) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = _whitelist;
        }
    }

    // Public Minting functions
    function crossMint(
        address to,
        uint256 collection,
        uint256 amount
    ) external payable isValidCollection(collection) whenNotPaused {
        require(amount > 0, "La cantidad para mintear debe ser mayor a 0.");
        require(
            checkSupply(collection, amount),
            "No queda esta cantidad de NFTs de esta collecion, prueba una cantidad menor."
        );
        require(
            checkSendedValue(collection, amount, msg.value),
            "Cantidad insuficiente de MATIC enviado."
        );

        if (whitelistEnabled) {
            require(whitelist[to], "Direccion no whitelistada.");
        }

        internalMint(collection, amount, to);
    }

    function mint(
        uint256 collection,
        uint256 amount
    ) external payable isValidCollection(collection) whenNotPaused {
        require(amount > 0, "La cantidad para mintear debe ser mayor a 0.");
        require(
            checkSupply(collection, amount),
            "No queda esta cantidad de NFTs de esta collecion, prueba una cantidad menor."
        );
        require(
            checkSendedValue(collection, amount, msg.value),
            "Cantidad insuficiente de MATIC enviado."
        );

        if (whitelistEnabled) {
            require(whitelist[_msgSender()], "Direccion no whitelistada.");
        }
        internalMint(collection, amount, _msgSender());
    }

    function adminMint(
        uint256 collection,
        uint256 amount,
        address to
    ) external onlyOwner {
        require(to != address(0), "Direccion no valida.");
        require(amount > 0, "Cantidad insuficiente.");
        require(
            checkSupply(collection, amount),
            "No queda esta cantidad de NFTs de esta collecion, prueba una cantidad menor."
        );
        internalMint(collection, amount, to);
    }

    // Internal Minting fuctions
    function getStage(
        uint256 collectionId
    ) public pure isValidIdCollection(collectionId) returns (uint256) {
        if (collectionId == 1 || collectionId == 4 || collectionId == 7)
            return 0;
        else if (collectionId == 2 || collectionId == 5) return 1;
        else if (collectionId == 3 || collectionId == 6) return 2;
        else return 8;
    }

    function getMaxSupply(
        uint256 collection
    ) external view isValidCollection(collection) returns (uint256) {
        if (collection == ID_V6) return V6.max;
        else if (collection == ID_V8) return V8.max;
        else if (collection == ID_VSPEC) return VSPEC.max;
        else return 0;
    }

    function getCollectionId(
        uint256 collection
    ) public view isValidCollection(collection) returns (uint256) {
        uint256 totalMint = 0;
        uint256 collectionId = 8;

        if (collection == ID_V6) {
            totalMint = V6.actual;
            for (uint8 i = 0; i < V6.stages.length; i++) {
                if (totalMint <= V6.stages[i].end) {
                    if (totalMint == V6.stages[i].end && i != 2)
                        collectionId = V6.stages[i + 1].collectionId;
                    else collectionId = V6.stages[i].collectionId;
                    break;
                }
            }
        } else if (collection == ID_V8) {
            totalMint = V8.actual;
            for (uint8 i = 0; i < V8.stages.length; i++) {
                if (totalMint <= V8.stages[i].end) {
                    if (totalMint == V8.stages[i].end && i != 2)
                        collectionId = V8.stages[i + 1].collectionId;
                    else collectionId = V8.stages[i].collectionId;
                    break;
                }
            }
        } else if (collection == ID_VSPEC) {
            collectionId = VSPEC.stages[0].collectionId;
        }

        return collectionId;
    }

    function getSupply(
        uint256 collection
    ) external view isValidCollection(collection) returns (uint256) {
        if (collection == ID_V6) return V6.actual;
        else if (collection == ID_V8) return V8.actual;
        else if (collection == ID_VSPEC) return VSPEC.actual;
        else return 0;
    }

    function getPrice(
        uint256 collection
    ) external view isValidCollection(collection) returns (uint256) {
        uint256 collectionId = getCollectionId(collection);
        uint256 stage = getStage(collectionId);

        if (collection == ID_V6) return V6.stages[stage].price;
        else if (collection == ID_V8) return V8.stages[stage].price;
        else if (collection == ID_VSPEC) return VSPEC.stages[stage].price;
        else return 0;
    }

    function checkSameStage(
        uint256 collection,
        uint256 amount
    ) internal view isValidCollection(collection) returns (bool) {
        uint256 collectionId = getCollectionId(collection);
        uint256 stage = getStage(collectionId);

        if (collection == ID_V6)
            return ((V6.actual + amount) <= (V6.stages[stage].end));
        else if (collection == ID_V8)
            return ((V8.actual + amount) <= (V8.stages[stage].end));
        else if (collection == ID_VSPEC)
            return ((VSPEC.actual + amount) <= (VSPEC.stages[stage].end));
        else return false;
    }

    function getTotalPrice(
        uint256 collection,
        uint256 amount
    ) external view isValidCollection(collection) returns (uint256) {
        uint256 price = 0;

        uint256 collectionId = getCollectionId(collection);
        uint256 stage = getStage(collectionId);

        if (checkSameStage(collection, amount)) {
            require(stage >= 0 && stage <= 2, "No hay mas etapas.");
            if (collection == ID_V6)
                return priceInMatic(V6.stages[stage].price) * amount;
            else if (collection == ID_V8)
                return priceInMatic(V8.stages[stage].price) * amount;
            else if (collection == ID_VSPEC)
                return priceInMatic(VSPEC.stages[stage].price) * amount;

            return price;
        } else {
            if (collection == ID_V6) {
                for (uint256 i = 1; i <= amount; ++i) {
                    if (V6.actual + i > V6.stages[stage].end) stage++;
                    price += V6.stages[stage].price;
                }
                return priceInMatic(price);
            } else if (collection == ID_V8) {
                for (uint256 i = 1; i <= amount; ++i) {
                    if (V8.actual + i > V8.stages[stage].end) stage++;
                    price += V8.stages[stage].price;
                }
                return priceInMatic(price);
            }

            return price;
        }
    }

    function checkSendedValue(
        uint256 collection,
        uint256 amount,
        uint256 value
    ) internal view isValidCollection(collection) returns (bool) {
        uint256 price = 0;

        uint256 collectionId = getCollectionId(collection);
        uint256 stage = getStage(collectionId);

        if (checkSameStage(collection, amount)) {
            require(stage >= 0 && stage <= 2, "No hay mas etapas.");
            if (collection == ID_V6)
                return (value >=
                    (priceInMatic(V6.stages[stage].price) * amount));
            else if (collection == ID_V8)
                return (value >=
                    (priceInMatic(V8.stages[stage].price) * amount));
            else if (collection == ID_VSPEC)
                return (value >=
                    (priceInMatic(VSPEC.stages[stage].price) * amount));

            return false;
        } else {
            if (collection == ID_V6) {
                for (uint256 i = 1; i <= amount; ++i) {
                    if (V6.actual + i > V6.stages[stage].end) stage++;
                    price += V6.stages[stage].price;
                }
                return (value >= priceInMatic(price));
            } else if (collection == ID_V8) {
                for (uint256 i = 1; i <= amount; ++i) {
                    if (V8.actual + i > V8.stages[stage].end) stage++;
                    price += V8.stages[stage].price;
                }
                return (value >= priceInMatic(price));
            }

            return false;
        }
    }

    function internalMint(
        uint256 collection,
        uint256 amount,
        address wallet
    ) internal nonReentrant isValidCollection(collection) {
        require(checkSupply(collection, amount), "Coleccion agotada.");
        require(wallet != address(0), "Direccion invalida.");
        uint256 collectionId = getCollectionId(collection);

        if (checkSameStage(collection, amount)) {
            _mint(wallet, collectionId, amount, "");
            if (collection == ID_V6) V6.actual += amount;
            else if (collection == ID_V8) V8.actual += amount;
            else if (collection == ID_VSPEC) VSPEC.actual += amount;
        } else {
            uint256 stage = getStage(collectionId);
            uint256 minted = 0;
            uint256 rest = amount;

            if (collection == ID_V6) {
                for (uint256 i = 0; i < amount; i += minted) {
                    if (V6.actual >= V6.stages[stage].end) {
                        collectionId = getCollectionId(collection);
                        stage = getStage(collectionId);
                    }
                    if (rest > 0) {
                        if (checkSameStage(collection, rest)) minted = rest;
                        else minted = V6.stages[stage].end - V6.actual;
                        _mint(wallet, collectionId, minted, "");
                        V6.actual += minted;
                        rest -= minted;
                    }
                }
            } else if (collection == ID_V8) {
                for (uint256 i = 0; i < amount; i += minted) {
                    if (V8.actual >= V8.stages[stage].end) {
                        collectionId = getCollectionId(collection);
                        stage = getStage(collectionId);
                    }
                    if (rest > 0) {
                        if (checkSameStage(collection, rest)) minted = rest;
                        else minted = V8.stages[stage].end - V8.actual;
                        _mint(wallet, collectionId, minted, "");
                        V8.actual += minted;
                        rest -= minted;
                    }
                }
            }
        }
    }

    // Supply general de las colecciones
    function checkSupply(
        uint256 collection,
        uint256 amount
    ) internal view isValidCollection(collection) returns (bool) {
        if (collection == ID_V6) return (V6.actual + amount <= V6.max);
        else if (collection == ID_V8) return (V8.actual + amount <= V8.max);
        else if (collection == ID_VSPEC)
            return (VSPEC.actual + amount <= VSPEC.max);

        return false;
    }

    function changePrice(
        uint256 collectionId,
        uint256 newPrice
    ) external onlyOwner {
        if (collectionId == 1) {
            V6.stages[0].price = newPrice;
        } else if (collectionId == 2) {
            V6.stages[1].price = newPrice;
        } else if (collectionId == 3) {
            V6.stages[2].price = newPrice;
        } else if (collectionId == 4) {
            V8.stages[0].price = newPrice;
        } else if (collectionId == 5) {
            V8.stages[1].price = newPrice;
        } else if (collectionId == 6) {
            V8.stages[2].price = newPrice;
        } else if (collectionId == 7) {
            VSPEC.stages[0].price = newPrice;
        } else {
            revert("Collection ID no valido.");
        }
    }

    // ------------------------------------- //
    // -------------- ROYALTIES ------------ //
    // ------------------------------------- //
    function royaltyInfo(
        uint256 collectionId,
        uint salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        if (exists(collectionId))
            return (royaltyRecipient, (salePrice * royaltyPercentage) / 10000);

        return (address(0), 0);
    }

    function setRoyaltyAddress(address payable rAddress) external onlyOwner {
        require(rAddress != address(0), "Direccion invalida.");
        royaltyRecipient = rAddress;
    }

    function setRoyaltiesBasicPoints(uint96 rBasicPoints) external onlyOwner {
        royaltyPercentage = rBasicPoints;
    }

    // ------------------------------------- //
    // -------------- PAYMENTS ------------- //
    // ------------------------------------- //

    // Payments
    function withdraw() external payable nonReentrant onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No hay saldo para retirar");

        (bool success, ) = payable(payments).call{value: balance}("");
        require(success, "Retirada fallida");
    }

    function setPaymentAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Direccion no valida.");
        payments = payable(newAddress);
    }

    // ------------------------------------- //
    // -------------- METADATA ------------- //
    // ------------------------------------- //
    function contractURI() external view returns (string memory) {
        return scURI;
    }

    function setContractURI(string memory newURI) external onlyOwner {
        scURI = newURI;
    }

    function uri(
        uint256 collectionId
    ) public view override returns (string memory) {
        require(exists(collectionId), "No existe el token.");

        if (collectionId == 1) {
            return V6.stages[0].uri;
        } else if (collectionId == 2) {
            return V6.stages[1].uri;
        } else if (collectionId == 3) {
            return V6.stages[2].uri;
        } else if (collectionId == 4) {
            return V8.stages[0].uri;
        } else if (collectionId == 5) {
            return V8.stages[1].uri;
        } else if (collectionId == 6) {
            return V8.stages[2].uri;
        } else if (collectionId == 7) {
            return VSPEC.stages[0].uri;
        } else {
            revert("Token no valido.");
        }
    }

    function changeUri(
        uint256 collectionId,
        string memory newUri
    ) external onlyOwner {
        if (collectionId == 1) {
            V6.stages[0].uri = newUri;
        } else if (collectionId == 2) {
            V6.stages[1].uri = newUri;
        } else if (collectionId == 3) {
            V6.stages[2].uri = newUri;
        } else if (collectionId == 4) {
            V8.stages[0].uri = newUri;
        } else if (collectionId == 5) {
            V8.stages[1].uri = newUri;
        } else if (collectionId == 6) {
            V8.stages[2].uri = newUri;
        } else if (collectionId == 7) {
            VSPEC.stages[0].uri = newUri;
        } else {
            revert("Collection ID no valido.");
        }
    }

    // ------------------------------------- //
    // --------------- PAUSE --------------- //
    // ------------------------------------- //
    function togglePause() external onlyOwner {
        if (!paused()) _pause();
        else _unpause();
    }

    // ---------------------------------------- //
    // -------------- Overrides --------------- //
    // ---------------------------------------- //

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // ------------------------------------- //
    // -------------- ORACLE --------------- //
    // ------------------------------------- //

    function decimals() public view returns (uint8) {
        return priceOracle.decimals();
    }

    function priceInMatic(uint256 _priceDollar) public view returns (uint256) {
        require(getLatestPrice() > 0, "Precio invalido del oraculo");
        require(_priceDollar >= 0, "Precio debe ser mayor a cero");
        uint256 matic = (1 ether *
            _priceDollar *
            uint256(10 ** uint256(decimals()))) / uint256(getLatestPrice());
        require(matic >= 0, "Price must be positive");
        return matic;
    }

    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceOracle.latestRoundData();
        return price;
    }
}