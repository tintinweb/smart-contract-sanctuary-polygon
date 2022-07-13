/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract CollectionChatRoom {

    event Comment(
        address indexed userAddr, 
        address indexed collectionAddress,
        uint256 userBalance, 
        string text, 
        uint256 indexed typeInt
    );

    function comment(
        address collectionAddress,
        string memory text,
        uint256 typeInt
    ) internal {

        (bool success, bytes memory data) = collectionAddress.staticcall(abi.encodeWithSignature("balanceOf(address)", msg.sender));
        uint256 userBalance = abi.decode(data, (uint));
        require(success && userBalance > 0);

        emit Comment(
            msg.sender, 
            collectionAddress,
            userBalance, 
            text, 
            typeInt
        );
    }
}