// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IAmpliFrensProfile} from "./interfaces/IAmpliFrensProfile.sol";
import {DataTypes} from "./libraries/types/DataTypes.sol";
import {ProfileLogic} from "./libraries/logic/ProfileLogic.sol";
import {PseudoModifier} from "./libraries/guards/PseudoModifier.sol";

/**
 * @title AmpliFrensProfile
 * @author Lucien Akchoté
 *
 * @notice Handles profile operations for AmpliFrens
 * @custom:security-contact [email protected]
 */
contract AmpliFrensProfile is IERC165, IAmpliFrensProfile {
    using Counters for Counters.Counter;

    mapping(address => DataTypes.Profile) private _profiles;
    mapping(bytes32 => address) private _usernames;
    mapping(address => bytes32) private _blacklistedAddresses;

    Counters.Counter public profilesCount;

    address public immutable facadeProxy;

    /// @dev Contract initialization with facade's proxy address precomputed
    constructor(address _facadeProxy) {
        facadeProxy = _facadeProxy;
    }

    /// @inheritdoc IAmpliFrensProfile
    function blacklist(address _address, bytes32 reason) external {
        PseudoModifier.addressEq(facadeProxy, msg.sender);
        ProfileLogic.blackList(_address, reason, _blacklistedAddresses, _profiles, profilesCount);
    }

    /// @inheritdoc IAmpliFrensProfile
    function createProfile(DataTypes.Profile calldata profile) external {
        ProfileLogic.createProfile(profile, _profiles, _usernames, profilesCount);
    }

    /// @inheritdoc IAmpliFrensProfile
    function deleteProfile(address _address) external {
        ProfileLogic.deleteProfile(_address, _profiles, profilesCount);
    }

    /// @inheritdoc IAmpliFrensProfile
    function updateProfile(DataTypes.Profile calldata profile) external {
        ProfileLogic.updateProfile(profile, _profiles, _usernames);
    }

    /// @inheritdoc IAmpliFrensProfile
    function getBlacklistReason(address _address) external view returns (bytes32 reason) {
        reason = ProfileLogic.getBlacklistReason(_address, _blacklistedAddresses);
    }

    /// @inheritdoc IAmpliFrensProfile
    function getProfile(address _address) external view returns (DataTypes.Profile memory profile) {
        profile = ProfileLogic.getProfile(_address, _profiles);
    }

    /// @inheritdoc IAmpliFrensProfile
    function getProfileByUsername(bytes32 username) external view returns (DataTypes.Profile memory profile) {
        profile = ProfileLogic.getProfileByUsername(username, _usernames, _profiles);
    }

    /// @inheritdoc IAmpliFrensProfile
    function hasProfile(address _address) external view returns (bool) {
        return _profiles[_address].valid;
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) external pure override(IERC165) returns (bool) {
        return type(IAmpliFrensProfile).interfaceId == interfaceId || type(IERC165).interfaceId == interfaceId;
    }
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
library Counters {
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {DataTypes} from "../libraries/types/DataTypes.sol";

/**
 * @title IAmpliFrensProfile
 * @author Lucien Akchoté
 *
 * @notice Handles the common use cases for interacting with profiles
 */
interface IAmpliFrensProfile {
    /**
     * @notice Event that is emitted when a profile is blacklisted
     *
     * @param _address The profile's address blacklisted
     * @param reason   The reason of the blacklist
     * @param timestamp The time when blacklisting occured
     */
    event ProfileBlacklisted(address indexed _address, bytes32 indexed reason, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is created
     *
     * @param _address The profile's address created
     * @param timestamp The time when profile creation occurred
     */
    event ProfileCreated(address indexed _address, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is updated
     *
     * @param _address The profile's address updated
     * @param timestamp The time when profile update occurred
     */
    event ProfileUpdated(address indexed _address, uint256 timestamp);

    /**
     * @notice Event that is emitted when a profile is deleted
     *
     * @param _address The profile's address deleted
     */
    event ProfileDeleted(address indexed _address, uint256 timestamp);

    /**
     * @notice Create a profile for address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function createProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Update a profile for address `msg.sender`
     *
     * @param profile `DataTypes.Profile` containing the profile data
     */
    function updateProfile(DataTypes.Profile calldata profile) external;

    /**
     * @notice Delete the profile of address `_address`
     *
     * @param _address The address's profile to delete
     */
    function deleteProfile(address _address) external;

    /**
     * @notice Get a profile if applicable for address `_address`
     *
     * @return `DataTypes.Profile` data
     */
    function getProfile(address _address) external view returns (DataTypes.Profile memory);

    /**
     * @notice Blacklist a profile with address `_address` for reason `reason`
     *
     * @param _address The profile's address to blacklist
     * @param reason The reason of the blacklist
     */
    function blacklist(address _address, bytes32 reason) external;

    /**
     * @notice Get the blacklist reason for address `_address`
     *
     * @param _address The profile's address to query
     * @return The reason of the blacklist
     */
    function getBlacklistReason(address _address) external view returns (bytes32);

    /**
     * @notice Get a profile by its username `username`
     *
     * @return `DataTypes.Profile` containing the profile data
     */
    function getProfileByUsername(bytes32 username) external view returns (DataTypes.Profile memory);

    /**
     * @notice Check if address `_address` has a profile
     *
     * @return True or false
     */
    function hasProfile(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title DataTypes
 * @author Lucien Akchoté
 *
 * @notice A standard library of data types used throughout AmpliFrens
 */
library DataTypes {
    /// @notice Contain the different statuses depending on tokens earnt
    enum FrenStatus {
        Anon,
        Degen,
        Pepe,
        Contributoor,
        Aggregatoor,
        Oracle
    }

    /// @notice Contain the different contributions categories
    enum ContributionCategory {
        NFT,
        Article,
        DeFi,
        Security,
        Thread,
        GameFi,
        Video,
        Misc
    }

    /**
     *  @notice Contain the basic information of a contribution
     *
     *  @dev Use tight packing to save up on storage cost
     *  4 storage slots used (string takes up 64 bytes or 2 slots in the storage)
     */
    struct Contribution {
        address author; /// @dev 20 bytes
        ContributionCategory category; /// @dev 1 byte
        bool valid; /// @dev 1 byte
        uint64 timestamp; /// @dev 8 bytes
        int16 votes; /// @dev 2 bytes
        bytes32 title; /// @dev 32 bytes
        string url; /// @dev 64 bytes
    }

    /// @notice Contain the basic information of a profile
    struct Profile {
        bytes32 lensHandle;
        bytes32 discordHandle;
        bytes32 twitterHandle;
        bytes32 username;
        bytes32 email;
        string websiteUrl;
        bool valid;
    }

    /// @notice These time-related variables are used in conjunction to determine when minting function can be called
    struct MintingInterval {
        uint256 lastBlockTimestamp;
        uint256 mintInterval;
    }

    /// @notice Contain contributions data
    struct Contributions {
        mapping(uint256 => DataTypes.Contribution) contribution;
        mapping(uint256 => mapping(address => bool)) upvoted;
        mapping(uint256 => mapping(address => bool)) downvoted;
        address[] upvoterAddresses;
        address[] downvoterAddresses;
        uint256[] upvotedIds;
        uint256[] downvotedIds;
        address adminAddress;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title ProfileLogic
 * @author Lucien Akchoté
 *
 * @notice A library that implements the logic of profile related functions
 */
library ProfileLogic {
    using Counters for Counters.Counter;

    /// @dev See `IAmpliFrensProfile` for descriptions
    event ProfileBlacklisted(address indexed _address, bytes32 indexed reason, uint256 timestamp);
    event ProfileCreated(address indexed _address, uint256 timestamp);
    event ProfileUpdated(address indexed _address, uint256 timestamp);
    event ProfileDeleted(address indexed _address, uint256 timestamp);

    modifier hasProfile(address _address, mapping(address => DataTypes.Profile) storage _profiles) {
        if (!_profiles[_address].valid) revert Errors.NoProfileWithAddress();
        _;
    }

    modifier hasHandleExistence(mapping(bytes32 => address) storage _handlesMap, bytes32 handle) {
        if (_handlesMap[handle] == address(0)) revert Errors.NoProfileWithSocialHandle();
        _;
    }

    /**
     * @notice Blacklist a profile with address `_address` for reason `reason`
     *
     * @param _address The profile's address to blacklist
     * @param reason The reason of the blacklist
     * @param _blacklistedAddresses The addresses of all blacklisted addresses
     * @param _profiles The current profiles list
     * @param profilesCount The total counter of all profiles
     */
    function blackList(
        address _address,
        bytes32 reason,
        mapping(address => bytes32) storage _blacklistedAddresses,
        mapping(address => DataTypes.Profile) storage _profiles,
        Counters.Counter storage profilesCount
    ) external hasProfile(_address, _profiles) {
        _blacklistedAddresses[_address] = reason;
        profilesCount.decrement();

        delete (_profiles[_address]);
        emit ProfileBlacklisted(_address, reason, block.timestamp);
    }

    /**
     * @notice Create a profile for address `msg.sender`
     *
     * @param profile The profile data
     * @param _profiles The current profiles list
     * @param _usernames The current usernames list
     */
    function createProfile(
        DataTypes.Profile calldata profile,
        mapping(address => DataTypes.Profile) storage _profiles,
        mapping(bytes32 => address) storage _usernames,
        Counters.Counter storage profilesCount
    ) external {
        if (bytes1(profile.username) == 0x00) revert Errors.EmptyUsername();
        if (_usernames[profile.username] != address(0)) revert Errors.UsernameExist();

        _profiles[msg.sender] = DataTypes.Profile(
            profile.lensHandle,
            profile.discordHandle,
            profile.twitterHandle,
            profile.username,
            profile.email,
            profile.websiteUrl,
            true
        );

        _usernames[profile.username] = msg.sender;

        profilesCount.increment();

        emit ProfileCreated(msg.sender, block.timestamp);
    }

    /**
     * @notice Delete the profile of address `_address`
     *
     * @param _address The profile's address to create
     * @param _profiles The current profiles list
     * @param profilesCount The total counter of all profiles
     */
    function deleteProfile(
        address _address,
        mapping(address => DataTypes.Profile) storage _profiles,
        Counters.Counter storage profilesCount
    ) external hasProfile(_address, _profiles) {
        profilesCount.decrement();

        delete (_profiles[_address]);

        emit ProfileDeleted(_address, block.timestamp);
    }

    /**
     * @notice Update the profile for address `_address`
     *
     * @param profile The profile data
     * @param _profiles The current profiles list
     * @param _usernames The current usernames list
     */
    function updateProfile(
        DataTypes.Profile calldata profile,
        mapping(address => DataTypes.Profile) storage _profiles,
        mapping(bytes32 => address) storage _usernames
    ) external hasProfile(msg.sender, _profiles) {
        if (bytes1(profile.username) != 0x00) {
            delete (_usernames[_profiles[msg.sender].username]);
            _usernames[profile.username] = msg.sender;
            _profiles[msg.sender].username = profile.username;
        }

        _profiles[msg.sender].email = profile.email;
        _profiles[msg.sender].lensHandle = profile.lensHandle;
        _profiles[msg.sender].discordHandle = profile.discordHandle;
        _profiles[msg.sender].twitterHandle = profile.twitterHandle;
        _profiles[msg.sender].websiteUrl = profile.websiteUrl;

        emit ProfileUpdated(msg.sender, block.timestamp);
    }

    /**
     * @notice Get the blacklist reason for address `_address`
     *
     * @param _address The profile's address to query
     * @param _blacklistedAddresses The addresses of all blacklisted addresses
     * @return The blacklist reason
     */
    function getBlacklistReason(address _address, mapping(address => bytes32) storage _blacklistedAddresses)
        external
        view
        returns (bytes32)
    {
        if (bytes1(_blacklistedAddresses[_address]) == 0x00) revert Errors.NotBlacklisted();
        return _blacklistedAddresses[_address];
    }

    /**
     * @notice Get the profile of address `_address`
     *
     * @param _address The profile's address to create
     * @param _profiles The current profiles list
     */
    function getProfile(address _address, mapping(address => DataTypes.Profile) storage _profiles)
        external
        view
        hasProfile(_address, _profiles)
        returns (DataTypes.Profile memory)
    {
        return _profiles[_address];
    }

    /**
     * @notice Get a profile by its username `username`
     *
     * @param username The username to query
     * @param _usernames The usernames list
     * @param _profiles The profiles list
     * @return `DataTypes.Profile` containing the profile data
     */
    function getProfileByUsername(
        bytes32 username,
        mapping(bytes32 => address) storage _usernames,
        mapping(address => DataTypes.Profile) storage _profiles
    ) external view hasHandleExistence(_usernames, username) returns (DataTypes.Profile memory) {
        return _profiles[_usernames[username]];
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import {Errors} from "../helpers/Errors.sol";

/**
 * @title PseudoModifier
 * @author Lucien Akchoté
 *
 * @notice Implements the (currently) unsupported functionality of using modifiers in libraries
 * @dev see https://github.com/ethereum/solidity/issues/12807
 */
library PseudoModifier {
    using Counters for Counters.Counter;

    /**
     * @notice Check address `expected` is equal to address `actual`
     *
     * @param expected The expected address
     * @param actual The actual address
     */
    function addressEq(address expected, address actual) external pure {
        if (expected != actual) revert Errors.Unauthorized();
    }

    /**
     * @dev Check if the index requested exist in counter
     *
     * @param index The id to verify existence for
     * @param counter The counter that holds enumeration
     */
    function isNotOutOfBounds(uint256 index, Counters.Counter storage counter) external view {
        if (index > counter.current() || index == 0) revert Errors.OutOfBounds();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Errors
 * @author Lucien Akchoté
 *
 * @notice Regroup all the different errors used throughout AmpliFrens
 * @dev Use custom errors to save gas
 */
library Errors {
    /// @dev Generic errors
    error Unauthorized();
    error OutOfBounds();
    error NotImplemented();
    error AddressNull();

    /// @dev Profile errors
    error NoProfileWithAddress();
    error NoProfileWithSocialHandle();
    error EmptyUsername();
    error UsernameExist();
    error NotBlacklisted();

    /// @dev Contribution errors
    error AlreadyVoted();
    error NotAuthorOrAdmin();
    error NotAuthor();

    /// @dev NFT errors
    error MaxSupplyReached();
    error AlreadyOwnNft();

    /// @dev SBT errors
    error MintingIntervalNotMet();
}