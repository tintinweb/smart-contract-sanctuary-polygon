// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { SafeOwnableInternal } from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";

import { IGuardianFacet } from "../interfaces/IGuardianFacet.sol";
import { Guardian } from "./Guardian.sol";
import { GuardianStorage } from "./GuardianStorage.sol";

import { SemaphoreGroupsBaseInternal } from "../semaphore/base/SemaphoreGroupsBase/SemaphoreGroupsBaseInternal.sol";
import { SemaphoreGroupsBaseStorage } from "../semaphore/base/SemaphoreGroupsBase/SemaphoreGroupsBaseStorage.sol";


/**
 * @title GuardianFacet 
 */
contract GuardianFacet is 
    IGuardianFacet, 
    Guardian, 
    SemaphoreGroupsBaseInternal,
    SafeOwnableInternal 
{
    /**
     * @inheritdoc IGuardianFacet
     */
    function addGuardians(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) external override groupExists(groupId) {
        _beforeSetInitialGuardians(identityCommitments);

        setInitialGuardians(identityCommitments);
        
        for (uint256 i; i < identityCommitments.length; i++) {
            _addMember(groupId, identityCommitments[i]);
        }
    }

    /**
     * @inheritdoc IGuardianFacet
     */
    function addGuardian(
        uint256 groupId,
        uint256 hashId,
        uint256 identityCommitment
    ) external override {
        _beforeAddGuardian(hashId);

        _beforeAddMember(groupId, identityCommitment);

        require(_addGuardian(hashId), "GuardianFacet: FAILED_TO_ADD_GUARDIAN");

        _addMember(groupId, identityCommitment);
        
        _afterAddMember(groupId, identityCommitment);
    }

    /**
     * @inheritdoc IGuardianFacet
     */
    function removeGuardian(
        uint256 groupId,
        uint256 hashId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external override {
        _beforeRemoveGuardian(hashId);
        
        require(_removeGuardian(hashId), "GuardianFacet: FAILED_TO_REMOVE_GUARDIAN");

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
     * @notice return the current version of GuardianFacet
     */
    function guardianFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }

     function _beforeSetInitialGuardians(uint256[] memory guardians) 
        internal
        view
        virtual
        override
        onlyOwner
    {
        super._beforeSetInitialGuardians(guardians);
    }

    function _beforeAddGuardian(uint256 hashId) internal view virtual override onlyOwner {
        super._beforeAddGuardian(hashId);
    }

    function _beforeRemoveGuardian(uint256 hashId) internal view virtual override onlyOwner {
        super._beforeRemoveGuardian(hashId);
    }

    function _beforeRemoveGuardians(uint256[] memory guardians) 
        internal view virtual override onlyOwner 
    {
        super._beforeRemoveGuardians(guardians);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ISafeOwnableInternal } from './ISafeOwnableInternal.sol';
import { OwnableInternal } from './OwnableInternal.sol';
import { OwnableStorage } from './OwnableStorage.sol';
import { SafeOwnableStorage } from './SafeOwnableStorage.sol';

abstract contract SafeOwnableInternal is ISafeOwnableInternal, OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;
    using SafeOwnableStorage for SafeOwnableStorage.Layout;

    modifier onlyNomineeOwner() {
        require(
            msg.sender == _nomineeOwner(),
            'SafeOwnable: sender must be nominee owner'
        );
        _;
    }

    /**
     * @notice get the nominated owner who has permission to call acceptOwnership
     */
    function _nomineeOwner() internal view virtual returns (address) {
        return SafeOwnableStorage.layout().nomineeOwner;
    }

    /**
     * @notice accept transfer of contract ownership
     */
    function _acceptOwnership() internal virtual {
        OwnableStorage.Layout storage l = OwnableStorage.layout();
        emit OwnershipTransferred(l.owner, msg.sender);
        l.setOwner(msg.sender);
        SafeOwnableStorage.layout().setNomineeOwner(address(0));
    }

    /**
     * @notice set nominee owner, granting permission to call acceptOwnership
     */
    function _transferOwnership(address account) internal virtual override {
        SafeOwnableStorage.layout().setNomineeOwner(account);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import {IGuardian} from "../guardian/IGuardian.sol";

/**
 * @title GuardianFacet interface
 */
interface IGuardianFacet is IGuardian {
    /**
     * @notice add guardians
     * @param groupId: the group id of the semaphore group
     * @param identityCommitments: the identity commitments of guardians
     *
     */
     function addGuardians(
        uint256 groupId,
        uint256[] memory identityCommitments
    ) external;

    /**
     * @notice add guardian
     * @param groupId: the group id of the semaphore group
     * @param hashId: the hash id of the guardian
     * @param identityCommitment: the identity commitment of the guardian
     *
     */
    function addGuardian(uint256 groupId, uint256 hashId, uint256 identityCommitment) external;

    /**
     * @notice remove guardian
     * @param groupId: the group id of the semaphore group
     * @param hashId: the hash id of the guardian
     * @param identityCommitment: existing identity commitment to be deleted
     * @param proofSiblings: array of the sibling nodes of the proof of membership of the semaphoregroup.
     * @param proofPathIndices: path of the proof of membership of the semaphoregroup
     *
     */
    function removeGuardian(
        uint256 groupId,
        uint256 hashId,
        uint256 identityCommitment,
        uint256[] calldata proofSiblings,
        uint8[] calldata proofPathIndices
    ) external;

    /**
     * @notice return the current version of GuardianFacet
     */
    function guardianFacetVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IGuardian} from "./IGuardian.sol";
import {GuardianInternal} from "./GuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";

/**
 * @title Guardian functions 
 */
abstract contract Guardian is IGuardian, GuardianInternal {
    /**
     * @inheritdoc IGuardian
     */
    function removeGuardians(uint256[] memory guardians) external override {
        _beforeRemoveGuardians(guardians);

         for (uint i = 0; i < guardians.length; i++) {
            uint256 hashId = guardians[i];
            require(removeGuardian(hashId), "Guardian: FAILED_TO_REMOVE_GUARDIAN");
         }         
        
        _afterRemoveGuardians(guardians);
    }

    /**
     * @inheritdoc IGuardian
     */
    function cancelPendingGuardians() external override {
        // TODO: implement
    }

    /**
     * @inheritdoc IGuardian
     */
    function setInitialGuardians(uint256[] memory guardians) public override {
        _beforeSetInitialGuardians(guardians);

         for (uint i = 0; i < guardians.length; i++) {
            uint256 hashId = guardians[i];
            require(addGuardian(hashId), "Guardian: FAILED_TO_ADD_GUARDIAN");         
        }

        _afterSetInitialGuardians(guardians);
    }

    /**
     * @inheritdoc IGuardian
     */
    function addGuardian(uint256 hashId) public override returns(bool){
        _beforeAddGuardian(hashId);
        
        return _addGuardian(hashId);
    }

    /**
     * @inheritdoc IGuardian
     */
    function removeGuardian(uint256 hashId) public override returns(bool) {
        _beforeRemoveGuardian(hashId);
        
        return _removeGuardian(hashId);
    }

    /**
     * @inheritdoc IGuardian
     */
    function getGuardian(uint256 hashId) external view override returns (GuardianStorage.Guardian memory) {
        uint index = _getGuardianIndex(hashId);
        require(index > 0, "Guardian: GUARDIAN_NOT_FOUND");

        uint arrayIndex = index - 1;
        return _getGuardian(arrayIndex);
    }

    /**
     * @inheritdoc IGuardian
     */
    function getGuardians(bool includePendingAddition) public view override returns (GuardianStorage.Guardian[] memory) {
        return _getGuardians(includePendingAddition);
    }

    /**
     * @inheritdoc IGuardian
     */
    function numGuardians(bool includePendingAddition) external view override returns (uint256) {
        return _numGuardians(includePendingAddition);
    }

    /**
     * @inheritdoc IGuardian
     */
    function requireMajority(GuardianDTO[] calldata guardians) external view override {
        _requireMajority(guardians);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

/**
 * @title Guardian Storage base on Diamond Standard Layout storage pattern
 */
library GuardianStorage {
    using SafeCast for uint;

    struct Guardian {
        uint256 hashId;
        uint8 status;
        uint64 timestamp;
    }
    struct Layout {
        // hashId -> guardianIdx
        mapping(uint256 => uint) guardianIndex;

        Guardian[] guardians;
        
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Guardian");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice store an new guardian to the storage.
     * @param hashId: the hashId of the guardian.
     * @param validSince: the valid period since the guardian is added.
     * @return returns a boolean value indicating whether the operation succeeded.
     */
    function storeGuardian(
        Layout storage s,
        uint256 hashId,
        uint validSince
    ) internal returns (bool){
        uint arrayIndex = s.guardians.length;
        uint index = arrayIndex + 1;
        s.guardians.push(
            Guardian(
                hashId,
                1,
                validSince.toUint64()
            )
        );
        s.guardianIndex[hashId] = index;
        return true;
    }

    /**
     * @notice delete a guardian from the storage,
     * we are going to switch the last item in the array with the one we are replacing.
     * That way when we pop, we are removing the correct item. 
     *
     * There are two cases we need to handle:
     *  - the address we are removing is not the last address in the array
     *  - or it is the last address in the array. 
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     */
     function deleteGuardian(
        Layout storage s,
        uint256 hashId
    ) internal returns (bool) {
        uint index = s.guardianIndex[hashId];
        require(index > 0, "Guardian: GUARDIAN_NOT_EXISTS");

        uint arrayIndex = index - 1;
         require(arrayIndex >= 0, "Guardian: ARRAY_INDEX_OUT_OF_BOUNDS");

        if(arrayIndex != s.guardians.length - 1) {
            s.guardians[arrayIndex] = s.guardians[s.guardians.length - 1];
            s.guardianIndex[s.guardians[arrayIndex].hashId] = index;
        }
        s.guardians.pop();
        delete s.guardianIndex[hashId];
        return true;
    }

    /**
     * @notice delete all guardians from the storage.
     */
    function deleteAllGuardians(Layout storage s) internal {
        uint count = s.guardians.length;

        for(int i = int(count) - 1; i >= 0; i--) {
            uint256 hashId = s.guardians[uint(i)].hashId;
            deleteGuardian(s, hashId);
        }
    }
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

import { IOwnableInternal } from './IOwnableInternal.sol';

interface ISafeOwnableInternal is IOwnableInternal {}

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

library SafeOwnableStorage {
    struct Layout {
        address nomineeOwner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.SafeOwnable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setNomineeOwner(Layout storage l, address nomineeOwner) internal {
        l.nomineeOwner = nomineeOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC173Internal } from '../IERC173Internal.sol';

interface IOwnableInternal is IERC173Internal {}

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

import {IGuardianInternal} from "./IGuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";

/**
 * @title Guardian interface 
 */
interface IGuardian is IGuardianInternal {
    /**
     * @notice set multiple guardians to the group.
     * @param guardians: guardians to be added.
     *
     * Emits multiple {GuardianAdded} event.
     */
    function setInitialGuardians(uint256[] memory guardians) external;

    /**
     * @notice add a new guardian to the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {GuardianAdded} event.
     */
    function addGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove guardian from the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {GuardianRemoved} event.
     */
    function removeGuardian(uint256 hashId) external returns(bool);

    /**
     * @notice remove multiple guardians from the group.
     * @param guardians: guardians to be removed.
     *
     * Emits multiple {GuardianRemoved} event.
     */
    function removeGuardians(uint256[] memory guardians) external;


    /**
     * @notice remove all pending guardians from the group.
     *
     * Emits multiple {GuardianRemoved} event.
     */
    function cancelPendingGuardians() external;

    /**
     * @notice query a guardian.
     * @param hashId: the hashId of the guardian.
     */
    function getGuardian(uint256 hashId) external returns (GuardianStorage.Guardian memory);

    /**
     * @notice query all guardians from the storage
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function getGuardians(bool includePendingAddition)
        external view returns (GuardianStorage.Guardian[] memory);

    /**
     * @notice query the length of the active guardians
     * @param includePendingAddition: whether to include pending addition guardians
     */
    function numGuardians(bool includePendingAddition) external view returns (uint256);

    
    /**
     * @notice check if the guardians are majority.
     * @param guardians: list of guardians to check.
     */
    function requireMajority(GuardianDTO[] calldata guardians) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial Guardian interface needed by internal functions
 */
interface IGuardianInternal {
    enum GuardianStatus
    {
        REMOVE,    // Being removed or removed after validUntil timestamp
        ADD        // Being added or added after validSince timestamp.
    }

    struct GuardianDTO {        
        uint256 hashId;
    }

    /**
     * @notice emitted when a new Guardian is added
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianAdded(uint256 indexed hashId, uint effectiveTime);


    /**
     * @notice emitted when a Guardian is removed
     * @param hashId: the hashId of the guardian
     * @param effectiveTime: the timestamp when the guardian is added
     */
    event GuardianRemoved (uint256 indexed hashId, uint effectiveTime);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Helper library for safe casting of uint and int values
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library SafeCast {
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, 'SafeCast: value does not fit');
        return uint224(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, 'SafeCast: value does not fit');
        return uint128(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, 'SafeCast: value does not fit');
        return uint96(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, 'SafeCast: value does not fit');
        return uint64(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, 'SafeCast: value does not fit');
        return uint32(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, 'SafeCast: value does not fit');
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, 'SafeCast: value does not fit');
        return uint8(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, 'SafeCast: value must be positive');
        return uint256(value);
    }

    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            'SafeCast: value does not fit'
        );
        return int128(value);
    }

    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            'SafeCast: value does not fit'
        );
        return int64(value);
    }

    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            'SafeCast: value does not fit'
        );
        return int32(value);
    }

    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            'SafeCast: value does not fit'
        );
        return int16(value);
    }

    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            'SafeCast: value does not fit'
        );
        return int8(value);
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(
            value <= uint256(type(int256).max),
            'SafeCast: value does not fit'
        );
        return int256(value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {SafeCast} from "@solidstate/contracts/utils/SafeCast.sol";

import {IGuardianInternal} from "./IGuardianInternal.sol";
import {GuardianStorage} from "./GuardianStorage.sol";
import {MIN_GUARDIANS, MAX_GUARDIANS, GUARDIAN_PENDING_PERIODS} from "../utils/Constants.sol";

/**
 * @title Guardian internal functions, excluding optional extensions
 */
abstract contract GuardianInternal is IGuardianInternal {
    using GuardianStorage for GuardianStorage.Layout;
    using SafeCast for uint;

    modifier isGuardian(uint256 hashId, bool includePendingAddition) {
        require(hashId != 0, "Guardian: GUARDIAN_HASH_ID_IS_ZERO");

        uint guardianIndex = _getGuardianIndex(hashId);
        require(guardianIndex > 0, "Guardian: GUARDIAN_NOT_FOUND");

        uint arrayIndex = guardianIndex - 1;

        GuardianStorage.Guardian memory g = _getGuardian(arrayIndex);
        require(_isActiveOrPendingAddition(g, includePendingAddition), "Guardian: GUARDIAN_NOT_ACTIVE");
        _;
    }

    modifier isMinGuardian(uint256[] memory guardians) {
        require(guardians.length >= MIN_GUARDIANS, "Guardian: MIN_GUARDIANS_NOT_MET");
        _;
    }

    modifier isMaxGuardian(uint256[] memory guardians) {
        require(guardians.length <= MAX_GUARDIANS, "Guardian: MAX_GUARDIANS_EXCEEDED");
        _;
    }

    /**
     * @notice internal function add a new guardian to the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded. 
     *
     * Emits a {GuardianAdded} event.
     */
     function _addGuardian(uint256 hashId) internal virtual returns(bool) {
        uint numGuardians = _numGuardians(true);
        require(numGuardians < MAX_GUARDIANS, "Guardian: TOO_MANY_GUARDIANS");

        uint validSince = block.timestamp;
        if (numGuardians > MIN_GUARDIANS) {
            validSince = block.timestamp + GUARDIAN_PENDING_PERIODS;
        }
        
        bool returned = GuardianStorage.layout().storeGuardian(hashId,validSince);

        require(returned, "Guardian: FAILED_TO_ADD_GUARDIAN");

        emit GuardianAdded(hashId, validSince);

        return returned;
    }

     /**
     * @notice internal function remove guardian from the group.
     * @param hashId: the hashId of the guardian.
     * @return returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {GuardianRemoved} event.
     */
    function _removeGuardian(uint256 hashId) internal virtual returns(bool) {
        uint validUntil = block.timestamp + GUARDIAN_PENDING_PERIODS;
        uint index = _getGuardianIndex(hashId);
        uint arrayIndex = index - 1;

        GuardianStorage.Guardian memory g = GuardianStorage.layout().guardians[arrayIndex];

        validUntil = _deleteGuardian(g, validUntil);
    
        emit GuardianRemoved(hashId, validUntil);

        return true;
    }

    /**
     * @notice internal query the mapping index of guardian.
     * @param hashId: the hashId of the guardian.
     */
    function _getGuardianIndex(uint256 hashId) internal view virtual returns (uint) {
        return GuardianStorage.layout().guardianIndex[hashId];
    }

    /**
     * @notice internal query query a guardian.
     * @param arrayIndex: the index of Guardian array.
     */
    function _getGuardian(uint arrayIndex) internal view virtual returns (GuardianStorage.Guardian memory) {
        return GuardianStorage.layout().guardians[arrayIndex];
    }

    /**
     * @notice internal function query all guardians from the storage
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function _getGuardians(bool includePendingAddition) internal view virtual returns (GuardianStorage.Guardian[] memory) {
        GuardianStorage.Guardian[] memory guardians = new GuardianStorage.Guardian[](GuardianStorage.layout().guardians.length);
        uint index = 0;
        for(uint i = 0; i < GuardianStorage.layout().guardians.length; i++) {
            GuardianStorage.Guardian memory g = GuardianStorage.layout().guardians[i];           
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                guardians[index] = g;
                index++;
            }
        }
            
        return guardians;
    }

    /**
     * @notice internal function query the length of the active guardians
     * @param includePendingAddition: whether to include pending addition guardians.
     */
    function _numGuardians(bool includePendingAddition) internal view virtual returns (uint count) {
        GuardianStorage.Guardian[] memory guardians = _getGuardians(includePendingAddition);
        for(uint i = 0; i < guardians.length; i++) {
            GuardianStorage.Guardian memory g = guardians[i];
            if (_isActiveOrPendingAddition(g, includePendingAddition)) {
                count++;
            }
        }
    }

     function _requireMajority(GuardianDTO[] calldata signers) internal view virtual returns (bool) {
        // We always need at least one signer
        if (signers.length == 0) {
            return false;
        }
        
        uint256 lastSigner;
        // Calculate total group sizes
        GuardianStorage.Guardian[] memory allGuardians = _getGuardians(false);
        require(allGuardians.length > 0, "NO_GUARDIANS");
        for (uint i = 0; i < signers.length; i++) {
            // Check for duplicates
            require(signers[i].hashId > lastSigner, "INVALID_SIGNERS_ORDER");
            lastSigner = signers[i].hashId;

            bool _isGuardian = false;
            for (uint j = 0; j < allGuardians.length; j++) {
                if (allGuardians[j].hashId == signers[i].hashId) {
                    _isGuardian = true;
                    break;
                    
                }
            }
            require(_isGuardian, "SIGNER_NOT_GUARDIAN");
        }
        uint numExtendedSigners = allGuardians.length;
        return signers.length >= (numExtendedSigners >> 1) + 1;
    }

    /**
     * @notice hook that is called before setInitialGuardians
     */
    function _beforeSetInitialGuardians(uint256[] memory guardians) 
        internal 
        view
        virtual 
        isMinGuardian(guardians) 
        isMaxGuardian(guardians) 
    {
        for(uint i = 0; i < guardians.length; i++) {
            require(guardians[i] != 0, "Guardian: GUARDIAN_HASH_ID_IS_ZERO");
            require(_getGuardianIndex(guardians[i]) == 0, "Guardian: GUARDIAN_EXISTS");
        }
    }

    /**
     * @notice hook that is called after setInitialGuardians
     */
    function _afterSetInitialGuardians(uint256[] memory guardians) internal view virtual {}

    /**
     * @notice hook that is called before addGuardian
     */
    function _beforeAddGuardian(uint256 hashId) internal view virtual {
        uint numGuardians = _numGuardians(true);
        require(numGuardians <= MAX_GUARDIANS, "Guardian: TOO_MANY_GUARDIANS");
    }

    /**
     * @notice hook that is called before removeGuardian
     */
    function _beforeRemoveGuardian(uint256 hashId) 
        internal view virtual 
        isGuardian(hashId, true)
    {}

    /**
     * @notice hook that is called before removeGuardians
     */
    function _beforeRemoveGuardians(uint256[] memory guardians) internal view virtual {
        require(guardians.length > 0, "Guardian: NO_GUARDIANS_TO_REMOVE");
    }

    /**
     * @notice hook that is called after removeGuardians
     */
    function _afterRemoveGuardians(uint256[] memory guardians) internal view virtual  {}


    /**
     * @notice check if the guardian is active or pending for addition
     * @param guardian: the guardian to be check.
     */
    function _isActiveOrPendingAddition(
        GuardianStorage.Guardian memory guardian,
        bool includePendingAddition
        )
        private
        view
        returns (bool)
    {
        return _isAdded(guardian) || includePendingAddition && _isPendingAddition(guardian);
    }

    /**
     * @notice check if the guardian is added
     * @param guardian: the guardian to be check.
     */
    function _isAdded(GuardianStorage.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(IGuardianInternal.GuardianStatus.ADD) &&
            guardian.timestamp <= block.timestamp;
    }

    /**
     * @notice check if the guardian is pending for addition
     * @param guardian: the guardian to be check.
     */
    function _isPendingAddition(GuardianStorage.Guardian memory guardian)
        private
        view
        returns (bool)
    {
        return guardian.status == uint8(IGuardianInternal.GuardianStatus.ADD) &&
            guardian.timestamp > block.timestamp;
    }

     /**
     * @notice private function delete a guardian from the storage.
     * @param g: the guardian to be deleted. 
     * @param validUntil: the timestamp when the guardian is removed.
     * @return returns validUntil. 
     */
    function _deleteGuardian(GuardianStorage.Guardian memory g, uint validUntil) private returns(uint) {
        if (_isAdded(g)) {
            g.status = uint8(IGuardianInternal.GuardianStatus.REMOVE);
            g.timestamp = validUntil.toUint64();
            require(GuardianStorage.layout().deleteGuardian(g.hashId), "Guardian: UNEXPECTED_RESULT");
            return validUntil;
        }
        if (_isPendingAddition(g)) {
            g.status = uint8(IGuardianInternal.GuardianStatus.REMOVE);
            g.timestamp = 0;
            require(GuardianStorage.layout().deleteGuardian(g.hashId), "Guardian: UNEXPECTED_RESULT");
            return 0;
        }
        return 0;
    }
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