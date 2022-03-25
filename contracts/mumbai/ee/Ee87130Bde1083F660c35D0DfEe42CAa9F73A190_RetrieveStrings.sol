/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;


interface IStore {
    function getProduct(uint256 listingIndex) external view returns (
        address productAddress,
        string memory imageURI,
        string memory title, 
        string memory desc,
        uint256 price
    );
}


contract RetrieveStrings {
    function getProductAddress(address target, uint256 listingIndex) public view returns (address) {
        (address productAddress, , , ,) = IStore(target).getProduct(listingIndex);
        return productAddress;
    }

    function getImageURI(address target, uint256 listingIndex) public view returns (string memory) {
        (, string memory imageURI, , ,) = IStore(target).getProduct(listingIndex);
        return imageURI;
    }

    function getTitle(address target, uint256 listingIndex) public view returns (string memory) {
        (, , string memory title, ,) = IStore(target).getProduct(listingIndex);
        return title;
    }

    function getDesc(address target, uint256 listingIndex) public view returns (string memory) {
        (, , , string memory desc,) = IStore(target).getProduct(listingIndex);
        return desc;
    }

    function getPrice(address target, uint256 listingIndex) public view returns (uint256) {
        (, , , , uint256 price) = IStore(target).getProduct(listingIndex);
        return price;
    }
}