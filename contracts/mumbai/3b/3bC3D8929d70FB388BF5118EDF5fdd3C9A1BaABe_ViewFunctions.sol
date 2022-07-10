/**
 *Submitted for verification at polygonscan.com on 2022-07-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOmniChainNFT {
    struct Spaceship {
        uint256 power;
        uint256 points;
        bool staked;
        bool inBattle;
        uint256 stakeStartTime;
        uint256 tokenMissiles;
        uint256 tokenShields;
    }

    function balanceOf(address owner) external view returns (uint256 balance);

    function getSpaceshipByTokenId(uint256 _id)
        external
        view
        returns (Spaceship memory spaceship);

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract ViewFunctions {
    address public nftContract;

    constructor(address _nftContract) {
        nftContract = _nftContract;
    }

    function getAllSpaceships()
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            bool[] memory
        )
    {
        uint256 total = IOmniChainNFT(nftContract).totalSupply();
        uint256[] memory tokenIds = new uint256[](total);
        uint256[] memory powers = new uint256[](total);
        uint256[] memory resources = new uint256[](total);
        uint256[] memory missiles = new uint256[](total);
        uint256[] memory shields = new uint256[](total);
        bool[] memory tokensStaked = new bool[](total);
        bool[] memory tokensInBattle = new bool[](total);

        for (uint256 i = 0; i < total; i++) {
            uint256 tokenId = IOmniChainNFT(nftContract).tokenByIndex(i);
            tokenIds[i] = tokenId;
            powers[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .power;
            resources[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .points;
            missiles[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .tokenMissiles;
            shields[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .tokenShields;
            tokensStaked[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .staked;
            tokensInBattle[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .inBattle;
        }
        return (
            tokenIds,
            powers,
            resources,
            missiles,
            shields,
            tokensStaked,
            tokensInBattle
        );
    }

    function getSpaceshipsByOwner(address owner)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory,
            bool[] memory
        )
    {
        uint256 balance = IOmniChainNFT(nftContract).balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256[] memory powers = new uint256[](balance);
        uint256[] memory resources = new uint256[](balance);
        uint256[] memory missiles = new uint256[](balance);
        // this is a temporary solution for stack too deep issue
        address ownerCopy = owner;
        uint256[] memory shields = new uint256[](balance);
        bool[] memory tokensStaked = new bool[](balance);
        bool[] memory tokensInBattle = new bool[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = IOmniChainNFT(nftContract).tokenOfOwnerByIndex(
                ownerCopy,
                i
            );
            tokenIds[i] = tokenId;
            powers[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .power;
            resources[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .points;
            missiles[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .tokenMissiles;
            shields[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .tokenShields;
            tokensStaked[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .staked;
            tokensInBattle[i] = IOmniChainNFT(nftContract)
                .getSpaceshipByTokenId(tokenId)
                .inBattle;
        }
        return (
            tokenIds,
            powers,
            resources,
            missiles,
            shields,
            tokensStaked,
            tokensInBattle
        );
    }
}