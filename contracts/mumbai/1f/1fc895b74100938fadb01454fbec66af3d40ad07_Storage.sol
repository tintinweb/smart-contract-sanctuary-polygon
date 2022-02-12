/**
 *Submitted for verification at polygonscan.com on 2022-02-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Storage {
    struct WContract { 
        bytes metaData;
        bool isSigned;
        bytes fixedMetaData;
        address wClient;
    }

    mapping(uint => WContract) public contractStorage;



    function store(uint256 num, WContract memory contractInfo) public {
        contractStorage[num] = contractInfo;
    }

    function retrieve(uint256 num) public view returns (WContract memory){
        return contractStorage[num];
    }
}