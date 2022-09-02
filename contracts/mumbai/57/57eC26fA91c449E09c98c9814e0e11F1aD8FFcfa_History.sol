/**
 *Submitted for verification at polygonscan.com on 2022-09-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract History {
    event DataAdded(
        address indexed userAddress,
        uint256 indexed tokenId,
        string data
    );
    mapping(uint256 => string) public tokenIdToData;

    function addData(
        address userAddress,
        uint256 eventTokenId,
        string memory data
    ) public {
        tokenIdToData[eventTokenId] = data;
        emit DataAdded(userAddress, eventTokenId, data);
    }
}