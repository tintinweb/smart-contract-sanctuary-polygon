// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract gasCalculator is Ownable {
 
    address public oracleAddress;
    uint256 public gasETH;
    uint256 public gasMultiplier;

    constructor(address _oracleAddress, uint256 _gasEth, uint256 _gasMultiplier) {
        oracleAddress = _oracleAddress;
        gasETH = _gasEth;
        gasMultiplier = _gasMultiplier;
    }

    function setGasEth(uint256 _gas) public {
        require(msg.sender == oracleAddress);
        gasETH = _gas;
    }

    function setOracleAddress(address newOracleAddress) public onlyOwner {
        oracleAddress = newOracleAddress;
    }

    function setGasMultiplier(uint256 newMultiplier) public onlyOwner {
        gasMultiplier = newMultiplier;
    }
}