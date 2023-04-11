// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GenericOracle {
    uint256 private price;
    uint256 private lastUpdated;
    address private allowedCaller;
    

    event PriceUpdated(uint256 timestamp, uint256 newPrice);
    event AllowedCallerUpdated(uint256 timestamp, address newAllowedCaller);

    constructor(address _allowedCaller) {
        allowedCaller = _allowedCaller == address(0) ? msg.sender : _allowedCaller;
    }

    function updatePrice(uint256 _price) public {
        require(msg.sender == allowedCaller, "Caller not authorized");
        require(_price > 0, "Price must be greater than 0");
        price = _price;
        lastUpdated = block.timestamp;
        emit PriceUpdated(block.timestamp, _price);
    }

    function updateAllowedCaller(address _newAllowedCaller) public {
        require(msg.sender == allowedCaller, "Caller not authorized");
        require(_newAllowedCaller != address(0), "New allowed caller cannot be address 0");
        require(_newAllowedCaller != allowedCaller, "New allowed caller must be different from the current one");
        allowedCaller = _newAllowedCaller;
        emit AllowedCallerUpdated(block.timestamp, _newAllowedCaller);
    }

    function getIndexValue() external view returns (uint256) {
        return price;
    }

    function getAllowedCaller() external view returns (address) {
        return allowedCaller;
    }

    function getLastUpdated() external view returns (uint256) {
        return lastUpdated;
    }


}