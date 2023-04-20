// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OurBlockchain {
    mapping(uint256 => string) idToUserData;

    function setDataToId(uint256 id, string memory userData) public {
        idToUserData[id] = userData;
    }
}