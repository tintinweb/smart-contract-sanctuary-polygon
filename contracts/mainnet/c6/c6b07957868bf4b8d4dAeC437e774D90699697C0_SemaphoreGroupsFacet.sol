// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { OwnableInternal } from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import { SemaphoreGroupsBase } from "./base/SemaphoreGroupsBase/SemaphoreGroupsBase.sol";
import { SemaphoreGroupsBaseStorage } from "./base/SemaphoreGroupsBase/SemaphoreGroupsBaseStorage.sol";


/**
 * @title SemaphoreGroupsFacet 
 */
contract SemaphoreGroupsFacet is SemaphoreGroupsBase, OwnableInternal {
    /**
     * @notice return the current version of SemaphoreGroupsFacet
     */
    function semaphoreGroupsFacetVersion() external pure returns (string memory) {
        return "0.1.0.alpha";
    }

    function _beforeCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual override onlyOwner {
        super._beforeCreateGroup(groupId, depth, zeroValue, admin);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IOwnableInternal } from './IOwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal is IOwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }

    function _owner() internal view virtual returns (address) {
        return OwnableStorage.layout().owner;
    }

    function _transferOwnership(address account) internal virtual {
        OwnableStorage.layout().setOwner(account);
        emit OwnershipTransferred(msg.sender, account);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroups, ISemaphoreGroupsBase} from "../../ISemaphoreGroups.sol";
import {SemaphoreGroupsBaseInternal} from "./SemaphoreGroupsBaseInternal.sol";
import {SemaphoreGroupsBaseStorage} from "./SemaphoreGroupsBaseStorage.sol";

/**
 * @title Base SemaphoreGroups functions, excluding optional extensions
 */
abstract contract SemaphoreGroupsBase is
    ISemaphoreGroups,
    SemaphoreGroupsBaseInternal
{
    using SemaphoreGroupsBaseStorage for SemaphoreGroupsBaseStorage.Layout;

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) external override {
        _beforeCreateGroup(groupId, depth, zeroValue, admin);

        _createGroup(groupId, depth, zeroValue);

        _setGroupAdmin(groupId, admin);

        _afterCreateGroup(groupId, depth, zeroValue, admin);
    }

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function updateGroupAdmin(uint256 groupId, address newAdmin)
        external
        override
    {
        _beforeUpdateGroupAdmin(groupId, newAdmin);

        _setGroupAdmin(groupId, newAdmin);

        emit GroupAdminUpdated(groupId, msg.sender, newAdmin);

        _afterUpdateGroupAdmin(groupId, newAdmin);
    }

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function addMembers(uint256 groupId, uint256[] memory identityCommitments)
        public
        override
    {
        _beforeAddMembers(groupId, identityCommitments);

        for (uint256 i; i < identityCommitments.length; i++) {
            addMember(groupId, identityCommitments[i]);
        }

        _afterAddMembers(groupId, identityCommitments);
    }

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override {
        _beforeRemoveMember(groupId, identityCommitment, proofSiblings, proofPathIndices);

        _removeMember(
            groupId,
            identityCommitment,
            proofSiblings,
            proofPathIndices
        );

        _afterRemoveMember(
            groupId,
            identityCommitment,
            proofSiblings,
            proofPathIndices
        );
    }

    /**
     * @inheritdoc ISemaphoreGroups
     */
    function getRoot(uint256 groupId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _getRoot(groupId);
    }

    /**
     * @inheritdoc ISemaphoreGroups
     */
    function getDepth(uint256 groupId)
        public
        view
        virtual
        override
        returns (uint8)
    {
        return _getDepth(groupId);
    }

    /**
     * @inheritdoc ISemaphoreGroups
     */
    function getNumberOfLeaves(uint256 groupId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _getNumberOfLeaves(groupId);
    }

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function getGroupAdmin(uint256 groupId)
        public
        view
        virtual
        override
        returns (address)
    {
        return _getGroupAdmin(groupId);
    }

    /**
     * @inheritdoc ISemaphoreGroupsBase
     */
    function addMember(uint256 groupId, uint256 identityCommitment)
        public
        override
    {
        _beforeAddMember(groupId, identityCommitment);

        _addMember(groupId, identityCommitment);

        _afterAddMember(groupId, identityCommitment);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;


/**
 * @title Semaphoregroups Storage base on Diamond Standard Layout storage pattern
 */
library SemaphoreGroupsBaseStorage {
    struct Layout {
        // groupId -> admin
        mapping(uint256 => address) groupAdmins;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreGroupsBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setGroupAdmin(
        Layout storage s,
        uint256 groupId,
        address admin
    ) internal {
        s.groupAdmins[groupId] = admin;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroupsBase} from "./base/SemaphoreGroupsBase/ISemaphoreGroupsBase.sol";

/**
 * @title SemaphoreGroups interface
 */
interface ISemaphoreGroups is ISemaphoreGroupsBase {
    /**
     * @notice query the last root hash of a group
     * @param groupId: Id of the group
     * @return root hash of the group.
     */
    function getRoot(uint256 groupId) external view returns (uint256);

    /**
     * @notice query the depth of the tree of a group
     * @param groupId: Id of the group
     * @return depth of the group tree
     */
    function getDepth(uint256 groupId) external view returns (uint8);

    /**
     * @notice query the number of tree leaves of a group
     * @param groupId: Id of the group
     * @return number of tree leaves
     */
    function getNumberOfLeaves(uint256 groupId) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroupsInternal} from "./ISemaphoreGroupsInternal.sol";
import {SemaphoreGroupsBaseStorage} from "./SemaphoreGroupsBaseStorage.sol";
import {SNARK_SCALAR_FIELD} from "../../../utils/Constants.sol";
import {IncrementalBinaryTreeInternal} from "../../../utils/cryptography/IncrementalBinaryTree/IncrementalBinaryTreeInternal.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreGroupsBaseInternal is ISemaphoreGroupsInternal, IncrementalBinaryTreeInternal {
    using SemaphoreGroupsBaseStorage for SemaphoreGroupsBaseStorage.Layout;    

    modifier onlyGroupAdmin(uint256 groupId) {
        require(
            _getGroupAdmin(groupId) == msg.sender,
            "SemaphoreGroupsBase: SENDER_NON_GROUP_ADMIN"
        );
        _;
    }

    modifier isScalarField(uint256 scalar) {
        require(scalar < SNARK_SCALAR_FIELD, "SCALAR_OUT_OF_BOUNDS");
        _;
    }

    modifier groupExists(uint256 groupId) {
        require(_getDepth(groupId) != 0, "SemaphoreGroupsBase: GROUP_ID_NOT_EXIST");
        _;
    }

    /**
     * @notice internal function creates a new group by initializing the associated tree
     * @param groupId: group id of the group
     * @param depth: depth of the tree
     * @param zeroValue: zero value of the tree
     */
    function _createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue
    ) internal virtual {
        _init(groupId, depth, zeroValue);

        emit GroupCreated(groupId, depth, zeroValue);
    }

    function _setGroupAdmin(uint256 groupId, address admin) internal {
        SemaphoreGroupsBaseStorage.layout().setGroupAdmin(groupId, admin);

        emit GroupAdminUpdated(groupId, address(0), admin);
    }

    /**
     * @notice  internal function adds an identity commitment to an existing group
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     */
    function _addMember(uint256 groupId, uint256 identityCommitment)
        internal
        virtual
    {       
        _insert(groupId, identityCommitment);

        uint256 root = _getRoot(groupId);

        emit MemberAdded(groupId, identityCommitment, root);
    }

    /**
     * @notice  internal function removes an identity commitment from an existing group. A proof of membership is
     * needed to check if the node to be deleted is part of the tree
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param proofSiblings: Array of the sibling nodes of the proof of membership.
     * @param proofPathIndices: Path of the proof of membership.
     */
    function _removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        _remove(groupId, identityCommitment, proofSiblings, proofPathIndices);

        uint256 root = _getRoot(groupId);

        emit MemberRemoved(groupId, identityCommitment, root);
    }

    /**
     * @notice internal query query a groupAdmin.
     * @param groupId: the groupId of the group.
     */
    function _getGroupAdmin(uint256 groupId)
        internal
        view
        virtual
        returns (address)
    {
        return SemaphoreGroupsBaseStorage.layout().groupAdmins[groupId];
    }

    /**
     * @notice hook that is called before createGroup
     */
    function _beforeCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual isScalarField(groupId) {
        require(
            _getDepth(groupId) == 0,
            "SemaphoreGroupsBase: GROUP_ID_EXISTS"
        );
        require(admin != address(0), "SemaphoreGroupsBase: ADMIN_ZERO_ADDRESS");
    }

    /**
     * @notice hook that is called after createGroup
     */
    function _afterCreateGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) internal view virtual {}

    /**
     * @notice hook that is called before updateGroupAdmin
     */
    function _beforeUpdateGroupAdmin(
        uint256 groupId,
        address newAdmin
    ) 
        internal view virtual 
        groupExists(groupId)
        onlyGroupAdmin(groupId)
    {}

    /**
     * @notice hook that is called after updateGroupAdmin
     */
    function _afterUpdateGroupAdmin(uint256 groupId, address newAdmin) internal view virtual {}

    /**
     * @notice hook that is called before addMembers
     */
    function _beforeAddMembers(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) 
        internal view virtual
        groupExists(groupId) 
        onlyGroupAdmin(groupId) {}

    /**
     * @notice hook that is called after addMembers
     */
    function _afterAddMembers(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) internal view virtual {}

    /**
     * @notice hook that is called before addMember
     */
    function _beforeAddMember(
        uint256 groupId,
        uint256 identityCommitment
    ) 
        internal view virtual
        groupExists(groupId)
        onlyGroupAdmin(groupId)
    {}

     /**
     * @notice hook that is called before addMember
     */
    function _afterAddMember(
        uint256 groupId,
        uint256 identityCommitment
    ) internal view virtual {}


    /**
     * @notice hook that is called before removeMember
     */
    function _beforeRemoveMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) 
        internal view virtual 
        groupExists(groupId) 
        onlyGroupAdmin(groupId)
    {}

    /**
     * @notice hook that is called after removeMember
     */
    function _afterRemoveMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal view virtual {}

    /**
     * @notice hook that is called before removeMembers
     */
    function _beforeRemoveMembers(
        uint256 groupId,
        RemoveMembersDTO[] calldata members
    ) 
        internal view virtual
        groupExists(groupId) 
        onlyGroupAdmin(groupId)
    {
        require(members.length > 0, "SemaphoreGroupsBase: NO_MEMBER_TO_REMOVE");
    }

    /**
     * @notice hook that is called after removeMembers
     */
    function _afterRemoveMembers(
        uint256 groupId,
        RemoveMembersDTO[] calldata members
    ) internal view virtual groupExists(groupId) {}

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {ISemaphoreGroupsInternal} from "./ISemaphoreGroupsInternal.sol";

/**
 * @title SemaphoreGroups base interface
 */
interface ISemaphoreGroupsBase is ISemaphoreGroupsInternal { 
    /**
     * @notice Updates the group admin.
     * @param groupId: Id of the group.
     * @param newAdmin: New admin of the group.
     *
     * Emits a {GroupAdminUpdated} event.
     */
    function updateGroupAdmin(uint256 groupId, address newAdmin) external;
    
    /**
     * @notice ceates a new group by initializing the associated tree.
     * @param groupId: Id of the group.
     * @param depth: Depth of the tree.
     * @param zeroValue: Zero value of the tree.
     * @param admin: Admin of the group.
     *
     * Emits {GroupCreated} and {GroupAdminUpdated} events.
     */
    function createGroup(
        uint256 groupId,
        uint8 depth,
        uint256 zeroValue,
        address admin
    ) external;

    /**
     * @notice adds identity commitments to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitments: array of new identity commitments.
     *
     * TODO: hash the identityCommitments to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits multiple {MemberAdded} events.
     */
    function addMembers(uint256 groupId, uint256[] memory identityCommitments)
        external;

    /**
     * @notice add a identity commitment to an existing group.
     * @param groupId: Id of the group.
     * @param identityCommitment: the identity commitment of the member.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
     *
     *
     * Emits a {MemberAdded} event.
     */
    function addMember(uint256 groupId, uint256 identityCommitment)
        external;

    /**
     * @notice removes an identity commitment from an existing group. A proof of membership is
     *         needed to check if the node to be deleted is part of the tree.
     * @param groupId: Id of the group.
     * @param identityCommitment: existing identity commitment to be deleted.
     * @param proofSiblings: array of the sibling nodes of the proof of membership.
     * @param proofPathIndices: path of the proof of membership.
     *
     * TODO: hash the identityCommitment to make sure users can't see
     *       which identityCommitment belongs to the guardian
      *
     * Emits a {MemberRemoved} event.
     */
    function removeMember(
        uint256 groupId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /**
     * @notice query a groupAdmin.
     * @param groupId: the groupId of the group.
     */
    function getGroupAdmin(uint256 groupId) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreGroups interface needed by internal functions
 */
interface ISemaphoreGroupsInternal {
    struct RemoveMembersDTO {
        uint256 identityCommitment;
        uint256[] proofSiblings;
        uint8[] proofPathIndices;
    }

    /**
     * @notice emitted when a new group is created
     * @param groupId: group id of the group
     * @param depth: depth of the tree
     * @param zeroValue: zero value of the tree
     */
    event GroupCreated(uint256 indexed groupId, uint8 depth, uint256 zeroValue);

    /**
     * @notice emitted when an admin is assigned to a group
     * @param groupId: Id of the group
     * @param oldAdmin: Old admin of the group
     * @param newAdmin: New admin of the group
     */
    event GroupAdminUpdated(
        uint256 indexed groupId,
        address indexed oldAdmin,
        address indexed newAdmin
    );

    /**
     * @notice emitted when a new identity commitment is added
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberAdded(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );

    /**
     * @notice emitted when a new identity commitment is removed
     * @param groupId: group id of the group
     * @param identityCommitment: New identity commitment
     * @param root: New root hash of the tree
     */
    event MemberRemoved(
        uint256 indexed groupId,
        uint256 identityCommitment,
        uint256 root
    );
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// semaphore
uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
uint8 constant MAX_DEPTH = 32;

// semaphoreGroupsBase
bytes32 constant GET_GROUP_ADMIN_TYPEHASH = keccak256(
  "getGroupAdmin(uint256)"
);

bytes32 constant UPDATE_GROUP_ADMIN_TYPEHASH = keccak256(
  "createGroup(uint256,uint8,uint256,address)"
);

bytes32 constant CREATE_GROUP_TYPEHASH = keccak256(
  "createGroup(uint256,uint8,uint256,address)"
);

bytes32 constant ADD_MEMBER_TYPEHASH = keccak256(
  "addMember(uint256,uint256)"
);

bytes32 constant REMOVE_MEMBER_TYPEHASH = keccak256(
  "removeMember(uint256,uint256 identityCommitment,uint256[] calldata,uint8[] calldata)"
);

bytes32 constant ADD_MEMBERS_TYPEHASH = keccak256(
  "addMember(uint256,uint256[] memory)"
);

bytes32 constant REMOVE_MEMBERS_TYPEHASH = keccak256(
  "removeMembers(uint256,RemoveMembersDTO[] calldata)"
);

// guardians
uint constant MIN_GUARDIANS = 3;
uint constant MAX_GUARDIANS = 10;
uint constant GUARDIAN_PENDING_PERIODS = 3 days;

bytes32 constant GET_GUARDIAN_TYPEHASH = keccak256(
  "getGuardian(uint256)"
);

bytes32 constant GET_GUARDIANS_TYPEHASH = keccak256(
  "getGuardians(bool)"
);

bytes32 constant NUM_GUARDIANS_TYPEHASH = keccak256(
  "numGuardians(bool)"
);

bytes32 constant REQUIRE_MAJORITY_TYPEHASH = keccak256(
  "requireMajority(GuardianDTO[] calldata)"
);

bytes32 constant SET_INITIAL_GUARDIANS_TYPEHASH = keccak256(
  "setInitialGuardians(uint256[] memory)"
);

bytes32 constant REMOVE_GUARDIAN_TYPEHASH = keccak256(
  "removeGuardian(uint256)"
);

bytes32 constant REMOVE_GUARDIANS_TYPEHASH = keccak256(
  "removeGuardians(uint256[] memory)"
);

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {SNARK_SCALAR_FIELD, MAX_DEPTH} from "../../Constants.sol";
import {PoseidonT3} from "../Hashes.sol";
import {IIncrementalBinaryTreeInternal} from "./IIncrementalBinaryTreeInternal.sol";
import {IncrementalBinaryTreeStorage} from "./IncrementalBinaryTreeStorage.sol";

/**
 * @title Base IncrementalBinaryTree internal functions, excluding optional extensions
 */
abstract contract IncrementalBinaryTreeInternal is IIncrementalBinaryTreeInternal {
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.Layout;
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.IncrementalTreeData;

    /**
     * @notice See {ISemaphoreGroups-getRoot}
     */
    function _getRoot(uint256 treeId) internal view virtual returns (uint256) {
        return IncrementalBinaryTreeStorage.layout().trees[treeId].root;
    }

    /**
     * @notice See {ISemaphoreGroups-getDepth}
     */
    function _getDepth(uint256 treeId) internal view virtual returns (uint8) {
        return IncrementalBinaryTreeStorage.layout().trees[treeId].depth;
    }

    function _getZeroes(uint256 treeId, uint256 leafIndex)
        internal
        view
        returns (uint256)
    {
        return
            IncrementalBinaryTreeStorage.layout().trees[treeId].zeroes[
                leafIndex
            ];
    }

    /**
     * @notice See {ISemaphoreGroups-getNumberOfLeaves}
     */
    function _getNumberOfLeaves(uint256 treeId)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            IncrementalBinaryTreeStorage.layout().trees[treeId].numberOfLeaves;
    }

    /**
     * @notice query trees of a group
     */
    function getTreeData(uint256 treeId)
        internal
        view
        virtual
        returns (IncrementalBinaryTreeStorage.IncrementalTreeData storage treeData)
    {
        return IncrementalBinaryTreeStorage.layout().trees[treeId];
    }

    /**
     * @notice initializes a tree
     * @param treeId:  group id of the group
     * @param depth: depth of the tree
     * @param zero: zero value to be used
     */
    function _init(
        uint256 treeId,
        uint8 depth,
        uint256 zero
    ) internal virtual {
        require(zero < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(depth > 0 && depth <= MAX_DEPTH, "IncrementalBinaryTree: tree depth must be between 1 and 32");

        IncrementalBinaryTreeStorage.layout().setDepth(treeId, depth);

        for (uint8 i = 0; i < depth; i++) {
            IncrementalBinaryTreeStorage.layout().setZeroes(treeId, i, zero);
            zero = PoseidonT3.poseidon([zero, zero]);
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, zero);
    }

    /**
     * @notice inserts a leaf in the tree
     * @param treeId:  group id of the group
     * @param leaf: Leaf to be inserted
     */
    function _insert(uint256 treeId, uint256 leaf) internal virtual {       
        uint256 index = _getNumberOfLeaves(treeId);
        uint256 hash = leaf;
        IncrementalBinaryTreeStorage.IncrementalTreeData
            storage data = IncrementalBinaryTreeStorage.layout().trees[treeId];

        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(index < 2**_getDepth(treeId), "IncrementalBinaryTree: tree is full");

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
            if (index % 2 == 0) {
                data.lastSubtrees[i] = [hash, _getZeroes(treeId, i)];
            } else {
                data.lastSubtrees[i][1] = hash;
            }

            hash = PoseidonT3.poseidon(data.lastSubtrees[i]);
            index /= 2;
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, hash);
        IncrementalBinaryTreeStorage.layout().setNumberOfLeaves(treeId);
    }

    /**
     * @notice removes a leaf from the tree
     * @param treeId:  group id of the group
     * @param leaf: leaf to be removed
     * @param proofSiblings: array of the sibling nodes of the proof of membership
     * @param proofPathIndices: path of the proof of membership
     */
    function _remove(
        uint256 treeId,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) internal virtual {
        require(_verify(treeId, leaf, proofSiblings, proofPathIndices), "IncrementalBinaryTree: leaf is not part of the tree");
        
        IncrementalBinaryTreeStorage.IncrementalTreeData
            storage data = IncrementalBinaryTreeStorage.layout().trees[treeId];

        uint256 hash = _getZeroes(treeId, 0);

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
            if (proofPathIndices[i] == 0) {
                if (proofSiblings[i] == data.lastSubtrees[i][1]) {
                    data.lastSubtrees[i][0] = hash;
                }

                hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
            } else {
                if (proofSiblings[i] == data.lastSubtrees[i][0]) {
                    data.lastSubtrees[i][1] = hash;
                }

                hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
            }
        }

        IncrementalBinaryTreeStorage.layout().setRoot(treeId, hash);
    }

    /**
     * @notice verify if the path is correct and the leaf is part of the tree
     * @param leaf: leaf to be removed
     * @param proofSiblings: array of the sibling nodes of the proof of membership
     * @param proofPathIndices: path of the proof of membership
     * @return True or false.
     */
    function _verify(
        uint256 treeId,
        uint256 leaf,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) private view returns (bool) {
        require(leaf < SNARK_SCALAR_FIELD, "IncrementalBinaryTree: leaf must be < SNARK_SCALAR_FIELD");
        require(proofPathIndices.length == _getDepth(treeId) && proofSiblings.length == _getDepth(treeId), "IncrementalBinaryTree: length of path is not correct");

        uint256 hash = leaf;

        for (uint8 i = 0; i < _getDepth(treeId); i++) {
        require(
            proofSiblings[i] < SNARK_SCALAR_FIELD,
            "IncrementalBinaryTree: sibling node must be < SNARK_SCALAR_FIELD"
        );

        if (proofPathIndices[i] == 0) {
            hash = PoseidonT3.poseidon([hash, proofSiblings[i]]);
        } else {
            hash = PoseidonT3.poseidon([proofSiblings[i], hash]);
        }
        }

        return hash == _getRoot(treeId);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library PoseidonT3 {
    function poseidon(uint256[2] memory) public pure returns (uint256) {}
}

library PoseidonT6 {
    function poseidon(uint256[5] memory) public pure returns (uint256) {}
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial IncrementalBinaryTree interface needed by internal functions
 */
interface IIncrementalBinaryTreeInternal {
    event TreeCreated(uint256 id, uint8 depth);
    event LeafInserted(uint256 indexed treeId, uint256 leaf, uint256 root);
    event LeafRemoved(uint256 indexed treeId, uint256 leaf, uint256 root);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library IncrementalBinaryTreeStorage {
    struct IncrementalTreeData {
        uint8 depth;
        uint256 root;
        uint256 numberOfLeaves;
        mapping(uint256 => uint256) zeroes;
        mapping(uint256 => uint256[2]) lastSubtrees;
    }

    struct Layout {
         mapping(uint256 => IncrementalTreeData) trees;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.IncrementalBinaryTree");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setDepth(
        Layout storage s,
        uint256 treeId,
        uint8 depth
    ) internal {
        s.trees[treeId].depth = depth;
    }

    function setRoot(
        Layout storage s,
        uint256 treeId,
        uint256 root
    ) internal {
        s.trees[treeId].root = root;
    }

    function setNumberOfLeaves(Layout storage s, uint256 treeId) internal {
        s.trees[treeId].numberOfLeaves += 1;
    }

    function setZeroes(
        Layout storage s,
        uint256 treeId,
        uint256 leafIndex,
        uint256 zeroValue
    ) internal {
        s.trees[treeId].zeroes[leafIndex] = zeroValue;
    }
}