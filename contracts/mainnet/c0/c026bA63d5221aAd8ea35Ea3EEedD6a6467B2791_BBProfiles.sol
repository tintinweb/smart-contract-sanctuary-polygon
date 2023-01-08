// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./BBErrorsV01.sol";
import "./interfaces/IBBProfiles.sol";

contract BBProfiles is IBBProfiles {
    event NewProfile(
        uint256 profileId,
        address owner,
        address receiver,
        string cid
    );

    event EditProfile(
        uint256 profileId,
        address owner,
        address receiver,
        string cid
    );

    struct Profile {
        address owner;
        address receiver;
        string cid;
    }

    // Profile ID => Profile
    mapping(uint256 => Profile) internal _profiles;

    uint256 internal _totalProfiles;

    // Owner => Index => Profile ID
    mapping(address => mapping(uint256 => uint256)) private _ownedProfiles;
    // Owner => Profile ID => Index
    mapping(address => mapping(uint256 => uint256)) private _ownedProfilesIndexes;
    // Owner => Total profiles owned
    mapping(address => uint256) private _ownersTotalProfiles;

    constructor() {

    }

    /*
        @dev Reverts if msg.sender is not profile IDs owner

        @param Profile ID
    */
    modifier onlyProfileOwner(uint256 profileId) {
        require(_profiles[profileId].owner == msg.sender, BBErrorCodesV01.NOT_OWNER);
        _;
    }

    /*
        @dev Reverts if profile ID does not exist

        @param Profile ID
    */
    modifier profileExists(uint256 profileId) {
      require(profileId < _totalProfiles, BBErrorCodesV01.PROFILE_NOT_EXIST);
      _;
    }

    /*
        @notice Creates a new profile

        @param Profile owner
        @param Profiles revenue receiver
        @param Profile CID

        @return Instantiated profiles ID
    */
    function createProfile(address owner, address receiver, string calldata cid) external override returns(uint256 profileId) {
        profileId = _totalProfiles;
        
        // Instantiate profile
        _profiles[profileId] = Profile(owner, receiver, cid);

        // Add profile ID to owners list of owned profiles
        _ownedProfiles[owner][_ownersTotalProfiles[owner]] = profileId;
        _ownedProfilesIndexes[owner][profileId] = _ownersTotalProfiles[owner];
        _ownersTotalProfiles[owner]++;

        // Increment total profiles
        _totalProfiles++;

        emit NewProfile(profileId, owner, receiver, cid);
    }

    /*
        @notice Set an existing profiles variables

        @param Profile ID
        @param Profile owner
        @param Profile revenue receiver
        @param Profile CID
    */
    function editProfile(uint256 profileId, address owner, address receiver, string calldata cid) external override profileExists(profileId) onlyProfileOwner(profileId) {       
        if (msg.sender != owner) {
            // Remove ID from previous owners list of owned profiles
            _ownedProfiles[msg.sender][_ownedProfilesIndexes[msg.sender][profileId]] = _ownedProfiles[msg.sender][_ownersTotalProfiles[msg.sender] - 1];
            _ownedProfiles[msg.sender][_ownersTotalProfiles[msg.sender] - 1] = 0;
            _ownedProfilesIndexes[msg.sender][profileId] = 0;
            _ownersTotalProfiles[msg.sender]--;

            // Add ID to new owners list of owned profiles
            _ownedProfiles[owner][_ownersTotalProfiles[owner]] = profileId;
            _ownedProfilesIndexes[owner][profileId] = _ownersTotalProfiles[owner];
            _ownersTotalProfiles[owner]++;
        }
        
        // Set profile variables
        _profiles[profileId] = Profile(owner, receiver, cid);

        emit EditProfile(profileId, owner, _profiles[profileId].receiver, cid);
    } 

    /*
        @notice Returns the total number of created profiles

        @return Total number of profiles
    */
    function totalProfiles() view external override returns (uint256) {
        return _totalProfiles;
    }

    /*
        @notice Returns a profiles variables

        @param Profile ID

        @return Profile owner
        @return Profile revenue receiver
        @return Profile CID
    */
    function getProfile(uint256 profileId) view external override profileExists(profileId) returns (address, address, string memory) {
        return (_profiles[profileId].owner, _profiles[profileId].receiver, _profiles[profileId].cid);
    }

    /*
        @notice Get a list of all profile IDs owned by an address

        @param Profile owner

        @return Array of profile IDs owned by an address
    */
    function getOwnersProfiles(address owner) external view override returns (uint256[] memory) {
        uint256[] memory profileIds = new uint256[](_ownersTotalProfiles[owner]);

        for(uint256 i; i < _ownersTotalProfiles[owner]; i++) {
            profileIds[i] = _ownedProfiles[owner][i];
        }

        return profileIds;
    }

    /*
        @notice Returns the total number of profiles an address owns

        @param Profile owner

        @return Profile count
    */
    function ownersTotalProfiles(address owner) view external returns (uint256) {
        return _ownersTotalProfiles[owner];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBBProfiles {
    function createProfile(address owner, address receiver, string calldata cid) external returns(uint256 profileId);
    function editProfile(uint256 profileId, address owner, address receiver, string calldata cid) external; 

    function totalProfiles() external view returns (uint256 total);
    function getProfile(uint256 profileId) external view returns (address owner, address receiver, string memory cid);

    function getOwnersProfiles(address account) external view returns (uint256[] memory profileIds);
    function ownersTotalProfiles(address owner) external view returns (uint256 total);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BBErrorCodesV01 {
    string public constant NOT_OWNER = "1";
    string public constant OUT_OF_BOUNDS = "2";
    string public constant NOT_SUBSCRIPTION_OWNER = "3";
    string public constant POST_NOT_EXIST = "4";
    string public constant PROFILE_NOT_EXIST = "5";
    string public constant TIER_SET_NOT_EXIST = "6";
    string public constant TIER_NOT_EXIST = "7";
    string public constant SUBSCRIPTION_NOT_EXIST = "8";
    string public constant ZERO_ADDRESS = "9";
    string public constant SUBSCRIPTION_NOT_EXPIRED = "10";
    string public constant SUBSCRIPTION_CANCELLED = "11";
    string public constant UPKEEP_FAIL = "12";
    string public constant INSUFFICIENT_PREPAID_GAS = "13";
    string public constant INSUFFICIENT_ALLOWANCE = "14";
    string public constant INSUFFICIENT_BALANCE = "15";
    string public constant SUBSCRIPTION_ACTIVE = "16";
    string public constant INVALID_LENGTH = "17";
    string public constant UNSUPPORTED_CURRENCY = "18";
    string public constant SUBSCRIPTION_PROFILE_ALREADY_EXISTS = "19";
    string public constant INVALID_PRICE = "20";
}