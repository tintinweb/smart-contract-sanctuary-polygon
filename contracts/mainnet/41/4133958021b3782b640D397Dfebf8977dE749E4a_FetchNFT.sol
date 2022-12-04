// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

contract FetchNFT {

    // The address of the contract that holds the NFTs
    address public nftContractAddress = 0xa9a6A3626993D487d2Dbda3173cf58cA1a9D9e9f;

    // The address of the wallet that holds the NFTs
    address public walletAddress;

    // The function to call on the contract to get an NFT
    function getNFT(uint256 nftId) public returns (bytes32 nftData) {
        // Call the contract at the specified address and return the data for the given NFT
        (bool success, bytes memory data) = address(nftContractAddress).call(abi.encodeWithSignature("getNFT(uint256)", nftId));
        require(success, "Failed to get NFT from contract");
        return bytes32(data);
    }

    // The function to call on the wallet to get an NFT
    function getNFTFromWallet(uint256 nftId) public returns (bytes32 nftData) {
        // Call the wallet at the specified address and return the data for the given NFT
        (bool success, bytes memory data) = address(walletAddress).call(abi.encodeWithSignature("getNFT(uint256)", nftId));
        require(success, "Failed to get NFT from wallet");
        return bytes32(data);
    }

    // The function to automatically fetch an NFT from the wallet
    // function fetchNFT(uint256 nftId) public {
    //     // Get the NFT data from the wallet
    //     bytes32 nftData = getNFTFromWallet(nftId);

    //     // Do something with the NFT data (e.g. store it in the contract, transfer it to another address, etc.)
    // }
}