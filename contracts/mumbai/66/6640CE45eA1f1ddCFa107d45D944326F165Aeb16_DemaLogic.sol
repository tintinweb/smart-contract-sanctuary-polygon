// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DemaStorage.sol";

contract DemaLogic {
    DemaStorage public demaStorage;

    address public owner;

    mapping(address => bool) public isReviewer;

    modifier onlyAdmin() {
        require(msg.sender == owner, "Only admin can call this function.");
        _;
    }

    constructor(address storageAddress, address admin) {
        demaStorage = DemaStorage(storageAddress);
        owner = admin;
    }

    function updateAdmin(address newAdmin) external onlyAdmin{
        isReviewer[newAdmin] = true;
    }

    function updateStorage(address storageAddress) external onlyAdmin{
       demaStorage = DemaStorage(storageAddress);
    }

    function productReview(uint256 id, string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setProductInfo(id, hash);
        return true;
    }

    function sellerReview(uint256 id, string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setSellerInfo(id, hash);
        return true;
    }

    function shoppersReview(uint256 id, string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setShopperInfo(id, hash);
        return true;
    }

    function allProducts(string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setAllProduct(hash);
        return true;
    }

    function allSellers(string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setAllSeller(hash);
        return true;
    }

    function allShoppers(string memory hash) external returns (bool) {
        require(isReviewer[msg.sender], "You are not owner");
        demaStorage.setAllShopper(hash);
        return true;
    }

    function viewProductReview(uint256 id) external view returns (string memory hash) {
        return demaStorage.getProductInfo(id);
    }

    function viewSellerReview(uint256 id) external view returns (string memory hash) {
        return demaStorage.getSellerInfo(id);
    }

    function viewShoppersReview(uint256 id) external view returns (string memory hash) {
        return demaStorage.getShopperInfo(id);
    }
}