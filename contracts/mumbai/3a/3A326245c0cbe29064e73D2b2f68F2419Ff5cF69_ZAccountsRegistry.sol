// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./BinaryMerkleZeros.sol";
import "../../protocol/triadTree/Hasher.sol";

/**
 * @title BinaryIncrementalUpdatableMerkleTree
 * @notice
 * @dev
 */
abstract contract BinaryIncrementalUpdatableMerkleTree is
    BinaryMerkleZeros,
    Hasher
{
    // `index` of the next leaf to insert
    // !!! NEVER access it directly from child contracts: `internal` to ease testing only
    uint256 internal _nextLeafIndex;

    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node])
    mapping(uint256 => bytes32[2]) internal _filledSubtrees;

    uint256 public constant LEAVES_NUM = 2**TREE_DEPTH;

    bytes32 public currentRoot;

    /**
     * @dev Inserts a leaf into the tree if it's not yet full
     * @param leaf The leaf to be inserted
     * @return insertedLeafIndex The leaf index which has been inserted
     */
    function insert(bytes32 leaf) internal returns (uint256 insertedLeafIndex) {
        uint256 index = _nextLeafIndex;
        require(index < LEAVES_NUM, "BIUT: Tree is full");

        // here the variable is intentionally declared only ...
        // slither-disable-next-line uninitialized-local
        bytes32[TREE_DEPTH] memory zeros;
        // ... and initialized in this call
        populateZeros(zeros);

        bytes32 left;
        bytes32 right;
        bytes32 _hash = leaf;

        for (uint8 level = 0; level < TREE_DEPTH; ) {
            if (index % 2 == 0) {
                left = _hash;
                right = zeros[level];

                _filledSubtrees[level] = [left, right];
            } else {
                left = _filledSubtrees[level][0];
                right = _hash;

                _filledSubtrees[level][1] = right;
            }

            _hash = hash(left, right);
            index >>= 1;

            unchecked {
                ++level;
            }
        }

        currentRoot = _hash;
        insertedLeafIndex = _nextLeafIndex;
        _nextLeafIndex++;
    }

    /**
     * @dev Update an existing leaf
     * @param leaf Leaf to be updated.
     * @param newLeaf New leaf.
     * @param proofSiblings Array of the sibling nodes of the proof of membership.
     * @param proofPathIndices Path of the proof of membership.
     * @return _hash The new root after updating the tree
     leafIndex is eq to proofPathIndices[0] * 2**0 and ...
     */
    function update(
        bytes32 leaf,
        bytes32 newLeaf,
        bytes32[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal returns (bytes32 _hash) {
        require(newLeaf != leaf, "BIUT: New leaf cannot be equal the old one");
        require(
            verify(leaf, proofSiblings, proofPathIndices),
            "BIUT: Leaf is not part of the tree"
        );

        _hash = newLeaf;
        uint256 updateIndex;

        for (uint256 i = 0; i < TREE_DEPTH; ) {
            updateIndex |= uint256(proofPathIndices[i]) << uint256(i);

            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == _filledSubtrees[i][1]) {
                    _filledSubtrees[i][0] = _hash;
                }

                _hash = hash(_hash, proofSiblings[i]);
            } else {
                if (proofSiblings[i] == _filledSubtrees[i][0]) {
                    _filledSubtrees[i][1] = _hash;
                }

                _hash = hash(proofSiblings[i], _hash);
            }

            unchecked {
                ++i;
            }
        }

        require(updateIndex < LEAVES_NUM, "BIUT: Leaf index out of range");

        currentRoot = _hash;
    }

    /**
     * @dev Verify if the path is correct and the leaf is part of the tree.
     * @param leaf Leaf to be updated.
     * @param proofSiblings Array of the sibling nodes of the proof of membership.
     * @param proofPathIndices Path of the proof of membership.
     * @return True or false.
     */
    function verify(
        bytes32 leaf,
        bytes32[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal view returns (bool) {
        require(
            proofPathIndices.length == TREE_DEPTH &&
                proofSiblings.length == TREE_DEPTH,
            "BIUT: length of path is not correct"
        );

        bytes32 _hash = leaf;

        for (uint256 i = 0; i < TREE_DEPTH; ) {
            require(
                proofPathIndices[i] == 1 || proofPathIndices[i] == 0,
                "IncrementalBinaryTree: path index is neither 0 nor 1"
            );

            if (proofPathIndices[i] == 0) {
                _hash = hash(_hash, proofSiblings[i]);
            } else {
                _hash = hash(proofSiblings[i], _hash);
            }

            unchecked {
                ++i;
            }
        }

        return _hash == currentRoot;
    }

    /**
     * @dev Gettign the next leaf index
     * @return the leaf index
     */
    function getNextLeafIndex() external view returns (uint256) {
        return uint256(_nextLeafIndex);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { FIELD_SIZE } from "../../protocol/crypto/SnarkConstants.sol";

// Content is autogenerated by `lib/binaryMerkleZerosContractGenerator.ts`

/**
 * Example:
 * [4]                                       0
 *                                           |
 * [3]                        0--------------------------------1
 *                            |                                |
 * [2]                0---------------1                 2--------------3
 *                    |               |                 |              |
 * [1]            0-------1       2-------3        4-------5       6-------7
 *               / \     / \     / \     / \      / \     / \     / \     / \
 * [0] index:   0   1   2   3   4   5   6   7    8   9   10 11   12 13   14 15
 *
 *   leaf ID:   0...1   2...3   4...5   6...7    8...8   10..11  12..13  14..15
 *
 * - Number in [] is the "level index" that starts from 0 for the leaves level.
 * - Numbers in node/leaf positions are "node/leaf indices" which starts from 0
 *   for the leftmost node/leaf of every level.
 * - Numbers bellow leaves are IDs of leaves.
 */

// @notice The "binary binary tree" populated with zero leaf values
abstract contract BinaryMerkleZeros {
    // solhint-disable var-name-mixedcase

    // @dev Number of levels in a tree excluding the root level
    uint256 internal constant TREE_DEPTH = 16;

    // Number of leaves in a branch with the root on the level 1
    uint256 internal constant TRIAD_SIZE = 2;

    // @dev Leaf zero value
    bytes32 internal constant ZERO_VALUE = 0x00;

    // Merkle root of a tree that contains zeros only
    bytes32 internal constant ZERO_ROOT =
        bytes32(
            uint256(
                0x2a7c7c9b6ce5880b9f6f228d72bf6a575a526f29c66ecceef8b753d38bba7323
            )
        );

    // solhint-enable var-name-mixedcase

    function populateZeros(bytes32[TREE_DEPTH] memory zeros) internal pure {
        zeros[0] = bytes32(uint256(0x0));
        zeros[1] = bytes32(
            uint256(
                0x2098f5fb9e239eab3ceac3f27b81e481dc3124d55ffed523a839ee8446b64864
            )
        );
        zeros[2] = bytes32(
            uint256(
                0x1069673dcdb12263df301a6ff584a7ec261a44cb9dc68df067a4774460b1f1e1
            )
        );
        zeros[3] = bytes32(
            uint256(
                0x18f43331537ee2af2e3d758d50f72106467c6eea50371dd528d57eb2b856d238
            )
        );
        zeros[4] = bytes32(
            uint256(
                0x7f9d837cb17b0d36320ffe93ba52345f1b728571a568265caac97559dbc952a
            )
        );
        zeros[5] = bytes32(
            uint256(
                0x2b94cf5e8746b3f5c9631f4c5df32907a699c58c94b2ad4d7b5cec1639183f55
            )
        );
        zeros[6] = bytes32(
            uint256(
                0x2dee93c5a666459646ea7d22cca9e1bcfed71e6951b953611d11dda32ea09d78
            )
        );
        zeros[7] = bytes32(
            uint256(
                0x78295e5a22b84e982cf601eb639597b8b0515a88cb5ac7fa8a4aabe3c87349d
            )
        );
        zeros[8] = bytes32(
            uint256(
                0x2fa5e5f18f6027a6501bec864564472a616b2e274a41211a444cbe3a99f3cc61
            )
        );
        zeros[9] = bytes32(
            uint256(
                0xe884376d0d8fd21ecb780389e941f66e45e7acce3e228ab3e2156a614fcd747
            )
        );
        zeros[10] = bytes32(
            uint256(
                0x1b7201da72494f1e28717ad1a52eb469f95892f957713533de6175e5da190af2
            )
        );
        zeros[11] = bytes32(
            uint256(
                0x1f8d8822725e36385200c0b201249819a6e6e1e4650808b5bebc6bface7d7636
            )
        );
        zeros[12] = bytes32(
            uint256(
                0x2c5d82f66c914bafb9701589ba8cfcfb6162b0a12acf88a8d0879a0471b5f85a
            )
        );
        zeros[13] = bytes32(
            uint256(
                0x14c54148a0940bb820957f5adf3fa1134ef5c4aaa113f4646458f270e0bfbfd0
            )
        );
        zeros[14] = bytes32(
            uint256(
                0x190d33b12f986f961e10c0ee44d8b9af11be25588cad89d416118e4bf4ebe80c
            )
        );
        zeros[15] = bytes32(
            uint256(
                0x22f98aa9ce704152ac17354914ad73ed1167ae6596af510aa5b3649325e06c92
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// slither-disable-next-line solc-version
pragma solidity ^0.8.4;

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
// slither-disable-next-line solc-version
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
    G1Point alfa1;
    G2Point beta2;
    G2Point gamma2;
    G2Point delta2;
    G1Point[] ic;
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
pragma solidity ^0.8.16;

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

library PoseidonT5 {
    function poseidon(bytes32[4] memory input) external pure returns (bytes32) {
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

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
// solhint-disable var-name-mixedcase
pragma solidity ^0.8.16;

// @dev Order of alt_bn128 and the field prime of Baby Jubjub and Poseidon hash
uint256 constant FIELD_SIZE = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

// @dev Field prime of alt_bn128
uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2021-22 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

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
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "../common/ImmutableOwnable.sol";
import "../common/binaryTree/BinaryIncrementalUpdatableMerkleTree.sol";
import "../common/Types.sol";

interface IPantherPoolV1 {
    function createUtxo(SnarkProof calldata proof) external view returns (bool);
}

/**
 * @title ZAccountsRegistry
 * @author Pantherprotocol Contributors
 * @notice Registry and whitelist of zAccounts allowed to interact with MASP.
 */
contract ZAccountsRegistry is
    ImmutableOwnable,
    BinaryIncrementalUpdatableMerkleTree
{
    // The contract is supposed to run behind a proxy DELEGATECALLing it.
    // On upgrades, adjust `__gap` to match changes of the storage layout.
    // slither-disable-next-line shadowing-state unused-state
    uint256[50] private __gap;

    // solhint-disable var-name-mixedcase

    uint8 constant zACCOUNT_ACTIVATED = 0x01;
    uint8 constant zACCOUNT_DEACTIVATED = 0x02;

    uint8 private constant zACCOUNT_UNDEFINED_ID = 0x00;
    uint256 private constant zACCOUNT_ID_SKIP = 4;
    uint256 private constant zACCOUNT_ID_MAX_RANGE = (2**8) - zACCOUNT_ID_SKIP;

    uint256 private constant iZACCOUNT_ID_NUM_MASK = (2**8) - 1; // ff : 8 lsb
    uint256 private constant iZACCOUNT_ID_PATH_MASK = (2**TREE_DEPTH) - 1; // fffffff

    uint8 private constant ZACCOUNT_VERSION = 0x01;
    string public constant ERC712_VERSION = "1";
    string public constant ERC712_NAME = "ZAccountsRegistry";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal constant REGISTRATION_TYPEHASH =
        keccak256(
            bytes(
                "Registration(bytes32 pubRootSpendingKey,bytes32 pubReadingKey,uint256 version)"
            )
        );

    IPantherPoolV1 public immutable PANTHER_POOL;

    // solhint-enable var-name-mixedcase

    uint256 private _ZAccountIdCounter;

    mapping(address => bool) public isMasterEoaBlacklisted;
    mapping(bytes32 => bool) public isPubRootSpendingKeyBlacklisted;

    struct ZAccount {
        uint216 _unused; // reserved
        uint24 id; // the ZAccount id, starts from 1
        uint8 version; // ZAccount version
        uint8 status; // ZAccount status, used to blacklist account
        bytes32 pubRootSpendingKey;
        bytes32 pubReadingKey;
    }
    // Mapping from `MasterEoa` to ZAccount (i.e. params of an ZAccount)
    mapping(address => ZAccount) private _registry;

    event ZAccountRegistered(ZAccount zAccount);
    event ZAccountStatusChanged(address masterEoa, uint256 newStatus);

    constructor(address _owner, address pantherPool) ImmutableOwnable(_owner) {
        // require(pantherPool != address(0), "Init: Zero address");

        PANTHER_POOL = IPantherPoolV1(pantherPool);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isZAccountActivated(address _masterEOA)
        external
        view
        returns (bool)
    {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        return
            _ZAccount.id != zACCOUNT_UNDEFINED_ID &&
            _ZAccount.status == zACCOUNT_ACTIVATED;
    }

    function getZAccount(address _masterEoa)
        public
        view
        returns (ZAccount memory)
    {
        return _registry[_masterEoa];
    }

    function getZAccountId(address _masterEOA) external view returns (uint64) {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        return _ZAccount.id;
    }

    function getNextZAccountId() public view returns (uint256) {
        return
            _ZAccountIdCounter % zACCOUNT_ID_MAX_RANGE == 0
                ? _ZAccountIdCounter + zACCOUNT_ID_SKIP
                : _ZAccountIdCounter + 1;
    }

    /* ========== ONLY FOR OWNER FUNCTIONS ========== */

    function updateMasterEoaStatus(address masterEoa, bool status)
        external
        onlyOwner
    {
        require(
            isMasterEoaBlacklisted[masterEoa] != status,
            "ZAR: Invalid master eoa status"
        );
        isMasterEoaBlacklisted[masterEoa] = status;
    }

    function updatePubRootSpendingKeyStatus(
        bytes32 pubRootSpendingKey,
        bool status
    ) external onlyOwner {
        require(
            isPubRootSpendingKeyBlacklisted[pubRootSpendingKey] != status,
            "ZAR: Invalid pub root spending key status"
        );

        isPubRootSpendingKeyBlacklisted[pubRootSpendingKey] = status;
    }

    function blacklistZAccountId(uint24 leaf, uint216 zAccountId)
        external
        onlyOwner
    {
        uint256 zAccountFlagIndex = (zAccountId & iZACCOUNT_ID_NUM_MASK) - 1; // flag index (zaccFlagIndex)
        uint256 leafIndex = zAccountId >> 8;

        uint256 newLeaf = leaf | (1 << zAccountFlagIndex);

        require(zAccountId % 256 < 253);
        require(zAccountFlagIndex < getNextZAccountId(), "ZAR: Id not exists");
        require(
            zAccountFlagIndex > zACCOUNT_UNDEFINED_ID &&
                zAccountFlagIndex <= zACCOUNT_ID_MAX_RANGE,
            "ZAR: Invalid Id"
        );

        insert(bytes32(uint256(leaf))); //update(leaf, newLeaf, siblings, leafIndex)
    }

    // restrict to owner at the moment, subject to delete onlyOwner and verify EOS's signature
    function registerZAccount(
        bytes32 _pubRootSpendingKey,
        bytes32 _pubReadingKey,
        bytes32 _salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 eip712DomainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(ERC712_NAME)),
                keccak256(bytes(ERC712_VERSION)),
                _getChainId(),
                address(this),
                _salt
            )
        );

        bytes32 RegisterationHash = keccak256(
            abi.encode(
                REGISTRATION_TYPEHASH,
                _pubRootSpendingKey,
                _pubReadingKey,
                uint256(ZACCOUNT_VERSION)
            )
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                "\\x19\\x01",
                eip712DomainSeparator,
                RegisterationHash
            )
        );

        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ZAR: invalid signature");

        ZAccount memory _ZAccount = getZAccount(signer);
        require(_ZAccount.id == zACCOUNT_UNDEFINED_ID, "ZAR: Record exists");
        require(!isMasterEoaBlacklisted[signer], "ZAR: Blacklisted master eoa");
        require(
            !isPubRootSpendingKeyBlacklisted[_pubRootSpendingKey],
            "ZAR: Blacklisted spending key"
        );

        _ZAccount = ZAccount({
            _unused: uint176(0),
            id: uint24(getNextZAccountId()),
            version: ZACCOUNT_VERSION,
            status: zACCOUNT_ACTIVATED,
            pubRootSpendingKey: _pubRootSpendingKey,
            pubReadingKey: _pubReadingKey
        });

        _registry[signer] = _ZAccount;

        _ZAccountIdCounter++;

        emit ZAccountRegistered(_ZAccount);
    }

    function deActivateZAccount(address _masterEOA) external onlyOwner {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        require(
            _ZAccount.id != zACCOUNT_UNDEFINED_ID &&
                _ZAccount.status == zACCOUNT_ACTIVATED,
            "ZAR: Not exist or Already deactivated"
        );

        _ZAccount.status = zACCOUNT_DEACTIVATED;

        _registry[_masterEOA] = _ZAccount;

        emit ZAccountStatusChanged(_masterEOA, uint256(zACCOUNT_DEACTIVATED));
    }

    //TODO it should create zone utxo inside the tree
    function activateZAccount(
        address _masterEOA,
        bytes32 nullifier,
        SnarkProof memory proof
    ) external {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        require(
            _ZAccount.id != zACCOUNT_UNDEFINED_ID &&
                _ZAccount.status == zACCOUNT_DEACTIVATED,
            "ZAR: Not exist or Already activated"
        );

        _ZAccount.status = zACCOUNT_ACTIVATED;

        _registry[_masterEOA] = _ZAccount;

        _createZAccountUTXO(nullifier, proof);

        emit ZAccountStatusChanged(_masterEOA, uint256(zACCOUNT_ACTIVATED));
    }

    function _createZAccountUTXO(bytes32 nullifier, SnarkProof memory proof)
        private
    {
        require(PANTHER_POOL.createUtxo(proof), "ZAR: Utxo creation failed");
    }

    function _getChainId() private view returns (uint256) {
        uint256 id;

        // solhint-disable no-inline-assembly
        // slither-disable-next-line assembly
        assembly {
            id := chainid()
        }
        // solhint-enable no-inline-assembly

        return id;
    }
}