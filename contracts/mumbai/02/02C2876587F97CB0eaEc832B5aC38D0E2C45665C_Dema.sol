/**
 *Submitted for verification at polygonscan.com on 2023-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dema {
    
    mapping(uint256 => string) private productInfo;
    mapping(uint256 => string) private sellerInfo;
    mapping(uint256 => string) private shopperInfo;

    string private allProducts;
    string private allSellers;
    string private allShoppers;

    function setShopperSellerReview(uint256 sellerId, uint256 shopperId, string memory sellerHash, string memory shopperHash, string memory allSellerHash, string memory allShopperHash) external {
        sellerInfo[sellerId] = sellerHash;
        shopperInfo[shopperId] = shopperHash;
        allShoppers = allShopperHash;
        allSellers  = allSellerHash;
    }

    function setReviewResponse(uint256 productId, uint256 sellerId, uint256 shopperId, string memory productHash, string memory sellerHash, string memory shopperHash,  string memory allProductHash, string memory allSellerHash, string memory allShopperHash) external {
        productInfo[productId] = productHash;
        shopperInfo[shopperId] = shopperHash;
        sellerInfo[sellerId] = sellerHash;
        allProducts = allProductHash;
        allShoppers = allShopperHash;
        allSellers  = allSellerHash;
    }

    function createProduct(uint256 productId, string memory productHash, string memory allProductHash) public {
        productInfo[productId] = productHash;
        allProducts = allProductHash;
    }

    function createSeller(uint256 sellerId, string memory sellerHash, string memory allSellerHash) public {
        sellerInfo[sellerId] = sellerHash;
        allSellers = allSellerHash;
    }

    function createShopper(uint256 shopperId, string memory shopperHash, string memory allShopperHash) public {
        shopperInfo[shopperId] = shopperHash;
        allShoppers = allShopperHash;
    }

    function viewProductReview(uint256 productId) public view returns (string memory){
        return productInfo[productId];
    }

    function viewSellerReview(uint256 sellerId) public view returns (string memory){
        return sellerInfo[sellerId];
    }

    function viewShopperReview(uint256 shopperId) public view returns (string memory){
        return shopperInfo[shopperId];
    }

    function getAllProductReview() public view returns (string memory){
        return allProducts;
    }

    function getAllShopperReview() public view returns (string memory){
        return allShoppers;
    }

    function getAllSellerReview() public view returns (string memory){
        return allSellers;
    }

}