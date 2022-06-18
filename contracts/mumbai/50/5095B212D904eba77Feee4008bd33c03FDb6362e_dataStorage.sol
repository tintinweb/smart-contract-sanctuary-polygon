/**
 *Submitted for verification at polygonscan.com on 2022-06-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract dataStorage {

    struct hash{
        uint256 productID;
        string hash;
        bool isExist;
    }

    mapping (uint256 => hash) private hashes;

    function addHash (uint256 _productID, string memory _hash) public returns (bool){
        require (hashes[_productID].isExist == false, "Hash of Same Product ID Already Exist");
        hashes[_productID] = hash(_productID, _hash, true);
        return true;
    }

    function getHash (uint256 _productID) public view returns (string memory){
        require (hashes[_productID].isExist == true, "No Product Found");
        return hashes[_productID].hash;
    }
}