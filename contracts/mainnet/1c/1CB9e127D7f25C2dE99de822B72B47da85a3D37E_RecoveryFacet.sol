// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { SafeOwnableInternal } from "@solidstate/contracts/access/ownable/SafeOwnableInternal.sol";
import { IRecoveryFacet } from "../interfaces/IRecoveryFacet.sol";
import { Recovery } from "./Recovery.sol";
import { RecoveryStorage } from "./RecoveryStorage.sol";


/**
 * @title RecoveryFacet 
 */
contract RecoveryFacet is IRecoveryFacet, Recovery, SafeOwnableInternal {
    using RecoveryStorage for RecoveryStorage.Layout;

    /**
     * @inheritdoc IRecoveryFacet
     */
    function recoveryFacetVersion() external pure override returns (string memory) {
        return "0.1.0.alpha";
    }

    function _beforeResetRecovery() internal view virtual override onlyOwner {}

    function _duringRecovery(uint256 majority, address newOwner) internal virtual override {
        _transferOwnership(newOwner);
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IRecovery } from "../recovery/IRecovery.sol";


/**
 * @title RecoveryFacet interface
 */
interface IRecoveryFacet is IRecovery {
    /**
     * @notice return the current version of RecoveryFacet
     */
    function recoveryFacetVersion() external pure returns (string memory);

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IRecovery} from "./IRecovery.sol";
import {RecoveryInternal} from "./RecoveryInternal.sol";
import {RecoveryStorage} from "./RecoveryStorage.sol";

import {GuardianInternal} from "../guardian/GuardianInternal.sol";
import {GuardianStorage} from "../guardian/GuardianStorage.sol";

import {ISemaphoreInternal} from "../semaphore/ISemaphoreInternal.sol";
import {SemaphoreInternal} from "../semaphore/SemaphoreInternal.sol";

/** 
 * @title Recovery
 */
abstract contract Recovery is IRecovery, ISemaphoreInternal, RecoveryInternal, GuardianInternal, SemaphoreInternal {
    /**
     * @inheritdoc IRecovery
     */
    function recover(//
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        address newOwner
    ) external override {
        GuardianStorage.Guardian[] memory allGuardians = _getGuardians(false);
        uint numExtendedSigners = allGuardians.length;
        require(numExtendedSigners > 0, "Recovery: NO_GUARDIANS");
        uint256 majority = (numExtendedSigners >> 1) + 1;
        
        _beforeRecover(majority, newOwner);

        _verifyProof(groupId, signal, nullifierHash, externalNullifier, proof);
        emit ProofVerified(groupId, signal);

        _recover(majority, newOwner);

        if (RecoveryStorage.layout().counter == (numExtendedSigners >> 1) + 1) {
            _duringRecovery(majority, newOwner);

            emit Recovered(newOwner);
            _resetRecovery();
        }
        _afterRecover(majority, newOwner);
    }

    /**
     * @inheritdoc IRecovery
     */
    function resetRecovery() public virtual override {
        _beforeResetRecovery();

        _resetRecovery();

        _afterResetRecovery();
    }

    /**
     * @inheritdoc IRecovery
     */
    function getRecoveryStatus() public view virtual override returns (IRecovery.RecoveryStatus) {
        return _getStatus();
    }

    /**
     * @inheritdoc IRecovery
     */
    function getMajority() public view virtual override returns (uint256) {
        return _getMajority();
    }

    function getRecoveryNominee() public view virtual override returns (address) {
        return _getNominee();
    }

    /**
     * @inheritdoc IRecovery
     */
    function getRecoveryCounter() public view virtual override returns (uint8) {
        return _getCounter();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";
/**
 * @title Recovery Storage base on Diamond Standard Layout storage pattern
 */
library RecoveryStorage {
    struct Layout {
        uint8 status;
        uint256 majority;
        address nominee;
        uint8 counter;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Recovery");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice set the status of the recovery process
     * @param status: the status of the recovery process
     */
    function setStatus(Layout storage s, uint8 status) internal {
        s.status = status;
    }

    /**
     * @notice set the majority of the recovery process
     * @param majority: the majority of the recovery process
     */
    function setMajority(Layout storage s, uint256 majority) internal {
        s.majority = majority;
    }

    /**
     * @notice set the nominee of the recovery process
     * @param nominee: the nominee of the recovery process
     */
    function setNominee(Layout storage s, address nominee) internal {
        s.nominee = nominee;
    }

    /**
     * @notice set the counter of the recovery process
     * @param counter: the counter of the recovery process
     */
    function setCounter(Layout storage s, uint8 counter) internal {
        s.counter = counter;
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

import {IRecoveryInternal} from "./IRecoveryInternal.sol";

/**
 * @title Recovery interface 
 */
interface IRecovery is IRecoveryInternal {
    /**
     * @notice recover the wallet by setting a new owner.
     * @param groupId the group id of the semaphore groups
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */
    function recover(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        address newOwner
    ) external;

    /**
     * @notice reset the recovery
     */
    function resetRecovery() external;

    /**
     * @notice query the status of the recovery
     */
    function getRecoveryStatus() external view returns (RecoveryStatus);

    /**
     * @notice query the majority of the recovery
     */
    function getMajority() external view returns (uint256);

    /**
     * @notice query the nominee of the recovery
     */
    function getRecoveryNominee() external view returns (address);

    /**
     * @notice query the counter of the recovery
     */
    function getRecoveryCounter() external view returns (uint8);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial Recovery interface needed by internal functions
 */
interface IRecoveryInternal {
    enum RecoveryStatus {
        NONE,
        PENDING,
        ACCEPTED,
        REJECTED
    }

    /**
     * @notice emitted when a wallet is recoverd
     * @param newOwner: the address of the new owner
     */
    event Recovered(address newOwner);

    /**
     * @notice emitted when _recovery is called.
     * @param status: the new status of the recovery.
     * @param majority: the majority amount of the recovery.
     * @param nominee: the nominee address of the recovery.
     */
    event RecoveryUpdated(RecoveryStatus status, uint256 majority, address nominee, uint8 counter);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IRecoveryInternal} from "./IRecoveryInternal.sol";
import {RecoveryStorage} from "./RecoveryStorage.sol";

/** 
 * @title Recovery internal functions, excluding optional extensions
 */
abstract contract RecoveryInternal is IRecoveryInternal {
    using RecoveryStorage for RecoveryStorage.Layout;

    /**
     * @notice internal functio recover a wallet by setting a new owner,
     */
    function _recover(uint256 majority, address nominee)  internal virtual {
        RecoveryStorage.layout().counter += 1;
        
        IRecoveryInternal.RecoveryStatus status = _getStatus();
        if (status == IRecoveryInternal.RecoveryStatus.NONE) {
            RecoveryStorage.layout().setStatus(uint8(IRecoveryInternal.RecoveryStatus.PENDING));
            RecoveryStorage.layout().setMajority(majority);
            RecoveryStorage.layout().setNominee(nominee);
            emit RecoveryUpdated(IRecoveryInternal.RecoveryStatus.PENDING, majority, nominee, RecoveryStorage.layout().counter);
        }
    }

    function _resetRecovery() internal virtual {
        RecoveryStorage.layout().setStatus(uint8(IRecoveryInternal.RecoveryStatus.NONE));
        RecoveryStorage.layout().setMajority(0);
        RecoveryStorage.layout().setNominee(0x0000000000000000000000000000000000000000);
        RecoveryStorage.layout().setCounter(0);
    }

    function _getStatus() internal view virtual returns (IRecoveryInternal.RecoveryStatus) {
        return IRecoveryInternal.RecoveryStatus(RecoveryStorage.layout().status);
    }

    function _getMajority() internal view virtual returns (uint256) {
        return RecoveryStorage.layout().majority;
    }

    function _getNominee() internal view virtual returns (address) {
        return RecoveryStorage.layout().nominee;
    }

    function _getCounter() internal view virtual returns (uint8) {
        return RecoveryStorage.layout().counter;
    }

    /**
     * @notice hook that is called before recover is called
     */
    function _beforeRecover(uint256 majority, address nominee) internal view virtual {
        require(majority > 0, "Recovery: ZERO_MAJORITY");
        require(nominee != address(0), "Recovery: ZERO_NOMINEE");
        require(nominee != msg.sender, "Recovery: NOT_ALLOWED_TO_RECOVER_OWN_WALLET");
        require(_getStatus() != IRecoveryInternal.RecoveryStatus.ACCEPTED, "Recovery: REOVERY_ALREADY_ACCEPTED");
    }

    /**
     * @notice hook that is called during recovery.
     * should override this function to transfer the ownership
     */
    function _duringRecovery(uint256 majority, address nominee) internal virtual {}

    /**
     * @notice hook that is called before recover is called
     */
    function _afterRecover(uint256 majority, address nominee) internal view virtual {}

    /**
     * @notice hook that is called before resetRecovery is called
     */
    function _beforeResetRecovery() internal view virtual {}

    /**
     * @notice hook that is called after resetRecovery is called
     */
    function _afterResetRecovery() internal view virtual {}
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title Partial Semaphore interface needed by internal functions
 */
interface ISemaphoreInternal {
    struct Verifier {
        address contractAddress;
        uint8 merkleTreeDepth;
    }
    
    /**
     * @notice emitted when a Semaphore proof is verified
     * @param signal: semaphore signal
     */
    event ProofVerified(uint256 indexed groupId, bytes32 signal);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IVerifier} from "../interfaces/IVerifier.sol";
import {ISemaphoreInternal} from "./ISemaphoreInternal.sol";
import {SemaphoreStorage} from "./SemaphoreStorage.sol";
import {SemaphoreCoreBaseStorage} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseStorage.sol";
import {SemaphoreCoreBaseInternal} from "./base/SemaphoreCoreBase/SemaphoreCoreBaseInternal.sol";
import {IncrementalBinaryTreeStorage} from "../utils/cryptography/IncrementalBinaryTree/IncrementalBinaryTreeStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreInternal is ISemaphoreInternal, SemaphoreCoreBaseInternal {
    using SemaphoreStorage for SemaphoreStorage.Layout;
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;
    using IncrementalBinaryTreeStorage for IncrementalBinaryTreeStorage.Layout;
    
    /**
     * @notice internal function: saves the nullifier hash to avoid double signaling and emits an event
     * if the zero-knowledge proof is valid
     * @param groupId: group id of the group
     * @param signal: semaphore signal
     * @param nullifierHash: nullifier hash
     * @param externalNullifier: external nullifier
     * @param proof: Zero-knowledge proof
     */

    function _verifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        
        uint256 root = IncrementalBinaryTreeStorage.layout().trees[groupId].root;
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;

        IVerifier verifier = SemaphoreStorage.layout().verifiers[depth];

        _verifyProof(signal, root, nullifierHash, externalNullifier, proof, verifier);

        // Prevent double-voting
        SemaphoreCoreBaseStorage.layout().saveNullifierHash(nullifierHash);
    }

    /**
     * @notice query the verifier address by merkle tree depth
     */
    function _getVerifier(uint8 merkleTreeDepth) internal returns (IVerifier) {
        return SemaphoreStorage.layout().verifiers[merkleTreeDepth];
    }

    /**
     * @notice hook that is called before verifyProof
     */
    function _beforeVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {
        uint8 depth = IncrementalBinaryTreeStorage.layout().trees[groupId].depth;
        require(depth != 0, "Semaphore: group does not exist");
    }

    /**
     * @notice hook that is called after verifyProof
     */
    function _afterVerifyProof(
        uint256 groupId,
        bytes32 signal,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof
    ) internal virtual {}
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @title verifier interface.
 */
interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import { IVerifier } from "../interfaces/IVerifier.sol";

library SemaphoreStorage {
    struct Layout {
        mapping(uint256 => IVerifier) verifiers;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.Semaphore");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

library SemaphoreCoreBaseStorage {
    struct Layout {
        /**
         * @notice gets a nullifier hash and returns true or false.
         * It is used to prevent double-signaling.
         */
        mapping(uint256 => bool) nullifierHashes;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("simplicy.contracts.storage.SemaphoreCoreBase");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice stores the nullifier hash to prevent double-signaling
     * @param nullifierHash: Semaphore nullifier has.
     */
    function saveNullifierHash(Layout storage s, uint256 nullifierHash)
        internal
    {
        s.nullifierHashes[nullifierHash] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

import {IVerifier} from "../../../interfaces/IVerifier.sol";
import {ISemaphoreCoreBaseInternal} from "./ISemaphoreCoreBaseInternal.sol";
import {SemaphoreCoreBaseStorage} from "./SemaphoreCoreBaseStorage.sol";

/**
 * @title Base SemaphoreGroups internal functions, excluding optional extensions
 */
abstract contract SemaphoreCoreBaseInternal is ISemaphoreCoreBaseInternal {
    using SemaphoreCoreBaseStorage for SemaphoreCoreBaseStorage.Layout;    

     /**
     * @notice asserts that no nullifier already exists and if the zero-knowledge proof is valid
     * @param signal: Semaphore signal.
     * @param root: Root of the Merkle tree.
     * @param nullifierHash: Nullifier hash.
     * @param externalNullifier: External nullifier.
     * @param proof: Zero-knowledge proof.
     * @param verifier: Verifier address.
     */
    function _verifyProof(
        bytes32 signal,
        uint256 root,
        uint256 nullifierHash,
        uint256 externalNullifier,
        uint256[8] calldata proof,
        IVerifier verifier
    ) internal view {
        require(!SemaphoreCoreBaseStorage.layout().nullifierHashes[nullifierHash], "SemaphoreCore: you cannot use the same nullifier twice");

        uint256 signalHash = _hashSignal(signal);

        verifier.verifyProof(
            [proof[0], proof[1]],
            [[proof[2], proof[3]], [proof[4], proof[5]]],
            [proof[6], proof[7]],
            [root, nullifierHash, signalHash, externalNullifier]
        );
    }

    /**
     * @notice creates a keccak256 hash of the signal
     * @param signal: Semaphore signal
     * @return Hash of the signal
     */
    function _hashSignal(bytes32 signal) private pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(signal))) >> 8;
    }
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.4;

/**
 * @title Partial SemaphoreCore interface needed by internal functions
 */
interface ISemaphoreCoreBaseInternal {
    /**
     * @notice emitted when a proof is verified correctly and a new nullifier hash is added.
     * @param nullifierHash: hash of external and identity nullifiers.
     */
     event NullifierHashAdded(uint256 nullifierHash);
}