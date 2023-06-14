/**
 *Submitted for verification at polygonscan.com on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract ProfileNFT {
    /// Platform owner
    address private _deployer;

    /// count for profile ID
    uint256 private _profileIds;

    /**
     * @dev Emitted when profile is minted
     */
    event ProfileMint(
        uint256 indexed profileId_,
        string indexed user_,
        string indexed uri_
    );

    /**
     * @dev Emitted when profile is updated
     */

    event ProfileUpdated(uint256 profileId_, string newURI_);

    /// Mapping from profile ID to owners
    mapping(uint256 => string) private _profileOwners;

    /// Mapping from profile holders to balance
    mapping(string => uint256) private _totalBalances;

    /// Mapping from profile ID to metaData URI
    mapping(uint256 => string) private _profileURIs;

    modifier onlyDeployer() {
        require(msg.sender == _deployer, "onlyDeployer: Unauthorized access");
        _;
    }

    constructor() {
        _deployer = msg.sender;
    }

    /**
     * @dev Mints new user profile
     * @param user_ Profile owner
     * @param uri_ Metadata URI
     */
    function createProfile(
        string calldata user_,
        string calldata uri_
    ) external onlyDeployer {
        require(
            bytes(user_).length > 0 && bytes(uri_).length > 0,
            "createProfile: Invalid input"
        );

        require(
            _totalBalances[user_] == 0,
            "createProfile: User already exist"
        );

        uint256 profileId = _profileIds;

        _profileOwners[profileId] = user_;

        _profileURIs[profileId] = uri_;

        _totalBalances[user_]++;

        _profileIds++;

        emit ProfileMint(profileId, user_, uri_);
    }

    function updateProfile(
        uint256 profileId_,
        string calldata newURI_
    ) external onlyDeployer {
        require(
            bytes(_profileURIs[profileId_]).length != 0,
            "updateProfile: Profile does not exist"
        );

        require(bytes(newURI_).length > 0, "updateProfile: Invalid input");

        _profileURIs[profileId_] = newURI_;

        emit ProfileUpdated(profileId_, newURI_);
    }

    /**
     * @dev Returns the uri of the profile
     * @param profileId_ user's profile ID
     */
    function getProfileURI(
        uint256 profileId_
    ) external view returns (string memory) {
        return _profileURIs[profileId_];
    }

    /**
     * @dev Returns the owner of the profile
     * @param profileId_ user's profile ID
     */
    function getProfileOwner(
        uint256 profileId_
    ) external view returns (string memory) {
        return _profileOwners[profileId_];
    }
}