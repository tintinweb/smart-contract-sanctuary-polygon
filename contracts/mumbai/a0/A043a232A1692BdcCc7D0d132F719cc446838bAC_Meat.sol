// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Meat {
    struct ProdInfo {
        string ProductDetails; //FarmID:AnimalID:SlaughterhouseID:ButcherID
        string SnEDate; //Slaughter and expiry date
        string RetailorID;
        string DistributorID;
    }
    mapping (string => ProdInfo) Products;    
    function create(string memory _ProdCode, string memory _ProductDetails, string memory _SnEDate) public {
        require(bytes(_ProdCode).length > 0, "Product code cannot be empty.");
        require(bytes(_ProductDetails).length > 0, "Product details cannot be empty.");
        require(bytes(_SnEDate).length > 0, "Slaughter and expiry date cannot be empty.");
        Products[_ProdCode].ProductDetails = _ProductDetails;
        Products[_ProdCode].SnEDate = _SnEDate;
    }

    function UpdateRetailor(string memory _ProdCode, string memory _RetailorID) public returns (bool) {
        require(bytes(_ProdCode).length > 0, "Product code cannot be empty.");
        require(bytes(_RetailorID).length > 0, "Retailor ID cannot be empty.");
        require(bytes(Products[_ProdCode].ProductDetails).length > 0, "Product details not found.");

        Products[_ProdCode].RetailorID = _RetailorID;
        return true;
    }

    function UpdateDistributor(string memory _ProdCode, string memory _DistributorID) public returns (bool) {
        require(bytes(_ProdCode).length > 0, "Product code cannot be empty.");
        require(bytes(_DistributorID).length > 0, "Distributor ID cannot be empty.");
        require(bytes(Products[_ProdCode].ProductDetails).length > 0, "Product details not found.");

        Products[_ProdCode].DistributorID = _DistributorID;
        return true;
    }

    function retrieve(string memory _ProdCode) public view returns (string memory, string memory, string memory, string memory) {
        require(bytes(_ProdCode).length > 0, "Product code cannot be empty.");
        require(bytes(Products[_ProdCode].ProductDetails).length > 0, "Product details not found.");

        ProdInfo memory prodInfo = Products[_ProdCode];
        return (prodInfo.ProductDetails, prodInfo.SnEDate, prodInfo.RetailorID, prodInfo.DistributorID);
    }



}