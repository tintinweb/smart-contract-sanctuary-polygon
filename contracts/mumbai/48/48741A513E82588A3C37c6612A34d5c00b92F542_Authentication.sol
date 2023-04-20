// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Authentication{

    struct ProdInfo {
        string ProductDetails; //FarmID:AnimalID:SlaughterhouseID:ButcherID "F001:A001:SH001:B001"
        string SnEDate; //Slaughter and expiry date "2-3-2023:15-3-2023"
        uint256 RecordCreationTime;
        string RetailorID; //    "R001"
        uint256 RetailorReceiveTime;
        string DistributorID;  // "D001"
        uint256 DistributorReceiveTime;
    }

mapping (string => ProdInfo) Products;
    
    function create(string memory _ProdCode, string memory _ProductDetails, string memory _SnEDate) public returns (bool) {
    if (bytes(Products[_ProdCode].ProductDetails).length == 0) {
        Products[_ProdCode].ProductDetails = _ProductDetails;
        Products[_ProdCode].SnEDate = _SnEDate;
        Products[_ProdCode].RecordCreationTime = block.timestamp;
        return true;
    } else {
        return false;
    }
}

    function UpdateRetailor(string memory _ProdCode, string memory _RetailorID) public returns (bool) {
    if (bytes(Products[_ProdCode].ProductDetails).length > 0) {
        ProdInfo storage prodInfo = Products[_ProdCode];
        if (bytes(prodInfo.RetailorID).length == 0) {
            prodInfo.RetailorID = _RetailorID;
            prodInfo.RetailorReceiveTime = block.timestamp;
            return true;
        } else {
            return false;
        }
    } else {
        // _ProdCode not found in mapping, return false
        return false;
    }
}

    function UpdateDistributor(string memory _ProdCode, string memory _DistributorID) public returns (bool) {
    if (bytes(Products[_ProdCode].ProductDetails).length > 0) {
        ProdInfo storage prodInfo = Products[_ProdCode];
        if (bytes(prodInfo.DistributorID).length == 0) {
            Products[_ProdCode].DistributorID = _DistributorID;
            Products[_ProdCode].DistributorReceiveTime = block.timestamp;
            return true;
        } else {
            return false;
        }
    } else {
        // _ProdCode not found in mapping, return false
        return false;
    }
}
    function retrieve(string memory _ProdCode) public view returns (string memory, string memory,uint256, string memory,uint256, string memory,uint256 ) {
        ProdInfo memory prodInfo = Products[_ProdCode];
        return (prodInfo.ProductDetails, prodInfo.SnEDate,prodInfo.RecordCreationTime, prodInfo.RetailorID,prodInfo.RetailorReceiveTime, prodInfo.DistributorID,prodInfo.DistributorReceiveTime);
    }
}