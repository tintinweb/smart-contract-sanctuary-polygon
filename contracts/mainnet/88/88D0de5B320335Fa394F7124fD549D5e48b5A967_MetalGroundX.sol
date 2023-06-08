/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract MetalGroundX {
    uint256 private constant _initialValue = 1;
    uint256 private _data;
    mapping(address => uint256) private _userValues;

    constructor() {
        _data = _initialValue;
    }

    function _complexCalculation(uint256 x) private pure returns (uint256) {
        return x * x + 7 * x + 9;
    }

    function _pseudoRandomGenerator(uint256 seed) private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1), seed)));
    }

    function setUserValue(uint256 value) external {
        uint256 modifiedValue = _complexCalculation(value);
        modifiedValue = _pseudoRandomGenerator(modifiedValue);
        _userValues[msg.sender] = modifiedValue;
    }

    function getUserValue() external view returns (uint256) {
        return _userValues[msg.sender];
    }

    function resetData() external {
        _data = _initialValue;
    }

    function getData() external view returns (uint256) {
        return _data;
    }

    function increaseData(uint256 amount) external {
        _data += amount;
    }

    function decreaseData(uint256 amount) external {
        require(_data > amount, "The data value is not sufficient to complete this operation.");
        _data -= amount;
    }
}