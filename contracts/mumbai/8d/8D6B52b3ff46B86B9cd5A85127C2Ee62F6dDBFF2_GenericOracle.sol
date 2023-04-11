// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenericOracle {
    address private allowedCaller;
    uint256 private indexValue;

    event PriceUpdated(uint256 timestamp, uint256 price);

    modifier onlyAllowedCaller() {
        require(msg.sender == allowedCaller, "Caller not authorized");
        _;
    }

    constructor(address _allowedCaller) {
        allowedCaller = _allowedCaller;
    }

    function updatePrice(uint256 price) external onlyAllowedCaller {
        indexValue = price;
        emit PriceUpdated(block.timestamp, price);
    }

    function getIndexValue() external view returns (uint256) {
        return indexValue;
    }
}