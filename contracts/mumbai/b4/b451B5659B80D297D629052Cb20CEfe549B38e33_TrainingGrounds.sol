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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./UtilitiesUpgradeable.sol";

// Do not add state to this contract.
//
contract AdminableUpgradeable is UtilitiesUpgradeable {

    mapping(address => bool) private admins;

    function __Adminable_init() internal initializer {
        UtilitiesUpgradeable.__Utilities__init();
    }

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function addAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function removeAdmins(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            admins[_addresses[i]] = false;
        }
    }

    function setPause(bool _shouldPause) external onlyAdminOrOwner {
        if(_shouldPause) {
            _pause();
        } else {
            _unpause();
        }
    }

    function isAdmin(address _address) public view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UtilitiesUpgradeable is Initializable, OwnableUpgradeable, PausableUpgradeable {

    function __Utilities__init() internal initializer {
        OwnableUpgradeable.__Ownable_init();
        PausableUpgradeable.__Pausable_init();

        _pause();
    }

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier onlyEOA() {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRandomizerCL {
    // Returns a request ID for the random number. This should be kept and mapped to whatever the contract
    // is tracking randoms for.
    // Admin only.
    function getRandomNumber() external returns(bytes32);

    // Returns the random for the given request ID.
    // Will revert if the random is not ready.
    function randomForRequestID(bytes32 _requestID) external view returns(uint256);

    // Returns if the request ID has been fulfilled yet.
    function isRequestIDFulfilled(bytes32 _requestID) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDragonStakable {
    function stake(uint256 _tokenId, address _owner) external;
    function unstake(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWizardStakable {
    function startStake(uint256 _tokenId, address _owner) external;
    function finishStake(uint256 _tokenId) external;

    function startUnstake(uint256 _tokenId) external;
    function finishUnstake(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IGP is IERC20Upgradeable {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ISacrificialAlter is IERC1155Upgradeable {
    function mint(uint256 typeId, uint16 qty, address recipient) external;
    function burn(uint256 typeId, uint16 qty, address burnFrom) external;
    function adminSafeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount) external;
    function adminSafeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IWnDRoot {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function getTokenTraits(uint256 _tokenId) external returns(WizardDragon memory);
    function ownerOf(uint256 _tokenId) external returns(address);
    function approve(address _to, uint256 _tokenId) external;
}

interface IWnD is IERC721EnumerableUpgradeable {
    function mint(address _to, uint256 _tokenId, WizardDragon calldata _traits) external;
    function burn(uint256 _tokenId) external;
    function isWizard(uint256 _tokenId) external view returns(bool);
    function getTokenTraits(uint256 _tokenId) external view returns(WizardDragon memory);
    function exists(uint256 _tokenId) external view returns(bool);
    function adminTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

struct WizardDragon {
    bool isWizard;
    uint8 body;
    uint8 head;
    uint8 spell;
    uint8 eyes;
    uint8 neck;
    uint8 mouth;
    uint8 wand;
    uint8 tail;
    uint8 rankIndex;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrainingGame {

    // Trains the given wizard. Must be staked at the training grounds.
    function train(uint256 _tokenId, bool equipWizard) external;

    // Trains the given wizards. Must be staked at the training grounds.
    function trainBatch(TrainingInfo[] calldata _tokensToTrain) external;

    // Reveals the reward for the given token id.
    function revealTrainingReward(uint256 _tokenId) external;


    // Reveals the rewards for the given token ids.
    function revealTrainingRewardBatch(uint256[] calldata _tokenIds) external;

    // Indicates if the given wizard can play the game.
    function canWizardPlay(uint256 _tokenId) external view returns(bool);

    // Returns the timestamp the wizard can next play the game. May be in the past.
    function timeWizardCanPlayNext(uint256 _tokenId) external view returns(uint256);

    // Returns if a wizard is currently training.
    function isWizardTraining(uint256 _tokenId) external view returns(bool);

    // Resets the stats of the Wizard
    function resetWizard(uint256 _tokenId) external;
}

struct TrainingInfo {
    uint256 tokenId;
    bool isEquipped;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/IWizardStakable.sol";
import "../shared/IDragonStakable.sol";

interface ITrainingGrounds is IWizardStakable, IDragonStakable {

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ITrainingGrounds.sol";
import "./TrainingGroundsDragonStakable.sol";
import "./TrainingGroundsWizardStakable.sol";

contract TrainingGrounds is Initializable, TrainingGroundsDragonStakable, TrainingGroundsWizardStakable {

    function initialize() external initializer {
        TrainingGroundsDragonStakable.__TrainingGroundsDragonStakable_init();
        TrainingGroundsWizardStakable.__TrainingGroundsWizardStakable_init();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./ITrainingGrounds.sol";
import "./TrainingGroundsState.sol";
import "../../shared/randomizercl/IRandomizerCL.sol";
import "../world/IWorld.sol";
import "../tokens/sacrificialalter/ISacrificialAlter.sol";
import "../tokens/gp/IGP.sol";
import "../trainingproficiency/ITrainingProficiency.sol";
import "../traininggame/ITrainingGame.sol";

abstract contract TrainingGroundsContracts is Initializable, ITrainingGrounds, TrainingGroundsState {

    function __TrainingGroundsContracts_init() internal initializer {
        TrainingGroundsState.__TrainingGroundsState_init();
    }

    function setContracts(address _worldAddress, address _sacrificialAlterAddress, address _gpAddress, address _trainingProficiencyAddress, address _trainingGameAddress, address _randomizerAddress) external onlyAdminOrOwner {
        require(_worldAddress != address(0)
            && _gpAddress != address(0)
            && _trainingProficiencyAddress != address(0)
            && _trainingGameAddress != address(0)
            && _randomizerAddress != address(0)
            && _sacrificialAlterAddress != address(0), "Bad address.");

        world = IWorld(_worldAddress);
        sacrificialAlter = ISacrificialAlter(_sacrificialAlterAddress);
        gp = IGP(_gpAddress);
        trainingProficiency = ITrainingProficiency(_trainingProficiencyAddress);
        trainingGame = ITrainingGame(_trainingGameAddress);
        randomizer = IRandomizerCL(_randomizerAddress);
    }

    modifier contractsAreSet() {
        require(areContractsSet(), "TrainingGrounds: Contracts not set");

        _;
    }

    function areContractsSet() public view returns(bool) {
        return address(world) != address(0)
            && address(gp) != address(0)
            && address(trainingProficiency) != address(0)
            && address(trainingGame) != address(0)
            && address(randomizer) != address(0)
            && address(sacrificialAlter) != address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TrainingGroundsContracts.sol";
import "../world/IWorld.sol";

abstract contract TrainingGroundsDragonStakable is Initializable, TrainingGroundsContracts {

    function __TrainingGroundsDragonStakable_init() internal initializer {
        TrainingGroundsContracts.__TrainingGroundsContracts_init();
    }

    function stake(uint256 _tokenId, address _owner) external override onlyAdminOrOwner contractsAreSet {
        // Nothing needed except for adding the dragon to the world at the right location.
        // This will also transfer the token.
        world.addDragonToWorld(_tokenId, _owner, Location.TRAINING_GROUNDS);
    }

    function unstake(uint256 _tokenId) external override onlyAdminOrOwner contractsAreSet {
        // Nothing needed except for removing the dragon from the world and transferring it to the existing owner.

        address _owner = world.ownerOfTokenId(_tokenId);
        world.removeDragonFromWorld(_tokenId, _owner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../shared/AdminableUpgradeable.sol";
import "../tokens/wnd/IWnD.sol";
import "../tokens/gp/IGP.sol";
import "../tokens/sacrificialalter/ISacrificialAlter.sol";
import "../world/IWorld.sol";
import "../trainingproficiency/ITrainingProficiency.sol";
import "../traininggame/ITrainingGame.sol";
import "../../shared/randomizercl/IRandomizerCL.sol";

contract TrainingGroundsState is Initializable, AdminableUpgradeable {

    event WizardStakingStart(address indexed _owner, uint256 indexed _tokenId, bytes32 indexed _requestId);
    event WizardStakingFinish(address indexed _owner, uint256 indexed _tokenId);

    event WizardUnstakingStart(address indexed _owner, uint256 indexed _tokenId, bytes32 indexed _requestId);
    event WizardUnstakingFinish(address indexed _owner, uint256 indexed _tokenId);

    event WizardStolen(address indexed _oldOwner, address indexed _newOwner, uint256 indexed _tokenId);
    event ChestStolen(address indexed _oldOwner, address indexed _newOwner, uint256 indexed _savedTokenId);

    mapping(uint256 => uint256) public tokenIdToTimeStaked;
    uint256 public wizardStakingCost;
    // The chance of being stolen out of 100
    uint8 public chanceWizardStolen;
    uint256 public minTimeStaked;
    uint256 public treasureChestId;
    IWorld public world;
    ISacrificialAlter public sacrificialAlter;
    IGP public gp;
    ITrainingProficiency public trainingProficiency;
    ITrainingGame public trainingGame;
    IRandomizerCL public randomizer;

    // Holds the commit ids for random numbers when staking or unstaking.
    mapping(uint256 => bytes32) internal tokenIdToRequestId;

    function __TrainingGroundsState_init() internal initializer {
        AdminableUpgradeable.__Adminable_init();

        wizardStakingCost = 8000 ether;
        chanceWizardStolen = 10;
        minTimeStaked = 2 days;
        treasureChestId = 5;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./TrainingGroundsContracts.sol";
import "../world/IWorld.sol";

abstract contract TrainingGroundsWizardStakable is TrainingGroundsContracts {

    function __TrainingGroundsWizardStakable_init() internal initializer {
        TrainingGroundsContracts.__TrainingGroundsContracts_init();
    }

    function setStakingSettings(uint256 _wizardStakingCost, uint8 _chanceWizardStolen, uint256 _minTimeStaked, uint256 _treasureChestId) external onlyAdminOrOwner {
        require(_chanceWizardStolen <= 100, "Bad stolen chance");
        wizardStakingCost = _wizardStakingCost;
        chanceWizardStolen = _chanceWizardStolen;
        treasureChestId = _treasureChestId;
        minTimeStaked = _minTimeStaked;
    }

    function startStake(uint256 _tokenId, address _owner) external override onlyAdminOrOwner contractsAreSet {
        _startStakingOrUnstaking(_tokenId, _owner, true);
    }

    function finishStake(uint256 _tokenId) public override onlyAdminOrOwner contractsAreSet {
        _finishStakingOrUnstaking(_tokenId, true);
    }

    function startUnstake(uint256 _tokenId) external override onlyAdminOrOwner contractsAreSet {
        uint256 _timeStaked = tokenIdToTimeStaked[_tokenId];
        require(block.timestamp > _timeStaked + minTimeStaked, "Stake longer");

        require(!trainingGame.isWizardTraining(_tokenId), "Can't unstake while training");

        address _currentOwner = world.ownerOfTokenId(_tokenId);

        _startStakingOrUnstaking(_tokenId, _currentOwner, false);
    }

    function finishUnstake(uint256 _tokenId) external override onlyAdminOrOwner contractsAreSet {
        _finishStakingOrUnstaking(_tokenId, false);
    }

    function requestIdForTokenId(uint256 _tokenId) public view returns(bytes32) {
        return tokenIdToRequestId[_tokenId];
    }

    function _startStakingOrUnstaking(uint256 _tokenId, address _owner, bool _isStaking) private {
        if(_tokenId <= 15000) {
            require(gp.balanceOf(_owner) >= wizardStakingCost, "Not enough GP");
            // Burn the fee.
            gp.burn(_owner, wizardStakingCost);
        }

        if(_isStaking) {
            // This will transfer the wizard to the world contract
            world.addWizardToWorld(_tokenId, _owner, Location.TRAINING_GROUNDS_ENTERING);
        } else {
            world.changeLocationOfWizard(_tokenId, Location.TRAINING_GROUNDS_LEAVING);
        }


        if(_canWizardGetStolen(_tokenId)) {
            bytes32 _requestId = randomizer.getRandomNumber();
            tokenIdToRequestId[_tokenId] = _requestId;

            if(_isStaking) {
                emit WizardStakingStart(_owner, _tokenId, _requestId);
            } else {
                emit WizardUnstakingStart(_owner, _tokenId, _requestId);
            }
        } else {
            // Wizard can't be stolen, so there is no point in waiting for a random number.
            _finalizeStakingOrUnstaking(_owner, _tokenId, _isStaking);
        }
    }

    function _finishStakingOrUnstaking(uint256 _tokenId, bool _isStaking) private {
        bytes32 _requestId = requestIdForTokenId(_tokenId);
        require(randomizer.isRequestIDFulfilled(_requestId), "Not ready");
        delete tokenIdToRequestId[_tokenId];

        address _tokenOwner = world.ownerOfTokenId(_tokenId);

        uint256 _randomness = randomizer.randomForRequestID(_requestId);

        uint256 _result = _randomness % 100;
        uint8 _wizardProf = trainingProficiency.proficiencyForWizard(_tokenId);
        uint8 _maxRemoval = _wizardProf > 8 ? 8 : _wizardProf;

        uint256 _chanceWizardStolen = chanceWizardStolen - _maxRemoval;
        if(world.totalNumberOfDragons() != 0 && _result < _chanceWizardStolen) {
            // Got stolen. Get bent.
            // The dragons number is fluctuating so using the same seed should be okay.
            address _dragonOwner = world.getRandomDragonOwner(_randomness, Location.TRAINING_GROUNDS);

            bool _hasChest = sacrificialAlter.balanceOf(_tokenOwner, treasureChestId) > 0;

            // Just look at the top bit for the 50/50 odds of stealing the chest
            if(_hasChest && _randomness >> 255 == 1) {
                sacrificialAlter.adminSafeTransferFrom(_tokenOwner, _dragonOwner, treasureChestId, 1);
                emit ChestStolen(_tokenOwner, _dragonOwner, _tokenId);

                _finalizeStakingOrUnstaking(_tokenOwner, _tokenId, _isStaking);
            } else {
                world.removeWizardFromWorld(_tokenId, _dragonOwner);
                emit WizardStolen(_tokenOwner, _dragonOwner, _tokenId);
            }
        } else {
            _finalizeStakingOrUnstaking(_tokenOwner, _tokenId, _isStaking);
        }
    }

    function _finalizeStakingOrUnstaking(address _owner, uint256 _tokenId, bool _isStaking) private {
        if(_isStaking) {
            tokenIdToTimeStaked[_tokenId] = block.timestamp;
            world.changeLocationOfWizard(_tokenId, Location.TRAINING_GROUNDS);
            emit WizardStakingFinish(_owner, _tokenId);
        } else {
            delete tokenIdToTimeStaked[_tokenId];
            world.removeWizardFromWorld(_tokenId, _owner);
            emit WizardUnstakingFinish(_owner, _tokenId);
        }
    }

    function _canWizardGetStolen(uint256 _tokenId) private view returns(bool) {
        return chanceWizardStolen != 0
            && world.totalNumberOfDragons() != 0
            && _tokenId > 15000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITrainingProficiency {

    // Returns the proficiency for the given Wizard.
    function proficiencyForWizard(uint256 _tokenId) external view returns(uint8);

    // Increases the proficiency of the given wizard by 1.
    // Only admin.
    function increaseProficiencyForWizard(uint256 _tokenId) external;
    // Resets the proficiency of the given wizard.
    // Only admin.
    function resetProficiencyForWizard(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWorldReadOnly {
    // Returns the total number of wizards staked somewhere in the world. Does not include in route wizards.
    function totalNumberOfWizards() external view returns(uint256);

    // Returns the total number of dragons staked somewhere in the world.
    function totalNumberOfDragons() external view returns(uint256);

    // Returns the location of the token. If it returns NONEXISTENT, the token is not staked in the world.
    function locationOfToken(uint256 _tokenId) external view returns(Location);

    // Returns if the token exists in the world. This also means the world contract holds the token.
    function isTokenInWorld(uint256 _tokenId) external view returns(bool);

    function getStakeableDragonLocations() external view returns(Location[] memory);

    function numberOfDragonsStakedAtRank(uint256 _rank) external view returns(uint256);

    // Returns the number of dragons that are staked at the given location and rank.
    function numberOfDragonsStakedAtLocationAtRank(Location _location, uint256 _rank) external view returns(uint256);

    // Returns the number of wizards that are staked at the given location.
    function numberOfWizardsStakedAtLocation(Location _location) external view returns(uint256);

    // Returns the dragon ID that is at the given location at the given index. Will revert if invalid index.
    function dragonAtLocationAtRankAtIndex(Location _location, uint256 _rank, uint256 _index) external view returns(uint256);

    // Returns the wizard ID that is at the given location at the given index. Will revert if invalid index.
    function wizardAtLocationAtIndex(Location _location, uint256 _index) external view returns(uint256);

    // Returns all dragons at the given location for the given owner. Avoid using in a contract-to-contract call.
    function getDragonsAtLocationForOwner(Location _location, address _owner) external view returns(uint256[] memory);

    // Returns all dragons at the given location for the given owner. Avoid using in a contract-to-contract call.
    function getWizardsAtLocationForOwner(Location _location, address _owner) external view returns(uint256[] memory);

    // The owner of the given token.
    function ownerOfTokenId(uint256 _tokenId) external view returns(address);

    // Returns if the passed in address is the owner of the token id.
    function isOwnerOfTokenId(uint256 _tokenId, address _owner) external view returns(bool);

    // Returns a random dragon owner based on the given seed.
    // Dragons that are staked at the given location have an increased odds of being selected.
    // If _locationOfEvent is set to NONEXISTENT, all dragons staked in the world will have the same odds.
    // If this function returns 0, there was not a random dragon staked.
    function getRandomDragonOwner(uint256 _randomSeed, Location _locationOfEvent) external view returns(address);
}

interface IWorldEditable {

    // Begins staking the given wizard at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function startStakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Finishes the stake for the given wizard ID. Must be called after the random has been seeded.
    function finishStakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Unstakes the given wizard from the given location.
    // May revert for various reasons.
    function startUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Finishes the unstake process for the given wizard id. Must be called after the random has been seeded.
    function finishUnstakeWizards(uint256[] calldata _tokenIds, Location _location) external;

    // Stakes the given dragon at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function stakeDragons(uint256[] calldata _tokenIds, Location _location) external;

    // Unstakes the given dragon at the given location. Must be approved to transfer from their wallet to this contract.
    // May revert for various reasons.
    function unstakeDragons(uint256[] calldata _tokenIds, Location _location) external;

    // When calling, should already have ensured this is a wizard and is not in the world already.
    // Transfers the 721 to the world contract.
    // Admin only.
    function addWizardToWorld(uint256 _tokenId, address _owner, Location _location) external;

    // When calling, should already have ensured this is a wizard and is not in the world already.
    // Transfers the 721 to the world contract.
    // Admin only.
    function addDragonToWorld(uint256 _tokenId, address _owner, Location _location) external;

    // Game logic should already validate that this is an option.
    // Transfers the 721 to the _owner.
    // Admin only.
    function removeWizardFromWorld(uint256 _tokenId, address _owner) external;

    // Game logic should already validate that this is an option.
    // Transfers the 721 to the _owner.
    // Admin only.
    function removeDragonFromWorld(uint256 _tokenId, address _owner) external;

    // When calling, game logic should already validate who owns the token, if they have permission, and that
    // the destination location makes sense.
    // Only callable by admin/owner.
    function changeLocationOfWizard(uint256 _tokenId, Location _location) external;

    function setStakeableDragonLocations(Location[] calldata _locations) external;
}

interface IWorld is IWorldEditable, IWorldReadOnly {

}

enum Location {
    NONEXISTENT,
    RIFT,
    TRAINING_GROUNDS_ENTERING,
    TRAINING_GROUNDS,
    TRAINING_GROUNDS_LEAVING
}