//SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

library Checks {
    uint256 constant MAX_HANDLE_LENGTH = 15;

    // checks handle for dislallowe characters
    function checkHandleValidity(string memory userName) public pure {
        bytes memory byteUserName = bytes(userName);
        if (byteUserName.length == 0 || byteUserName.length > MAX_HANDLE_LENGTH)
            revert("Max Handle Length Exceeded");

        uint256 byteHandleLength = byteUserName.length;
        for (uint256 i = 0; i < byteHandleLength; ) {
            if (
                (byteUserName[i] < "0" ||
                    byteUserName[i] > "z" ||
                    (byteUserName[i] > "9" && byteUserName[i] < "a")) ||
                byteUserName[i] == "." ||
                byteUserName[i] == "-" ||
                byteUserName[i] == "_"
            ) revert("Invalid Characters Used");

            unchecked {
                ++i;
            }
        }

        if (
            keccak256(abi.encodePacked(userName)) ==
            keccak256(abi.encodePacked("nousername"))
        ) {
            revert("Cant Use Default Username");
        }
    }

    // checks if username has been taken or address already has a username
    function checkUserNameAndAddressExistence(
        string calldata _userName,
        mapping(string => bool) storage _userNameExistence,
        mapping(address => bool) storage _addressExistence
    ) public view {
        if (_userNameExistence[_userName] || _addressExistence[msg.sender]) {
            revert("Username Taken Or Address Already Registered");
        }
    }
}