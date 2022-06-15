// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

interface IStakedMatic {
    function ratio() external view returns (uint256);
}

contract RateProvider is IRateProvider {
    IStakedMatic public aMaticC;

    constructor(IStakedMatic _AMaticC) {
        aMaticC = _AMaticC;
    }

    function getRate() external override view returns (uint256) {
        return aMaticC.ratio();
    }
}