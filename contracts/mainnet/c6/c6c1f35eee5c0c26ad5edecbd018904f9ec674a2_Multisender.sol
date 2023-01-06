/**
 *Submitted for verification at polygonscan.com on 2023-01-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract Multisender {
    constructor () {}
    
    function multisend(address collection, address[] memory recipients, uint[] memory tokenIds) public {
        require(recipients.length == tokenIds.length, "INCORRECT_ARRAYS_LENGTH");
        for (uint i; i<tokenIds.length; i++) {
            IERC721(collection).safeTransferFrom(msg.sender, recipients[i], tokenIds[i]);
        }
    }
}