/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

// Extended the interface of the contract to include tokensOfOwner function
interface INFTContract {
    function useNFT(address _holder, uint256 _tokenId) external;
    function tokensOfOwner(address _owner) external view returns (uint256[] memory);
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

    function useNFTsMultipleTimes(address[] calldata _holders, uint256[] calldata _tokenIds, uint256 _times) external {
    require(_holders.length == _tokenIds.length, "Arrays length mismatch");

    for (uint256 i = 0; i < _holders.length; i++) {
        for (uint256 j = 0; j < _times; j++) {
            nftContract.useNFT(_holders[i], _tokenIds[i]);
        }
    }
}

    // This function takes an array of addresses and for each address
    // it retrieves the list of tokenIds owned by that address.
    // It returns an array of arrays of tokenIds.
    function getTokensOfOwners(address[] calldata _owners) external view returns (uint256[][] memory) {
        uint256[][] memory ownerTokens = new uint256[][](_owners.length);
        for (uint256 i = 0; i < _owners.length; i++) {
            ownerTokens[i] = nftContract.tokensOfOwner(_owners[i]);
        }
        return ownerTokens;
    }

}