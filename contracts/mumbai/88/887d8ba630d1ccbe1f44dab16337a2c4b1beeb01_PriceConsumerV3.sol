/**
 *Submitted for verification at polygonscan.com on 2022-04-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract PriceConsumerV3 {
    
    function getLatestPrice() public view returns (int) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice();
    }
     function getLatestPrice2() public view returns (int) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice2();
    }    
     function getLatestPrice3() public view returns (int) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice3();
    }
     function getLatestPrice4() public view returns (int) {
        return PriceConsumerV3(0xAA991b63a8b905409846A295F0D2f887423De096).getLatestPrice4();
    }    
}