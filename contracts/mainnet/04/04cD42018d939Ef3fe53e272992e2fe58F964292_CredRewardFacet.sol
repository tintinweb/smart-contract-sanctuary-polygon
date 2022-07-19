// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import {OwnableInternal} from "@solidstate/contracts/access/ownable/OwnableInternal.sol";
import {PausableInternal} from "@solidstate/contracts/security/PausableInternal.sol";

import {CredRegistryTypes} from "../registry/CredRegistryTypes.sol";
import {ICredRewardCalculator} from "../registry/ICredRewardCalculator.sol";

import {CredRewardStorage} from "./CredRewardStorage.sol";

// import "hardhat/console.sol";

contract CredRewardFacet is ICredRewardCalculator, OwnableInternal, PausableInternal {

    event RewardPerTonneOffsetChanged(uint256 indexed projectID, uint256 amount);

    /**
     * @dev Sets the amount of CRED rewarded per tonne offset for each of the specified projects.
     */
    function batchSetRewardPerTonneOffset(uint256[] calldata projectIDs, uint256[] calldata amounts)
        external
        onlyOwner
        whenNotPaused
    {
        require(projectIDs.length == amounts.length, "!SAME_LENGTH");

        CredRewardStorage.Layout storage l = CredRewardStorage.layout();
        for (uint256 i; i < projectIDs.length; ++i) {
            uint256 id = projectIDs[i];
            require(CredRegistryTypes.isValidTokenID(id, CredRegistryTypes.PROJECT), "!VALID_ID");

            uint256 amount = amounts[i];
            l.rewardPerTonneOffsetByProject[id] = amount;

            emit RewardPerTonneOffsetChanged(id, amount);
        }
    }

    function getRewardPerTonneOffset(uint256 projectID) public view returns (uint256) {
        require(CredRegistryTypes.isValidTokenID(projectID, CredRegistryTypes.PROJECT), "!VALID_ID");

        return CredRewardStorage.layout().rewardPerTonneOffsetByProject[projectID];
    }

    function calculateReward(uint256 projectID, uint256 vintageID, uint256 kilos) public view returns (uint256) {
        uint256 credPerTonne = CredRewardStorage.layout().rewardPerTonneOffsetByProject[projectID];
        return (credPerTonne * kilos) / 1000;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { PausableStorage } from './PausableStorage.sol';

/**
 * @title Internal functions for Pausable security control module.
 */
abstract contract PausableInternal {
    using PausableStorage for PausableStorage.Layout;

    event Paused(address account);

    event Unpaused(address account);

    modifier whenNotPaused() {
        require(!_paused(), 'Pausable: paused');
        _;
    }

    modifier whenPaused() {
        require(_paused(), 'Pausable: not paused');
        _;
    }

    /**
     * @notice query the contracts paused state.
     * @return true if paused, false if unpaused.
     */
    function _paused() internal view virtual returns (bool) {
        return PausableStorage.layout().paused;
    }

    /**
     * @notice Triggers paused state, when contract is unpaused.
     */
    function _pause() internal virtual whenNotPaused {
        PausableStorage.layout().paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @notice Triggers unpaused state, when contract is paused.
     */
    function _unpause() internal virtual whenPaused {
        PausableStorage.layout().paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library CredRegistryTypes {
    uint256 constant TYPE_BITS = 64;
    uint256 constant TYPE_SHIFT = 192;
    uint256 constant TYPE_MASK = ((1 << TYPE_BITS) - 1) << TYPE_SHIFT;

    uint256 constant ID_BITS = 64;
    uint256 constant ID_MASK = (1 << ID_BITS) - 1;
    uint256 constant MAX_ID = (1 << ID_BITS) - 1;

    /**
     * @dev token type for a project (NFT)
     */
    uint256 constant PROJECT = uint256(uint64(bytes8("PROJECT"))) << TYPE_SHIFT;

    /**
     * @dev token type for a project vintage (NFT)
     */
    uint256 constant VINTAGE = uint256(uint64(bytes8("VINTAGE"))) << TYPE_SHIFT;

    /**
     * @dev token type for a batch of N kilos from a specific vintage (NFT)
     */
    uint256 constant BATCH = uint256(uint64(bytes8("BATCH"))) << TYPE_SHIFT;

    /**
     * @dev token type for fractionalized carbon from a specific vintage (partially fungible, at kilo granularity)
     */
    uint256 constant CARB = uint256(uint64(bytes8("CARB"))) << TYPE_SHIFT;

    /**
     * @dev token type for an offset of N kilos (NFT)
     */
    uint256 constant OFFSET = uint256(uint64(bytes8("OFFSET"))) << TYPE_SHIFT;

    /**
     * @dev Checks whether `id` is a valid token ID of the specified token type.
     */
    function isValidTokenID(uint256 id, uint256 typ) internal pure returns (bool) {
        return ((id & TYPE_MASK) == typ) && (id != typ);
    }

    function simpleID(uint256 id) internal pure returns (uint256) {
        return id & ID_MASK;
    }

    enum BatchStatus {
        PENDING,
        REJECTED,
        CONFIRMED
    }

    struct Project {
        string registryID;
    }

    struct Vintage {
        uint256 projectID;
        string name;
    }

    struct Batch {
        uint256 vintageID;
        uint256 kilos;
        string serialNumber;
        BatchStatus status;
    }

    struct Offset {
        uint256 vintageID;
        uint256 kilos;
        uint256 timestamp;
        uint256 credReward;
        string reason;
    }

    struct OffsetInfo {
        uint256 projectID;
        uint256 vintageID;
        uint256 kilos;
        uint256 timestamp;
        uint256 credReward;
        string reason;
        string uri;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface ICredRewardCalculator {
    /**
     * Calculates and returns the amount of CRED to reward when creating an OFFSET of `kilos` kilos
     * from the specified PROJECT and VINTAGE.
     */
    function calculateReward(uint256 projectID, uint256 vintageID, uint256 kilos) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library CredRewardStorage {
    struct Layout {
        mapping(uint256 => uint256) rewardPerTonneOffsetByProject;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("@credprotocol.storage.CredReward");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library PausableStorage {
    struct Layout {
        bool paused;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Pausable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}