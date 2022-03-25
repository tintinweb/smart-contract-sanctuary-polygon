//SPDX-License-Identifier: MIT
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '../interface/IGalleryFactory.sol';
import './Gallery.sol';
import '../interface/IGallery.sol';
import '../interface/INFT.sol';
import '../interface/IMarketPlace.sol';

pragma solidity ^0.8.0;

contract GalleryFactory is IGalleryFactory {
	using Counters for Counters.Counter;
	using EnumerableSet for EnumerableSet.Bytes32Set;

	struct galleryInfo {
		address owner;
		address galleryAddress;
		string name;
		IGallery gallery;
	}

	INFT public NFT;
	IMarketPlace public marketPlace;

	mapping(bytes32 => galleryInfo) public galleries;

	EnumerableSet.Bytes32Set private allgalleriesId;

	constructor(address nft, address market) {
		NFT = INFT(nft);
		marketPlace = IMarketPlace(market);
		NFT.addAdmin(address(this));
		marketPlace.addAdmin(address(this));
	}

	function createGallery(string calldata _name, address _owner) public override {
		bytes32 galleryid = findHash(_name);
		require(!allgalleriesId.contains(galleryid), 'Name already registered');
		allgalleriesId.add(galleryid);
		Gallery galleryaddress = new Gallery(_name, _owner, address(NFT), address(marketPlace));
		galleries[galleryid] = galleryInfo(_owner, address(galleryaddress), _name, IGallery(address(galleryaddress)));
		emit gallerycreated(address(galleryaddress), _owner);
	}

	function mintNftInNewGallery(
		string calldata _name,
		address _owner,
		string calldata _uri,
		string calldata nftname,
		address artist,
		uint256 amount,
		uint256 artistFee,
		uint256 galleryOwnerFee
	) external override {
		bytes32 galleryid = findHash(_name);
		require(!allgalleriesId.contains(galleryid), 'Name already registered');
		galleryInfo storage gallery = galleries[galleryid];
		allgalleriesId.add(galleryid);
		Gallery galleryaddress = new Gallery(_name, _owner, address(NFT), address(marketPlace));
		galleries[galleryid] = galleryInfo(_owner, address(galleryaddress), _name, IGallery(address(galleryaddress)));
		NFT.manageMinters(address(galleryaddress), true);
		marketPlace.addGallery(address(galleryaddress), true);
		uint256 tokenid = gallery.gallery.mintAndSellNft(nftname, _uri, artist, amount, artistFee, galleryOwnerFee);
		emit mintedNftInNewGallery(address(galleryaddress), _owner, tokenid, address(galleryaddress));
	}

	function listgallery()
		public
		view
		override
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryAddress
		)
	{
		uint256 total = allgalleriesId.length();
		string[] memory name_ = new string[](total);
		address[] memory owner_ = new address[](total);
		address[] memory galleryaddress_ = new address[](total);

		for (uint256 i = 0; i < total; i++) {
			bytes32 id = allgalleriesId.at(i);
			name_[i] = galleries[id].name;
			owner_[i] = galleries[id].owner;
			galleryaddress_[i] = galleries[id].galleryAddress;
		}
		return (name_, owner_, galleryaddress_);
	}

	function changeNftAddress(address newnft) public override {
		NFT = INFT(newnft);
	}

	function changeMarketAddress(address newMarket) public override {
		marketPlace = IMarketPlace(newMarket);
	}

	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFT {
	function mint(string calldata _tokenURI, address _to) external returns (uint256);

	function burn(uint256 _tokenId) external;

	function safeTransferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;

	function ownerOf(uint256 tokenId) external view returns (address);

	function tokenURI(uint256 tokenId) external view returns (string memory);

	// function approve(address to, uint256 tokenId) external;
	function setApprovalForAll(address operator, bool approved) external;

	// function getApproved(uint256 tokenId) external view returns (address);
	// function isApprovedForAll(address owner, address operator) external view returns (bool);
	function manageMinters(address user, bool status) external;

	function addAdmin(address _admin) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketPlace {
	struct tokenMarketInfo {
		uint256 tokenId;
		uint256 totalSell;
		uint256 minPrice;
		uint256 artistfee;
		uint256 galleryownerfee;
		uint256 totalartistfee;
		uint256 totalgalleryownerfee;
		uint256 totalplatformfee;
		bool onSell;
		address payable galleryOwner;
		address payable artist;
		address owner;
	}

	event nftonsell(uint256 indexed _tokenid, uint256 indexed _price);
	event nftbought(uint256 indexed _tokenid, uint256 indexed _price, address indexed _buyer);
	event cancelnftsell(uint256 indexed _tokenid);

	/*@notice buy the token listed for sell 
     @param _tokenId id of token  */
	function buy(uint256 _tokenId, address _buyer) external payable;

	function addAdmin(address _admin) external;

	function addGallery(address _gallery, bool _status) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param _minprice minimum price to sell token*/
	function sell(
		uint256 _tokenId,
		uint256 _minprice,
		uint256 _artistfee,
		uint256 _galleryownerfee,
		address _gallery,
		address _artist,
		address _owner
	) external;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelSell(uint256 _tokenId) external;

	///@notice resale the token
	///@param _tokenId id of the token to resale
	///@param _minPrice amount to be updated
	function resale(uint256 _tokenId, uint256 _minPrice) external;

	///@notice change the artist fee commission rate
	function changeArtistFee(uint256 _tokenId, uint256 _artistFee) external;

	///@notice change the gallery owner commssion rate
	function changeGalleryFee(uint256 _tokenId, uint256 _galleryFee) external;

	/* @notice  listtoken added on sale list */
	function listtokenforsale() external view returns (uint256[] memory);

	//@notice get token info
	//@params tokenId to get information about
	function gettokeninfo(uint256 _tokenId) external view returns (tokenMarketInfo memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGalleryFactory {
	event gallerycreated(address indexed galleryaddress, address indexed _creator);
	event mintedNftInNewGallery(
		address indexed galleryaddress,
		address indexed _owner,
		uint256 indexed tokenid,
		address minter
	);

	/* @notice create new gallery contract
        @param name name of the gallery
        @param _owner address of gallery owner*/
	function createGallery(string calldata _name, address _owner) external;

	///@notice creategallery and mint a NFT
	function mintNftInNewGallery(
		string calldata name,
		address _owner,
		string calldata _uri,
		string calldata _nftname,
		address artist,
		uint256 amount,
		uint256 artistFee,
		uint256 galleryOwnerFee
	) external;

	///@notice change address of nftcontract
	///@param newNft new address of the nftcontract
	function changeNftAddress(address newNft) external;

	///@notice change the address of marketcontract
	///@param newMarket new address of the marketcontract
	function changeMarketAddress(address newMarket) external;

	//get the information of gallery creacted
	function listgallery()
		external
		returns (
			string[] memory name,
			address[] memory owner,
			address[] memory galleryaddress
		);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGallery {
	event nftadded(uint256 indexed nftid, address indexed _artist);
	event nftminted(uint256 indexed _tokenId, address indexed _minter);
	event nftburned(uint256 indexed _tokenId, address indexed _from);
	event transfered(uint256 indexed _tokenId, address indexed _from, address indexed _to);
	event nftmintedandsold(uint256 indexed _tokenId, address indexed _minter, uint256 indexed _price);

	/*@notice add nft to gallery*/
	// function addNft(string calldata _uri, string calldata _name) external;

	/*@notice mint Nft
    @param nftid id of nft to mint
    @param _to address to mint the token */
	function mintNFT(
		string calldata nftid,
		string calldata uri,
		address artist
	) external returns (uint256 tokenId);

	///@notice mintAndSellNft
	function mintAndSellNft(
		string calldata _name,
		string calldata _uri,
		address artist,
		uint256 amount,
		uint256 artistFee,
		uint256 galleryOwnerFee
	) external returns (uint256 tokenId);

	/*@notice get nft details
    @param nftid  id of  nft to get details*/
	function getNftdetails(bytes32 _nftid)
		external
		view
		returns (
			string memory tokenuri,
			address[] memory owner,
			address minter
		);

	/* @notice transfer nft
    @param from address of current owner
    @param to address of new owner */
	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) external;

	/*@notice burn token
    @param _tokenid id of token to be burned */
	function burn(uint256 _tokenId) external;

	/*@notice buynft
    @param tokenid id of token to be bought*/
	function buyNft(uint256 tokenid) external payable;

	/*@notice cancel the sell 
    @params _tokenId id of the token to cancel the sell */
	function cancelNftSell(uint256 _tokenid) external;

	/* @notice add token for sale
    @param _tokenId id of token
    @param amount minimum price to sell token*/
	function sellNft(
		uint256 tokenid,
		uint256 amount,
		uint256 artistfee,
		uint256 galleryOwnerFee
	) external;

	/*@notice get token details
    @param tokenid  id of  token to get details*/
	function getTokendetails(uint256 tokenid)
		external
		view
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 galleryOwnerFee
		);

	//@notice get the list of token minted in gallery//
	function getListOfTokenIds() external view returns (uint256[] memory);

	//@notice get the list of nfts added in gallery//

	function getListOfNfts() external view returns (bytes32[] memory);
}

//SPDX-License-Identifier:MIT

import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '../interface/IGallery.sol';
import '../interface/INFT.sol';
import '../interface/IMarketPlace.sol';
pragma solidity ^0.8.0;

//TODO //create voucher by contract owner. can be minted by anyone

contract Gallery is Ownable, EIP712, IGallery {
	mapping(address => bool) public admins;
	string public name;
	address public creator;
	INFT public nft;
	IMarketPlace public market;

	string private constant SIGNING_DOMAIN = 'LazyNFt-Voucher';
	string private constant SIGNATURE_VERSION = '1';

	using EnumerableSet for EnumerableSet.Bytes32Set;
	using EnumerableSet for EnumerableSet.AddressSet;
	using EnumerableSet for EnumerableSet.UintSet;

	constructor(
		string memory _name,
		address _owner,
		address _nft,
		address _market
	) EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
		name = _name;
		creator = _owner;
		nft = INFT(_nft);
		admins[_owner] = true;
		admins[msg.sender] = true;
		market = IMarketPlace(_market);
		transferOwnership(_owner);
	}

	modifier _onlyAdminOrOwner(address _owner) {
		require(admins[_owner] || owner() == _owner, 'Should be owner or admin');
		_;
	}
	modifier onlyTokenOwner(uint256 tokenid) {
		address owner = address(nft.ownerOf(tokenid));
		require(owner == msg.sender, 'Only Token owner can sell');
		_;
	}

	struct NftInfo {
		string nftId;
		string uri;
		address artist;
		address[] owner;
		address minter;
	}

	struct TokenInfo {
		uint256 tokenId;
		uint256 minprice;
		uint256 artistfee;
		uint256 galleryOwnerfee;
		string nftId;
		bool onSell;
		address artist;
		bool hasPhysicalTwin;
		string extras;
	}

	struct NftVoucher {
		string uri;
		uint256 minPrice;
		address artist;
		bytes signature;
		string nftid;
	}

	EnumerableSet.Bytes32Set private nftids;
	EnumerableSet.UintSet private listOfTokenIds;
	EnumerableSet.UintSet private listOfTokenIdsForSale;

	mapping(bytes32 => NftInfo) private nftInfo;
	mapping(uint256 => TokenInfo) private tokeninfo;

	receive() external payable {}

	function mintNFT(
		string calldata _name,
		string calldata _uri,
		address artist
	) public override _onlyAdminOrOwner(msg.sender) returns (uint256) {
		bytes32 _nftid = findHash(_name);
		NftInfo storage NFT = nftInfo[_nftid];
		if (!nftids.contains(_nftid)) nftids.add(_nftid);
		NFT.uri = _uri;
		uint256 tokenid = nft.mint(NFT.uri, address(this));
		if (owner() != creator) transferOwnership(creator);
		listOfTokenIds.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.nftId = _name;
		Token.artist = artist;
		NFT.artist = artist;
		NFT.owner.push(address(this));
		NFT.minter = msg.sender;
		emit nftminted(tokenid, address(this));
		return tokenid;
	}

	function burn(uint256 _tokenId) public override onlyOwner {
		nft.burn(_tokenId);
		listOfTokenIds.remove(_tokenId);
		emit nftburned(_tokenId, msg.sender);
	}

	function transferNft(
		address from,
		address to,
		uint256 tokenId
	) public override {
		nft.safeTransferFrom(from, to, tokenId);
		emit transfered(tokenId, from, to);
	}

	function buyNft(uint256 tokenid) public payable override {
		require(listOfTokenIds.contains(tokenid), 'Tokenid is not listed in this gallery');
		TokenInfo memory Token = tokeninfo[tokenid];
		require(Token.onSell, 'Token not on sell');
		bytes32 _nftid = findHash(Token.nftId);
		NftInfo storage NFT = nftInfo[_nftid];
		address tokenowner = nft.ownerOf(tokenid);
		market.buy{ value: msg.value }(tokenid, msg.sender);
		removeAddress(NFT.owner, tokenowner);
		NFT.owner.push(msg.sender);
		listOfTokenIdsForSale.remove(tokenid);
		Token.onSell = false;
	}

	function sellNft(
		uint256 tokenId,
		uint256 amount,
		uint256 artistFee,
		uint256 galleryOwnerFee
	) public override {
		require(listOfTokenIds.contains(tokenId), 'Tokenid is not listed in this gallery');
		TokenInfo storage Token = tokeninfo[tokenId];
		Token.minprice = amount;
		Token.onSell = true;
		Token.artistfee = artistFee;
		Token.galleryOwnerfee = galleryOwnerFee;
		listOfTokenIdsForSale.add(tokenId);
		address tokenowner = nft.ownerOf(tokenId);
		nft.setApprovalForAll(address(market), true);
		market.sell(tokenId, amount, artistFee, galleryOwnerFee, address(this), Token.artist, tokenowner);
	}

	function mintAndSellNft(
		string calldata _name,
		string calldata _uri,
		address artist,
		uint256 amount,
		uint256 artistFee,
		uint256 galleryOwnerFee
	) public override returns (uint256 _tokenId) {
		uint256 tokenId = mintNFT(_name, _uri, artist);
		sellNft(tokenId, amount, artistFee, galleryOwnerFee);
		emit nftmintedandsold(tokenId, address(this), amount);
		return tokenId;
	}

	function cancelNftSell(uint256 tokenid) public override {
		require(listOfTokenIds.contains(tokenid), 'Tokenid is not listed in this gallery');
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.minprice = 0;
		Token.onSell = false;
		listOfTokenIdsForSale.remove(tokenid);
		market.cancelSell(tokenid);
	}

	function changeArtistCommission(uint256 _tokenId, uint256 _artistfee) public {
		require(listOfTokenIds.contains(_tokenId), 'Tokenid is not listed in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.artistfee = _artistfee;
		market.changeArtistFee(_tokenId, _artistfee);
	}

	function changeGalleryCommission(uint256 _tokenId, uint256 _galleryOwnerFee) public {
		require(listOfTokenIds.contains(_tokenId), 'Tokenid is not listed in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.galleryOwnerfee = _galleryOwnerFee;
		market.changeGalleryFee(_tokenId, _galleryOwnerFee);
	}

	function reSaleNft(uint256 _tokenId, uint256 _minprice) public {
		require(listOfTokenIds.contains(_tokenId), 'Tokenid is not listed in this gallery');
		TokenInfo storage Token = tokeninfo[_tokenId];
		Token.minprice = _minprice;
		market.resale(_tokenId, _minprice);
	}

	/*@notice Lazy Miniting functionality */
	function lazyMinting(address redeemer, NftVoucher calldata voucher) public payable returns (uint256) {
		address signer = _verify(voucher);
		bytes32 _nftid = findHash(voucher.nftid);
		NftInfo storage NFT = nftInfo[_nftid];
		// make sure that the signer is authorized to mint NFTs
		require(signer == owner(), 'Signature invalid or unauthorized');
		//make sure the redeemer is paying enough to cover buyer's cost
		require(msg.value >= voucher.minPrice, 'Insufficent funds to redeem');
		uint256 tokenid = nft.mint(NFT.uri, address(this));
		listOfTokenIds.add(tokenid);
		TokenInfo storage Token = tokeninfo[tokenid];
		Token.nftId = voucher.nftid;
		Token.artist = NFT.artist;
		nft.safeTransferFrom(address(this), redeemer, tokenid);
		NFT.owner.push(address(this));
		return tokenid;
	}

	function _hash(NftVoucher calldata voucher) internal view returns (bytes32) {
		return
			_hashTypedDataV4(
				keccak256(
					abi.encode(
						keccak256('NFTVoucher(uint256 tokenId,uint256 minPrice,string uri)'),
						voucher.artist,
						voucher.minPrice,
						keccak256(bytes(voucher.uri))
					)
				)
			);
	}

	//@notice to verify the signature and signed data
	function _verify(NftVoucher calldata voucher) internal view returns (address) {
		bytes32 digest = _hash(voucher);
		return ECDSA.recover(digest, voucher.signature);
	}

	function getListOfTokenIds() public view returns (uint256[] memory) {
		return listOfTokenIds.values();
	}

	function getTokendetails(uint256 tokenid)
		public
		view
		override
		returns (
			string memory tokenuri,
			address owner,
			uint256 minprice,
			bool onSell,
			uint256 artistfee,
			uint256 galleryOwnerFee
		)
	{
		TokenInfo memory Token = tokeninfo[tokenid];
		address tokenowner = nft.ownerOf(tokenid);
		string memory uri = nft.tokenURI(tokenid);
		return (uri, tokenowner, Token.minprice, Token.onSell, Token.artistfee, Token.galleryOwnerfee);
	}

	function getListOfNfts() public view returns (bytes32[] memory) {
		return nftids.values();
	}

	function getNftdetails(bytes32 _nftid)
		public
		view
		override
		returns (
			string memory tokenuri,
			address[] memory owner,
			address minter
		)
	{
		NftInfo memory NFT = nftInfo[_nftid];
		return (NFT.uri, NFT.owner, NFT.minter);
	}

	function getListOfTokenOnSell() public view returns (uint256[] memory) {
		return listOfTokenIdsForSale.values();
	}

	function getBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function findHash(string memory _data) private pure returns (bytes32) {
		return keccak256(abi.encodePacked(_data));
	}

	function removeAddress(address[] storage ownerlist, address element) private returns (bool) {
		for (uint256 i = 0; i < ownerlist.length; i++) {
			if (ownerlist[i] == element) {
				ownerlist[i] = ownerlist[ownerlist.length - 1];
				ownerlist.pop();
				return true;
			}
		}
		return false;
	}
}