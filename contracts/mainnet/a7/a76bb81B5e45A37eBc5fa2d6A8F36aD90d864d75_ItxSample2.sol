//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract ItxSample2 {
    uint256 private sumOfArgs;
    uint256 private arg1;
    uint256 private arg2;

    function setNumber(uint256 _arg1, uint256 _arg2) external {
        arg1 = _arg1;
        arg2 = _arg2;
        sumOfArgs = arg1 + arg2;
    }

    function getNumber() external view returns (uint256) {
        return sumOfArgs;
    }
}