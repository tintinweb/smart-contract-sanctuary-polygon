// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Keeper {
    mapping(string => address) tTP;
    mapping(address => string) pTT;

    constructor() {
    }

    function setTerraPolygonAddresses(address polAd, string memory telAd) public {
        tTP[telAd] = polAd;
        pTT[polAd] = telAd;
    }
    function getTelAd(address polAd) view public returns (string memory) {
        return pTT[polAd];
    }

    function getPolAd(string memory telAd) view public returns (address) {
        return tTP[telAd];
    }
}