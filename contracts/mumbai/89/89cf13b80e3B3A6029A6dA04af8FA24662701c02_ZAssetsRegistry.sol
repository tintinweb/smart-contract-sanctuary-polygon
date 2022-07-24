// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { ERC20_TOKEN_TYPE, MAX_SCALE, zASSET_ENABLED, zASSET_UNKNOWN } from "./common/Constants.sol";
import "./errMsgs/ZAssetsRegistryErrMsgs.sol";
import "./common/ImmutableOwnable.sol";
import { ZAsset } from "./common/Types.sol";
import "./interfaces/IZAssetsRegistry.sol";

/**
 * @title ZAssetsRegistry
 * @author Pantherprotocol Contributors
 * @notice Registry and whitelist of assets (tokens) supported by the Panther
 * Protocol Multi-Asset Shielded Pool (aka "MASP")
 */
contract ZAssetsRegistry is ImmutableOwnable, IZAssetsRegistry {
    /**
    "zAsset" - abstraction of a token for representation in the MASP.
    ZK-circuits "treat" each zAsset as a unique (independent) token.
    `zAssetId` - ID of a zAsset.
    Circuits "know" a token by its zAssetID rather than the token addresses or
    its _tokenId/_id.
    Each distinguishable token supported by the MASP must be represented by its
    "own" zAsset. zAsset must never  "represent" two (or more) different tokens.
    An ERC-721/ERC-1155 token, with its unique _tokenId/_id, must "have" its own
    zAsset, different from zAssets of other tokens on the same contract.
    An ERC-20 token should be represented by at least one zAsset (further
    referred to as the "default" zAsset). A few other zAssets (aka "alternative"
    zAssets) may exist for the same ERC-20 token, with each zAsset having a
    different "scaling factor" (`ZAsset.scale`).

    `ZAsset` - a record on the Registry with parameters of zAsset(s).
    `zAssetRecId` - ID of a ZAsset record.
    Not every zAsset has its "own" ZAsset record, but each ZAsset keeps params
    of at least one zAsset. It groups all zAssets, which share the same token
    contract and the "scaling factor".
    There is just one ZAsset record for all zAssets representing tokens on an
    ERC-721/1155 contract. Thus, for any such supported contract there must be
    EXACTLY one ZAsset record on the Registry.
    Every zAsset representing an ERC-20 token must have its own ZAsset record.
    So, the Registry must have at LEAST one ZAsset (for the default zAsset) for
    an ERC-20 contract. However, other ZAsset records (for alternative zAssets)
    may exist for the same ERC-20 token.

    `subId` - additional ID which, coupled with the token contract address, let
    deterministically compute `zAssetId` and `zAssetRecId`.

    This code is written with the following specs in mind:
    - If at least one token on an ERC-721/ERC-1155 contract is whitelisted, any
      token on the contract is implicitly whitelisted w/o further configuration
    - Registry must have one ZAsset record only for all tokens of an ERC-721/
      ERC-1155 contract
    - ZAsset record of any zAsset, w/ exception of extremely rare cases, should
      be obtained with just a single SLOAD
    - Backward compatible upgrades should be able to implement ..
    -- .. separate whitelists of zAssets allowed for deposits and withdrawals
       (e.g. via extension of ZAsset.status)
    -- .. blacklist for some tokens on a whitelisted ERC-721/ERC-1155 contract
       (e.g. by extending ZAsset.tokenType and introducing a blacklist)
    -- .. limits per a zAsset for max allowed amounts of deposits/withdrawals
       (e.g. with "alternative" zAssets and re-defining ZAsset._unused)
    */

    // Mapping from `zAssetRecId` to ZAsset (i.e. params of an zAsset)
    mapping(uint160 => ZAsset) private _registry;

    // solhint-disable-next-line no-empty-blocks
    constructor(address _owner) ImmutableOwnable(_owner) {
        // Proxy-friendly: no storage initialization
    }

    function getZAssetId(address token, uint256 subId)
        public
        pure
        override
        returns (uint160)
    {
        // Being uint160, it is surely less then the FIELD_SIZE
        return
            uint160(
                uint256(
                    keccak256(
                        abi.encode(uint256(uint160(token)), uint256(subId))
                    )
                ) >> 96
            );
    }

    /// @notice Returns ZAsset record for the given record ID
    function getZAsset(uint160 zAssetRecId)
        public
        view
        override
        returns (ZAsset memory asset)
    {
        asset = _registry[zAssetRecId];
    }

    /// @notice Returns zAsset IDs and ZAsset record for the given token
    /// @param token Address of the token contract
    /// @param subId Extra ID to identify zAsset (0 by default)
    /// @dev For ERC-721/ERC-1155 token, `subId` is the _tokenId/_id. For  the
    // "default" zAsset of an ERC-20 token it is 0. For an "alternative" zAsset
    // it is the `defaultZAssetRecId XOR ver`, where `defaultZAssetRecId` is the
    // `zAssetRecId` of the default zAsset for this token, and `ver` is a unique
    // int in the range [1..31].
    /// @return zAssetId
    /// @return _tokenId ERC-721/1155 _tokenId/_id, if it's an NFT, or 0 for ERC-20
    /// @return zAssetRecId ID of the ZAsset record
    /// @return asset ZAsset record for the token
    function getZAssetAndIds(address token, uint256 subId)
        public
        view
        override
        returns (
            uint160 zAssetId,
            uint256 _tokenId,
            uint160 zAssetRecId,
            ZAsset memory asset
        )
    {
        // Gas optimized based on assumptions:
        // - most often, this code is called for the default zAsset of ERC-20
        // - if `ver` is in [1..31], highly likely, it is an alternative zAsset
        require(token != address(0), ERR_ZERO_TOKEN_ADDRESS);

        _tokenId = subId;
        if (subId != 0) {
            // for an "alternative" zAsset, `subId` must be none-zero, ...
            uint256 ver = uint256(uint160(token)) ^ subId;
            // ... and `ver` must be in [1..31]
            if (ver < 32 && ver != 0) {
                // Likely, it's the alternative zAsset w/ `zAssetRecId = subId`
                asset = _registry[uint160(subId)];

                if (asset.version == uint8(ver)) {
                    // Surely, it's the alternative zAsset of the ERC-20 token
                    // as `.version` must be 0 for NFTs and default zAssets.
                    // As `.version != 0`, `.status` can't be zASSET_UNKNOWN.
                    // Check `asset.tokenType == ERC20_TOKEN_TYPE` is skipped
                    // as the code registering ZAssets is assumed to ensure it.
                    zAssetId = getZAssetId(token, subId);
                    zAssetRecId = uint160(subId);
                    _tokenId = 0;
                    return (zAssetId, _tokenId, zAssetRecId, asset);
                }
            }
        }
        // The zAsset can't be an alternative zAsset of an ERC-20 token here.
        // It's either an NFT (`subId` is _tokenId), or the default zAsset of
        // an ERC-20 token (`subId` is 0). In both cases `asset.version == 0`.

        zAssetRecId = uint160(token); // same as `uint160(token) ^ 0`
        asset = _registry[zAssetRecId];
        if (asset.status == zASSET_UNKNOWN) {
            // Unknown token - return zero IDs, and empty ZAsset
            return (0, 0, 0, asset);
        }

        // For the default zAsset of an ERC-20 the `subId` must be 0
        require(
            subId == 0 || asset.tokenType != ERC20_TOKEN_TYPE,
            ERR_ZERO_SUBID_EXPECTED
        );
        zAssetId = getZAssetId(token, _tokenId);
        return (zAssetId, _tokenId, zAssetRecId, asset);
    }

    function isZAssetWhitelisted(uint160 zAssetRecId)
        external
        view
        override
        returns (bool)
    {
        ZAsset memory asset = _registry[zAssetRecId];
        return asset.status == zASSET_ENABLED;
    }

    /// @notice Register with the MASP a new asset with given params
    /// @param asset Params of the asset (including its `ZAsset.status`)
    /// @dev The "owner" may call only
    function addZAsset(ZAsset memory asset) external onlyOwner {
        require(asset.token != address(0), ERR_ZERO_TOKEN_ADDRESS);
        require(asset.status != zASSET_UNKNOWN, ERR_WRONG_ASSET_STATUS);
        require(
            // ERC-20 zAsset only may be "alternative" ones
            asset.version == 0 ||
                (asset.tokenType == ERC20_TOKEN_TYPE && asset.version < 32),
            ERR_WRONG_ASSET_VER
        );
        _checkScaleIsInRange(asset.scale);

        // note, `x ^ 0 == x`
        uint160 zAssetRecId = uint160(asset.token) ^ uint160(asset.version);

        ZAsset memory existingAsset = _registry[zAssetRecId];
        require(
            existingAsset.status == zASSET_UNKNOWN,
            ERR_ASSET_ALREADY_REGISTERED
        );
        _registry[zAssetRecId] = asset;
        emit AssetAdded(zAssetRecId, asset);
    }

    /// @notice Updates the status of the existing asset
    /// @param zAssetRecId ID of the ZAsset record
    /// @param newStatus Status to be set
    /// @dev The "owner" may call only
    function changeZAssetStatus(uint160 zAssetRecId, uint8 newStatus)
        external
        onlyOwner
    {
        require(_registry[zAssetRecId].token != address(0), ERR_UNKNOWN_ASSET);
        uint8 oldStatus = _registry[zAssetRecId].status;
        // New status value restrictions relaxed to allow for protocol updates.
        require(
            newStatus != zASSET_UNKNOWN && oldStatus != newStatus,
            ERR_WRONG_ASSET_STATUS
        );
        _registry[zAssetRecId].status = newStatus;
        emit AssetStatusChanged(zAssetRecId, newStatus, oldStatus);
    }

    function _checkScaleIsInRange(uint8 scale) private pure {
        //  Valid range is [0..31]
        require(scale < MAX_SCALE, ERR_WRONG_ASSET_SCALE);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

// Constants

uint256 constant IN_PRP_UTXOs = 1;
uint256 constant IN_UTXOs = 2 + IN_PRP_UTXOs;

uint256 constant OUT_PRP_UTXOs = 1;
uint256 constant OUT_UTXOs = 2 + OUT_PRP_UTXOs;

// Number of 32-bit words in the `secrets` of the `NewCommitment` events
uint256 constant UTXO_SECRETS = 4;
// Number of 32-bit words in the ciphertext in the "type 0" message
uint256 constant CIPERTEXT0_WORDS = 4;
// Number of 32-bit words in the ciphertext in the "type 1" message
uint256 constant CIPHERTEXT1_WORDS = 3;

// For overflow protection and circuits optimization
// (must be less than the FIELD_SIZE)
uint256 constant MAX_EXT_AMOUNT = 2**96;
uint256 constant MAX_IN_CIRCUIT_AMOUNT = 2**96;
uint256 constant MAX_TIMESTAMP = 2**32;
uint256 constant MAX_ZASSET_ID = 2**160;
uint8 constant MAX_SCALE = 32;

// Token types
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant ERC20_TOKEN_TYPE = 0x00;
uint8 constant ERC721_TOKEN_TYPE = 0x10;
uint8 constant ERC1155_TOKEN_TYPE = 0x11;
// defined for every tokenId rather than for all tokens on the contract
// (unsupported in the V0 and V1 of the MASP)
uint8 constant BY_TOKENID_TOKEN_TYPE = 0xFF;

// ZAsset statuses
// (not `enum` to let protocol extensions use bits, if needed)
uint8 constant zASSET_ENABLED = 0x01;
uint8 constant zASSET_DISABLED = 0x02;
uint8 constant zASSET_UNKNOWN = 0x00;

// UTXO data (opening values - encrypted and public) formats
uint8 constant UTXO_DATA_TYPE_ZERO = 0xA0; // no data (for zero UTXO)
uint8 constant UTXO_DATA_TYPE0 = 0xAA;
uint8 constant UTXO_DATA_TYPE1 = 0xAB;

// Address of the "virtual token contract" for PRPs.
// "Virtual" since PRP is NOT a token, and it does not have a token contract.
// Other contracts must use it to identify PRPs, whenever needed.
// Calculated as: keccak256('Privacy Reward Point') >> 96.
address constant PRP_VIRTUAL_CONTRACT = 0x1afa2212970b809aE15D51AF00C502D5c8eB3bAf;
// zAssetId (i.e. "token" in the UTXO preimage) of PRPs
// Other contracts must use it to encode/decode PRPs in UTXOs.
// Calculated as:
// uint160(
//   uint256(keccak256(abi.encode(uint256(PRP_VIRTUAL_CONTRACT), uint256(0)))) >> 96
// )`
uint160 constant PRP_ZASSET_ID = 0x000a1ebe17885f8603834b4c02054ce84cedf8756e;

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/// @title Staking
abstract contract ImmutableOwnable {
    /// @notice The owner who has privileged rights
    // solhint-disable-next-line var-name-mixedcase
    address public immutable OWNER;

    /// @dev Throws if called by any account other than the {OWNER}.
    modifier onlyOwner() {
        require(OWNER == msg.sender, "ImmOwn: unauthorized");
        _;
    }

    constructor(address _owner) {
        require(_owner != address(0), "ImmOwn: zero owner address");
        OWNER = _owner;
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

struct G1Point {
    uint256 x;
    uint256 y;
}

// Encoding of field elements is: X[0] * z + X[1]
struct G2Point {
    uint256[2] x;
    uint256[2] y;
}

// Verification key for SNARK
struct VerifyingKey {
    G1Point alpha1;
    G2Point beta2;
    G2Point gamma2;
    G2Point delta2;
    G1Point[2] ic;
}

struct SnarkProof {
    G1Point a;
    G2Point b;
    G1Point c;
}

struct PluginData {
    address contractAddress;
    bytes callData;
}

struct ElGamalCiphertext {
    G1Point c1;
    G1Point c2;
}

// For MASP V0 and V1
struct ZAsset {
    // reserved (for networkId, tokenIdPolicy. etc..)
    uint64 _unused;
    // 0x00 by default
    uint8 version;
    // Refer to Constants.sol
    uint8 status;
    // Refer to Constants.sol
    uint8 tokenType;
    // 0x00 - no scaling
    uint8 scale;
    // token contract address
    address token;
}

struct LockData {
    // Refer to Constants.sol
    uint8 tokenType;
    // Token contract address
    address token;
    // For ERC-721, ERC-1155 tokens
    uint256 tokenId;
    // The account to transfer the token from/to (on `lock`/`unlock`)
    address extAccount;
    // The token amount to transfer to/from the Vault (on `lock`/`unlock`)
    uint96 extAmount;
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

string constant ERR_ASSET_ALREADY_REGISTERED = "AR:E1";
string constant ERR_UNKNOWN_ASSET = "AR:E2";
string constant ERR_WRONG_ASSET_STATUS = "AR:E3";
string constant ERR_WRONG_ASSET_SCALE = "AR:E4";
string constant ERR_WRONG_ASSET_VER = "AR:E5";
string constant ERR_ZERO_SUBID_EXPECTED = "AR:E6";
string constant ERR_ZERO_TOKEN_ADDRESS = "AR:E7";

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { ZAsset } from "../common/Types.sol";

interface IZAssetsRegistry {
    /// @dev declared as view rather than pure to allow for protocol changes
    function getZAssetId(address token, uint256 subId)
        external
        view
        returns (uint160);

    function getZAssetAndIds(address token, uint256 subId)
        external
        view
        returns (
            uint160 zAssetId,
            uint256 _tokenId,
            uint160 zAssetRecId,
            ZAsset memory asset
        );

    function getZAsset(uint160 zAssetRecId)
        external
        view
        returns (ZAsset memory asset);

    function isZAssetWhitelisted(uint160 zAssetRecId)
        external
        view
        returns (bool);

    event AssetAdded(uint160 indexed zAssetRecId, ZAsset asset);
    event AssetStatusChanged(
        uint160 indexed zAssetRecId,
        uint8 newStatus,
        uint8 oldStatus
    );
}