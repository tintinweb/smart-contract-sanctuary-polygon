// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

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
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ChaiLabsPrivateSale {
    using SafeERC20 for IERC20;

    struct Sale {
        // token for the private sale
        address saleToken;
        // the admin of the sale
        address admin;
        // address to receive the payment from sale
        address paymentRecipient;
        // true if user can contribute
        bool enabled;
        // true if admin has claimed the payment and closed the sale
        bool finalized;
        // timestamp when user can claim their tokens
        uint256 claimTime;
        // merkle proof root
        bytes32 root;
    }

    // sale can be conducted in multiple rounds
    struct SaleRound {
        // 0 value is considered not capped
        uint256 softCap;
        // 0 value is considered not capped
        uint256 hardCap;
        // unit price per unit of token
        uint256 price;
        // maximum amount of payment tokens spent by user for this round
        uint256 maxContribution;
        // minimum amount of payment tokens spent by user for this round
        uint256 minContribution;
        // token to buy the sale round, zero address is considered eth
        address paymentToken;
        // timestamp for the round to start, 0 is for manaul start by admin
        uint256 startTime;
        // time duration of this round
        uint256 saleDuration;
        // true if only whitelisted users can contribute
        bool whitelisted;
        // if true, the sale is moved to next round manually
        bool closed;
    }

    uint256 public nextSaleId;

    // sale id => Sale
    mapping(uint256 => Sale) public sales;
    // sale id => SaleRound[]
    mapping(uint256 => SaleRound[]) public saleRounds;
    // user address => sale id => saleRound id => user contributions
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userContributions;
    // user address => sale id => saleRound id => user deposited amount,
    // that the contract receives after any fee deduction in payment method
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userDepositedAmount;
    // tracks who has contributed in whitelist
    mapping(address => mapping(uint256 => mapping(uint256 => bool))) public whitelistClaimed;
    // sale id => saleRound id => total contributions
    mapping(uint256 => mapping(uint256 => uint256)) public totalContributions;
    // sale id => saleRound id => total deposit amount,
    // that the contract receives after any fee deduction in payment method
    mapping(uint256 => mapping(uint256 => uint256)) public totalDepositedAmounts;

    event SaleCreated(
        uint256 indexed saleId,
        address indexed saleToken,
        address indexed admin,
        address paymentRecipient,
        uint256 rounds
    );
    event SaleRoundCreated(
        uint256 saleId,
        uint256 softCap,
        uint256 hardCap,
        uint256 price,
        uint256 maxContribution,
        uint256 minContribution,
        address paymentToken,
        uint256 startTime,
        uint256 saleDuration
    );
    event SaleRoundClosed(uint256 indexed saleId, uint256 indexed saleRoundId, uint256 timestamp);
    event SaleFinalized(uint256 indexed saleId, uint256[] amount);
    event UserContribution(uint256 indexed saleId, uint256 indexed saleRoundId, address indexed user, uint256 amount);
    event UserClaim(
        uint256 indexed saleId,
        uint256 indexed saleRoundId,
        address indexed user,
        uint256 contribution,
        uint256 claim
    );
    event UserClaimBackContribution(uint256 indexed saleId, uint256 indexed saleRoundId, uint256 amount);
    event SaleMerkleRootUpdated(uint256 indexed saleId, bytes32 root);
    event SaleClaimTimeUpdated(uint256 indexed saleId,uint256 claimTime);

    uint256 public constant PRICE_DENOMINATOR = 1e18;

    modifier validateSale(uint256 saleId) {
        require(saleId < nextSaleId, "ChaiLabs: invlaid sale id");
        require(sales[saleId].enabled, "ChaiLabs: sale disabled");
        _;
    }

    function getSaleRoundsLength(uint256 saleId) public view returns (uint256) {
        return saleRounds[saleId].length;
    }

    function getSaleInfo(uint256 saleId, address user)
        public
        view
        returns (
            Sale memory _sale,
            SaleRound[] memory _rounds,
            uint256[] memory,
            uint256[] memory
        )
    {
        _sale = sales[saleId];
        _rounds = saleRounds[saleId];
        uint256[] memory _totalContributions = new uint256[](_rounds.length);
        uint256[] memory _userContributions = new uint256[](_rounds.length);
        for (uint256 i = 0; i < _rounds.length; i++) {
            _totalContributions[i] = totalContributions[saleId][i];
            _userContributions[i] = userContributions[user][saleId][i];
        }

        return (_sale, _rounds, _totalContributions, _userContributions);
    }

    function createSale(
        Sale memory sale,
        SaleRound[] memory rounds,
        uint256 amountToDeposit
    ) external {
        require(sale.admin != address(0), "ChaiLabs: invalid admin");
        require(sale.paymentRecipient != address(0), "ChaiLabs: invalid paymentRecipient");
        require(sale.claimTime >= block.timestamp, "ChaiLabs: invalid claim time");
        require(sale.saleToken != address(0), "ChainLabs: invalid saleToken");

        sale.finalized = false;
        sales[nextSaleId] = sale;

        _addSaleRound(nextSaleId, rounds);
        _depositSaleToken(nextSaleId, rounds, amountToDeposit);

        SaleRound memory lastRound = saleRounds[nextSaleId][saleRounds[nextSaleId].length - 1];
        require(lastRound.startTime + lastRound.saleDuration < sale.claimTime, "ChaiLabs: claim time too soon");

        emit SaleCreated(nextSaleId, sale.saleToken, sale.admin, sale.paymentRecipient, saleRounds[nextSaleId].length);
        if (sale.root.length != 0) emit SaleMerkleRootUpdated(nextSaleId, sale.root);

        nextSaleId++;
    }

    function contribute(
        uint256 saleId,
        uint256 roundId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external payable validateSale(saleId) {
        SaleRound memory saleRound = saleRounds[saleId][roundId];
        require(!sales[saleId].finalized, "ChaiLabs: sale closed");

        _canContribute(saleId, roundId, amount, merkleProof);

        if (saleRound.paymentToken == address(0)) {
            require(msg.value != 0, "ChaiLabs: invalid eth");
            userContributions[msg.sender][saleId][roundId] += amount;
            userDepositedAmount[msg.sender][saleId][roundId] += amount;
            totalContributions[saleId][roundId] += amount;
            totalDepositedAmounts[saleId][roundId] += amount;
        } else {
            userContributions[msg.sender][saleId][roundId] += amount;
            totalContributions[saleId][roundId] += amount;
            uint256 balanceBefore = IERC20(saleRound.paymentToken).balanceOf(address(this));
            IERC20(saleRound.paymentToken).safeTransferFrom(msg.sender, address(this), amount);
            uint256 amountDeposited = IERC20(saleRound.paymentToken).balanceOf(address(this)) - balanceBefore;
            userDepositedAmount[msg.sender][saleId][roundId] += amountDeposited;
            totalDepositedAmounts[saleId][roundId] += amountDeposited;
        }

        emit UserContribution(saleId, roundId, msg.sender, amount);
    }

    function finalizeSale(uint256 saleId, address paymentRecipient) external validateSale(saleId) {
        Sale storage sale = sales[saleId];
        require(paymentRecipient != address(0), "ChaiLabs:Recipient address is zero");
        require(sale.admin == msg.sender, "ChaiLabs: not admin");
        require(!sales[saleId].finalized, "ChaiLabs: sale already finalized");

        sale.finalized = true;
        SaleRound[] memory rounds = saleRounds[saleId];
        uint256[] memory amounts = new uint256[](rounds.length);
        for (uint256 i = 0; i < rounds.length; i++) {
            // if softcap is filled, finalize this round
            if (totalContributions[saleId][i] >= rounds[i].softCap) continue;

            amounts[i] = totalDepositedAmounts[saleId][i];
            if (rounds[i].paymentToken == address(0)) {
                payable(paymentRecipient).transfer(totalDepositedAmounts[saleId][i]);
            } else {
                IERC20(rounds[i].paymentToken).safeTransfer(paymentRecipient, totalDepositedAmounts[saleId][i]);
            }
        }
        emit SaleFinalized(saleId, amounts);
    }

    /**
        Tokens can be claimed in following condition are true
        -   ClaimTime has started
        -   Softcap has filled
     */
    function claim(uint256 saleId) external validateSale(saleId) {
        Sale memory sale = sales[saleId];
        SaleRound[] memory rounds = saleRounds[saleId];

        require(sale.claimTime <= block.timestamp, "ChaiLabs: claim too early");

        for (uint256 i = 0; i < rounds.length; i++) {
            uint256 claimAmount = (userContributions[msg.sender][saleId][i] * rounds[i].price) / PRICE_DENOMINATOR;
            // if softcap is filled and user have some contribution, allow him to claim tokens
            require(claimAmount != 0,"ChaiLabs: User has not enough funds to claim");
            if (claimAmount > 0 && _softCapFilled(saleId, i)) {
                delete userContributions[msg.sender][saleId][i];
                IERC20(sale.saleToken).safeTransfer(msg.sender, claimAmount);
                emit UserClaim(saleId, i, msg.sender, claimAmount, claimAmount);
            }
        }
    }

    /**
        If the last round of the sale is filled, 
        Then Admin can update claim time of sale

     */

    function updateSaleClaimTime(uint256 saleId, uint256 _claimTime) external validateSale(saleId) {
        require(sales[saleId].admin == msg.sender, "ChaiLabs: not admin");
        require(!sales[saleId].finalized, "ChaiLabs: sale already finalized");
        SaleRound memory lastSaleRound = saleRounds[saleId][saleRounds[saleId].length - 1];
        uint256 lastRoundEndTime = lastSaleRound.startTime + lastSaleRound.saleDuration;
        require(
            lastSaleRound.softCap <= totalContributions[saleId][saleRounds[saleId].length - 1],
            "ChaiLabs: Last round softcap not filled"
        );
        require(_claimTime > lastRoundEndTime, "ChaiLabs:invalid claim time");
    
        sales[saleId].claimTime = _claimTime;
        emit SaleClaimTimeUpdated(saleId,_claimTime);
    }

    /**
        If the round wasn't filled properly, 
        user can claim there tokens back when sale ends if the following conditions are true
        -   Softcap hasn't filled 
            & 
        -   Sale round duration has ended
     */

    function claimBackContribution(uint256 saleId) external validateSale(saleId) {
        SaleRound[] memory rounds = saleRounds[saleId];

        for (uint256 i = 0; i < rounds.length; i++) {
            // if round has ended and soft cap wasn't filled, return back the payment to user

            require(rounds[i].startTime + rounds[i].saleDuration < block.timestamp, "ChaiLabs: Round has not ended");
            require(saleRounds[saleId][i].softCap != 0, "ChaiLabs: Round softcap is zero");
            require(
                saleRounds[saleId][i].softCap >= totalContributions[saleId][i],
                "ChaiLabs: Round softcap is filled"
            );

            uint256 contribution = userContributions[msg.sender][saleId][i];
            uint256 depositAmount = userDepositedAmount[msg.sender][saleId][i];
            totalDepositedAmounts[saleId][i] -= depositAmount;
            totalContributions[saleId][i] -= contribution;
            delete userDepositedAmount[msg.sender][saleId][i];
            delete userContributions[msg.sender][saleId][i];
            if (rounds[i].paymentToken == address(0)) {
                payable(msg.sender).transfer(depositAmount);
            } else {
                IERC20(rounds[i].paymentToken).safeTransfer(msg.sender, depositAmount);
            }
            emit UserClaimBackContribution(saleId, i, depositAmount);
        }
    }

    function setMerkleRoot(uint256 saleId, bytes32 root) external {
        require(msg.sender == sales[saleId].admin, "ChaiLabs: not admin");
        sales[saleId].root = root; 
    }

    function _addSaleRound(uint256 saleId, SaleRound[] memory rounds) private {
        require(msg.sender == sales[saleId].admin, "ChaiLabs: not admin");

        for (uint256 i = 0; i < rounds.length; i++) {
            require(rounds[i].hardCap != 0, "ChaiLabs: hardcap can't be zero");
            uint256 lastRoundEndTime;
            if (saleRounds[saleId].length == 0) {
                lastRoundEndTime = 0;
            } else {
                SaleRound memory lastSaleRound = saleRounds[saleId][saleRounds[saleId].length - 1];
                lastRoundEndTime = lastSaleRound.startTime + lastSaleRound.saleDuration;
            }
            rounds[i].closed = false;
            saleRounds[saleId].push(rounds[i]);
            require(
                lastRoundEndTime < rounds[i].startTime &&
                    rounds[i].startTime != rounds[i].saleDuration &&
                    rounds[i].startTime > block.timestamp,
                "ChaiLabs: invalid round start time or duration"
            );
            lastRoundEndTime = rounds[i].startTime + rounds[i].saleDuration;

            emit SaleRoundCreated(
                saleId,
                rounds[i].softCap,
                rounds[i].hardCap,
                rounds[i].price,
                rounds[i].maxContribution,
                rounds[i].minContribution,
                rounds[i].paymentToken,
                rounds[i].startTime,
                rounds[i].saleDuration
            );
        }
    }

    /** A user can only contribute if
        - Sale is not finished
        - Round was not closed manually
        - Round has started
        - Round time has not finished
        - Contribution is not greater than max contribution
        - Hardcap for round is not filled
        - If previous round's softcap was reached
     */
    function _canContribute(
        uint256 saleId,
        uint256 roundId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) internal {
        SaleRound memory saleRound = saleRounds[saleId][roundId];

        require(!sales[saleId].finalized, "ChaiLabs: sale finalized");
        require(!saleRound.closed, "ChaiLabs: round closed");
        require(saleRound.startTime <= block.timestamp, "ChaiLabs: round not started yet");
        require(saleRound.startTime + saleRound.saleDuration >= block.timestamp, "ChaiLabs: round has ended");
        require(saleRound.minContribution <= amount, "ChaiLabs: contribution too low");

        require(
            saleRound.maxContribution >= userContributions[msg.sender][saleId][roundId] + amount,
            "ChaiLabs: contribution too high"
        );
        require(!_hardCapFilled(saleId, roundId, amount), "ChaiLabs: hardcap filled");

        // only allow if previous round's softcap was filled
        if (saleRounds[saleId].length > 1 && roundId > 0) {
            require(
                saleRounds[saleId][roundId - 1].hardCap == totalContributions[saleId][roundId],
                "ChaiLabs: previous round not filled"
            );
        }

        // check if sale round is whitelisted
        if (saleRound.whitelisted) {
            _validateWhitelist(saleId, roundId, msg.sender, merkleProof);
        }
    }

    function _validateWhitelist(
        uint256 saleId,
        uint256 saleRoundId,
        address user,
        bytes32[] calldata merkleProof
    ) internal {
        require(!whitelistClaimed[user][saleId][saleRoundId], "ChaiLabs: whitelist already used");

        bytes32 node = keccak256(abi.encodePacked(user));
        require(MerkleProof.verify(merkleProof, sales[saleId].root, node), "ChaiLabs: invalid proof");
        whitelistClaimed[user][saleId][saleRoundId] = true;
    }

    function _depositSaleToken(
        uint256 saleId,
        SaleRound[] memory rounds,
        uint256 amountToDeposit
    ) internal {
        Sale memory sale = sales[saleId];

        uint256 saleTokenAmount;
        for (uint256 i = 0; i < rounds.length; i++) {
            saleTokenAmount += (rounds[i].hardCap * rounds[i].price) / PRICE_DENOMINATOR;
        }
        uint256 balanceBefore = IERC20(sale.saleToken).balanceOf(address(this));
        IERC20(sale.saleToken).safeTransferFrom(msg.sender, address(this), amountToDeposit);
        uint256 amountDeposited = IERC20(sale.saleToken).balanceOf(address(this)) - balanceBefore;
        require(amountDeposited >= saleTokenAmount, "ChaiLabs: deposit amount not enough");
    }

    function _softCapFilled(uint256 saleId, uint256 roundId) internal view validateSale(saleId) returns (bool) {
        return
            saleRounds[saleId][roundId].softCap >= totalContributions[saleId][roundId] ||
            saleRounds[saleId][roundId].softCap == 0;
    }

    function _hardCapFilled(
        uint256 saleId,
        uint256 roundId,
        uint256 amount
    ) internal view validateSale(saleId) returns (bool isFilled) {
        isFilled = true;
        if (
            saleRounds[saleId][roundId].hardCap == 0 ||
            saleRounds[saleId][roundId].hardCap >= totalContributions[saleId][roundId] + amount
        ) {
            isFilled = false;
        }
    }
}