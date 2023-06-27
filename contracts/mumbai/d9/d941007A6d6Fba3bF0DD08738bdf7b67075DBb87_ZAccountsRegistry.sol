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

// @dev Circuit extra public input as work-around for recently found groth16 vulnerability
uint256 constant MAGICAL_CONSTRAINT = 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00;

// SPDX-License-Identifier: MIT
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

import { SnarkProof } from "../../common/Types.sol";

interface IPantherPoolV1 {
    function createUtxo(SnarkProof calldata proof) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "../common/ImmutableOwnable.sol";
import "../common/Types.sol";
import "./zAccountsRegistry/blacklistedZAccountIdsTree/BlacklistedZAccountIdsTree.sol";
import "./zAccountsRegistry/ZAccountRegeistrationSignatureVerifier.sol";

import "./interfaces/IPantherPoolV1.sol";

/**
 * @title ZAccountsRegistry
 * @author Pantherprotocol Contributors
 * @notice Registry and whitelist of zAccounts allowed to interact with MASP.
 */
contract ZAccountsRegistry is
    ImmutableOwnable,
    BlacklistedZAccountIdsTree,
    ZAccountRegeistrationSignatureVerifier
{
    // The contract is supposed to run behind a proxy DELEGATECALLing it.
    // On upgrades, adjust `__gap` to match changes of the storage layout.
    // slither-disable-next-line shadowing-state unused-state
    uint256[50] private __gap;

    // solhint-disable var-name-mixedcase

    uint8 constant zACCOUNT_ACTIVATED = 0x01;
    uint8 constant zACCOUNT_DEACTIVATED = 0x02;
    uint8 constant zACCOUNT_SUSPENDED = 0x03;

    IPantherPoolV1 public immutable PANTHER_POOL;

    // solhint-enable var-name-mixedcase

    struct ZAccount {
        uint216 _unused; // reserved
        uint24 id; // the ZAccount id, starts from 1
        uint8 version; // ZAccount version
        uint8 status; // ZAccount status, used to blacklist account
        bytes32 pubRootSpendingKey;
        bytes32 pubReadingKey;
    }

    uint256 public zAccountIdTracker;

    mapping(address => bool) public isMasterEoaBlacklisted;
    mapping(bytes32 => bool) public isPubRootSpendingKeyBlacklisted;
    mapping(bytes32 => bool) public nullifiers;

    // Mapping from `MasterEoa` to ZAccount (i.e. params of an ZAccount)
    mapping(address => ZAccount) private _registry;

    event ZAccountRegistered(ZAccount zAccount);
    event ZAccountStatusChanged(address masterEoa, uint256 newStatus);
    event BlacklistForZAccountIdUpdated(uint256 zAccountId, bool isBlackListed);
    event BlacklistForMasterEoaUpdated(address masterEoa, bool isBlackListed);
    event BlacklistForPubRootSpendingKeyUpdated(
        bytes32 pubRootSpendingKey,
        bool isBlackListed
    );

    constructor(address _owner, address pantherPool) ImmutableOwnable(_owner) {
        require(pantherPool != address(0), "Init: Zero address");

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
            _ZAccount.id != zACCOUNT_ID_ZERO &&
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

    /* ========== EXTERNAL FUNCTIONS ========== */

    function registerZAccount(
        bytes32 _pubRootSpendingKey,
        bytes32 _pubReadingKey,
        bytes32 _salt,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            !isPubRootSpendingKeyBlacklisted[_pubRootSpendingKey],
            "ZAR: Blacklisted pub root spending key"
        );

        bytes32 hash = toTypedMessageHash(
            _salt,
            _pubRootSpendingKey,
            _pubReadingKey
        );

        address masterEoa = verifySignature(hash, v, r, s);
        require(
            !isMasterEoaBlacklisted[masterEoa],
            "ZAR: Blacklisted master eoa"
        );

        ZAccount memory _ZAccount = getZAccount(masterEoa);
        require(_ZAccount.id == zACCOUNT_ID_ZERO, "ZAR: ZAccount exists");

        _ZAccount = ZAccount({
            _unused: uint176(0),
            id: uint24(_getNextZAccountId()),
            version: ZACCOUNT_VERSION,
            status: zACCOUNT_DEACTIVATED,
            pubRootSpendingKey: _pubRootSpendingKey,
            pubReadingKey: _pubReadingKey
        });

        _registry[masterEoa] = _ZAccount;

        emit ZAccountRegistered(_ZAccount);
    }

    //TDOD should accepts public inputs
    function activateZAccount(
        address _masterEOA,
        bytes32 nullifier,
        SnarkProof memory proof
    ) external {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        require(
            _ZAccount.id != zACCOUNT_ID_ZERO &&
                _ZAccount.status == zACCOUNT_DEACTIVATED,
            "ZAR: Not exist or not deactivated"
        );

        _ZAccount.status = zACCOUNT_ACTIVATED;

        require(!nullifiers[nullifier], "ZAR: nullifier exists");
        nullifiers[nullifier] = true;

        _registry[_masterEOA] = _ZAccount;

        _createZAccountUTXO(nullifier, proof);

        emit ZAccountStatusChanged(_masterEOA, uint256(zACCOUNT_ACTIVATED));
    }

    /* ========== ONLY FOR OWNER FUNCTIONS ========== */

    function updateBlacklistForMasterEoa(address masterEoa, bool isBlackListed)
        external
        onlyOwner
    {
        require(
            isMasterEoaBlacklisted[masterEoa] != isBlackListed,
            "ZAR: Invalid master eoa status"
        );
        isMasterEoaBlacklisted[masterEoa] = isBlackListed;

        emit BlacklistForMasterEoaUpdated(masterEoa, isBlackListed);
    }

    function updateBlacklistForPubRootSpendingKey(
        bytes32 pubRootSpendingKey,
        bool isBlackListed
    ) external onlyOwner {
        require(
            isPubRootSpendingKeyBlacklisted[pubRootSpendingKey] !=
                isBlackListed,
            "ZAR: Invalid pub root spending key status"
        );

        isPubRootSpendingKeyBlacklisted[pubRootSpendingKey] = isBlackListed;

        emit BlacklistForPubRootSpendingKeyUpdated(
            pubRootSpendingKey,
            isBlackListed
        );
    }

    function updateBlacklistForZAccountId(
        uint24 zAccountId,
        bytes32 leaf,
        bytes32[] calldata proofSiblings,
        bool isBlackListed
    ) external onlyOwner {
        if (isBlackListed)
            _addBlacklistZAccountId(zAccountId, leaf, proofSiblings);
        else _removeBlacklistZAccountId(zAccountId, leaf, proofSiblings);

        emit BlacklistForZAccountIdUpdated(uint256(zAccountId), isBlackListed);
    }

    function suspendZAccount(address _masterEOA) external onlyOwner {
        ZAccount memory _ZAccount = getZAccount(_masterEOA);
        require(
            _ZAccount.id != zACCOUNT_ID_ZERO &&
                _ZAccount.status != zACCOUNT_SUSPENDED,
            "ZAR: Not exist or already suspended"
        );

        _ZAccount.status = zACCOUNT_SUSPENDED;

        _registry[_masterEOA] = _ZAccount;

        emit ZAccountStatusChanged(_masterEOA, uint256(zACCOUNT_SUSPENDED));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _createZAccountUTXO(bytes32 nullifier, SnarkProof memory proof)
        private
    {
        require(PANTHER_POOL.createUtxo(proof), "ZAR: Utxo creation failed");
    }

    function _getNextZAccountId() internal returns (uint256 nextId) {
        nextId = zAccountIdTracker + 1;

        if (nextId & zACCOUNT_ID_MAX == zACCOUNT_ID_MAX)
            zAccountIdTracker = nextId + zACCOUNT_ID_JUMP_COUNT;
        else zAccountIdTracker = nextId;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

import "../merkleTrees/BinaryUpdatableMerkleTree.sol";

import { PoseidonT3 } from "../../crypto/Poseidon.sol";
import { FIELD_SIZE } from "../../crypto/SnarkConstants.sol";

abstract contract BlacklistedZAccountIdsTree is BinaryUpdatableMerkleTree {
    uint256 constant iZACCOUNT_ID_FLAG_POS_MASK = 0xFF;

    uint256 constant zACCOUNT_ID_JUMP_COUNT = 4;

    uint256 constant zACCOUNT_ID_ZERO = 0;
    uint256 constant zACCOUNT_ID_MAX = (2**8) - zACCOUNT_ID_JUMP_COUNT;

    function _getZAccountFlagAndLeafIndexes(uint24 zAccountId)
        internal
        returns (uint256 flagIndex, uint256 leafIndex)
    {
        // getting position which is between 1 and 252
        uint256 flagPos = zAccountId & iZACCOUNT_ID_FLAG_POS_MASK;

        require(
            flagPos > zACCOUNT_ID_ZERO && flagPos <= zACCOUNT_ID_MAX,
            "ZAR: invalid flag index"
        );

        flagIndex = flagPos - 1;
        // getting the 16 MSB from uint24
        leafIndex = zAccountId >> 8;
    }

    function _addBlacklistZAccountId(
        uint24 zAccountId,
        bytes32 leaf,
        bytes32[] memory proofSiblings
    ) internal {
        (uint256 flagIndex, uint256 leafIndex) = _getZAccountFlagAndLeafIndexes(
            zAccountId
        );

        uint256 newLeaf = uint256(leaf) | (1 << flagIndex);

        update(leaf, bytes32(newLeaf), leafIndex, proofSiblings);
    }

    function _removeBlacklistZAccountId(
        uint24 zAccountId,
        bytes32 leaf,
        bytes32[] memory proofSiblings
    ) internal {
        (uint256 flagIndex, uint256 leafIndex) = _getZAccountFlagAndLeafIndexes(
            zAccountId
        );

        uint256 newLeaf = uint256(leaf) & ~(1 << flagIndex);

        update(leaf, bytes32(newLeaf), leafIndex, proofSiblings);
    }

    function hash(bytes32 left, bytes32 right)
        internal
        pure
        override
        returns (bytes32)
    {
        require(
            uint256(left) < FIELD_SIZE && uint256(right) < FIELD_SIZE,
            "ZAR:TOO_LARGE_LEAF_INPUT"
        );
        return PoseidonT3.poseidon([left, right]);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity ^0.8.16;

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
pragma solidity 0.8.16;

import "./BinaryMerkleZeros.sol";

/**
 * @title BinaryIncrementalUpdatableMerkleTree
 * @notice
 * @dev
 */
abstract contract BinaryUpdatableMerkleTree is BinaryMerkleZeros {
    // `index` of the next leaf to insert
    // !!! NEVER access it directly from child contracts: `internal` to ease testing only
    uint256 internal _nextLeafIndex;

    // The nodes of the subtrees used in the last addition of a leaf (level -> [left node, right node])
    mapping(uint256 => bytes32[2]) internal _filledSubtrees;

    uint256 public constant LEAVES_NUM = 2**TREE_DEPTH;

    bytes32 public currentRoot;

    /**
     * @dev Update an existing leaf
     * @param leaf Leaf to be updated.
     * @param newLeaf New leaf.
     * @param leafIndex leafIndex
     * @param proofSiblings Path of the proof of membership.
     * @return _hash The new root after updating the tree
     leafIndex is eq to proofPathIndice[0] * 2**0 and ...
     */
    function update(
        bytes32 leaf,
        bytes32 newLeaf,
        uint256 leafIndex,
        bytes32[] memory proofSiblings
    ) internal returns (bytes32 _hash) {
        require(newLeaf != leaf, "BIUT: New leaf cannot be equal the old one");
        require(
            verify(leaf, leafIndex, proofSiblings),
            "BIUT: Leaf is not part of the tree"
        );

        _hash = newLeaf;
        uint256 proofPathIndice;

        for (uint256 i = 0; i < TREE_DEPTH; ) {
            // getting the bit at position `i` and check if it's 0 or 1
            proofPathIndice = (leafIndex >> i) & 1;

            if (proofPathIndice == 0) {
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

        currentRoot = _hash;
    }

    /**
     * @dev Verify if the path is correct and the leaf is part of the tree.
     * @param leaf Leaf to be updated.
     * @param leafIndex leafIndex
     * @param proofSiblings Path of the proof of membership.
     * @return True or false.
     */
    function verify(
        bytes32 leaf,
        uint256 leafIndex,
        bytes32[] memory proofSiblings
    ) internal view returns (bool) {
        require(
            proofSiblings.length == TREE_DEPTH,
            "BIUT: length of path is not correct"
        );
        require(leafIndex < LEAVES_NUM, "BIUT: invalid leaf index");

        bytes32 _hash = leaf;
        uint256 proofPathIndice;

        for (uint256 i = 0; i < TREE_DEPTH; ) {
            // getting the bit at position `i` and check if it's 0 or 1
            proofPathIndice = (leafIndex >> i) & 1;

            if (proofPathIndice == 0) {
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

    function hash(bytes32 left, bytes32 right)
        internal
        pure
        virtual
        returns (bytes32);
}

// SPDX-License-Identifier: BUSL-1.1
// SPDX-FileCopyrightText: Copyright 2023 Panther Ventures Limited Gibraltar
pragma solidity 0.8.16;

abstract contract ZAccountRegeistrationSignatureVerifier {
    string public constant ERC712_VERSION = "1";
    string public constant ERC712_NAME = "ZAccountsRegistry";

    uint8 public constant ZACCOUNT_VERSION = 0x01;

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

    function getDomainSeperator(bytes32 _salt) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    keccak256(bytes(ERC712_NAME)),
                    keccak256(bytes(ERC712_VERSION)),
                    _getChainId(),
                    address(this),
                    _salt
                )
            );
    }

    function getRegisteration(
        bytes32 _pubRootSpendingKey,
        bytes32 _pubReadingKey
    ) public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    REGISTRATION_TYPEHASH,
                    _pubRootSpendingKey,
                    _pubReadingKey,
                    uint256(ZACCOUNT_VERSION)
                )
            );
    }

    function toTypedMessageHash(
        bytes32 _salt,
        bytes32 _pubRootSpendingKey,
        bytes32 _pubReadingKey
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    getDomainSeperator(_salt),
                    getRegisteration(_pubRootSpendingKey, _pubReadingKey)
                )
            );
    }

    function verifySignature(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (address signer) {
        signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "invalid signature");
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