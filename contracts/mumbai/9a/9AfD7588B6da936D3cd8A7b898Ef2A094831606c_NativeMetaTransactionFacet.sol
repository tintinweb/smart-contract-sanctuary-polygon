// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../utils/EIP712Base.sol";
import "./../utils/FacetInitializable.sol";
import "./../utils/ContextMixin.sol";
import "./../interfaces/IMetaTransaction.sol";
import "openzeppelin4/utils/Context.sol";
import "openzeppelin4/utils/cryptography/ECDSA.sol";
import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";
import { LibMetaTransactionStorage as Storage } from "./../libraries/LibMetaTransactionStorage.sol";
import { LibMerkleProof } from "./../libraries/merkle/LibMerkleProof.sol";

// slither-disable-next-line locked-ether
contract NativeMetaTransactionFacet is IMetaTransaction, EIP712Base, ContextMixin, FacetInitializable {
    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);

    function initializeMetaTransaction() external initializer(Storage.getStorage().inited) {
        Storage.MetaTransactionStorage storage data = Storage.getStorage();
        data.domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes("KreatorhoodMarketplace")),
                keccak256(bytes(ERC712_VERSION)),
                getChainId(),
                address(this)
            )
        );
    }

    function getDomainSeparator() public view override returns (bytes32) {
        Storage.MetaTransactionStorage storage data = Storage.getStorage();
        return data.domainSeparator;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        Storage.MetaTransactionStorage storage data = Storage.getStorage();
        IMetaTransaction.MetaTransaction memory metaTx = MetaTransaction({
            nonce: data.nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        data.nonces[userAddress]++;

        emit MetaTransactionExecuted(userAddress, payable(_msgSender()), functionSignature);

        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));
        require(success, "Function call not successful");

        return returnData;
    }

    function getNonce(address user) external view override returns (uint256 nonce) {
        Storage.MetaTransactionStorage storage data = Storage.getStorage();
        nonce = data.nonces[user];
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Storage.META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return signer == ECDSA.recover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
    }

    function hashPayment(StructStorage.Payment memory payment) public pure returns (bytes32) {
        return keccak256(abi.encode(Storage.PAYMENT_TYPEHASH, payment.amount, payment.recipient));
    }

    function hashSplits(StructStorage.Splits memory splits, bytes32 tradeDataHash) public pure returns (bytes32) {
        uint256 paymentsLength = splits.payments.length;
        bytes32[] memory paymentsHashes = new bytes32[](paymentsLength);
        unchecked {
            for (uint256 i; i < paymentsLength; ++i) {
                // Hash the payment and place the result into memory.
                paymentsHashes[i] = hashPayment(splits.payments[i]);
            }
        }

        return
            keccak256(
                abi.encode(
                    Storage.SPLITS_TYPEHASH,
                    keccak256(abi.encodePacked(paymentsHashes)),
                    splits.actionExpiration,
                    splits.nonce,
                    splits.token,
                    tradeDataHash
                )
            );
    }

    function hashMints(StructStorage.MintData[] memory mints) public pure returns (bytes32) {
        uint256 mintsLength = mints.length;
        bytes32[] memory mintsHashes = new bytes32[](mintsLength);
        unchecked {
            for (uint256 i; i < mintsLength; ++i) {
                mintsHashes[i] = hashMintData(mints[i]);
            }
        }
        return keccak256(abi.encode(Storage.MINTS_TYPEHASH, keccak256(abi.encodePacked(mintsHashes))));
    }

    function hashMintData(StructStorage.MintData memory mintData) public pure returns (bytes32) {
        uint256 dropsLength = mintData.drops.length;
        bytes32[] memory drops = new bytes32[](dropsLength);
        // not unchecked because the whole method is unchecked when called from hashMints
        for (uint256 i; i < dropsLength; ++i) {
            drops[i] = hashDropData(mintData.drops[i]);
        }
        return
            keccak256(abi.encode(Storage.MINT_DATA_TYPEHASH, mintData.nftAddress, keccak256(abi.encodePacked(drops))));
    }

    function hashDropData(StructStorage.DropData memory dropData) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Storage.DROP_DATA_TYPEHASH,
                    dropData.dropId,
                    dropData.maxEditions,
                    dropData.mintEditions,
                    dropData.royaltiesPercent,
                    dropData.creatorAddress,
                    keccak256(bytes(dropData.tokenUri))
                )
            );
    }

    function hashSellData(StructStorage.SellData memory sellData) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    Storage.SELL_DATA_TYPEHASH,
                    sellData.seller,
                    sellData.nftAddress,
                    sellData.tokenId,
                    sellData.sellNonce,
                    sellData.expirationDate
                )
            );
    }

    function tryRecoverMerkleProofOrSellDataSigner(StructStorage.SellDTO calldata sellDTO) external view {
        uint256 length = sellDTO.sells.length;

        for (uint256 i; i < length; ) {
            bytes32 sellDataHash = hashSellData(sellDTO.sells[i]);
            uint256 proofLength = sellDTO.merkleTrees[i].proof.length;

            if (proofLength != 0) {
                if (proofLength > StructStorage.MAX_CALLDATA_PROOF_LENGTH) {
                    revert StructStorage.MERKLE_PROOF_TOO_LARGE(sellDTO.sells[i].sellNonce, proofLength);
                }

                if (
                    !LibMerkleProof.verifyProof(sellDTO.merkleTrees[i].proof, sellDTO.merkleTrees[i].root, sellDataHash)
                ) {
                    revert StructStorage.MERKLE_PROOF_INVALID(sellDTO.sells[i].sellNonce);
                }

                sellDataHash = Storage.hashBatchSellData(sellDTO.merkleTrees[i].root, proofLength);
            }
            (address signer, ECDSA.RecoverError err) = ECDSA.tryRecover(
                toTypedMessageHash(sellDataHash),
                sellDTO.sellerSignatures[i]
            );

            if (err != ECDSA.RecoverError.NoError) revert StructStorage.INVALID_SIGNATURE();
            if (sellDTO.sells[i].seller != signer) revert StructStorage.SELL_SIGNATURE(sellDTO.sells[i].sellNonce);

            unchecked {
                ++i;
            }
        }
    }

    function tryRecoverSplitsSigner(
        StructStorage.Splits calldata splits,
        bytes32 tradeDataHash
    ) external view returns (bool valid, address signer) {
        (address signer_, ECDSA.RecoverError err) = ECDSA.tryRecover(
            toTypedMessageHash(hashSplits(splits, tradeDataHash)),
            splits.signature
        );
        return (err == ECDSA.RecoverError.NoError, signer_);
    }

    function tryRecoverMintDataSigner(
        StructStorage.MintData[] calldata mintData,
        bytes calldata mintsSignature
    ) external view returns (bool valid, address signer) {
        (address signer_, ECDSA.RecoverError err) = ECDSA.tryRecover(
            toTypedMessageHash(hashMints(mintData)),
            mintsSignature
        );
        return (err == ECDSA.RecoverError.NoError, signer_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAccessControl {
    function initializeAccessControl(address fundsAdmin) external;

    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function setDiamondOwner(address newOwner) external;

    function getDiamondOwner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { LibStructStorage as StructStorage } from "./../libraries/LibStructStorage.sol";

interface IMetaTransaction {
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function initializeMetaTransaction() external;

    function tryRecoverSplitsSigner(
        StructStorage.Splits calldata splits,
        bytes32 tradeDataHash
    ) external view returns (bool valid, address signer);

    function tryRecoverMintDataSigner(
        StructStorage.MintData[] calldata dropData,
        bytes calldata mintsSignature
    ) external view returns (bool valid, address signer);

    function tryRecoverMerkleProofOrSellDataSigner(StructStorage.SellDTO calldata sellDTO) external view;

    function executeMetaTransaction(
        address userAddress,
        bytes calldata functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function getNonce(address user) external view returns (uint256 nonce);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";

library LibMetaTransactionStorage {
    bytes32 internal constant METATRANSACTION_STORAGE_SLOT = keccak256("KTHD.NATIVEMETATRANSACTION.STORAGE");

    bytes internal constant PAYMENT_TYPE = "Payment(uint256 amount,address recipient)";

    bytes internal constant SPLITS_TYPE =
        "Splits(Payment[] payments,uint256 actionExpiration,uint256 nonce,address token,bytes32 tradeDataHash)";

    bytes internal constant DROP_DATA_TYPE =
        "DropData(uint256 dropId,uint256 maxEditions,uint256 mintEditions,uint16 royaltiesPercent,address creatorAddress,string tokenUri)";

    bytes internal constant MINT_DATA_TYPE = "MintData(address nftAddress,DropData[] drops)";

    bytes internal constant SELL_DATA_TYPE =
        "SellData(address seller,address nftAddress,uint256 tokenId,uint256 sellNonce,uint256 expirationDate)";

    bytes32 internal constant META_TRANSACTION_TYPEHASH =
        keccak256("MetaTransaction(uint256 nonce,address from,bytes functionSignature)");

    bytes32 internal constant PAYMENT_TYPEHASH = keccak256(PAYMENT_TYPE);

    bytes32 internal constant SPLITS_TYPEHASH = keccak256(abi.encodePacked(SPLITS_TYPE, PAYMENT_TYPE));

    bytes32 internal constant DROP_DATA_TYPEHASH = keccak256(DROP_DATA_TYPE);

    bytes32 internal constant MINT_DATA_TYPEHASH = keccak256(abi.encodePacked(MINT_DATA_TYPE, DROP_DATA_TYPE));

    bytes32 internal constant MINTS_TYPEHASH =
        keccak256(abi.encodePacked("Mints(MintData[] mints)", DROP_DATA_TYPE, MINT_DATA_TYPE));

    bytes32 internal constant SELL_DATA_TYPEHASH = keccak256(SELL_DATA_TYPE);

    struct MetaTransactionStorage {
        LibStructStorage.InitFlag inited;
        bytes32 domainSeparator;
        mapping(address => uint256) nonces;
    }

    function getStorage() external pure returns (MetaTransactionStorage storage storageStruct) {
        bytes32 position = METATRANSACTION_STORAGE_SLOT;
        assembly {
            storageStruct.slot := position
        }
    }

    function hashBatchSellData(bytes32 root, uint256 proofLength) external pure returns (bytes32 batchOrderHash) {
        batchOrderHash = keccak256(abi.encode(_getBatchSellDataTypehash(proofLength), root));
    }

    /**
     * @dev It looks like this for each height:
     *      height == n: BatchSellData(SellData[2]...[2] tree)SellData(address seller,address nftAddress,uint256 tokenId,uint256 sellNonce,uint256 expirationDate)
     */
    function _getBatchSellDataTypehash(uint256 height) internal pure returns (bytes32 typehash) {
        if (height == 1) {
            typehash = hex"bcc5c167775dfab074989eaf90ffb9544eb1bdff926630cb8e92c3e8773dfa52";
        } else if (height == 2) {
            typehash = hex"20203ed4b830e5c48717e2df5dfe2ae6a6a4afd18a544df3c31e74dae6e557f2";
        } else if (height == 3) {
            typehash = hex"35e0c130769feb2635b43bed48a63b6522856d970f863613fc521073632617e3";
        } else if (height == 4) {
            typehash = hex"dac54b4f4d799dcb91def02c872430dc06f0bec74be9334703be36792759e073";
        } else if (height == 5) {
            typehash = hex"43fcf3f1d25d4cb83922aaedf35c1bdc824c5be4740575a6d11534999ae9a33a";
        } else if (height == 6) {
            typehash = hex"5e83a0bf06b6462d716e0e090be830e569d4b9a2add16178f4e77a87079f74ab";
        } else if (height == 7) {
            typehash = hex"b56abaa9ce702de85c66af7d7ade5594892a5f2c9710888d3dea4ac0674ee26f";
        } else if (height == 8) {
            typehash = hex"4074c7238c65a53743b7491b669ed2c1c000a236234e8f3831c4023569e8e506";
        } else if (height == 9) {
            typehash = hex"c5a83ae1bb471f052c5039842a4f7ac69331e0db147979b2bd9503fd8739ab86";
        } else if (height == 10) {
            typehash = hex"3e31961c790ef9db22a83d31c6f38daea1e328c33b45c27ef0108ab7cb2e9f00";
        } else {
            revert LibStructStorage.INVALID_PROOF_HEIGHT(height);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library LibStructStorage {
    //encoded roles
    bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant FUNDS_ADMIN_ROLE = keccak256("FUNDS_ADMIN_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    //numeric constants
    uint256 internal constant MAX_CALLDATA_PROOF_LENGTH = 10;

    //general
    error INVALID_SIGNATURE(); //0xa3402a38
    error EXTERNAL_ID_USED(uint256 externalId); //0xcf1823bf
    error PAYMENT_TOKEN_NOT_ACCEPTED(address tokenAddress); //0xb31d0d90

    //merkle proof
    error MERKLE_PROOF_TOO_LARGE(uint256 sellNonce, uint256 length); //0xc4ebf85a
    error MERKLE_PROOF_INVALID(uint256 sellNonce); //0x2e218f81
    error INVALID_PROOF_HEIGHT(uint256 height); //0x56e0614d

    //primary market
    error EDITION_LIMIT(uint256 dropId); //0x452a12bb
    error MINTS_SIGNATURE(bytes signature); //0x670079be

    //funds facet
    error FA_NATIVE_TRANSFER(); //0xe9dd4fbc
    error FA_DISTRIBUTOR_CALLER_TRANSFER(); //0x81522ab7

    //splits
    error SPLITS_EXPIRED(uint256 splitsNonce); //0x2eed249c
    error SPLITS_NONCE_INVALID(uint256 splitsNonce); //0x4cb00050
    error SPLITS_SIGNATURE(uint256 splitsNonce); //0xe9a2746d

    //sell and delist
    error SELL_NONCE_INVALID(uint256 sellNonce); //0x4d7b9199
    error SELL_DATA_EXPIRED(uint256 sellNonce); //0x209878c5
    error SELL_SIGNATURE(uint256 sellNonce); //0x5397bc4f
    error SELL_NONCE_ALREADY_CANCELED(uint256 sellNonce); //0x69df89fa
    error CALLER_NOT_OWNER_OR_SELLER(uint256 sellNonce); //0xe1efaf1e

    //role
    error MISSING_ROLE(bytes32 role); //0x6a9d0f78

    bytes4 internal constant IERC721_INTERFACE = 0x80ac58cd;

    enum MerkleNodePosition {
        Left,
        Right
    }

    struct MerkleNode {
        bytes32 value;
        MerkleNodePosition position;
    }

    struct MerkleTree {
        bytes32 root;
        MerkleNode[] proof;
    }

    struct SellData {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 sellNonce;
        uint256 expirationDate;
    }

    struct SellDTO {
        SellData[] sells;
        bytes[] sellerSignatures;
        MerkleTree[] merkleTrees;
    }

    struct Payment {
        uint256 amount;
        address recipient;
    }

    struct Splits {
        Payment[] payments;
        uint256 actionExpiration;
        address token;
        uint256 nonce;
        bytes signature;
    }

    struct DropData {
        uint dropId;
        uint maxEditions;
        uint mintEditions;
        uint16 royaltiesPercent;
        address creatorAddress;
        string tokenUri;
        string[] utilityIds;
    }

    struct MintData {
        address nftAddress;
        DropData[] drops;
    }

    /*
        @dev: DO NOT modify struct; doing so will break the diamond storage layout
    */
    struct InitFlag {
        bool inited;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// Libraries
import { LibStructStorage } from "../LibStructStorage.sol";

/**
 * @title LibMerkleProof
 * @notice This library is adjusted from the work of OpenZeppelin
 */
library LibMerkleProof {
    /**
     * @notice This returns true if a `leaf` can be proved to be a part of a Merkle tree defined by `root`.
     *         For this, a `proof` must be provided, containing sibling hashes on the branch from the leaf to the
     *         root of the tree. Each pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verifyProof(
        LibStructStorage.MerkleNode[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @notice This returns the rebuilt hash obtained by traversing a Merkle tree up from `leaf` using `proof`.
     *         A `proof` is valid if and only if the rebuilt hash matches the root of the tree.
     *         When processing the proof, the pairs of leafs & pre-images are assumed to be sorted.
     */
    function processProofCalldata(
        LibStructStorage.MerkleNode[] calldata proof,
        bytes32 leaf
    ) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        uint256 length = proof.length;

        for (uint256 i = 0; i < length; ) {
            if (proof[i].position == LibStructStorage.MerkleNodePosition.Left) {
                computedHash = _efficientHash(proof[i].value, computedHash);
            } else {
                computedHash = _efficientHash(computedHash, proof[i].value);
            }
            unchecked {
                ++i;
            }
        }
        return computedHash;
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
pragma solidity 0.8.13;

abstract contract ContextMixin {
    function _msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

abstract contract EIP712Base {
    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"));

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        uint256 chainId;
    }

    function getDomainSeparator() public view virtual returns (bytes32);

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";
import "./../utils/ContextMixin.sol";
import "./../interfaces/IAccessControl.sol";

abstract contract FacetInitializable is ContextMixin {
    modifier initializer(LibStructStorage.InitFlag storage flag) {
        require(!flag.inited, "already inited");
        _;
        flag.inited = true;
    }

    modifier only(bytes32 role) {
        if (!IAccessControl(address(this)).hasRole(role, msg.sender)) {
            revert LibStructStorage.MISSING_ROLE(role);
        }
        _;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}