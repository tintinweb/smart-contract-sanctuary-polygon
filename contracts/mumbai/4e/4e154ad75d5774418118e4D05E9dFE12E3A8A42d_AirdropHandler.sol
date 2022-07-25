// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "../common/Upgradeable.sol";
import "../utils/AssemblyUtils.sol";
import "../interfaces/INFTify1155.sol";
import "../interfaces/INFTify721.sol";

/**
 * receiver - The address who claims NFT
 * tokenIds - The list of NFT id
 * amounts - The amount of each NFT
 * types - The type of each NFT: 0 - 1155, 1 - 721
 * collections - The collection's address of each NFT
 * start - The event's start time
 * end - The event's end time
 */
struct AirdropClaim {
    address receiver;
    // uint256[] tokenIds;
    // uint256[] amounts;
    // uint256[] types;
    // address[] collections;
    uint256 start;
    uint256 end;
    uint256 limitation;
    uint256 nonce;
    bytes airdropEventSignature;
}

contract AirdropHandler is Upgradeable {
    using AssemblyUtils for uint256;

    uint256 private constant ERC_1155 = 0;
    uint256 private constant ERC_721 = 1;

    bytes32 public constant AIRDROP_CLAIM_REQUEST =
        keccak256(bytes("AIRDROP_CLAIM_REQUEST"));

    event AirdropClaimed(
        address receiver,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] types,
        address[] collections,
        string internalTxId
    );

    /**
     * @dev Claim NFTs from airdrop event
     * @param data [0] start, [1] end, [2] limitation, [3] transactionType, [4--] tokenIds, [..] amounts, [..] types
     * @param addr [0] receiver, [1] signer, [2--] collections
     * @param strs [0] internalTxId
     * @param signatures [0] airdropEventSignature, [1] airdropClaimSignature
     */
    function claimAirdrop(
        uint256[] memory data,
        address[] memory addr,
        string[] memory strs,
        bytes[] memory signatures
    ) public {
        uint256 quantity = addr.length - 2;
        address[] memory collections = new address[](quantity);
        uint256[] memory tokenIds = new uint256[](quantity);
        uint256[] memory amounts = new uint256[](quantity);
        uint256[] memory types = new uint256[](quantity);

        for (uint256 i = 0; i < quantity; i++) {
            collections[i] = addr[i + 2];
            tokenIds[i] = data[i + 3];
            amounts[i] = data[quantity + i + 3];
            types[i] = data[2 * quantity + i + 3];
        }

        /**
         * AirdropClaim
         */
        AirdropClaim memory airdrop = AirdropClaim({
            receiver: addr[0],
            // tokenIds: tokenIds,
            // amounts: amounts,
            // types: types,
            // collections: collections,
            start: data[0],
            end: data[1],
            limitation: data[2],
            nonce: _nonces[AIRDROP_CLAIM_REQUEST][addr[0]],
            airdropEventSignature: signatures[0]
        });

        {
            // CHECK: The airdrop event must not be cancelled before.
            require(
                !invalidAirdropEvent[airdrop.airdropEventSignature],
                "Event was cancelled"
            );

            // CHECK: The airdrop event must have been started
            require(
                block.timestamp >= airdrop.start,
                "Event has not been started"
            );

            // CHECK: The airdrop event must have not finished
            require(block.timestamp <= airdrop.end, "Event finished");

            // CHECK: The signer must be approved
            require(signers[addr[1]], "Only admin's signature");

            if (airdrop.limitation > 0) {
                // CHECK: The amount of the current airdrop claim must be still enough
                require(
                    airdrop.limitation >=
                        claimedAmount[airdrop.airdropEventSignature][
                            airdrop.receiver
                        ] +
                            quantity,
                    "Exceed the event's limitation"
                );
            }

            // VERIFY: airdropClaimSignature
            require(
                ECDSA.recover(
                    ECDSA.toEthSignedMessageHash(hash(airdrop)),
                    signatures[1]
                ) == addr[1],
                "Fail to verify the airdrop claim"
            );

            for (uint256 i = 0; i < quantity; i++) {
                if (types[i] == ERC_721) {
                    INFTify721(collections[i]).mint(
                        airdrop.receiver,
                        tokenIds[i],
                        ""
                    );
                } else if (types[i] == ERC_1155) {
                    INFTify1155(collections[i]).mint(
                        airdrop.receiver,
                        tokenIds[i],
                        amounts[i],
                        ""
                    );
                }
            }

            // TODO: Increase _nonces
            _nonces[AIRDROP_CLAIM_REQUEST][airdrop.receiver]++;

            // TODO: Increase the claimed amount
            claimedAmount[airdrop.airdropEventSignature][
                airdrop.receiver
            ] += quantity;

            emit AirdropClaimed(
                airdrop.receiver,
                tokenIds,
                amounts,
                types,
                collections,
                strs[0]
            );
        }
    }

    function hash(AirdropClaim memory airdrop)
        private
        pure
        returns (bytes32 digest)
    {
        // uint256 quantity = airdrop.collections.length;

        // uint256 size = (0x20 * (3 * quantity + 4)) +
        //     (0x14 * (quantity + 1)) +
        //     airdrop.airdropEventSignature.length;
        uint256 size = (0x20 * 4) + (0x14 * 1) + airdrop.airdropEventSignature.length;

        bytes memory array = new bytes(size);
        uint256 index;

        assembly {
            index := add(array, 0x20)
        }

        index = index.writeAddress(airdrop.receiver);

        // for (uint256 i = 0; i < quantity; i++) {
        //     index = index.writeUint256(airdrop.tokenIds[i]);
        // }

        // for (uint256 i = 0; i < quantity; i++) {
        //     index = index.writeUint256(airdrop.amounts[i]);
        // }

        // for (uint256 i = 0; i < quantity; i++) {
        //     index = index.writeUint256(airdrop.types[i]);
        // }

        // for (uint256 i = 0; i < quantity; i++) {
        //     index = index.writeAddress(airdrop.collections[i]);
        // }

        index = index.writeUint256(airdrop.start);
        index = index.writeUint256(airdrop.end);
        index = index.writeUint256(airdrop.limitation);
        index = index.writeUint256(airdrop.nonce);

        index = index.writeBytes(airdrop.airdropEventSignature);

        assembly {
            digest := keccak256(add(array, 0x20), size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
pragma solidity ^0.8.0;

import "./ReentrancyGuarded.sol";

abstract contract Upgradeable is ReentrancyGuarded {
    address public trustedForwarder;
    address public recipient;
    address public signatureUtils;

    address public feeUtils;
    address public offerHandler;
    address public boxUtils;
    mapping(bytes => bool) public openedBoxSignatures;

    mapping(address => bool) adminList;
    mapping(address => bool) public acceptedTokens;
    mapping(uint256 => uint256) public soldQuantity;
    mapping(bytes => bool) invalidSaleOrder;
    mapping(bytes => bool) invalidOffers;
    mapping(bytes => bool) acceptedOffers;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;
    /**
     * Change from `currentSaleOrderByTokenID` to `_nonces`
     */
    mapping(address => uint256) public nonces;
    mapping(address => uint256) public tokensFee;
    address public metaHandler;

    // address erc721NftAddress;
    mapping(bytes => mapping(address => uint256)) claimedAmount;
    // address erc721OfferHandlerAddress;
    mapping(bytes32 => mapping(address => uint256)) _nonces;
    // address erc721BuyHandlerAddress;
    mapping(bytes => bool) public invalidAirdropEvent;
    // address erc721OfferHandlerNativeAddress;
    address public airdropHandler;
    address erc721BuyHandlerNativeAddress;
    address offerHandlerNativeAddress;
    address public buyHandler;
    address sellHandlerAddress;
    address erc721SellHandlerAddress;
    address public featureHandler;
    address public sellHandler;
    address erc721SellHandlerNativeAddress;

    mapping(string => mapping(string => bool)) storeFeatures;
    mapping(string => mapping(address => uint256)) royaltyFeeAmount;
    address public cancelHandler;
    mapping(string => mapping(address => uint256)) featurePrice; // featureId => tokenAddress => price
    mapping(string => mapping(string => mapping(address => uint256))) featureStakedAmount; // storeID => featureID => address => amount
    mapping(address => bool) signers;

    mapping(address => mapping(uint8 => bool)) subAdminList;

    function _delegatecall(address _impl) internal {
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AssemblyUtils {
    function writeUint8(uint256 index, uint8 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore8(index, source)
            index := add(index, 0x1)
        }
        return index;
    }

    function writeAddress(uint256 index, address source)
        internal
        pure
        returns (uint256)
    {
        uint256 conv = uint256(uint160(source)) << 0x60;
        assembly {
            mstore(index, conv)
            index := add(index, 0x14)
        }
        return index;
    }

    function writeUint256(uint256 index, uint256 source)
        internal
        pure
        returns (uint256)
    {
        assembly {
            mstore(index, source)
            index := add(index, 0x20)
        }
        return index;
    }

    function writeBytes(uint256 index, bytes memory source)
        internal
        pure
        returns (uint256)
    {
        if (source.length > 0) {
            assembly {
                let length := mload(source)
                let end := add(source, add(0x20, length))
                let arrIndex := add(source, 0x20)
                let tempIndex := index
                for {

                } eq(lt(arrIndex, end), 1) {
                    arrIndex := add(arrIndex, 0x20)
                    tempIndex := add(tempIndex, 0x20)
                } {
                    mstore(tempIndex, mload(arrIndex))
                }
                index := add(index, length)
            }
        }
        return index;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTify1155 {
    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTify721 {
    function mint(
        address account,
        uint256 id,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;
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

pragma solidity ^0.8.0;

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }
}