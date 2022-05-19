/**
 *Submitted for verification at polygonscan.com on 2022-05-19
*/

// Dependency file: @openzeppelin/contracts/security/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Context.sol";

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


// Dependency file: @openzeppelin/contracts/utils/Strings.sol

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

// pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// Dependency file: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

// pragma solidity ^0.8.1;

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


// Dependency file: @openzeppelin/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/Strings.sol";

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Root file: contracts/MysteryBoxesUSDT.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";
// import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IVoxelRoleParts {
    function mint(
        address _to,
        uint256 _tokenId,
        uint256 amount,
        bytes memory data
    ) external;
}

contract MysteryBoxesUSDT is Ownable, ReentrancyGuard {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    // polygon 0xc2132D05D31c914a87C6611C10748AEb04B58e8F
    // mumbai 0x114F0D71018D6606C6A68AD0a534F81bf4cf9B58 Custom USDT token
    address public paymentToken = 0x114F0D71018D6606C6A68AD0a534F81bf4cf9B58;

    address public cfoAddress = 0xd2B0660F1B2275512Dec4643B4f2BDd7F8d4d653;

    address public voxelRoleParts = 0xe3C464ec14ceDD3C569434FCce8Cf64E3776dc50;

    // price
    mapping(uint256 => uint256) public priceMap;

    mapping(uint256 => uint256) public priceRareMap;

    // point 1 ~ 10000
    mapping(uint256 => uint256[]) public partConf;

    uint256 public startTimeMysteryBox = 1681529080; // time
    uint256 public startTimeMysteryBoxWhiteFree = 1648113212; // time

    uint256 public inviteDivide = 10; // 100
    uint256 public discountRatio = 90; // 100

    mapping(address => bool) public contractWhiteList; //

    mapping(address => mapping(uint256 => uint256)) public freeWhiteList;

    mapping(address => mapping(uint256 => uint256)) public discountWhiteList;

    mapping(address => mapping(uint256 => uint256)) public epicWhiteList;

    uint256 public maxSupply = ~uint256(0);
    uint256 public totalSupply;

    uint256 public maxSupplyRare = ~uint256(0);
    uint256 public totalSupplyRare;

    uint256 public maxSupplyEpic = ~uint256(0);
    uint256 public totalSupplyEpic;

    // ========= Event =========

    event BuyMysteryBoxEvt(
        address indexed buyer,
        uint256 indexed quantity,
        uint256 paid,
        uint256 lucky
    );

    event BuyMysteryBoxRefEvt(
        address indexed buyer,
        uint256 indexed quantity,
        address indexed ref,
        uint256 paid,
        uint256 lucky
    );

    // ========= Business Logic =========

    function buyMysteryBox(uint256 pointer, uint256 salt) public nonReentrant {
        require(pointer == 1 || pointer == 3 || pointer == 6 || pointer == 9);

        address wallet = _msgSender();

        if (!contractWhiteList[wallet]) {
            require(wallet == tx.origin, "Prohibit contract call");
        }

        require(block.timestamp >= startTimeMysteryBox, "No start");

        require(pointer + totalSupply <= maxSupply, "maxSupply limt");

        uint256 price = priceMap[pointer];

        IERC20(paymentToken).safeTransferFrom(wallet, cfoAddress, price);

        uint256 randomDigit = getRandom4RepeatHash(salt);

        mint(pointer, randomDigit);

        totalSupply += pointer;

        emit BuyMysteryBoxEvt(wallet, pointer, price, randomDigit);
    }

    function buyMysteryBoxWhite(
        uint256 pointer,
        uint256 salt,
        bool isFree
    ) public nonReentrant {
        require(pointer == 1 || pointer == 3 || pointer == 6 || pointer == 9);

        address wallet = _msgSender();

        if (!contractWhiteList[wallet]) {
            require(wallet == tx.origin, "Prohibit contract call");
        }

        require(block.timestamp >= startTimeMysteryBoxWhiteFree, "No start");

        require(pointer + totalSupply <= maxSupply, "maxSupply limt");

        uint256 finalPrice;

        if (isFree) {
            require(freeWhiteList[wallet][pointer] > 0, "Unauthorised");
            unchecked {
                freeWhiteList[wallet][pointer] -= 1;
            }
        } else {
            require(discountWhiteList[wallet][pointer] > 0, "Unauthorised");
            unchecked {
                discountWhiteList[wallet][pointer] -= 1;
            }

            finalPrice = (priceMap[pointer] * 50) / 100;
            IERC20(paymentToken).safeTransferFrom(
                wallet,
                cfoAddress,
                finalPrice
            );
        }

        uint256 randomDigit = getRandom4RepeatHash(salt);

        mint(pointer, randomDigit);

        totalSupply += pointer;

        emit BuyMysteryBoxEvt(wallet, pointer, finalPrice, randomDigit);
    }

    function buyMysteryBoxRef(
        uint256 pointer,
        uint256 salt,
        address ref
    ) public nonReentrant {
        require(pointer == 1 || pointer == 3 || pointer == 6 || pointer == 9);

        address _wallet = _msgSender();

        if (!contractWhiteList[_wallet]) {
            require(_wallet == tx.origin, "Prohibit contract call");
        }

        require(block.timestamp >= startTimeMysteryBox, "No start");

        require(pointer + totalSupply <= maxSupply, "maxSupply limt");

        require(_wallet != ref, "You can't invite yourself");

        uint256 finalPrice = (priceMap[pointer] * discountRatio) / 100;

        uint256 randomDigit = getRandom4RepeatHash(salt);

        mint(pointer, randomDigit);

        uint256 refRebate = (finalPrice * inviteDivide) / 100;

        IERC20(paymentToken).safeTransferFrom(
            _wallet,
            cfoAddress,
            finalPrice - refRebate
        );
        IERC20(paymentToken).safeTransferFrom(_wallet, ref, refRebate);

        totalSupply += pointer;

        emit BuyMysteryBoxRefEvt(
            _wallet,
            pointer,
            ref,
            finalPrice,
            randomDigit
        );
    }

    function buyMysteryBoxRare(uint256 pointer, uint256 salt)
        public
        nonReentrant
    {
        require(pointer == 6 || pointer == 9);

        address wallet = _msgSender();

        if (!contractWhiteList[wallet]) {
            require(wallet == tx.origin, "Prohibit contract call");
        }

        require(block.timestamp >= startTimeMysteryBox, "No start");

        require(pointer + totalSupplyRare <= maxSupplyRare, "maxSupply limt");

        uint256 price = priceRareMap[pointer];

        IERC20(paymentToken).safeTransferFrom(wallet, cfoAddress, price);

        uint256 randomDigit = getRandom4RepeatHash(salt);

        uint256 ranPointer = pointer - 2;

        mint(ranPointer, randomDigit);

        uint256 offset = ranPointer * 16;
        uint256[] memory bodyParts = partConf[10]; // body
        uint256 bodyPartRan = uint256((randomDigit >> offset) % 10000);
        for (uint256 k = 0; k < bodyParts.length; k++) {
            if (bodyPartRan < bodyParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(_msgSender(), 1000 + k, 1, "0x");
                break;
            }
        }

        uint256[] memory pantsParts = partConf[17]; // pants
        uint256 pantsPartRan = uint256((randomDigit >> (offset + 16)) % 10000);
        for (uint256 k = 0; k < pantsParts.length; k++) {
            if (pantsPartRan < pantsParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(
                    _msgSender(),
                    1700 + k,
                    1,
                    "0x"
                );
                break;
            }
        }

        totalSupplyRare += pointer;

        emit BuyMysteryBoxEvt(wallet, pointer, price, randomDigit);
    }

    function buyMysteryBoxRefRare(
        uint256 pointer,
        uint256 salt,
        address ref
    ) public nonReentrant {
        require(pointer == 6 || pointer == 9);

        address _wallet = _msgSender();

        if (!contractWhiteList[_wallet]) {
            require(_wallet == tx.origin, "Prohibit contract call");
        }

        require(block.timestamp >= startTimeMysteryBox, "No start");

        require(pointer + totalSupplyRare <= maxSupplyRare, "maxSupply limt");

        require(_wallet != ref, "You can't invite yourself");

        uint256 finalPrice = (priceRareMap[pointer] * discountRatio) / 100;

        uint256 randomDigit = getRandom4RepeatHash(salt);

        uint256 ranPointer = pointer - 2;

        mint(ranPointer, randomDigit);

        uint256 refRebate = (finalPrice * inviteDivide) / 100;

        IERC20(paymentToken).safeTransferFrom(
            _wallet,
            cfoAddress,
            finalPrice - refRebate
        );
        IERC20(paymentToken).safeTransferFrom(_wallet, ref, refRebate);

        uint256 offset = ranPointer * 16;
        uint256[] memory bodyParts = partConf[10]; // body
        uint256 bodyPartRan = uint256((randomDigit >> offset) % 10000);
        for (uint256 k = 0; k < bodyParts.length; k++) {
            if (bodyPartRan < bodyParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(
                    _msgSender(),
                    1000 + k,
                    1,
                    "0x"
                );
                break;
            }
        }

        uint256[] memory pantsParts = partConf[17]; // pants
        uint256 pantsPartRan = uint256((randomDigit >> (offset + 16)) % 10000);
        for (uint256 k = 0; k < pantsParts.length; k++) {
            if (pantsPartRan < pantsParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(
                    _msgSender(),
                    1700 + k,
                    1,
                    "0x"
                );
                break;
            }
        }

        totalSupplyRare += pointer;

        emit BuyMysteryBoxRefEvt(
            _wallet,
            pointer,
            ref,
            finalPrice,
            randomDigit
        );
    }

    function buyMysteryBoxEpic(uint256 salt) public nonReentrant {
        require(6 + totalSupplyEpic <= maxSupplyEpic, "maxSupply limt");
        totalSupplyEpic += 6;

        address _wallet = _msgSender();

        if (!contractWhiteList[_wallet]) {
            require(_wallet == tx.origin, "Prohibit contract call");
        }

        require(epicWhiteList[_wallet][6] > 0, "Unauthorised");
        unchecked {
            epicWhiteList[_wallet][6] -= 1;
        }

        uint256 randomDigit = getRandom4RepeatHash(salt);

        uint256 offset = 0;
        uint256[] memory bodyParts = partConf[10]; // body
        uint256 bodyPartRan = uint256((randomDigit >> offset) % 10000);
        for (uint256 k = 0; k < bodyParts.length; k++) {
            if (bodyPartRan < bodyParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(
                    _msgSender(),
                    1000 + k,
                    1,
                    "0x"
                );
                break;
            }
        }

        uint256[] memory pantsParts = partConf[17]; // pants
        uint256 pantsPartRan = uint256((randomDigit >> (offset + 16)) % 10000);
        for (uint256 k = 0; k < pantsParts.length; k++) {
            if (pantsPartRan < pantsParts[k]) {
                IVoxelRoleParts(voxelRoleParts).mint(
                    _msgSender(),
                    1700 + k,
                    1,
                    "0x"
                );
                break;
            }
        }

        uint8[9] memory mainIds = [11, 12, 13, 14, 15, 16, 18, 19, 20];

        for (uint256 i = 0; i < 4; i++) {
            uint256 mainIdIndex = uint256((randomDigit >> offset) % (9 - i));

            uint256 mainId = mainIds[mainIdIndex];

            (mainIds[mainIdIndex], mainIds[9 - 1 - i]) = (
                mainIds[9 - 1 - i],
                mainIds[mainIdIndex]
            );

            uint256[] memory subParts = partConf[mainId];

            offset += 8;

            uint256 subPartRan = uint256((randomDigit >> offset) % 10000);

            for (uint256 k = 0; k < subParts.length; k++) {
                if (subPartRan < subParts[k]) {
                    IVoxelRoleParts(voxelRoleParts).mint(
                        _msgSender(),
                        mainId * 100 + k,
                        1,
                        "0x"
                    );
                    break;
                }
            }

            offset += 8;
        }
    }

    function mint(uint256 mintQuantity, uint256 randomDigit) internal {
        uint256 ranOffset = 0;
        for (uint256 i = 0; i < mintQuantity; i++) {
            uint256 mainId = uint256((randomDigit >> ranOffset) % 11) + 10;

            uint256[] memory subParts = partConf[mainId];

            ranOffset += 8;

            uint256 subPartRan = uint256((randomDigit >> ranOffset) % 10000);

            for (uint256 k = 0; k < subParts.length; k++) {
                if (subPartRan < subParts[k]) {
                    IVoxelRoleParts(voxelRoleParts).mint(
                        _msgSender(),
                        mainId * 100 + k,
                        1,
                        "0x"
                    );
                    break;
                }
            }

            ranOffset += 8;
        }
    }

    // Notice: This is an insecure random number implementation scheme
    function getRandom4RepeatHash(uint256 salt) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        keccak256(
                            abi.encodePacked(
                                block.timestamp,
                                block.difficulty,
                                block.coinbase,
                                _msgSender(),
                                salt
                            )
                        )
                    )
                )
            );
    }

    // ========= Administrator Method =========

    function setCfoAddress(address newAddr) public onlyOwner {
        cfoAddress = newAddr;
    }

    function setVoxelRoleParts(address newAddr) public onlyOwner {
        voxelRoleParts = newAddr;
    }

    function setPriceMap(uint256 priceIndex, uint256 price) public onlyOwner {
        priceMap[priceIndex] = price;
    }

    function setPriceRareMap(uint256 priceIndex, uint256 price)
        public
        onlyOwner
    {
        priceRareMap[priceIndex] = price;
    }

    function setStartTimeBlindBox(uint256 t) public onlyOwner {
        startTimeMysteryBox = t;
    }

    function setStartTimeMysteryBoxWhiteFree(uint256 t) public onlyOwner {
        startTimeMysteryBoxWhiteFree = t;
    }

    function setPartConf(uint256 mainId, uint256[] memory conf)
        public
        onlyOwner
    {
        partConf[mainId] = conf;
    }

    function setInviteDivide(uint256 divide) public onlyOwner {
        inviteDivide = divide;
    }

    function setDiscountRatio(uint256 divide) public onlyOwner {
        discountRatio = divide;
    }

    function setMaxSupplyRare(uint256 _maxSupplyRare) public onlyOwner {
        maxSupplyRare = _maxSupplyRare;
    }

    function setDiscountWhiteList(
        address[] memory addrs,
        uint256[] memory boxTypes,
        uint256[] memory nums
    ) public onlyOwner {
        require(addrs.length == boxTypes.length);
        require(nums.length == boxTypes.length);

        for (uint256 i; i < addrs.length; i++) {
            discountWhiteList[addrs[i]][boxTypes[i]] = nums[i];
        }
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setFreeWhiteList(
        address[] memory addrs,
        uint256[] memory boxTypes,
        uint256[] memory nums
    ) public onlyOwner {
        require(addrs.length == boxTypes.length);
        require(nums.length == boxTypes.length);

        for (uint256 i; i < addrs.length; i++) {
            freeWhiteList[addrs[i]][boxTypes[i]] = nums[i];
        }
    }

    function setEpicWhiteList(
        address[] memory addrs,
        uint256[] memory boxTypes,
        uint256[] memory nums
    ) public onlyOwner {
        require(addrs.length == boxTypes.length);
        require(nums.length == boxTypes.length);

        for (uint256 i; i < addrs.length; i++) {
            epicWhiteList[addrs[i]][boxTypes[i]] = nums[i];
        }
    }

    function setContractWhiteList(address addr, bool isHave) public onlyOwner {
        contractWhiteList[addr] = isHave;
    }

    function withdraw(address payable to) public onlyOwner {
        Address.sendValue(to, address(this).balance);
    }

    // ========= constructor =========

    constructor() {
        // default
        priceMap[1] = 1e15;
        priceMap[3] = 2e15;
        priceMap[6] = 3e15;
        priceMap[9] = 4e15;

        priceRareMap[6] = 5e15;
        priceRareMap[9] = 6e15;

        // body
        partConf[10] = [6000, 8400, 9360, 9744, 9898, 9959, 10000];

        partConf[11] = [
            1200,
            2400,
            3600,
            4600,
            5600,
            6600,
            7400,
            8200,
            9000,
            9500,
            9800,
            10000
        ];

        partConf[12] = [
            1400,
            2800,
            4000,
            5200,
            6200,
            7200,
            8000,
            8800,
            9600,
            10000
        ];

        partConf[13] = [
            1200,
            2400,
            3600,
            4600,
            5600,
            6600,
            7400,
            8200,
            9000,
            9500,
            10000
        ];

        partConf[14] = [
            600,
            1200,
            1800,
            2400,
            2900,
            3400,
            3900,
            4400,
            4800,
            5200,
            5600,
            6000,
            6400,
            6700,
            7000,
            7300,
            7600,
            7900,
            8200,
            8500,
            8700,
            8900,
            9100,
            9300,
            9500,
            9600,
            9700,
            9800,
            9900,
            10000
        ];

        partConf[15] = [
            1400,
            2800,
            4200,
            5200,
            6200,
            7200,
            8000,
            8800,
            9600,
            10000
        ];

        partConf[16] = [
            800,
            1600,
            2400,
            3200,
            3800,
            4400,
            5000,
            5600,
            6100,
            6600,
            7100,
            7600,
            8000,
            8400,
            8800,
            9200,
            9400,
            9600,
            9800,
            10000
        ];

        partConf[17] = [
            800,
            1600,
            2400,
            3200,
            3800,
            4400,
            5000,
            5600,
            6100,
            6600,
            7100,
            7600,
            8000,
            8400,
            8800,
            9200,
            9400,
            9600,
            9800,
            10000
        ];

        partConf[18] = [
            800,
            1600,
            2400,
            3200,
            3800,
            4400,
            5000,
            5600,
            6100,
            6600,
            7100,
            7600,
            8000,
            8400,
            8800,
            9200,
            9400,
            9600,
            9800,
            10000
        ];

        partConf[19] = [
            1200,
            2400,
            3600,
            4600,
            5600,
            6600,
            7400,
            8200,
            9000,
            9500,
            10000
        ];

        partConf[20] = [
            800,
            1600,
            2400,
            3200,
            3800,
            4400,
            5000,
            5600,
            6100,
            6600,
            7100,
            7600,
            8000,
            8400,
            8800,
            9200,
            9400,
            9600,
            9800,
            10000
        ];
    }
}