/**
 *Submitted for verification at polygonscan.com on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

contract EmailList {
    uint256 public emailCount;
    mapping(uint256 => string) public emails;

    function addEmail(string calldata email) public {
        require(bytes(email).length > 0, "Email cannot be empty");

        bool valid = false;
        for (uint256 i = 0; i < bytes(email).length; i++) {
            if (bytes(email)[i] == 0x40) { // 0x40 - символ "@"
                valid = true;
                break;
            }
        }
        require(valid, "Invalid email format");

        emails[emailCount] = email;
        emailCount++;
    }
}