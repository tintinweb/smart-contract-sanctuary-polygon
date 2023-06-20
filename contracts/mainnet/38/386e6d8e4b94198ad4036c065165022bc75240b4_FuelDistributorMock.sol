// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

contract FuelDistributorMock {
    constructor() {}

    function destinationsProtocol(uint256 _usdAmount) external returns (address _fuelTo, uint24, string memory) {
        return (address(0x1), 1, "test");
    }
}