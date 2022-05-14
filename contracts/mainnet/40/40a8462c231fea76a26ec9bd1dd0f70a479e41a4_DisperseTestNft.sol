/**
 *Submitted for verification at polygonscan.com on 2022-05-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


interface IERC721 {
    // function transfer(address to, uint256 value) external returns (bool);
    // function transferFrom(address from, address to, uint256 value) external returns (bool);
    // function balanceOf(address account) external view returns (uint256);
    // function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
}


contract DisperseTestNft {

    function disperseERC721(IERC721 nft, address[] memory recipients, uint256[][] memory tokenIds) external {
        require(recipients.length == tokenIds.length, "invalid array length");
        for (uint256 i = 0; i < recipients.length; i++) {
             for (uint256 j = 0; j < tokenIds[i].length; j++) {
                 require(nft.ownerOf(tokenIds[i][j]) == msg.sender, "NOT OWNER");
                 nft.safeTransferFrom(nft.ownerOf(tokenIds[i][j]), recipients[i], tokenIds[i][j]);
             }
        }

    }
}