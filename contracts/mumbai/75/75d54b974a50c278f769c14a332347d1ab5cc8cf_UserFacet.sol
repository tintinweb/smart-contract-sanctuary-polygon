// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

import {Base} from "../base/Base.sol";
import {UserStorage} from "../libraries/LibUserStorage.sol";
import {ISignatureFacet} from "../interfaces/ISignatureFacet.sol";

/// @title User Management Module
/// @author Kfish n Chips
/// @notice Create, Update and Frozen a User
/// @dev Use signature to create a user
/// @custom:security-contact [email protected]
contract UserFacet is Base {

    /// @notice Check that _address exits as user
    /// @dev is NOT a user revert QueryNonExistentUser()
    /// @param _address to check that is a user
    modifier userExists(address _address) {
        if(s.users[_address].wallet == address(0)) revert QueryNonExistentUser();
        _;
    }

    /// @notice Check that discordId_ is from msg.sender
    /// @dev revert InvalidSignature() on an invalid signature_
    /// @param discordId_ the ID on Discord of msg.sender
    /// @param signature_ a signature of (msg.sender, discordId_)
    modifier isValidSignature(uint256 discordId_, bytes memory signature_) {
        ISignatureFacet(address(this)).isValidSignature(
            s.createUserSigner,
            bytes32(abi.encodePacked(msg.sender, discordId_)),
            signature_
        );
        _;
    }
    

    function createUser(uint256 discordId_, bytes memory signature_)
        external
        onlyEoA()
        isValidSignature(discordId_, signature_)
    {
        if (s.users[msg.sender].wallet == msg.sender)
            revert UserAlreadyExists();
        s.users[msg.sender].wallet = msg.sender;
        s.users[msg.sender].discordId = discordId_;
        s.usersCount += 1;
    }

    function setCreateUserSigner(address signer_) external {
        if(signer_ == address(0)) revert CreateUserSignerZero();
        if(signer_ == s.createUserSigner) revert AlreadyIsCreateUserSigner();
        s.createUserSigner = signer_;
    }

    function updateUser(
        address wallet_,
        uint256 discordId_,
        bool frozen_
    ) external userExists(wallet_) {
        s.users[wallet_].discordId = discordId_;
        s.users[wallet_].frozen = frozen_;
    }

    function getUserByAddress(address address_)
        external
        view
        userExists(address_)
        returns (UserStorage memory)
    {
        return s.users[address_];
    }

    function isUserFrozen(address wallet_)
        public
        view
        userExists(wallet_)
        returns (bool)
    {
        return s.users[wallet_].frozen;
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

interface ISignatureFacet {
    function isValidSignature(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) external view;
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