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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IManagers.sol";
import "../interfaces/IPlayToEarnVault.sol";
import {ClaimData, IWithdrawClaim} from "../interfaces/IWithdrawClaim.sol";

contract WithdrawClaim is IWithdrawClaim, ERC165Storage {
    using SafeERC20 for IERC20;

    //Structs
    struct AllocationRecord {
        bytes32 merkleRootHash;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 remainingAmount;
    }
   

    //State Variables
    IManagers private managers;
    AllocationRecord[] public withdrawDefinitions;
    IPlayToEarnVault public vaultContract;

    uint256 public periodCount;

    address public soulsTokenAddress;
    address public authorizedAddress;

    mapping(uint256 => mapping(address => uint256)) public claimRecords;
    mapping(uint256 => ClaimData[]) claimedPlayersForPeriods;

    //Custom Errors
    error AddressCannotBeManagerAddress();
    error StartTimeMustBeInTheFuture();
    error NotEnoughBalanceInContract();
    error InvalidMerkleRootHash();
    error ClaimPeridNotStarted();
    error AddressCannotBeZero();
    error ThereIsActivePeriod();
    error NotAuthorizedCaller();
    error ClaimPeriodEnded();
    error ZeroTotalAmount();
    error NoActivePeriod();
    error AlreadyClaimed();
    error OnlyManagers();
    error NoAllocation();

    //Events
    event CreateClaim(uint256 period, bytes32 merkleRootHash, uint256 totalAmount, uint256 startTime, uint256 endTime);
    event Claim(address indexed player, string playfabId, uint256 amount);
    event SetAuthorizedAddress(address manager, address newAddress, bool isApproved);
    event WithdrawTokens(address manager, uint256 amount, address receiver, bool isApproved);

    constructor(address _managersContract, address _soulsTokenAddress, address _authorizedAddress) {
        soulsTokenAddress = _soulsTokenAddress;
        authorizedAddress = _authorizedAddress;
        managers = IManagers(_managersContract);
        vaultContract = IPlayToEarnVault(msg.sender);
        _registerInterface(type(IWithdrawClaim).interfaceId);
    }

    //Modifiers
    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert OnlyManagers();
        }
        _;
    }

    //Write Functions
    //Managers function
    function setAuthorizedAddress(address _newAddress) external onlyManager {
        if (_newAddress == address(0)) {
            revert AddressCannotBeZero();
        }
        if (managers.isManager(_newAddress)) {
            revert AddressCannotBeManagerAddress();
        }

        string memory _title = "Set withdraw claim service address";

        bytes memory _encodedValues = abi.encode(_newAddress);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            authorizedAddress = _newAddress;
            managers.deleteTopic(_title);
        }
        emit SetAuthorizedAddress(msg.sender, _newAddress, _isApproved);
    }

    //Managers function
    function withdrawTokens(address _receiver) external onlyManager {
        if (_receiver == address(0)) {
            revert AddressCannotBeZero();
        }
        string memory _title = "Withdraw balance from withdraw claim contract";
        bytes memory _encodedValues = abi.encode(_receiver);
        managers.approveTopic(_title, _encodedValues);

        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        uint256 _balance = _soulsToken.balanceOf(address(this));
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            _soulsToken.safeTransfer(msg.sender, _balance);
            managers.deleteTopic(_title);
        }
        emit WithdrawTokens(msg.sender, _balance, _receiver, _isApproved);
    }

    function createWithdrawDefinition(
        uint256 _startTime,
        bytes32 _merkleRootHash,
        uint256 _totalAmount,
        address _nextAuthorizedAddress
    ) external {
        if (msg.sender != authorizedAddress) {
            revert NotAuthorizedCaller();
        }
        if (_merkleRootHash.length == 0) {
            revert InvalidMerkleRootHash();
        }
        if (_startTime <= block.timestamp) {
            revert StartTimeMustBeInTheFuture();
        }
        if (!isLastPeriodEnded()) {
            revert ThereIsActivePeriod();
        }

        if (_totalAmount == 0) {
            revert ZeroTotalAmount();
        }

        if (IERC20(soulsTokenAddress).balanceOf(address(this)) < _totalAmount) {
            revert NotEnoughBalanceInContract();
        }

        uint256 _interval = vaultContract.intervalBetweenDistributions();
        uint256 _endTime = _startTime + _interval - vaultContract.distributionOffset();

        withdrawDefinitions.push(
            AllocationRecord({
                merkleRootHash: _merkleRootHash,
                totalAmount: _totalAmount,
                startTime: _startTime,
                endTime: _endTime,
                remainingAmount: _totalAmount
            })
        );
        authorizedAddress = _nextAuthorizedAddress;
        periodCount++;
        emit CreateClaim(periodCount, _merkleRootHash, _totalAmount, _startTime, _endTime);
    }

    function claimTokens(
        string calldata _playfabId,
        string calldata _playfabTxId,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external {
        if (periodCount == 0) {
            revert NoActivePeriod();
        }
        uint256 _currentPeriod = periodCount - 1;
        AllocationRecord storage _currentPeriodRecord = withdrawDefinitions[_currentPeriod];
        if (block.timestamp < _currentPeriodRecord.startTime) {
            revert ClaimPeridNotStarted();
        }
        if (block.timestamp > _currentPeriodRecord.endTime) {
            revert ClaimPeriodEnded();
        }

        if (claimRecords[_currentPeriod][msg.sender] != 0) {
            revert AlreadyClaimed();
        }
        bytes32 _leaf = keccak256(abi.encodePacked(msg.sender, _currentPeriod, _amount, _playfabId, _playfabTxId));
        if (!MerkleProof.verifyCalldata(_merkleProof, _currentPeriodRecord.merkleRootHash, _leaf)) {
            revert NoAllocation();
        }

        claimRecords[_currentPeriod][msg.sender] = _amount;
        claimedPlayersForPeriods[_currentPeriod].push(
            ClaimData({
                playfabId: _playfabId,
                playfabTxId: _playfabTxId,
                player: msg.sender,
                amount: _amount,
                claimTime: block.timestamp
            })
        );
        _currentPeriodRecord.remainingAmount -= _amount;
        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        _soulsToken.safeTransfer(msg.sender, _amount);
        emit Claim(msg.sender, _playfabId, _amount);
    }

    //Read Functions
    function getClaimRecords(uint256 _period) public view returns (ClaimData[] memory _claimRecords) {
        _claimRecords = new ClaimData[](claimedPlayersForPeriods[_period].length);
        for (uint256 i = 0; i < _claimRecords.length; i++) {
            _claimRecords[i] = claimedPlayersForPeriods[_period][i];
        }
    }


    function isLastPeriodEnded() public view returns (bool) {
        if (periodCount == 0) return true;
        uint256 _currentPeriod = periodCount - 1;
        AllocationRecord memory _currentPeriodRecord = withdrawDefinitions[_currentPeriod];
        return block.timestamp > _currentPeriodRecord.endTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IManagers {
    function isManager(address _address) external view returns (bool);

    function approveTopic(string memory _title, bytes memory _encodedValues) external;

    function cancelTopicApproval(string memory _title) external;

    function deleteTopic(string memory _title) external;

    function isApproved(string memory _title, bytes memory _value) external view returns (bool);

    function changeManager1(address _newAddress) external;

    function changeManager2(address _newAddress) external;

    function changeManager3(address _newAddress) external;

    function changeManager4(address _newAddress) external;

    function changeManager5(address _newAddress) external;

    function isTrustedSource(address _address) external view returns (bool);

    function addAddressToTrustedSources(address _address, string memory _name) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPancakeRouter02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

	//Router02

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IVault.sol";

interface IPlayToEarnVault is IVault {
    function intervalBetweenDistributions() external returns (uint256);

    function distributionOffset() external returns (uint256);

    function claimContractAddress() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _lockDurationInDays,
        uint256 _countOfVesting,
        uint256 _releaseFrequencyInDays
    ) external;

    function withdrawTokens(address[] memory _receivers, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

struct ClaimData {
    string playfabId;
    string playfabTxId;
    address player;
    uint256 amount;
	uint256 claimTime;
}

interface IWithdrawClaim {
    function setAuthorizedAddress(address _newAddress) external;

    function withdrawTokens(address _receiver) external;

    function createWithdrawDefinition(
        uint256 _startTime,
        bytes32 _merkleRootHash,
        uint256 _totalAmount,
        address _nextAuthorizedAddress
    ) external;

    function claimTokens(
        string calldata _playfabId,
        string calldata _playfabTxId,
        uint256 _amount,
        bytes32[] calldata _merkleProof
    ) external;

    function getClaimRecords(uint256 _period) external view returns (ClaimData[] memory _claimRecords);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Vault.sol";
import "../Claimables/WithdrawClaim.sol";
import "../interfaces/IPancakeFactory.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/IPancakePair.sol";
import "../interfaces/IWithdrawClaim.sol";

contract PlayToEarnVault is Vault, Pausable {
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    //Storage Variables
    address public claimContractAddress;
    address public authorizedAddress;

    uint256 public lastDistributionTime;
    uint256 public intervalBetweenDistributions = 7 days;
    uint256 public distributionOffset = 1 days;
    uint256 public withdrawMaxLimit = 5000 ether;
    uint256 public withdrawMinLimit = 1000 ether;

    mapping(address => mapping(string => uint256)) public depositRecords;

    //Custom Errors
    error DistributionOffsetMustBeLessThenDuration();
    error Use_depositToClaimContract_function();
    error NotEnoughBalanceWaitUntilNextVesting();
    error NotReachedNextDistributionTime();
    error InvalidWithdrawClaimContract();
    error ValueMustBeGreaterThanZero();
    error TrasactionAlreadyDeposited();
    error InvalidLimitAmounts();
    error AmountCannotBeZero();
    error TransferFailed();
    error NotAuthorized();

    //Events
    event PlayerDeposit(address player, string PlayFabId, string playfabTxId, uint256 amount);
    event DepositToClaimContract(address claimContractAddress, uint256 amount);
    event SetWithdrawClaimContractAddress(address newAddress, address oldAddress, bool isApproved);
    event SetWithdrawLimits(uint256 minLimit, uint256 maxLimit, bool isApproved);
    event SetWithdrawDistributionInterval(
        uint256 durationInMinutes,
        uint256 distributionOffsetInMinutes,
        bool isApproved
    );
    event SetAuthorizedAddress(address newAddress, address oldAddress, bool isApproved);
    event Unpause(bool isApproved);
    event Pause();

    constructor(
        address _mainVaultAddress,
        address _soulsTokenAddress,
        address _managersAddress,
        address _authorizedAddress,
        address _withdrawClaimAuthorizedAddress
    ) Vault("Play To Earn Vault", _mainVaultAddress, _soulsTokenAddress, _managersAddress) {
        authorizedAddress = _authorizedAddress;
        claimContractAddress = address(
            new WithdrawClaim(_managersAddress, _soulsTokenAddress, _withdrawClaimAuthorizedAddress)
        );
    }

    // Write Fuctions

    //Managers function
    function setClaimContractAddress(address _newAddress) external onlyManager {
        if (!_newAddress.supportsInterface(type(IWithdrawClaim).interfaceId)) {
            revert InvalidWithdrawClaimContract();
        }
        string memory _title = "Set Withdraw Claim Contract Address";

        bytes memory _encodedValues = abi.encode(_newAddress);
        managers.approveTopic(_title, _encodedValues);

        address _currentValue = claimContractAddress;
        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            claimContractAddress = _newAddress;
            managers.deleteTopic(_title);
        }

        emit SetWithdrawClaimContractAddress(_newAddress, _currentValue, _isApproved);
    }

    //Managers function
    function setWithdrawLimits(uint256 _minLimit, uint256 _maxLimit) external onlyManager {
        if (_minLimit == 0) {
            revert ValueMustBeGreaterThanZero();
        }
        if (_maxLimit <= _minLimit) {
            revert InvalidLimitAmounts();
        }

        string memory _title = "Set withdraw limits";

        bytes memory _encodedValues = abi.encode(_minLimit, _maxLimit);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            withdrawMinLimit = _minLimit;
            withdrawMaxLimit = _maxLimit;
            managers.deleteTopic(_title);
        }

        emit SetWithdrawLimits(_minLimit, _maxLimit, _isApproved);
    }

    //Managers function
    function setIntervalBetweenDistributions(
        uint256 _durationInMinutes,
        uint256 _distributionOffsetInMinutes
    ) external onlyManager {
        if (_durationInMinutes == 0 || _distributionOffsetInMinutes == 0) {
            revert ValueMustBeGreaterThanZero();
        }
        if (_distributionOffsetInMinutes >= _durationInMinutes) {
            revert DistributionOffsetMustBeLessThenDuration();
        }

        string memory _title = "Set withdraw distribution Interval";

        bytes memory _encodedValues = abi.encode(_durationInMinutes, _distributionOffsetInMinutes);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            intervalBetweenDistributions = _durationInMinutes * 1 minutes;
            distributionOffset = _distributionOffsetInMinutes * 1 minutes;
            managers.deleteTopic(_title);
        }

        emit SetWithdrawDistributionInterval(_durationInMinutes, _distributionOffsetInMinutes, _isApproved);
    }

    //Managers function
    function setAuthorizedAddress(address _newAddress) external onlyManager {
        if (_newAddress == address(0)) {
            revert ZeroAddress();
        }

        string memory _title = "Set play to earn service address";

        bytes memory _encodedValues = abi.encode(_newAddress);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        address _currentValue = authorizedAddress;
        if (_isApproved) {
            authorizedAddress = _newAddress;
            managers.deleteTopic(_title);
        }

        emit SetAuthorizedAddress(_newAddress, _currentValue, _isApproved);
    }

    function pause() external onlyManager whenNotPaused {
        _pause();
        emit Pause();
    }

    //Managers function
    function unpause() external onlyManager whenPaused {
        string memory _title = "Unpause play to earn vault functions";
        bytes memory _encodedValues = abi.encode(true);
        managers.approveTopic(_title, _encodedValues);

        bool _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            _unpause();
            managers.deleteTopic(_title);
        }
        emit Unpause(_isApproved);
    }

    function withdrawTokens(address[] calldata, uint256[] calldata) external view override onlyManager {
        revert Use_depositToClaimContract_function();
    }

    function playerDepositTokensToGame(
        uint256 _amount,
        string memory _playfabId,
        string memory _playfabTxId
    ) external whenNotPaused {
        if (_amount == 0) {
            revert AmountCannotBeZero();
        }

        if (depositRecords[msg.sender][_playfabTxId] > 0) {
            revert TrasactionAlreadyDeposited();
        }

        depositRecords[msg.sender][_playfabTxId] = _amount;

        IERC20(soulsTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        emit PlayerDeposit(msg.sender, _playfabId, _playfabTxId, _amount);
    }

    function depositToClaimContract(uint256 _requiredAmount, address _nextAuthorizedAddress) external whenNotPaused {
        if (msg.sender != authorizedAddress) {
            revert NotAuthorized();
        }

        if (_nextAuthorizedAddress == address(0)) {
            revert ZeroAddress();
        }

        uint256 _nextDistributionTime = lastDistributionTime + intervalBetweenDistributions - distributionOffset;
        if (_nextDistributionTime > block.timestamp) {
            revert NotReachedNextDistributionTime();
        }

        lastDistributionTime = getNextPeriodStartTime();
        authorizedAddress = _nextAuthorizedAddress;
        IERC20 _soulsToken = IERC20(soulsTokenAddress);
        uint256 _balance = _soulsToken.balanceOf(address(this));

        if (_requiredAmount > _balance) {
            //Needs to release new vesting
            currentVestingIndex++;
            if (tokenVestings[currentVestingIndex - 1].unlockTime < block.timestamp) {
                tokenVestings[currentVestingIndex - 1].released = true;
                _soulsToken.safeTransferFrom(
                    mainVaultAddress,
                    address(this),
                    tokenVestings[currentVestingIndex - 1].amount
                );
                emit ReleaseVesting(block.timestamp, currentVestingIndex - 1);
            } else {
                revert NotEnoughBalanceWaitUntilNextVesting();
            }
        }

        _soulsToken.safeTransfer(claimContractAddress, _requiredAmount);

        emit DepositToClaimContract(claimContractAddress, _requiredAmount);
    }

    // Read Fuctions
    function isReadyForNextDistribution() public view returns (bool) {
        return block.timestamp >= lastDistributionTime + intervalBetweenDistributions - distributionOffset;
    }

    function getNextPeriodStartTime() public view returns (uint256 _startTime) {
        _startTime = block.timestamp + distributionOffset;
        if (lastDistributionTime + intervalBetweenDistributions > block.timestamp) {
            _startTime = lastDistributionTime + intervalBetweenDistributions;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IManagers.sol";

contract Vault {
    using SafeERC20 for IERC20;

    //Structs
    struct VestingInfo {
        uint256 amount;
        uint256 unlockTime;
        bool released;
    }

    //Storage Variables
    IManagers immutable managers;
    address public immutable soulsTokenAddress;
    address public immutable mainVaultAddress;

    uint256 public currentVestingIndex;

    string public vaultName;

    VestingInfo[] public tokenVestings;

    //Custom Errors
    error OnlyOnceFunctionWasCalledBefore();
    error WaitForNextVestingReleaseDate();
    error NotAuthorized_ONLY_MAINVAULT();
    error NotAuthorized_ONLY_MANAGERS();
    error DifferentParametersLength();
    error InvalidFrequency();
    error NotEnoughAmount();
    error NoMoreVesting();
    error ZeroAmount();
    error ZeroAddress();

    //Events
    event Withdraw(uint256 date, uint256 amount, bool isApproved);
    event ReleaseVesting(uint256 date, uint256 vestingIndex);

    constructor(
        string memory _vaultName,
        address _mainVaultAddress,
        address _soulsTokenAddress,
        address _managersAddress
    ) {
        if (_mainVaultAddress == address(0) || _soulsTokenAddress == address(0) || _managersAddress == address(0)) {
            revert ZeroAddress();
        }
        vaultName = _vaultName;
        mainVaultAddress = _mainVaultAddress;
        soulsTokenAddress = _soulsTokenAddress;
        managers = IManagers(_managersAddress);
    }

    //Modifiers
    modifier onlyOnce() {
        if (tokenVestings.length > 0) {
            revert OnlyOnceFunctionWasCalledBefore();
        }
        _;
    }

    modifier onlyMainVault() {
        if (msg.sender != mainVaultAddress) {
            revert NotAuthorized_ONLY_MAINVAULT();
        }
        _;
    }

    modifier onlyManager() {
        if (!managers.isManager(msg.sender)) {
            revert NotAuthorized_ONLY_MANAGERS();
        }
        _;
    }

    // Write Functions
    function createVestings(
        uint256 _totalAmount,
        uint256 _initialRelease,
        uint256 _initialReleaseDate,
        uint256 _countOfVestings,
        uint256 _vestingStartDate,
        uint256 _releaseFrequencyInDays
    ) public virtual onlyOnce onlyMainVault {
        if (_totalAmount == 0) {
            revert ZeroAmount();
        }
        if (_countOfVestings > 0 && _releaseFrequencyInDays == 0) {
            revert InvalidFrequency();
        }

        uint256 _amountUsed = 0;

        if (_initialRelease > 0) {
            tokenVestings.push(
                VestingInfo({amount: _initialRelease, unlockTime: _initialReleaseDate, released: false})
            );
            _amountUsed += _initialRelease;
        }
        uint256 releaseFrequency = _releaseFrequencyInDays * 1 days;

        if (_countOfVestings > 0) {
            uint256 _vestingAmount = (_totalAmount - _initialRelease) / _countOfVestings;

            for (uint256 i = 0; i < _countOfVestings; i++) {
                if (i == _countOfVestings - 1) {
                    _vestingAmount = _totalAmount - _amountUsed;
                }
                tokenVestings.push(
                    VestingInfo({
                        amount: _vestingAmount,
                        unlockTime: _vestingStartDate + (i * releaseFrequency),
                        released: false
                    })
                );
                _amountUsed += _vestingAmount;
            }
        }
    }

    //Managers function
    function withdrawTokens(address[] calldata _receivers, uint256[] calldata _amounts) external virtual onlyManager {
        _withdrawTokens(_receivers, _amounts);
    }

    function _withdrawTokens(
        address[] memory _receivers,
        uint256[] memory _amounts
    ) internal returns (bool _isApproved) {
        if (_receivers.length != _amounts.length) {
            revert DifferentParametersLength();
        }

        uint256 _totalAmount = 0;
        for (uint256 a = 0; a < _amounts.length; a++) {
            if (_amounts[a] == 0) {
                revert ZeroAmount();
            }

            _totalAmount += _amounts[a];
        }

        uint256 _balance = IERC20(soulsTokenAddress).balanceOf(address(this));
        uint256 _amountWillBeReleased = 0;
        if (_totalAmount > _balance) {
            if (currentVestingIndex >= tokenVestings.length) {
                revert NoMoreVesting();
            }

            if (block.timestamp < tokenVestings[currentVestingIndex].unlockTime) {
                revert WaitForNextVestingReleaseDate();
            }

            for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                if (tokenVestings[v].unlockTime > block.timestamp) break;
                _amountWillBeReleased += tokenVestings[v].amount;
            }

            if (_amountWillBeReleased + _balance < _totalAmount) {
                revert NotEnoughAmount();
            }
        }

        string memory _title = string.concat("Withdraw Tokens From ", vaultName);

        bytes memory _encodedValues = abi.encode(_receivers, _amounts);
        managers.approveTopic(_title, _encodedValues);
        _isApproved = managers.isApproved(_title, _encodedValues);
        if (_isApproved) {
            IERC20 _soulsToken = IERC20(soulsTokenAddress);
            if (_totalAmount > _balance) {
                //Needs to release new vesting

                for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
                    if (tokenVestings[v].unlockTime < block.timestamp) {
                        tokenVestings[v].released = true;
                        emit ReleaseVesting(block.timestamp, v);
                        currentVestingIndex++;
                    }
                }

                if (_amountWillBeReleased > 0) {
                    _soulsToken.safeTransferFrom(mainVaultAddress, address(this), _amountWillBeReleased);
                }
            }

            for (uint256 r = 0; r < _receivers.length; r++) {
                address _receiver = _receivers[r];
                uint256 _amount = _amounts[r];

                _soulsToken.safeTransfer(_receiver, _amount);
            }
            managers.deleteTopic(_title);
        }

        emit Withdraw(block.timestamp, _totalAmount, _isApproved);
    }

    //Read Functions
    function getVestingData() public view returns (VestingInfo[] memory) {
        return tokenVestings;
    }

    function getAvailableAmountForWithdraw() public view returns (uint256 _amount) {
        _amount = IERC20(soulsTokenAddress).balanceOf(address(this));
        for (uint256 v = currentVestingIndex; v < tokenVestings.length; v++) {
            if (tokenVestings[v].unlockTime > block.timestamp) break;
            _amount += tokenVestings[v].amount;
        }
    }
}