// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        require(l.status != 2, 'ReentrancyGuard: reentrant call');
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@solidstate/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/PortToken/IPortToken.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import "../libraries/LibTrackedToken.sol";
import "../libraries/LibDexInterface.sol";
import "../libraries/LibReferralToken.sol";
import "../libraries/LibEIP712.sol";
import "./FeeFacet.sol"; //TODO refactor to internall call

contract DexInvestorFacet is Modifiers, ReentrancyGuard {
    bytes32 private constant _NAME_HASH = keccak256("DexInvestorFacet");
    bytes32 private constant _VERSION_HASH = keccak256("1");

    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using SafeERC20 for IERC20;

    struct MultipleCallParams {
        address dex;
        address tokenAddress;
        uint256 tokenAmount;
        bytes[] dexCalldata;
    }

    event IssuedUsingDex(address indexed sender, address indexed _portTokenAddr, uint256 amount, address fromAddr, uint256 fromAmount);
    event RedeemedUsingDex(address indexed sender, address indexed _portTokenAddr, uint256 amount, address toAddr, uint256 toAmount);

    // see LibTrackedToken for original definition, needed for ethers.js catch event
    event TrackedTokenBalancesChanged(address indexed portTokenAddress, uint256 portTokenSupply, address[] tokenAddrs, uint256[] amounts);

    modifier onlyAllowedDex(address _dexAddress) {
        require(LibDexInterface.diamondStorage().dexAddressWhitelist.contains(_dexAddress), "Unknown DEX address");
        _;
    }

    /**
     @notice issue port folio token using dex to swap from source token to tracked tokens
     @dev checks: 
        - Dex is whitelisted
        - Amount > 0
        - Tracked tokens > 0 
        - From amount enough for direct transfer
        - Not paused
        - If token is refferal investor should be allowed
     From amount enought for dex operations - not checked explicitly, since fromAmount is used for dex allowance,
     either dex call will fail or received amount won't be enough.

     If investing in refferal token emit IssuedUsingDex as usual for full amount, 
     but also emit ReferralFeeCharged for fee amount
     @param _addr port token address
     @param _amount amout of portfolio token to issue
     @param _call MultipleCallParams structure with parameters for dex calls
    */
    function issueFromDexCalldata(
        address _addr,
        uint256 _amount,
        MultipleCallParams memory _call
    ) external {
        _issueFromDexCalldata(msg.sender, _addr, _amount, _call);
    }

    bytes32 private constant _MULTIPLE_CALL_TYPEHASH =
        keccak256("MultipleCallParams(address dex,address tokenAddress,uint256 tokenAmount,bytes[] dexCalldata)");

    bytes32 private constant _ISSUE_TYPEHASH =
        keccak256(
            "issueFromDexCalldataWithAuthorization(address investor,address addr,uint256 amount,MultipleCallParams call,uint256 validAfter,uint256 validBefore,uint32 nonce)MultipleCallParams(address dex,address tokenAddress,uint256 tokenAmount,bytes[] dexCalldata)"
        );

    bytes32 private constant _REDEEM_TYPEHASH =
        keccak256(
            "redeemToDexCalldataWithAuthorization(address investor,address addr,uint256 amount,MultipleCallParams call,uint256 validAfter,uint256 validBefore,uint32 nonce)MultipleCallParams(address dex,address tokenAddress,uint256 tokenAmount,bytes[] dexCalldata)"
        );

    function _hashMultipleCall(MultipleCallParams calldata call) internal pure returns (bytes32) {
        bytes32[] memory _dexCalldata = new bytes32[](call.dexCalldata.length);
        for (uint256 i = 0; i < _dexCalldata.length; ++i) {
            _dexCalldata[i] = keccak256(call.dexCalldata[i]);
        }

        return
            keccak256(abi.encode(_MULTIPLE_CALL_TYPEHASH, call.dex, call.tokenAddress, call.tokenAmount, keccak256(abi.encodePacked(_dexCalldata))));
    }

    function issueFromDexCalldataWithAuthorization(
        address investor,
        address addr,
        uint256 amount,
        MultipleCallParams calldata call,
        uint256 validAfter,
        uint256 validBefore,
        uint32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        LibEIP712.verifyTimestamps(validAfter, validBefore);

        {
            bytes32 hash = LibEIP712.hashTypedDataV4(
                _NAME_HASH,
                _VERSION_HASH,
                keccak256(abi.encode(_ISSUE_TYPEHASH, investor, addr, amount, _hashMultipleCall(call), validAfter, validBefore, nonce))
            );

            LibEIP712.verifySigner(investor, hash, nonce, v, r, s);
        }

        _issueFromDexCalldata(investor, addr, amount, call);
    }

    function _issueFromDexCalldata(
        address msgSender,
        address _addr,
        uint256 _amount,
        MultipleCallParams memory _call
    ) internal onlyAllowedDex(_call.dex) whenNotPaused nonReentrant {
        require(_amount > 0, "Zero issue amount provided");

        require(!LibReferralToken.isReferralToken(_addr) || LibReferralToken.isAllowedInvestor(_addr, msgSender), "Investor not alowed");

        //mint pending fees before issue so fees wont affect amount calculations
        FeeFacet(address(this)).accumulateAndMintFees(_addr);


        //get tracked token info
        LibTrackedToken.TrackedTokensList memory tl = LibTrackedToken.getActualAmount(_addr, _amount);
        require(tl.length > 0, "Must track tokens to issue");

        //get source token
        IERC20 fromToken = IERC20(_call.tokenAddress);
        fromToken.safeTransferFrom(msgSender, address(this), _call.tokenAmount);

        // calculate required tracked token balances
        uint256 dirrectlyTransfered = 0;
        uint256[] memory requiredBalances = new uint256[](tl.length);
        for (uint256 i = 0; i < tl.length; i++) {
            requiredBalances[i] = IERC20(tl.tokens[i]).balanceOf(_addr) + tl.amounts[i];

            // direct transfer if from token is tracked
            if (tl.tokens[i] == _call.tokenAddress) {
                require(_call.tokenAmount >= tl.amounts[i], "Not enough for direct transfer");
                fromToken.safeTransfer(_addr, tl.amounts[i]);
                dirrectlyTransfered = tl.amounts[i];
            }
        }

        //this from balance doesn't account for dirrect transfer if it happened!
        uint256 fromBalance = fromToken.balanceOf(address(this));
        fromToken.safeApprove(_call.dex, _call.tokenAmount - dirrectlyTransfered);
        // use provided calldata to execute swaps
        for (uint256 i = 0; i < _call.dexCalldata.length; i++) {
            _call.dex.functionCall(_call.dexCalldata[i], "DEX call failed");
        }

        // final balance checks
        for (uint256 i = 0; i < tl.length; i++) {
            uint256 newBalance = IERC20(tl.tokens[i]).balanceOf(_addr);
            require(newBalance >= requiredBalances[i], "Not enough received by portfolio");
            //TODO do something with skims
            //skims[i] = newBalance-requiredBalances[i];
        }

        // return from token leftovers if any
        uint256 fromLeftover = _call.tokenAmount + fromToken.balanceOf(address(this)) - fromBalance - dirrectlyTransfered;
        if (fromLeftover > 0) {
            fromToken.safeTransfer(msgSender, fromLeftover);
        }

        uint256 fromAmount = _call.tokenAmount - fromLeftover;

        emit IssuedUsingDex(msgSender, _addr, _amount, _call.tokenAddress, fromAmount);

        if (LibReferralToken.isReferralToken(_addr) && LibReferralToken.getFeeValue(_addr) > 0) {
            uint256 _feeAmount;
            (_amount, _feeAmount) = LibReferralToken.splitAmount(_addr, _amount);

            address feeDistributor = LibReferralToken.getFeeDistributor(_addr);
            IPortToken(_addr).controllerMint(feeDistributor, _feeAmount);
            emit LibReferralToken.ReferralFeeCharged(_addr, msgSender, feeDistributor, _feeAmount);
        }

        // finally mint port token
        IPortToken(_addr).controllerMint(msgSender, _amount);

        fromToken.safeApprove(_call.dex, 0);
        LibTrackedToken.emitTrackedTokenBalancesChanged(_addr);
    }

    /**
     @notice redeem port folio token using dex to swap from tracked tokens to tracked tokens to requested token
     @dev checks: 
        - Dex is whitelisted
        - Amount > 0 and user balance of port token is enought
        - Tracked tokens > 0 
        - User receives at least MultipleCallParams.tokenAmount of MultipleCallParams.tokenAddress
        - Not paused
        No explicit check for spent amount becase dex won't be able to spend
        more that actual amount of tracked token for _amount of port token,
        since aprovals are based on _amount.
     @param _addr port token address
     @param _amount amout of portfolio token to redeem
     @param _call MultipleCallParams structure with parameters for dex calls
    */
    function redeemToDexCalldata(
        address _addr,
        uint256 _amount,
        MultipleCallParams memory _call
    ) external {
        _redeemToDexCalldata(msg.sender, _addr, _amount, _call);
    }

    function redeemToDexCalldataWithAuthorization(
        address investor,
        address addr,
        uint256 amount,
        MultipleCallParams calldata call,
        uint256 validAfter,
        uint256 validBefore,
        uint32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        LibEIP712.verifyTimestamps(validAfter, validBefore);

        {
            bytes32 hash = LibEIP712.hashTypedDataV4(
                _NAME_HASH,
                _VERSION_HASH,
                keccak256(abi.encode(_REDEEM_TYPEHASH, investor, addr, amount, _hashMultipleCall(call), validAfter, validBefore, nonce))
            );

            LibEIP712.verifySigner(investor, hash, nonce, v, r, s);
        }

        _redeemToDexCalldata(investor, addr, amount, call);
    }

    function _redeemToDexCalldata(
        address msgSender,
        address _addr,
        uint256 _amount,
        MultipleCallParams memory _call
    ) internal onlyAllowedDex(_call.dex) whenNotPaused nonReentrant {
        require(_amount > 0, "Zero redeem amount provided");

        IPortToken portToken = IPortToken(_addr);
        require(portToken.balanceOf(msgSender) >= _amount, "Redeem amount exceeds balance");

        //mint pending fees before withdrawal so fees will be included in amount calculations
        FeeFacet(address(this)).accumulateAndMintFees(_addr);

        //get tracked token info
        LibTrackedToken.TrackedTokensList memory tl = LibTrackedToken.getActualAmount(_addr, _amount);
        require(tl.length > 0, "Must track tokens to redeem");

        uint256 oldUserBalance = IERC20(_call.tokenAddress).balanceOf(msgSender);

        for (uint256 i = 0; i < tl.length; i++) {
            require(IERC20(tl.tokens[i]).balanceOf(_addr) >= tl.amounts[i], "Token reserve is not enought");

            // transfer or allow tracked tokens
            {
                bytes memory res;
                if (tl.tokens[i] == _call.tokenAddress) {
                    res = portToken.externalCall(
                        tl.tokens[i],
                        abi.encodeWithSelector(IERC20.transfer.selector, msgSender, tl.amounts[i]),
                        0,
                        "Direct transfer failed"
                    );
                    if (res.length > 0) {
                        require(abi.decode(res, (bool)), "Direct transfer failed");
                    }
                } else {
                    res = portToken.externalCall(
                        tl.tokens[i],
                        abi.encodeWithSelector(IERC20.approve.selector, _call.dex, tl.amounts[i]),
                        0,
                        "Allowance change failed"
                    );
                    if (res.length > 0) {
                        require(abi.decode(res, (bool)), "Allowance change failed");
                    }
                }
            }
        }
        for (uint256 i = 0; i < _call.dexCalldata.length; i++) {
            portToken.externalCall(_call.dex, _call.dexCalldata[i], 0, "DEX call failed");
        }

        uint256 newUserBalance = IERC20(_call.tokenAddress).balanceOf(msgSender);
        require(oldUserBalance + _call.tokenAmount <= newUserBalance, "Not enought received by user");

        portToken.controllerBurn(msgSender, _amount);
        emit RedeemedUsingDex(msgSender, _addr, _amount, _call.tokenAddress, newUserBalance - oldUserBalance);
        LibTrackedToken.emitTrackedTokenBalancesChanged(_addr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/PortToken/IPortToken.sol";
import "../interfaces/ITransferHookReceiver.sol";
import {Modifiers} from "../libraries/Modifiers.sol";
import "../libraries/LibFee.sol";

// streaming fee lifecycle
// Accumulated - after every mint/burn or if called manually
// Minted      - Minted and can be claimed

contract FeeFacet is Modifiers, ITransferHookReceiver {
    struct TokenFeeData {
        uint256 pendingSuccessFee;
        uint256 pendingStreamingFee;
        uint256 unclaimedFee;
        uint256 currentPrice;
        uint256 lastMaxPrice;
        uint256 lastMintedAt;
    }

    event StreamingFeeMinted(address indexed portTokenAddr, uint256 amount);
    event StreamingFeeChanged(address indexed portTokenAddr, uint32 value);
    event SuccessFeeChanged(address indexed portTokenAddr, uint32 value);
    event FeeLimitsChanged(LibFee.FeeLimits limits);
    event FeeMinted(address indexed portTokenAddr, uint256 amount);

    function setFeeLimits(LibFee.FeeLimits calldata _limits) external onlyOwner whenNotPaused {
        LibFee.DiamondStorage storage ds = LibFee.diamondStorage();
        ds.feeLimits = _limits;

        emit FeeLimitsChanged(_limits);
    }

    function getFeeLimits() external view returns (LibFee.FeeLimits memory limits) {
        LibFee.DiamondStorage storage ds = LibFee.diamondStorage();
        return ds.feeLimits;
    }

    function getManagementFeeVault() external view returns(address){
        return LibFee.diamondStorage().feeVault;
    }

    function setManagementFeeVault(address vault) external onlyOwner whenNotPaused{
        LibFee.diamondStorage().feeVault = vault;
    }

    function setStreamingFee(address _addr, uint16 _value) external onlyTokenManager(_addr) whenNotPaused {
        require(_value < LibFee.feeDataForToken(_addr).streamingFee, "Streaming fee cannot be increased");
        LibFee.setStreamingFee(_addr, _value);
    }

    function setSuccessFee(address _addr, uint16 _value) external onlyTokenManager(_addr) whenNotPaused {
        require(_value < LibFee.feeDataForToken(_addr).successFee, "Success fee cannot be increased");
        LibFee.setSuccessFee(_addr, _value);
    }

    function getStreamingFee(address _addr) external view returns (uint16) {
        return LibFee.feeDataForToken(_addr).streamingFee;
    }

    function getSuccessFee(address _addr) external view returns (uint16) {
        return LibFee.feeDataForToken(_addr).successFee;
    }

    function onTokenTransfer(
        address token,
        address from,
        address to,
        uint256
    ) external override whenNotPaused{
        //mint or burn
        if (from == address(0) || to == address(0)) {
            LibFee.accumulateAndMintFees(token);
        }
    }

    function getFeeInfo(address portTokenAddr) external view returns (TokenFeeData memory data) {
        data.pendingStreamingFee = LibFee.getPendingStreamingFee(portTokenAddr);
        (data.pendingSuccessFee, data.currentPrice) = LibFee.getPendingSuccessFee(portTokenAddr);
        data.lastMaxPrice = LibFee.feeDataForToken(portTokenAddr).lastMaxPrice;
        data.unclaimedFee = LibFee.getUnclaimedFeeAmount(portTokenAddr);
        data.lastMintedAt = LibFee.feeDataForToken(portTokenAddr).lastMintedAt;
    }

    function accumulateAndMintFees(address portTokenAddr) external whenNotPaused {
        LibFee.accumulateAndMintFees(portTokenAddr);
    }


    /// @notice reinitialize fees using data from graph and default token price
    function reinitializeFees(address[] calldata portTokenAddrs, uint16[] calldata streaming, uint16[] calldata success) external onlyOwner{
        uint _l = portTokenAddrs.length;
        LibTrackedToken.TrackedTokensList memory tl;
        address baseToken = LibPriceInterface.diamondStorage().baseToken;
        for (uint i=0; i<_l;i++) {
            tl=LibTrackedToken.getTargetAmount(portTokenAddrs[i]);
            LibFee.FeeData storage d = LibFee.feeDataForToken(portTokenAddrs[i]);
            
            if (tl.length==0 || d.successFeeBase!=address(0))  {
                continue;
            }

            LibFee.setStreamingFee(portTokenAddrs[i], streaming[i]);
            LibFee.setSuccessFee(portTokenAddrs[i], success[i]);
            
            
            d.successFeeBase = baseToken;
            d.lastMintedAt = block.timestamp;
            d.lastMaxPrice = 10**7; // 10USDC

            emit LibFee.SuccessFeeInitialized(portTokenAddrs[i], baseToken, d.lastMaxPrice);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAggregatorV3Minimal {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOffchainOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, bool useWrappers) external view returns (uint256 weightedRate);    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferHookReceiver {
    function onTokenTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPortTokenControllable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";


interface IPortToken is IERC20Upgradeable, IERC20MetadataUpgradeable, IPortTokenControllable {
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPortTokenControllable {
    function controller() external view returns (address);

    function manager() external view returns (address);

    function changeController(address newController) external;

    function changeManager(address newManager) external;

    function controllerMint(address account, uint256 amount) external;

    function controllerBurn(address account, uint256 amount) external;

    function externalCall(
        address target,
        bytes calldata data,
        uint256 value,
        string memory errorMessage
    ) external returns (bytes memory returndata);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibDexInterface {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.dexinterface");
    struct DiamondStorage {
        EnumerableSet.AddressSet dexAddressWhitelist;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Not contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

library LibEIP712 {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.metatx.v1");
    bytes32 constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    
    struct DiamondStorage {
        mapping(address=>uint32) nonces;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // TODO maybe cache this
    function buildDomainSeparator(bytes32 nameHash, bytes32 versionHash) internal view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, nameHash, versionHash, block.chainid, address(this)));
    }

    function hashTypedDataV4(
        bytes32 nameHash,
        bytes32 versionHash,
        bytes32 structHash
    ) internal view returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(buildDomainSeparator(nameHash, versionHash), structHash);
    }

    function verifyTimestamps(uint256 validAfter, uint256 validBefore) internal view {
        require(block.timestamp > validAfter, "Authorization is not yet valid");
        require(block.timestamp < validBefore, "Authorization is expired");
    }

    function verifySigner(
        address signer,
        bytes32 hash,
        uint32 nonce_,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        require(diamondStorage().nonces[signer]++ == nonce_, "Invalid nonce");

        address _signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == _signer, "Invalid signer");
        
    }

    function nonce(address signer) internal view returns(uint32) {
        return diamondStorage().nonces[signer];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "../interfaces/PortToken/IPortToken.sol";
import "./LibTrackedToken.sol";
import "./LibTokenWhitelist.sol";

library LibFee {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.streamingfee.v2");
    uint256 constant FEE_DENOMINATOR = 1000;
    /* 14 % platform fee */
    uint256 constant PLATFORM_FEE = 140;

    struct TokenFeeSettings {
        uint16 streamingFeeValue;
        uint16 successFeeValue;
        address successFeeBaseToken;
    }

    struct FeeLimits {
        uint16 minSuccessFee;
        uint16 maxSuccessFee;
        uint16 minStreamingFee;
        uint16 maxStreamingFee;
    }

    struct FeeData {
        uint16 successFee;
        uint16 streamingFee;
        uint256 lastMintedAt;
        address successFeeBase;
        uint256 lastMaxPrice;
    }

    // struct StreamingFeeData {
    //     uint16 value;
    //     uint256 lastAccumulatedAt;
    //     uint256 lastReleasedAt;
    //     uint256 accumulatedAmount;
    //     uint256 releasedAmount;
    // }

    // struct SuccessFeeData {
    //     uint16 value;
    //     address baseToken;
    //     uint256 lastMaxPrice;
    //     uint256 lastAccumulatedAt;
    //     uint256 accumulatedAmount;
    // }

    struct DiamondStorage {
        // mapping(address => StreamingFeeData) streamingFeeData;
        // mapping(address => SuccessFeeData) successFeeData;
        FeeLimits feeLimits;
        mapping(address => FeeData) feeData;
        address feeVault;
    }

    event StreamingFeeChanged(address indexed portTokenAddr, uint32 feeValue);
    event StreamingFeeAccumulated(address indexed portTokenAddr, uint256 amount);

    event SuccessFeeInitialized(address indexed portTokenAddr, address baseTokenAddr, uint256 initialPrice);
    event SuccessFeeChanged(address indexed portTokenAddr, uint32 feeValue);
    event SuccessFeeAccumulated(address indexed portTokenAddr, uint256 amount);
    event HighTideUpdated(address indexed portTokenAddr, uint256 newMaxPrice);

    event FeeMinted(address indexed portTokenAddr, uint256 amount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // function streamingFeeDataForToken(address _addr) internal view returns (StreamingFeeData storage) {
    //     DiamondStorage storage ds = diamondStorage();
    //     return ds.streamingFeeData[_addr];
    // }

    // function successFeeDataForToken(address _addr) internal view returns (SuccessFeeData storage) {
    //     DiamondStorage storage ds = diamondStorage();
    //     return ds.successFeeData[_addr];
    // }

    function feeDataForToken(address _addr) internal view returns (FeeData storage) {
        DiamondStorage storage ds = diamondStorage();
        return ds.feeData[_addr];
    }

    function setStreamingFee(address _addr, uint16 _value) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_value <= ds.feeLimits.maxStreamingFee && _value >= ds.feeLimits.minStreamingFee, "Invalid streaming fee");

        feeDataForToken(_addr).streamingFee = _value;

        emit StreamingFeeChanged(_addr, _value);
    }

    function setSuccessFee(address _addr, uint16 _value) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_value <= ds.feeLimits.maxSuccessFee && _value >= ds.feeLimits.minSuccessFee, "Invalid success fee");

        feeDataForToken(_addr).successFee = _value;

        emit SuccessFeeChanged(_addr, _value);
    }

    /// @notice set high tide value to target token price without minting success fee
    function initSuccessFee(
        address portTokenAddr,
        address baseToken,
        uint256 price
    ) internal {
        if (baseToken == address(0)) {
            baseToken = LibPriceInterface.diamondStorage().baseToken;
        }
        
        require(LibTokenWhitelist.isAllowed(baseToken), "invalid base token");

        FeeData storage d = feeDataForToken(portTokenAddr);
        require(d.lastMaxPrice == 0, "success fee already initialized");

        d.successFeeBase = baseToken;
        d.lastMaxPrice = price;

        emit SuccessFeeInitialized(portTokenAddr, baseToken, price);
    }

    function initFees(
        address portTokenAddr,
        TokenFeeSettings memory feeSettings,
        uint256 initialPrice
    ) internal {
        initSuccessFee(portTokenAddr, feeSettings.successFeeBaseToken, initialPrice);
        setStreamingFee(portTokenAddr, feeSettings.streamingFeeValue);
        setSuccessFee(portTokenAddr, feeSettings.successFeeValue);

        feeDataForToken(portTokenAddr).lastMintedAt = block.timestamp;
    }

    /// @notice get amount of already minted, but unclaimed fees
    function getUnclaimedFeeAmount(address portTokenAddr) internal view returns (uint256) {
        return IPortToken(portTokenAddr).balanceOf(diamondStorage().feeVault);
    }

    /// @notice calculate amount of not yet accumulated success fee with current portfolio token price
    // TODO  extend natspec
    function getPendingSuccessFee(address portTokenAddr) internal view returns (uint256 amount, uint256 currentTokenPrice) {
        FeeData storage d =feeDataForToken(portTokenAddr);
        if (d.successFeeBase == address(0)) {
            return (0,0);
        }

        uint256 pendingStreamingFee =  getPendingStreamingFee(portTokenAddr);
        currentTokenPrice = LibTrackedToken.getRealPortTokenPriceInOtherToken(
            portTokenAddr,
            d.successFeeBase,
           pendingStreamingFee
        );

        if (d.successFee > 0 && currentTokenPrice > d.lastMaxPrice) {
            // amount in % is A%=(OLD_MAX-NEW_MAX)/OLD_MAX*FEE_VALUE
            // amount in token units is AABS = A%*TotalSupply

            amount = (currentTokenPrice - d.lastMaxPrice) * d.successFee * (IERC20(portTokenAddr).totalSupply()+pendingStreamingFee) / d.lastMaxPrice / FEE_DENOMINATOR;
        }
    }

  
    /// @notice calculate amount of not yet accumulated streaming fee
    function getPendingStreamingFee(address portTokenAddr) internal view returns (uint256 amount) {
        FeeData storage d = feeDataForToken(portTokenAddr);

        if (d.streamingFee > 0) {
            //streaming fee value d.value is in 1/1000 (1000==100%) per year
            //means streaming fee per second = d.value/31536000 (seconds in one year)
            uint256 unclaimedAmount = getUnclaimedFeeAmount(portTokenAddr);

            amount =
                ((IPortToken(portTokenAddr).totalSupply() - unclaimedAmount) * d.streamingFee * (block.timestamp - d.lastMintedAt)) /
                31536000 /
                LibFee.FEE_DENOMINATOR;
        }
    }

       function accumulateAndMintFees(address portTokenAddr) internal {
        FeeData storage d = feeDataForToken(portTokenAddr);

        // avoid double mint in same block
        if (d.lastMintedAt >= block.timestamp) {
            return;
        }

        uint256 accumulatedStreamingFee = getPendingStreamingFee(portTokenAddr);
        if (accumulatedStreamingFee>0) {
            emit StreamingFeeAccumulated(portTokenAddr, accumulatedStreamingFee);
        }

        (uint256 accumulatedSuccessFee, uint256 currentTokenPrice) = getPendingSuccessFee(portTokenAddr);

        // accumulate new fees if success fee not 0 and if old high tide was not 0
        if (currentTokenPrice > d.lastMaxPrice) {
            d.lastMaxPrice = currentTokenPrice;
            
            if (accumulatedSuccessFee > 0) {
                emit SuccessFeeAccumulated(portTokenAddr, accumulatedSuccessFee);
            }

            emit HighTideUpdated(portTokenAddr, currentTokenPrice);
        }
    
        uint256 totalAccumulatedFee = accumulatedStreamingFee+accumulatedSuccessFee;

        
        d.lastMintedAt = block.timestamp;
        
        if (totalAccumulatedFee == 0) {
            return;
        }

        address feeVault = diamondStorage().feeVault;
        require(feeVault!=address(0), "fee distributor should be initialized");
        IPortToken(portTokenAddr).controllerMint(feeVault, totalAccumulatedFee);

        emit FeeMinted(portTokenAddr, totalAccumulatedFee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibPause {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.pause.v1");
    struct DiamondStorage {
        bool isPaused;
        mapping(address => bool) pausedManagers;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function isPaused() internal view returns (bool) {
        return diamondStorage().isPaused;
    }

    function isManagerPaused(address _manager) internal view returns (bool) {
        return diamondStorage().pausedManagers[_manager];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IAggregatorV3.sol";
import "../interfaces/IOffchainOracle.sol";

library LibChainlinkUtils {
    function getAnswer(address _feed) internal view returns (uint8 decimals, int256 price) {
        require(_feed != address(0));
        IAggregatorV3Minimal feed = IAggregatorV3Minimal(_feed);
        (, price, , , ) = feed.latestRoundData();
        decimals = feed.decimals();
    }

    function getDerivedPrice(
        address _tokenFeed,
        address _baseFeed,
        uint8 _baseTokenDecimals
    ) internal view returns (uint256 price) {
        (uint8 tokenFeedDecimals, int256 tokenPrice) = getAnswer(_tokenFeed);
        (uint8 baseFeedDecimals, int256 basePrice) = getAnswer(_baseFeed);
        require(tokenPrice >= 0 && basePrice >= 0);

        //price in base units
        price = (uint256(tokenPrice) * (10**_baseTokenDecimals)) / uint256(basePrice);

        //  adjust if price feed have different decimals
        if (tokenFeedDecimals > baseFeedDecimals) {
            price = price / (10**(tokenFeedDecimals - baseFeedDecimals));
        } else if (tokenFeedDecimals < baseFeedDecimals) {
            price = price * (10**(baseFeedDecimals - tokenFeedDecimals));
        }
    }
}

library LibPriceInterface {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.priceinterface.v1");
    uint256 constant SHARE_DENOMINATOR = 10000;

    // feedType: feedTypes with id>=200 considered unsafe and shouldn't be used in production
    // 1: chainlink usdc feed
    // 254: 1inch offchain oracle
    struct PriceSourceSettings {
        address feed;
        uint8 feedType;
    }

    struct DiamondStorage {
        address baseToken; // token to price against
        address utilityToken; // utility token address
        uint16 minUtilityTokenShare; // desired minimum utility token share in 1/10000 (1%=100)
        mapping(address => PriceSourceSettings) priceSources;
        bool allowUnreliablePriceSources;
        uint256 minTokenValuation; // portfolio token has a significant balance of tracked token if locked tracked token valuation exceeds this value (converted to base token)
        uint256 minUtilityTokenBalance; // utility token balance required to skip utility token share check
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function hasPriceSource(address _addr) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        PriceSourceSettings storage os = ds.priceSources[_addr];
        return (os.feed != address(0) && os.feedType > 0 && (os.feedType < 200 || ds.allowUnreliablePriceSources));
    }

    /// @notice checks if price of provided amount of token in greater than minTokenValuation
    /// @param _addr ERC20 token address
    /// @param _amount amount of token
    /// @return isSignificant
    function amountIsSignificant(address _addr, uint256 _amount) internal view returns (bool isSignificant) {
        return priceIsSignificant(_addr, getTokenPrice(_addr, _amount));
    }

    // TODO description
    function priceIsSignificant(address /*_addr*/, uint256 _price)  internal view returns (bool isSignificant) {
        return _price > diamondStorage().minTokenValuation;
    }

    // get amount of base token  per _amount of token
    function getTokenPrice(address _addr, uint256 _amount) internal view returns (uint256 price) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.baseToken == _addr) {
            return _amount;
        }

        PriceSourceSettings storage os = ds.priceSources[_addr];
        require(hasPriceSource(_addr), "No price source for token");

        if (os.feedType == 1) {
            PriceSourceSettings storage bs = ds.priceSources[ds.baseToken];
            require(os.feed != address(0), "No chainlink price feed for base");

            price =
                (LibChainlinkUtils.getDerivedPrice(os.feed, bs.feed, IERC20Metadata(ds.baseToken).decimals()) * _amount) /
                (10**IERC20Metadata(_addr).decimals());
        } else if (os.feedType == 254) {
            price = (IOffchainOracle(os.feed).getRate(IERC20(_addr), IERC20(ds.baseToken), true) * _amount) / (10**IERC20Metadata(_addr).decimals());
        }
    }

    // get amount of token per _amount of base token
    function getTokenForPrice(address _addr, uint256 _price) internal view returns (uint256 amount) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.baseToken == _addr) {
            return _price;
        }

        PriceSourceSettings storage os = ds.priceSources[_addr];
        require(hasPriceSource(_addr), "No price source for token");

        if (os.feedType == 1) {
            PriceSourceSettings storage bs = ds.priceSources[ds.baseToken];
            require(os.feed != address(0), "No chainlink price feed for base");

            amount =
                (LibChainlinkUtils.getDerivedPrice(bs.feed, os.feed, IERC20Metadata(_addr).decimals()) * _price) /
                (10**IERC20Metadata(ds.baseToken).decimals());
        } else if (os.feedType == 254) {
            amount = (IOffchainOracle(os.feed).getRate(IERC20(ds.baseToken), IERC20(_addr), true) * _price) / 10**IERC20Metadata(_addr).decimals();
            // * rate multiplicator / rate denumenator * amount / amount denumerator,  and rate multiplicator == amount denumenator
        }
    }

    // get total amount of base token units equal to amounts of tokens
    function getTokensTotalPrice(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            address _addr = _tokens[i];
            totalPrice += getTokenPrice(_addr, _amounts[i]);
        }

        return totalPrice;
    }

    function getUtilityTokenShare(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        uint256 totalPrice;
        uint256 utilityPrice;

        for (uint256 i = 0; i < _tokens.length; i++) {
            uint256 price = getTokenPrice(_tokens[i], _amounts[i]);
            totalPrice += price;

            if (_tokens[i] == diamondStorage().utilityToken) {
                utilityPrice = price;
            }
        }
        require(totalPrice > 0, "Total token price is 0");

        return (utilityPrice * SHARE_DENOMINATOR) / totalPrice;
    }

    function checkUtilityTokenShare(
        address portTokenOwner,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.minUtilityTokenShare == 0) {
            return true;
        }

        if (
            portTokenOwner != address(0) &&
            ds.minUtilityTokenBalance > 0 &&
            IERC20(ds.utilityToken).balanceOf(portTokenOwner) >= ds.minUtilityTokenBalance
        ) {
            return true;
        }

        return getUtilityTokenShare(_tokens, _amounts) >= ds.minUtilityTokenShare;
    }

    function estimateMinUtilityTokenAmount(address[] memory _tokens, uint256[] memory _amounts) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        if (ds.minUtilityTokenShare == 0) {
            return 0;
        }

        uint256 totalPrice = getTokensTotalPrice(_tokens, _amounts);
        uint256 utilityUnit = 10**IERC20Metadata(ds.utilityToken).decimals();
        uint256 utilityPrice = getTokenPrice(ds.utilityToken, utilityUnit);

        return (((totalPrice * ds.minUtilityTokenShare) / SHARE_DENOMINATOR) * utilityUnit) / utilityPrice;
    }

    function estimateAmountsFromTotalPrice(
        uint256 _totalPrice,
        address[] memory _tokens,
        uint256[] memory _ratios
    ) internal view returns (uint256[] memory _amounts) {
        _amounts = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            _amounts[i] = getTokenForPrice(_tokens[i], (_totalPrice * _ratios[i]) / SHARE_DENOMINATOR);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

library LibReferralToken {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.refferaltoken.v1");
    uint256 constant FEE_DENOMINATOR = 1000;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    struct ReferralFeeLimits {
        uint16 minFee;
        uint16 maxFee;
    }

    struct ReferralFeeSettings {
        uint16 feeValue;
        address feeDistributor;
        mapping(address => bool) allowedInvestors;
    }

    struct DiamondStorage {
        ReferralFeeLimits feeLimits;
        mapping(address => bool) isReferral;
        mapping(address => ReferralFeeSettings) tokenSettings;
        EnumerableSetUpgradeable.AddressSet approvedSigners;
        EnumerableSetUpgradeable.AddressSet approvedFeeDistributors;
        mapping(address => bool) isAllowedManager;
    }

    event ReferralTokenSettingsChanged(address indexed portTokenAddr, bool isReferral, uint16 feeValue, address feeDistrubutor);
    event ReferralFeeCharged(address indexed portTokenAddr, address indexed investor, address indexed feeDistributor, uint256 feeAmount);
    event ReferralTokenInvestorAllowed(address indexed portTokenAddr, address indexed investor);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // TODO check fee distributor
    function configureToken(
        address portToken,
        bool isReferral,
        uint16 referralFee,
        address feeDistributor
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        require(referralFee >= ds.feeLimits.minFee && referralFee <= ds.feeLimits.maxFee, "Invalid referral fee");

        ds.isReferral[portToken] = isReferral;
        ds.tokenSettings[portToken].feeValue = referralFee;
        ds.tokenSettings[portToken].feeDistributor = feeDistributor;

        emit ReferralTokenSettingsChanged(portToken, isReferral, referralFee, feeDistributor);
    }

    function isReferralToken(address portToken) internal view returns (bool) {
        return diamondStorage().isReferral[portToken];
    }

    function isAllowedManager(address manager) internal view returns (bool) {
        return diamondStorage().isAllowedManager[manager];
    }

    function isAllowedInvestor(address portToken, address investor) internal view returns (bool) {
        return diamondStorage().tokenSettings[portToken].allowedInvestors[investor];
    }

    function isAllowedFeeDistributor(address distributor) internal view returns (bool) {
        return diamondStorage().approvedFeeDistributors.contains(distributor);
    }

    function allowInvestor(
        address signer,
        address portTokenAddr,
        address investor
    ) internal {
        LibReferralToken.DiamondStorage storage ds = LibReferralToken.diamondStorage();
        require(ds.approvedSigners.contains(signer), "Invalid signer");
        require(ds.isReferral[portTokenAddr], "Token is not referral");

        ds.tokenSettings[portTokenAddr].allowedInvestors[investor] = true;
        emit ReferralTokenInvestorAllowed(portTokenAddr, investor);
    }

    function getFeeDistributor(address portToken) internal view returns (address feeDistributor) {
        feeDistributor = diamondStorage().tokenSettings[portToken].feeDistributor;
        require(feeDistributor != address(0), "Invalid fee distrubutor");
    }

    function getFeeValue(address portToken) internal view returns (uint16) {
        return diamondStorage().tokenSettings[portToken].feeValue;
    }

    function splitAmount(address portToken, uint256 amount) internal view returns (uint256 investorAmount, uint256 feeAmount) {
        feeAmount = (amount * diamondStorage().tokenSettings[portToken].feeValue) / FEE_DENOMINATOR;
        investorAmount = amount - feeAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/LibPriceInterface.sol";

library LibTokenWhitelist {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.tokenlist.v1");

    struct DiamondStorage {
        EnumerableSet.AddressSet whitelist;
    }

    event TokenEnabled(address indexed tokenAddr);
    event TokenDisabled(address indexed tokenAddr);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function enableToken(address _addr) internal {
        DiamondStorage storage ds = diamondStorage();
        if (!ds.whitelist.contains(_addr)) {
            ds.whitelist.add(_addr);
            emit TokenEnabled(_addr);
        }
    }

    function disableToken(address _addr) internal {
        DiamondStorage storage ds = diamondStorage();
        if (ds.whitelist.contains(_addr)) {
            ds.whitelist.remove(_addr);
            emit TokenDisabled(_addr);
        }
    }

    function isAllowed(address _addr) internal view returns (bool) {
        DiamondStorage storage ds = diamondStorage();
        return ds.whitelist.contains(_addr) && LibPriceInterface.hasPriceSource(_addr);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibTokenWhitelist.sol";
import "./LibPriceInterface.sol";

library LibTrackedToken {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("portfolio.trackedtokens.v1");
    uint256 constant MAX_TRACKED_TOKENS = 10;

    struct TrackedTokensList {
        address[] tokens;
        uint256[] amounts;
        uint256 length;
    }

    struct TrackedTokensConfig {
        // Set of tracked token addresses
        EnumerableSet.AddressSet trackedTokens;
        // Amount of base units of tracked token per one (10^18 units) portfolio token
        mapping(address => uint256) targetAmounts;
    }

    struct DiamondStorage {
        mapping(address => TrackedTokensConfig) tokenConfig;
    }

    event TrackedTokenAdded(address indexed portTokenAddr, address tokenAddr, uint256 amount);
    event TrackedTokenBalancesChanged(address indexed portTokenAddress, uint256 portTokenSupply, address[] tokenAddrs, uint256[] amounts);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function configForToken(address _addr) internal view returns (TrackedTokensConfig storage tc) {
        return diamondStorage().tokenConfig[_addr];
    }

    function addTrackedToken(
        address _addr,
        address _trackedAddr,
        uint256 _amount
    ) internal {
        TrackedTokensConfig storage tc = configForToken(_addr);

        require(_trackedAddr != _addr, "Can`t track itself"); // even if portToken is whitelisted, it shouldn't be allowed
        require(LibTokenWhitelist.isAllowed(_trackedAddr), "Token not allowed");
        require(!tc.trackedTokens.contains(_trackedAddr), "Token already tracked");
        require(tc.trackedTokens.length() <= LibTrackedToken.MAX_TRACKED_TOKENS, "Tracked tokens limit reached");

        tc.targetAmounts[_trackedAddr] = _amount;
        tc.trackedTokens.add(_trackedAddr);

        emit TrackedTokenAdded(_addr, _trackedAddr, _amount);
    }

    // TODO WHAT?!
    function getTargetAmount(address _addr) internal view returns (TrackedTokensList memory tl) {
        TrackedTokensConfig storage tc = configForToken(_addr);
        tl.length = tc.trackedTokens.length();

        tl.tokens = new address[](tl.length);
        tl.amounts = new uint256[](tl.length);

        for (uint256 i; i < tl.length; i++) {
            tl.tokens[i] = tc.trackedTokens.at(i);
            tl.amounts[i] = tc.targetAmounts[tc.trackedTokens.at(i)];
        }

        return tl;
    }

    function getTargetAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        require(_amount > 0);

        tl = getTargetAmount(_addr);

        for (uint256 i; i < tl.length; i++) {
            tl.amounts[i] = (tl.amounts[i] * _amount) / (10**18);
        }

        return tl;
    }

    /// @notice get total locked amounts of tracked tokens
    function getTotalRealAmount(address _addr) internal view returns (TrackedTokensList memory tl) {
        TrackedTokensConfig storage tc = configForToken(_addr);
        tl.length = tc.trackedTokens.length();
        tl.tokens = new address[](tl.length);
        tl.amounts = new uint256[](tl.length);

        for (uint256 i; i < tl.length; i++) {
            tl.tokens[i] = tc.trackedTokens.at(i);
            tl.amounts[i] = IERC20(tl.tokens[i]).balanceOf(_addr);
        }

        return tl;
    }

    /// @notice get amount of locked tockens per provided amount of port token
    function getRealAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        require(_amount > 0);
        tl = getTotalRealAmount(_addr);
        uint256 portTokenSupply = IERC20(_addr).totalSupply();

        for (uint256 i; i < tl.length; i++) {
            if (portTokenSupply > 0) {
                tl.amounts[i] = (tl.amounts[i] * _amount) / portTokenSupply;
            } else {
                tl.amounts[i] = 0;
            }
        }

        return tl;
    }

    function getActualAmount(address _addr, uint256 _amount) internal view returns (TrackedTokensList memory tl) {
        if (hasTrackedTokenBalance(_addr) && IERC20(_addr).totalSupply() > 0) {
            return getRealAmount(_addr, _amount);
        } else {
            return getTargetAmount(_addr, _amount);
        }
    }

    function emitTrackedTokenBalancesChanged(address _addr) internal {
        TrackedTokensList memory tl = getTotalRealAmount(_addr);
        emit TrackedTokenBalancesChanged(_addr, IERC20(_addr).totalSupply(), tl.tokens, tl.amounts);
    }

    /// @notice checks if portfolio token has significant amount of at least one tracked token
    /// @param _addr portfolio token address
    /// @return bool
    function hasTrackedTokenBalance(address _addr) internal view returns (bool) {
        TrackedTokensConfig storage tc = configForToken(_addr);

        uint256 _l = tc.trackedTokens.length();

        for (uint256 i = 0; i < _l; i++) {
            if (LibPriceInterface.amountIsSignificant(tc.trackedTokens.at(i), IERC20(tc.trackedTokens.at(i)).balanceOf(_addr))) {
                return true;
            }
        }

        return false;
    }

    /**
        @notice get value of locked tracked tokens per one portfolio token
                requires all tokens to have significant balances
        @param portTokenAddr port token address
        @param additionalSupply value to be added to current total supply during price calculation, 
                                for example used to calculate price accounting for unminted fees
    */
    function getRealPortTokenPrice(address portTokenAddr, uint256 additionalSupply) internal view returns (uint256 totalPrice) {
        uint256 totalSupply = IERC20(portTokenAddr).totalSupply();

        // zero real price for token without supply
        if (totalSupply == 0) {
            return 0;
        }

        totalSupply += additionalSupply;

        TrackedTokensList memory tl = getTotalRealAmount(portTokenAddr);

        //not using LibPriceInterface.getTokensTotalPrice to query oracle once
        for (uint256 i = 0; i < tl.length; i++) {
            if (tl.amounts[i] > 0) {
                uint256 price = LibPriceInterface.getTokenPrice(tl.tokens[i], tl.amounts[i]);

                if (LibPriceInterface.priceIsSignificant(tl.tokens[i], price)) {
                    totalPrice += price;
                }
            }
        }

        if (totalPrice > 0) {
            totalPrice = (totalPrice * 10**18) / totalSupply;
        }
    }

    /**
        @notice get value of locked tracked tokens per one portfolio token
                denominated in other token
                requires all tokens to have significant balances
        @param portTokenAddr port token address
        @param otherTokenAddr address of token to denominate price in
        @param additionalSupply value to be added to current total supply during price calculation, 
                                for example used to calculate price accounting for unminted fees
    */
    function getRealPortTokenPriceInOtherToken(
        address portTokenAddr,
        address otherTokenAddr,
        uint256 additionalSupply
    ) internal view returns (uint256 totalPrice) {
        totalPrice = getRealPortTokenPrice(portTokenAddr, additionalSupply);

        if (totalPrice == 0) {
            return 0;
        }

        if (otherTokenAddr != LibPriceInterface.diamondStorage().baseToken) {
            totalPrice /= LibPriceInterface.getTokenPrice(otherTokenAddr, 10**IERC20Metadata(otherTokenAddr).decimals());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/PortToken/IPortTokenControllable.sol";
import {LibDiamond} from "./LibDiamond.sol";
import {LibPause} from "./LibPause.sol";

contract Modifiers {
    // AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyTokenManager(address _tokenAddr) {
        require(IPortTokenControllable(_tokenAddr).manager() == msg.sender, "Only porfolio manager allowed");
        require(!LibPause.isManagerPaused(msg.sender), "Portfolio manager paused");
        _;
    }

    modifier whenNotPaused() {
        require(!LibPause.isPaused(), "Platform paused");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Can be called only by diamond");
        _;
    }
}