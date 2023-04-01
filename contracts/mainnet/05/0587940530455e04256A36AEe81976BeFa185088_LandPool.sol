// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Context} from "@openzeppelin/contracts-442/utils/Context.sol";
import {SafeERC20} from "@openzeppelin/contracts-442/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts-442/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts-442/security/ReentrancyGuard.sol";
import {Address} from "@openzeppelin/contracts-442/utils/Address.sol";
import {Pausable} from "@openzeppelin/contracts-442/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts-442/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts-442/utils/math/Math.sol";
import {ERC2771HandlerV2} from "./lib/ERC2771HandlerV2.sol";
import {StakeTokenWrapper} from "./lib/StakeTokenWrapper.sol";
import {IContributionRules} from "./lib/IContributionRules.sol";
import {IRewardCalculator} from "./lib/IRewardCalculator.sol";
import {LockRules} from "./lib/LockRules.sol";
import {RequirementsRules} from "./lib/RequirementsRules.sol";

/// @title A pool that distributes rewards between users that stake any erc20 token
/// @notice The contributions are updated passively, an external call to computeContribution from a backend is needed.
/// @notice After initialization the reward calculator must be set by the admin.
/// @dev The contract has two plugins that affect the behaviour: contributionCalculator and rewardCalculator
/// @dev contributionCalculator instead of using the stake directly the result of computeContribution is used
/// @dev this way some users can get an extra share of the rewards
/// @dev rewardCalculator is used to manage the rate at which the rewards are distributed.
/// @dev This way we can build different types of pools by mixing in the plugins we want with this contract.
/// @dev default behaviour (address(0)) for contributionCalculator is to use the stacked amount as contribution.
/// @dev default behaviour (address(0)) for rewardCalculator is that no rewards are given
contract LandPool is
    Ownable,
    StakeTokenWrapper,
    LockRules,
    RequirementsRules,
    ReentrancyGuard,
    ERC2771HandlerV2,
    Pausable
{
    using SafeERC20 for IERC20;
    using Address for address;

    event Staked(address indexed account, uint256 stakeAmount);
    event Withdrawn(address indexed account, uint256 stakeAmount);
    event Exit(address indexed account);
    event RewardPaid(address indexed account, uint256 rewardAmount);
    event ContributionUpdated(address indexed account, uint256 newContribution, uint256 oldContribution);

    uint256 internal constant DECIMALS_18 = 1 ether;

    // This value multiplied by the user contribution is the share of accumulated rewards (from the start of time
    // until the last call to restartRewards) for the user taking into account the value of totalContributions.
    uint256 public rewardPerTokenStored;

    IERC20 public rewardToken;
    IContributionRules public contributionRules;
    IRewardCalculator public rewardCalculator;

    // This value multiplied by the user contribution is the share of reward from the the last time
    // the user changed his contribution and called restartRewards
    mapping(address => uint256) public userRewardPerTokenPaid;

    // This value is the accumulated rewards won by the user when he called the contract.
    mapping(address => uint256) public rewards;

    uint256 internal _totalContributions;
    mapping(address => uint256) internal _contributions;

    constructor(
        IERC20 stakeToken_,
        IERC20 rewardToken_,
        address trustedForwarder
    ) StakeTokenWrapper(stakeToken_) {
        require(address(rewardToken_).isContract(), "ERC20RewardPool: is not a contract");
        rewardToken = rewardToken_;
        __ERC2771HandlerV2_initialize(trustedForwarder);
    }

    // Checks that the given address is a contract and
    // that the caller of the method is the owner of this contract - ERC20RewardPool.
    modifier isContractAndAdmin(address contractAddress) {
        require(contractAddress.isContract(), "ERC20RewardPool: is not a contract");
        require(owner() == _msgSender(), "ERC20RewardPool: not admin");
        _;
    }

    modifier isValidAddress(address account) {
        require(account != address(0), "ERC20RewardPool: zero address");

        _;
    }

    /// @notice set the reward token
    /// @param contractAddress address token used to pay rewards
    function setRewardToken(address contractAddress)
        external
        isContractAndAdmin(contractAddress)
        isValidAddress(contractAddress)
    {
        IERC20 _newRewardToken = IERC20(contractAddress);
        require(
            rewardToken.balanceOf(address(this)) <= _newRewardToken.balanceOf(address(this)),
            "ERC20RewardPool: insufficient balance"
        );
        rewardToken = _newRewardToken;
    }

    /// @notice set the stake token
    /// @param contractAddress address token used to stake funds
    function setStakeToken(address contractAddress)
        external
        isContractAndAdmin(contractAddress)
        isValidAddress(contractAddress)
    {
        IERC20 _newStakeToken = IERC20(contractAddress);
        require(
            _stakeToken.balanceOf(address(this)) <= _newStakeToken.balanceOf(address(this)),
            "ERC20RewardPool: insufficient balance"
        );
        _stakeToken = _newStakeToken;
    }

    /// @notice set the trusted forwarder
    /// @param trustedForwarder address of the contract that is enabled to send meta-tx on behalf of the user
    function setTrustedForwarder(address trustedForwarder) external isContractAndAdmin(trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    /// @notice set contract that contains all the contribution rules
    function setContributionRules(address contractAddress)
        external
        isContractAndAdmin(contractAddress)
        isValidAddress(contractAddress)
    {
        contributionRules = IContributionRules(contractAddress);
    }

    /// @notice set the reward calculator
    /// @param contractAddress address of a plugin that calculates absolute rewards at any point in time
    /// @param restartRewards_ if true the rewards from the previous calculator are accumulated before changing it
    function setRewardCalculator(address contractAddress, bool restartRewards_)
        external
        isContractAndAdmin(contractAddress)
        isValidAddress(contractAddress)
    {
        // We process the rewards of the current reward calculator before the switch.
        if (restartRewards_) {
            _restartRewards();
        }
        rewardCalculator = IRewardCalculator(contractAddress);
    }

    /// @notice the admin recover is able to recover reward funds
    /// @param receiver address of the beneficiary of the recovered funds
    /// @dev this function must be called in an emergency situation only.
    /// @dev Calling it is risky specially when rewardToken == stakeToken
    function recoverFunds(address receiver) external onlyOwner whenPaused() isValidAddress(receiver) {
        uint256 recoverAmount;

        if (rewardToken == _stakeToken) {
            recoverAmount = rewardToken.balanceOf(address(this)) - _totalSupply;
        } else {
            recoverAmount = rewardToken.balanceOf(address(this));
        }

        rewardToken.safeTransfer(receiver, recoverAmount);
    }

    /// @notice return the total supply of staked tokens
    /// @return the total supply of staked tokens
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /// @notice return the balance of staked tokens for a user
    /// @param account the address of the account
    /// @return balance of staked tokens
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// @notice return the address of the stake token contract
    /// @return address of the stake token contract
    function stakeToken() external view returns (IERC20) {
        return _stakeToken;
    }

    /// @notice return the amount of rewards deposited in the contract that can be distributed by different campaigns
    /// @return the total amount of deposited rewards
    /// @dev this function can be called by a reward calculator to throw if a campaign doesn't have
    /// @dev enough rewards to start
    function getRewardsAvailable() external view returns (uint256) {
        if (address(rewardToken) != address(_stakeToken)) {
            return rewardToken.balanceOf(address(this));
        }
        return _stakeToken.balanceOf(address(this)) - _totalSupply;
    }

    /// @notice return the sum of the values returned by the contribution calculator
    /// @return total contributions of the users
    /// @dev this is the same than the totalSupply only if the contribution calculator
    /// @dev uses the staked amount as the contribution of the user which is the default behaviour
    function totalContributions() external view returns (uint256) {
        return _totalContributions;
    }

    /// @notice return the contribution of some user
    /// @param account the address of the account
    /// @return contribution of the users
    /// @dev this is the same than the balanceOf only if the contribution calculator
    /// @dev uses the staked amount as the contribution of the user which is the default behaviour
    function contributionOf(address account) external view returns (uint256) {
        return _contributions[account];
    }

    /// @notice accumulated rewards taking into account the totalContribution (see: rewardPerTokenStored)
    /// @return the accumulated total rewards
    /// @dev This value multiplied by the user contribution is the share of accumulated rewards for the user. Taking
    /// @dev into account the value of totalContributions.
    function rewardPerToken() external view returns (uint256) {
        return rewardPerTokenStored + _rewardPerToken();
    }

    /// @notice available earnings for some user
    /// @param account the address of the account
    /// @return the available earnings for the user
    function earned(address account) external view returns (uint256) {
        return rewards[account] + _earned(account, _rewardPerToken());
    }

    /// @notice accumulates the current rewards into rewardPerTokenStored and restart the reward calculator
    /// @dev calling this function makes no difference. It is useful for testing and when the reward calculator
    /// @dev is changed.
    function restartRewards() external {
        _restartRewards();
    }

    /// @notice update the contribution for a user
    /// @param account the address of the account
    /// @dev if the user change his holdings (or any other parameter that affect the contribution calculation),
    /// @dev he can the reward distribution to his favor. This function must be called by an external agent ASAP to
    /// @dev update the contribution for the user. We understand the risk but the rewards are distributed slowly so
    /// @dev the user cannot affect the reward distribution heavily.
    function computeContribution(address account) external isValidAddress(account) {
        // We decide to give the user the accumulated rewards even if he cheated a little bit.
        _processRewards(account);
        _updateContribution(account);
    }

    /// @notice update the contribution for a sef of users
    /// @param accounts the addresses of the accounts to update
    /// @dev see: computeContribution
    function computeContributionInBatch(address[] calldata accounts) external {
        _restartRewards();
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (account == address(0)) {
                continue;
            }
            _processAccountRewards(account);
            _updateContribution(account);
        }
    }

    /// @notice stake some amount into the contract
    /// @param amount the amount of tokens to stake
    /// @dev the user must approve in the stake token before calling this function
    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused()
        antiDepositCheck(_msgSender())
        checkRequirements(_msgSender(), amount, _balances[_msgSender()])
    {
        require(amount > 0, "ERC20RewardPool: Cannot stake 0");

        // The first time a user stakes he cannot remove his rewards immediately.
        if (timeLockClaim.lastClaim[_msgSender()] == 0) {
            timeLockClaim.lastClaim[_msgSender()] = block.timestamp;
        }

        lockDeposit.lastDeposit[_msgSender()] = block.timestamp;

        uint256 earlierRewards = 0;

        if (_totalContributions == 0 && rewardCalculator != IRewardCalculator(address(0))) {
            earlierRewards = rewardCalculator.getRewards();
        }

        _processRewards(_msgSender());
        super._stake(amount);
        _updateContribution(_msgSender());
        require(_contributions[_msgSender()] > 0, "ERC20RewardPool: not enough contributions");

        if (earlierRewards != 0) {
            rewards[_msgSender()] = rewards[_msgSender()] + earlierRewards;
        }
        emit Staked(_msgSender(), amount);
    }

    /// @notice withdraw the stake from the contract
    /// @param amount the amount of tokens to withdraw
    /// @dev the user can withdraw his stake independently from the rewards
    function withdraw(uint256 amount) external nonReentrant whenNotPaused() {
        _processRewards(_msgSender());
        _withdrawStake(_msgSender(), amount);
        _updateContribution(_msgSender());
    }

    /// @notice withdraw the stake and the rewards from the contract
    function exit() external nonReentrant() whenNotPaused() {
        _processRewards(_msgSender());
        _withdrawStake(_msgSender(), _balances[_msgSender()]);
        _withdrawRewards(_msgSender());
        _updateContribution(_msgSender());
        emit Exit(_msgSender());
    }

    /// @notice withdraw the rewards from the contract
    /// @dev the user can withdraw his stake independently from the rewards
    function getReward() external nonReentrant whenNotPaused() {
        _processRewards(_msgSender());
        _withdrawRewards(_msgSender());
        _updateContribution(_msgSender());
    }

    function renounceOwnership() public view override onlyOwner {
        revert("ERC20RewardPool: can't renounceOwnership");
    }

    function _withdrawStake(address account, uint256 amount) internal antiWithdrawCheck(_msgSender()) {
        require(amount > 0, "ERC20RewardPool: Cannot withdraw 0");
        lockWithdraw.lastWithdraw[_msgSender()] = block.timestamp;
        super._withdraw(amount);
        emit Withdrawn(account, amount);
    }

    function _withdrawRewards(address account) internal timeLockClaimCheck(account) {
        uint256 reward = rewards[account];
        uint256 mod = 0;
        if (reward > 0) {
            if (amountLockClaim.claimLockEnabled == true) {
                // constrain the reward amount to the integer allowed
                mod = reward % DECIMALS_18;
                reward = reward - mod;
                require(
                    amountLockClaim.amount <= reward,
                    "ERC20RewardPool: Cannot withdraw - lockClaim.amount < reward"
                );
            }
            rewards[account] = mod;
            rewardToken.safeTransfer(account, reward);
            emit RewardPaid(account, reward);
        }
    }

    function _updateContribution(address account) internal {
        uint256 oldContribution = _contributions[account];
        _totalContributions = _totalContributions - oldContribution;
        uint256 contribution = _computeContribution(account);
        _totalContributions = _totalContributions + contribution;
        _contributions[account] = contribution;
        emit ContributionUpdated(account, contribution, oldContribution);
    }

    function _computeContribution(address account) internal returns (uint256) {
        if (contributionRules == IContributionRules(address(0))) {
            return Math.min(_balances[account], maxStakeAllowedCalculator(account));
        } else {
            return
                contributionRules.computeMultiplier(
                    account,
                    Math.min(_balances[account], maxStakeAllowedCalculator(account))
                );
        }
    }

    // Something changed (stake, withdraw, etc), we distribute current accumulated rewards and start from zero.
    // Called each time there is a change in contract state (stake, withdraw, etc).
    function _processRewards(address account) internal {
        _restartRewards();
        _processAccountRewards(account);
    }

    // Update the earnings for this specific user with what he earned until now
    function _processAccountRewards(address account) internal {
        // usually _earned takes _rewardPerToken() but in this method is zero because _restartRewards must be
        // called before _processAccountRewards
        rewards[account] = rewards[account] + _earned(account, 0);
        // restart rewards for this specific user, now earned(account) = 0
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }

    function _restartRewards() internal {
        if (rewardCalculator != IRewardCalculator(address(0))) {
            // Distribute the accumulated rewards
            rewardPerTokenStored = rewardPerTokenStored + _rewardPerToken();
            // restart rewards so now the rewardCalculator return zero rewards
            rewardCalculator.restartRewards();
        }
    }

    function _earned(address account, uint256 rewardPerToken_) internal view returns (uint256) {
        // - userRewardPerTokenPaid[account] * _contributions[account]  / _totalContributions is the portion of
        //      rewards the last time the user changed his contribution and called _restartRewards
        //      (_totalContributions corresponds to previous value of that moment).
        // - rewardPerTokenStored * _contributions[account] is the share of the user from the
        //      accumulated rewards (from the start of time until the last call to _restartRewards) with the
        //      current value of _totalContributions
        // - _rewardPerToken() * _contributions[account]  / _totalContributions is the share of the user of the
        //      rewards from the last time anybody called _restartRewards until this moment
        //
        // The important thing to note is that at any moment in time _contributions[account] / _totalContributions is
        // the share of the user even if _totalContributions changes because of other users activity.
        return
            ((rewardPerToken_ + rewardPerTokenStored - userRewardPerTokenPaid[account]) * _contributions[account]) /
            1e24;
    }

    // This function gives the proportion of the total contribution that corresponds to each user from
    // last restartRewards call.
    // _rewardsPerToken() * _contributions[account] is the amount of extra rewards gained from last restartRewards.
    function _rewardPerToken() internal view returns (uint256) {
        if (rewardCalculator == IRewardCalculator(address(0)) || _totalContributions == 0) {
            return 0;
        }
        return (rewardCalculator.getRewards() * 1e24) / _totalContributions;
    }

    // @dev Triggers stopped state.
    // The contract must not be paused.
    function pause() external onlyOwner {
        _pause();
    }

    // @dev Returns to normal state.
    // The contract must be paused.
    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view override(Context, ERC2771HandlerV2) returns (address sender) {
        return ERC2771HandlerV2._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771HandlerV2) returns (bytes calldata) {
        return ERC2771HandlerV2._msgData();
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable-next-line compiler-version
pragma solidity 0.8.2;

/// @dev minimal ERC2771 handler to keep bytecode-size down.
/// based on: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol

abstract contract ERC2771HandlerV2 {
    address internal _trustedForwarder;

    function __ERC2771HandlerV2_initialize(address forwarder) internal {
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
            require(msg.data.length >= 24, "ERC2771HandlerV2: Invalid msg.data");
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
            require(msg.data.length >= 24, "ERC2771HandlerV2: Invalid msg.data");
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Plugins for the ERC20RewardPool that calculates the contributions (multipliers) must implement this interface
interface IContributionRules {
    /// @notice based on the user stake and address apply the contribution rules
    /// @param account address of the user that is staking tokens
    /// @param amountStaked the amount of tokens stacked
    function computeMultiplier(address account, uint256 amountStaked) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

/// @title Plugins for Reward Pools that calculate the rewards must implement this interface
interface IRewardCalculator {
    /// @dev At any point in time this function must return the accumulated rewards from the last call to restartRewards
    function getRewards() external view returns (uint256);

    /// @dev The main contract has distributed the rewards (getRewards()) until this point, this must start
    /// @dev from scratch => getRewards() == 0
    function restartRewards() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Context} from "@openzeppelin/contracts-442/utils/Context.sol";
import {Ownable} from "@openzeppelin/contracts-442/access/Ownable.sol";

// Note: this contract is meant to be inherited by ERC20RewardPool.
// we should override the renounceOwnership() method otherwise.
contract LockRules is Context, Ownable {
    // limits
    uint256 public constant timeLockLimit = 180 days;
    uint256 public constant amountLockLimit = 1000 ether;

    struct TimeLockClaim {
        uint256 lockPeriodInSecs;
        mapping(address => uint256) lastClaim;
    }

    struct AmountLockClaim {
        uint256 amount;
        bool claimLockEnabled;
    }

    struct TimeLockWithdraw {
        uint256 lockPeriodInSecs;
        mapping(address => uint256) lastWithdraw;
    }

    struct TimeLockDeposit {
        uint256 lockPeriodInSecs;
        mapping(address => uint256) lastDeposit;
    }

    event TimelockClaimSet(uint256 lockPeriodInSecs);
    event TimelockDepositSet(uint256 newTimeDeposit);
    event TimeLockWithdrawSet(uint256 newTimeWithdraw);
    event AmountLockClaimSet(uint256 newAmountLockClaim, bool isEnabled);

    // This is used to implement a time buffer for reward retrieval, so the user cannot re-stake the rewards too fast.
    TimeLockClaim public timeLockClaim;
    AmountLockClaim public amountLockClaim;
    TimeLockWithdraw public lockWithdraw;
    TimeLockDeposit public lockDeposit;

    modifier timeLockClaimCheck(address account) {
        // We use lockPeriodInSecs == 0 to disable this check
        if (timeLockClaim.lockPeriodInSecs != 0) {
            require(
                block.timestamp > timeLockClaim.lastClaim[account] + timeLockClaim.lockPeriodInSecs,
                "LockRules: Claim must wait"
            );
        }
        timeLockClaim.lastClaim[account] = block.timestamp;
        _;
    }

    modifier antiWithdrawCheck(address account) {
        // We use lockPeriodInSecs == 0 to disable this check
        if (lockWithdraw.lockPeriodInSecs != 0) {
            require(
                block.timestamp > lockWithdraw.lastWithdraw[account] + lockWithdraw.lockPeriodInSecs,
                "LockRules: Withdraw must wait"
            );
        }
        lockWithdraw.lastWithdraw[account] = block.timestamp;
        _;
    }

    modifier antiDepositCheck(address account) {
        // We use lockPeriodInSecs == 0 to disable this check
        if (lockDeposit.lockPeriodInSecs != 0) {
            require(
                block.timestamp > lockDeposit.lastDeposit[account] + lockDeposit.lockPeriodInSecs,
                "LockRules: Deposit must wait"
            );
        }
        lockDeposit.lastDeposit[account] = block.timestamp;
        _;
    }

    /// @notice set the _lockPeriodInSecs for the anti-compound buffer
    /// @param _lockPeriodInSecs amount of time the user must wait between reward withdrawal
    function setTimelockClaim(uint256 _lockPeriodInSecs) external onlyOwner {
        require(_lockPeriodInSecs <= timeLockLimit, "LockRules: invalid lockPeriodInSecs");
        timeLockClaim.lockPeriodInSecs = _lockPeriodInSecs;

        emit TimelockClaimSet(_lockPeriodInSecs);
    }

    function setTimelockDeposit(uint256 _newTimeDeposit) external onlyOwner {
        require(_newTimeDeposit <= timeLockLimit, "LockRules: invalid lockPeriodInSecs");
        lockDeposit.lockPeriodInSecs = _newTimeDeposit;

        emit TimelockDepositSet(_newTimeDeposit);
    }

    function setTimeLockWithdraw(uint256 _newTimeWithdraw) external onlyOwner {
        require(_newTimeWithdraw <= timeLockLimit, "LockRules: invalid lockPeriodInSecs");
        lockWithdraw.lockPeriodInSecs = _newTimeWithdraw;

        emit TimeLockWithdrawSet(_newTimeWithdraw);
    }

    function setAmountLockClaim(uint256 _newAmountLockClaim, bool _isEnabled) external onlyOwner {
        require(_newAmountLockClaim <= amountLockLimit, "LockRules: invalid newAmountLockClaim");
        amountLockClaim.amount = _newAmountLockClaim;
        amountLockClaim.claimLockEnabled = _isEnabled;

        emit AmountLockClaimSet(_newAmountLockClaim, _isEnabled);
    }

    function getRemainingTimelockClaim() external view returns (uint256) {
        uint256 timeLock = (timeLockClaim.lastClaim[_msgSender()] + timeLockClaim.lockPeriodInSecs);

        if (timeLock > block.timestamp) {
            return timeLock - block.timestamp;
        } else {
            return 0;
        }
    }

    function getRemainingTimelockWithdraw() external view returns (uint256) {
        uint256 timeLock = (lockWithdraw.lastWithdraw[_msgSender()] + lockWithdraw.lockPeriodInSecs);

        if (timeLock > block.timestamp) {
            return timeLock - block.timestamp;
        } else {
            return 0;
        }
    }

    function getRemainingTimelockDeposit() external view returns (uint256) {
        uint256 timeLock = (lockDeposit.lastDeposit[_msgSender()] + lockDeposit.lockPeriodInSecs);

        if (timeLock > block.timestamp) {
            return timeLock - block.timestamp;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import {Ownable} from "@openzeppelin/contracts-442/access/Ownable.sol";
import {Address} from "@openzeppelin/contracts-442/utils/Address.sol";
import {Math} from "@openzeppelin/contracts-442/utils/math/Math.sol";
import {IERC721} from "@openzeppelin/contracts-442/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts-442/token/ERC1155/IERC1155.sol";

contract RequirementsRules is Ownable {
    using Address for address;

    // we limited the number of Ids and contracts that we can have in the lists
    // to avoid the risk of DoS caused by gas limits being exceeded during the iterations
    uint256 public idsLimit = 64;
    uint256 public contractsLimit = 4;

    // maxStake amount allowed if user has no ERC721 or ERC1155
    uint256 public maxStakeOverall;

    struct ERC721RequirementRule {
        uint256[] ids;
        bool balanceOf;
        uint256 minAmountBalanceOf;
        uint256 maxAmountBalanceOf;
        uint256 minAmountId;
        uint256 maxAmountId;
        uint256 index;
    }

    struct ERC1155RequirementRule {
        uint256[] ids;
        uint256 minAmountId;
        uint256 maxAmountId;
        uint256 index;
    }

    mapping(IERC721 => ERC721RequirementRule) internal _listERC721;
    mapping(IERC1155 => ERC1155RequirementRule) internal _listERC1155;
    IERC721[] internal _listERC721Index;
    IERC1155[] internal _listERC1155Index;

    event ERC1155RequirementListSet(
        address indexed contractERC1155,
        uint256[] ids,
        uint256 minAmountId,
        uint256 maxAmountId
    );
    event ERC721RequirementListSet(
        address indexed contractERC721,
        uint256[] ids,
        bool balanceOf,
        uint256 minAmountBalanceOf,
        uint256 maxAmountBalanceOf,
        uint256 minAmountId,
        uint256 maxAmountId
    );
    event MaxStakeOverallSet(uint256 newMaxStake, uint256 oldMaxStake);
    event ERC11551RequirementListDeleted(address indexed contractERC1155);
    event ERC721RequirementListDeleted(address indexed contractERC721);

    modifier isContract(address account) {
        require(account.isContract(), "RequirementsRules: is not contract");

        _;
    }

    modifier checkRequirements(
        address account,
        uint256 amount,
        uint256 balanceOf
    ) {
        uint256 maxStakeERC721 = checkAndGetERC721Stake(account);
        uint256 maxStakeERC1155 = checkAndGetERC1155Stake(account);
        uint256 maxAllowed = _maxStakeAllowedCalculator(maxStakeERC721, maxStakeERC1155);

        if ((maxAllowed > 0) || _listERC721Index.length > 0 || _listERC1155Index.length > 0) {
            require(amount + balanceOf <= maxAllowed, "RequirementsRules: maxAllowed");
        }

        _;
    }

    modifier isERC721MemberList(address contractERC721) {
        require(
            isERC721MemberRequirementList(IERC721(contractERC721)),
            "RequirementsRules: contract is not in the list"
        );
        _;
    }

    modifier isERC1155MemberList(address contractERC1155) {
        require(
            isERC1155MemberRequirementList(IERC1155(contractERC1155)),
            "RequirementsRules: contract is not in the list"
        );
        _;
    }

    // if user has not erc721 or erc1155
    function setMaxStakeOverall(uint256 newMaxStake) external onlyOwner {
        uint256 oldMaxStake = maxStakeOverall;
        maxStakeOverall = newMaxStake;

        emit MaxStakeOverallSet(newMaxStake, oldMaxStake);
    }

    function setERC721RequirementList(
        address contractERC721,
        uint256[] memory ids,
        bool balanceOf,
        uint256 minAmountBalanceOf,
        uint256 maxAmountBalanceOf,
        uint256 minAmountId,
        uint256 maxAmountId
    ) external onlyOwner isContract(contractERC721) {
        require(
            (balanceOf == true && ids.length == 0 && minAmountBalanceOf > 0 && maxAmountBalanceOf > 0) ||
                (balanceOf == false && ids.length > 0 && minAmountId > 0 && maxAmountId > 0 && ids.length <= idsLimit),
            "RequirementRules: invalid list"
        );
        IERC721 newContract = IERC721(contractERC721);

        if (ids.length != 0) {
            _listERC721[newContract].ids = ids;
        }
        _listERC721[newContract].minAmountBalanceOf = minAmountBalanceOf;
        _listERC721[newContract].maxAmountBalanceOf = maxAmountBalanceOf;
        _listERC721[newContract].minAmountId = minAmountId;
        _listERC721[newContract].maxAmountId = maxAmountId;
        _listERC721[newContract].balanceOf = balanceOf;

        // if it's a new member create a new registry, instead, only update
        if (isERC721MemberRequirementList(newContract) == false) {
            // Limiting the size of the array (interations) to avoid the risk of DoS.
            require(contractsLimit > _listERC721Index.length, "RequirementsRules: contractsLimit exceeded");
            _listERC721Index.push(newContract);
            _listERC721[newContract].index = _listERC721Index.length - 1;
        }

        emit ERC721RequirementListSet(
            contractERC721,
            ids,
            balanceOf,
            minAmountBalanceOf,
            maxAmountBalanceOf,
            minAmountId,
            maxAmountId
        );
    }

    function setERC1155RequirementList(
        address contractERC1155,
        uint256[] memory ids,
        uint256 minAmountId,
        uint256 maxAmountId
    ) external onlyOwner isContract(contractERC1155) {
        require(
            ids.length > 0 && minAmountId > 0 && maxAmountId > 0 && ids.length <= idsLimit,
            "RequirementRules: invalid list"
        );
        IERC1155 newContract = IERC1155(contractERC1155);
        _listERC1155[newContract].ids = ids;
        _listERC1155[newContract].minAmountId = minAmountId;
        _listERC1155[newContract].maxAmountId = maxAmountId;

        // if it's a new member create a new registry, instead, only update
        if (isERC1155MemberRequirementList(newContract) == false) {
            // Limiting the size of the array (interations) to avoid the risk of DoS.
            require(contractsLimit > _listERC1155Index.length, "RequirementsRules: contractsLimit exceeded");
            _listERC1155Index.push(newContract);
            _listERC1155[newContract].index = _listERC1155Index.length - 1;
        }

        emit ERC1155RequirementListSet(contractERC1155, ids, minAmountId, maxAmountId);
    }

    function getERC721RequirementList(address contractERC721)
        external
        view
        isContract(contractERC721)
        isERC721MemberList(contractERC721)
        returns (ERC721RequirementRule memory)
    {
        return _listERC721[IERC721(contractERC721)];
    }

    function getERC1155RequirementList(address contractERC1155)
        external
        view
        isContract(contractERC1155)
        isERC1155MemberList(contractERC1155)
        returns (ERC1155RequirementRule memory)
    {
        return _listERC1155[IERC1155(contractERC1155)];
    }

    function deleteERC721RequirementList(address contractERC721)
        external
        onlyOwner
        isContract(contractERC721)
        isERC721MemberList(contractERC721)
    {
        IERC721 reqContract = IERC721(contractERC721);
        uint256 indexToDelete = _listERC721[reqContract].index;
        IERC721 addrToMove = _listERC721Index[_listERC721Index.length - 1];
        _listERC721Index[indexToDelete] = addrToMove;
        _listERC721[addrToMove].index = indexToDelete;
        _listERC721Index.pop();

        emit ERC721RequirementListDeleted(contractERC721);
    }

    function deleteERC1155RequirementList(address contractERC1155)
        external
        onlyOwner
        isContract(contractERC1155)
        isERC1155MemberList(contractERC1155)
    {
        IERC1155 reqContract = IERC1155(contractERC1155);
        uint256 indexToDelete = _listERC1155[reqContract].index;
        IERC1155 addrToMove = _listERC1155Index[_listERC1155Index.length - 1];
        _listERC1155Index[indexToDelete] = addrToMove;
        _listERC1155[addrToMove].index = indexToDelete;
        _listERC1155Index.pop();

        emit ERC11551RequirementListDeleted(contractERC1155);
    }

    function isERC721MemberRequirementList(IERC721 reqContract) public view returns (bool) {
        return (_listERC721Index.length != 0) && (_listERC721Index[_listERC721[reqContract].index] == reqContract);
    }

    function isERC1155MemberRequirementList(IERC1155 reqContract) public view returns (bool) {
        return (_listERC1155Index.length != 0) && (_listERC1155Index[_listERC1155[reqContract].index] == reqContract);
    }

    function getERC721MaxStake(address account) public view returns (uint256) {
        uint256 _maxStake = 0;
        for (uint256 i = 0; i < _listERC721Index.length; i++) {
            uint256 balanceOf = 0;
            uint256 balanceOfId = 0;
            IERC721 reqContract = _listERC721Index[i];

            if (_listERC721[reqContract].balanceOf == true) {
                balanceOf = reqContract.balanceOf(account);
            } else {
                balanceOfId = getERC721BalanceId(reqContract, account);
            }

            _maxStake =
                _maxStake +
                (balanceOf *
                    _listERC721[reqContract].maxAmountBalanceOf +
                    balanceOfId *
                    _listERC721[reqContract].maxAmountId);
        }

        return _maxStake;
    }

    function getERC1155MaxStake(address account) public view returns (uint256) {
        uint256 _maxStake = 0;

        for (uint256 i = 0; i < _listERC1155Index.length; i++) {
            uint256 _totalBal = 0;
            IERC1155 reqContract = _listERC1155Index[i];

            uint256 bal = getERC1155BalanceId(reqContract, account);

            _totalBal = _totalBal + bal;

            _maxStake = _maxStake + (_totalBal * _listERC1155[reqContract].maxAmountId);
        }

        return _maxStake;
    }

    function maxStakeAllowedCalculator(address account) public view returns (uint256) {
        uint256 maxStakeERC721 = getERC721MaxStake(account);
        uint256 maxStakeERC1155 = getERC1155MaxStake(account);
        return _maxStakeAllowedCalculator(maxStakeERC721, maxStakeERC1155);
    }

    function getERC721BalanceId(IERC721 reqContract, address account) public view returns (uint256) {
        uint256 balanceOfId = 0;

        for (uint256 j = 0; j < _listERC721[reqContract].ids.length; j++) {
            address owner = reqContract.ownerOf(_listERC721[reqContract].ids[j]);
            if (owner == account) {
                ++balanceOfId;
            }
        }

        return balanceOfId;
    }

    function getERC1155BalanceId(IERC1155 reqContract, address account) public view returns (uint256) {
        uint256 balanceOfId = 0;

        for (uint256 j = 0; j < _listERC1155[reqContract].ids.length; j++) {
            uint256 bal = reqContract.balanceOf(account, _listERC1155[reqContract].ids[j]);

            balanceOfId = balanceOfId + bal;
        }

        return balanceOfId;
    }

    function checkAndGetERC1155Stake(address account) public view returns (uint256) {
        uint256 _maxStake = 0;
        for (uint256 i = 0; i < _listERC1155Index.length; i++) {
            uint256 _totalBal = 0;
            IERC1155 reqContract = _listERC1155Index[i];

            uint256 balanceId = getERC1155BalanceId(reqContract, account);
            if (_listERC1155[reqContract].ids.length > 0) {
                require(balanceId >= _listERC1155[reqContract].minAmountId, "RequirementsRules: balanceId");
            }

            _totalBal = _totalBal + balanceId;
            _maxStake = _maxStake + (_totalBal * _listERC1155[reqContract].maxAmountId);
        }
        return _maxStake;
    }

    function checkAndGetERC721Stake(address account) public view returns (uint256) {
        uint256 _maxStake = 0;
        for (uint256 i = 0; i < _listERC721Index.length; i++) {
            uint256 balanceOf = 0;
            uint256 balanceOfId = 0;
            IERC721 reqContract = _listERC721Index[i];

            if (_listERC721[reqContract].balanceOf == true) {
                require(
                    (reqContract.balanceOf(account) >= _listERC721[reqContract].minAmountBalanceOf) ||
                        (maxStakeOverall > 0),
                    "RequirementsRules: balanceOf"
                );
                balanceOf = reqContract.balanceOf(account);
            } else {
                balanceOfId = getERC721BalanceId(reqContract, account);
                if (_listERC721[reqContract].ids.length > 0) {
                    require(
                        (balanceOfId >= _listERC721[reqContract].minAmountId) || (maxStakeOverall > 0),
                        "RequirementsRules: balanceId"
                    );
                }
            }

            _maxStake =
                _maxStake +
                (balanceOf *
                    _listERC721[reqContract].maxAmountBalanceOf +
                    balanceOfId *
                    _listERC721[reqContract].maxAmountId);
        }
        return _maxStake;
    }

    function _maxStakeAllowedCalculator(uint256 maxStakeERC721, uint256 maxStakeERC1155)
        internal
        view
        returns (uint256)
    {
        uint256 maxAllowed = maxStakeOverall;

        if (maxStakeERC721 + maxStakeERC1155 > 0) {
            if (maxStakeOverall > 0) {
                maxAllowed = Math.min(maxAllowed, maxStakeERC721 + maxStakeERC1155);
            } else {
                maxAllowed = maxStakeERC721 + maxStakeERC1155;
            }
        } else {
            maxAllowed = maxStakeOverall;
        }

        return maxAllowed;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.2;

import "@openzeppelin/contracts-442/utils/Context.sol";
import "@openzeppelin/contracts-442/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts-442/utils/Address.sol";

abstract contract StakeTokenWrapper is Context {
    using Address for address;
    using SafeERC20 for IERC20;
    IERC20 internal _stakeToken;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;

    constructor(IERC20 stakeToken) {
        require(address(stakeToken).isContract(), "StakeTokenWrapper: is not a contract");
        _stakeToken = stakeToken;
    }

    function _stake(uint256 amount) internal virtual {
        require(amount > 0, "StakeTokenWrapper: amount > 0");
        _totalSupply = _totalSupply + amount;
        _balances[_msgSender()] = _balances[_msgSender()] + amount;
        _stakeToken.safeTransferFrom(_msgSender(), address(this), amount);
    }

    function _withdraw(uint256 amount) internal virtual {
        require(amount > 0, "StakeTokenWrapper: amount > 0");
        _totalSupply = _totalSupply - amount;
        _balances[_msgSender()] = _balances[_msgSender()] - amount;
        _stakeToken.safeTransfer(_msgSender(), amount);
    }

    uint256[50] private __gap;
}