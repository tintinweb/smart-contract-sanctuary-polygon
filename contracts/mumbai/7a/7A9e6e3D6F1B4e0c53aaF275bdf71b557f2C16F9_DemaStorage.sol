/**
 *Submitted for verification at polygonscan.com on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DemaStorage {
    
    uint256 public totalProducts;
    uint256 public totalShoppers;
    uint256 public totalSellers;

    mapping(uint256 => string) public productInfo;
    mapping(uint256 => string) public sellerInfo;
    mapping(uint256 => string) public shopperInfo;

    mapping(uint256 => string) public allProduct;
    mapping(uint256 => string) public allSeller;
    mapping(uint256 => string) public allShopper;

    function setProductInfo(uint256 id, string memory hash) external{
        if(bytes(productInfo[id]).length == 0){
            productInfo[id] = hash;
            totalProducts++;
        }else{
            productInfo[id] = hash;
        }
    }

    function getProductInfo(uint256 id) external view returns (string memory){
        if(bytes(productInfo[id]).length != 0){
            return productInfo[id];
        }else{
            return '0';
        }
    }

    function setSellerInfo(uint256 id, string memory hash) external{
        if(bytes(sellerInfo[id]).length == 0){
            sellerInfo[id] = hash;
            totalSellers++;
        }else{
            sellerInfo[id] = hash;
        }     
    }
    
    function getSellerInfo(uint256 id) external view returns (string memory){
        if(bytes(sellerInfo[id]).length != 0){
            return sellerInfo[id];
        }else{
            return '0';
        }
    }

    function setShopperInfo(uint256 id, string memory hash) external{
        if(bytes(shopperInfo[id]).length == 0){
            shopperInfo[id] = hash;
            totalShoppers++;
        }else{
            shopperInfo[id] = hash;
        }      
    }

    function getShopperInfo(uint256 id) external view returns (string memory){
        if(bytes(shopperInfo[id]).length != 0){
            return shopperInfo[id];
        }else{
            return '0';
        }
    }
    
    function setAllProduct(string memory hash) external{
        allProduct[0] = hash;
    }

    function setAllSeller(string memory hash) external{
        allSeller[0] = hash;
    }

    function setAllShopper(string memory hash) external{
        allShopper[0] = hash;
    }
}