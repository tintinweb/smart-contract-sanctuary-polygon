// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Meat {
    struct ProdInfo {
        string ProductDetails; //ProductID:SlaughterhouseID:FarmID:ButcherID
        string SnEDate; //Slaughter and expiry date
        string RetailorID;
        string DistributorID;
    }
    mapping (string => ProdInfo) Products;
    function create(string memory _ProdCode, string memory _ProductDetails, string memory _SnEDate) public {
        Products[_ProdCode].ProductDetails = _ProductDetails;
        Products[_ProdCode].SnEDate = _SnEDate;
    }

    function UpdateRetailor(string memory _ProdCode, string memory _RetailorID) public returns (bool) {
        Products[_ProdCode].RetailorID = _RetailorID;
        return true;
    }

    function UpdateDistributor(string memory _ProdCode, string memory _DistributorID) public returns (bool) {
        Products[_ProdCode].DistributorID = _DistributorID;
        return true;
    }

    function retrieve(string memory _ProdCode) public view returns (string memory, string memory, string memory, string memory) {
        ProdInfo memory prodInfo = Products[_ProdCode];
        return (prodInfo.ProductDetails, prodInfo.SnEDate, prodInfo.RetailorID, prodInfo.DistributorID);
    }
}