/**
 *Submitted for verification at polygonscan.com on 2022-12-23
*/

// SPDX-License-Identifier: GPL-3.0

// File: contracts/interfaces/INFT.sol


pragma solidity ^0.8.2;

interface INFT {
    // Get the owner of a token
    function ownerOf(uint256 tokenId) external view returns (address);

    // Get the owner of a token
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/1_Storage.sol


contract Storage {

    // User Stats
    struct UserStats {
        uint256 postCount;
        uint256 commentCount;
        uint256 followerCount;
        uint256 followingCount;
        uint256 tipsReceived;
        uint256 tipsSent;
    }

    // User Avatar
    struct UserAvatar {
        string avatar;
        string avatarMetadata;
        address avatarContract;
    }

    // The User data struct
    struct UserData {
        string handle;
        string location;
        uint256 joinBlock;
        uint256 joinTime;
        UserAvatar userAvatar;
        string uri;
        string bio;
        uint256 followLimit;
        uint16 verified;
        address[] following;
        bool isGroup;
        UserStats userStats;
    }

    // Map the User Address => User Data
    mapping (address => UserData) public usrProfileMap;

    INFT public NFT;

    constructor() {
        
    }

        // Set an NFT as your profile photo (only for users / not groups)
    function setNFTAsAvatar(address _nftContract, uint256 tokenId) public {
        // Make sure we get a valid address
        require(_nftContract != address(0), "Need the contract address that minted the NFT");

        // Setup link to the NFT contract
        NFT = INFT(_nftContract);

        // Check that they're the owner of the NFT
        require(NFT.ownerOf(tokenId) == msg.sender, "You're not the owner of that NFT");

        // Save the token metadata
        usrProfileMap[msg.sender].userAvatar.avatarMetadata = NFT.tokenURI(tokenId);

        // Save the token contract
        usrProfileMap[msg.sender].userAvatar.avatarContract = _nftContract;
    }
}