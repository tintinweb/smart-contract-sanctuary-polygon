// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IBigBang {
    struct AccrueInfo {
        uint64 debtRate;
        uint64 lastAccrued;
    }

    function accrueInfo()
        external
        view
        returns (uint64 debtRate, uint64 lastAccrued);

    function minDebtRate() external view returns (uint256);

    function maxDebtRate() external view returns (uint256);

    function debtRateAgainstEthMarket() external view returns (uint256);

    function penrose() external view returns (address);

    function getDebtRate() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ICommonData {
    struct IWithdrawParams {
        bool withdraw;
        uint256 withdrawLzFeeAmount;
        bool withdrawOnOtherChain;
        uint16 withdrawLzChainId;
        bytes withdrawAdapterParams;
    }

    struct ISendOptions {
        uint256 extraGasLimit;
        address zroPaymentAddress;
    }

    struct IApproval {
        bool permitAll;
        bool allowFailure;
        address target;
        bool permitBorrow;
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct ICommonExternalContracts {
        address magnetar;
        address singularity;
        address bigBang;
    }

    struct IDepositData {
        bool deposit;
        uint256 amount;
        bool extractFromSender;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IMarket {
    function asset() external view returns (address);

    function assetId() external view returns (uint256);

    function collateral() external view returns (address);

    function collateralId() external view returns (uint256);

    function totalBorrowCap() external view returns (uint256);

    function totalCollateralShare() external view returns (uint256);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function totalBorrow()
        external
        view
        returns (uint128 elastic, uint128 base);

    function oracle() external view returns (address);

    function oracleData() external view returns (bytes memory);

    function exchangeRate() external view returns (uint256);

    function yieldBox() external view returns (address payable);

    function liquidationMultiplier() external view returns (uint256);

    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 amount,
        uint256 share
    ) external;

    function removeCollateral(address from, address to, uint256 share) external;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function execute(
        bytes[] calldata calls,
        bool revertOnFail
    ) external returns (bool[] memory successes, string[] memory results);

    function refreshPenroseFees(
        address feeTo
    ) external returns (uint256 feeShares);

    function penrose() external view returns (address);

    function owner() external view returns (address);

    function buyCollateral(
        address from,
        uint256 borrowAmount,
        uint256 supplyAmount,
        uint256 minAmountOut,
        address swapper,
        bytes calldata dexData
    ) external returns (uint256 amountOut);

    function sellCollateral(
        address from,
        uint256 share,
        uint256 minAmountOut,
        address swapper,
        bytes calldata dexData
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IOracle {
    // @notice Precision of the return value.
    function decimals() external view returns (uint8);

    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(
        bytes calldata data
    ) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(
        bytes calldata data
    ) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ISwapper.sol";

interface IPenrose {
    /// @notice swap extra data
    struct SwapData {
        uint256 minAssetAmount;
    }

    /// @notice Used to define the MasterContract's type
    enum ContractType {
        lowRisk,
        mediumRisk,
        highRisk
    }

    /// @notice MasterContract address and type
    struct MasterContract {
        address location;
        ContractType risk;
    }

    function bigBangEthMarket() external view returns (address);

    function bigBangEthDebtRate() external view returns (uint256);

    function swappers(ISwapper swapper) external view returns (bool);

    function yieldBox() external view returns (address payable);

    function tapToken() external view returns (address);

    function tapAssetId() external view returns (uint256);

    function usdoToken() external view returns (address);

    function usdoAssetId() external view returns (uint256);

    function feeTo() external view returns (address);

    function wethToken() external view returns (address);

    function wethAssetId() external view returns (uint256);

    function isMarketRegistered(address market) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISendFrom {
    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        LzCallParams calldata _callParams
    ) external payable;

    function useCustomAdapterParams() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./IMarket.sol";
import {IUSDOBase} from "./IUSDO.sol";

interface ISingularity is IMarket {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerSecond,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) external returns (uint256 share);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function liquidationQueue() external view returns (address payable);

    function computeAllowedLendShare(
        uint256 amount,
        uint256 tokenId
    ) external view returns (uint256 share);

    function getInterestDetails()
        external
        view
        returns (AccrueInfo memory _accrueInfo, uint256 utilization);

    function multiHopBuyCollateral(
        address from,
        uint256 collateralAmount,
        uint256 borrowAmount,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;

    function multiHopSellCollateral(
        address from,
        uint256 share,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ISwapper {
    struct SwapTokensData {
        address tokenIn;
        uint256 tokenInId;
        address tokenOut;
        uint256 tokenOutId;
    }

    struct SwapAmountData {
        uint256 amountIn;
        uint256 shareIn;
        uint256 amountOut;
        uint256 shareOut;
    }

    struct YieldBoxData {
        bool withdrawFromYb;
        bool depositToYb;
    }

    struct SwapData {
        SwapTokensData tokensData;
        SwapAmountData amountData;
        YieldBoxData yieldBoxData;
    }

    //Add more overloads if needed
    function buildSwapData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external view returns (SwapData memory);

    function buildSwapData(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn,
        uint256 shareIn,
        bool withdrawFromYb,
        bool depositToYb
    ) external view returns (SwapData memory);

    function getDefaultDexOptions() external view returns (bytes memory);

    function getOutputAmount(
        SwapData calldata swapData,
        bytes calldata dexOptions
    ) external view returns (uint256 amountOut);

    function getInputAmount(
        SwapData calldata swapData,
        bytes calldata dexOptions
    ) external view returns (uint256 amountIn);

    function swap(
        SwapData calldata swapData,
        uint256 amountOutMin,
        address to,
        bytes calldata dexOptions
    ) external returns (uint256 amountOut, uint256 shareOut);
}

interface ICurveSwapper is ISwapper {
    function curvePool() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "./ISendFrom.sol";
import {IUSDOBase} from "./IUSDO.sol";
import "./ICommonData.sol";

interface ITapiocaOFTBase {
    function hostChainID() external view returns (uint256);

    function wrap(
        address fromAddress,
        address toAddress,
        uint256 amount
    ) external;

    function wrapNative(address _toAddress) external payable;

    function unwrap(address _toAddress, uint256 _amount) external;

    function erc20() external view returns (address);

    function lzEndpoint() external view returns (address);
}

/// @dev used for generic TOFTs
interface ITapiocaOFT is ISendFrom, ITapiocaOFTBase {
    struct IRemoveParams {
        uint256 amount;
        address marketHelper;
        address market;
    }

    struct IBorrowParams {
        uint256 amount;
        uint256 borrowAmount;
        address marketHelper;
        address market;
    }

    function totalFees() external view returns (uint256);

    function erc20() external view returns (address);

    function wrappedAmount(uint256 _amount) external view returns (uint256);

    function isHostChain() external view returns (bool);

    function balanceOf(address _holder) external view returns (uint256);

    function isTrustedRemote(
        uint16 lzChainId,
        bytes calldata path
    ) external view returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool);

    function extractUnderlying(uint256 _amount) external;

    function harvestFees() external;

    /// OFT specific methods
    function sendToYBAndBorrow(
        address _from,
        address _to,
        uint16 lzDstChainId,
        bytes calldata airdropAdapterParams,
        IBorrowParams calldata borrowParams,
        ICommonData.IWithdrawParams calldata withdrawParams,
        ICommonData.ISendOptions calldata options,
        ICommonData.IApproval[] calldata approvals
    ) external payable;

    function sendToStrategy(
        address _from,
        address _to,
        uint256 amount,
        uint256 share,
        uint256 assetId,
        uint16 lzDstChainId,
        ICommonData.ISendOptions calldata options
    ) external payable;

    function retrieveFromStrategy(
        address _from,
        uint256 amount,
        uint256 share,
        uint256 assetId,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes memory airdropAdapterParam
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData
    ) external payable;

    function removeCollateral(
        address from,
        address to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        ICommonData.IWithdrawParams calldata withdrawParams,
        ITapiocaOFT.IRemoveParams calldata removeParams,
        ICommonData.IApproval[] calldata approvals,
        bytes calldata adapterParams
    ) external payable;

    function initMultiSell(
        address from,
        uint256 share,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData,
        bytes calldata airdropAdapterParams,
        ICommonData.IApproval[] calldata approvals
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaOptionLiquidityProvision {
    struct IOptionsLockData {
        bool lock;
        address target;
        uint128 lockDuration;
        uint128 amount;
        uint256 fraction;
    }

    struct IOptionsUnlockData {
        bool unlock;
        address target;
        uint256 tokenId;
    }

    function yieldBox() external view returns (address);

    function activeSingularities(
        address singularity
    )
        external
        view
        returns (
            uint256 sglAssetId,
            uint256 totalDeposited,
            uint256 poolWeight
        );

    function lock(
        address to,
        address singularity,
        uint128 lockDuration,
        uint128 amount
    ) external returns (uint256 tokenId);

    function unlock(
        uint256 tokenId,
        address singularity,
        address to
    ) external returns (uint256 sharesOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface ITapiocaOptions {
    struct TapOption {
        uint128 expiry; // timestamp, as once one wise man said, the sun will go dark before this overflows
        uint128 discount; // discount in basis points
        uint256 tOLP; // tOLP token ID
    }

    function attributes(
        uint256 _tokenId
    ) external view returns (address, TapOption memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import {ICommonOFT} from "tapioca-sdk/dist/contracts/token/oft/v2/ICommonOFT.sol";
import "./ICommonData.sol";

interface ITapiocaOptionsBrokerCrossChain {
    struct IExerciseOptionsData {
        address from;
        address target;
        uint256 paymentTokenAmount;
        uint256 oTAPTokenID;
        address paymentToken;
        uint256 tapAmount;
    }
    struct IExerciseLZData {
        uint16 lzDstChainId;
        address zroPaymentAddress;
        uint256 extraGas;
    }
    struct IExerciseLZSendTapData {
        bool withdrawOnAnotherChain;
        address tapOftAddress;
        uint16 lzDstChainId;
        uint256 amount;
        address zroPaymentAddress;
        uint256 extraGas;
    }

    function exerciseOption(
        IExerciseOptionsData calldata optionsData,
        IExerciseLZData calldata lzData,
        IExerciseLZSendTapData calldata tapSendData,
        ICommonData.IApproval[] calldata approvals
    ) external payable;
}

interface ITapiocaOptionsBroker {
    struct IOptionsParticipateData {
        bool participate;
        address target;
        uint256 tOLPTokenId;
    }

    struct IOptionsExitData {
        bool exit;
        address target;
        uint256 oTAPTokenID;
    }

    function oTAP() external view returns (address);

    function exerciseOption(
        uint256 oTAPTokenID,
        address paymentToken,
        uint256 tapAmount
    ) external;

    function participate(
        uint256 tOLPTokenID
    ) external returns (uint256 oTAPTokenID);

    function exitPosition(uint256 oTAPTokenID) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IMarket.sol";
import "./ISingularity.sol";
import "./ITapiocaOptionsBroker.sol";
import "./ITapiocaOptionLiquidityProvision.sol";
import "./ICommonData.sol";

interface IUSDOBase {
    // remove and repay
    struct ILeverageExternalContractsData {
        address swapper;
        address magnetar;
        address tOft;
        address srcMarket;
    }

    struct IRemoveAndRepay {
        bool removeAssetFromSGL;
        uint256 removeAmount; //slightly greater than repayAmount to cover the interest
        bool repayAssetOnBB;
        uint256 repayAmount; // on BB
        bool removeCollateralFromBB;
        uint256 collateralAmount; // from BB
        ITapiocaOptionsBroker.IOptionsExitData exitData;
        ITapiocaOptionLiquidityProvision.IOptionsUnlockData unlockData;
        ICommonData.IWithdrawParams assetWithdrawData;
        ICommonData.IWithdrawParams collateralWithdrawData;
    }

    // lend or repay
    struct ILendOrRepayParams {
        bool repay;
        uint256 depositAmount;
        uint256 repayAmount;
        address marketHelper;
        address market;
        bool removeCollateral;
        uint256 removeCollateralShare;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionsBroker.IOptionsParticipateData participateData;
    }

    //leverage data
    struct ILeverageLZData {
        uint256 srcExtraGasLimit;
        uint16 lzSrcChainId;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes dstAirdropAdapterParam;
        bytes srcAirdropAdapterParam;
        address refundAddress;
    }

    struct ILeverageSwapData {
        address tokenOut;
        uint256 amountOutMin;
        bytes data;
    }

    struct IMintData {
        bool mint;
        uint256 mintAmount;
        ICommonData.IDepositData collateralDepositData;
    }

    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function sendAndLendOrRepay(
        address _from,
        address _to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        ILendOrRepayParams calldata lendParams,
        ICommonData.IApproval[] calldata approvals,
        ICommonData.IWithdrawParams calldata withdrawParams, //collateral remove data
        bytes calldata adapterParams
    ) external payable;

    function sendForLeverage(
        uint256 amount,
        address leverageFor,
        ILeverageLZData calldata lzData,
        ILeverageSwapData calldata swapData,
        ILeverageExternalContractsData calldata externalData
    ) external payable;

    function initMultiHopBuy(
        address from,
        uint256 collateralAmount,
        uint256 borrowAmount,
        IUSDOBase.ILeverageSwapData calldata swapData,
        IUSDOBase.ILeverageLZData calldata lzData,
        IUSDOBase.ILeverageExternalContractsData calldata externalData,
        bytes calldata airdropAdapterParams,
        ICommonData.IApproval[] memory approvals
    ) external payable;

    function removeAsset(
        address from,
        address to,
        uint16 lzDstChainId,
        address zroPaymentAddress,
        bytes calldata adapterParams,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData,
        ICommonData.IApproval[] calldata approvals
    ) external payable;
}

interface IUSDO is IUSDOBase, IERC20Metadata {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "tapioca-sdk/dist/contracts/YieldBox/contracts/enums/YieldBoxTokenType.sol";

interface IYieldBoxBase {
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function isApprovedForAll(
        address user,
        address spender
    ) external view returns (bool);

    function setApprovalForAll(address spender, bool status) external;

    function assets(
        uint256 assetId
    )
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function assetTotals(
        uint256 assetId
    ) external view returns (uint256 totalShare, uint256 totalAmount);

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function balanceOf(
        address user,
        uint256 assetId
    ) external view returns (uint256 share);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//OZ
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//TAPIOCA
import "./MagnetarV2Storage.sol";
import "./modules/MagnetarMarketModule.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

contract MagnetarV2 is Ownable, MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    // ************ //
    // *** VARS *** //
    // ************ //
    enum Module {
        Market
    }

    /// @notice returns the Market module
    MagnetarMarketModule public marketModule;

    constructor(address _owner, address payable _marketModule) {
        transferOwnership(_owner);
        marketModule = MagnetarMarketModule(_marketModule);
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns Singularity markets' information
    /// @param who user to return for
    /// @param markets the list of Singularity markets to query for
    function singularityMarketInfo(
        address who,
        ISingularity[] calldata markets
    ) external view returns (SingularityInfo[] memory) {
        return _singularityMarketInfo(who, markets);
    }

    /// @notice returns BigBang markets' information
    /// @param who user to return for
    /// @param markets the list of BigBang markets to query for
    function bigBangMarketInfo(
        address who,
        IBigBang[] calldata markets
    ) external view returns (BigBangInfo[] memory) {
        return _bigBangMarketInfo(who, markets);
    }

    /// @notice Calculate the collateral amount off the shares.
    /// @param market the Singularity or BigBang address
    /// @param share The shares.
    /// @return amount The amount.
    function getCollateralAmountForShare(
        IMarket market,
        uint256 share
    ) external view returns (uint256 amount) {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        return yieldBox.toAmount(market.collateralId(), share, false);
    }

    /// @notice Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The borrow part.
    /// @return collateralShares The collateral shares.
    function getCollateralSharesForBorrowPart(
        IMarket market,
        uint256 borrowPart,
        uint256 liquidationMultiplierPrecision,
        uint256 exchangeRatePrecision
    ) external view returns (uint256 collateralShares) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());
        uint256 borrowAmount = _totalBorrowed.toElastic(borrowPart, false);
        return
            yieldBox.toShare(
                market.collateralId(),
                (borrowAmount *
                    market.liquidationMultiplier() *
                    market.exchangeRate()) /
                    (liquidationMultiplierPrecision * exchangeRatePrecision),
                false
            );
    }

    /// @notice Return the equivalent of borrow part in asset amount.
    /// @param market the Singularity or BigBang address
    /// @param borrowPart The amount of borrow part to convert.
    /// @return amount The equivalent of borrow part in asset amount.
    function getAmountForBorrowPart(
        IMarket market,
        uint256 borrowPart
    ) external view returns (uint256 amount) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toElastic(borrowPart, false);
    }

    /// @notice Return the equivalent of amount in borrow part.
    /// @param market the Singularity or BigBang address
    /// @param amount The amount to convert.
    /// @return part The equivalent of amount in borrow part.
    function getBorrowPartForAmount(
        IMarket market,
        uint256 amount
    ) external view returns (uint256 part) {
        Rebase memory _totalBorrowed;
        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);

        return _totalBorrowed.toBase(amount, false);
    }

    /// @notice Compute the amount of `singularity.assetId` from `fraction`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(
        ISingularity singularity,
        uint256 fraction
    ) external view returns (uint256 amount) {
        (uint128 totalAssetElastic, uint128 totalAssetBase) = singularity
            .totalAsset();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());
        return
            yieldBox.toAmount(
                singularity.assetId(),
                (fraction * totalAssetElastic) / totalAssetBase,
                false
            );
    }

    /// @notice Compute the fraction of `singularity.assetId` from `amount`
    /// `fraction` can be `singularity.accrueInfo.feeFraction` or `singularity.balanceOf`
    /// @param singularity the singularity address
    /// @param amount The amount.
    /// @return fraction The fraction.
    function getFractionForAmount(
        ISingularity singularity,
        uint256 amount
    ) external view returns (uint256 fraction) {
        (uint128 totalAssetShare, uint128 totalAssetBase) = singularity
            .totalAsset();
        (uint128 totalBorrowElastic, ) = singularity.totalBorrow();
        uint256 assetId = singularity.assetId();

        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        uint256 share = yieldBox.toShare(assetId, amount, false);
        uint256 allShare = totalAssetShare +
            yieldBox.toShare(assetId, totalBorrowElastic, true);

        fraction = allShare == 0 ? share : (share * totalAssetBase) / allShare;
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //
    /// @notice Batch multiple calls together
    /// @param calls The list of actions to perform
    function burst(
        Call[] calldata calls
    ) external payable returns (Result[] memory returnData) {
        uint256 valAccumulator;

        uint256 length = calls.length;
        returnData = new Result[](length);

        for (uint256 i = 0; i < length; i++) {
            Call calldata _action = calls[i];
            if (!_action.allowFailure) {
                require(
                    _action.call.length > 0,
                    string.concat(
                        "MagnetarV2: Missing call for action with index",
                        string(abi.encode(i))
                    )
                );
            }

            unchecked {
                valAccumulator += _action.value;
            }

            if (_action.id == PERMIT_ALL) {
                _permit(
                    _action.target,
                    _action.call,
                    true,
                    _action.allowFailure
                );
            } else if (_action.id == PERMIT) {
                _permit(
                    _action.target,
                    _action.call,
                    false,
                    _action.allowFailure
                );
            } else if (_action.id == TOFT_WRAP) {
                WrapData memory data = abi.decode(_action.call[4:], (WrapData));
                _checkSender(data.from);
                if (_action.value > 0) {
                    unchecked {
                        valAccumulator += _action.value;
                    }
                    ITapiocaOFT(_action.target).wrapNative{
                        value: _action.value
                    }(data.to);
                } else {
                    ITapiocaOFT(_action.target).wrap(
                        msg.sender,
                        data.to,
                        data.amount
                    );
                }
            } else if (_action.id == TOFT_SEND_FROM) {
                (
                    address from,
                    uint16 dstChainId,
                    bytes32 to,
                    uint256 amount,
                    ISendFrom.LzCallParams memory lzCallParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint16,
                            bytes32,
                            uint256,
                            (ISendFrom.LzCallParams)
                        )
                    );
                _checkSender(from);

                ISendFrom(_action.target).sendFrom{value: _action.value}(
                    msg.sender,
                    dstChainId,
                    to,
                    amount,
                    lzCallParams
                );
            } else if (_action.id == YB_DEPOSIT_ASSET) {
                YieldBoxDepositData memory data = abi.decode(
                    _action.call[4:],
                    (YieldBoxDepositData)
                );
                _checkSender(data.from);

                (uint256 amountOut, uint256 shareOut) = IYieldBoxBase(
                    _action.target
                ).depositAsset(
                        data.assetId,
                        msg.sender,
                        data.to,
                        data.amount,
                        data.share
                    );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amountOut, shareOut)
                });
            } else if (_action.id == MARKET_ADD_COLLATERAL) {
                SGLAddCollateralData memory data = abi.decode(
                    _action.call[4:],
                    (SGLAddCollateralData)
                );
                _checkSender(data.from);

                IMarket(_action.target).addCollateral(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.amount,
                    data.share
                );
            } else if (_action.id == MARKET_BORROW) {
                SGLBorrowData memory data = abi.decode(
                    _action.call[4:],
                    (SGLBorrowData)
                );
                _checkSender(data.from);

                (uint256 part, uint256 share) = IMarket(_action.target).borrow(
                    msg.sender,
                    data.to,
                    data.amount
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(part, share)
                });
            } else if (_action.id == YB_WITHDRAW_TO) {
                (
                    address yieldBox,
                    address from,
                    uint256 assetId,
                    uint16 dstChainId,
                    bytes32 receiver,
                    uint256 amount,
                    uint256 share,
                    bytes memory adapterParams,
                    address payable refundAddress
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint16,
                            bytes32,
                            uint256,
                            uint256,
                            bytes,
                            address
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule.withdrawToChain.selector,
                        yieldBox,
                        from,
                        assetId,
                        dstChainId,
                        receiver,
                        amount,
                        share,
                        adapterParams,
                        refundAddress,
                        _action.value
                    )
                );
            } else if (_action.id == MARKET_LEND) {
                SGLLendData memory data = abi.decode(
                    _action.call[4:],
                    (SGLLendData)
                );
                _checkSender(data.from);

                uint256 fraction = IMarket(_action.target).addAsset(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.share
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(fraction)
                });
            } else if (_action.id == MARKET_REPAY) {
                SGLRepayData memory data = abi.decode(
                    _action.call[4:],
                    (SGLRepayData)
                );
                _checkSender(data.from);

                uint256 amount = IMarket(_action.target).repay(
                    msg.sender,
                    data.to,
                    data.skim,
                    data.part
                );
                returnData[i] = Result({
                    success: true,
                    returnData: abi.encode(amount)
                });
            } else if (_action.id == TOFT_SEND_AND_BORROW) {
                (
                    address from,
                    address to,
                    uint16 lzDstChainId,
                    bytes memory airdropAdapterParams,
                    ITapiocaOFT.IBorrowParams memory borrowParams,
                    ICommonData.IWithdrawParams memory withdrawParams,
                    ICommonData.ISendOptions memory options,
                    ICommonData.IApproval[] memory approvals
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            bytes,
                            ITapiocaOFT.IBorrowParams,
                            ICommonData.IWithdrawParams,
                            ICommonData.ISendOptions,
                            ICommonData.IApproval[]
                        )
                    );
                _checkSender(from);

                ITapiocaOFT(_action.target).sendToYBAndBorrow{
                    value: _action.value
                }(
                    msg.sender,
                    to,
                    lzDstChainId,
                    airdropAdapterParams,
                    borrowParams,
                    withdrawParams,
                    options,
                    approvals
                );
            } else if (_action.id == TOFT_SEND_AND_LEND) {
                (
                    address from,
                    address to,
                    uint16 dstChainId,
                    address zroPaymentAddress,
                    IUSDOBase.ILendOrRepayParams memory lendParams,
                    ICommonData.IApproval[] memory approvals,
                    ICommonData.IWithdrawParams memory withdrawParams,
                    bytes memory adapterParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint16,
                            address,
                            (IUSDOBase.ILendOrRepayParams),
                            (ICommonData.IApproval[]),
                            (ICommonData.IWithdrawParams),
                            bytes
                        )
                    );
                _checkSender(from);

                IUSDOBase(_action.target).sendAndLendOrRepay{
                    value: _action.value
                }(
                    msg.sender,
                    to,
                    dstChainId,
                    zroPaymentAddress,
                    lendParams,
                    approvals,
                    withdrawParams,
                    adapterParams
                );
            } else if (_action.id == TOFT_DEPOSIT_TO_STRATEGY) {
                TOFTSendToStrategyData memory data = abi.decode(
                    _action.call[4:],
                    (TOFTSendToStrategyData)
                );
                _checkSender(data.from);

                ITapiocaOFT(_action.target).sendToStrategy{
                    value: _action.value
                }(
                    msg.sender,
                    data.to,
                    data.amount,
                    data.share,
                    data.assetId,
                    data.lzDstChainId,
                    data.options
                );
            } else if (_action.id == TOFT_RETRIEVE_FROM_STRATEGY) {
                (
                    address from,
                    uint256 amount,
                    uint256 share,
                    uint256 assetId,
                    uint16 lzDstChainId,
                    address zroPaymentAddress,
                    bytes memory airdropAdapterParam
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            uint256,
                            uint256,
                            uint256,
                            uint16,
                            address,
                            bytes
                        )
                    );

                _checkSender(from);

                ITapiocaOFT(_action.target).retrieveFromStrategy{
                    value: _action.value
                }(
                    msg.sender,
                    amount,
                    share,
                    assetId,
                    lzDstChainId,
                    zroPaymentAddress,
                    airdropAdapterParam
                );
            } else if (_action.id == MARKET_YBDEPOSIT_AND_LEND) {
                HelperLendData memory data = abi.decode(
                    _action.call[4:],
                    (HelperLendData)
                );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule.mintFromBBAndLendOnSGL.selector,
                        data.user,
                        data.lendAmount,
                        data.mintData,
                        data.depositData,
                        data.lockData,
                        data.participateData,
                        data.externalContracts
                    )
                );
            } else if (_action.id == MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW) {
                (
                    address market,
                    address user,
                    uint256 collateralAmount,
                    uint256 borrowAmount,
                    ,
                    bool deposit,
                    ICommonData.IWithdrawParams memory withdrawParams
                ) = abi.decode(
                        _action.call[4:],
                        (
                            address,
                            address,
                            uint256,
                            uint256,
                            bool,
                            bool,
                            ICommonData.IWithdrawParams
                        )
                    );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositAddCollateralAndBorrowFromMarket
                            .selector,
                        market,
                        user,
                        collateralAmount,
                        borrowAmount,
                        false,
                        deposit,
                        withdrawParams
                    )
                );
            } else if (_action.id == MARKET_REMOVE_ASSET) {
                HelperMarketRemoveAndRepayAsset memory data = abi.decode(
                    _action.call[4:],
                    (HelperMarketRemoveAndRepayAsset)
                );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .exitPositionAndRemoveCollateral
                            .selector,
                        data.user,
                        data.externalData,
                        data.removeAndRepayData
                    )
                );
            } else if (_action.id == MARKET_DEPOSIT_REPAY_REMOVE_COLLATERAL) {
                HelperDepositRepayRemoveCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperDepositRepayRemoveCollateral)
                );

                _executeModule(
                    Module.Market,
                    abi.encodeWithSelector(
                        MagnetarMarketModule
                            .depositRepayAndRemoveCollateralFromMarket
                            .selector,
                        data.market,
                        data.user,
                        data.depositAmount,
                        data.repayAmount,
                        data.collateralAmount,
                        data.extractFromSender,
                        data.withdrawCollateralParams
                    )
                );
            } else if (_action.id == MARKET_BUY_COLLATERAL) {
                HelperBuyCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperBuyCollateral)
                );

                IMarket(data.market).buyCollateral(
                    data.from,
                    data.borrowAmount,
                    data.supplyAmount,
                    data.minAmountOut,
                    address(data.swapper),
                    data.dexData
                );
            } else if (_action.id == MARKET_SELL_COLLATERAL) {
                HelperSellCollateral memory data = abi.decode(
                    _action.call[4:],
                    (HelperSellCollateral)
                );

                IMarket(data.market).sellCollateral(
                    data.from,
                    data.share,
                    data.minAmountOut,
                    address(data.swapper),
                    data.dexData
                );
            } else if (_action.id == TAP_EXERCISE_OPTION) {
                HelperExerciseOption memory data = abi.decode(
                    _action.call[4:],
                    (HelperExerciseOption)
                );

                ITapiocaOptionsBrokerCrossChain(_action.target).exerciseOption(
                    data.optionsData,
                    data.lzData,
                    data.tapSendData,
                    data.approvals
                );
            } else if (_action.id == MARKET_MULTIHOP_BUY) {
                HelperMultiHopBuy memory data = abi.decode(
                    _action.call[4:],
                    (HelperMultiHopBuy)
                );

                IUSDOBase(_action.target).initMultiHopBuy(
                    data.from,
                    data.collateralAmount,
                    data.borrowAmount,
                    data.swapData,
                    data.lzData,
                    data.externalData,
                    data.airdropAdapterParams,
                    data.approvals
                );
            } else if (_action.id == MARKET_MULTIHOP_BUY) {
                HelperMultiHopBuy memory data = abi.decode(
                    _action.call[4:],
                    (HelperMultiHopBuy)
                );

                IUSDOBase(_action.target).initMultiHopBuy(
                    data.from,
                    data.collateralAmount,
                    data.borrowAmount,
                    data.swapData,
                    data.lzData,
                    data.externalData,
                    data.airdropAdapterParams,
                    data.approvals
                );
            } else if (_action.id == TOFT_REMOVE_AND_REPAY) {
                HelperTOFTRemoveAndRepayAsset memory data = abi.decode(
                    _action.call[4:],
                    (HelperTOFTRemoveAndRepayAsset)
                );

                IUSDOBase(_action.target).removeAsset(
                    data.from,
                    data.to,
                    data.lzDstChainId,
                    data.zroPaymentAddress,
                    data.adapterParams,
                    data.externalData,
                    data.removeAndRepayData,
                    data.approvals
                );
            } else {
                revert("MagnetarV2: action not valid");
            }
        }

        require(msg.value == valAccumulator, "MagnetarV2: value mismatch");
    }

    /// @notice performs a withdraw operation
    /// @dev it can withdraw on the current chain or it can send it to another one
    ///     - if `dstChainId` is 0 performs a same-chain withdrawal
    ///          - all parameters except `yieldBox`, `from`, `assetId` and `amount` or `share` are ignored
    ///     - if `dstChainId` is NOT 0, the method requires gas for the `sendFrom` operation
    /// @param yieldBox the YieldBox address
    /// @param from user to withdraw from
    /// @param assetId the YieldBox asset id to withdraw
    /// @param dstChainId LZ chain id to withdraw to
    /// @param receiver the receiver on the destination chain
    /// @param amount the amount to withdraw
    /// @param share the share to withdraw
    /// @param adapterParams LZ adapter params
    /// @param refundAddress the LZ refund address which receives the gas not used in the process
    /// @param gas the amount of gas to use for sending the asset to another layer
    function withdrawToChain(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.withdrawToChain.selector,
                yieldBox,
                from,
                assetId,
                dstChainId,
                receiver,
                amount,
                share,
                adapterParams,
                refundAddress,
                gas
            )
        );
    }

    /// @notice helper for deposit to YieldBox, add collateral to a market, borrom from the same market and withdraw
    /// @dev all operations are optional:
    ///         - if `deposit` is false it will skip the deposit to YieldBox step
    ///         - if `withdraw` is false it will skip the withdraw step
    ///         - if `collateralAmount == 0` it will skip the add collateral step
    ///         - if `borrowAmount == 0` it will skip the borrow step
    ///     - the amount deposited to YieldBox is `collateralAmount`
    /// @param market the SGL/BigBang market
    /// @param user the user to perform the action for
    /// @param collateralAmount the collateral amount to add
    /// @param borrowAmount the borrow amount
    /// @param extractFromSender extracts collateral tokens from sender or from the user
    /// @param deposit true/false flag for the deposit to YieldBox step
    /// @param withdrawParams necessary data for the same chain or the cross-chain withdrawal
    function depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule
                    .depositAddCollateralAndBorrowFromMarket
                    .selector,
                market,
                user,
                collateralAmount,
                borrowAmount,
                extractFromSender,
                deposit,
                withdrawParams
            )
        );
    }

    /// @notice helper for deposit asset to YieldBox, repay on a market, remove collateral and withdraw
    /// @dev all steps are optional:
    ///         - if `depositAmount` is 0, the deposit to YieldBox step is skipped
    ///         - if `repayAmount` is 0, the repay step is skipped
    ///         - if `collateralAmount` is 0, the add collateral step is skipped
    /// @param market the SGL/BigBang market
    /// @param user the user to perform the action for
    /// @param depositAmount the amount to deposit to YieldBox
    /// @param repayAmount the amount to repay to the market
    /// @param collateralAmount the amount to withdraw from the market
    /// @param extractFromSender extracts collateral tokens from sender or from the user
    /// @param withdrawCollateralParams withdraw specific params
    function depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule
                    .depositRepayAndRemoveCollateralFromMarket
                    .selector,
                market,
                user,
                depositAmount,
                repayAmount,
                collateralAmount,
                extractFromSender,
                withdrawCollateralParams
            )
        );
    }

    /// @notice helper to deposit mint from BB, lend on SGL, lock on tOLP and participate on tOB
    /// @dev all steps are optional:
    ///         - if `mintData.mint` is false, the mint operation on BB is skipped
    ///             - add BB collateral to YB, add collateral on BB and borrow from BB are part of the mint operation
    ///         - if `depositData.deposit` is false, the asset deposit to YB is skipped
    ///         - if `lendAmount == 0` the addAsset operation on SGL is skipped
    ///             - if `mintData.mint` is true, `lendAmount` will be automatically filled with the minted value
    ///         - if `lockData.lock` is false, the tOLP lock operation is skipped
    ///         - if `participateData.participate` is false, the tOB participate operation is skipped
    /// @param user the user to perform the operation for
    /// @param lendAmount the amount to lend on SGL
    /// @param mintData the data needed to mint on BB
    /// @param depositData the data needed for asset deposit on YieldBox
    /// @param lockData the data needed to lock on TapiocaOptionLiquidityProvision
    /// @param participateData the data needed to perform a participate operation on TapiocaOptionsBroker
    /// @param externalContracts the contracts' addresses used in all the operations performed by the helper
    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.mintFromBBAndLendOnSGL.selector,
                user,
                lendAmount,
                mintData,
                depositData,
                lockData,
                participateData,
                externalContracts
            )
        );
    }

    /// @notice helper to exit from  tOB, unlock from tOLP, remove from SGL, repay on BB, remove collateral from BB and withdraw
    /// @dev all steps are optional:
    ///         - if `removeAndRepayData.exitData.exit` is false, the exit operation is skipped
    ///         - if `removeAndRepayData.unlockData.unlock` is false, the unlock operation is skipped
    ///         - if `removeAndRepayData.removeAssetFromSGL` is false, the removeAsset operation is skipped
    ///         - if `!removeAndRepayData.assetWithdrawData.withdraw && removeAndRepayData.repayAssetOnBB`, the repay operation is performed
    ///         - if `removeAndRepayData.removeCollateralFromBB` is false, the rmeove collateral is skipped
    ///     - the helper can either stop at the remove asset from SGL step or it can continue until is removes & withdraws collateral from BB
    ///         - removed asset can be withdrawn by providing `removeAndRepayData.assetWithdrawData`
    ///     - BB collateral can be removed by providing `removeAndRepayData.collateralWithdrawData`
    function exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable {
        _executeModule(
            Module.Market,
            abi.encodeWithSelector(
                MagnetarMarketModule.exitPositionAndRemoveCollateral.selector,
                user,
                externalData,
                removeAndRepayData
            )
        );
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //
    /// @notice rescues unused ETH from the contract
    /// @param amount the amount to rescue
    /// @param to the recipient
    function rescueEth(uint256 amount, address to) external onlyOwner {
        (bool success, ) = to.call{value: amount}("");
        require(success, "Magnetar: transfer failed.");
    }

    // ********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _commonInfo(
        address who,
        IMarket market
    ) private view returns (MarketInfo memory) {
        Rebase memory _totalBorrowed;
        MarketInfo memory info;

        info.collateral = market.collateral();
        info.asset = market.asset();
        info.oracle = IOracle(market.oracle());
        info.oracleData = market.oracleData();
        info.totalCollateralShare = market.totalCollateralShare();
        info.userCollateralShare = market.userCollateralShare(who);

        (uint128 totalBorrowElastic, uint128 totalBorrowBase) = market
            .totalBorrow();
        _totalBorrowed = Rebase(totalBorrowElastic, totalBorrowBase);
        info.totalBorrow = _totalBorrowed;
        info.userBorrowPart = market.userBorrowPart(who);

        info.currentExchangeRate = market.exchangeRate();
        (, info.oracleExchangeRate) = IOracle(market.oracle()).peek(
            market.oracleData()
        );
        info.spotExchangeRate = IOracle(market.oracle()).peekSpot(
            market.oracleData()
        );
        info.totalBorrowCap = market.totalBorrowCap();
        info.assetId = market.assetId();
        info.collateralId = market.collateralId();

        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        (
            info.totalYieldBoxCollateralShare,
            info.totalYieldBoxCollateralAmount
        ) = yieldBox.assetTotals(info.collateralId);
        (info.totalYieldBoxAssetShare, info.totalYieldBoxAssetAmount) = yieldBox
            .assetTotals(info.assetId);

        (
            info.yieldBoxCollateralTokenType,
            info.yieldBoxCollateralContractAddress,
            info.yieldBoxCollateralStrategyAddress,
            info.yieldBoxCollateralTokenId
        ) = yieldBox.assets(info.collateralId);
        (
            info.yieldBoxAssetTokenType,
            info.yieldBoxAssetContractAddress,
            info.yieldBoxAssetStrategyAddress,
            info.yieldBoxAssetTokenId
        ) = yieldBox.assets(info.assetId);

        return info;
    }

    function _singularityMarketInfo(
        address who,
        ISingularity[] memory markets
    ) private view returns (SingularityInfo[] memory) {
        uint256 len = markets.length;
        SingularityInfo[] memory result = new SingularityInfo[](len);

        Rebase memory _totalAsset;
        for (uint256 i = 0; i < len; i++) {
            ISingularity sgl = markets[i];

            result[i].market = _commonInfo(who, IMarket(address(sgl)));

            (uint128 totalAssetElastic, uint128 totalAssetBase) = sgl //
                .totalAsset(); //
            _totalAsset = Rebase(totalAssetElastic, totalAssetBase); //
            result[i].totalAsset = _totalAsset; //
            result[i].userAssetFraction = sgl.balanceOf(who); //

            (
                ISingularity.AccrueInfo memory _accrueInfo,
                uint256 _utilization
            ) = sgl.getInterestDetails();

            result[i].accrueInfo = _accrueInfo;
            result[i].utilization = _utilization;
        }

        return result;
    }

    function _bigBangMarketInfo(
        address who,
        IBigBang[] memory markets
    ) private view returns (BigBangInfo[] memory) {
        uint256 len = markets.length;
        BigBangInfo[] memory result = new BigBangInfo[](len);

        IBigBang.AccrueInfo memory _accrueInfo;
        for (uint256 i = 0; i < len; i++) {
            IBigBang bigBang = markets[i];
            result[i].market = _commonInfo(who, IMarket(address(bigBang)));

            (uint64 debtRate, uint64 lastAccrued) = bigBang.accrueInfo();
            _accrueInfo = IBigBang.AccrueInfo(debtRate, lastAccrued);
            result[i].accrueInfo = _accrueInfo;
            result[i].minDebtRate = bigBang.minDebtRate();
            result[i].maxDebtRate = bigBang.maxDebtRate();
            result[i].debtRateAgainstEthMarket = bigBang
                .debtRateAgainstEthMarket();
            result[i].currentDebtRate = bigBang.getDebtRate();

            IPenrose penrose = IPenrose(bigBang.penrose());
            result[i].mainBBMarket = penrose.bigBangEthMarket();
            result[i].mainBBDebtRate = penrose.bigBangEthDebtRate();
        }

        return result;
    }

    function _permit(
        address target,
        bytes calldata actionCalldata,
        bool permitAll,
        bool allowFailure
    ) private {
        if (permitAll) {
            PermitAllData memory permitData = abi.decode(
                actionCalldata[4:],
                (PermitAllData)
            );
            _checkSender(permitData.owner);
        } else {
            PermitData memory permitData = abi.decode(
                actionCalldata[4:],
                (PermitData)
            );
            _checkSender(permitData.owner);
        }

        require(target.code.length > 0, "Magnetar: no contract");
        (bool success, bytes memory returnData) = target.call(actionCalldata);
        if (!success && !allowFailure) {
            _getRevertMsg(returnData);
        }
    }

    function _extractModule(Module _module) private view returns (address) {
        address module;
        if (_module == Module.Market) {
            module = address(marketModule);
        }

        if (module == address(0)) {
            revert("MagnetarV2: module not found");
        }

        return module;
    }

    function _executeModule(
        Module _module,
        bytes memory _data
    ) private returns (bytes memory returnData) {
        bool success = true;
        address module = _extractModule(_module);

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            _getRevertMsg(returnData);
        }
    }

    function _getRevertMsg(bytes memory _returnData) private pure {
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert("MagnetarV2: Reason unknown");

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//Boring
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";

//TAPIOCA
import "../interfaces/IOracle.sol";
import "../interfaces/ISingularity.sol";
import "../interfaces/IBigBang.sol";
import "../interfaces/ITapiocaOFT.sol";
import "../interfaces/ISwapper.sol";
import "../interfaces/ITapiocaOptionsBroker.sol";
import "../interfaces/ITapiocaOptionLiquidityProvision.sol";
import "../interfaces/IPenrose.sol";
import "../interfaces/ITapiocaOptionsBroker.sol";

import {IUSDOBase} from "../interfaces/IUSDO.sol";

//YIELDBOX
import "tapioca-sdk/dist/contracts/YieldBox/contracts/enums/YieldBoxTokenType.sol";

contract MagnetarV2Storage {
    // ************ //
    // *** VARS *** //
    // ************ //
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    struct MarketInfo {
        address collateral;
        uint256 collateralId;
        address asset;
        uint256 assetId;
        IOracle oracle;
        bytes oracleData;
        uint256 totalCollateralShare;
        uint256 userCollateralShare;
        Rebase totalBorrow;
        uint256 userBorrowPart;
        uint256 currentExchangeRate;
        uint256 spotExchangeRate;
        uint256 oracleExchangeRate;
        uint256 totalBorrowCap;
        uint256 totalYieldBoxCollateralShare;
        uint256 totalYieldBoxCollateralAmount;
        uint256 totalYieldBoxAssetShare;
        uint256 totalYieldBoxAssetAmount;
        TokenType yieldBoxCollateralTokenType;
        address yieldBoxCollateralContractAddress;
        address yieldBoxCollateralStrategyAddress;
        uint256 yieldBoxCollateralTokenId;
        TokenType yieldBoxAssetTokenType;
        address yieldBoxAssetContractAddress;
        address yieldBoxAssetStrategyAddress;
        uint256 yieldBoxAssetTokenId;
    }
    struct SingularityInfo {
        MarketInfo market;
        Rebase totalAsset;
        uint256 userAssetFraction;
        ISingularity.AccrueInfo accrueInfo;
        uint256 utilization;
    }
    struct BigBangInfo {
        MarketInfo market;
        IBigBang.AccrueInfo accrueInfo;
        uint256 minDebtRate;
        uint256 maxDebtRate;
        uint256 debtRateAgainstEthMarket;
        address mainBBMarket;
        uint256 mainBBDebtRate;
        uint256 currentDebtRate;
    }

    // --- ACTIONS DATA ----
    struct Call {
        uint16 id;
        address target;
        uint256 value;
        bool allowFailure;
        bytes call;
    }

    struct Result {
        bool success;
        bytes returnData;
    }

    struct PermitData {
        address owner;
        address spender;
        uint256 value;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct PermitAllData {
        address owner;
        address spender;
        uint256 deadline;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct WrapData {
        address from;
        address to;
        uint256 amount;
    }

    struct WrapNativeData {
        address to;
    }

    struct TOFTSendAndBorrowData {
        address from;
        address to;
        uint16 lzDstChainId;
        bytes airdropAdapterParams;
        ITapiocaOFT.IBorrowParams borrowParams;
        ICommonData.IWithdrawParams withdrawParams;
        ICommonData.ISendOptions options;
        ICommonData.IApproval[] approvals;
    }

    struct TOFTSendAndLendData {
        address from;
        address to;
        uint16 lzDstChainId;
        IUSDOBase.ILendOrRepayParams lendParams;
        ICommonData.ISendOptions options;
        ICommonData.IApproval[] approvals;
    }

    struct TOFTSendToStrategyData {
        address from;
        address to;
        uint256 amount;
        uint256 share;
        uint256 assetId;
        uint16 lzDstChainId;
        ICommonData.ISendOptions options;
    }

    struct TOFTRetrieveFromStrategyData {
        address from;
        uint256 amount;
        uint256 share;
        uint256 assetId;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes airdropAdapterParam;
    }

    struct YieldBoxDepositData {
        uint256 assetId;
        address from;
        address to;
        uint256 amount;
        uint256 share;
    }

    struct SGLAddCollateralData {
        address from;
        address to;
        bool skim;
        uint256 amount;
        uint256 share;
    }

    struct SGLBorrowData {
        address from;
        address to;
        uint256 amount;
    }

    struct SGLLendData {
        address from;
        address to;
        bool skim;
        uint256 share;
    }

    struct SGLRepayData {
        address from;
        address to;
        bool skim;
        uint256 part;
    }

    struct HelperRemoveAssetData {
        address market;
        address user;
        uint256 fraction;
    }

    struct HelperLendData {
        address user;
        uint256 lendAmount;
        IUSDOBase.IMintData mintData;
        ICommonData.IDepositData depositData;
        ITapiocaOptionLiquidityProvision.IOptionsLockData lockData;
        ITapiocaOptionsBroker.IOptionsParticipateData participateData;
        ICommonData.ICommonExternalContracts externalContracts;
    }

    struct HelperBorrowData {
        address market;
        address user;
        uint256 collateralAmount;
        uint256 borrowAmount;
        bool extractFromSender;
        bool deposit;
        bool withdraw;
        bytes withdrawData;
    }

    struct HelperDepositRepayRemoveCollateral {
        address market;
        address user;
        uint256 depositAmount;
        uint256 repayAmount;
        uint256 collateralAmount;
        bool extractFromSender;
        ICommonData.IWithdrawParams withdrawCollateralParams;
    }

    struct HelperBuyCollateral {
        address market;
        address from;
        uint256 borrowAmount;
        uint256 supplyAmount;
        uint256 minAmountOut;
        ISwapper swapper;
        bytes dexData;
    }

    struct HelperSellCollateral {
        address market;
        address from;
        uint256 share;
        uint256 minAmountOut;
        ISwapper swapper;
        bytes dexData;
    }

    struct HelperExerciseOption {
        ITapiocaOptionsBrokerCrossChain.IExerciseOptionsData optionsData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZData lzData;
        ITapiocaOptionsBrokerCrossChain.IExerciseLZSendTapData tapSendData;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMultiHopBuy {
        address from;
        uint256 collateralAmount;
        uint256 borrowAmount;
        IUSDOBase.ILeverageSwapData swapData;
        IUSDOBase.ILeverageLZData lzData;
        IUSDOBase.ILeverageExternalContractsData externalData;
        bytes airdropAdapterParams;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMultiHopSell {
        address from;
        uint256 share;
        IUSDOBase.ILeverageSwapData swapData;
        IUSDOBase.ILeverageLZData lzData;
        IUSDOBase.ILeverageExternalContractsData externalData;
        bytes airdropAdapterParams;
        ICommonData.IApproval[] approvals;
    }

    struct HelperMarketRemoveAndRepayAsset {
        address user;
        ICommonData.ICommonExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
    }

    struct HelperTOFTRemoveAndRepayAsset {
        address from;
        address to;
        uint16 lzDstChainId;
        address zroPaymentAddress;
        bytes adapterParams;
        ICommonData.ICommonExternalContracts externalData;
        IUSDOBase.IRemoveAndRepay removeAndRepayData;
        ICommonData.IApproval[] approvals;
    }

    // --- ACTIONS IDS ----
    uint16 internal constant PERMIT_ALL = 1;
    uint16 internal constant PERMIT = 2;

    uint16 internal constant YB_DEPOSIT_ASSET = 100;
    uint16 internal constant YB_WITHDRAW_TO = 102;

    uint16 internal constant MARKET_ADD_COLLATERAL = 200;
    uint16 internal constant MARKET_BORROW = 201;
    uint16 internal constant MARKET_LEND = 203;
    uint16 internal constant MARKET_REPAY = 204;
    uint16 internal constant MARKET_YBDEPOSIT_AND_LEND = 205;
    uint16 internal constant MARKET_YBDEPOSIT_COLLATERAL_AND_BORROW = 206;
    uint16 internal constant MARKET_REMOVE_ASSET = 207;
    uint16 internal constant MARKET_DEPOSIT_REPAY_REMOVE_COLLATERAL = 208;
    uint16 internal constant MARKET_BUY_COLLATERAL = 209;
    uint16 internal constant MARKET_SELL_COLLATERAL = 210;
    uint16 internal constant MARKET_MULTIHOP_BUY = 211;
    uint16 internal constant MARKET_MULTIHOP_SELL = 212;

    uint16 internal constant TOFT_WRAP = 300;
    uint16 internal constant TOFT_SEND_FROM = 301;
    uint16 internal constant TOFT_SEND_APPROVAL = 302;
    uint16 internal constant TOFT_SEND_AND_BORROW = 303;
    uint16 internal constant TOFT_SEND_AND_LEND = 304;
    uint16 internal constant TOFT_DEPOSIT_TO_STRATEGY = 305;
    uint16 internal constant TOFT_RETRIEVE_FROM_STRATEGY = 306;
    uint16 internal constant TOFT_REMOVE_AND_REPAY = 307;

    uint16 internal constant TAP_EXERCISE_OPTION = 400;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // ************************ //
    // *** INTERNAL METHODS *** //
    // ************************ //
    function _checkSender(address _from) internal view {
        require(_from == msg.sender, "MagnetarV2: operator not approved");
    }

    receive() external payable virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

//LZ
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

//OZ
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//TAPIOCA
import "../../interfaces/IYieldBoxBase.sol";
import "../../interfaces/ITapiocaOptions.sol";

import "../MagnetarV2Storage.sol";

contract MagnetarMarketModule is MagnetarV2Storage {
    using SafeERC20 for IERC20;
    using RebaseLibrary for Rebase;

    function withdrawToChain(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) external payable {
        _withdrawToChain(
            yieldBox,
            from,
            assetId,
            dstChainId,
            receiver,
            amount,
            share,
            adapterParams,
            refundAddress,
            gas
        );
    }

    function depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams
    ) external payable {
        _depositAddCollateralAndBorrowFromMarket(
            market,
            user,
            collateralAmount,
            borrowAmount,
            extractFromSender,
            deposit,
            withdrawParams
        );
    }

    function depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams
    ) external payable {
        _depositRepayAndRemoveCollateralFromMarket(
            market,
            user,
            depositAmount,
            repayAmount,
            collateralAmount,
            extractFromSender,
            withdrawCollateralParams
        );
    }

    function mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData calldata mintData,
        ICommonData.IDepositData calldata depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts
    ) external payable {
        _mintFromBBAndLendOnSGL(
            user,
            lendAmount,
            mintData,
            depositData,
            lockData,
            participateData,
            externalContracts
        );
    }

    function exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) external payable {
        _exitPositionAndRemoveCollateral(
            user,
            externalData,
            removeAndRepayData
        );
    }

    // *********************** //
    // *** PRIVATE METHODS *** //
    // *********************** //
    function _depositAddCollateralAndBorrowFromMarket(
        IMarket market,
        address user,
        uint256 collateralAmount,
        uint256 borrowAmount,
        bool extractFromSender,
        bool deposit,
        ICommonData.IWithdrawParams calldata withdrawParams
    ) private {
        IYieldBoxBase yieldBox = IYieldBoxBase(market.yieldBox());

        uint256 collateralId = market.collateralId();
        (, address collateralAddress, , ) = yieldBox.assets(collateralId);

        uint256 _share = yieldBox.toShare(
            collateralId,
            collateralAmount,
            false
        );
        //deposit to YieldBox
        if (deposit) {
            if (!extractFromSender) {
                _checkSender(user);
            }

            // transfers tokens from sender or from the user to this contract
            collateralAmount = _extractTokens(
                extractFromSender ? msg.sender : user,
                collateralAddress,
                collateralAmount
            );
            _share = yieldBox.toShare(collateralId, collateralAmount, false);

            // deposit to YieldBox
            IERC20(collateralAddress).approve(address(yieldBox), 0);
            IERC20(collateralAddress).approve(
                address(yieldBox),
                collateralAmount
            );
            yieldBox.depositAsset(
                collateralId,
                address(this),
                address(this),
                0,
                _share
            );
        }

        // performs .addCollateral on market
        if (collateralAmount > 0) {
            _setApprovalForYieldBox(address(market), yieldBox);
            market.addCollateral(
                deposit ? address(this) : user,
                user,
                false,
                collateralAmount,
                _share
            );
        }

        // performs .borrow on market
        // if `withdraw` it uses `withdrawTo` to withdraw assets on the same chain or to another one
        if (borrowAmount > 0) {
            address borrowReceiver = withdrawParams.withdraw
                ? address(this)
                : user;
            market.borrow(user, borrowReceiver, borrowAmount);

            if (withdrawParams.withdraw) {
                bytes memory withdrawAssetBytes = abi.encode(
                    withdrawParams.withdrawOnOtherChain,
                    withdrawParams.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    withdrawParams.withdrawAdapterParams
                );
                _withdraw(
                    borrowReceiver,
                    withdrawAssetBytes,
                    market,
                    yieldBox,
                    borrowAmount,
                    0,
                    false
                );
            }
        }

        _revertYieldBoxApproval(address(market), yieldBox);
    }

    function _depositRepayAndRemoveCollateralFromMarket(
        address market,
        address user,
        uint256 depositAmount,
        uint256 repayAmount,
        uint256 collateralAmount,
        bool extractFromSender,
        ICommonData.IWithdrawParams calldata withdrawCollateralParams
    ) private {
        IMarket marketInterface = IMarket(market);
        IYieldBoxBase yieldBox = IYieldBoxBase(marketInterface.yieldBox());

        uint256 assetId = marketInterface.assetId();
        (, address assetAddress, , ) = yieldBox.assets(assetId);

        // deposit to YieldBox
        if (depositAmount > 0) {
            depositAmount = _extractTokens(
                extractFromSender ? msg.sender : user,
                assetAddress,
                depositAmount
            );
            IERC20(assetAddress).approve(address(yieldBox), 0);
            IERC20(assetAddress).approve(address(yieldBox), depositAmount);
            yieldBox.depositAsset(
                assetId,
                address(this),
                address(this),
                depositAmount,
                0
            );
        }

        // performs a repay operation for the specified market
        if (repayAmount > 0) {
            _setApprovalForYieldBox(market, yieldBox);
            marketInterface.repay(
                depositAmount > 0 ? address(this) : user,
                user,
                false,
                repayAmount
            );
            _revertYieldBoxApproval(market, yieldBox);
        }

        // performs a removeCollateral operation on the market
        // if `withdrawCollateralParams.withdraw` it uses `withdrawTo` to withdraw collateral on the same chain or to another one
        if (collateralAmount > 0) {
            address collateralWithdrawReceiver = withdrawCollateralParams
                .withdraw
                ? address(this)
                : user;
            uint256 collateralShare = yieldBox.toShare(
                marketInterface.collateralId(),
                collateralAmount,
                false
            );
            marketInterface.removeCollateral(
                user,
                collateralWithdrawReceiver,
                collateralShare
            );

            //withdraw
            if (withdrawCollateralParams.withdraw) {
                _withdrawToChain(
                    yieldBox,
                    collateralWithdrawReceiver,
                    marketInterface.collateralId(),
                    withdrawCollateralParams.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    collateralAmount,
                    collateralShare,
                    withdrawCollateralParams.withdrawAdapterParams,
                    payable(this),
                    address(this).balance
                );
            }
        }
    }

    function _mintFromBBAndLendOnSGL(
        address user,
        uint256 lendAmount,
        IUSDOBase.IMintData memory mintData,
        ICommonData.IDepositData memory depositData,
        ITapiocaOptionLiquidityProvision.IOptionsLockData calldata lockData,
        ITapiocaOptionsBroker.IOptionsParticipateData calldata participateData,
        ICommonData.ICommonExternalContracts calldata externalContracts
    ) private {
        IMarket bigBang = IMarket(externalContracts.bigBang);
        ISingularity singularity = ISingularity(externalContracts.singularity);
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        if (address(singularity) != address(0)) {
            _setApprovalForYieldBox(address(singularity), yieldBox);
        }
        if (address(bigBang) != address(0)) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
        }

        // if `mint` was requested the following actions are performed:
        //  - extracts & deposits collateral to YB
        //  - performs bigBang.addCollateral
        //  - performs bigBang.borrow
        if (mintData.mint) {
            uint256 bbCollateralId = bigBang.collateralId();
            (, address bbCollateralAddress, , ) = yieldBox.assets(
                bbCollateralId
            );
            uint256 bbCollateralShare = yieldBox.toShare(
                bbCollateralId,
                mintData.collateralDepositData.amount,
                false
            );
            // deposit collateral to YB
            if (mintData.collateralDepositData.deposit) {
                if (!mintData.collateralDepositData.extractFromSender) {
                    _checkSender(user);
                }
                mintData.collateralDepositData.amount = _extractTokens(
                    mintData.collateralDepositData.extractFromSender
                        ? msg.sender
                        : user,
                    bbCollateralAddress,
                    mintData.collateralDepositData.amount
                );
                bbCollateralShare = yieldBox.toShare(
                    bbCollateralId,
                    mintData.collateralDepositData.amount,
                    false
                );

                IERC20(bbCollateralAddress).approve(address(yieldBox), 0);
                IERC20(bbCollateralAddress).approve(
                    address(yieldBox),
                    mintData.collateralDepositData.amount
                );
                yieldBox.depositAsset(
                    bbCollateralId,
                    address(this),
                    address(this),
                    0,
                    bbCollateralShare
                );
            }

            // add collateral to BB
            if (mintData.collateralDepositData.amount > 0) {
                //add collateral to BingBang
                _setApprovalForYieldBox(address(bigBang), yieldBox);
                bigBang.addCollateral(
                    mintData.collateralDepositData.deposit
                        ? address(this)
                        : user,
                    user,
                    false,
                    mintData.collateralDepositData.amount,
                    bbCollateralShare
                );
            }

            // mints from BB
            bigBang.borrow(user, user, mintData.mintAmount);
        }

        // if `depositData.deposit`:
        //      - deposit SGL asset to YB for `user`
        uint256 sglAssetId = singularity.assetId();
        (, address sglAssetAddress, , ) = yieldBox.assets(sglAssetId);
        if (depositData.deposit) {
            if (!depositData.extractFromSender) {
                _checkSender(user);
            }

            depositData.amount = _extractTokens(
                depositData.extractFromSender ? msg.sender : user,
                sglAssetAddress,
                depositData.amount
            );

            IERC20(sglAssetAddress).approve(address(yieldBox), 0);
            IERC20(sglAssetAddress).approve(
                address(yieldBox),
                depositData.amount
            );
            yieldBox.depositAsset(
                sglAssetId,
                address(this),
                user,
                0,
                yieldBox.toShare(sglAssetId, depositData.amount, false)
            );
        }

        // if `lendAmount` > 0:
        //      - add asset to SGL
        uint256 fraction = 0;
        if (lendAmount == 0 && depositData.deposit) {
            lendAmount = depositData.amount;
        }
        if (lendAmount > 0) {
            uint256 lendShare = yieldBox.toShare(sglAssetId, lendAmount, false);
            fraction = singularity.addAsset(user, user, false, lendShare);
        }

        // if `lockData.lock`:
        //      - transfer `fraction` from user to `address(this)
        //      - deposits `fraction` to YB for `address(this)`
        //      - performs tOLP.lock
        uint256 tOLPTokenId = 0;
        if (lockData.lock) {
            if (lockData.fraction > 0) {
                fraction = lockData.fraction;
            }
            // retrieve and deposit SGLAssetId registered in tOLP
            (uint256 tOLPSglAssetId, , ) = ITapiocaOptionLiquidityProvision(
                lockData.target
            ).activeSingularities(address(singularity));
            require(fraction > 0, "Magnetar: fraction 0");
            IERC20(address(singularity)).safeTransferFrom(
                user,
                address(this),
                fraction
            );
            IERC20(address(singularity)).approve(address(yieldBox), 0);
            IERC20(address(singularity)).approve(address(yieldBox), fraction);
            yieldBox.depositAsset(
                tOLPSglAssetId,
                address(this),
                address(this),
                fraction,
                0
            );

            _setApprovalForYieldBox(lockData.target, yieldBox);
            address lockTo = participateData.participate ? address(this) : user;
            tOLPTokenId = ITapiocaOptionLiquidityProvision(lockData.target)
                .lock(
                    lockTo,
                    address(singularity),
                    lockData.lockDuration,
                    lockData.amount
                );
            _revertYieldBoxApproval(lockData.target, yieldBox);
        }

        // if `participateData.participate`:
        //      - verify tOLPTokenId
        //      - performs tOB.participate
        //      - transfer `oTAPTokenId` to user
        if (participateData.participate) {
            if (participateData.tOLPTokenId != 0) {
                if (tOLPTokenId != 0) {
                    require(
                        participateData.tOLPTokenId == tOLPTokenId,
                        "Magnetar: tOLPTokenId mismatch"
                    );
                }

                tOLPTokenId = participateData.tOLPTokenId;
            }
            require(
                lockData.target != address(0),
                "Magnetar: lock target mismatch"
            );
            require(tOLPTokenId != 0, "Magnetar: tOLPTokenId 0");
            IERC721(lockData.target).approve(
                participateData.target,
                tOLPTokenId
            );
            uint256 oTAPTokenId = ITapiocaOptionsBroker(participateData.target)
                .participate(tOLPTokenId);

            address oTapAddress = ITapiocaOptionsBroker(participateData.target)
                .oTAP();
            IERC721(oTapAddress).approve(address(this), oTAPTokenId);
            IERC721(oTapAddress).safeTransferFrom(
                address(this),
                user,
                oTAPTokenId,
                "0x"
            );
        }

        if (address(singularity) != address(0)) {
            _revertYieldBoxApproval(address(singularity), yieldBox);
        }
        if (address(bigBang) != address(0)) {
            _revertYieldBoxApproval(address(bigBang), yieldBox);
        }
    }

    function _exitPositionAndRemoveCollateral(
        address user,
        ICommonData.ICommonExternalContracts calldata externalData,
        IUSDOBase.IRemoveAndRepay calldata removeAndRepayData
    ) private {
        IMarket bigBang = IMarket(externalData.bigBang);
        ISingularity singularity = ISingularity(externalData.singularity);
        IYieldBoxBase yieldBox = IYieldBoxBase(singularity.yieldBox());

        // if `removeAndRepayData.exitData.exit` the following operations are performed
        //      - if ownerOfTapTokenId is user, transfers the oTAP token id to this contract
        //      - tOB.exitPosition
        //      - if `!removeAndRepayData.unlockData.unlock`, transfer the obtained tokenId to the user
        uint256 tOLPId = 0;
        if (removeAndRepayData.exitData.exit) {
            require(
                removeAndRepayData.exitData.oTAPTokenID > 0,
                "Magnetar: oTAPTokenID 0"
            );

            address oTapAddress = ITapiocaOptionsBroker(
                removeAndRepayData.exitData.target
            ).oTAP();
            (, ITapiocaOptions.TapOption memory oTAPPosition) = ITapiocaOptions(
                oTapAddress
            ).attributes(removeAndRepayData.exitData.oTAPTokenID);

            tOLPId = oTAPPosition.tOLP;

            address ownerOfTapTokenId = IERC721(oTapAddress).ownerOf(
                removeAndRepayData.exitData.oTAPTokenID
            );
            require(
                ownerOfTapTokenId == user || ownerOfTapTokenId == address(this),
                "Magnetar: oTAPTokenID owner mismatch"
            );
            if (ownerOfTapTokenId == user) {
                IERC721(oTapAddress).safeTransferFrom(
                    user,
                    address(this),
                    removeAndRepayData.exitData.oTAPTokenID,
                    "0x"
                );
            }
            ITapiocaOptionsBroker(removeAndRepayData.exitData.target)
                .exitPosition(removeAndRepayData.exitData.oTAPTokenID);

            if (!removeAndRepayData.unlockData.unlock) {
                IERC721(oTapAddress).safeTransferFrom(
                    address(this),
                    user,
                    removeAndRepayData.exitData.oTAPTokenID,
                    "0x"
                );
            }
        }

        // performs a tOLP.unlock operation
        if (removeAndRepayData.unlockData.unlock) {
            if (removeAndRepayData.unlockData.tokenId != 0) {
                if (tOLPId != 0) {
                    require(
                        tOLPId == removeAndRepayData.unlockData.tokenId,
                        "Magnetar: tOLPId mismatch"
                    );
                }
                tOLPId = removeAndRepayData.unlockData.tokenId;
            }
            ITapiocaOptionLiquidityProvision(
                removeAndRepayData.unlockData.target
            ).unlock(tOLPId, externalData.singularity, user);
        }

        // if `removeAndRepayData.removeAssetFromSGL` performs the follow operations:
        //      - removeAsset from SGL
        //      - if `removeAndRepayData.assetWithdrawData.withdraw` withdraws by using the `withdrawTo` operation
        uint256 _removeAmount = removeAndRepayData.removeAmount;
        if (removeAndRepayData.removeAssetFromSGL) {
            uint256 share = yieldBox.toShare(
                singularity.assetId(),
                _removeAmount,
                false
            );

            address removeAssetTo = removeAndRepayData
                .assetWithdrawData
                .withdraw || removeAndRepayData.repayAssetOnBB
                ? address(this)
                : user;
            uint256 removedShare = singularity.removeAsset(
                user,
                removeAssetTo,
                share
            );

            //withdraw
            if (removeAndRepayData.assetWithdrawData.withdraw) {
                bytes memory withdrawAssetBytes = abi.encode(
                    removeAndRepayData.assetWithdrawData.withdrawOnOtherChain,
                    removeAndRepayData.assetWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    removeAndRepayData.assetWithdrawData.withdrawAdapterParams
                );
                _withdraw(
                    address(this),
                    withdrawAssetBytes,
                    singularity,
                    yieldBox,
                    0,
                    removedShare,
                    true
                );
            }
        }

        // performs a BigBang repay operation
        if (
            !removeAndRepayData.assetWithdrawData.withdraw &&
            removeAndRepayData.repayAssetOnBB
        ) {
            _setApprovalForYieldBox(address(bigBang), yieldBox);
            uint256 repayed = bigBang.repay(
                address(this),
                user,
                false,
                removeAndRepayData.repayAmount
            );
            // transfer excess amount to the user
            if (repayed < _removeAmount) {
                yieldBox.transfer(
                    address(this),
                    user,
                    bigBang.assetId(),
                    yieldBox.toShare(
                        bigBang.assetId(),
                        _removeAmount - repayed,
                        false
                    )
                );
            }
        }

        // performs a BigBang removeCollateral operation
        // if `removeAndRepayData.collateralWithdrawData.withdraw` withdraws by using the `withdrawTo` method
        if (removeAndRepayData.removeCollateralFromBB) {
            uint256 collateralShare = yieldBox.toShare(
                bigBang.collateralId(),
                removeAndRepayData.collateralAmount,
                false
            );
            address removeCollateralTo = removeAndRepayData
                .collateralWithdrawData
                .withdraw
                ? address(this)
                : user;
            bigBang.removeCollateral(user, removeCollateralTo, collateralShare);

            //withdraw
            if (removeAndRepayData.collateralWithdrawData.withdraw) {
                bytes memory withdrawCollateralBytes = abi.encode(
                    removeAndRepayData
                        .collateralWithdrawData
                        .withdrawOnOtherChain,
                    removeAndRepayData.collateralWithdrawData.withdrawLzChainId,
                    LzLib.addressToBytes32(user),
                    removeAndRepayData
                        .collateralWithdrawData
                        .withdrawAdapterParams
                );
                _withdraw(
                    address(this),
                    withdrawCollateralBytes,
                    singularity,
                    yieldBox,
                    0,
                    collateralShare,
                    true
                );
            }
        }
        _revertYieldBoxApproval(address(bigBang), yieldBox);
    }

    function _withdrawToChain(
        IYieldBoxBase yieldBox,
        address from,
        uint256 assetId,
        uint16 dstChainId,
        bytes32 receiver,
        uint256 amount,
        uint256 share,
        bytes memory adapterParams,
        address payable refundAddress,
        uint256 gas
    ) private {
        // perform a same chain withdrawal
        if (dstChainId == 0) {
            yieldBox.withdraw(
                assetId,
                from,
                LzLib.bytes32ToAddress(receiver),
                amount,
                share
            );
            return;
        }
        // perform a cross chain withdrawal
        (, address asset, , ) = yieldBox.assets(assetId);
        // make sure the asset supports a cross chain operation
        try
            IERC165(address(asset)).supportsInterface(
                type(ISendFrom).interfaceId
            )
        {} catch {
            return;
        }

        // withdraw from YieldBox
        yieldBox.withdraw(assetId, from, address(this), amount, 0);

        // build LZ params
        bytes memory _adapterParams;
        ISendFrom.LzCallParams memory callParams = ISendFrom.LzCallParams({
            refundAddress: msg.value > 0 ? refundAddress : payable(this),
            zroPaymentAddress: address(0),
            adapterParams: ISendFrom(address(asset)).useCustomAdapterParams()
                ? adapterParams
                : _adapterParams
        });

        // sends the asset to another layer
        ISendFrom(address(asset)).sendFrom{value: gas}(
            address(this),
            dstChainId,
            receiver,
            amount,
            callParams
        );
    }

    function _withdraw(
        address from,
        bytes memory withdrawData,
        IMarket market,
        IYieldBoxBase yieldBox,
        uint256 amount,
        uint256 share,
        bool withdrawCollateral
    ) private {
        require(withdrawData.length > 0, "MagnetarV2: withdrawData is empty");
        (
            bool withdrawOnOtherChain,
            uint16 destChain,
            bytes32 receiver,
            bytes memory adapterParams
        ) = abi.decode(withdrawData, (bool, uint16, bytes32, bytes));

        uint256 gas = msg.value > 0 ? msg.value : address(this).balance;
        _withdrawToChain(
            yieldBox,
            from,
            withdrawCollateral ? market.collateralId() : market.assetId(),
            withdrawOnOtherChain ? destChain : 0,
            receiver,
            amount,
            share,
            adapterParams,
            gas > 0 ? payable(msg.sender) : payable(this),
            gas
        );
    }

    function _setApprovalForYieldBox(
        address target,
        IYieldBoxBase yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(target)
        );
        if (!isApproved) {
            yieldBox.setApprovalForAll(address(target), true);
        }
    }

    function _revertYieldBoxApproval(
        address target,
        IYieldBoxBase yieldBox
    ) private {
        bool isApproved = yieldBox.isApprovedForAll(
            address(this),
            address(target)
        );
        if (isApproved) {
            yieldBox.setApprovalForAll(address(target), false);
        }
    }

    function _extractTokens(
        address _from,
        address _token,
        uint256 _amount
    ) private returns (uint256) {
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        uint256 balanceAfter = IERC20(_token).balanceOf(address(this));
        require(balanceAfter > balanceBefore, "Magnetar: transfer failed");
        return balanceAfter - balanceBefore;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

library LzLib {
    // LayerZero communication
    struct CallParams {
        address payable refundAddress;
        address zroPaymentAddress;
    }

    //---------------------------------------------------------------------------
    // Address type handling

    struct AirdropParams {
        uint airdropAmount;
        bytes32 airdropAddress;
    }

    function buildAdapterParams(LzLib.AirdropParams memory _airdropParams, uint _uaGasLimit) internal pure returns (bytes memory adapterParams) {
        if (_airdropParams.airdropAmount == 0 && _airdropParams.airdropAddress == bytes32(0x0)) {
            adapterParams = buildDefaultAdapterParams(_uaGasLimit);
        } else {
            adapterParams = buildAirdropAdapterParams(_uaGasLimit, _airdropParams);
        }
    }

    // Build Adapter Params
    function buildDefaultAdapterParams(uint _uaGas) internal pure returns (bytes memory) {
        // txType 1
        // bytes  [2       32      ]
        // fields [txType  extraGas]
        return abi.encodePacked(uint16(1), _uaGas);
    }

    function buildAirdropAdapterParams(uint _uaGas, AirdropParams memory _params) internal pure returns (bytes memory) {
        require(_params.airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_params.airdropAddress != bytes32(0x0), "Airdrop address must be set");

        // txType 2
        // bytes  [2       32        32            bytes[]         ]
        // fields [txType  extraGas  dstNativeAmt  dstNativeAddress]
        return abi.encodePacked(uint16(2), _uaGas, _params.airdropAmount, _params.airdropAddress);
    }

    function getGasLimit(bytes memory _adapterParams) internal pure returns (uint gasLimit) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Decode Adapter Params
    function decodeAdapterParams(bytes memory _adapterParams) internal pure returns (uint16 txType, uint uaGas, uint airdropAmount, address payable airdropAddress) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            txType := mload(add(_adapterParams, 2))
            uaGas := mload(add(_adapterParams, 34))
        }
        require(txType == 1 || txType == 2, "Unsupported txType");
        require(uaGas > 0, "Gas too low");

        if (txType == 2) {
            assembly {
                airdropAmount := mload(add(_adapterParams, 66))
                airdropAddress := mload(add(_adapterParams, 86))
            }
        }
    }

    //---------------------------------------------------------------------------
    // Address type handling
    function bytes32ToAddress(bytes32 _bytes32Address) internal pure returns (address _address) {
        return address(uint160(uint(_bytes32Address)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the IOFT core standard
 */
interface ICommonOFT is IERC165 {

    struct LzCallParams {
        address payable refundAddress;
        address zroPaymentAddress;
        bytes adapterParams;
    }

    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _amount - amount of the tokens to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParam - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    function estimateSendAndCallFee(uint16 _dstChainId, bytes32 _toAddress, uint _amount, bytes calldata _payload, uint64 _dstGasForCall, bool _useZro, bytes calldata _adapterParams) external view returns (uint nativeFee, uint zroFee);

    /**
     * @dev returns the circulating amount of tokens on current chain
     */
    function circulatingSupply() external view returns (uint);

    /**
     * @dev returns the address of the ERC20 token
     */
    function token() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}