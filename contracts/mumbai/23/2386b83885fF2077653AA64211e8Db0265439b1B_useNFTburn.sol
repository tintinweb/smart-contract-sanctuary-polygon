/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// This is an interface of the contract that contains the useNFT function
interface INFTContract {
    function useNFT(address _holder, uint256 _tokenId) external;
}


contract useNFTburn {
    INFTContract nftContract;

    // Initialize the address of the NFT contract in the constructor
    constructor(address _nftContractAddress) {
        nftContract = INFTContract(_nftContractAddress);
    }

    // Function to call useNFT function twice for each address and token ID
    function useNFTsTwice(address[] calldata _holders, uint256[] calldata _tokenIds) external {
        require(_holders.length == _tokenIds.length, "Arrays length mismatch");

        for (uint256 i = 0; i < _holders.length; i++) {
            nftContract.useNFT(_holders[i], _tokenIds[i]);
            nftContract.useNFT(_holders[i], _tokenIds[i]);
        }
    }
}