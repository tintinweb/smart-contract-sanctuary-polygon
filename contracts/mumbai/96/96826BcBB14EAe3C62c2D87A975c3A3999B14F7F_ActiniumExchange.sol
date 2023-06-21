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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./lib/ActiniumExchangeManagement.sol";
import "./lib/ActiniumExchangeService.sol";

contract ActiniumExchange is ActiniumMarketManagement, ActiniumExchangeService {
    using Counters for Counters.Counter;

    // Interface Ids
    Counters.Counter private orderId;

    mapping(uint256 => MarketOrder) public orders;

    /*
        Events
    */
    event OrderCreated(
        uint256 orderTime,
        uint256 expirationTime,
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed makerAddress,
        address currencyContract,
        address item,
        ItemStandard itemStandard,
        OrderSide orderSide,
        uint256 quantity,
        uint256 unitPrice,
        uint256 unitMarketFee
    );

    event OrderAccepted(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed takerAddress,
        address currencyContract,
        address item,
        uint256 tradeQuantity,
        uint256 orderLeftQuantity,
        uint256 unitPrice,
        uint256 unitMarketFee
    );

    event OrderUpdated(
        uint256 orderTime,
        uint256 expirationTime,
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed makerAddress,
        address currencyContract,
        address item,
        OrderSide orderSide,
        uint256 quantity,
        uint256 unitPrice,
        uint256 unitMarketFee,
        bool isFullfilled
    );

    event OrderCancelled(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed makerAddress,
        address currencyContract,
        address item,
        uint256 quantity,
        uint256 unitPrice,
        uint256 unitMarketFee
    );


    /**
     * @dev Check if seller owns items and approval is maden
     */
    function _checkSellable(
        address sellerAddress,
        address item,
        ItemStandard itemStandard,
        uint256 tokenId,
        uint256 quantity
    ) internal view {
        _checkOwnedItem(item, itemStandard, sellerAddress, tokenId, quantity);
        _checkApproveItem(item, itemStandard, sellerAddress);
    }

    function _checkSpendable(
        address buyerAddress,
        address currencyContract,
        uint256 totalPrice
    ) internal view {
        _checkBalanceCurrency(currencyContract, buyerAddress, totalPrice);
        _checkApproveCurrency(currencyContract, buyerAddress, totalPrice);
    }

    function _newOrderId() internal returns (uint256) {
        orderId.increment();
        return orderId.current();
    }

    function _checkOrderAcceptable(
        MarketOrder memory order,
        address sellerAddress,
        address buyerAddress,
        uint256 requestOrderQuantity
    ) internal view {
        require(order.expirationTime > block.timestamp, "ActiniumExchange: order is expired");
        require(sellerAddress != buyerAddress, "ActiniumExchange: trader is same as order maker");
        require(order.quantity >= requestOrderQuantity, "ActiniumExchange: available listed quantity is less than request quantity");
        require(order.isFullfilled == false, "ActiniumExchange: order is fullfilled");
        require(order.isCanceled == false, "ActiniumExchange: order is canceled");
    }

    function _calculateTotalPriceAndFee(
        uint256 unitPrice,
        uint256 unitFee,
        uint256 quantity
    ) internal pure returns (uint256, uint256) {
        uint256 totalPrice = unitPrice * quantity;
        uint256 totalFee = unitFee * quantity;
        return (totalPrice, totalFee);
    }

    function _makeNewOrder(
        address makerAddress,
        OrderSide side,
        uint256 expirationTime,
        address currencyContract,
        address item,
        ItemStandard itemStandard,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity
    ) internal {
        // Id AutoIncrement
        uint256 newOrderId = _newOrderId();

        // Get Variables
        uint256 orderTime = block.timestamp;

        uint256 unitMarketFee = calculateMarketFee(unitPrice, marketFeeRate);

        // Mapping Struct & Push
        MarketOrder memory orderResult = MarketOrder(
        // timestamp fields
            orderTime,
            expirationTime,
            // id fields
            newOrderId,
            tokenId,
            // address info fields
            makerAddress,
            currencyContract,
            item,
            itemStandard,
            // enum fields
            side,
            // meta info
            quantity,
            unitPrice,
            unitMarketFee,
            false,
            false
        );
        orders[newOrderId] = orderResult;

        // Create Event
        emit OrderCreated(
            orderResult.orderTime,
            orderResult.expirationTime,
            newOrderId,
            tokenId,
            orderResult.trader,
            orderResult.currencyContract,
            orderResult.itemContract,
            orderResult.itemStandard,
            orderResult.orderSide,
            orderResult.quantity,
            orderResult.price,
            orderResult.marketFee
        );
    }

    function _getExistingOrder(
        uint256 targetOrderId
    ) internal view returns (MarketOrder storage) {
        MarketOrder storage order = orders[targetOrderId];
        require(order.trader != address(0), "ActiniumExchange: order is not exist");
        return order;
    }

    /*
        public Methods
    */
    function calculateMarketFee(
        uint256 price,
        uint256 feeRate
    ) public pure returns (uint256) {
        // e.g., feeRate 1 = 0.01% = 0.0001
        uint256 marketFee = (price * feeRate) / 10000;
        return marketFee;
    }

    function createListingOrder(
        uint256 expirationTime,
        address currencyContract,
        address item,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity
    ) external
    checkSupportedCurrency(currencyContract)
    checkBlackList(msg.sender)
    checkSupportedItemContract(item)
    {
        address sellerAddress = msg.sender;
        ItemStandard itemStandard = _getItemStandard(item);

        // Check seller owned item, and transfer approved
        _checkSellable(sellerAddress, item, itemStandard, tokenId, quantity);

        // Parameter Check
        require(expirationTime > block.timestamp, "ActiniumExchange: expiration time must be greater than now");
        require(quantity > 0, "ActiniumExchange: quantity must be greater than zero");

        _makeNewOrder(
            sellerAddress,
            OrderSide.LISTING,
            expirationTime,
            currencyContract,
            item,
            itemStandard,
            tokenId,
            unitPrice,
            quantity
        );
    }

    function createOfferingOrder(
        uint256 expirationTime,
        address currencyContract,
        address itemContract,
        uint256 tokenId,
        uint256 unitPrice,
        uint256 quantity
    ) external
    checkSupportedCurrency(currencyContract)
    checkBlackList(msg.sender)
    checkSupportedItemContract(itemContract)
    {
        address buyerAddress = msg.sender;

        ItemStandard itemStandard = _getItemStandard(itemContract);

        // Check Buyer's Token transfer approved
        _checkSpendable(buyerAddress, currencyContract, quantity * unitPrice);

        // Parameter Check
        require(expirationTime > block.timestamp, "ActiniumExchange: expiration time must be greater than now");
        require(tokenId != 0, "ActiniumExchange: tokenId must be greater than zero");
        require(quantity > 0, "ActiniumExchange: quantity must be greater than zero");

        _makeNewOrder(
            buyerAddress,
            OrderSide.OFFERING,
            expirationTime,
            currencyContract,
            itemContract,
            itemStandard,
            tokenId,
            unitPrice,
            quantity
        );
    }

    function acceptListingOrder(
        uint256 targetOrderId,
        uint256 requestOrderQuantity
    ) public checkBlackList(msg.sender) {
        // Get Variables
        MarketOrder storage order = _getExistingOrder(targetOrderId);
        address buyerAddress = msg.sender;
        address sellerAddress = order.trader;

        // Check Order Object
        _checkOrderAcceptable(order, sellerAddress, buyerAddress, requestOrderQuantity);
        require(order.orderSide == OrderSide.LISTING, "ActiniumExchange: orderSide is not LISTING");

        // get total price and fee
        (uint256 currentOrderTotalPrice, uint256 currentMarketFee) = _calculateTotalPriceAndFee(order.price, order.marketFee, requestOrderQuantity);

        // Seller - check owned, Aprroved
        _checkSellable(sellerAddress, order.itemContract, order.itemStandard, order.tokenId, requestOrderQuantity);

        // Buyer - check balance, Approved
        _checkSpendable(buyerAddress, order.currencyContract, currentOrderTotalPrice);

        // Transfer market fee to fee address from buyer address
        _transferMarketFee(order.currencyContract, buyerAddress, currentMarketFee);
        // Market Fee Transfer

        // Transfer ERC-20 with ERC-721/ERC-1155
        _transferItem(order.itemContract, order.itemStandard, sellerAddress, buyerAddress, order.tokenId, requestOrderQuantity);
        // Item: seller -> buyer
        _transferCurrency(order.currencyContract, buyerAddress, sellerAddress, currentOrderTotalPrice - currentMarketFee);
        // ERC20: buyer -> seller

        order.quantity = order.quantity - requestOrderQuantity;
        if (order.quantity == 0) {
            order.isFullfilled = true;
        }

        emit OrderAccepted(
            order.orderId,
            order.tokenId,
            buyerAddress,
            order.currencyContract,
            order.itemContract,
            requestOrderQuantity,
            order.quantity,
            order.price,
            order.marketFee
        );
    }

    function acceptOfferingOrder(
        uint256 targetOrderId,
        uint256 requestOrderQuantity
    ) external checkBlackList(msg.sender) {
        // Get Variables
        MarketOrder storage order = _getExistingOrder(targetOrderId);
        address buyerAddress = order.trader;
        address sellerAddress = msg.sender;

        // Check Order Object
        _checkOrderAcceptable(order, sellerAddress, buyerAddress, requestOrderQuantity);
        require(order.orderSide == OrderSide.OFFERING, "ActiniumExchange: orderSide is not OFFERING");

        // get total price and fee
        (uint256 currentOrderTotalPrice,uint256 currentMarketFee) = _calculateTotalPriceAndFee(order.price, order.marketFee, requestOrderQuantity);

        // Seller - check owned, Aprroved
        _checkSellable(sellerAddress, order.itemContract, order.itemStandard, order.tokenId, requestOrderQuantity);

        // Buyer - check balance, Approved
        _checkSpendable(buyerAddress, order.currencyContract, currentOrderTotalPrice);

        // Transfer market fee
        _transferMarketFee(order.currencyContract, buyerAddress, currentMarketFee);
        // Market Fee Transfer

        // Transfer
        _transferItem(order.itemContract, order.itemStandard, sellerAddress, buyerAddress, order.tokenId, requestOrderQuantity);
        // Item: seller -> buyer
        _transferCurrency(order.currencyContract, buyerAddress, sellerAddress, currentOrderTotalPrice - currentMarketFee);
        // ERC20: buyer -> seller

        order.quantity = order.quantity - requestOrderQuantity;
        if (order.quantity == 0) {
            order.isFullfilled = true;
        }

        emit OrderAccepted(
            order.orderId,
            order.tokenId,
            sellerAddress,
            order.currencyContract,
            order.itemContract,
            requestOrderQuantity,
            order.quantity,
            order.price,
            order.marketFee
        );
    }

    function updateListingOrder(
        uint256 targetOrderId,
        uint256 updateTotalQuantity,
        uint256 updateUnitPrice
    ) external checkBlackList(msg.sender) {
        require(updateTotalQuantity > 0 && updateUnitPrice > 0, "ActiniumExchange: update quantity and unit price is zero");

        // Get Variables
        MarketOrder storage order = _getExistingOrder(targetOrderId);
        address sellerAddress = msg.sender;

        // Check Order Object
        require(sellerAddress == order.trader, "ActiniumExchange: only order trader can update order");
        require(order.expirationTime > block.timestamp, "ActiniumExchange: order is expired");
        require(order.orderSide == OrderSide.LISTING, "ActiniumExchange: orderSide is not LISTING");
        require(order.isFullfilled == false, "ActiniumExchange: order is fullfilled");
        require(order.isCanceled == false, "ActiniumExchange: order is canceled");

        // Check Seller's Item Owned, and Aprroveds
        _checkSellable(sellerAddress, order.itemContract, order.itemStandard, order.tokenId, updateTotalQuantity);

        // Optional parameters: quantity and price
        order.quantity = updateTotalQuantity;
        order.price = updateUnitPrice;

        // Recalculate unit market fee
        order.marketFee = calculateMarketFee(order.price, marketFeeRate);

        if (order.quantity == 0) {
            order.isFullfilled = true;
        }

        // Create Event
        emit OrderUpdated(
            order.orderTime,
            order.expirationTime,
            targetOrderId,
            order.tokenId,
            order.trader,
            order.currencyContract,
            order.itemContract,
            order.orderSide,
            order.quantity,
            order.price,
            order.marketFee,
            order.isFullfilled
        );
    }

    function updateOfferingOrder(
        uint256 targetOrderId,
        uint256 updateTotalQuantity,
        uint256 updateUnitPrice
    ) external checkBlackList(msg.sender) {
        require(updateTotalQuantity != 0 && updateUnitPrice != 0, "ActiniumExchange: update quantity and unit price is zero");

        // Get Variables
        MarketOrder storage order = _getExistingOrder(targetOrderId);
        address buyerAddress = msg.sender;

        // Check Order Object
        require(buyerAddress == order.trader, "ActiniumExchange: only order trader can update order");
        require(order.expirationTime > block.timestamp, "ActiniumExchange: order is expired");
        require(order.orderSide == OrderSide.OFFERING, "ActiniumExchange: orderSide is not OFFERING");
        require(order.isFullfilled == false, "ActiniumExchange: order is fullfilled");
        require(order.isCanceled == false, "ActiniumExchange: order is canceled");

        // Check Buyer's Token Balance, and Aprroved
        uint256 updateTotalPrice = updateTotalQuantity * updateUnitPrice;
        _checkSpendable(buyerAddress, order.currencyContract, updateTotalPrice);

        // Optional parameters: quantity and price
        order.quantity = updateTotalQuantity;
        order.price = updateUnitPrice;

        // Reculculate unit market fee
        order.marketFee = calculateMarketFee(order.price, marketFeeRate);

        if (order.quantity == 0) {
            order.isFullfilled = true;
        }

        // Create Event
        emit OrderUpdated(
            order.orderTime,
            order.expirationTime,
            targetOrderId,
            order.tokenId,
            order.trader,
            order.currencyContract,
            order.itemContract,
            order.orderSide,
            order.quantity,
            order.price,
            order.marketFee,
            order.isFullfilled
        );
    }

    function cancelOrder(uint256 targetOrderId) external checkBlackList(msg.sender) {
        // Get Variables
        MarketOrder storage order = _getExistingOrder(targetOrderId);
        address traderAddress = msg.sender;

        // Check Order Object
        require(traderAddress == order.trader || msg.sender == owner(), "ActiniumExchange: only the manager or the owner of the order can cancel");
        require(order.expirationTime > block.timestamp, "ActiniumExchange: order is expired");
        require(order.isFullfilled == false, "ActiniumExchange: order is already fullfilled");
        require(order.isCanceled == false, "ActiniumExchange: order is already canceled");

        // Cancel Order
        order.isCanceled = true;

        // Create Event
        emit OrderCancelled(
            targetOrderId,
            order.tokenId,
            order.trader,
            order.currencyContract,
            order.itemContract,
            order.quantity,
            order.price,
            order.marketFee
        );
    }

    function getTotalOrderPrice(address currencyContract, uint256[] memory listOrderId, uint256[] memory listQuantity)
    public
    view
    returns (uint256)
    {
        require(listOrderId.length == listQuantity.length, "ActiniumExchange: invalid input");

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < listOrderId.length; i++) {
            MarketOrder memory order = _getExistingOrder(listOrderId[i]);
            require(order.currencyContract == currencyContract, "ActiniumExchange: invalid Currency Contract");
            totalPrice += order.price * listQuantity[i];
        }
        return totalPrice;
    }

    function acceptBulkListingOrder(
        address currencyContract,
        uint256[] memory listOrderId,
        uint256[] memory listQuantity
    ) external checkBlackList(msg.sender) {
        require(listOrderId.length == listQuantity.length, "ActiniumExchange: invalid input");

        // Check Buyer Balance
        uint256 totalPrice = getTotalOrderPrice(currencyContract, listOrderId, listQuantity);
        _checkSpendable(msg.sender, currencyContract, totalPrice);

        // Check Seller's Item Owned, and approves
        for (uint256 i = 0; i < listOrderId.length; i++) {
            acceptListingOrder(listOrderId[i], listQuantity[i]);
        }
    }

    /*
    * @dev cancel if order is not acceptable
    */
    function validateOrder(uint256 orderId) public {
        MarketOrder storage order = _getExistingOrder(orderId);
        if (order.orderSide == OrderSide.LISTING) {
            bool sellable = _getItemSellableState(order.trader, order.itemContract, order.itemStandard, order.tokenId, order.quantity);
            if (!sellable) {
                order.isCanceled = true;

                // Create Event
                emit OrderCancelled(
                    orderId,
                    order.tokenId,
                    order.trader,
                    order.currencyContract,
                    order.itemContract,
                    order.quantity,
                    order.price,
                    order.marketFee
                );
            }
        } else if (order.orderSide == OrderSide.OFFERING) {
            bool spendable = _getCurrencySpendableState(order.trader, order.currencyContract, order.price * order.quantity);
            if (!spendable) {
                order.isCanceled = true;

                // Create Event
                emit OrderCancelled(
                    orderId,
                    order.tokenId,
                    order.trader,
                    order.currencyContract,
                    order.itemContract,
                    order.quantity,
                    order.price,
                    order.marketFee
                );
            }
        }
    }

    /*
    * @dev bulk validation
    */
    function validateBulkOrders(uint256[] memory listOrderId) public {
        for (uint256 i = 0; i < listOrderId.length; i++) {
            validateOrder(listOrderId[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ActiniumMarketManagement is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal listCurrency;
    EnumerableSet.AddressSet internal itemContracts;
    EnumerableSet.AddressSet internal blackLists;

    uint256 public marketFeeRate = 200; // default 2% = 200/10000
    // IERC20 interfaceId to constant
    bytes4 private constant IERC20_IID = type(IERC20).interfaceId;


    modifier checkSupportedCurrency(address _token) {
        require(listCurrency.contains(_token), "ActiniumMarketManagement: currency is not supported erc20.");
        _;
    }

    modifier checkSupportedItemContract(address _itemContract) {
        require(itemContracts.contains(_itemContract), "ActiniumMarketManagement: item contract is not supported.");
        _;
    }

    modifier checkBlackList(address trader) {
        require(!blackLists.contains(trader), "ActiniumMarketManagement: trader is in black list.");
        _;
    }

    function getListSupportedCurrency()
    external
    view
    onlyOwner
    returns (address[] memory)
    {
        uint256 length = listCurrency.length();
        address[] memory tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = listCurrency.at(i);
        }
        return tokens;
    }

    function getListSupportedCurrencyAndBalance()
    external
    view
    onlyOwner
    returns (address[] memory, uint256[] memory)
    {
        uint256 length = listCurrency.length();
        address[] memory tokens = new address[](length);
        uint256[] memory balances = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            tokens[i] = listCurrency.at(i);
            balances[i] = IERC20(tokens[i]).balanceOf(address(this));
        }
        return (tokens, balances);
    }

    function getContractCurrencyBalance(
        address _token
    ) external view onlyOwner checkSupportedCurrency(_token) returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function isSupportedCurrency(address _token) external view returns (bool) {
        return listCurrency.contains(_token);
    }

    function addSupportedCurrency(address _token) external onlyOwner {
        require(_token != address(0), "ActiniumMarketManagement: invalid token address");
        // check ierc20 interface
        require(IERC165(_token).supportsInterface(IERC20_IID), "ActiniumMarketManagement: token does not support IERC20 interface");
        listCurrency.add(_token);
    }

    function removeSupportedCurrency(address _token) external onlyOwner {
        require(_token != address(0), "ActiniumMarketManagement: invalid token address");
        listCurrency.remove(_token);
    }

    function addSupportedItemContract(address _itemContract) external onlyOwner {
        require(_itemContract != address(0), "ActiniumMarketManagement: invalid item contract address");
        itemContracts.add(_itemContract);
    }

    function removeSupportedItemContract(address _itemContract) external onlyOwner {
        require(_itemContract != address(0), "ActiniumMarketManagement: invalid item contract address");
        itemContracts.remove(_itemContract);
    }

    function addBlackList(address trader) public onlyOwner {
        require(trader != address(0), "ActiniumMarketManagement: invalid trader address");
        blackLists.add(trader);
    }

    function removeBlackList(address trader) public onlyOwner {
        require(trader != address(0), "ActiniumMarketManagement: invalid trader address");
        blackLists.remove(trader);
    }

    function addBulkBlackList(address[] memory traders) public onlyOwner {
        for (uint256 i = 0; i < traders.length; i++) {
            addBlackList(traders[i]);
        }
    }

    function removeBulkBlackList(address[] memory traders) public onlyOwner {
        for (uint256 i = 0; i < traders.length; i++) {
            removeBlackList(traders[i]);
        }
    }

    function withdrawCurrency(
        uint256 _amount,
        address tokenAddress
    ) public onlyOwner {
        require(_amount > 0, "ActiniumMarketManagement: invalid withdraw amount");
        IERC20(tokenAddress).transferFrom(address(this), owner(), _amount);
    }

    function setMarketFeeRate(uint256 _marketFeeRate) public onlyOwner {
        marketFeeRate = _marketFeeRate;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ActiniumExchangeStruct.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ActiniumExchangeService {
    using SafeERC20 for IERC20;

    // Interface Ids
    bytes4 private constant IERC721_IID = type(IERC721).interfaceId;
    bytes4 private constant IERC1155_IID = type(IERC1155).interfaceId;

    function _checkApproveCurrency(
        address tokenContract,
        address sender,
        uint256 requestTokenQuantity
    ) internal view {
        uint256 allowanceTokenQuantity = IERC20(tokenContract).allowance(sender, address(this));

        require(allowanceTokenQuantity >= requestTokenQuantity, "ActiniumExchange: transfer not approved by token owner");
    }

    function _checkApproveItem(
        address itemContract,
        ItemStandard itemStandard,
        address userAddress
    ) internal view {
        bool result = false;
        // check if itemContract supports ERC721 or ERC1155
        if (itemStandard == ItemStandard.ERC721) {
            // ERC721
            result = IERC721(itemContract).isApprovedForAll(userAddress, address(this));
        } else if (itemStandard == ItemStandard.ERC1155) {
            // ERC1155
            result = IERC1155(itemContract).isApprovedForAll(userAddress, address(this));
        } else {
            result = false;
        }
        require(result, "ActiniumExchange: transfer not approved by Item owner");
    }

    function _checkBalanceCurrency(
        address tokenContract,
        address userAddress,
        uint256 requestTokenQuantity
    ) internal view {
        uint256 balanceTokenQuantity = IERC20(tokenContract).balanceOf(userAddress);

        require(balanceTokenQuantity >= requestTokenQuantity, "ActiniumExchange: token balance is not enough");
    }

    function _checkOwnedItem(
        address itemContract,
        ItemStandard itemStandard,
        address userAddress,
        uint256 itemTokenId,
        uint256 quantity
    ) internal view {
        // check if itemContract supports ERC721 or ERC1155
        if (itemStandard == ItemStandard.ERC721) {
            // ERC721
            require(IERC721(itemContract).ownerOf(itemTokenId) == userAddress, "ActiniumExchange: item balance is not enough");
        } else if (itemStandard == ItemStandard.ERC1155) {
            // ERC1155
            require(IERC1155(itemContract).balanceOf(userAddress, itemTokenId) >= quantity, "ActiniumExchange: item balance is not enough");
        } else {
            revert("ActiniumExchange: item standard is not supported");
        }
    }

    /**
     * @dev Check if item own and approved for this contract
     */
    function _getItemSellableState(
        address sellerAddress,
        address itemContract,
        ItemStandard itemStandard,
        uint256 tokenId,
        uint256 quantity
    ) internal view returns (bool){
        if (itemStandard == ItemStandard.ERC721) {
            return IERC721(itemContract).ownerOf(tokenId) == sellerAddress &&
            IERC721(itemContract).isApprovedForAll(sellerAddress, address(this));
        } else if (itemStandard == ItemStandard.ERC1155) {
            return IERC1155(itemContract).balanceOf(sellerAddress, tokenId) >= quantity &&
            IERC1155(itemContract).isApprovedForAll(sellerAddress, address(this));
        } else {
            return false;
        }
    }

    /**
    * @dev Check if currency balance and allowance is enough for this contract
    */
    function _getCurrencySpendableState(
        address buyerAddress,
        address currencyContract,
        uint256 quantity
    ) internal view returns (bool){
        return IERC20(currencyContract).balanceOf(buyerAddress) >= quantity &&
        IERC20(currencyContract).allowance(buyerAddress, address(this)) >= quantity;
    }

    function _transferCurrency(
        address tokenContract,
        address sender,
        address receiver,
        uint256 quantity
    ) internal {
        // Transfer tokens from sender to receiver.
        IERC20(tokenContract).safeTransferFrom(sender, receiver, quantity);
    }

    function _transferItem(
        address itemContract,
        ItemStandard itemStandard,
        address sender,
        address receiver,
        uint256 tokenId,
        uint256 quantity
    ) internal {
        // check if itemContract supports ERC721 or ERC1155
        if (itemStandard == ItemStandard.ERC721) {
            // ERC721
            IERC721(itemContract).safeTransferFrom(sender, receiver, tokenId);
        } else if (itemStandard == ItemStandard.ERC1155) {
            // ERC1155
            IERC1155(itemContract).safeTransferFrom(sender, receiver, tokenId, quantity, "");
        } else {
            revert("ActiniumExchange: not supported item contract");
        }
    }

    function _transferMarketFee(
        address currencyContract,
        address sender,
        uint256 requestQuantity
    ) internal {
        // Transfer tokens from sender to receiver.
        IERC20(currencyContract).safeTransferFrom(sender, address(this), requestQuantity);
    }

    function _getItemStandard(address itemContract) internal view returns (ItemStandard) {
        if (IERC165(itemContract).supportsInterface(IERC721_IID)) {
            // ERC721
            return ItemStandard.ERC721;
        } else if (IERC165(itemContract).supportsInterface(IERC1155_IID)) {
            // ERC1155
            return ItemStandard.ERC1155;
        } else {
            revert("ActiniumExchange: not supported item contract");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
enum OrderSide {
    // NONE is 0, so default value of enum
    NONE,
    // LISTING is 1
    LISTING,
    // OFFERING is 2
    OFFERING
}
    enum ItemStandard {
        // NONE is 0, so default value of enum
        NONE,
        // ERC721 is 1
        ERC721,
        // ERC1155 is 2
        ERC1155
    }

    struct MarketOrder {
        // timestamp fields
        uint256 orderTime;
        uint256 expirationTime;

        // id fields
        uint256 orderId;
        uint256 tokenId;

        // address info fields
        address trader;
        address currencyContract; // ERC-20 token
        address itemContract;
        ItemStandard itemStandard;

        // enum fields
        OrderSide orderSide;

        // meta info fields
        uint256 quantity; // total quantity
        uint256 price; // unit price
        uint256 marketFee; //  unit market fee = price * {fee rate}

        bool isFullfilled;
        bool isCanceled;
    }