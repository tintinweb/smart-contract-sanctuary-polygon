// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./../libraries/LibStructStorage.sol";

library LibFundsAdminStorage {
    bytes32 public constant FUNDSADMIN_STORAGE_SLOT = keccak256("KTHD.FUNDSADMIN.STORAGE");

    struct FundsAdminStorage {
        LibStructStorage.InitFlag inited;
        uint referenceBlockNumber;
        uint blocksPerDay;
    }

    function getStorage() external pure returns (FundsAdminStorage storage storageStruct) {
        bytes32 position = FUNDSADMIN_STORAGE_SLOT;
        assembly {
            storageStruct.slot := position
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