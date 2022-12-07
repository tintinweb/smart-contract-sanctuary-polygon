/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract TdexMock {

    uint256 public _price;

    constructor() {
        _price = 12500*10**26;
    }
    
    function getPrice(address tokenContract) external view returns(uint256){
        return _price;
    }

    function setPrice(uint256 price) external {
        _price = price;
    }

}