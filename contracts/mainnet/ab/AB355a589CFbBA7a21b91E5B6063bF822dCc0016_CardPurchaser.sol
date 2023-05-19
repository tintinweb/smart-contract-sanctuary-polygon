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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "./interfaces/IUSDC.sol";
import "./interfaces/IPublicLock.sol";
import "./interfaces/IUnlock.sol";

/// @custom:security-contact [email protected]
contract CardPurchaser is Ownable, EIP712 {
  error WITHDRAW_FAILED();
  error MISSING_LOCK();
  error LOCK_CALL_FAILED();
  error TOO_MUCH_SPENT();
  error TOO_LATE();
  error PURCHASER_DOES_NOT_MATCH_PAYER();
  error SIGNER_DOES_NOT_MATCH();

  // Unlock address on current chain
  address public unlockAddress;

  // Address of USDC contract
  address public usdc;

  // Name of contract (OZ's EIP712 does not expose it)
  string public name;

  // VErsion of contract (OZ's EIP712 does not expose it)
  string public version;

  struct ApprovalMessage {
    address from;
    address to;
    uint256 value;
    uint256 validAfter;
    uint256 validBefore;
    bytes32 nonce;
  }

  struct PurchaseMessage {
    address lock;
    address sender;
    uint256 expiration;
  }

  /**
   * Constructor
   * We double the `name` and `version` fields from EIP712 so we can query the contract to get them and OZ's Ownable does not expose them
   */
  constructor(
    address _owner,
    address _unlockAddress,
    address _usdc
  ) EIP712("Card Purchaser", "1") Ownable() {
    name = "Card Purchaser";
    version = "1";
    unlockAddress = _unlockAddress;
    usdc = _usdc;
    transferOwnership(_owner);
  }

  /**
   * The function that withdraws the USDC tokens from the user,
   * and then uses them to perform a purchase
   */
  function purchase(
    ApprovalMessage memory approvalMessage,
    bytes memory approvalSignature,
    PurchaseMessage memory purchaseMessage,
    bytes memory purchaseSignature,
    bytes memory callData
  ) public returns (bytes memory) {
    // This works only for locks
    (bool lockExists, , ) = IUnlock(unlockAddress).locks(purchaseMessage.lock);
    if (!lockExists) {
      revert MISSING_LOCK();
    }

    // Check the purchase is not expired
    if (purchaseMessage.expiration < block.timestamp) {
      revert TOO_LATE();
    }

    // Check the purchaseMessage.sender is approvalMessage.from (purchaser is the spender)
    if (purchaseMessage.sender != approvalMessage.from) {
      revert PURCHASER_DOES_NOT_MATCH_PAYER();
    }

    // Check the signature on the purchase matches its sender
    bytes32 structHash = keccak256(
      abi.encode(
        keccak256("Purchase(address lock,address sender,uint256 expiration)"),
        purchaseMessage.lock,
        purchaseMessage.sender,
        purchaseMessage.expiration
      )
    );
    bytes32 hash = _hashTypedDataV4(structHash);
    address recovered = ECDSA.recover(hash, purchaseSignature);
    if (recovered != approvalMessage.from) {
      revert SIGNER_DOES_NOT_MATCH();
    }

    // Get the balance to make sure no extra token are spent!
    uint balanceBefore = IUSDC(usdc).balanceOf(address(this));

    // Get the tokens from the user
    transferTokens(approvalMessage, approvalSignature);

    // Approve the lock to spend all of the USDC (but it should spend less!)
    IUSDC(usdc).approve(purchaseMessage.lock, approvalMessage.value);

    // Finally: call the lock
    (bool lockCallSuccess, bytes memory returnData) = purchaseMessage.lock.call{
      value: 0
    }(callData);

    // Reset approval
    IUSDC(usdc).approve(purchaseMessage.lock, 0);

    // Bubble up any error
    if (lockCallSuccess == false) {
      // If there is return data, the call reverted without a reason or a custom error.
      if (returnData.length == 0) revert();
      assembly {
        // We use Yul's revert() to bubble up errors from the target contract.
        revert(add(32, returnData), mload(returnData))
      }
    }

    // Check that balance only increased!
    uint balanceAfter = IUSDC(usdc).balanceOf(address(this));
    if (balanceAfter < balanceBefore) {
      revert TOO_MUCH_SPENT();
    }

    return returnData;
  }

  /**
   * This is used to send remaining tokens back to the owner (collecting fees!)
   * @param tokenAddress the ERC20 contract address of the token to withdraw
   * or address(0) for native tokens (it should mostly be USDC, but could be anything else, just in case)
   * @param recipient the address that will receive the tokens
   * @param amount the amount of tokens to transfer
   */
  function withdraw(
    address tokenAddress,
    address recipient,
    uint amount
  ) public onlyOwner {
    if (tokenAddress != address(0)) {
      IUSDC(tokenAddress).transfer(recipient, amount);
    } else {
      (bool sent, ) = payable(recipient).call{value: amount}("");
      if (sent == false) {
        revert WITHDRAW_FAILED();
      }
    }
  }

  // Helper
  function splitSignature(
    bytes memory sig
  ) private pure returns (bytes32 r, bytes32 s, uint8 v) {
    require(sig.length == 65, "invalid signature length");

    assembly {
      /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

      // first 32 bytes, after the length prefix
      r := mload(add(sig, 32))
      // second 32 bytes
      s := mload(add(sig, 64))
      // final byte (first byte of the next 32 bytes)
      v := byte(0, mload(add(sig, 96)))
    }

    // implicitly return (r, s, v)
  }

  // Helper
  function transferTokens(
    ApprovalMessage memory approvalMessage,
    bytes memory approvalSignature
  ) private {
    (bytes32 ra, bytes32 sa, uint8 va) = splitSignature(approvalSignature);
    IUSDC(usdc).transferWithAuthorization(
      approvalMessage.from,
      address(this), // We explicitly don't use approvalMessage.to, just in case it was compromised!
      approvalMessage.value,
      approvalMessage.validAfter,
      approvalMessage.validBefore,
      approvalMessage.nonce,
      va,
      ra,
      sa
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
pragma experimental ABIEncoderV2;

/**
 * @title The PublicLock Interface
 */

interface IPublicLock {
  /// Functions
  function initialize(
    address _lockCreator,
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName
  ) external;

  // default role from OpenZeppelin
  function DEFAULT_ADMIN_ROLE()
    external
    view
    returns (bytes32 role);

  /**
   * @notice The version number of the current implementation on this network.
   * @return The current version number.
   */
  function publicLockVersion()
    external
    pure
    returns (uint16);

  /**
   * @dev Called by lock manager to withdraw all funds from the lock
   * @param _tokenAddress specifies the token address to withdraw or 0 for ETH. This is usually
   * the same as `tokenAddress` in MixinFunds.
   * @param _recipient specifies the address that will receive the tokens
   * @param _amount specifies the max amount to withdraw, which may be reduced when
   * considering the available balance. Set to 0 or MAX_UINT to withdraw everything.
   * -- however be wary of draining funds as it breaks the `cancelAndRefund` and `expireAndRefundFor` use cases.
   */
  function withdraw(
    address _tokenAddress,
    address payable _recipient,
    uint _amount
  ) external;

  /**
   * A function which lets a Lock manager of the lock to change the price for future purchases.
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if lock has been disabled
   * @dev Throws if _tokenAddress is not a valid token
   * @param _keyPrice The new price to set for keys
   * @param _tokenAddress The address of the erc20 token to use for pricing the keys,
   * or 0 to use ETH
   */
  function updateKeyPricing(
    uint _keyPrice,
    address _tokenAddress
  ) external;

  /**
   * Update the main key properties for the entire lock:
   *
   * - default duration of each key
   * - the maximum number of keys the lock can edit
   * - the maximum number of keys a single address can hold
   *
   * @notice keys previously bought are unaffected by this changes in expiration duration (i.e.
   * existing keys timestamps are not recalculated/updated)
   * @param _newExpirationDuration the new amount of time for each key purchased or type(uint).max for a non-expiring key
   * @param _maxKeysPerAcccount the maximum amount of key a single user can own
   * @param _maxNumberOfKeys uint the maximum number of keys
   * @dev _maxNumberOfKeys Can't be smaller than the existing supply
   */
  function updateLockConfig(
    uint _newExpirationDuration,
    uint _maxNumberOfKeys,
    uint _maxKeysPerAcccount
  ) external;

  /**
   * Checks if the user has a non-expired key.
   * @param _user The address of the key owner
   */
  function getHasValidKey(
    address _user
  ) external view returns (bool);

  /**
   * @dev Returns the key's ExpirationTimestamp field for a given owner.
   * @param _tokenId the id of the key
   * @dev Returns 0 if the owner has never owned a key for this lock
   */
  function keyExpirationTimestampFor(
    uint _tokenId
  ) external view returns (uint timestamp);

  /**
   * Public function which returns the total number of unique owners (both expired
   * and valid).  This may be larger than totalSupply.
   */
  function numberOfOwners() external view returns (uint);

  /**
   * Allows the Lock owner to assign
   * @param _lockName a descriptive name for this Lock.
   * @param _lockSymbol a Symbol for this Lock (default to KEY).
   * @param _baseTokenURI the baseTokenURI for this Lock
   */
  function setLockMetadata(
    string calldata _lockName,
    string calldata _lockSymbol,
    string calldata _baseTokenURI
  ) external;

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string memory);

  /**  @notice A distinct Uniform Resource Identifier (URI) for a given asset.
   * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
   *  3986. The URI may point to a JSON file that conforms to the "ERC721
   *  Metadata JSON Schema".
   * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
   * @param _tokenId The tokenID we're inquiring about
   * @return String representing the URI for the requested token
   */
  function tokenURI(
    uint256 _tokenId
  ) external view returns (string memory);

  /**
   * Allows a Lock manager to add or remove an event hook
   * @param _onKeyPurchaseHook Hook called when the `purchase` function is called
   * @param _onKeyCancelHook Hook called when the internal `_cancelAndRefund` function is called
   * @param _onValidKeyHook Hook called to determine if the contract should overide the status for a given address
   * @param _onTokenURIHook Hook called to generate a data URI used for NFT metadata
   * @param _onKeyTransferHook Hook called when a key is transfered
   * @param _onKeyExtendHook Hook called when a key is extended or renewed
   * @param _onKeyGrantHook Hook called when a key is granted
   */
  function setEventHooks(
    address _onKeyPurchaseHook,
    address _onKeyCancelHook,
    address _onValidKeyHook,
    address _onTokenURIHook,
    address _onKeyTransferHook,
    address _onKeyExtendHook,
    address _onKeyGrantHook
  ) external;

  /**
   * Allows a Lock manager to give a collection of users a key with no charge.
   * Each key may be assigned a different expiration date.
   * @dev Throws if called by other than a Lock manager
   * @param _recipients An array of receiving addresses
   * @param _expirationTimestamps An array of expiration Timestamps for the keys being granted
   * @return the ids of the granted tokens
   */
  function grantKeys(
    address[] calldata _recipients,
    uint[] calldata _expirationTimestamps,
    address[] calldata _keyManagers
  ) external returns (uint256[] memory);

  /**
   * Allows the Lock owner to extend an existing keys with no charge.
   * @param _tokenId The id of the token to extend
   * @param _duration The duration in secondes to add ot the key
   * @dev set `_duration` to 0 to use the default duration of the lock
   */
  function grantKeyExtension(
    uint _tokenId,
    uint _duration
  ) external;

  /**
   * @dev Purchase function
   * @param _values array of tokens amount to pay for this purchase >= the current keyPrice - any applicable discount
   * (_values is ignored when using ETH)
   * @param _recipients array of addresses of the recipients of the purchased key
   * @param _referrers array of addresses of the users making the referral
   * @param _keyManagers optional array of addresses to grant managing rights to a specific address on creation
   * @param _data array of arbitrary data populated by the front-end which initiated the sale
   * @notice when called for an existing and non-expired key, the `_keyManager` param will be ignored
   * @dev Setting _value to keyPrice exactly doubles as a security feature. That way if the lock owner increases the
   * price while my transaction is pending I can't be charged more than I expected (only applicable to ERC-20 when more
   * than keyPrice is approved for spending).
   * @return tokenIds the ids of the created tokens
   */
  function purchase(
    uint256[] calldata _values,
    address[] calldata _recipients,
    address[] calldata _referrers,
    address[] calldata _keyManagers,
    bytes[] calldata _data
  ) external payable returns (uint256[] memory tokenIds);

  /**
   * @dev Extend function
   * @param _value the number of tokens to pay for this purchase >= the current keyPrice - any applicable discount
   * (_value is ignored when using ETH)
   * @param _tokenId the id of the key to extend
   * @param _referrer address of the user making the referral
   * @param _data arbitrary data populated by the front-end which initiated the sale
   * @dev Throws if lock is disabled or key does not exist for _recipient. Throws if _recipient == address(0).
   */
  function extend(
    uint _value,
    uint _tokenId,
    address _referrer,
    bytes calldata _data
  ) external payable;

  /**
   * Returns the percentage of the keyPrice to be sent to the referrer (in basis points)
   * @param _referrer the address of the referrer
   * @return referrerFee the percentage of the keyPrice to be sent to the referrer (in basis points)
   */
  function referrerFees(
    address _referrer
  ) external view returns (uint referrerFee);

  /**
   * Set a specific percentage of the keyPrice to be sent to the referrer while purchasing,
   * extending or renewing a key.
   * @param _referrer the address of the referrer
   * @param _feeBasisPoint the percentage of the price to be used for this
   * specific referrer (in basis points)
   * @dev To send a fixed percentage of the key price to all referrers, sett a percentage to `address(0)`
   */
  function setReferrerFee(
    address _referrer,
    uint _feeBasisPoint
  ) external;

  /**
   * Merge existing keys
   * @param _tokenIdFrom the id of the token to substract time from
   * @param _tokenIdTo the id of the destination token  to add time
   * @param _amount the amount of time to transfer (in seconds)
   */
  function mergeKeys(
    uint _tokenIdFrom,
    uint _tokenIdTo,
    uint _amount
  ) external;

  /**
   * Deactivate an existing key
   * @param _tokenId the id of token to burn
   * @notice the key will be expired and ownership records will be destroyed
   */
  function burn(uint _tokenId) external;

  /**
   * @param _gasRefundValue price in wei or token in smallest price unit
   * @dev Set the value to be refunded to the sender on purchase
   */
  function setGasRefundValue(
    uint256 _gasRefundValue
  ) external;

  /**
   * _gasRefundValue price in wei or token in smallest price unit
   * @dev Returns the value/price to be refunded to the sender on purchase
   */
  function gasRefundValue()
    external
    view
    returns (uint256 _gasRefundValue);

  /**
   * @notice returns the minimum price paid for a purchase with these params.
   * @dev this considers any discount from Unlock or the OnKeyPurchase hook.
   */
  function purchasePriceFor(
    address _recipient,
    address _referrer,
    bytes calldata _data
  ) external view returns (uint);

  /**
   * Allow a Lock manager to change the transfer fee.
   * @dev Throws if called by other than a Lock manager
   * @param _transferFeeBasisPoints The new transfer fee in basis-points(bps).
   * Ex: 200 bps = 2%
   */
  function updateTransferFee(
    uint _transferFeeBasisPoints
  ) external;

  /**
   * Determines how much of a fee would need to be paid in order to
   * transfer to another account.  This is pro-rated so the fee goes
   * down overtime.
   * @dev Throws if _tokenId does not have a valid key
   * @param _tokenId The id of the key check the transfer fee for.
   * @param _time The amount of time to calculate the fee for.
   * @return The transfer fee in seconds.
   */
  function getTransferFee(
    uint _tokenId,
    uint _time
  ) external view returns (uint);

  /**
   * @dev Invoked by a Lock manager to expire the user's key
   * and perform a refund and cancellation of the key
   * @param _tokenId The key id we wish to refund to
   * @param _amount The amount to refund to the key-owner
   * @dev Throws if called by other than a Lock manager
   * @dev Throws if _keyOwner does not have a valid key
   */
  function expireAndRefundFor(
    uint _tokenId,
    uint _amount
  ) external;

  /**
   * @dev allows the key manager to expire a given tokenId
   * and send a refund to the keyOwner based on the amount of time remaining.
   * @param _tokenId The id of the key to cancel.
   * @notice cancel is enabled with a 10% penalty by default on all Locks.
   */
  function cancelAndRefund(uint _tokenId) external;

  /**
   * Allow a Lock manager to change the refund penalty.
   * @dev Throws if called by other than a Lock manager
   * @param _freeTrialLength The new duration of free trials for this lock
   * @param _refundPenaltyBasisPoints The new refund penaly in basis-points(bps)
   */
  function updateRefundPenalty(
    uint _freeTrialLength,
    uint _refundPenaltyBasisPoints
  ) external;

  /**
   * @dev Determines how much of a refund a key owner would receive if they issued
   * @param _tokenId the id of the token to get the refund value for.
   * @notice Due to the time required to mine a tx, the actual refund amount will be lower
   * than what the user reads from this call.
   * @return refund the amount of tokens refunded
   */
  function getCancelAndRefundValue(
    uint _tokenId
  ) external view returns (uint refund);

  function addLockManager(address account) external;

  function isLockManager(
    address account
  ) external view returns (bool);

  /**
   * Returns the address of the `onKeyPurchaseHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyPurchaseHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onKeyCancelHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyCancelHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onValidKeyHook` hook.
   * @return hookAddress address of the hook
   */
  function onValidKeyHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onTokenURIHook` hook.
   * @return hookAddress address of the hook
   */
  function onTokenURIHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onKeyTransferHook` hook.
   * @return hookAddress address of the hook
   */
  function onKeyTransferHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onKeyExtendHook` hook.
   * @return hookAddress the address ok the hook
   */
  function onKeyExtendHook()
    external
    view
    returns (address hookAddress);

  /**
   * Returns the address of the `onKeyGrantHook` hook.
   * @return hookAddress the address ok the hook
   */
  function onKeyGrantHook()
    external
    view
    returns (address hookAddress);

  function renounceLockManager() external;

  /**
   * @return the maximum number of key allowed for a single address
   */
  function maxKeysPerAddress() external view returns (uint);

  function expirationDuration()
    external
    view
    returns (uint256);

  function freeTrialLength()
    external
    view
    returns (uint256);

  function keyPrice() external view returns (uint256);

  function maxNumberOfKeys()
    external
    view
    returns (uint256);

  function refundPenaltyBasisPoints()
    external
    view
    returns (uint256);

  function tokenAddress() external view returns (address);

  function transferFeeBasisPoints()
    external
    view
    returns (uint256);

  function unlockProtocol() external view returns (address);

  function keyManagerOf(
    uint
  ) external view returns (address);

  ///===================================================================

  /**
   * @notice Allows the key owner to safely share their key (parent key) by
   * transferring a portion of the remaining time to a new key (child key).
   * @dev Throws if key is not valid.
   * @dev Throws if `_to` is the zero address
   * @param _to The recipient of the shared key
   * @param _tokenId the key to share
   * @param _timeShared The amount of time shared
   * checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256('onERC721Received(address,address,uint,bytes)'))`.
   * @dev Emit Transfer event
   */
  function shareKey(
    address _to,
    uint _tokenId,
    uint _timeShared
  ) external;

  /**
   * @notice Update transfer and cancel rights for a given key
   * @param _tokenId The id of the key to assign rights for
   * @param _keyManager The address to assign the rights to for the given key
   */
  function setKeyManagerOf(
    uint _tokenId,
    address _keyManager
  ) external;

  /**
   * Check if a certain key is valid
   * @param _tokenId the id of the key to check validity
   * @notice this makes use of the onValidKeyHook if it is set
   */
  function isValidKey(
    uint _tokenId
  ) external view returns (bool);

  /**
   * Returns the number of keys owned by `_keyOwner` (expired or not)
   * @param _keyOwner address for which we are retrieving the total number of keys
   * @return numberOfKeys total number of keys owned by the address
   */
  function totalKeys(
    address _keyOwner
  ) external view returns (uint numberOfKeys);

  /// @notice A descriptive name for a collection of NFTs in this contract
  function name()
    external
    view
    returns (string memory _name);

  ///===================================================================

  /// From ERC165.sol
  function supportsInterface(
    bytes4 interfaceId
  ) external view returns (bool);

  ///===================================================================

  /// From ERC-721
  /**
   * In the specific case of a Lock, `balanceOf` returns only the tokens with a valid expiration timerange
   * @return balance The number of valid keys owned by `_keyOwner`
   */
  function balanceOf(
    address _owner
  ) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the NFT specified by `tokenId`.
   */
  function ownerOf(
    uint256 tokenId
  ) external view returns (address _owner);

  /**
   * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
   * another (`to`).
   *
   * Requirements:
   * - `from`, `to` cannot be zero.
   * - `tokenId` must be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this
   * NFT by either {approve} or {setApprovalForAll}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * an ERC721-like function to transfer a token from one account to another.
   * @param from the owner of token to transfer
   * @param to the address that will receive the token
   * @param tokenId the id of the token
   * @dev Requirements: if the caller is not `from`, it must be approved to move this token by
   * either {approve} or {setApprovalForAll}.
   * The key manager will be reset to address zero after the transfer
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * Lending a key allows you to transfer the token while retaining the
   * ownerships right by setting yourself as a key manager first.
   * @param from the owner of token to transfer
   * @param to the address that will receive the token
   * @param tokenId the id of the token
   * @notice This function can only be called by 1) the key owner when no key manager is set or 2) the key manager.
   * After calling the function, the `_recipent` will be the new owner, and the sender of the tx
   * will become the key manager.
   */
  function lendKey(
    address from,
    address to,
    uint tokenId
  ) external;

  /**
   * Unlend is called when you have lent a key and want to claim its full ownership back.
   * @param _recipient the address that will receive the token ownership
   * @param _tokenId the id of the token
   * @dev Only the key manager of the token can call this function
   */
  function unlendKey(
    address _recipient,
    uint _tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  /**
   * @notice Get the approved address for a single NFT
   * @dev Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for
   * @return operator The approved address for this NFT, or the zero address if there is none
   */
  function getApproved(
    uint256 _tokenId
  ) external view returns (address operator);

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _operator operator address to set the approval
   * @param _approved representing the status of the approval to be set
   * @notice disabled when transfers are disabled
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  ) external;

  /**
   * @dev Tells whether an operator is approved by a given keyManager
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  ) external view returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  /**
   * Returns the total number of keys, including non-valid ones
   * @return _totalKeysCreated the total number of keys, valid or not
   */
  function totalSupply() external view returns (uint256 _totalKeysCreated);

  function tokenOfOwnerByIndex(
    address _owner,
    uint256 index
  ) external view returns (uint256 tokenId);

  function tokenByIndex(
    uint256 index
  ) external view returns (uint256);

  /**
   * Innherited from Open Zeppelin AccessControl.sol
   */
  function getRoleAdmin(
    bytes32 role
  ) external view returns (bytes32);

  function grantRole(
    bytes32 role,
    address account
  ) external;

  function revokeRole(
    bytes32 role,
    address account
  ) external;

  function renounceRole(
    bytes32 role,
    address account
  ) external;

  function hasRole(
    bytes32 role,
    address account
  ) external view returns (bool);

  /** `owner()` is provided as an helper to mimick the `Ownable` contract ABI.
   * The `Ownable` logic is used by many 3rd party services to determine
   * contract ownership - e.g. who is allowed to edit metadata on Opensea.
   *
   * @notice This logic is NOT used internally by the Unlock Protocol and is made
   * available only as a convenience helper.
   */
  function owner() external view returns (address owner);

  function setOwner(address account) external;

  function isOwner(
    address account
  ) external view returns (bool isOwner);

  /**
   * Migrate data from the previous single owner => key mapping to
   * the new data structure w multiple tokens.
   * @param _calldata an ABI-encoded representation of the params (v10: the number of records to migrate as `uint`)
   * @dev when all record schemas are sucessfully upgraded, this function will update the `schemaVersion`
   * variable to the latest/current lock version
   */
  function migrate(bytes calldata _calldata) external;

  /**
   * Returns the version number of the data schema currently used by the lock
   * @notice if this is different from `publicLockVersion`, then the ability to purchase, grant
   * or extend keys is disabled.
   * @dev will return 0 if no ;igration has ever been run
   */
  function schemaVersion() external view returns (uint);

  /**
   * Set the schema version to the latest
   * @notice only lock manager call call this
   */
  function updateSchemaVersion() external;

  /**
   * Renew a given token
   * @notice only works for non-free, expiring, ERC20 locks
   * @param _tokenId the ID fo the token to renew
   * @param _referrer the address of the person to be granted UDT
   */
  function renewMembershipFor(
    uint _tokenId,
    address _referrer
  ) external;

  /**
   * @dev helper to check if a key is currently renewable 
   * it will revert if the pricing or duration of the lock have been modified 
   * unfavorably since the key was bought(price increase or duration decrease).
   * It will also revert if a lock is not renewable or if the key is not ready for renewal yet 
   * (at least 90% expired).
   * @param tokenId the id of the token to check
   * @param referrer the address where to send the referrer fee
   * @return true if the terms has changed
   */
  function isRenewable(uint256 tokenId, address referrer) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

/**
 * @title The Unlock Interface
 **/

interface IUnlock {
  // Use initialize instead of a constructor to support proxies(for upgradeability via zos).
  function initialize(address _unlockOwner) external;

  /**
   * @dev deploy a ProxyAdmin contract used to upgrade locks
   */
  function initializeProxyAdmin() external;

  /**
   * Retrieve the contract address of the proxy admin that manages the locks
   * @return _proxyAdminAddress the address of the ProxyAdmin instance
   */
  function proxyAdminAddress()
    external
    view
    returns (address _proxyAdminAddress);

  /**
   * @notice Create lock (legacy)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param _expirationDuration the duration of the lock (pass 0 for unlimited duration)
   * @param _tokenAddress set to the ERC20 token address, or 0 for ETH.
   * @param _keyPrice the price of each key
   * @param _maxNumberOfKeys the maximum nimbers of keys to be edited
   * @param _lockName the name of the lock
   * param _salt [deprec] -- kept only for backwards copatibility
   * This may be implemented as a sequence ID or with RNG. It's used with `create2`
   * to know the lock's address before the transaction is mined.
   * @dev internally call `createUpgradeableLock`
   */
  function createLock(
    uint _expirationDuration,
    address _tokenAddress,
    uint _keyPrice,
    uint _maxNumberOfKeys,
    string calldata _lockName,
    bytes12 // _salt
  ) external returns (address);

  /**
   * @notice Create lock (default)
   * This deploys a lock for a creator. It also keeps track of the deployed lock.
   * @param data bytes containing the call to initialize the lock template
   * @dev this call is passed as encoded function - for instance:
   *  bytes memory data = abi.encodeWithSignature(
   *    'initialize(address,uint256,address,uint256,uint256,string)',
   *    msg.sender,
   *    _expirationDuration,
   *    _tokenAddress,
   *    _keyPrice,
   *    _maxNumberOfKeys,
   *    _lockName
   *  );
   * @return address of the create lock
   */
  function createUpgradeableLock(bytes memory data) external returns (address);

  /**
   * Create an upgradeable lock using a specific PublicLock version
   * @param data bytes containing the call to initialize the lock template
   * (refer to createUpgradeableLock for more details)
   * @param _lockVersion the version of the lock to use
   */
  function createUpgradeableLockAtVersion(
    bytes memory data,
    uint16 _lockVersion
  ) external returns (address);

  /**
   * @notice Upgrade a lock to a specific version
   * @dev only available for publicLockVersion > 10 (proxyAdmin /required)
   * @param lockAddress the existing lock address
   * @param version the version number you are targeting
   * Likely implemented with OpenZeppelin TransparentProxy contract
   */
  function upgradeLock(
    address payable lockAddress,
    uint16 version
  ) external returns (address);

  /**
   * This function keeps track of the added GDP, as well as grants of discount tokens
   * to the referrer, if applicable.
   * The number of discount tokens granted is based on the value of the referal,
   * the current growth rate and the lock's discount token distribution rate
   * This function is invoked by a previously deployed lock only.
   */
  function recordKeyPurchase(
    uint _value,
    address _referrer // solhint-disable-line no-unused-vars
  ) external;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function will keep track of consumed discounts by a given user.
   * It will also grant discount tokens to the creator who is granting the discount based on the
   * amount of discount and compensation rate.
   * This function is invoked by a previously deployed lock only.
   */
  function recordConsumedDiscount(
    uint _discount,
    uint _tokens // solhint-disable-line no-unused-vars
  ) external view;

  /**
   * @notice [DEPRECATED] Call to this function has been removed from PublicLock > v9.
   * @dev [DEPRECATED] Kept for backwards compatibility
   * This function returns the discount available for a user, when purchasing a
   * a key from a lock.
   * This does not modify the state. It returns both the discount and the number of tokens
   * consumed to grant that discount.
   */
  function computeAvailableDiscountFor(
    address _purchaser, // solhint-disable-line no-unused-vars
    uint _keyPrice // solhint-disable-line no-unused-vars
  ) external pure returns (uint discount, uint tokens);

  // Function to read the globalTokenURI field.
  function globalBaseTokenURI() external view returns (string memory);

  /**
   * @dev Redundant with globalBaseTokenURI() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalBaseTokenURI() external view returns (string memory);

  // Function to read the globalTokenSymbol field.
  function globalTokenSymbol() external view returns (string memory);

  // Function to read the chainId field.
  function chainId() external view returns (uint);

  /**
   * @dev Redundant with globalTokenSymbol() for backwards compatibility with v3 & v4 locks.
   */
  function getGlobalTokenSymbol() external view returns (string memory);

  /**
   * @notice Allows the owner to update configuration variables
   */
  function configUnlock(
    address _udt,
    address _weth,
    uint _estimatedGasForPurchase,
    string calldata _symbol,
    string calldata _URI,
    uint _chainId
  ) external;

  /**
   * @notice Add a PublicLock template to be used for future calls to `createLock`.
   * @dev This is used to upgrade conytract per version number
   */
  function addLockTemplate(address impl, uint16 version) external;

  /**
   * Match lock templates addresses with version numbers
   * @param _version the number of the version of the template
   * @return _implAddress address of the lock templates
   */
  function publicLockImpls(
    uint16 _version
  ) external view returns (address _implAddress);

  /**
   * Match version numbers with lock templates addresses
   * @param _impl the address of the deployed template contract (PublicLock)
   * @return number of the version corresponding to this address
   */
  function publicLockVersions(address _impl) external view returns (uint16);

  /**
   * Retrive the latest existing lock template version
   * @return _version the version number of the latest template (used to deploy contracts)
   */
  function publicLockLatestVersion() external view returns (uint16 _version);

  /**
   * @notice Upgrade the PublicLock template used for future calls to `createLock`.
   * @dev This will initialize the template and revokeOwnership.
   */
  function setLockTemplate(address payable _publicLockAddress) external;

  // Allows the owner to change the value tracking variables as needed.
  function resetTrackedValue(
    uint _grossNetworkProduct,
    uint _totalDiscountGranted
  ) external;

  function grossNetworkProduct() external view returns (uint);

  function totalDiscountGranted() external view returns (uint);

  function locks(
    address
  )
    external
    view
    returns (bool deployed, uint totalSales, uint yieldedDiscountTokens);

  // The address of the public lock template, used when `createLock` is called
  function publicLockAddress() external view returns (address);

  // Map token address to exchange contract address if the token is supported
  // Used for GDP calculations
  function uniswapOracles(address) external view returns (address);

  // The WETH token address, used for value calculations
  function weth() external view returns (address);

  // The UDT token address, used to mint tokens on referral
  function udt() external view returns (address);

  // The approx amount of gas required to purchase a key
  function estimatedGasForPurchase() external view returns (uint);

  /**
   * Helper to get the network mining basefee as introduced in EIP-1559
   * @dev this helper can be wrapped in try/catch statement to avoid
   * revert in networks where EIP-1559 is not implemented
   */
  function networkBaseFee() external view returns (uint);

  // The version number of the current Unlock implementation on this network
  function unlockVersion() external pure returns (uint16);

  /**
   * @notice allows the owner to set the oracle address to use for value conversions
   * setting the _oracleAddress to address(0) removes support for the token
   * @dev This will also call update to ensure at least one datapoint has been recorded.
   */
  function setOracle(address _tokenAddress, address _oracleAddress) external;

  // Initialize the Ownable contract, granting contract ownership to the specified sender
  function __initializeOwnable(address sender) external;

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() external view returns (bool);

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() external view returns (address);

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() external;

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external;

  /**
   * Set the fee collected by the protocol
   * @param _protocolFee fee (in basis points)
   */
  function setProtocolFee(uint _protocolFee) external;

  /**
   * The fee (in basis points) collected by the protocol on each purchase / 
   extension / renewal of a key
   * @return the protocol fee in basic point
   */
  function protocolFee() external view returns (uint);

  /**
   * Returns the ProxyAdmin contract address that manage upgrades for
   * the current Unlock contract.
   * @dev this reads the address directly from storage, at the slot `_ADMIN_SLOT`
   * defined by Open Zeppelin's EIP1967 Proxy implementation which corresponds
   * to the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1
   */
  function getAdmin() external view returns (address);

  /**
   * Call executed by a lock after its version upgrade triggred by `upgradeLock`
   * - PublicLock v12 > v13 (mainnet): migrate an existing Lock to another instance
   * of the Unlock contract
   * @dev The `msg.sender` will be the upgraded lock
   */
  function postLockUpgrade() external;

  /**
   * Functions which transfers tokens held by the contract
   * It handles both ERC20 and the base currency.
   * @dev This function is onlyOwner
   * @param token the address of the token to transfer (pass the 0x0 address for the base currency)
   * @param to the address to transfer the tokens to
   * @param amount the amount of tokens to transfer
   */
  function transferTokens(address token, address to, uint256 amount) external;

  /**
   * Removes a lock from the list of locks. This will prevent the lock from being able to receive governance tokens.
   * The lock will still be able to sell its memberships.
   * @dev This function is onlyOwner
   * @param lock address of the lock to remove
   */
  function removeLock(address lock) external;
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IUSDC {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event AuthorizationCanceled(
    address indexed authorizer,
    bytes32 indexed nonce
  );
  event AuthorizationUsed(address indexed authorizer, bytes32 indexed nonce);
  event Blacklisted(address indexed _account);
  event BlacklisterChanged(address indexed newBlacklister);
  event Burn(address indexed burner, uint256 amount);
  event MasterMinterChanged(address indexed newMasterMinter);
  event Mint(address indexed minter, address indexed to, uint256 amount);
  event MinterConfigured(address indexed minter, uint256 minterAllowedAmount);
  event MinterRemoved(address indexed oldMinter);
  event OwnershipTransferred(address previousOwner, address newOwner);
  event Pause();
  event PauserChanged(address indexed newAddress);
  event RescuerChanged(address indexed newRescuer);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event UnBlacklisted(address indexed _account);
  event Unpause();

  function CANCEL_AUTHORIZATION_TYPEHASH() external view returns (bytes32);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external view returns (bytes32);

  function RECEIVE_WITH_AUTHORIZATION_TYPEHASH()
    external
    view
    returns (bytes32);

  function TRANSFER_WITH_AUTHORIZATION_TYPEHASH()
    external
    view
    returns (bytes32);

  function allowance(
    address owner,
    address spender
  ) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function authorizationState(
    address authorizer,
    bytes32 nonce
  ) external view returns (bool);

  function balanceOf(address account) external view returns (uint256);

  function blacklist(address _account) external;

  function blacklister() external view returns (address);

  function burn(uint256 _amount) external;

  function cancelAuthorization(
    address authorizer,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function configureMinter(
    address minter,
    uint256 minterAllowedAmount
  ) external returns (bool);

  function currency() external view returns (string memory);

  function decimals() external view returns (uint8);

  function decreaseAllowance(
    address spender,
    uint256 decrement
  ) external returns (bool);

  function increaseAllowance(
    address spender,
    uint256 increment
  ) external returns (bool);

  function initialize(
    string memory tokenName,
    string memory tokenSymbol,
    string memory tokenCurrency,
    uint8 tokenDecimals,
    address newMasterMinter,
    address newPauser,
    address newBlacklister,
    address newOwner
  ) external;

  function initializeV2(string memory newName) external;

  function initializeV2_1(address lostAndFound) external;

  function isBlacklisted(address _account) external view returns (bool);

  function isMinter(address account) external view returns (bool);

  function masterMinter() external view returns (address);

  function mint(address _to, uint256 _amount) external returns (bool);

  function minterAllowance(address minter) external view returns (uint256);

  function name() external view returns (string memory);

  function nonces(address owner) external view returns (uint256);

  function owner() external view returns (address);

  function pause() external;

  function paused() external view returns (bool);

  function pauser() external view returns (address);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function receiveWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function removeMinter(address minter) external returns (bool);

  function rescueERC20(
    address tokenContract,
    address to,
    uint256 amount
  ) external;

  function rescuer() external view returns (address);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function transferOwne1rship(address newOwner) external;

  function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  function unBlacklist(address _account) external;

  function unpause() external;

  function updateBlacklister(address _newBlacklister) external;

  function updateMasterMinter(address _newMasterMinter) external;

  function updatePauser(address _newPauser) external;

  function updateRescuer(address newRescuer) external;

  function version() external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationCanceled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"authorizer","type":"address"},{"indexed":true,"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"AuthorizationUsed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"Blacklisted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newBlacklister","type":"address"}],"name":"BlacklisterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"burner","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Burn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newMasterMinter","type":"address"}],"name":"MasterMinterChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"MinterConfigured","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"oldMinter","type":"address"}],"name":"MinterRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":false,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[],"name":"Pause","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newAddress","type":"address"}],"name":"PauserChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newRescuer","type":"address"}],"name":"RescuerChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"uint256","name":"value","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_account","type":"address"}],"name":"UnBlacklisted","type":"event"},{"anonymous":false,"inputs":[],"name":"Unpause","type":"event"},{"inputs":[],"name":"CANCEL_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"DOMAIN_SEPARATOR","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"PERMIT_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"RECEIVE_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"TRANSFER_WITH_AUTHORIZATION_TYPEHASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"}],"name":"allowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"approve","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"}],"name":"authorizationState","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"blacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"blacklister","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"burn","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"authorizer","type":"address"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"cancelAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"},{"internalType":"uint256","name":"minterAllowedAmount","type":"uint256"}],"name":"configureMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"currency","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"decimals","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"decrement","type":"uint256"}],"name":"decreaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"increment","type":"uint256"}],"name":"increaseAllowance","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"tokenName","type":"string"},{"internalType":"string","name":"tokenSymbol","type":"string"},{"internalType":"string","name":"tokenCurrency","type":"string"},{"internalType":"uint8","name":"tokenDecimals","type":"uint8"},{"internalType":"address","name":"newMasterMinter","type":"address"},{"internalType":"address","name":"newPauser","type":"address"},{"internalType":"address","name":"newBlacklister","type":"address"},{"internalType":"address","name":"newOwner","type":"address"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"newName","type":"string"}],"name":"initializeV2","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"lostAndFound","type":"address"}],"name":"initializeV2_1","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"isBlacklisted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"masterMinter","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"minterAllowance","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"nonces","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"paused","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pauser","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"deadline","type":"uint256"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"permit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"receiveWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"minter","type":"address"}],"name":"removeMinter","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"contract IERC20","name":"tokenContract","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"rescueERC20","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"rescuer","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transfer","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"transferFrom","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"value","type":"uint256"},{"internalType":"uint256","name":"validAfter","type":"uint256"},{"internalType":"uint256","name":"validBefore","type":"uint256"},{"internalType":"bytes32","name":"nonce","type":"bytes32"},{"internalType":"uint8","name":"v","type":"uint8"},{"internalType":"bytes32","name":"r","type":"bytes32"},{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"transferWithAuthorization","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_account","type":"address"}],"name":"unBlacklist","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newBlacklister","type":"address"}],"name":"updateBlacklister","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newMasterMinter","type":"address"}],"name":"updateMasterMinter","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_newPauser","type":"address"}],"name":"updatePauser","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newRescuer","type":"address"}],"name":"updateRescuer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/