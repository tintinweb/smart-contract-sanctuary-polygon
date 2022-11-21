/**
 *Submitted for verification at polygonscan.com on 2022-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract KMKNftStakingBase {
    event NftStaked(address indexed owner, uint256 indexed collectionId, uint256 tokenId, uint256 timestamp, string extraData);
    event NftUnstaked(address indexed owner, uint256 indexed collectionId, uint256 tokenId, uint256 timestamp, string extraData);

    constructor() {}

    function stake(
        uint256[] calldata collectionIds,
        uint256[] calldata tokenIds,
        string[] calldata extraData
    )
        public
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 collectionId = collectionIds[i];
            uint256 tokenId = tokenIds[i];
            string memory extra = extraData[i];
            emit NftStaked(msg.sender, collectionId, tokenId, block.timestamp, extra);
        }
    }

    function unstake(
        address to,
        uint256[] calldata collectionIds,
        uint256[] calldata tokenIds
    )
        public
    {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 collectionId = collectionIds[i];
            uint256 tokenId = tokenIds[i];
            emit NftUnstaked(msg.sender, collectionId, tokenId, block.timestamp, "unstake");
        }
    }
}