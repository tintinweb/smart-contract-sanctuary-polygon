// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {Listing} from "../base/Listing.sol";
import {RaffleStorage} from "../libraries/LibRaffleStorage.sol";
import {IProjectFacet} from "../interfaces/IProjectFacet.sol";

contract RaffleFacet is Listing {

    function _projectFacet() private view returns (IProjectFacet projectFacet) {
        projectFacet = IProjectFacet(address(this));
    }

    function purchaseRaffle(uint256 raffleId_) external {

    }

    function getRaffleById(uint256 id_)
        external
        view
        raffleExists(id_)
        returns (
            RaffleStorage memory
        )
    {
        // require project id to exist
        return s.raffles[id_];
    }

    function createRaffle(
        uint256 stock,
        uint256 price,
        uint256 startTime,
        uint256 endTime,
        uint256 projectId,
        string memory metadataUrl_
    ) external {
        if(startTime > endTime) revert EndTimeBeforeStartTime();
        if(!_projectFacet().isProjectActiveById(projectId)) revert ProjectNotActive(); // TODO make this efficient and pretty
        s.rafflesCount += 1;
        s.raffles[s.rafflesCount].stock = stock;
        s.raffles[s.rafflesCount].price = price;
        s.raffles[s.rafflesCount].startTime = startTime;
        s.raffles[s.rafflesCount].endTime = endTime;
        s.raffles[s.rafflesCount].projectId = projectId;
        s.raffles[s.rafflesCount].raffleMetadataUrl = metadataUrl_;
    }

    function updateRaffle(
        uint256 _raffleId,
        uint256 _stock,
        uint256 _price,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _projectId,
        string memory metadataUrl_
    ) external raffleExists(_raffleId) {
        s.raffles[_raffleId].stock = _stock;
        s.raffles[_raffleId].price = _price;
        s.raffles[_raffleId].startTime = _startTime;
        s.raffles[_raffleId].endTime = _endTime;
        s.raffles[_raffleId].projectId = _projectId;
        s.raffles[_raffleId].raffleMetadataUrl = metadataUrl_;
    }

    function getAllRaffles() external view returns (RaffleStorage[] memory _raffles) {
        _raffles = new RaffleStorage[](
            s.rafflesCount
        );
        for (uint256 i = 0; i < s.rafflesCount; i++) {
            _raffles[i] = s.raffles[i+1];
        }
    }

    function raffleHasStockById(uint256 id_)
        public
        view
        raffleExists(id_)
        returns (bool)
    {
        return s.raffles[id_].stock > 0;
    }

    modifier raffleExists(uint256 id_) {
        if(id_ == 0 || id_ > s.rafflesCount) revert QueryNonExistentRaffle();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {Base} from "./Base.sol";
import {ListingStorage} from "../libraries/LibListingStorage.sol";

abstract contract Listing is Base {

    function _create() internal virtual {}
    function _read(uint256 id) internal virtual returns (ListingStorage memory) {
        return s.listings[id];
    }
    function _update(ListingStorage memory listing) internal virtual {}
    function _destroy(ListingStorage memory listing) internal virtual {}
    function _purchase(ListingStorage memory listing, uint256 amount) internal virtual {
        if(amount > _getCurrentStock(listing)) revert NotEnoughStock();
        _increaseSold(listing, amount);
    }
    function _pause(ListingStorage storage listing) internal virtual {
        listing.paused = true;
    }
    function _unpause(ListingStorage storage listing) internal virtual {
        listing.paused = false;
    }
    function _archive(ListingStorage memory listing) internal virtual {
        // ?
    }
    function _bid(ListingStorage memory listing) internal virtual {}
    // stock
    function _getTotalStock(ListingStorage memory listing) internal view virtual returns (uint256) {
        return listing.totalStock;
    }
    function _setTotalStock(ListingStorage memory listing, uint256 _totalStock) internal virtual {
        if(_totalStock < listing.soldStock) revert TotalStockLessThanSoldStock();
    }
    function _getSoldStock(ListingStorage memory listing) internal virtual returns (uint256) {
        return listing.soldStock;
    }
    function _getCurrentStock(ListingStorage memory listing) internal virtual returns (uint256) {
        return listing.totalStock - listing.soldStock;
    }
    function _increaseSold(ListingStorage memory listing, uint256 _quantity) internal virtual {
        if(_quantity + _getCurrentStock(listing) >= listing.totalStock) {
            _archive(listing);
        }
    }
    // price
    function _getPricePerUnit(ListingStorage memory listing) internal virtual {

    }
    function _getMinimumBid(ListingStorage memory listing) internal virtual {}
    // info
    function _getBidEnabled(ListingStorage memory listing) internal virtual {}
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