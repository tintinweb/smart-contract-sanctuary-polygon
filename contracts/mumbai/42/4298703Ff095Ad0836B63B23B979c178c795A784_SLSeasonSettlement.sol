// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLCollectable {
    function getCollectingScoreAtBlock(
        address _hunter,
        uint256 _blockNumber
    ) external view returns (uint256);

    function getLatestCollectingScore(
        address _hunter
    ) external view returns (uint256);

    function getCollectingScoreAtBlockBatch(
        address[] calldata _hunters,
        uint256[] calldata _blockNumbers
    ) external view returns (uint256[] memory);

    function getLatestCollectingScoreBatch(
        address[] calldata _hunters
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLMT {
    /*
     *  Mint
     */
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;

    function mintBatch(
        address _to,
        uint256[] calldata _tokenIds,
        uint256[] calldata _amounts
    ) external;

    /*
     *  ERC1155
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /*
     *  Burn
     */
    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    /*
     *  Exists
     */
    function exists(uint256 id) external view returns (bool);

    function existsBatch(uint256[] calldata ids) external view returns (bool);

    /*
     *  Base
     */
    function getMintedSupply(uint256 _tokenId) external view returns (uint256);

    function getBurnedSupply(uint256 _tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract BaseStorage {
    /*
     *  Enum
     */
    enum TokenType {
        ERC721,
        ERC1155
    }

    enum RankType {
        E,
        D,
        C,
        B,
        A,
        S
    }

    enum StoneType {
        E,
        D,
        C,
        B,
        A,
        S,
        Broken
    }

    /*
     *  Event
     */
    event Create(string target, uint64 targetId, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";

import {BaseStorage} from "./BaseStorage.sol";

abstract contract SLBaseUpgradeable is ContextUpgradeable, BaseStorage {
    function emitCreate(string memory _target, uint64 _targetId) internal {
        emit Create(_target, _targetId, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../utils/Initializable.sol";

import {BaseStorage} from "./BaseStorage.sol";
import {RoleAccessError} from "../errors/RoleAccessError.sol";
import {ISLProject} from "../project/ISLProject.sol";

abstract contract SLControllerUpgradeable is
    Initializable,
    ContextUpgradeable,
    RoleAccessError
{
    ISLProject internal projectContract;

    function __SLCotroller_init(
        ISLProject _projectContract
    ) internal onlyInitializing {
        projectContract = _projectContract;
    }

    modifier onlyOperatorMaster() {
        _onlyOperatorMaster(_msgSender());
        _;
    }

    modifier onlyOperator() {
        _onlyOperator(_msgSender());
        _;
    }

    function _onlyOperatorMaster(address _account) private view {
        if (!projectContract.isOperatorMaster(_account))
            revert OnlyOperatorMaster();
    }

    function _onlyOperator(address _account) private view {
        if (!projectContract.isOperator(_account)) revert OnlyOperator();
    }

    function setProjectContract(
        ISLProject _projectContract
    ) external onlyOperatorMaster {
        projectContract = _projectContract;
    }

    function getProjectContract() external view returns (address) {
        return address(projectContract);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {DungeonGateError} from "../errors/DungeonGateError.sol";
import {ISLRandom} from "../random/ISLRandom.sol";
import {ISLSeason} from "../season/ISLSeason.sol";

/// @notice Core storage and event for dungeon gate contract
abstract contract DungeonGateBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    DungeonGateError
{
    CountersUpgradeable.Counter internal gateIds;

    /// @notice precision 100.00000%
    uint256 internal constant DENOMINATOR = 100_00000;

    // season contract
    ISLSeason seasonContract;

    // random contract
    ISLRandom randomContract;

    // collectionId
    uint256 internal essenceStoneCollectionId;

    // boost block count per 1 broken stone
    uint256 internal boostBlockCount;

    // essence stone amount per gate
    uint256 internal stonePerGate;

    // gate offerting distributions
    address[] internal distributedAccounts;
    uint256[] internal distributedRates;

    /*
     *  Struct
     */
    struct GateInfo {
        uint256 price;
        uint32 blockCount;
    }

    struct Gate {
        uint64 id;
        uint64 seasonId;
        uint32 startBlock;
        uint32 endBlock;
        uint32 usedBrokenStone;
        bool cleared;
        RankType gateRank;
        address hunter;
    }

    struct PercentageForGate {
        uint256[7] percentages; // E - S + Broken
    }

    /*
     *  Mapping
     */
    /// @notice RankType to GateInfo
    mapping(RankType => GateInfo) internal gateInfoPerRank; // E - S

    /// @notice RankType to Slot
    mapping(RankType => uint256) internal slotPerHunterRank; // E - S

    /// @notice RankType to gate percentages
    mapping(RankType => uint256[7]) internal percentageForGate; // E - S

    /// @notice gateId to Gate
    mapping(uint256 => Gate) internal gates;

    /// @notice hunter to gateIds
    mapping(address => EnumerableSetUpgradeable.UintSet)
        internal gateOfHunterSlot;

    /// @notice seasonId to hunter to gate count
    mapping(uint256 => mapping(address => CountersUpgradeable.Counter))
        internal gateCountOfSeason;

    /*
     *  Event
     */
    event SetDistributedAccounts(
        address[] distributedAccounts,
        uint256[] distributedRates,
        uint256 timestamp
    );

    event GateCreated(
        uint256 indexed seasonId,
        RankType indexed gateRank,
        address indexed hunter,
        uint256 gateId,
        uint256 startBlock,
        uint256 endBlock
    );

    event GateFeeDistributed(
        uint256 indexed seasonId,
        RankType indexed gateRank,
        uint256 indexed gateId,
        uint256 price,
        address[] distributedAccounts,
        uint256[] distributedAmounts,
        uint256 timestamp
    );

    event GateCleared(
        RankType indexed gateRank,
        address indexed hunter,
        uint256 indexed gateId,
        uint256 usedBrokenStone,
        bytes[] gateSignatures,
        uint256[] stoneIds,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {DungeonGateBase} from "./DungeonGateBase.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLRandom} from "../random/ISLRandom.sol";

interface ISLDungeonGate {
    /*
     *  Distribution
     */
    function setGateDistributedAccounts(
        address[] calldata _distributedAccounts,
        uint256[] calldata _distributedRates
    ) external;

    function getGateDistributedAccounts()
        external
        view
        returns (
            address[] memory distributedAccounts,
            uint256[] memory distributedRates
        );

    /*
     *  Slot
     */
    // E - S
    function setSlotPerHunterRank(uint256[6] calldata _slots) external;

    function getHunterUsingSlot(
        address _hunter
    ) external view returns (uint256);

    function getHunterSlot(
        uint256 _seasonId,
        address _hunter
    ) external view returns (uint256 availableSlot, uint256 usingSlot);

    function getSlotPerHunterRank() external view returns (uint256[6] memory);

    /*
     *  Gate
     */
    function enterToGate(
        uint256 _seasonId,
        BaseStorage.RankType _gateRank
    ) external payable;

    function clearGate(
        uint256 _gateId,
        bytes[] calldata _gateSignatures
    ) external;

    function isExistGateById(uint256 _gateId) external view returns (bool);

    function getGateHunter(uint256 _gateId) external view returns (address);

    function getGateRemainingBlock(
        uint256 _gateId
    ) external view returns (uint256);

    function getRequiredBrokenStoneForClear(
        uint256 _gateId
    ) external view returns (uint256);

    function getGateIdOfHunterSlot(
        address _hunter
    ) external view returns (uint256[] memory);

    function getGateOfHunterSlot(
        address _hunter
    )
        external
        view
        returns (
            DungeonGateBase.Gate[] memory gateOfHunterSlot,
            uint256[] memory requiredBrokenStones
        );

    function isClearGate(uint256 _gateId) external view returns (bool);

    function getGateById(
        uint256 _gateId
    ) external view returns (DungeonGateBase.Gate memory);

    function getGateCountOfSeason(
        uint256 _seasonId,
        address _hunter
    ) external view returns (uint256);

    function getGateCountOfSeasonBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) external view returns (uint256[] memory);

    /*
     *  Gate Base
     */
    // E - S
    function setGateInfoPerRank(
        DungeonGateBase.GateInfo[6] calldata _gateInfo
    ) external;

    // E - S
    function setPercentageForGate(
        DungeonGateBase.PercentageForGate[6] calldata _percentages
    ) external;

    function setBoostBlockCount(uint256 _boostBlockCount) external;

    function setStonePerGate(uint256 _stonePerGate) external;

    function getGateInfoPerRank()
        external
        view
        returns (DungeonGateBase.GateInfo[6] memory _gateInfo);

    function getPercentageForGate()
        external
        view
        returns (DungeonGateBase.PercentageForGate[6] memory);

    function getBoostBlockCount() external view returns (uint256);

    function getStonePerGate() external view returns (uint256);

    /*
     *  Collection
     */
    function setEssenceStoneCollectionId(
        uint256 _essenceStoneCollectionId
    ) external;

    function getEssenceStoneCollectionId() external view returns (uint256);

    /*
     *  Base
     */
    function setSeasonContract(ISLSeason _seasonContract) external;

    function setRandomContract(ISLRandom _randomContract) external;

    function getSeasonContract() external view returns (address);

    function getRandomContract() external view returns (address);

    function getDenominator() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface DungeonGateError {
    //////////////////
    // Distribution //
    //////////////////

    error InvalidAddress();
    error TransferFailed();
    error InvalidAccount();
    error InvalidRate();

    //////////
    // Slot //
    //////////

    error InvalidSlot();

    //////////
    // Gate //
    //////////

    error InvalidSeasonId();
    error InvalidRankType();
    error InvalidPrice();
    error ExceedGateSlot();
    error InvalidGateId();
    error InvalidGateSignature();
    error AlreadyClearGate();
    error InvalidPercentage();
    error InvalidArgument();

    //////////
    // Base //
    //////////

    error InvalidCollectionId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface MonsterFactoryError {
    /////////////
    // Monster //
    /////////////

    error InvalidRankType();
    error InvalidMonsterId();
    error AlreadyMinted();
    error InvalidArgument();

    ///////////
    // Trait //
    ///////////

    error AlreadyExistTypeName();
    error AlreadyExistValueName();
    error InvalidTraitTypeId();
    error InvalidTraitValueId();
    error AlreadyExistMonster();
    error InvalidTraitMonsterSet();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {RoleAccessError} from "./RoleAccessError.sol";

interface ProjectError is RoleAccessError {
    //////////
    // Role //
    //////////

    error InvalidOperator();

    //////////////
    // Universe //
    //////////////

    error InvalidUniverseId();

    ////////////////
    // Collection //
    ////////////////

    error InvalidCollectionId();
    error AlreadyExistTokenContract();
    error InvalidTokenContract();
    error InvalidArgument();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface RoleAccessError {
    error OnlyOperatorMaster();
    error OnlyOperator();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface SeasonError {
    ////////////
    // Season //
    ////////////

    error InvalidBlockNumber();
    error InvalidSeasonId();
    error InvalidCollectionId();
    error EndedSeason();
    error AlreadyStartSeason();

    ////////////
    // RankUp //
    ////////////

    error AlreadyClaimed();
    error InvalidRankType();
    error InvalidMonster();
    error InvalidArgument();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface SeasonQuestError {
    ////////////
    // Season //
    ////////////

    error InvalidSeasonId();
    error EndedSeason();

    ///////////
    // Quest //
    ///////////

    error InvalidArgument();
    error InvalidQuestId();
    error UnActiveQuest();
    error InvalidMonster();
    error InvalidTrait();
    error InvalidHunterItemId();

    /////////////
    // Comfirm //
    /////////////

    error InvalidHunterRank();
    error ExceedCompletableCount();
    error NotCompleteRequiredQuest();
    error NotEnoughMonster();
    error GeneralQuestVerifyFailed();
    error InvalidQuestType();

    /////////
    // Base//
    /////////

    error InvalidCollectionId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface SeasonSettlementError {
    ///////////
    // Score //
    ///////////

    error InvalidRate();
    error InvalidSeasonId();

    ////////////
    // Reward //
    ////////////

    error AlreadyClaimed();

    ////////////////
    // Collection //
    ////////////////

    error InvalidCollectionId();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {MonsterFactoryBase} from "./MonsterFactoryBase.sol";

interface ISLMonsterFactory {
    /*
     *  Monster
     */
    function addMonster(
        BaseStorage.RankType _monsterRank,
        bool _isShadow
    ) external;

    function setMonsterRankType(
        bool _isShadow,
        uint256 _monsterId,
        BaseStorage.RankType _monsterRank
    ) external;

    function setMonsterScore(
        bool _isShadow,
        uint256[] calldata _scores
    ) external;

    /*
     *  Monster View
     */
    function isExistMonsterById(
        bool _isShadow,
        uint256 _monsterId
    ) external view returns (bool);

    function isExistMonsterBatch(
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external view returns (bool);

    function getMonsterLength(bool _isShadow) external view returns (uint256);

    function getMonsterRankType(
        bool _isShadow,
        uint256 _monsterId
    ) external view returns (BaseStorage.RankType);

    function getMonsterRankTypeBatch(
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external view returns (BaseStorage.RankType[] memory);

    function getMonsterIdOfRankType(
        BaseStorage.RankType _rankType,
        bool _isShadow
    ) external view returns (uint256[] memory);

    function isValidMonster(
        BaseStorage.RankType _rankType,
        bool _isShadow,
        uint256 _monsterId
    ) external view returns (bool);

    function isValidMonsterBatch(
        BaseStorage.RankType _rankType,
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external view returns (bool);

    function getMonsterScore(
        BaseStorage.RankType _rankType,
        bool _isShadow
    ) external view returns (uint256);

    function getMonsterScores(
        bool _isShadow
    ) external view returns (uint256[] memory);

    /*
     *  TraitType
     */
    function addMonsterTraitType(string calldata _name) external;

    function setMonsterTraitTypeName(
        uint256 _typeId,
        string calldata _name
    ) external;

    function setMonsterTraitTypeActive(
        uint256 _typeId,
        bool _isActive
    ) external;

    /*
     *  TraitType View
     */
    function isExistTraitTypeById(uint256 _typeId) external view returns (bool);

    function isActiveTraitType(uint256 _typeId) external view returns (bool);

    function isExistTraitTypeByName(
        string calldata _name
    ) external view returns (bool);

    function getTraitTypeIdByName(
        string calldata _name
    ) external view returns (uint256);

    function getTraitTypeById(
        uint256 _typeId
    ) external view returns (MonsterFactoryBase.TraitType memory);

    function getTraitTypeLength() external view returns (uint256);

    /*
     *  TraitValue
     */
    function addMonsterTraitValue(
        uint256 _typeId,
        string calldata _name
    ) external;

    function removeMonsterTraitValue(uint256 _valueId) external;

    /*
     *  TraitValue View
     */
    function isExistTraitValueById(
        uint256 _valueId
    ) external view returns (bool);

    function isExistTraitValueByName(
        uint256 _typeId,
        string calldata _name
    ) external view returns (bool);

    function isContainTraitValueOfType(
        uint256 _typeId,
        uint256 _valueId
    ) external view returns (bool);

    function isContainTraitValueOfTypeBatch(
        uint256 _typeId,
        uint256[] calldata _valueIds
    ) external view returns (bool);

    function getTraitValueIdByName(
        uint256 _typeId,
        string calldata _name
    ) external view returns (uint256);

    function getTraitValueById(
        uint256 _valueId
    ) external view returns (MonsterFactoryBase.TraitValue memory);

    function getTraitValueIdOfType(
        uint256 _typeId
    ) external view returns (uint256[] memory);

    function getTraitValueOfType(
        uint256 _typeId
    ) external view returns (MonsterFactoryBase.TraitValue[] memory);

    /*
     *  Trait Monster
     */
    function addMonsterOfTrait(
        uint256 _typeId,
        MonsterFactoryBase.TraitMonsterSet[] calldata _traitMonsterSets
    ) external;

    function removeMonsterOfTrait(
        uint256 _valueId,
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external;

    /*
     *  Trait Monster View
     */
    function isContainMonsterOfTraitType(
        uint256 _typeId,
        bool _isShadow,
        uint256 _monsterId
    ) external view returns (bool);

    function isContainMonsterOfTraitTypeBatch(
        uint256 _typeId,
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external view returns (bool);

    function isContainMonsterOfTraitValue(
        uint256 _valueId,
        bool _isShadow,
        uint256 _monsterId
    ) external view returns (bool);

    function isContainMonsterOfTraitValueBatch(
        uint256 _valueId,
        bool _isShadow,
        uint256[] calldata _monsterIds
    ) external view returns (bool);

    function getMonsterLengthOfTraitValue(
        uint256 _valueId,
        bool _isShadow
    ) external view returns (uint256);

    function getMonsterIdOfTraitType(
        uint256 _typeId,
        bool _isShadow
    ) external view returns (uint256[] memory);

    function getMonsterIdOfTraitValue(
        uint256 _valueId,
        bool _isShadow
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {MonsterFactoryError} from "../errors/MonsterFactoryError.sol";

/// @notice Core storage and event for monster factory contract
abstract contract MonsterFactoryBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    MonsterFactoryError
{
    CountersUpgradeable.Counter internal traitTypeIds;
    CountersUpgradeable.Counter internal traitValueIds;

    /*
     *  Struct
     */
    struct TraitType {
        uint64 id;
        uint32 createdTimestamp;
        bool isActive;
        string name;
    }

    struct TraitValue {
        uint64 id;
        uint64 typeId;
        uint32 createdTimestamp;
        string name;
    }

    struct TraitMonsterSet {
        uint256 valueId;
        uint256[] normalMonsterIds;
        uint256[] shadowMonsterIds;
    }

    /*
     *  Mapping
     */
    /// @notice isShadow to monsterId
    mapping(bool => CountersUpgradeable.Counter) internal monsterIds;

    /// @notice RankType to isShadow to monsterIds
    mapping(RankType => mapping(bool => EnumerableSetUpgradeable.UintSet))
        internal monsterOfRankType;

    /// @notice isShadow to monsterId to RankType
    mapping(bool => mapping(uint256 => RankType)) internal monsterRankTypes;

    /// @notice RankType to isShadow to monster collecting score
    mapping(RankType => mapping(bool => uint256)) internal monsterScores;

    /// @notice traitTypeId to TraitType
    mapping(uint256 => TraitType) internal traitTypes;

    /// @notice valueId to TraitValue
    mapping(uint256 => TraitValue) internal traitValues;

    /// @notice traitType name to traitTypeId
    mapping(bytes32 => uint256) internal typeIdByName;

    /// @notice traitTypeId to traitValue name to traitValueId
    mapping(uint256 => mapping(bytes32 => uint256)) internal valueIdByName;

    /// @notice traitTypeId to traitValueIds
    mapping(uint256 => EnumerableSetUpgradeable.UintSet)
        internal traitValueOfType;

    /// @notice traitTypeId to isShadow to monsterIds
    mapping(uint256 => mapping(bool => EnumerableSetUpgradeable.UintSet))
        internal monsterOfTraitType;

    /// @notice traitValueId to isShadow to monsterIds
    mapping(uint256 => mapping(bool => EnumerableSetUpgradeable.UintSet))
        internal monsterOfTraitValue;

    /*
     *  Event
     */
    event AddMonster(
        RankType indexed monsterRank,
        bool indexed isShadow,
        uint256 monsterId,
        uint256 timestamp
    );

    event SetMonsterRankType(
        bool indexed isShadow,
        uint256 indexed monsterId,
        RankType monsterRank,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {}

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {}

    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(
            AddressUpgradeable.isContract(newImplementation),
            "ERC1967: new implementation is not a contract"
        );
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                require(
                    slot == _IMPLEMENTATION_SLOT,
                    "ERC1967Upgrade: unsupported proxiableUUID"
                );
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(
            newAdmin != address(0),
            "ERC1967: new admin is the zero address"
        );
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(
            AddressUpgradeable.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        require(
            AddressUpgradeable.isContract(
                IBeaconUpgradeable(newBeacon).implementation()
            ),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data)
        private
        returns (bytes memory)
    {
        require(
            AddressUpgradeable.isContract(target),
            "Address: delegate call to non-contract"
        );

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            AddressUpgradeable.verifyCallResult(
                success,
                returndata,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) ||
                (!AddressUpgradeable.isContract(address(this)) &&
                    _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(
            !_initializing && _initialized < version,
            "Initializable: contract is already initialized"
        );
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    IERC1822ProxiableUpgradeable,
    ERC1967UpgradeUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(
            address(this) != __self,
            "Function must be called through delegatecall"
        );
        require(
            _getImplementation() == __self,
            "Function must be called through active proxy"
        );
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(
            address(this) == __self,
            "UUPSUpgradeable: must not be called through delegatecall"
        );
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data)
        external
        payable
        virtual
        onlyProxy
    {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {ProjectBase} from "./ProjectBase.sol";
import {ISLRoleWallet} from "../wallet/ISLRoleWallet.sol";

interface ISLProject {
    /*
     *  Authorization
     */
    function isOperatorMaster(address _account) external view returns (bool);

    function isOperator(address _account) external view returns (bool);

    /*
     *  Role
     */
    function setOperator(ISLRoleWallet _operator) external;

    function getOperator() external view returns (address);

    /*
     *  Universe
     */
    function addUniverse() external;

    function setUniverseActive(uint256 _universeId, bool _isActive) external;

    function getUniverseId() external view returns (uint256);

    function isExistUniverseById(
        uint256 _universeId
    ) external view returns (bool);

    function isActiveUniverse(uint256 _universeId) external view returns (bool);

    function getUniverseById(
        uint256 _universeId
    )
        external
        view
        returns (
            ProjectBase.Universe memory universe,
            uint256[] memory collectionIds
        );

    function addCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external;

    function removeCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external;

    /*
     *  Collection
     */
    function addCollection(address _tokenContract, address _creator) external;

    function setCollectionTokenContract(
        uint256 _collectionId,
        address _tokenContract
    ) external;

    function setCollectionCreator(
        uint256 _collectionId,
        address _creator
    ) external;

    function setCollectionActive(
        uint256 _collectionId,
        bool _isActive
    ) external;

    function getCollectionId() external view returns (uint256);

    function isExistCollectionById(
        uint256 _collectionId
    ) external view returns (bool);

    function isExistTokenContract(
        address _tokenContract
    ) external view returns (bool);

    function isActiveCollection(
        uint256 _collectionId
    ) external view returns (bool);

    function getCollectionById(
        uint256 _collectionId
    ) external view returns (ProjectBase.Collection memory);

    function getCollectionIdByToken(
        address _tokenContract
    ) external view returns (uint256);

    function isContainCollectionOfUniverse(
        uint256 _universeId,
        uint256 _collectionId
    ) external view returns (bool);

    function getCollectionIdOfUniverse(
        uint256 _universeId,
        bool _activeFilter
    ) external view returns (uint256[] memory);

    function getCollectionByToken(
        address _tokenContract
    ) external view returns (ProjectBase.Collection memory);

    function getTokenContractByCollectionId(
        uint256 _collectionId
    ) external view returns (address);

    function getCollectionTypeByCollectionId(
        uint256 _collectionId
    ) external view returns (BaseStorage.TokenType);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {ProjectError} from "../errors/ProjectError.sol";
import {ISLRoleWallet} from "../wallet/ISLRoleWallet.sol";

/// @notice Core storage and event for project contract
abstract contract ProjectBase is SLBaseUpgradeable, ProjectError {
    CountersUpgradeable.Counter internal universeIds;
    CountersUpgradeable.Counter internal collectionIds;

    /// @notice operator multisig wallet
    ISLRoleWallet operator;

    /*
     *  Struct
     */
    struct Universe {
        uint64 id;
        uint32 createdTimestamp;
        bool isActive;
    }

    struct Collection {
        uint64 id;
        uint32 createdTimestamp;
        bool isActive;
        address tokenContract;
        address creator;
        TokenType tokenType;
    }

    /*
     *  Mapping
     */
    /// @notice universeId to Universe
    mapping(uint256 => Universe) internal universes;

    /// @notice collectionId to Collection
    mapping(uint256 => Collection) internal collections;

    /// @notice universeId to collectionIds
    mapping(uint256 => EnumerableSetUpgradeable.UintSet)
        internal collectionOfUniverse;

    /// @notice tokenContract to collectionId
    mapping(address => uint256) internal collectionByTokenContract;

    /*
     *  Event
     */
    event SetOperator(address operator, uint256 timestamp);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLRandom {
    /*
     *  Signer
     */
    function setRandomSigner(address _signer) external;

    function getRandomSigner() external view returns (address);

    /*
     *  Verify
     */
    function verifyRandomSignature(
        address _hunter,
        bytes calldata _signature
    ) external;

    function getNonce(address _hunter) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {SeasonBase} from "./SeasonBase.sol";
import {ISLMonsterFactory} from "../monsterFactory/ISLMonsterFactory.sol";

interface ISLSeason {
    /*
     *  Season
     */
    function addSeason(
        uint256 _hunterRankCollectionId,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256[] calldata _seasonCollectionIds
    ) external;

    function setSeasonCollection(
        uint256 _seasonId,
        uint256 _hunterRankCollectionId,
        uint256[] calldata _seasonCollectionIds
    ) external;

    function setSeasonBlock(
        uint256 _seasonId,
        uint256 _startBlock,
        uint256 _endBlock
    ) external;

    function isExistSeasonById(uint256 _seasonId) external view returns (bool);

    function isCurrentSeasonById(
        uint256 _seasonId
    ) external view returns (bool);

    function isEndedSeasonById(uint256 _seasonId) external view returns (bool);

    function isStartSeasonById(uint256 _seasonId) external view returns (bool);

    function getSeasonById(
        uint256 _seasonId
    ) external view returns (SeasonBase.Season memory);

    function getSeasonCollection(
        uint256 _seasonId
    ) external view returns (uint256[] memory);

    function getSeasonLength() external view returns (uint256);

    /*
     *  RankUp
     */

    function claimERank(uint256 _seasonId) external;

    function rankUp(
        uint256 _seasonId,
        BaseStorage.RankType _hunterRank,
        uint256[] calldata _monsterIds,
        uint256[] calldata _monsterAmounts,
        bool _isShadow
    ) external;

    function setRequiredMonsterForRankUp(
        uint256[5] calldata _requiredNormalMonsters,
        uint256[2] calldata _requiredShadowMonsters
    ) external;

    function getRequiredMonsterForRankUp()
        external
        view
        returns (
            uint256[5] memory requiredNormalMonsters,
            uint256[2] memory requiredShadowMonsters
        );

    function getHunterRankTokenBalance(
        uint256 _seasonId,
        address _hunter
    ) external view returns (uint256[] memory);

    function getHunterRank(
        uint256 _seasonId,
        address _hunter
    ) external view returns (BaseStorage.RankType);

    /*
     *  Collection
     */
    function setMonsterCollectionId(
        uint256 _monsterCollectionId,
        bool _isShadow
    ) external;

    function getMonsterCollectionId(
        bool _isShadow
    ) external view returns (uint256);

    /*
     *  Base
     */
    function setMonsterFactoryContract(
        ISLMonsterFactory _monsterFactoryContract
    ) external;

    function getMonsterFactoryContract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {SeasonError} from "../errors/SeasonError.sol";
import {ISLMonsterFactory} from "../monsterFactory/ISLMonsterFactory.sol";

/// @notice Core storage and event for season contract
abstract contract SeasonBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    SeasonError
{
    CountersUpgradeable.Counter internal seasonIds;

    // monsterFactory contract
    ISLMonsterFactory monsterFactoryContract;

    // collectionId
    uint256 internal normalMonsterCollectionId;
    uint256 internal shadowMonsterCollectionId;

    /*
     *  Struct
     */
    struct Season {
        uint64 id;
        uint64 hunterRankCollectionId;
        uint32 startBlock;
        uint32 endBlock;
        uint256[] seasonCollectionIds;
    }

    /*
     *  Mapping
     */
    /// @notice seasonId to Season
    mapping(uint256 => Season) internal seasons;

    /// @notice RankType to required normal monster count for hunter rankUp
    mapping(RankType => uint256) internal requiredNormalMonsterForRankUp; // E-A

    /// @notice RankType to required shadow monster count for hunter rankUp
    mapping(RankType => uint256) internal requiredShadowMonsterForRankUp; // B-A

    /*
     *  Event
     */
    event ERankClaimed(
        uint256 indexed seasonId,
        address indexed hunter,
        uint256 timestamp
    );

    event HunterRankUp(
        uint256 indexed seasonId,
        address indexed hunter,
        RankType indexed rankType,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {BaseStorage} from "../core/BaseStorage.sol";
import {SeasonQuestBase} from "./SeasonQuestBase.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLMonsterFactory} from "../monsterFactory/ISLMonsterFactory.sol";

interface ISLSeasonQuest {
    /*
     *  Quest
     */
    function addGeneralQuest(
        SeasonQuestBase.QuestInput calldata _quest
    ) external;

    function addMonsterSetQuest(
        SeasonQuestBase.QuestInput calldata _quest,
        SeasonQuestBase.MonsterSet calldata _monsterSet
    ) external;

    function addMonsterTraitQuest(
        SeasonQuestBase.QuestInput calldata _quest,
        SeasonQuestBase.MonsterTrait calldata _monsterTrait
    ) external;

    function setQuestActive(uint256 _questId, bool _isActive) external;

    function isExistQuestById(uint256 _questId) external view returns (bool);

    function isActiveQuest(uint256 _questId) external view returns (bool);

    function getQuestCompletedCount(
        uint256 _questId,
        address _hunter
    ) external view returns (uint256);

    function getQuestById(
        uint256 _questId
    ) external view returns (SeasonQuestBase.Quest memory);

    function getMonsterSetQuestById(
        uint256 _questId
    )
        external
        view
        returns (
            SeasonQuestBase.Quest memory quest,
            SeasonQuestBase.MonsterSet memory monsterSet
        );

    function getMonsterTraitQuestById(
        uint256 _questId
    )
        external
        view
        returns (
            SeasonQuestBase.Quest memory quest,
            SeasonQuestBase.MonsterTrait memory monsterTrait
        );

    function getQuestTypeById(
        uint256 _questId
    ) external view returns (SeasonQuestBase.QuestType);

    function getQuestLength() external view returns (uint256);

    function getQuestIdOfSeason(
        uint256 _seasonId,
        bool _activeFilter
    ) external view returns (uint256[] memory);

    function getQuestIdOfQuestType(
        uint256 _seasonId,
        SeasonQuestBase.QuestType _questType
    ) external view returns (uint256[] memory);

    function getHunterQuestScore(
        uint256 _seasonId,
        address _hunter
    ) external view returns (uint256);

    function getHunterQuestScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) external view returns (uint256[] memory);

    /*
     *  Comfirm
     */
    function confirmGeneralQuest(
        uint256 _questId,
        bytes calldata _questSignature
    ) external;

    function confirmMonsterSetQuest(uint256 _questId) external;

    function confirmMonsterTraitQuest(
        uint256 _questId,
        SeasonQuestBase.MonsterSet calldata _traitMonsterSet
    ) external;

    /*
     *  Collection
     */
    function setHunterItemCollectionId(
        uint256 _hunterItemCollectionId
    ) external;

    function setMonsterCollectionId(
        uint256 _monsterCollectionId,
        bool _isShadow
    ) external;

    function getHunterItemCollectionId() external view returns (uint256);

    function getMonsterCollectionId(
        bool _isShadow
    ) external view returns (uint256);

    /*
     *  Base
     */
    function setMonsterFactoryContract(
        ISLMonsterFactory _monsterFactoryContract
    ) external;

    function setSeasonContract(ISLSeason _seasonContract) external;

    function getMonsterFactoryContract() external view returns (address);

    function getSeasonContract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {SeasonQuestError} from "../errors/SeasonQuestError.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLMonsterFactory} from "../monsterFactory/ISLMonsterFactory.sol";

/// @notice Core storage and event for season quest contract
abstract contract SeasonQuestBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    SeasonQuestError
{
    CountersUpgradeable.Counter internal questIds;

    // season contract
    ISLSeason internal seasonContract;

    // monsterFactory contract
    ISLMonsterFactory internal monsterFactoryContract;

    // collectionId
    uint256 internal hunterItemCollectionId;
    uint256 internal normalMonsterCollectionId;
    uint256 internal shadowMonsterCollectionId;

    /*
     *  Struct
     */
    struct Quest {
        uint64 id;
        uint64 seasonId;
        uint128 rewardScore; // 256
        uint32 completableCount;
        uint64 requiredQuestId;
        bool isActive;
        QuestType questType;
        RankType rankType;
        uint256[] hunterItemIds;
    }

    struct MonsterSet {
        uint256[] normalMonsterIds;
        uint256[] normalMonsterAmounts;
        uint256[] shadowMonsterIds;
        uint256[] shadowMonsterAmounts;
    }

    struct MonsterTrait {
        uint256 requiredNormalMonster;
        uint256 requiredShadowMonster;
        Trait[] traits;
    }

    struct Trait {
        uint64 traitTypeId;
        uint64 traitValueId;
    }

    struct QuestInput {
        uint64 seasonId;
        uint128 rewardScore;
        uint32 completableCount;
        uint64 requiredQuestId;
        RankType rankType;
        uint256[] hunterItemIds;
    }

    /*
     *  Mapping
     */
    /// @notice questId to Quest
    mapping(uint256 => Quest) internal quests;

    /// @notice monsterSet questId to MonsterSet
    mapping(uint256 => MonsterSet) internal monsterSets;

    /// @notice monsterTrait questId to monsterTrait
    mapping(uint256 => MonsterTrait) internal monsterTraits;

    /// @notice seasonId to questIds
    mapping(uint256 => EnumerableSetUpgradeable.UintSet) internal questOfSeason;

    /// @notice seasonId to QuestType to questIds
    mapping(uint256 => mapping(QuestType => EnumerableSetUpgradeable.UintSet))
        internal questOfQuestType;

    /// @notice questId to hunter to completed count
    mapping(uint256 => mapping(address => CountersUpgradeable.Counter))
        internal questCompleted;

    /// @notice seasonId to hunter to quest score
    mapping(uint256 => mapping(address => uint256)) internal questScores;

    /*
     *  Enum
     */
    enum QuestType {
        MonsterSet,
        MonsterTrait,
        General
    }

    /*
     *  Event
     */
    event QuestCompleted(
        address indexed hunter,
        uint256 indexed questId,
        uint256 currentScore,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {SeasonSettlementBase} from "./SeasonSettlementBase.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLSeasonQuest} from "../seasonQuest/ISLSeasonQuest.sol";
import {ISLDungeonGate} from "../dungeonGate/ISLDungeonGate.sol";

interface ISLSeasonSettlement {
    /*
     *  Score
     */
    function getCurrentSeasonScore(
        uint256 _seasonId,
        address _hunter
    )
        external
        view
        returns (SeasonSettlementBase.SeasonScore memory seasonScore);

    function getCurrentSeasonScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    )
        external
        view
        returns (SeasonSettlementBase.SeasonScore[] memory seasonScores);

    function getEndedSeasonScore(
        uint256 _seasonId,
        address _hunter
    )
        external
        view
        returns (SeasonSettlementBase.SeasonScore memory seasonScore);

    function getEndedSeasonScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    )
        external
        view
        returns (SeasonSettlementBase.SeasonScore[] memory seasonScores);

    /*
     *  Score Base
     */
    function setScoreRate(
        uint32 _questRate,
        uint32 _activityRate,
        uint32 _collectingRate
    ) external;

    function setScorePerGate(uint256 _scorePerGate) external;

    function getScoreRate()
        external
        view
        returns (SeasonSettlementBase.ScoreRate memory);

    function getScorePerGate() external view returns (uint256);

    /*
     *  Reward
     */
    function claimSeasonReward(uint256 _seasonId) external;

    function isSeasonRewardClaimed(
        uint256 _seasonId,
        address _hunter
    ) external view returns (bool);

    /*
     *  Collection
     */
    function setSRankRewardCollectionId(
        uint256 _SRankRewardCollectionId
    ) external;

    function setSeasonScoreCollectionId(
        uint256 _seasonScoreCollectionId
    ) external;

    function getSRankRewardCollectionId() external view returns (uint256);

    function getSeasonScoreCollectionId() external view returns (uint256);

    /*
     *  Base
     */
    function setSeasonContract(ISLSeason _seasonContract) external;

    function setSeasonQuestContract(
        ISLSeasonQuest _seasonQuestContract
    ) external;

    function setDungeonGateContract(
        ISLDungeonGate _dungeonGateContract
    ) external;

    function getSeasonContract() external view returns (address);

    function getSeasonQuestContract() external view returns (address);

    function getDungeonGateContract() external view returns (address);

    function getDenominator() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Score} from "./Score.sol";
import {ISLMT} from "../../collections/ISLMT.sol";

abstract contract Reward is Score {
    /*
     *  Reward
     */
    function claimSeasonReward(uint256 _seasonId) external {
        address hunter = _msgSender();

        if (isSeasonRewardClaimed(_seasonId, hunter)) revert AlreadyClaimed();

        rewardClaimed[_seasonId][hunter] = true;

        SeasonScore memory seasonScore = getEndedSeasonScore(_seasonId, hunter);
        RankType hunterRank = seasonContract.getHunterRank(_seasonId, hunter);

        uint256 SRankRewardTokenId;

        if (hunterRank == RankType.S && SRankRewardCollectionId != 0) {
            ISLMT rewardCollection = ISLMT(
                projectContract.getTokenContractByCollectionId(
                    SRankRewardCollectionId
                )
            );

            SRankRewardTokenId = _seasonId;
            rewardCollection.mint(hunter, _seasonId, 1);
        }

        uint256 mintedSeasonScore;

        if (seasonScore.seasonScore > 0 && seasonScoreCollectionId != 0) {
            ISLMT seasonScoreCollection = ISLMT(
                projectContract.getTokenContractByCollectionId(
                    seasonScoreCollectionId
                )
            );

            seasonScoreCollection.mint(
                hunter,
                _seasonId,
                seasonScore.seasonScore
            );
            mintedSeasonScore = seasonScore.seasonScore;
        }

        emit SeasonRewardClaimed(
            _seasonId,
            hunter,
            mintedSeasonScore,
            SRankRewardTokenId,
            block.timestamp
        );
    }

    function isSeasonRewardClaimed(
        uint256 _seasonId,
        address _hunter
    ) public view returns (bool) {
        return rewardClaimed[_seasonId][_hunter];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {Unsafe} from "../../utils/Unsafe.sol";

import {ISLSeasonSettlement} from "../ISLSeasonSettlement.sol";
import {SeasonSettlementBase} from "../SeasonSettlementBase.sol";
import {ISLCollectable} from "../../collections/ISLCollectable.sol";
import {SeasonBase} from "../../season/SeasonBase.sol";

abstract contract Score is ISLSeasonSettlement, SeasonSettlementBase {
    using Unsafe for uint256;

    /*
     *  Score
     */
    function getCurrentSeasonScore(
        uint256 _seasonId,
        address _hunter
    ) external view returns (SeasonScore memory seasonScore) {
        if (!seasonContract.isCurrentSeasonById(_seasonId))
            revert InvalidSeasonId();

        uint256 questScore = _getHunterQuestScore(_seasonId, _hunter);
        uint256 activityScore = _getActivityScore(_seasonId, _hunter);
        uint256 collectingScore = _getLatestCollectingScore(_seasonId, _hunter);

        uint256 convertedQuestScore = _calculateQuestScore(questScore);
        uint256 convertedActivityScore = _calculateActivityScore(activityScore);
        uint256 convertedCollectingScore = _calculateCollectingScore(
            collectingScore
        );

        seasonScore = SeasonScore({
            questScore: questScore,
            convertedQuestScore: convertedQuestScore,
            activityScore: activityScore,
            convertedActivityScore: convertedActivityScore,
            collectingScore: collectingScore,
            convertedCollectingScore: convertedCollectingScore,
            seasonScore: convertedQuestScore +
                convertedActivityScore +
                convertedCollectingScore
        });
    }

    function getCurrentSeasonScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) external view returns (SeasonScore[] memory seasonScores) {
        if (!seasonContract.isCurrentSeasonById(_seasonId))
            revert InvalidSeasonId();

        uint256 hunterCount = _hunters.length;

        uint256[] memory questScores = _getHunterQuestScoreBatch(
            _seasonId,
            _hunters
        );
        uint256[] memory activityScores = _getActivityScoreBatch(
            _seasonId,
            _hunters
        );
        uint256[] memory collectingScores = _getLatestCollectingScoreBatch(
            _seasonId,
            _hunters
        );

        seasonScores = new SeasonScore[](hunterCount);

        for (uint256 i = 0; i < hunterCount; i = i.increment()) {
            uint256 questScore = questScores[i];
            uint256 activityScore = activityScores[i];
            uint256 collectingScore = collectingScores[i];

            uint256 convertedQuestScore = _calculateQuestScore(questScore);
            uint256 convertedActivityScore = _calculateActivityScore(
                activityScore
            );
            uint256 convertedCollectingScore = _calculateCollectingScore(
                collectingScore
            );

            seasonScores[i] = SeasonScore({
                questScore: questScore,
                convertedQuestScore: convertedQuestScore,
                activityScore: activityScore,
                convertedActivityScore: convertedActivityScore,
                collectingScore: collectingScore,
                convertedCollectingScore: convertedCollectingScore,
                seasonScore: convertedQuestScore +
                    convertedActivityScore +
                    convertedCollectingScore
            });
        }
    }

    function getEndedSeasonScore(
        uint256 _seasonId,
        address _hunter
    ) public view returns (SeasonScore memory seasonScore) {
        if (!seasonContract.isEndedSeasonById(_seasonId))
            revert InvalidSeasonId();

        uint256 questScore = _getHunterQuestScore(_seasonId, _hunter);
        uint256 activityScore = _getActivityScore(_seasonId, _hunter);
        uint256 collectingScore = _getCollectingScoreAtEnded(
            _seasonId,
            _hunter
        );

        uint256 convertedQuestScore = _calculateQuestScore(questScore);
        uint256 convertedActivityScore = _calculateActivityScore(activityScore);
        uint256 convertedCollectingScore = _calculateCollectingScore(
            collectingScore
        );

        seasonScore = SeasonScore({
            questScore: questScore,
            convertedQuestScore: convertedQuestScore,
            activityScore: activityScore,
            convertedActivityScore: convertedActivityScore,
            collectingScore: collectingScore,
            convertedCollectingScore: convertedCollectingScore,
            seasonScore: convertedQuestScore +
                convertedActivityScore +
                convertedCollectingScore
        });
    }

    function getEndedSeasonScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) external view returns (SeasonScore[] memory seasonScores) {
        if (!seasonContract.isEndedSeasonById(_seasonId))
            revert InvalidSeasonId();

        uint256 hunterCount = _hunters.length;

        uint256[] memory questScores = _getHunterQuestScoreBatch(
            _seasonId,
            _hunters
        );
        uint256[] memory activityScores = _getActivityScoreBatch(
            _seasonId,
            _hunters
        );
        uint256[] memory collectingScores = _getCollectionScoreAtEndedBatch(
            _seasonId,
            _hunters
        );

        seasonScores = new SeasonScore[](hunterCount);

        for (uint256 i = 0; i < hunterCount; i = i.increment()) {
            uint256 questScore = questScores[i];
            uint256 activityScore = activityScores[i];
            uint256 collectingScore = collectingScores[i];

            uint256 convertedQuestScore = _calculateQuestScore(questScore);
            uint256 convertedActivityScore = _calculateActivityScore(
                activityScore
            );
            uint256 convertedCollectingScore = _calculateCollectingScore(
                collectingScore
            );

            seasonScores[i] = SeasonScore({
                questScore: questScore,
                convertedQuestScore: convertedQuestScore,
                activityScore: activityScore,
                convertedActivityScore: convertedActivityScore,
                collectingScore: collectingScore,
                convertedCollectingScore: convertedCollectingScore,
                seasonScore: convertedQuestScore +
                    convertedActivityScore +
                    convertedCollectingScore
            });
        }
    }

    function _getHunterQuestScore(
        uint256 _seasonId,
        address _hunter
    ) private view returns (uint256) {
        return seasonQuestContract.getHunterQuestScore(_seasonId, _hunter);
    }

    function _getHunterQuestScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) private view returns (uint256[] memory) {
        return
            seasonQuestContract.getHunterQuestScoreBatch(_seasonId, _hunters);
    }

    function _getActivityScore(
        uint256 _seasonId,
        address _hunter
    ) private view returns (uint256) {
        uint256 gateCount = dungeonGateContract.getGateCountOfSeason(
            _seasonId,
            _hunter
        );
        return gateCount * scorePerGate;
    }

    function _getActivityScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) private view returns (uint256[] memory) {
        uint256 hunterCount = _hunters.length;

        uint256[] memory gateCounts = dungeonGateContract
            .getGateCountOfSeasonBatch(_seasonId, _hunters);

        uint256[] memory activityScores = new uint256[](hunterCount);

        for (uint256 i = 0; i < hunterCount; i = i.increment()) {
            activityScores[i] = gateCounts[i] * scorePerGate;
        }

        return activityScores;
    }

    function _getLatestCollectingScore(
        uint256 _seasonId,
        address _hunter
    ) private view returns (uint256) {
        uint256 collectingScore;

        uint256[] memory seasonCollectionIds = seasonContract
            .getSeasonCollection(_seasonId);

        for (uint256 i = 0; i < seasonCollectionIds.length; i = i.increment()) {
            uint256 collectionId = seasonCollectionIds[i];
            ISLCollectable collection = ISLCollectable(
                projectContract.getTokenContractByCollectionId(collectionId)
            );

            collectingScore += collection.getLatestCollectingScore(_hunter);
        }

        return collectingScore;
    }

    function _getLatestCollectingScoreBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) private view returns (uint256[] memory) {
        uint256 hunterCount = _hunters.length;

        uint256[] memory results = new uint256[](hunterCount);

        uint256[] memory seasonCollectionIds = seasonContract
            .getSeasonCollection(_seasonId);

        for (uint256 i = 0; i < seasonCollectionIds.length; i = i.increment()) {
            uint256 collectionId = seasonCollectionIds[i];
            ISLCollectable collection = ISLCollectable(
                projectContract.getTokenContractByCollectionId(collectionId)
            );

            uint256[] memory collectingScores = collection
                .getLatestCollectingScoreBatch(_hunters);

            for (uint256 j = 0; j < hunterCount; j = j.increment()) {
                results[j] += collectingScores[j];
            }
        }

        return results;
    }

    function _getCollectingScoreAtEnded(
        uint256 _seasonId,
        address _hunter
    ) private view returns (uint256) {
        uint256 collectingScore;
        SeasonBase.Season memory season = seasonContract.getSeasonById(
            _seasonId
        );
        uint256 blockNumber = season.endBlock;
        uint256[] memory seasonCollectionIds = season.seasonCollectionIds;
        for (uint256 i = 0; i < seasonCollectionIds.length; i = i.increment()) {
            uint256 collectionId = seasonCollectionIds[i];
            ISLCollectable collection = ISLCollectable(
                projectContract.getTokenContractByCollectionId(collectionId)
            );

            collectingScore += collection.getCollectingScoreAtBlock(
                _hunter,
                blockNumber
            );
        }

        return collectingScore;
    }

    function _getCollectionScoreAtEndedBatch(
        uint256 _seasonId,
        address[] calldata _hunters
    ) private view returns (uint256[] memory) {
        uint256 hunterCount = _hunters.length;

        uint256[] memory results = new uint256[](hunterCount);

        SeasonBase.Season memory season = seasonContract.getSeasonById(
            _seasonId
        );
        uint256 blockNumber = season.endBlock;
        uint256[] memory seasonCollectionIds = season.seasonCollectionIds;

        for (uint256 i = 0; i < seasonCollectionIds.length; i = i.increment()) {
            uint256 collectionId = seasonCollectionIds[i];

            ISLCollectable collection = ISLCollectable(
                projectContract.getTokenContractByCollectionId(collectionId)
            );

            uint256[] memory collectingScores = collection
                .getCollectingScoreAtBlockBatch(
                    _hunters,
                    _asUintArray(blockNumber, hunterCount)
                );

            for (uint256 j = 0; j < hunterCount; j = j.increment()) {
                results[j] += collectingScores[j];
            }
        }

        return results;
    }

    function _calculateQuestScore(
        uint256 _questScore
    ) private view returns (uint256) {
        return (_questScore * scoreRate.quest) / DENOMINATOR;
    }

    function _calculateActivityScore(
        uint256 _activityScore
    ) private view returns (uint256) {
        return (_activityScore * scoreRate.activity) / DENOMINATOR;
    }

    function _calculateCollectingScore(
        uint256 _collectingScore
    ) private view returns (uint256) {
        return (_collectingScore * scoreRate.collecting) / DENOMINATOR;
    }

    function _asUintArray(
        uint256 _element,
        uint256 _length
    ) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](_length);

        for (uint256 i = 0; i < _length; i = i.increment()) {
            array[i] = _element;
        }

        return array;
    }

    /*
     *  Base
     */
    function setScoreRate(
        uint32 _questRate,
        uint32 _activityRate,
        uint32 _collectingRate
    ) external onlyOperator {
        if (_questRate + _activityRate + _collectingRate != DENOMINATOR)
            revert InvalidRate();

        scoreRate.quest = _questRate;
        scoreRate.activity = _activityRate;
        scoreRate.collecting = _collectingRate;

        emit SetScoreRate(
            _questRate,
            _activityRate,
            _collectingRate,
            block.timestamp
        );
    }

    function setScorePerGate(uint256 _scorePerGate) external onlyOperator {
        scorePerGate = _scorePerGate;
    }

    function getScoreRate() external view returns (ScoreRate memory) {
        return scoreRate;
    }

    function getScorePerGate() external view returns (uint256) {
        return scorePerGate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {CountersUpgradeable} from "../utils/CountersUpgradeable.sol";
import {EnumerableSetUpgradeable} from "../utils/EnumerableSetUpgradeable.sol";

import {SLBaseUpgradeable} from "../core/SLBaseUpgradeable.sol";
import {SLControllerUpgradeable} from "../core/SLControllerUpgradeable.sol";
import {SeasonSettlementError} from "../errors/SeasonSettlementError.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLSeasonQuest} from "../seasonQuest/ISLSeasonQuest.sol";
import {ISLDungeonGate} from "../dungeonGate/ISLDungeonGate.sol";

/// @notice Core storage and event for season settlement contract
abstract contract SeasonSettlementBase is
    SLBaseUpgradeable,
    SLControllerUpgradeable,
    SeasonSettlementError
{
    /// @notice precision 100.00000%
    uint256 internal constant DENOMINATOR = 100_00000;

    // season contract
    ISLSeason internal seasonContract;

    // season quest contract
    ISLSeasonQuest internal seasonQuestContract;

    // dungeon gate contract
    ISLDungeonGate internal dungeonGateContract;

    uint256 internal SRankRewardCollectionId;
    uint256 internal seasonScoreCollectionId;

    // score per gate clear
    uint256 internal scorePerGate;

    ScoreRate internal scoreRate;

    /*
     *  Struct
     */
    struct ScoreRate {
        uint32 quest;
        uint32 activity;
        uint32 collecting;
    }

    struct SeasonScore {
        uint256 questScore;
        uint256 convertedQuestScore;
        uint256 activityScore;
        uint256 convertedActivityScore;
        uint256 collectingScore;
        uint256 convertedCollectingScore;
        uint256 seasonScore;
    }

    /*
     *  Mapping
     */
    /// @notice seasonId to hunter to claimed reward
    mapping(uint256 => mapping(address => bool)) internal rewardClaimed;

    /*
     *  Event
     */
    event SetScoreRate(
        uint256 quest,
        uint256 activity,
        uint256 collecting,
        uint256 timestamp
    );

    event SeasonRewardClaimed(
        uint256 indexed seasonId,
        address indexed hunter,
        uint256 mintedSeasonScore,
        uint256 SRankRewardTokenId,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {UUPSUpgradeable} from "../utils/UUPSUpgradeable.sol";

import {Reward} from "./parts/Reward.sol";
import {ISLProject} from "../project/ISLProject.sol";
import {ISLSeason} from "../season/ISLSeason.sol";
import {ISLSeasonQuest} from "../seasonQuest/ISLSeasonQuest.sol";
import {ISLDungeonGate} from "../dungeonGate/ISLDungeonGate.sol";

contract SLSeasonSettlement is Reward, UUPSUpgradeable {
    function initialize(
        ISLProject _projectContract,
        ISLSeason _seasonContract,
        ISLSeasonQuest _seasonQuestContract,
        ISLDungeonGate _dungeonGateContract,
        uint256 _SRankRewardCollectionId,
        uint256 _seasonScoreCollectionId
    ) public initializer {
        __SLCotroller_init(_projectContract);

        seasonContract = _seasonContract;
        seasonQuestContract = _seasonQuestContract;
        dungeonGateContract = _dungeonGateContract;

        SRankRewardCollectionId = _SRankRewardCollectionId;
        seasonScoreCollectionId = _seasonScoreCollectionId;

        scorePerGate = 100;
        scoreRate = ScoreRate({
            quest: 50_00000,
            activity: 30_00000,
            collecting: 20_00000
        });
    }

    function _authorizeUpgrade(address) internal override onlyOperatorMaster {}

    /*
     *  Collection
     */
    function setSRankRewardCollectionId(
        uint256 _SRankRewardCollectionId
    ) external onlyOperator {
        if (!projectContract.isActiveCollection(_SRankRewardCollectionId))
            revert InvalidCollectionId();

        TokenType tokenType = projectContract.getCollectionTypeByCollectionId(
            _SRankRewardCollectionId
        );

        if (tokenType != TokenType.ERC1155) revert InvalidCollectionId();

        SRankRewardCollectionId = _SRankRewardCollectionId;
    }

    function setSeasonScoreCollectionId(
        uint256 _seasonScoreCollectionId
    ) external onlyOperator {
        if (!projectContract.isActiveCollection(_seasonScoreCollectionId))
            revert InvalidCollectionId();

        TokenType tokenType = projectContract.getCollectionTypeByCollectionId(
            _seasonScoreCollectionId
        );

        if (tokenType != TokenType.ERC1155) revert InvalidCollectionId();

        seasonScoreCollectionId = _seasonScoreCollectionId;
    }

    function getSRankRewardCollectionId() external view returns (uint256) {
        return SRankRewardCollectionId;
    }

    function getSeasonScoreCollectionId() external view returns (uint256) {
        return seasonScoreCollectionId;
    }

    /*
     *  Base
     */
    function setSeasonContract(
        ISLSeason _seasonContract
    ) external onlyOperatorMaster {
        seasonContract = _seasonContract;
    }

    function setSeasonQuestContract(
        ISLSeasonQuest _seasonQuestContract
    ) external onlyOperatorMaster {
        seasonQuestContract = _seasonQuestContract;
    }

    function setDungeonGateContract(
        ISLDungeonGate _dungeonGateContract
    ) external onlyOperatorMaster {
        dungeonGateContract = _dungeonGateContract;
    }

    function getSeasonContract() external view returns (address) {
        return address(seasonContract);
    }

    function getSeasonQuestContract() external view returns (address) {
        return address(seasonQuestContract);
    }

    function getDungeonGateContract() external view returns (address) {
        return address(dungeonGateContract);
    }

    function getDenominator() external pure returns (uint256) {
        return DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/ContextUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/CountersUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/proxy/utils/Initializable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Unsafe {
    function increment(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x + 1;
        }
    }

    function decrement(uint256 x) internal pure returns (uint256) {
        unchecked {
            return x - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../openzeppelin/upgradeable/proxy/utils/UUPSUpgradeable.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ISLRoleWallet {
    /*
     *  Event
     */
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event ExecuteTransaction(
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );
    event MasterAdded(address indexed master, uint256 timestamp);
    event MasterRemoved(address indexed master, uint256 timestamp);
    event ManagerAdded(address indexed manager, uint256 timestamp);
    event ManagerRemoved(address indexed manager, uint256 timestamp);

    /*
     *  Error
     */
    error RequiredMaster();
    error TransactionFailed();
    error OnlyMaster();
    error OnlyManager();
    error AlreadyExistAccount();
    error DoesNotExistAccount();

    function executeTransaction(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external;

    function hasRole(address _account) external view returns (bool);

    /*
     *  Master
     */
    function addMaster(address _master) external;

    function renounceMaster() external;

    function isMaster(address _master) external view returns (bool);

    function getMaster(uint256 _index) external view returns (address);

    function getMasters() external view returns (address[] memory);

    function getMasterCount() external view returns (uint256);

    /*
     *  Manager
     */

    function addManager(address _manager) external;

    function removeManager(address _manager) external;

    function renounceManager() external;

    function isManager(address _manager) external view returns (bool);

    function getManager(uint256 _index) external view returns (address);

    function getManagers() external view returns (address[] memory);

    function getManagerCount() external view returns (uint256);
}