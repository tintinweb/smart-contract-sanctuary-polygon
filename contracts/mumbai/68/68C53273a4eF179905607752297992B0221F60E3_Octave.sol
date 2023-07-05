// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Octave {
    event TokenOpenForMonetize(
        uint256 monetizeId,
        address contractAddress,
        address owner,
        uint256 tokenId,
        string metaDataUri
    );
    struct MusicNFT {
        address contractAddress;
        uint256 tokenId;
        string metaDataUri;
    }

    uint256 musicNftCounter = 0;
    mapping(uint256 => MusicNFT) public tokenIdToMusic;

    function openForMonetize(
        address contractAddress,
        uint256 tokenId,
        string memory metaDataUri
    ) public {
        tokenIdToMusic[musicNftCounter].contractAddress = contractAddress;
        tokenIdToMusic[musicNftCounter].tokenId = tokenId;
        tokenIdToMusic[musicNftCounter].metaDataUri = metaDataUri;
        emit TokenOpenForMonetize(
            musicNftCounter,
            contractAddress,
            msg.sender,
            tokenId,
            metaDataUri
        );
        musicNftCounter++;
    }
}