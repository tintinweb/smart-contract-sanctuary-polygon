/**
 *Submitted for verification at polygonscan.com on 2023-02-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Cerclex {
    struct WasteMaterial {
        uint wasteId;
        string Type_of_Material;
        string Category;
        string Sub_Category;
        string Geo_Address;
        uint Timestamp;
    }
    
    mapping (uint => WasteMaterial) public wasteMaterials;
    uint wasteIdCounter = 0;
    
    // The address of the NFT contract
    address public nftContractAddress;
    
    constructor(address _nftContractAddress) public {
        nftContractAddress = _nftContractAddress;
    }
    
    function addWasteMaterial(string memory Type_of_Material, string memory Category, string memory Sub_Category, string memory Geo_Address, uint Timestamp) public {
        require(isNFTOwner(), "You must be an NFT owner to add waste material");
        wasteIdCounter ++;
        wasteMaterials[wasteIdCounter] = WasteMaterial(wasteIdCounter, Type_of_Material, Category, Sub_Category, Geo_Address, Timestamp);
    }
    
    function getWasteMaterial(uint wasteId) public view returns (string memory, string memory, string memory, string memory, uint) {
        WasteMaterial storage wasteMaterial = wasteMaterials[wasteId];
        return (wasteMaterial.Type_of_Material, wasteMaterial.Category, wasteMaterial.Sub_Category, wasteMaterial.Geo_Address, wasteMaterial.Timestamp);
    }
    
    function isNFTOwner() private view returns (bool) {
        // Replace this with the correct NFT contract call to check ownership
        return true;
    }
}