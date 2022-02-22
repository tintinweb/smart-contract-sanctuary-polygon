// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./interfaces/ITangibleProfile.sol";

contract TangibleProfile is ITangibleProfile {
    mapping(address => Profile) public userProfiles;

    function update(Profile memory profile) external override {
        address owner = msg.sender;
        userProfiles[owner] = profile;
    }

    function remove() external override {
        delete userProfiles[msg.sender];
    }

    function nameOf(address owner)
        external
        view
        override
        returns (string memory)
    {
        return userProfiles[owner].userName;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

interface ITangibleProfile {
    struct Profile {
        string userName;
        string imageURL;
    }

    event ProfileUpdated(Profile oldProfile, Profile newProfile);

    /// @dev The function updates the user profile.
    function update(Profile memory profile) external;

    /// @dev The function removes the user profile.
    function remove() external;

    /// @dev The function returns name of user.
    function nameOf(address owner) external view returns (string memory);
}