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

    function namesOf(address[] calldata owners)
        external
        view
        override
        returns (string[] memory names)
    {
        uint256 length = owners.length;
        names = new string[](length);
        for (uint256 i = 0; i < length; i++) {
            names[i] = userProfiles[owners[i]].userName;
        }
        return names;
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

    /// @dev The function returns name(s) of user(s).
    function namesOf(address[] calldata owners)
        external
        view
        returns (string[] memory);
}