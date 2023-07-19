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