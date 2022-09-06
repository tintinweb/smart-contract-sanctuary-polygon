// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {Base} from "../base/Base.sol";
import {ProjectStorage} from "../libraries/LibProjectStorage.sol";

contract ProjectFacet is Base {
    function getProjectById(uint256 id_)
        public
        view
        ensureProjectExists(id_)
        returns (ProjectStorage memory)
    {
        return s.projects[id_];
    }

    function isProjectActiveById(uint256 id_) public view returns (bool) {
        return getProjectById(id_).active;
    }

    function createProject(
        uint256 previousProjectId_,
        uint256 maxPerWallet_,
        string memory metadataUrl_,
        bool active_
    ) external {
        if (previousProjectId_ > 0 && !_projectExists(previousProjectId_))
            revert QueryNonExistentProject();
        if (maxPerWallet_ == 0) revert MaxPerWalletZero();
        s.projectsCount += 1;
        s.projects[s.projectsCount].previousProjectId = previousProjectId_;
        s.projects[s.projectsCount].maxPerWallet = maxPerWallet_;
        s.projects[s.projectsCount].metadataUrl = metadataUrl_;
        s.projects[s.projectsCount].active = active_;
    }

    function updateProject(
        uint256 id_,
        uint256 previousProjectId_,
        uint256 maxPerWallet_,
        string memory metadataUrl_,
        bool active_
    ) external ensureProjectExists(id_) {
        s.projects[id_].previousProjectId = previousProjectId_;
        s.projects[id_].maxPerWallet = maxPerWallet_;
        s.projects[id_].metadataUrl = metadataUrl_;
        s.projects[id_].active = active_;
    }

    function setProjectActive(uint256 projectId_, bool active_) external ensureProjectExists(projectId_) {
        if(active_ == s.projects[projectId_].active) revert ProjectAlreadyInState();
        s.projects[projectId_].active = active_;
    }

    function getAllProjects() external view returns (ProjectStorage[] memory) {
        ProjectStorage[] memory _projects = new ProjectStorage[](
            s.projectsCount
        );
        for (uint256 i = 0; i < s.projectsCount; i++) {
            _projects[i] = s.projects[i];
        }
        return _projects;
    }

    function _projectExists(uint256 id_) private view returns (bool) {
        return (id_ <= s.projectsCount && id_ > 0);
    }

    modifier ensureProjectExists(uint256 id_) {
        if (!_projectExists(id_)) revert QueryNonExistentProject();
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {AppStorage} from "../libraries/LibAppStorage.sol";
import {IBase} from "../interfaces/IBase.sol";

abstract contract Base is IBase {
    AppStorage internal s;
    uint256 constant MAX_UINT = type(uint256).max;

    modifier onlyEoA() {
        if(tx.origin != msg.sender) revert CallerNotEoA();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct ProjectStorage {
    uint256 previousProjectId;
    uint256 maxPerWallet;
    bool active;
    bool initialized;
    string metadataUrl;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {UserStorage} from "./LibUserStorage.sol";
import {ProjectStorage} from "./LibProjectStorage.sol";
import {AllowlistStorage} from "./LibAllowlistStorage.sol";
import {RaffleStorage} from "./LibRaffleStorage.sol";
import {SpotStorage} from "./LibSpotStorage.sol";
import {AllowlistStorage} from "./LibAllowlistStorage.sol";
import {UserInventoryAllowlistStorage} from "./LibUserInventoryAllowlistStorage.sol";
import {ListingStorage} from "./LibListingStorage.sol";

struct AppStorage {
    uint256 allowlistsCount;
    uint256 rafflesCount;
    uint256 usersCount;
    uint256 projectsCount;
    address createUserSigner;
    mapping(uint256 => ListingStorage) listings;
    // wallet =>
    mapping(address => UserStorage) users;
    // project id =>
    mapping(uint256 => ProjectStorage) projects;
    // listing id =>
    mapping(uint256 => AllowlistStorage) allowlists;
    // raffle id =>
    mapping(uint256 => RaffleStorage) raffles;
    // listing id =>
    mapping(uint256 => SpotStorage) spots;
    // address => project id => spots
    mapping(address => UserInventoryAllowlistStorage) userAllowlists;














    // wallet => listing => purchased balance
    mapping(address => mapping(uint256 => uint256)) userAllowlistsBalances;
    // wallet => listing => purchased id
    mapping(address => uint256[]) userAllowlistsPurchased;
    // wallet => listing => bids
    mapping(address => mapping(uint256 => uint256)) userAllowlistsBids;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IBase {
    error EndTimeBeforeStartTime();
    error CallerNotEoA();
    error InvalidSignature();
    error NoStockLeft();
    /**
        STOCK
    */
    error TotalStockLessThanSoldStock();
    error NotEnoughStock();
    /**
        USERS
    */
    error UserAlreadyExists();
    error CreateUserSignerZero();
    error AlreadyIsCreateUserSigner();
    error QueryNonExistentUser();
    error UserIsFrozen();
    /**
        ALLOWLISTS
    */
    error QueryNonExistentAllowlist();
    error MinBidGreaterThanPrice();
    /**
        RAFFLES
    */
    error QueryNonExistentRaffle();
    /**
        PROJECTS
    */
    error QueryNonExistentProject();
    error ProjectNotActive();
    error MaxPerWalletZero();
    error ProjectAlreadyInState();
    /**
        RBAC
    */
    error CallerNotAuthorized();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/// @notice Data Storage for User
/// wallet: address of the user
/// discordID: ID of the user on Discord
/// frozen: enable/disable user
struct UserStorage {
    address wallet;
    uint256 discordId;
    bool frozen;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct AllowlistStorage {
    uint256 stock;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 minBid;
    uint256 projectId;
    string  allowlistMetadataUrl;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

struct RaffleStorage {
    uint256 stock;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 maxWinners;
    uint256 projectId;
    string  raffleMetadataUrl;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

struct SpotStorage {
    uint256 total;
    uint256 purchased;
    address[] addresses;
    bool filled;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

// struct UserInventoryERC20Storage {
//     // user => contract => erc20 balance
//     mapping(address => mapping(address => uint256)) userERC20BalanceOfContract;
// }

// struct UserInventoryNFTStorage {
//     // user => contract => token ids
//     mapping(address => mapping(address => uint256[])) userNFTsOfContract;
// }

// struct UserInventoryRafflesTicketsStorage {
//     // user => raffle id => ticket balance
//     mapping(address => mapping(uint256 => uint256)) userRaffleTicketBalance;
// }

struct UserInventoryAllowlistStorage {
    mapping(uint256 => uint256) allowlists;
    mapping(uint256 => bool) hasSpotsInAllowlist;
    uint256[] projectIds;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

struct ListingStorage {
    uint256 totalStock;
    uint256 soldStock;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 minBid;
    uint256 projectId;
    bool paused;
}