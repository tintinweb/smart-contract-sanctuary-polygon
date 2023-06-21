// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.17;

import "./IGuardians.sol";

/**
 * @dev {IERC11554K} interface:
 */
interface IERC11554K {
    function controllerMint(
        address mintAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function controllerBurn(
        address burnAddress,
        uint256 tokenId,
        uint256 amount
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setURI(string calldata newuri) external;

    function setCollectionURI(string calldata collectionURI_) external;

    function setVerificationStatus(bool _isVerified) external;

    function setGlobalRoyalty(address receiver, uint96 feeNumerator) external;

    function owner() external view returns (address);

    function balanceOf(
        address user,
        uint256 item
    ) external view returns (uint256);

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function totalSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";

/**
 * @dev {IERC11554KController} interface:
 */
interface IERC11554KController {
    /// @dev Batch minting request data structure.
    struct BatchRequestMintData {
        /// @dev Collection address.
        IERC11554K collection;
        /// @dev Item id.
        uint256 id;
        /// @dev Guardian address.
        address guardianAddress;
        /// @dev Amount to mint.
        uint256 amount;
        /// @dev Service fee to guardian.
        uint256 serviceFee;
        /// @dev Is item supply expandable.
        bool isExpandable;
        /// @dev Recipient address.
        address mintAddress;
        /// @dev Guardian class index.
        uint256 guardianClassIndex;
        /// @dev Guardian fee amount to pay.
        uint256 guardianFeeAmount;
    }

    function requestMint(
        IERC11554K collection,
        uint256 id,
        address guardian,
        uint256 amount,
        uint256 serviceFee,
        bool expandable,
        address mintAddress,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount
    ) external returns (uint256);

    function mint(IERC11554K collection, uint256 id) external;

    function owner() external returns (address);

    function originators(
        address collection,
        uint256 tokenId
    ) external returns (address);

    function isActiveCollection(address collection) external returns (bool);

    function isLinkedCollection(address collection) external returns (bool);

    function paymentToken() external returns (IERC20Upgradeable);

    function maxMintPeriod() external returns (uint256);

    function remediationBurn(
        IERC11554K collection,
        address owner,
        uint256 id,
        uint256 amount
    ) external;

    function setMaxMintPeriod(uint256 maxMintPeriod_) external;

    function setRemediator(address _remediator) external;

    function setCollectionFee(uint256 collectionFee_) external;

    function setBeneficiary(address beneficiary_) external;

    function setGuardians(IGuardians guardians_) external;

    function setPaymentToken(IERC20Upgradeable paymentToken_) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function guardians() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./IERC11554K.sol";

/**
 * @dev {IERC11554KDrops} interface:
 */
interface IERC11554KDrops is IERC11554K {
    function setItemUriID(uint256 id, uint256 uriID) external;

    function setVaulted() external;

    function setRevealed(string calldata collectionURI_) external;

    function setMintingDrops(address mintingDrops_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IGuardians.sol";
import "./IERC11554KController.sol";

/**
 * @dev {IFeesManager} interface:
 */
interface IFeesManager {
    function receiveFees(
        IERC11554K erc11554k,
        uint256 id,
        IERC20Upgradeable asset,
        uint256 _salePrice
    ) external;

    function calculateTotalFee(
        IERC11554K erc11554k,
        uint256 id,
        uint256 _salePrice
    ) external returns (uint256);

    function payGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address payer,
        IERC20Upgradeable paymentAsset
    ) external;

    function refundGuardianFee(
        uint256 guardianFeeAmount,
        uint256 guardianClassFeeRateMultiplied,
        address guardian,
        uint256 storagePaidUntil,
        address recipient,
        IERC20Upgradeable paymentAsset
    ) external;

    function moveFeesBetweenGuardians(
        address guardianFrom,
        address guardianTo,
        IERC20Upgradeable asset
    ) external;

    function setGuardians(IGuardians guardians_) external;

    function setController(IERC11554KController controller_) external;

    function setGlobalTradingFee(uint256 globalTradingFee_) external;

    function setTradingFeeSplit(
        uint256 protocolSplit,
        uint256 guardianSplit
    ) external;

    function setExchange(address exchange_) external;

    function setVersion(bytes32 version_) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IERC11554K.sol";
import "./IERC11554KController.sol";
import "./IFeesManager.sol";

/**
 * @dev {IGuardians} interface:
 */
interface IGuardians {
    enum GuardianFeeRatePeriods {
        SECONDS,
        MINUTES,
        HOURS,
        DAYS
    }

    function controllerStoreItem(
        IERC11554K collection,
        address mintAddress,
        uint256 id,
        address guardian,
        uint256 guardianClassIndex,
        uint256 guardianFeeAmount,
        uint256 numItems,
        address feePayer,
        IERC20Upgradeable paymentAsset
    ) external;

    function controllerTakeItemOut(
        address guardian,
        IERC11554K collection,
        uint256 id,
        uint256 numItems,
        address from
    ) external;

    function shiftGuardianFeesOnTokenMove(
        address from,
        address to,
        uint256 id,
        uint256 amount
    ) external;

    function setController(IERC11554KController controller_) external;

    function setFeesManager(IFeesManager feesManager_) external;

    function setMinStorageTime(uint256 minStorageTime_) external;

    function setMinimumRequestFee(uint256 minimumRequestFee_) external;

    function setMaximumGuardianFeeSet(uint256 maximumGuardianFeeSet_) external;

    function setGuardianFeeSetWindow(uint256 guardianFeeSetWindow_) external;

    function moveItems(
        IERC11554K collection,
        uint256[] calldata ids,
        address oldGuardian,
        address newGuardian,
        uint256[] calldata newGuardianClassIndeces
    ) external;

    function copyGuardianClasses(
        address oldGuardian,
        address newGuardian
    ) external;

    function setActivity(address guardian, bool activity) external;

    function setPrivacy(address guardian, bool privacy) external;

    function setLogo(address guardian, string calldata logo) external;

    function setName(address guardian, string calldata name) external;

    function setPhysicalAddressHash(
        address guardian,
        bytes32 physicalAddressHash
    ) external;

    function setPolicy(address guardian, string calldata policy) external;

    function setRedirect(address guardian, string calldata redirect) external;

    function changeWhitelistUsersStatus(
        address guardian,
        address[] calldata users,
        bool whitelistStatus
    ) external;

    function removeGuardian(address guardian) external;

    function setGuardianClassMintingFee(
        address guardian,
        uint256 classID,
        uint256 mintingFee
    ) external;

    function setGuardianClassRedemptionFee(
        address guardian,
        uint256 classID,
        uint256 redemptionFee
    ) external;

    function setGuardianClassGuardianFeeRate(
        address guardian,
        uint256 classID,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassGuardianFeePeriodAndRate(
        address guardian,
        uint256 classID,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        uint256 guardianFeeRate
    ) external;

    function setGuardianClassURI(
        address guardian,
        uint256 classID,
        string calldata uri
    ) external;

    function setGuardianClassActiveStatus(
        address guardian,
        uint256 classID,
        bool activeStatus
    ) external;

    function setGuardianClassMaximumCoverage(
        address guardian,
        uint256 classID,
        uint256 maximumCoverage
    ) external;

    function addGuardianClass(
        address guardian,
        uint256 maximumCoverage,
        uint256 mintingFee,
        uint256 redemptionFee,
        uint256 guardianFeeRate,
        GuardianFeeRatePeriods guardianFeeRatePeriod,
        string calldata uri
    ) external;

    function registerGuardian(
        address guardian,
        string calldata name,
        string calldata logo,
        string calldata policy,
        string calldata redirect,
        bytes32 physicalAddressHash,
        bool privacy
    ) external;

    function transferOwnership(address newOwner) external;

    function setVersion(bytes32 version_) external;

    function isAvailable(address guardian) external view returns (bool);

    function guardianInfo(
        address guardian
    )
        external
        view
        returns (
            bytes32,
            string memory,
            string memory,
            string memory,
            string memory,
            bool,
            bool
        );

    function guardianWhitelist(
        address guardian,
        address user
    ) external view returns (bool);

    function delegated(address guardian) external view returns (address);

    function getRedemptionFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function getMintingFee(
        address guardian,
        uint256 classID
    ) external view returns (uint256);

    function isClassActive(
        address guardian,
        uint256 classID
    ) external view returns (bool);

    function minStorageTime() external view returns (uint256);

    function feesManager() external view returns (address);

    function stored(
        address guardian,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function whereItemStored(
        IERC11554K collection,
        uint256 id
    ) external view returns (address);

    function itemGuardianClass(
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function guardianFeePaidUntil(
        address user,
        address collection,
        uint256 id
    ) external view returns (uint256);

    function isFeeAboveMinimum(
        uint256 guardianFeeAmount,
        uint256 numItems,
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (bool);

    function getGuardianFeeRateByCollectionItem(
        IERC11554K collection,
        uint256 itemId
    ) external view returns (uint256);

    function getGuardianFeeRate(
        address guardian,
        uint256 guardianClassIndex
    ) external view returns (uint256);

    function isWhitelisted(address guardian) external view returns (bool);

    function inRepossession(
        address user,
        IERC11554K collection,
        uint256 id
    ) external view returns (uint256);

    function isDelegated(
        address guardian,
        address delegatee,
        IERC11554K collection
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IERC11554KController.sol";
import "./interfaces/IERC11554KDrops.sol";
import "./interfaces/IGuardians.sol";

/**
 * @dev MintingDrops manages minting drops for a collection.
 */
contract MintingDrops is Ownable {
    using SafeERC20 for IERC20;

    /// @notice Minting Drops types
    enum DropType {
        /// @notice ERC-721 (ERC-1155 with each id having single item) random minting drop
        NFT,
        /// @notice Users choose set of items and randomly mint items in each set
        SEMI,
        /// @notice Users choose which item to mint
        DETERMINED
    }

    /// @notice Is minting drop private or public.
    bool public immutable isPrivate;
    /// @notice Collection contract.
    IERC11554KDrops public immutable collection;
    /// @notice Controller contract.
    IERC11554KController public immutable controller;
    /// @notice Maximum items to mint per mint for collection.
    uint256 public immutable maxItemsPerMint;
    /// @notice Maximum items to mint per ID for collection.
    uint256 public immutable maxItemsPerID;
    /// @notice Maximum items to mint in the drop.
    uint256 public immutable maxItems;
    /// @notice Maximum items to mint per mint for collection.
    uint256 public immutable guardianFeeAmountPerItem;
    /// @notice Maximum items to mint per ID for collection.
    uint256 public immutable guardianClassIndex;
    /// @notice Maximum items to mint in the drop.
    uint256 public immutable serviceFeePerItem;
    /// @notice Items variations in case of non-NFT drop.
    uint256 public immutable variations;
    /// @notice Drop type.
    DropType public immutable dropType;
    /// @notice Guardian that vaults items during drop.
    address public immutable managingGuardian;
    /// @notice Allowlist merkle root for checking if user in allowlist or not.
    bytes32 public allowlistMerkleRoot;
    /// @notice Minted items.
    uint256 public mintedItems;
    /// @notice ETH drop minting fee.
    uint256 public dropFee;
    /// @notice Minting Drop start time. Can only be set once.
    uint256 public startTime;
    /// @notice Minting Drop end time. Can only be set once.
    uint256 public endTime;
    /// @notice Which user owns item with URI ID
    mapping(uint256 => address) public uriIDUser;
    /// @notice Items minted for each URI ID.
    mapping(uint256 => uint256) public itemsIDMinted;
    /// @notice Mapped URI IDs to collection item IDs.
    mapping(uint256 => uint256) public uriIDItemID;
    /// @notice Helper initial state of URI ids for NFT random minting drop
    uint256[] public helperIdsList;
    /// @notice Items classes variations prefix sums. i-th element is sum of classes variations from 0-th to i-th.
    uint256[] public prefixSumsVariations;

    /// @notice Minted drop
    event MintedDrop(
        uint256 id,
        uint256 randomUriID,
        uint256 amount,
        address minter
    );

    error AccessDenied();
    error NotPrivate();
    error EqualItems();
    error InvalidAmount();
    error AlreadySet();
    error MintingLimitExceeded();
    error AlreadyMinted();
    error ETHTransferFailed();
    error LowSentETH();
    error NotNFTDrop();
    error NotSEMIDrop();
    error NotManagingGuardian();
    error NotStarted();
    error InvalidItemID();
    error HasEnded();

    /**
     * @dev Only guardian modifier.
     */
    modifier onlyManagingGuardian() {
        if (managingGuardian != _msgSender()) {
            revert NotManagingGuardian();
        }
        _;
    }

    constructor(
        IERC11554KController controller_,
        IERC11554KDrops collection_,
        bool isPrivate_,
        uint256 maxItemsPerMint_,
        uint256 maxItemsPerID_,
        uint256 maxItems_,
        uint256 variations_,
        address managingGuardian_,
        DropType dropType_,
        uint256 serviceFeePerItem_,
        uint256 guardianFeeAmountPerItem_,
        uint256 guardianClassIndex_
    ) {
        controller = controller_;
        collection = collection_;
        isPrivate = isPrivate_;
        maxItemsPerMint = maxItemsPerMint_;
        maxItemsPerID = maxItemsPerID_;
        maxItems = maxItems_;
        variations = variations_;
        managingGuardian = managingGuardian_;
        dropType = dropType_;
        serviceFeePerItem = serviceFeePerItem_;
        guardianFeeAmountPerItem = guardianFeeAmountPerItem_;
        guardianClassIndex = guardianClassIndex_;
        controller_.paymentToken().approve(
            address(controller_),
            type(uint256).max
        );
        controller_.paymentToken().approve(
            IGuardians(controller_.guardians()).feesManager(),
            type(uint256).max
        );
    }

    /**
     * @notice Fallback ETH receive function.
     */
    receive() external payable {}

    /**
     * @notice Withdraws ETH to receiver.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param amount ETH amount to withdraw.
     * @param receiver address to send ETH.
     */
    function withdrawEther(
        uint256 amount,
        address payable receiver
    ) external payable onlyOwner {
        (bool success, ) = receiver.call{value: amount}(""); // solhint-disable-line avoid-low-level-calls
        if (!success) {
            revert ETHTransferFailed();
        }
    }

    /**
     * @notice Withdraws payment token asset to receiver.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param amount ETH amount to withdraw.
     * @param receiver address to send ETH.
     */
    function withdrawPaymentToken(
        uint256 amount,
        address receiver
    ) external payable onlyOwner {
        IERC20(address(controller.paymentToken())).safeTransfer(
            receiver,
            amount
        );
    }

    /**
     * @notice Sets helper ids list for NFT random drop. Can do it only once.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     */
    function setHelperIdsList() external onlyOwner {
        if (helperIdsList.length > 0) {
            revert AlreadySet();
        }
        if (dropType != DropType.NFT) {
            revert NotNFTDrop();
        }
        uint256 maxItems_ = maxItems;
        for (uint256 i = 1; i <= maxItems_; ++i) {
            helperIdsList.push(i);
        }
    }

    /**
     * @notice Sets items classes variations if they are different by class in case of SEMI drop.
     * Calculates prefix sums of classes variations to later on derive exact URI ID of an item.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * 2) Variations list length must be a number of classes.
     */
    function setClassesVariations(uint256[] calldata variationsList) external onlyOwner {
        if (prefixSumsVariations.length > 0) {
            revert AlreadySet();
        }
        if (dropType != DropType.SEMI) {
            revert NotSEMIDrop();
        }
        for (uint256 i = 0; i < variationsList.length; ++i) {
            // Calculate next prefix variations sum of first i claases by taking (i-1)-th prefix sum and adding i-th variations.
            prefixSumsVariations.push((i > 0 ? prefixSumsVariations[i - 1] : 0) + variationsList[i]);
        }
    }

    /**
     * @notice Sets dropFee to dropFee_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param dropFee_ New drops fee
     */
    function setDropFee(uint256 dropFee_) external onlyOwner {
        dropFee = dropFee_;
    }

    /**
     * @notice Sets startTime to startTime_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param startTime_ New start time
     */
    function setStartTime(uint256 startTime_) external onlyOwner {
        if (startTime != 0) {
            revert AlreadySet();
        }
        startTime = startTime_;
    }

    /**
     * @notice Sets endTime to endTime_.
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param endTime_ New end time
     */
    function setEndTime(uint256 endTime_) external onlyOwner {
        if (endTime != 0) {
            revert AlreadySet();
        }
        endTime = endTime_;
    }

    /**
     * @notice Sets allowlist root if drop is private
     *
     * Requirements:
     *
     * 1) The caller must be a contract owner.
     * @param allowlistMerkleRoot_ Allowlist merkle root
     */
    function setAllowlistMerkleRoot(
        bytes32 allowlistMerkleRoot_
    ) external onlyOwner {
        if (!isPrivate) {
            revert NotPrivate();
        }
        allowlistMerkleRoot = allowlistMerkleRoot_;
    }

    /**
     * @notice Sets collection status to vaulted.
     *
     * Requirements:
     *
     * 1) The caller must be a managing guardian.
     **/
    function setVaulted() external virtual onlyManagingGuardian {
        collection.setVaulted();
    }

    /**
     * @notice Does minting drop for user based on IERC11554KController requestMint.
     *
     * Requirements:
     *
     * 1) Must satisfy all controller.requestMint() and controller.mint() conditions
     * 2) Sender should be in allowlist if the drop is private.
     * 3) Amount items to mint cannot exceed maxItemsPerMint.
     * 4) Must send enough ETH to cover dropFee * amount and to cover all additional fees
     * @param amount Amount of items to mint.
     * @param itemId If minting drop allows users to mint to any id then just means URI item id (regardless of whether we have variations or not),
     * in case of semi-random items sets with variations allows to mint to specific items class. If its random NFT minting then fully ignored.
     * @param allowlistProof, merkle proof list of user inclusing in drop allowlist, used if drop is private.
     * @return id
     */
    function mint(
        uint256 amount,
        uint256 itemId,
        bytes32[] calldata allowlistProof
    ) external payable virtual returns (uint256 id, uint256 uriID) {
        if (startTime != 0 && startTime > block.timestamp) {
            revert NotStarted();
        }
        if (endTime != 0 && endTime < block.timestamp) {
            revert HasEnded();
        }
        if (
            isPrivate &&
            !MerkleProof.verifyCalldata(
                allowlistProof,
                allowlistMerkleRoot,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert AccessDenied();
        }
        if (amount > 1 && dropType == DropType.NFT) {
            revert InvalidAmount();
        }
        if (amount > maxItemsPerMint || mintedItems + amount > maxItems) {
            revert MintingLimitExceeded();
        }
        if (msg.value != dropFee * amount) {
            revert LowSentETH();
        }
        if (dropType == DropType.SEMI && prefixSumsVariations.length > 0 && itemId > prefixSumsVariations.length) {
            revert InvalidItemID();
        }
        if (dropType == DropType.DETERMINED) {
            uriID = itemId;
        } else {
            if (dropType == DropType.NFT) {
                uint256 curHelperLen = helperIdsList.length - mintedItems;
                uriID = uint256(blockhash(block.number)) % curHelperLen;
                uint256 realIDValue = helperIdsList[uriID];
                if (curHelperLen > 1) {
                    helperIdsList[uriID] = helperIdsList[curHelperLen - 1];
                    helperIdsList[curHelperLen - 1] = realIDValue;
                }
                uriID = realIDValue;
            } else {
                // 2 cases, if variations are different per class or if they are equal "variations".
                if (prefixSumsVariations.length > 0) {
                    // Take previous class variations (itemIds are numbered from 1 instead of 0, so substract -1 additionally everywhere).
                    uint256 prevClassVariations = (itemId > 1 ? prefixSumsVariations[itemId - 2] : 0);
                    // Calculate random variation for class itemId.
                    // URI IDs start from prefixSumsVariations[itemId - 2] + 1 until prefixSumsVariations[itemId - 1].
                    // So we need to have a random number in range from [0; prefixSumsVariations[itemId - 1] - prefixSumsVariations[itemId - 2] - 1].
                    uriID = uint256(blockhash(block.number)) % (prefixSumsVariations[itemId - 1] - prevClassVariations);
                    // Add up URI IDs shift for itemId class.
                    uriID += prevClassVariations + 1;
                } else {
                    uriID = uint256(blockhash(block.number)) % variations;
                    uriID += variations * (itemId - 1) + 1;
                }
            }
        }
        if (itemsIDMinted[uriID] + amount > maxItemsPerID) {
            revert MintingLimitExceeded();
        }
        mintedItems += amount;
        itemsIDMinted[uriID] += amount;
        id = controller.requestMint(
            collection,
            dropType == DropType.NFT ? 0 : uriIDItemID[uriID], // If dropType is NFT drop then mint new item, otherwise take mapped URI ID to actual collection item id.
            managingGuardian,
            amount,
            serviceFeePerItem * amount,
            dropType == DropType.NFT ? false : true,
            msg.sender,
            guardianClassIndex,
            guardianFeeAmountPerItem * amount
        );
        // If drop type is not NFT type then map URI ID to collection item id.
        if (dropType != DropType.NFT && uriIDItemID[uriID] == 0) {
            uriIDItemID[uriID] = id;
        }
        controller.mint(collection, id);
        collection.setItemUriID(id, uriID);
        emit MintedDrop(id, uriID, amount, msg.sender);
    }
}