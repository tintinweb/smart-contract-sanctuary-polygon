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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IRentingTypes.sol";

interface IRentingContractStorage is IRentingTypes {

    function getLandStatus(uint256 landId) external view returns (TokenRentingStatus);

    function getBotStatus(uint256 botId) external view returns (TokenRentingStatus);

    function renewRenting(uint256 id, uint256 renewTs, uint256 rentingEndTs) external;

    function getRentingInfo(uint256 landId) external view returns (RentingInfo memory);

    function getCollection(uint256 id) external view returns (Collection memory);

    function createRenting(BattleSet memory bs, RentingType rt, Coin coin, uint256 price, address owner, address renter,
        uint256 rentingEnd, uint256 collectionId, bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function deleteListingInfo(uint256 landId) external;

    function getListingInfo(uint256 landId) external view returns (ListingInfo memory);

    function updateCollectionRentedAssets(uint256 id, uint256[] memory availableLands, uint256[] memory availableBotsIds,
        uint256[] memory rentedLandIds, uint256[] memory rentedBotsIds) external;

    function deleteRenting(uint256 landId) external;

    function createCollection(address assetsOwner, uint256[] memory landIds, uint256[] memory botIds,
        bool perpetual, address[] memory players, PaymentData memory pd) external returns (uint256);

    function editCollection(uint256 id, Coin coin, uint256 price, RentingType rentingType, bool perpetual, uint revenueShare) external;

    function addAssetsToCollection(uint id, uint256[] memory landIds, uint256[] memory botIds) external;

    function removeListedLand(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedLands(uint id, uint256 landIdToRemove) external;

    function pushToBeRemovedBots(uint id, uint256 botIdToRemove) external;

    function removeListedBot(uint id, uint256 botIdToRemove) external;

    function disbandCollection(uint256 id) external returns (bool);

    function processCollectionRentalEnd(RentingInfo memory ri) external returns (Collection memory);

    function createListingInfo(BattleSet memory bs, RentingType rt, address owner, Coin coin, uint256 price,
        bool perpetual, address[] memory whitelist, uint revenueShare) external;

    function addPlayersToCollection(uint id, address[] memory players) external;

    function removePlayersFromCollection(uint id, address player) external;

    function setRentingCancelTs(uint256 id, uint256 cancelTs) external;

    function getCollectionIdByIndex(uint256 idx) external view returns (uint256);

    function getCollectionsCount() external view returns (uint256);

    function getRentingIdByIndex(uint256 idx) external view returns (uint256);

    function getRentingsCount() external view returns (uint256);

    function getListingIdByIndex(uint256 idx) external view returns (uint256);

    function getListingCount() external view returns (uint256);
}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IRentingTypes {

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        BUSD,
        USDT,
        DAI
    }

    enum RentingType {
        FIXED_PRICE,
        REVENUE_SHARE
    }

    enum TokenRentingStatus {
        AVAILABLE,
        LISTED_BATTLE_SET,
        LISTED_COLLECTION,
        RENTED
    }

    struct BattleSet {
        uint256 landId;
        uint256[] botsIds;
    }

    struct ListingInfo {
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 listingTs;
        address owner;
        uint256 price;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct RentingInfo {
        uint256 id;
        BattleSet battleSet;
        RentingType rentingType;
        Coin chargeCoin;
        uint256 price;
        address owner;
        address renter;
        uint256 rentingTs;
        uint256 renewTs;
        uint256 rentingEndTs;
        uint256 renewedPeriodEndTs;
        uint256 cancelTs;
        uint256 collectionId;
        bool perpetual;
        address[] whitelist;
        uint revenueShare;
    }

    struct Collection {
        uint256 id;
        address owner;
        uint256[] landIds;
        uint256[] botsIds;
        uint256[] rentedLandIds;
        uint256[] rentedBotsIds;
        uint256[] landsToRemove;
        uint256[] botsToRemove;
        address[] whitelist;
        RentingType rentingType;
        Coin chargeCoin;// probaby change to uint
        uint256 price;
        bool perpetual;
        uint256 disbandTs;
        uint revenueShare;
    }

    struct PaymentData {
        RentingType rentingType;
        Coin coin;
        uint256 price;
        uint revenueShare;
    }

    enum TradedNft {
        RBXL,
        RBFB
    }

}

/// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IRentingContractStorage.sol";
import "./IRentingTypes.sol";



interface IXoiliumMarketplaceTypes {
    event TokenListed(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId, uint256 price, Coin coin, uint256 endTs, address allowedBuyer);
    event TokenListingUpdated(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId, uint256 price, Coin coin, uint256 endTs, address allowedBuyer);
    event ListingCanceled(address indexed seller, TradedNft indexed nft, uint256 indexed tokenId);
    event TokenBought(address indexed buyer, TradedNft indexed nft, uint256 indexed tokenId, Coin coin, uint256 price);
    event TokenWithdrawn(address tokenContractAddress, uint256 amount);
    event FeesUpdate(address caller, uint256 feePercent, address feeCollectorAddress);

    struct Listing {
        TradedNft nft;
        uint256 tokenId;
        Coin coin;
        uint256 price;
        address seller;
        uint256 endTs;
        address allowedBuyer;
    }

    enum Coin {
        XOIL,
        RBLS,
        WETH,
        USDC,
        USDT,
        BUSDF
    }

    enum TradedNft {
        RBXL,
        RBFB
    }
}

interface IXoiliumMarketplaceStorage is IXoiliumMarketplaceTypes {
    function setListing(TradedNft nft, uint256 tokenId, Coin coin, uint256 price, address seller, uint256 endTs, address allowedBuyer) external;

    function deleteListing(TradedNft nft, uint256 tokenId) external;

    function getListing(TradedNft nft, uint256 tokenId) external view returns (Listing memory);

    function getListingByIdx(TradedNft nft, uint idx) external view returns (Listing memory);
}


contract Marketplace is IXoiliumMarketplaceTypes, ReentrancyGuard, Ownable, Pausable {

    using SafeERC20 for IERC20;

    mapping(TradedNft => IERC721) nftContracts;
    mapping(Coin => address) paymentContracts;
    IRentingContractStorage internal rentingStorageContract;
    IXoiliumMarketplaceStorage internal marketplaceStorage;

    uint8 private constant PAGE_SIZE = 10;
    uint256 private feePercent = 5;
    address private feeCollectorAddress;
    Coin[] private supportedCoins = [Coin.WETH];


    constructor(address marketplaceStorageAddress, address landsContractAddress, address botsContractAddress,
        address xoilAddress, address rblsAddress, address wethAddress) {
        paymentContracts[Coin.XOIL] = xoilAddress;
        paymentContracts[Coin.RBLS] = rblsAddress;
        paymentContracts[Coin.WETH] = wethAddress;
        marketplaceStorage = IXoiliumMarketplaceStorage(marketplaceStorageAddress);
        nftContracts[TradedNft.RBXL] = IERC721(landsContractAddress);
        nftContracts[TradedNft.RBFB] = IERC721(botsContractAddress);
        feeCollectorAddress = _msgSender();
    }


    function setSupportedCoins(Coin[] memory newCoins) external onlyOwner {
        supportedCoins = newCoins;
    }

    function setRentingStorageContract(address storageContractAddress) external onlyOwner {
        rentingStorageContract = IRentingContractStorage(storageContractAddress);
    }


    function updateFees(uint256 newFeePercent, address newFeeCollectorAddress) external onlyOwner {
        require(newFeePercent < 100, "Incorrect fee");
        require(newFeeCollectorAddress != address(0), "Incorrect fee");
        feePercent = newFeePercent;
        feeCollectorAddress = newFeeCollectorAddress;
        emit FeesUpdate(_msgSender(), newFeePercent, newFeeCollectorAddress);
    }


    function listToken(TradedNft nft, uint256 tokenId, uint256 price, Coin coin, uint256 duration, address allowedBuyer) external whenNotPaused {
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");
        require(containsCoin(supportedCoins, coin), "Not supported payment currency");
        require(tokenId > 0, "Unknown token ID");
        require(price >= 100, "Price is to loo");
        require(duration != 0, "duration is to loo");
        require(this.getListing(nft, tokenId).seller != _msgSender(), "Token already listed");
        require(!isTokenListedForRent(nft, tokenId), "Token already listed for the renting");
        require(allowedBuyer == address(0) || allowedBuyer != _msgSender(), "Whitelisted buyer incorrect");

        require(isApproved(nft, tokenId), "Not approved");

        uint256 endTs =  block.timestamp + duration;
        marketplaceStorage.setListing(nft, tokenId, coin, price, _msgSender(), endTs, allowedBuyer);
        emit TokenListed(msg.sender, nft, tokenId, price, coin, endTs, allowedBuyer);
    }

    function cancelListing(TradedNft nft, uint256 tokenId) external nonReentrant whenNotPaused {
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");

        marketplaceStorage.deleteListing(nft, tokenId);

        emit ListingCanceled(msg.sender, nft, tokenId);
    }


    function updateListing(TradedNft nft, uint256 tokenId, uint256 price, Coin coin, uint256 duration, address allowedBuyer) external nonReentrant whenNotPaused {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        require(isOwnerOf(nft, tokenId, _msgSender()), "Caller is not an owner");
        require(containsCoin(supportedCoins, coin), "Not supported payment currency");
        require(price >= 100, "Price is to low");
        require(listing.seller != address(0), "Token is not listed");
        require(listing.endTs >= block.timestamp, "Listing expired");
        uint256 endTs = block.timestamp + duration;
        marketplaceStorage.setListing(nft, tokenId, coin, price, _msgSender(), endTs, allowedBuyer);
        emit TokenListingUpdated(msg.sender, nft, tokenId, price, coin, endTs, allowedBuyer);
    }

    function buyItem(TradedNft nft, uint256 tokenId) external nonReentrant whenNotPaused {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        require(listing.seller != address(0), "Listing not found");
        require(isOwnerOf(nft, tokenId, listing.seller), "Incorrect owner of the token");
        require(listing.endTs >= block.timestamp, "Listing expired");
        require(listing.allowedBuyer == address(0) || listing.allowedBuyer == _msgSender(), "Address not whitelisted");

        if (!transferPayment(listing.coin, listing.price, listing.seller)) {
            revert("Failed to transfer payment");
        }

        marketplaceStorage.deleteListing(nft, tokenId);

        IERC721(nftContracts[nft]).safeTransferFrom(listing.seller, _msgSender(), tokenId);
        emit TokenBought(_msgSender(), nft, tokenId, listing.coin, listing.price);
    }

    function transferPayment(Coin coin, uint256 price, address seller) private returns (bool) {
        IERC20 paymentContract = IERC20(paymentContracts[coin]);
        uint256 fee = getPlatformFee(price);
        uint256 sellerAward = price - fee;
        if (!paymentContract.transferFrom(_msgSender(), feeCollectorAddress, fee) || !paymentContract.transferFrom(_msgSender(), seller, sellerAward)) {
            return false;
        }
        return true;
    }

    function getListing(TradedNft nft, uint256 tokenId) public view returns (Listing memory) {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        if (isOwnerOf(nft, tokenId, listing.seller) && listing.endTs > block.timestamp) {
            return listing;
        }
        return Listing(TradedNft.RBXL, 0, Coin.XOIL, 0, address(0), 0, address(0));
    }

    function validListingExists(TradedNft nft, uint256 tokenId) public view returns (bool) {
        Listing memory listing = marketplaceStorage.getListing(nft, tokenId);
        if (isOwnerOf(nft, tokenId, listing.seller) && listing.endTs > block.timestamp) {
            return true;
        }
        return false;
    }

    function anyListingsExist(TradedNft nft, uint256[] memory tokenIds) external view returns (bool) {
        for (uint i = 0; i < tokenIds.length; i++) {
            if (validListingExists(nft, tokenIds[i])) {
                return true;
            }
        }
        return false;
    }

    function getListingByIdx(TradedNft nft, uint idx) external view returns (Listing memory) {
        return marketplaceStorage.getListingByIdx(nft, idx);
    }

    function getNotValidListings(TradedNft nft, uint256 searchFromIdx, uint256 searchToIdx) external view returns (uint256[] memory) {
        require(searchFromIdx < searchToIdx, "Incorrect parameters");
        uint256[] memory tokenIdsToDelete =  new uint[](searchToIdx - searchFromIdx);
        uint deleteCounter = 0;
        for (uint i = searchFromIdx; i < searchToIdx; i++) {
            Listing memory listing = marketplaceStorage.getListingByIdx(nft, i);
            if ((listing.seller != address(0) && !isOwnerOf(nft, listing.tokenId, listing.seller)) || (listing.endTs > 0 && listing.endTs <= block.timestamp)) {
                tokenIdsToDelete[deleteCounter++] = listing.tokenId;
            }
        }
        uint256[] memory trimmedResult = new uint256[](deleteCounter);
        for (uint j = 0; j < deleteCounter; j++) {
            trimmedResult[j] = tokenIdsToDelete[j];
        }

        return trimmedResult;
    }

    function removeNotValidListings(TradedNft nft, uint256[] memory ids) external {
        for (uint i = 0; i < ids.length; i++) {
            Listing memory listing = marketplaceStorage.getListing(nft, ids[i]);
            if ((listing.seller != address(0) && !isOwnerOf(nft, listing.tokenId, listing.seller)) || (listing.endTs > 0 && listing.endTs <= block.timestamp)) {
                marketplaceStorage.deleteListing(nft, listing.tokenId);
            }
        }
    }


    function getListings(TradedNft nft, uint page) external view returns (Listing[] memory, bool) {
        Listing[] memory result = new Listing[](PAGE_SIZE);
        uint counter = 0;
        for (uint i = PAGE_SIZE * page; i < PAGE_SIZE * (page + 1); i++) {
            Listing memory listing = marketplaceStorage.getListingByIdx(nft, i);
            if (listing.seller != address(0) && isOwnerOf(nft, listing.tokenId, listing.seller) && listing.endTs > block.timestamp) {
                result[counter++] = listing;
            }
        }

        Listing[] memory trimmedResult = new Listing[](counter);
        for (uint j = 0; j < counter; j++) {
            trimmedResult[j] = result[j];
        }
        return (trimmedResult, marketplaceStorage.getListingByIdx(nft, PAGE_SIZE * (page + 1)).seller != address(0));
    }

    function isOwnerOf(TradedNft nft, uint256 tokenId, address assetOwner) private view returns (bool) {
        return nftContracts[nft].ownerOf(tokenId) == assetOwner;
    }

    function isApproved(TradedNft nft, uint256 tokenId) private view returns (bool) {
        return nftContracts[nft].getApproved(tokenId) == address(this) || nftContracts[nft].isApprovedForAll(_msgSender(), address(this));
    }

    function isTokenListedForRent(TradedNft nft, uint256 tokenId) private view returns (bool) {
        if (nft == TradedNft.RBXL) {
            return rentingStorageContract.getLandStatus(tokenId) != IRentingTypes.TokenRentingStatus.AVAILABLE;
        } else if (nft == TradedNft.RBFB) {
            return rentingStorageContract.getBotStatus(tokenId) != IRentingTypes.TokenRentingStatus.AVAILABLE;
        }
        return false;
    }


    function getPlatformFee(uint256 price) private view returns (uint256){
        return (price * feePercent) / 100;
    }

    function containsCoin(Coin[] memory array, Coin value) private pure returns (bool) {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                return true;
            }
        }
        return false;
    }

    /**
    * @dev Pauses operations.
    */
    function pause() external onlyOwner {
        _pause();
    }

    /**
    * @dev Unpauses operations.
    */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     *
     * @dev Allow owner to transfer ERC-20 token from contract
     *
     * @param tokenContract contract address of corresponding token
     * @param amount amount of token to be transferred
     *
     */
    function withdrawToken(address tokenContract, uint256 amount) external onlyOwner {
        if (IERC20(tokenContract).transfer(msg.sender, amount)) {
            emit TokenWithdrawn(tokenContract, amount);
        }
    }


}