// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {Base} from "../base/Base.sol";
import {AllowlistStorage} from "../libraries/LibAllowlistStorage.sol";
import {IProjectFacet} from "../interfaces/IProjectFacet.sol";
import {IUserFacet} from "../interfaces/IUserFacet.sol";

contract AllowlistFacet is Base {

    modifier allowlistExists(uint256 id_) {
        if (id_ == 0 || id_ > s.allowlistsCount) revert QueryNonExistentAllowlist();
        _;
    }

    modifier hasStockAvailable(uint256 allowlistId_) {
        if (!allowlistHasStockById(allowlistId_)) revert NoStockLeft();
        _;
    }

    modifier projectIsActive(uint256 projectId) {
        if (!_projectFacet().isProjectActiveById(projectId))
            revert ProjectNotActive();
        _;
    }

    modifier purchasable(uint256 allowlistId_) {
        _purchasable(allowlistId_);
        _;
    } 

    function purchaseAllowlist(uint256 allowlistId_)
        external
        purchasable(allowlistId_)
    {
        s.allowlists[allowlistId_].stock--;
        s.userAllowlistsBalances[msg.sender][allowlistId_]++;
        s.userAllowlistsPurchased[msg.sender].push(allowlistId_);
    }

    function bid(uint256 allowlistId_)
        external
        purchasable(allowlistId_)
    {  // solhint-disable-line no-empty-blocks   
    }
   

    function createAllowlist(
        uint256 stock,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 minBid,
        uint256 projectId,
        string memory metadataUrl_
    ) external projectIsActive(projectId) {
        if (startTime > endTime) revert EndTimeBeforeStartTime();
        // TODO make this efficient and pretty
        if (price > 0 && price <= minBid) revert MinBidGreaterThanPrice();
        s.allowlistsCount += 1;
        s.allowlists[s.allowlistsCount].stock = stock;
        s.allowlists[s.allowlistsCount].price = price;
        s.allowlists[s.allowlistsCount].startTime = startTime;
        s.allowlists[s.allowlistsCount].endTime = endTime;
        s.allowlists[s.allowlistsCount].minBid = minBid;
        s.allowlists[s.allowlistsCount].projectId = projectId;
        s.allowlists[s.allowlistsCount].allowlistMetadataUrl = metadataUrl_;
    }

    function updateAllowlist(
        uint256 _allowlistId,
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minBid,
        uint256 _projectId,
        string memory metadataUrl_
    ) external allowlistExists(_allowlistId) {
        s.allowlists[_allowlistId].stock = _stock;
        s.allowlists[_allowlistId].price = _price;
        s.allowlists[_allowlistId].startTime = _startTime;
        s.allowlists[_allowlistId].endTime = _endTime;
        s.allowlists[_allowlistId].minBid = _minBid;
        s.allowlists[_allowlistId].projectId = _projectId;
        s.allowlists[_allowlistId].allowlistMetadataUrl = metadataUrl_;
    }

     function getPurchasesOfUser(address user_) external view returns (uint256[] memory) {
        if(_userFacet().isUserFrozen(user_)) {
            revert UserIsFrozen();
        }
        return s.userAllowlistsPurchased[user_];
    }

    function getAllAllowlists() external view returns (AllowlistStorage[] memory) {
        AllowlistStorage[] memory _allowlists = new AllowlistStorage[](
            s.allowlistsCount
        );
        for (uint256 i = 0; i < s.allowlistsCount; i++) {
            _allowlists[i] = s.allowlists[i + 1];
        }
        return _allowlists;
    }

     function getAllowlistById(uint256 id_)
        external
        view
        allowlistExists(id_)
        returns (AllowlistStorage memory)
    {
        return s.allowlists[id_];
    }

    function allowlistHasStockById(uint256 id_)
        public
        view
        allowlistExists(id_)
        returns (bool)
    {
        return s.allowlists[id_].stock > 0;
    }

    function _purchasable(uint256 allowlistId_)
        private
        view
        projectIsActive(s.allowlists[allowlistId_].projectId)
        allowlistExists(allowlistId_)
        hasStockAvailable(allowlistId_)
    {
        if(_userFacet().isUserFrozen(msg.sender)) revert UserIsFrozen();
    }

    function _projectFacet()
        private
        view
        returns (IProjectFacet projectFacet)
    {
        projectFacet = IProjectFacet(address(this));
    }

    function _userFacet() private view returns (IUserFacet userFacet) {
        userFacet = IUserFacet(address(this));
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

struct AllowlistStorage {
    uint256 stock;
    uint256 price;
    uint256 startTime;
    uint256 endTime;
    uint256 minBid;
    uint256 projectId;
    string  allowlistMetadataUrl;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ProjectStorage} from "../libraries/LibProjectStorage.sol";

interface IProjectFacet {
    function getProjectById(uint256 id_)
        external
        view
        returns (ProjectStorage memory);

    function isProjectActiveById(uint256 id_) external view returns (bool);

    function createProject(
        uint256 previousProjectId_,
        uint256 maxPerWallet_,
        bool active_
    ) external;

    function updateProject(
        uint256 id_,
        uint256 previousProjectId_,
        uint256 maxPerWallet_,
        bool active_
    ) external;

    function getAllProjects() external view returns (ProjectStorage[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {UserStorage} from "../libraries/LibUserStorage.sol";

interface IUserFacet {
    function getUserByAddress(address address_)
        external
        view
        returns (UserStorage memory);

    function createUser(uint256 discordId_, bytes memory signature_) external;

    function updateUser(
        address wallet_,
        uint256 discordId_,
        bool frozen_
    ) external;

    function isUserFrozen(address wallet_) external view returns (bool);

    function setCreateUserSigner(address signer_) external;
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

struct ProjectStorage {
    uint256 previousProjectId;
    uint256 maxPerWallet;
    bool active;
    bool initialized;
    string metadataUrl;
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