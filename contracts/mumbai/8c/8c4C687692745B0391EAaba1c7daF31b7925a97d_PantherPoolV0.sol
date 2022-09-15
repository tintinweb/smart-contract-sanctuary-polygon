// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import "./common/Constants.sol";
import "./errMsgs/PantherPoolErrMsgs.sol";
import "./common/ImmutableOwnable.sol";
import "./common/NonReentrant.sol";
import "./common/Types.sol";
import "./common/Utils.sol";
import "./interfaces/IPrpGrantor.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IZAssetsRegistry.sol";
import "./common/Claimable.sol";
import "./pantherPool/AmountConvertor.sol";
import "./pantherPool/CommitmentGenerator.sol";
import "./pantherPool/CommitmentsTrees.sol";
import "./pantherPool/MerkleProofVerifier.sol";
import "./pantherPool/NullifierGenerator.sol";
import "./pantherPool/PubKeyGenerator.sol";

/**
 * @title PantherPool
 * @author Pantherprotocol Contributors
 * @notice Multi-Asset Shielded Pool main contract v0
 * @dev It is the "version 0" of the Panther Protocol Multi-Asset Shielded Pool ("MASP").
 * It locks assets (ERC-20, ERC-721 or ERC-1155 tokens) of a user with the `Vault` smart
 * contract and generates UTXO's in the MASP for the user (i.e. builds merkle trees of
 * UTXO's commitments).
 * It can also generate UTX0's with "Panther Reward Points" (aka "PRP", a special unit).
 * To get a PRP UTXO, a user must be given a "grant" booked in the `PrpGrantor` contract.
 * The present contract is assumed to have the "grant processor" role with the latest.
 * This contract does not implement the functionality for spending UTXO's (other than the
 * `exit` described further) and is supposed to be upgraded with the new one.
 * The new contract, the "v.1" of the MASP, is planned to implement spending of UTXO's
 * using zero-knowledge proves.
 * To be upgradable, this contract is assumed to run as an "implementation" for a proxy
 * that DELEGATECALL's the implementation.
 * To protect holders against lost of assets in case this contract is not upgraded, it
 * exposes the `exit` function, through which users may withdraw their locked assets via
 * revealing preimages of commitments.
 */
contract PantherPoolV0 is
    ImmutableOwnable,
    NonReentrant,
    Claimable,
    CommitmentsTrees,
    AmountConvertor,
    CommitmentGenerator,
    MerkleProofVerifier,
    NullifierGenerator,
    PubKeyGenerator,
    Utils
{
    // The contract is supposed to run behind a proxy DELEGATECALLing it.
    // On upgrades, adjust `__gap` to match changes of the storage layout.
    uint256[50] private __gap;

    // solhint-disable var-name-mixedcase

    /// @notice Address of the ZAssetRegistry contract
    address public immutable ASSET_REGISTRY;

    /// @notice Address of the Vault contract
    address public immutable VAULT;

    /// @notice Address of the PrpGrantor contract
    address public immutable PRP_GRANTOR;

    /// @notice (UNIX) Time since when the `exit` calls get enabled
    uint32 public exitTime;

    /// @notice Period (seconds) since `commitToExit` when `exit` opens
    // Needed to mitigate front-run attacks on `exit`
    uint24 public exitDelay;

    // (rest of the storage slot) reserved for upgrades
    uint200 private _reserved;

    // solhint-enable var-name-mixedcase

    // @notice Seen (i.e. spent) commitment nullifiers
    // nullifier hash => spent
    mapping(bytes32 => bool) public isSpent;

    /// @notice Unused registered commitments to exit
    // hash(privSpendKey, recipient) => commitment timestamp
    mapping(bytes32 => uint32) public exitCommitments;

    /// @dev Emitted when exit time and/or exit delay updated
    event ExitTimesUpdated(uint256 newExitTime, uint256 newExitDelay);

    /// @dev New nullifier has been seen
    event Nullifier(bytes32 nullifier);

    /// @dev A tiny disowned token amount gets locked in the Vault
    /// (as a result of imprecise scaling of deposited amounts)
    event Change(address indexed token, uint256 change);

    /// @dev New exit commitment registered
    event ExitCommitment(uint256 timestamp);

    /// @param _owner Address of the `OWNER` who may call `onlyOwner` methods
    /// @param assetRegistry Address of the ZAssetRegistry contract
    /// @param vault Address of the Vault contract
    /// @param prpGrantor Address of the PrpGrantor contract
    constructor(
        address _owner,
        address assetRegistry,
        address vault,
        address prpGrantor
    ) ImmutableOwnable(_owner) {
        require(TRIAD_SIZE == OUT_UTXOs, "E0");

        revertZeroAddress(assetRegistry);
        revertZeroAddress(vault);
        revertZeroAddress(prpGrantor);

        // As it runs behind the DELEGATECALL'ing proxy, initialization of
        // immutable "vars" only is allowed in the constructor

        ASSET_REGISTRY = assetRegistry;
        VAULT = vault;
        PRP_GRANTOR = prpGrantor;
    }

    /// @notice Update the exit time and the exit delay
    /// @dev Owner only may calls
    function updateExitTimes(uint32 newExitTime, uint24 newExitDelay)
        public
        onlyOwner
    {
        require(
            newExitTime >= exitTime &&
                newExitTime < MAX_TIMESTAMP &&
                newExitDelay != 0,
            "E1"
        );

        exitTime = newExitTime;
        exitDelay = newExitDelay;

        emit ExitTimesUpdated(uint256(newExitTime), uint256(newExitDelay));
    }

    /// @notice Transfer assets from the msg.sender to the VAULT and generate UTXOs in the MASP
    /// @param tokens Address of the token contract for every UTXO
    /// @dev For PRP granted the address ot this contract (proxy) is supposed to be used
    /// @param tokenIds For ERC-721 and ERC-1155 - token ID or subId of the token, 0 for ERC-20
    /// @param amounts Token amounts (unscaled) to be deposited
    /// @param pubSpendingKeys Public Spending Key for every UTXO
    /// @param secrets Encrypted opening values for every UTXO
    /// @param createdAt Optional, if 0 the network time used
    /// @dev createdAt must be less (or equal) the network time
    /// @return leftLeafId The `leafId` of the first UTXO (leaf) in the batch
    function generateDeposits(
        address[OUT_UTXOs] calldata tokens,
        uint256[OUT_UTXOs] calldata tokenIds,
        uint256[OUT_UTXOs] calldata amounts,
        G1Point[OUT_UTXOs] calldata pubSpendingKeys,
        uint256[CIPHERTEXT1_WORDS][OUT_UTXOs] calldata secrets,
        uint32 createdAt
    ) external nonReentrant returns (uint256 leftLeafId) {
        require(exitTime > 0, ERR_UNCONFIGURED_EXIT_TIME);

        uint32 timestamp = safe32TimeNow();
        if (createdAt != 0) {
            require(createdAt <= timestamp, ERR_TOO_EARLY_CREATED_AT);
            timestamp = createdAt;
        }

        bytes32[OUT_UTXOs] memory commitments;
        bytes[OUT_UTXOs] memory perUtxoData;

        for (uint256 utxoIndex = 0; utxoIndex < OUT_UTXOs; utxoIndex++) {
            (uint160 zAssetId, uint96 scaledAmount) = _processDepositedAsset(
                tokens[utxoIndex],
                tokenIds[utxoIndex],
                amounts[utxoIndex]
            );

            if (scaledAmount == 0) {
                // At least the 1st deposited amount shall be non-zero
                require(utxoIndex != 0, ERR_ZERO_DEPOSIT);

                // the zero UTXO
                commitments[utxoIndex] = ZERO_VALUE;
                perUtxoData[utxoIndex] = abi.encodePacked(UTXO_DATA_TYPE_ZERO);
            } else {
                // non-zero UTXO
                commitments[utxoIndex] = generateCommitment(
                    pubSpendingKeys[utxoIndex].x,
                    pubSpendingKeys[utxoIndex].y,
                    scaledAmount,
                    zAssetId,
                    timestamp
                );

                uint256 tokenAndAmount = (uint256(uint160(tokens[utxoIndex])) <<
                    96) | uint256(scaledAmount);
                perUtxoData[utxoIndex] = abi.encodePacked(
                    uint8(UTXO_DATA_TYPE1),
                    secrets[utxoIndex],
                    tokenAndAmount,
                    tokenIds[utxoIndex]
                );
            }
        }

        leftLeafId = addAndEmitCommitments(commitments, perUtxoData, timestamp);
    }

    /// @notice Register future `exit` to protect against front-run and DoS.
    /// The `exit` is possible only after `exitDelay` since this function call.
    /// @param exitCommitment Commitment to the UTXO spending key and the recipient address.
    /// MUST be equal to keccak256(abi.encode(uint256(privSpendingKey), address(recipient)).
    function commitToExit(bytes32 exitCommitment) external {
        require(
            exitCommitments[exitCommitment] == uint32(0),
            ERR_EXITCOMMIT_EXISTS
        );
        uint32 timestamp = safe32TimeNow();
        exitCommitments[exitCommitment] = timestamp;
        emit ExitCommitment(timestamp);
    }

    /// @notice Spend an UTXO in the MASP and withdraw the asset from the Vault to the msg.sender.
    /// This function call must be registered in advance with `commitToExit`.
    /// @param token Address of the token contract
    /// @param subId '_tokenId'/'_id' for ERC-721/1155, 0 for the "default" zAsset of an ERC-20 token,
    // or `subId` for an "alternative" zAsset of an ERC-20 (see ZAssetRegistry.sol for details)
    /// @param scaledAmount Token scaled amount
    /// @param privSpendingKey UTXO's Private Spending Key
    /// @param leafId Id of the leaf with the UTXO commitments in the Merkle Trees
    /// @param pathElements Elements of the Merkle proof of inclusion
    /// @param merkleRoot The root of the Merkle Tree the leaf is a part of
    /// @param cacheIndexHint Index of the `merkleRoot` in the cache of roots, 0 by default
    /// @dev `cacheIndexHint` needed for the "current" (partially populated) tree only
    function exit(
        address token,
        uint256 subId,
        uint96 scaledAmount,
        uint32 creationTime,
        uint256 privSpendingKey,
        uint256 leafId,
        bytes32[TREE_DEPTH + 1] calldata pathElements,
        bytes32 merkleRoot,
        uint256 cacheIndexHint
    ) external nonReentrant {
        require(safe32TimeNow() >= exitTime, ERR_TOO_EARLY_EXIT);
        _verifyExitCommitment(privSpendingKey, msg.sender);

        {
            bytes32 nullifier = generateNullifier(privSpendingKey, leafId);
            require(!isSpent[nullifier], ERR_SPENT_NULLIFIER);
            isSpent[nullifier] = true;
            emit Nullifier(nullifier);
        }
        require(
            isKnownRoot(getTreeId(leafId), merkleRoot, cacheIndexHint),
            ERR_UNKNOWN_MERKLE_ROOT
        );

        ZAsset memory asset;
        uint256 _tokenId;
        {
            bytes32 commitment;
            {
                uint160 zAssetId;
                {
                    (zAssetId, _tokenId, , asset) = IZAssetsRegistry(
                        ASSET_REGISTRY
                    ).getZAssetAndIds(token, subId);
                    require(asset.status == zASSET_ENABLED, ERR_WRONG_ASSET);
                }
                G1Point memory pubSpendingKey = generatePubSpendingKey(
                    privSpendingKey
                );
                commitment = generateCommitment(
                    pubSpendingKey.x,
                    pubSpendingKey.y,
                    scaledAmount,
                    zAssetId,
                    creationTime
                );
            }
            verifyMerkleProof(
                merkleRoot,
                _getTriadIndex(leafId),
                _getTriadNodeIndex(leafId),
                commitment,
                pathElements
            );
        }

        uint96 amount = _unscaleAmount(scaledAmount, asset.scale);
        IVault(VAULT).unlockAsset(
            LockData(asset.tokenType, token, _tokenId, msg.sender, amount)
        );
    }

    /// @notice Withdraw accidentally sent tokens or ETH from this contract
    /// @dev The "owner" may call only
    function claimEthOrErc20(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner nonReentrant {
        _claimEthOrErc20(token, to, amount);
    }

    /// Internal and private functions follow

    // Declared `internal` rather than `private` to ease testing
    function _processDepositedAsset(
        address token,
        uint256 subId,
        uint256 amount
    ) internal returns (uint160 zAssetId, uint96 scaledAmount) {
        // Do nothing if it's the "zero" (or "dummy") deposit
        if (amount == 0) {
            // Both token and subId must be zeros for the "zero" deposit
            require(token == address(0) && subId == 0, ERR_WRONG_DEPOSIT);
            return (0, 0);
        }
        // amount can't be zero here and further

        // Use a PRP grant, if it's a "deposit" in PRPs
        if (token == PRP_VIRTUAL_CONTRACT) {
            require(subId == 0, ERR_WRONG_PRP_SUBID);
            // Check amount is within the limit (no amount scaling for PRPs)
            uint96 _sanitizedAmount = _sanitizeScaledAmount(amount);
            // No reentrancy guard needed for the trusted contract call
            IPrpGrantor(PRP_GRANTOR).redeemGrant(msg.sender, amount);
            return (PRP_ZASSET_ID, _sanitizedAmount);
        }

        // At this point, a non-zero deposit of a real asset (token) expected
        uint256 _tokenId;
        ZAsset memory asset;
        (zAssetId, _tokenId, , asset) = IZAssetsRegistry(ASSET_REGISTRY)
            .getZAssetAndIds(token, subId);
        require(asset.status == zASSET_ENABLED, ERR_WRONG_ASSET);

        // Scale amount, if asset.scale provides for it (ERC-20 only)
        uint256 change;
        (scaledAmount, change) = _scaleAmount(amount, asset.scale);

        // The `change` will remain locked in the Vault until it's claimed
        // (when and if future upgrades implement change claiming)
        if (change > 0) emit Change(token, change);

        IVault(VAULT).lockAsset(
            LockData(
                asset.tokenType,
                asset.token,
                _tokenId,
                msg.sender,
                uint96(amount)
            )
        );

        return (zAssetId, scaledAmount);
    }

    function _verifyExitCommitment(uint256 privSpendingKey, address recipient)
        internal
    {
        bytes32 commitment = keccak256(abi.encode(privSpendingKey, recipient));

        uint32 commitmentTime = exitCommitments[commitment];
        require(commitmentTime != uint32(0), ERR_EXITCOMMIT_MISSING);

        uint256 allowedTime = uint256(commitmentTime) + uint256(exitDelay);
        require(timeNow() > allowedTime, ERR_EXITCOMMIT_LOCKED);

        // Let's gain some gas back
        exitCommitments[commitment] = uint32(0);
        // No extra event emitted as spent UTXO and withdrawal events will fire
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

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

// CommitmentGenerator contract
string constant ERR_TOO_LARGE_PUBKEY = "CG:E1";

// CommitmentsTrees contract
string constant ERR_TOO_LARGE_COMMITMENTS = "CT:E1"; // commitment exceeds maximum scalar field size

// MerkleProofVerifier
string constant ERR_MERKLE_PROOF_VERIFICATION_FAILED = "MP:E1";
string constant ERR_TRIAD_INDEX_MIN_VALUE = "MP:E2";
string constant ERR_TRIAD_INDEX_MAX_VALUE = "MP:E3";

// TriadIncrementalMerkleTrees contract
string constant ERR_ZERO_ROOT = "TT:E1"; // merkle tree root can not be zero

// PantherPool contract
string constant ERR_DEPOSIT_OVER_LIMIT = "PP:E1";
string constant ERR_DEPOSIT_FROM_ZERO_ADDRESS = "PP:E2";
string constant ERR_EXITCOMMIT_EXISTS = "PP:E32";
string constant ERR_EXITCOMMIT_LOCKED = "PP:E33";
string constant ERR_EXITCOMMIT_MISSING = "PP:E34";
string constant ERR_EXPIRED_TX_TIME = "PP:E3";
string constant ERR_INVALID_JOIN_INPUT = "PP:E4";
string constant ERR_INVALID_PROOF = "PP:E5";
string constant ERR_MISMATCHED_ARR_LENGTH = "PP:E6";
string constant ERR_PLUGIN_FAILURE = "PP:E7";
string constant ERR_SPENT_NULLIFIER = "PP:E8";
string constant ERR_TOO_EARLY_CREATED_AT = "PP:E9";
string constant ERR_TOO_EARLY_EXIT = "PP:E30";
string constant ERR_TOO_LARGE_AMOUNT = "PP:E10";
string constant ERR_TOO_LARGE_COMMITMENT = "PP:E11";
string constant ERR_TOO_LARGE_NULLIFIER = "PP:E12";
string constant ERR_TOO_LARGE_LEAFID = "PP:E27";
string constant ERR_TOO_LARGE_PRIVKEY = "PP:E28";
string constant ERR_TOO_LARGE_ROOT = "PP:E13";
string constant ERR_TOO_LARGE_SCALED_AMOUNT = "PP:E26";
string constant ERR_TOO_LARGE_TIME = "PP:E14";
string constant ERR_UNCONFIGURED_EXIT_TIME = "PP:E31";
string constant ERR_UNKNOWN_MERKLE_ROOT = "PP:E16";
string constant ERR_WITHDRAW_OVER_LIMIT = "PP:E17";
string constant ERR_WITHDRAW_TO_ZERO_ADDRESS = "PP:E18";
string constant ERR_WRONG_ASSET = "PP:E19";
string constant ERR_WRONG_DEPOSIT = "PP:E29";
string constant ERR_WRONG_PRP_SUBID = "PP:E25";
string constant ERR_ZERO_DEPOSIT = "PP:E21";
string constant ERR_ZERO_FEE_PAYER = "PP:E22";
string constant ERR_ZERO_TOKEN_EXPECTED = "PP:E23";
string constant ERR_ZERO_TOKEN_UNEXPECTED = "PP:E24";

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
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

/**
 * @title NonReentrant
 * @notice It provides reentrancy guard.
 * The code borrowed from openzeppelin-contracts.
 * Unlike original, this version requires neither `constructor` no `init` call.
 */
abstract contract NonReentrant {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _reentrancyStatus;

    modifier nonReentrant() {
        // Being called right after deployment, when _reentrancyStatus is 0 ,
        // it does not revert (which is expected behaviour)
        require(_reentrancyStatus != _ENTERED, "claimErc20: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _NOT_ENTERED;
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

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

abstract contract Utils {
    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, "UNSAFE32");
        return uint32(n);
    }

    function safe96(uint256 n) internal pure returns (uint96) {
        require(n < 2**96, "UNSAFE96");
        return uint96(n);
    }

    function safe128(uint256 n) internal pure returns (uint128) {
        require(n < 2**128, "UNSAFE128");
        return uint128(n);
    }

    function safe160(uint256 n) internal pure returns (uint160) {
        require(n < 2**160, "UNSAFE160");
        return uint160(n);
    }

    function safe32TimeNow() internal view returns (uint32) {
        return safe32(timeNow());
    }

    function safe32BlockNow() internal view returns (uint32) {
        return safe32(blockNow());
    }

    /// @dev Returns the current block timestamp (added to ease testing)
    function timeNow() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /// @dev Returns the current block number (added to ease testing)
    function blockNow() internal view virtual returns (uint256) {
        return block.number;
    }

    function revertZeroAddress(address account) internal pure {
        require(account != address(0), "UNEXPECTED_ZERO_ADDRESS");
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

/**
 * @title IPrpGrantor
 * @notice Interface for the `PrpGrantor` contract
 * @dev Excluding `onlyOwner` functions
 */
interface IPrpGrantor {
    /// @notice Return the address of the "grant processor"
    /// @dev This account only is authorized to call `redeemGrant`
    function grantProcessor() external view returns (address);

    /// @notice Returns the total amount (in PRPs) of grants issued so far
    /// (excluding burnt grants)
    function totalGrantsIssued() external returns (uint256);

    /// @notice Returns the total amount (in PRPs) of grants redeemed so far
    function totalGrantsRedeemed() external returns (uint256);

    /// @notice Returns the total amount (in PRPs) of unused grants for the given grantee
    function getUnusedGrantAmount(address grantee)
        external
        view
        returns (uint256 prpAmount);

    /// @notice Returns the PRP amount of the grant specified by a given curator and type
    function getGrantAmount(address curator, bytes4 grantType)
        external
        view
        returns (uint256 prpAmount);

    /// @notice Increase the amount of "unused" grants for the given grantee, by the amount
    /// defined for the given "grant type"
    /// @return prpAmount The amount (in PRPs) of the grant
    /// @dev An authorized "curator" may call with the enabled (added) "grant type" only
    function issueGrant(address grantee, bytes4 grantType)
        external
        returns (uint256 prpAmount);

    /// @notice Increase the amount of "unused" grants for the given grantee, by the amount
    /// specified.
    /// @dev Only the owner may call.
    function issueOwnerGrant(address grantee, uint256 prpAmount) external;

    /// @notice Burn unused grants for the msg.sender in the specified PRP amount
    function burnGrant(uint256 prpAmount) external;

    /// @notice Account for redemption of grants in the given amount for the given grantee
    /// @dev Only the account returned by `grantProcessor()` may call
    function redeemGrant(address grantee, uint256 prpAmount) external;

    /// @notice PRP grant issued
    event PrpGrantIssued(
        bytes4 indexed grantType,
        address grantee,
        uint256 prpAmount
    );

    /// @notice PRP grant redeemed (used)
    event PrpGrantRedeemed(address grantee, uint256 prpAmount);

    /// @notice PRP grant burnt
    event PrpGrantBurnt(address grantee, uint256 prpAmount);

    /// @notice New grant type added
    event PrpGrantEnabled(address curator, bytes4 grantType, uint256 prpAmount);

    /// @notice Existing grant type disabled
    event PrpGrantDisabled(address curator, bytes4 grantType);
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { LockData } from "../common/Types.sol";

interface IVault {
    function lockAsset(LockData calldata data) external;

    function unlockAsset(LockData memory data) external;

    event Locked(LockData data);
    event Unlocked(LockData data);
}

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

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable-next-line compiler-fixed, compiler-gt-0_8
pragma solidity ^0.8.0;

import "./TransferHelper.sol";

/**
 * @title Claimable
 * @notice It withdraws accidentally sent tokens or ETH from this contract.
 */
abstract contract Claimable {
    /// @dev Withdraws ERC20 tokens from this contract
    /// (take care of reentrancy attack risk mitigation)
    function _claimEthOrErc20(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (token == address(0)) {
            // withdraw ETH
            TransferHelper.safeTransferETH(to, amount);
        } else {
            // withdraw ERC20
            TransferHelper.safeTransfer(token, to, amount);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { MAX_EXT_AMOUNT, MAX_IN_CIRCUIT_AMOUNT } from "../common/Constants.sol";
import { ERR_TOO_LARGE_AMOUNT, ERR_TOO_LARGE_SCALED_AMOUNT } from "../errMsgs/PantherPoolErrMsgs.sol";

/**
 * @title AmountConvertor
 * @author Pantherprotocol Contributors
 * @notice Methods for scaling amounts for computations within/outside the
 * Panther Protocol Multi-Asset Shielded Pool (aka "MASP")
 */
abstract contract AmountConvertor {
    // "Scaled amounts" - amounts ZK-circuits of the MASP operate with
    // "Unscaled amounts" - amounts token contracts operate with
    // Scaling is relevant for fungible tokens only - for ERC-721/ERC-1155
    // tokens, scaled and unscaled amounts MUST be equal. For some ERC-20
    // tokens, the "scaling factor" MAY be 1:1, i.e. scaled and unscaled
    // amounts are equal.

    // Conversion from the unscaled amount (aka amount) to the scaled one.
    // Returns the scaled amount and the reminder.
    function _scaleAmount(uint256 amount, uint8 scale)
        internal
        pure
        returns (uint96 scaledAmount, uint256 change)
    {
        uint256 _scaledAmount;
        if (scale == 0) {
            // No scaling and no change for zero `scale`
            _scaledAmount = amount;
            change = 0;
        } else {
            unchecked {
                uint256 factor = _getScalingFactor(scale);
                // divider can't be zero
                _scaledAmount = amount / factor;
                // `restoredAmount` can not exceed the `amount`
                uint256 restoredAmount = _scaledAmount * factor;
                change = amount - restoredAmount;
            }
        }
        scaledAmount = _sanitizeScaledAmount(_scaledAmount);
    }

    // Conversion from the scaled amount to unscaled one.
    // Returns the unscaled amount.
    function _unscaleAmount(uint96 scaledAmount, uint8 scale)
        internal
        pure
        returns (uint96)
    {
        uint256 amount = scale == 0
            ? scaledAmount // no scaling
            : uint256(scaledAmount) * _getScalingFactor(scale);
        return _sanitizeAmount(amount);
    }

    function _sanitizeAmount(uint256 amount) internal pure returns (uint96) {
        require(amount < MAX_EXT_AMOUNT, ERR_TOO_LARGE_AMOUNT);
        return uint96(amount);
    }

    function _sanitizeScaledAmount(uint256 scaledAmount)
        internal
        pure
        returns (uint96)
    {
        require(
            scaledAmount < MAX_IN_CIRCUIT_AMOUNT,
            ERR_TOO_LARGE_SCALED_AMOUNT
        );
        return uint96(scaledAmount);
    }

    /// Private functions follow

    // Note: implementation accepts 0..255 values for nonZeroScale
    // It is responsibility of the caller check it is indeed less than 255 since 10^255 overflows uint256
    // This overflow check not implemented here since caller will implement it in upper level
    function _getScalingFactor(uint8 nonZeroScale)
        private
        pure
        returns (uint256)
    {
        return 10**nonZeroScale;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { PoseidonT6 } from "../crypto/Poseidon.sol";

import { ERR_TOO_LARGE_PUBKEY } from "../errMsgs/PantherPoolErrMsgs.sol";
import { FIELD_SIZE } from "../crypto/SnarkConstants.sol";

abstract contract CommitmentGenerator {
    /// Generate UTXOs, these UTXOs will be used later
    /// @param pubSpendingKeyX Public Spending Key for every UTXO - 256 bit - used in circom
    /// @param pubSpendingKeyY Public Spending Key for every UTXO - 256 bit - used in circom
    /// @param scaledAmount 96 bit size - used in circom
    /// @param zAssetId 160 bit size - used in circom
    /// @param creationTime 32 bit size - used in circom
    function generateCommitment(
        uint256 pubSpendingKeyX,
        uint256 pubSpendingKeyY,
        uint96 scaledAmount,
        uint160 zAssetId,
        uint32 creationTime
    ) internal pure returns (bytes32 commitment) {
        require(
            pubSpendingKeyX <= FIELD_SIZE && pubSpendingKeyY <= FIELD_SIZE,
            ERR_TOO_LARGE_PUBKEY
        );
        // Being 160 bits and less, other input params can't exceed FIELD_SIZE

        commitment = PoseidonT6.poseidon(
            [
                bytes32(pubSpendingKeyX),
                bytes32(pubSpendingKeyY),
                bytes32(uint256(scaledAmount)),
                bytes32(uint256(zAssetId)),
                bytes32(uint256(creationTime))
            ]
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import "../triadTree/TriadIncrementalMerkleTrees.sol";
import { OUT_UTXOs, UTXO_SECRETS } from "../common/Constants.sol";
import { ERR_TOO_LARGE_COMMITMENTS } from "../errMsgs/PantherPoolErrMsgs.sol";

/**
 * @title CommitmentsTrees
 * @author Pantherprotocol Contributors
 * @notice Incremental Merkle trees of commitments for the `PantherPool` contract
 */
abstract contract CommitmentsTrees is TriadIncrementalMerkleTrees {
    /**
     * @dev Emitted on a new batch of Commitments
     * @param leftLeafId The `leafId` of the first leaf in the batch
     * @dev `leafId = leftLeafId + 1` for the 2nd leaf (`leftLeafId + 2` for the 3rd leaf)
     * @param commitments Commitments hashes
     * @param utxoData opening values (encrypted and public) for UTXOs
     */
    event NewCommitments(
        uint256 indexed leftLeafId,
        uint256 creationTime,
        bytes32[OUT_UTXOs] commitments,
        bytes utxoData
    );

    /**
     * @notice Adds commitments to merkle tree(s) and emits events
     * @param commitments Commitments (leaves hashes) to be inserted into merkle tree(s)
     * @param perUtxoData opening values (encrypted and public) for every UTXO
     * @return leftLeafId The `leafId` of the first leaf in the batch
     */
    function addAndEmitCommitments(
        bytes32[OUT_UTXOs] memory commitments,
        bytes[OUT_UTXOs] memory perUtxoData,
        uint256 timestamp
    ) internal returns (uint256 leftLeafId) {
        bytes memory utxoData = "";
        for (uint256 i = 0; i < OUT_UTXOs; i++) {
            require(
                uint256(commitments[i]) < FIELD_SIZE,
                ERR_TOO_LARGE_COMMITMENTS
            );
            utxoData = bytes.concat(utxoData, perUtxoData[i]);
        }

        // Insert hashes into Merkle tree(s)
        leftLeafId = insertBatch(commitments);

        emit NewCommitments(leftLeafId, timestamp, commitments, utxoData);
    }

    // NOTE: The contract is supposed to run behind a proxy DELEGATECALLing it.
    // For compatibility on upgrades, decrease `__gap` if new variables added.
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { PoseidonT3, PoseidonT4 } from "../crypto/Poseidon.sol";
import "../errMsgs/PantherPoolErrMsgs.sol";
import "../triadTree/TriadIncrementalMerkleTrees.sol";

abstract contract MerkleProofVerifier {
    // @dev Number of levels in a tree excluding the root level
    // (also defined in scripts/generateTriadMerkleZeroesContracts.sh)
    uint256 private constant TREE_DEPTH = 15;

    //t |bH  bL| Subtree
    //--|------|------------
    //0 | 0  0 | hash(C,L,R)
    //1 | 0  1 | hash(L,C,R)
    //2 | 1  0 | hash(L,R,C)
    //3 | 1  1 | Not allowed
    //--|------|------------
    // Current leaf index in triad is (C,L,R)
    uint256 private constant iTRIAD_INDEX_LEFT = 0x0;
    // Current leaf index in triad is (L,C,R)
    uint256 private constant iTRIAD_INDEX_MIDDLE = 0x1;
    // Current leaf index in triad is (L,R,C)
    uint256 private constant iTRIAD_INDEX_RIGHT = 0x2;
    // Forbidden triad value in tria is `11`
    uint256 private constant iTRIAD_INDEX_FORBIDDEN = 0x3;

    /// @param merkleRoot - verify checked to this hash
    /// @param triadIndex - index inside triad = { 0, 1, 2 }
    /// @param triadNodeIndex - index of triad hash ( c0,c1,c2 ) in the tree - Triad contract insures its is in range
    /// @param leaf - commitment leaf value
    /// @param pathElements - TREE_DEPTH + 1 elements - c1,c2 & path-elements
    /// @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
    /// @dev defined by `root`. For this, a `proof` must be provided, containing
    /// @dev sibling hashes on the branch from the leaf to the root of the tree.
    function verifyMerkleProof(
        bytes32 merkleRoot,
        uint256 triadIndex,
        uint256 triadNodeIndex,
        bytes32 leaf,
        bytes32[TREE_DEPTH + 1] calldata pathElements
    ) public pure {
        // [0] - Assumed it is computed by the TriadIncrementalMerkleTrees
        //       using modulo operation, so no need to check lower range
        //require(iTRIAD_INDEX_LEFT <= triadIndex, ERR_TRIAD_INDEX_MIN_VALUE);
        require(triadIndex < iTRIAD_INDEX_FORBIDDEN, ERR_TRIAD_INDEX_MAX_VALUE);

        // [1] - Compute zero level hash
        bytes32 nodeHash;
        // NOTE: no else-case needed since this code executed after require at step [0]
        if (triadIndex == iTRIAD_INDEX_LEFT) {
            nodeHash = PoseidonT4.poseidon(
                [leaf, pathElements[0], pathElements[1]]
            );
        } else if (triadIndex == iTRIAD_INDEX_MIDDLE) {
            nodeHash = PoseidonT4.poseidon(
                [pathElements[0], leaf, pathElements[1]]
            );
        } else if (triadIndex == iTRIAD_INDEX_RIGHT) {
            nodeHash = PoseidonT4.poseidon(
                [pathElements[0], pathElements[1], leaf]
            );
        }

        // [2] - Compute root
        for (uint256 level = 2; level < pathElements.length; level++) {
            bool isLeftNode;
            unchecked {
                // triadNodeIndex is actually a path to triad-node in merkle-tree
                // each LSB bit of this number is left or right path
                // it means for example: path = b111 , zero leaf will be from right size of hash
                // and path element[2] will be from right side of hash, all other path elements [3,4] will be from
                // left side of the next hashes till root.
                isLeftNode = ((triadNodeIndex & (0x1 << (level - 2))) == 0);
            }
            if (isLeftNode) {
                // computed node from left side
                // Hash(left = nodeHash, right = pathElement)
                nodeHash = PoseidonT3.poseidon([nodeHash, pathElements[level]]);
            } else {
                // computed node from right side
                // Hash(left = pathElement, right = nodeHash)
                nodeHash = PoseidonT3.poseidon([pathElements[level], nodeHash]);
            }
        }
        // [3] - revert if verification fails
        require(merkleRoot == nodeHash, ERR_MERKLE_PROOF_VERIFICATION_FAILED);
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { PoseidonT3 } from "../crypto/Poseidon.sol";
import { FIELD_SIZE } from "../crypto/SnarkConstants.sol";
import { ERR_TOO_LARGE_LEAFID, ERR_TOO_LARGE_PRIVKEY } from "../errMsgs/PantherPoolErrMsgs.sol";

abstract contract NullifierGenerator {
    function generateNullifier(uint256 privSpendingKey, uint256 leafId)
        internal
        pure
        returns (bytes32 nullifier)
    {
        require(privSpendingKey < FIELD_SIZE, ERR_TOO_LARGE_PRIVKEY);
        require(leafId < FIELD_SIZE, ERR_TOO_LARGE_LEAFID);
        nullifier = PoseidonT3.poseidon(
            [bytes32(privSpendingKey), bytes32(leafId)]
        );
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

import { G1Point } from "../common/Types.sol";
import { ERR_TOO_LARGE_PRIVKEY } from "../errMsgs/PantherPoolErrMsgs.sol";
import { FIELD_SIZE } from "../crypto/SnarkConstants.sol";
import "../crypto/BabyJubJub.sol";

abstract contract PubKeyGenerator {
    function generatePubSpendingKey(uint256 privKey)
        internal
        view
        returns (G1Point memory pubKey)
    {
        // [0] - Require
        require(privKey < FIELD_SIZE, ERR_TOO_LARGE_PRIVKEY);
        // [1] - Generate public key
        G1Point memory base8 = G1Point({
            x: BabyJubJub.BASE8_X,
            y: BabyJubJub.BASE8_Y
        });
        pubKey = BabyJubJub.mulPointEscalar(base8, privKey);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable avoid-low-level-calls
pragma solidity >=0.6.0;

/// @title TransferHelper library
/// @dev Helper methods for interacting with ERC20, ERC721, ERC1155 tokens and sending ETH
/// Based on the Uniswap/solidity-lib/contracts/libraries/TransferHelper.sol
library TransferHelper {
    /// @dev Approve the `spender` to spend the `amount` of ERC20 token on behalf of `owner`.
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('approve(address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    /// @dev Transfer `value` ERC20 tokens from caller to `to`.
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('transfer(address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /// @dev Transfer `value` ERC20 tokens on behalf of `from` to `to`.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256('transferFrom(address,address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer an ERC721 token with id of `tokenId` on behalf of `from` to `to`.
    function erc721SafeTransferFrom(
        address token,
        uint256 tokenId,
        address from,
        address to
    ) internal {
        // bytes4(keccak256('safeTransferFrom(address,address,uint256)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x42842e0e, from, to, tokenId)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer `amount` ERC1155 token with id of `tokenId` on behalf of `from` to `to`.
    function erc1155SafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory _data
    ) internal {
        // bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)'));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, tokenId, amount, _data)
        );
        _requireTransferSuccess(success, data);
    }

    /// @dev Transfer `value` Ether from caller to `to`.
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }

    function _requireTransferSuccess(bool success, bytes memory res)
        private
        pure
    {
        require(
            success && (res.length == 0 || abi.decode(res, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// This is a stub to keep solc happy; the actual code is generated
// using poseidon_gencontract.js from circomlibjs.

library PoseidonT3 {
    function poseidon(bytes32[2] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

library PoseidonT4 {
    function poseidon(bytes32[3] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

library PoseidonT6 {
    function poseidon(bytes32[5] memory input) external pure returns (bytes32) {
        require(input.length == 99, "FAKE"); // always reverts
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

// @dev Order of alt_bn128 and the field prime of Baby Jubjub and Poseidon hash
uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// @dev Field prime of alt_bn128
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import "./Hasher.sol";
import "./TriadMerkleZeros.sol";
import { ERR_ZERO_ROOT } from "../errMsgs/PantherPoolErrMsgs.sol";
import "../interfaces/IRootsHistory.sol";

/**
 * @title TriadIncrementalMerkleTrees
 * @author Pantherprotocol Contributors
 * @notice Incremental Merkle trees with batch insertion of 3 leaves at once
 * @dev Refer to {TriadMerkleZeros} for comments on "triad trees" used
 * Inspired by MACI project
 * https://github.com/appliedzkp/maci/blob/master/contracts/sol/IncrementalMerkleTree.sol
 */
contract TriadIncrementalMerkleTrees is
    TriadMerkleZeros,
    Hasher,
    IRootsHistory
{
    /**
     * @dev {treeId} is a consecutive number of trees, starting from 0.
     * @dev {leafId} of a leaf is a "modified" number of leaves inserted in all
     * tries before this leaf. It is unique across all trees, starts from 0 for
     * the 1st leaf of the 1st tree, and constantly increments like this:
     * 0,1,2,  4,5,6,  8,9,10,  12,13,14 ... (i.e. every 4th number is skipped)
     * See comments to {TriadMerkleZeros}.
     */

    // `leafId` of the next leaf to insert
    // !!! NEVER access it directly from child contracts: `internal` to ease testing only
    uint256 internal _nextLeafId;

    // Right-most elements (hashes) in the current tree per level
    // level index => hash
    mapping(uint256 => bytes32) private _filledSubtrees;

    /// @notice Roots of fully populated trees
    /// @dev treeId => root
    mapping(uint256 => bytes32) public finalRoots;

    // Recent roots of trees seen
    // cacheIndex => root ^ treeId
    mapping(uint256 => uint256) private _cachedRoots;

    // @dev Root permanently added to the `finalRoots`
    event AnchoredRoot(uint256 indexed treeId, bytes32 root);

    // @dev Root temporarily saved in the `_cachedRoots`
    event CachedRoot(uint256 indexed treeId, bytes32 root);

    // NOTE: No `constructor` (initialization) function needed

    // Max number of latest roots to cache (must be a power of 2)
    uint256 internal constant CACHED_ROOTS_NUM = 256;

    // Number of leaves in a modified triad used for leaf ID calculation
    uint256 private constant iTRIAD_SIZE = 4;
    // The number of leaves in a tree used for leaf ID calculation
    uint256 private constant iLEAVES_NUM = 2**(TREE_DEPTH - 1) * iTRIAD_SIZE;

    // Bitmasks and numbers of bits for "cheaper" arithmetics
    uint256 private constant iTRIAD_SIZE_MASK = iTRIAD_SIZE - 1;
    uint256 private constant iTRIAD_SIZE_BITS = 2;
    uint256 private constant iLEAVES_NUM_MASK = iLEAVES_NUM - 1;
    uint256 private constant iLEAVES_NUM_BITS =
        TREE_DEPTH - 1 + iTRIAD_SIZE_BITS;
    uint256 private constant CACHE_SIZE_MASK =
        CACHED_ROOTS_NUM * iTRIAD_SIZE - 1;

    /**
     * @notice Returns the number of leaves inserted in all trees so far
     */
    function leavesNum() external view returns (uint256) {
        return _nextLeafId2LeavesNum(_nextLeafId);
    }

    /**
     * @notice Returns `treeId` of the current tree
     */
    function curTree() external view returns (uint256) {
        return getTreeId(_nextLeafId);
    }

    /**
     * @notice Returns `treeId` of the given leaf's tree
     */
    function getTreeId(uint256 leafId) public pure returns (uint256) {
        // equivalent to `leafId / iLEAVES_NUM`
        return leafId >> iLEAVES_NUM_BITS;
    }

    /**
     * @notice Returns `leafIndex` (index in the tree) of the given leaf
     */
    function getLeafIndex(uint256 leafId) public pure returns (uint256) {
        unchecked {
            // equiv to `leafId % LEAVES_NUM`
            uint256 iIndex = leafId & iLEAVES_NUM_MASK; // throws away tree-id bits
            uint256 fullTriadsNum = (iIndex + 1) >> iTRIAD_SIZE_BITS; // computes index of triad node in the tree
            return iIndex - fullTriadsNum; // start index of first leaf in the triad
        }
    }

    /**
     * @notice Returns the root of the current tree and its index in cache
     */
    function curRoot()
        external
        view
        returns (bytes32 root, uint256 cacheIndex)
    {
        // Return zero root and index if the current tree is empty
        uint256 nextLeafId = _nextLeafId;
        if (_isEmptyTree(nextLeafId)) return (ZERO_ROOT, 0);

        // Return cached values otherwise
        uint256 treeId = getTreeId(nextLeafId);
        cacheIndex = _nextLeafId2CacheIndex(nextLeafId);
        uint256 v = _cachedRoots[cacheIndex];
        root = bytes32(v ^ treeId);
    }

    /// @inheritdoc IRootsHistory
    function isKnownRoot(
        uint256 treeId,
        bytes32 root,
        uint256 cacheIndexHint
    ) public view override returns (bool) {
        require(root != 0, ERR_ZERO_ROOT);

        // if hint provided, use hint
        if (cacheIndexHint != 0)
            return _isCorrectCachedRoot(treeId, root, cacheIndexHint);

        // then, check the history
        if (finalRoots[treeId] == root) return true;

        // finally, look in cache, starting from the current root
        uint256 leafId = _nextLeafId;
        unchecked {
            uint256 i = CACHED_ROOTS_NUM;
            while ((leafId >= iTRIAD_SIZE) && (i != 0)) {
                i -= 1;
                // Skip the last triad in a tree (i.e. the full tree root)
                if (leafId & iLEAVES_NUM_MASK == 0) continue;
                uint256 cacheIndex = _nextLeafId2CacheIndex(leafId);
                if (_isCorrectCachedRoot(treeId, root, cacheIndex)) return true;
                leafId -= iTRIAD_SIZE;
            }
        }
        return false;
    }

    /**
     * @dev Inserts 3 leaves into the current tree, or a new one, if that's full
     * @param leaves The 3 leaves to insert (must be less than SNARK_SCALAR_FIELD)
     * @return leftLeafId The `leafId` of the first leaf from 3 inserted
     */
    function insertBatch(bytes32[TRIAD_SIZE] memory leaves)
        internal
        returns (uint256 leftLeafId)
    {
        leftLeafId = _nextLeafId;

        bytes32[TREE_DEPTH] memory zeros;
        populateZeros(zeros);

        // index of a "current" node (0 for the leftmost node/leaf of a level)
        uint256 nodeIndex;
        // hash (value) of a "current" node
        bytes32 nodeHash;
        // index of a "current" level (0 for leaves, increments toward root)
        uint256 level;

        // subtree from 3 leaves being inserted on `level = 0`
        nodeHash = hash(leaves[0], leaves[1], leaves[2]);
        // ... to be placed under this index on `level = 1`
        // (equivalent to `(leftLeafId % iLEAVES_NUM) / iTRIAD_SIZE`)
        nodeIndex = (leftLeafId & iLEAVES_NUM_MASK) >> iTRIAD_SIZE_BITS;

        bytes32 left;
        bytes32 right;
        for (level = 1; level < TREE_DEPTH; level++) {
            // if `nodeIndex` is, say, 25, over the iterations it will be:
            // 25, 12, 6, 3, 1, 0, 0 ...

            if (nodeIndex % 2 == 0) {
                left = nodeHash;
                right = zeros[level];
                _filledSubtrees[level] = nodeHash;
            } else {
                // for a new tree, "than" block always run before "else" block
                // so `_filledSubtrees[level]` gets updated before its use
                left = _filledSubtrees[level];
                right = nodeHash;
            }

            nodeHash = hash(left, right);

            // equivalent to `nodeIndex /= 2`
            nodeIndex >>= 1;
        }

        uint256 nextLeafId = leftLeafId + iTRIAD_SIZE;
        _nextLeafId = nextLeafId;

        uint256 treeId = getTreeId(leftLeafId);
        if (_isFullTree(leftLeafId)) {
            // Switch to a new tree
            // Ignore `_filledSubtrees` old values as they are never re-used
            finalRoots[treeId] = nodeHash;
            emit AnchoredRoot(treeId, nodeHash);
        } else {
            uint256 cacheIndex = _nextLeafId2CacheIndex(nextLeafId);
            _cachedRoots[cacheIndex] = uint256(nodeHash) ^ treeId;
            emit CachedRoot(treeId, nodeHash);
        }
    }

    /// private functions follow (some of them made `internal` to ease testing)

    function _isFullTree(uint256 leftLeafId) internal pure returns (bool) {
        unchecked {
            return
                (iLEAVES_NUM - (leftLeafId & iLEAVES_NUM_MASK)) <= iTRIAD_SIZE;
        }
    }

    function _isEmptyTree(uint256 nextLeafId) internal pure returns (bool) {
        return (nextLeafId & iLEAVES_NUM_MASK) == 0;
    }

    function _nextLeafId2LeavesNum(
        uint256 nextLeafId // declared as `internal` to facilitate testing
    ) internal pure returns (uint256) {
        // equiv to `nextLeafId / iTRIAD_SIZE * TRIAD_SIZE + nextLeafId % iTRIAD_SIZE`
        unchecked {
            return
                (nextLeafId >> iTRIAD_SIZE_BITS) *
                TRIAD_SIZE +
                (nextLeafId & iTRIAD_SIZE_MASK);
        }
    }

    // Returns `triadIndex` index in the triad-node of the given leaf = { 0, 1, 2 }
    function _getTriadIndex(uint256 leafId) internal pure returns (uint256) {
        return getLeafIndex(leafId) % TRIAD_SIZE;
    }

    // Returns `triadNodeIndex` index of the triad-node of the given leaf
    // This index is the path to this node - used by anyone who needs the path
    function _getTriadNodeIndex(uint256 leafId)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            // equiv to `leafId % LEAVES_NUM`
            uint256 iIndex = leafId & iLEAVES_NUM_MASK; // throws away tree-id bits
            uint256 fullTriadsNum = (iIndex + 1) >> iTRIAD_SIZE_BITS; // computes index of triad node in the tree
            return fullTriadsNum;
        }
    }

    // nextLeafId must be even
    function _nextLeafId2CacheIndex(uint256 nextLeafId)
        private
        pure
        returns (uint256)
    {
        // equiv to `nextLeafId % (CACHED_ROOTS_NUM * iTRIAD_SIZE) + 1`
        return (nextLeafId & CACHE_SIZE_MASK) | 1;
    }

    function _isCorrectCachedRoot(
        uint256 treeId,
        bytes32 root,
        uint256 cacheIndex
    ) private view returns (bool) {
        uint256 v = _cachedRoots[cacheIndex];
        return v == (uint256(root) ^ treeId);
    }

    // NOTE: The contract is supposed to run behind a proxy DELEGATECALLing it.
    // For compatibility on upgrades, decrease `__gap` if new variables added.
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { PoseidonT3, PoseidonT4 } from "../crypto/Poseidon.sol";

/*
 * @dev Poseidon hash functions
 */
abstract contract Hasher {
    function hash(bytes32 left, bytes32 right) internal pure returns (bytes32) {
        bytes32[2] memory input;
        input[0] = left;
        input[1] = right;
        return PoseidonT3.poseidon(input);
    }

    function hash(
        bytes32 left,
        bytes32 mid,
        bytes32 right
    ) internal pure returns (bytes32) {
        bytes32[3] memory input;
        input[0] = left;
        input[1] = mid;
        input[2] = right;
        return PoseidonT4.poseidon(input);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.4;

import { FIELD_SIZE } from "../crypto/SnarkConstants.sol";

// Content is autogenerated by `lib/triadMerkleZerosContractGenerator.ts`

/**
 * @dev The "triad binary tree" is a modified Merkle (full) binary tree with:
 * - every node, from the root upto the level preceding leaves, excluding
 * that level, has 2 child nodes (i.e. this subtree is a full binary tree);
 * - every node of the layer preceding leaves has 3 child nodes (3 leaves).
 * Example:
 * [4]                                       0
 *                                           |
 * [3]                        0--------------------------------1
 *                            |                                |
 * [2]                0---------------1                 2--------------3
 *                    |               |                 |              |
 * [1]            0-------1       2-------3        4-------5       6-------7
 *               /|\     /|\     /|\     /|\      /|\     /|\     /|\     /|\
 * [0] index:   0..2    3..5    6..8    9...11  12..14  15..17  18..20  21..24
 *
 *   leaf ID:   0..2    4..6    8..10   12..14  16..18  20..23  24..27  28..30
 *
 * - Number in [] is the "level index" that starts from 0 for the leaves level.
 * - Numbers in node/leaf positions are "node/leaf indices" which starts from 0
 *   for the leftmost node/leaf of every level.
 * - Numbers bellow leaves are IDs of leaves.
 *
 * Arithmetic operations with multiples of 2 (i.e. shifting) is "cheaper" than
 * operations with multiples of 3 (both on-chain and in zk-circuits).
 * Therefore, IDs of leaves (but NOT hashes of nodes) are calculated as if the
 * tree would have 4 (not 3) leaves in branches, with every 4th leaf skipped.
 * In other words, there are no leaves with IDs 3, 7, 11, 15, 19...
 */

// @notice The "triad binary tree" populated with zero leaf values
abstract contract TriadMerkleZeros {
    // @dev Number of levels in a tree excluding the root level
    // (also defined in scripts/generateTriadMerkleZeroesContracts.sh)
    uint256 internal constant TREE_DEPTH = 15;

    // Number of levels in a tree including both leaf and root levels
    uint256 internal constant TREE_LEVELS = TREE_DEPTH + 1;

    // Number of leaves in a branch with the root on the level 1
    uint256 internal constant TRIAD_SIZE = 3;

    // Number of leaves in the fully populated tree
    uint256 internal constant LEAVES_NUM = (2**(TREE_DEPTH - 1)) * TRIAD_SIZE;

    // @dev Leaf zero value (`keccak256("Pantherprotocol")%FIELD_SIZE`)
    bytes32 internal constant ZERO_VALUE =
        bytes32(
            uint256(
                0x667764c376602b72ef22218e1673c2cc8546201f9a77807570b3e5de137680d
            )
        );

    // Merkle root of a tree that contains zeros only
    bytes32 internal constant ZERO_ROOT =
        bytes32(
            uint256(
                0x20fc043586a9fcb416cdf2a3bc8a995f8f815d43f1046a20d1c588cf20482a55
            )
        );

    function populateZeros(bytes32[TREE_DEPTH] memory zeros) internal pure {
        zeros[0] = bytes32(
            uint256(
                0x667764c376602b72ef22218e1673c2cc8546201f9a77807570b3e5de137680d
            )
        );
        zeros[1] = bytes32(
            uint256(
                0x1be18cd72ac1586de27dd60eba90654bd54383004991951bccb0f6bad02c67f6
            )
        );
        zeros[2] = bytes32(
            uint256(
                0x7677e6102f0acf343edde864f79ef7652faa5a66d575b8b60bb826a4aa517e6
            )
        );
        zeros[3] = bytes32(
            uint256(
                0x28a85866ab97bd65cc94b0d1f5c5986481f8a0d65bdd5c1e562659eebb13cf63
            )
        );
        zeros[4] = bytes32(
            uint256(
                0x87321a66ea3af7780128ea1995d7fc6ec44a96a1b2d85d3021208cede68c15c
            )
        );
        zeros[5] = bytes32(
            uint256(
                0x233b4e488f0aaf5faef4fc8ea4fefeadb6934eb882bc33b9df782fd1d83b41a0
            )
        );
        zeros[6] = bytes32(
            uint256(
                0x1a0cefcf0c592da6426717d3718408c61af1d0a9492887f3faecefcba1a0a309
            )
        );
        zeros[7] = bytes32(
            uint256(
                0x2cdf963150b321923dd07b2b52659aceb529516a537dfebe24106881dd974293
            )
        );
        zeros[8] = bytes32(
            uint256(
                0x93a186bf9ec2cc874ceab26409d581579e1a431ecb6987d428777ceedfa15c4
            )
        );
        zeros[9] = bytes32(
            uint256(
                0xcbfc07131ef4197a4b4e60153d43381520ec9ab4c9c3ed34d88883a881a4e07
            )
        );
        zeros[10] = bytes32(
            uint256(
                0x17b31de43ba4c687cf950ad00dfbe33df40047e79245b50bd1d9f87e622bf2af
            )
        );
        zeros[11] = bytes32(
            uint256(
                0x2f3328354bceaf5882a8cc88053e0dd0ae594009a4e84e9e75a4fefe8604a602
            )
        );
        zeros[12] = bytes32(
            uint256(
                0x2b2e8defd4dad2404c6874918925fc1192123f45df0ee3e04b6c16ff22ca1cfd
            )
        );
        zeros[13] = bytes32(
            uint256(
                0x1cbdc4065aa4137da01d64a090706267d65f425ea5e815673516d29d9aa14d38
            )
        );
        zeros[14] = bytes32(
            uint256(
                0x13ca69f9fde4ece39e395bb55dd41ed7dd9dfaa26671e26bd9fd6f4f635fc872
            )
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.4;

interface IRootsHistory {
    /// @notice Returns `true` if the given root of the given tree is known
    /// @param cacheIndexHint Index of the root in the cache, ignored if 0
    function isKnownRoot(
        uint256 treeId,
        bytes32 root,
        uint256 cacheIndexHint
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../common/Types.sol";

// solhint-disable no-inline-assembly

library BabyJubJub {
    // Curve parameters
    // E: 168700x^2 + y^2 = 1 + 168696x^2y^2
    // A = 168700
    uint256 public constant A = 0x292FC;
    // D = 168696
    uint256 public constant D = 0x292F8;
    // Prime Q = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    uint256 public constant Q =
        0x30644E72E131A029B85045B68181585D2833E84879B9709143E1F593F0000001;

    // @dev Base point generates the subgroup of points P of Baby Jubjub satisfying l * P = O.
    // That is, it generates the set of points of order l and origin O.
    uint256 public constant BASE8_X =
        5299619240641551281634865583518297030282874472190772894086521144482721001553;
    uint256 public constant BASE8_Y =
        16950150798460657717958625567821834550301663161624707787222815936182638968203;

    /**
     * @dev Add 2 points on baby jubjub curve
     * Formulae for adding 2 points on a twisted Edwards curve:
     * x3 = (x1y2 + y1x2) / (1 + dx1x2y1y2)
     * y3 = (y1y2 - ax1x2) / (1 - dx1x2y1y2)
     */
    function pointAdd(G1Point memory g1, G1Point memory g2)
        internal
        view
        returns (G1Point memory)
    {
        uint256 x3;
        uint256 y3;
        if (g1.x == 0 && g1.y == 0) {
            return G1Point(x3, y3);
        }

        if (g2.x == 0 && g1.y == 0) {
            return G1Point(x3, y3);
        }

        uint256 x1x2 = mulmod(g1.x, g2.x, Q);
        uint256 y1y2 = mulmod(g1.y, g2.y, Q);
        uint256 dx1x2y1y2 = mulmod(D, mulmod(x1x2, y1y2, Q), Q);
        uint256 x3Num = addmod(mulmod(g1.x, g2.y, Q), mulmod(g1.y, g2.x, Q), Q);
        uint256 y3Num = submod(y1y2, mulmod(A, x1x2, Q), Q);

        x3 = mulmod(x3Num, inverse(addmod(1, dx1x2y1y2, Q)), Q);
        y3 = mulmod(y3Num, inverse(submod(1, dx1x2y1y2, Q)), Q);
        return G1Point(x3, y3);
    }

    /**
     * @dev Perform modular subtraction
     */
    function submod(
        uint256 _a,
        uint256 _b,
        uint256 _mod
    ) internal pure returns (uint256) {
        uint256 aNN = _a;

        if (_a <= _b) {
            aNN += _mod;
        }

        return addmod(aNN - _b, 0, _mod);
    }

    /**
     * @dev Compute modular inverse of a number
     */
    function inverse(uint256 _a) internal view returns (uint256) {
        // We can use Euler's theorem instead of the extended Euclidean algorithm
        // Since m = Q and Q is prime we have: a^-1 = a^(m - 2) (mod m)
        return expmod(_a, Q - 2, Q);
    }

    /**
     * @dev Helper function to call the bigModExp precompile
     */
    function expmod(
        uint256 _b,
        uint256 _e,
        uint256 _m
    ) internal view returns (uint256 o) {
        assembly {
            let memPtr := mload(0x40)
            mstore(memPtr, 0x20) // Length of base _b
            mstore(add(memPtr, 0x20), 0x20) // Length of exponent _e
            mstore(add(memPtr, 0x40), 0x20) // Length of modulus _m
            mstore(add(memPtr, 0x60), _b) // Base _b
            mstore(add(memPtr, 0x80), _e) // Exponent _e
            mstore(add(memPtr, 0xa0), _m) // Modulus _m

            // The bigModExp precompile is at 0x05
            let success := staticcall(gas(), 0x05, memPtr, 0xc0, memPtr, 0x20)
            switch success
            case 0 {
                revert(0x0, 0x0)
            }
            default {
                o := mload(memPtr)
            }
        }
    }

    function mulPointEscalar(G1Point memory point, uint256 scalar)
        internal
        view
        returns (G1Point memory r)
    {
        r.x = 0;
        r.y = 1;

        uint256 rem = scalar;
        G1Point memory exp = point;

        while (rem != uint256(0)) {
            if ((rem & 1) == 1) {
                r = pointAdd(r, exp);
            }
            exp = pointAdd(exp, exp);
            rem = rem >> 1;
        }
        r.x = r.x % Q;
        r.y = r.y % Q;

        return r;
    }
}