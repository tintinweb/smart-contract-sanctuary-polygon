/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
List of charities:
1. UkraineDAO - 0x633b7218644b83d57d90e7299039ebab19698e9c
*/


contract GBAStore {

    uint public percentage;

    uint public totalDonated;
    uint public itemsSold;

    //temporary!
    address public charityAddress;
    address public gbaAddress;

    constructor() {
        percentage = 15;
        totalDonated = 0;
        itemsSold = 0;
        /*todo: replace with real addresses */
        charityAddress = 0x0EbBEeeE9B746F0f53b73Acc534A0784FFBfB2b4;
        gbaAddress = 0x071c3C0D9c9f19214c5b48F36f488a23BAb3d000;
    }

    function purchase() public payable {
        // Split the amount
        uint charityCut = msg.value * percentage / 100;
        uint gbaCut = msg.value - charityCut;

        payable(charityAddress).transfer(charityCut);
        payable(gbaAddress).transfer(gbaCut);

        totalDonated += charityCut;
        itemsSold += 1;
    }

}