/**
 *Submitted for verification at polygonscan.com on 2022-08-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/*
Ukraine Donation address: 0x165CD37b4C644C2921454429E7F9358d18A45e14
Source: https://twitter.com/Ukraine/status/1497594592438497282
*/


contract GBAStore {

    uint public percentage;

    uint public totalDonated;
    uint public itemsSold;

    //Ukraine Donation Address and GBA Treasury
    address public uaAddress;
    address public gbaAddress;

    constructor(uint _percentage) {
        require(_percentage <= 100, 'Percentage must be less than 100');
        percentage = _percentage;
        totalDonated = 0;
        itemsSold = 0;
        /*todo: replace with real addresses */
        uaAddress = 0x165CD37b4C644C2921454429E7F9358d18A45e14;
        gbaAddress = 0xE1C98A5c3174DD3de80eA9aa48c3d3aeC40cbeF8;
    }

    event Purchased (uint amountDonated, uint amountGBA);

    function purchase() public payable {
        require(msg.value > 0, 'The amount must be greater than 0');

        // Split the amount
        uint ukraineCut = msg.value * percentage / 100;
        uint gbaCut = msg.value - ukraineCut;

        payable(uaAddress).transfer(ukraineCut);
        payable(gbaAddress).transfer(gbaCut);

        totalDonated += ukraineCut;
        itemsSold += 1;

        emit Purchased(ukraineCut, gbaCut);
    }

}