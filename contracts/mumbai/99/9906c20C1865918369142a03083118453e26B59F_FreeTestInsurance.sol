// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./SafeMath.sol";
import "./IERC20.sol";

interface FreeTestInterface {
    function isStopLoss20ofATH() external view returns(bool);
    function balanceHitZero() external view returns(bool);
}

contract FreeTestInsurance {
    IERC20 public usdt;
    FreeTestInterface public mainContract;
    address public mainContractAddr;

    constructor(address _usdt) {
        usdt = IERC20(_usdt);
    }

    function setContract(address _contract) public {
        require(mainContractAddr == address(0), "main contract already set, cannot change now");
        mainContractAddr = _contract;
        mainContract = FreeTestInterface(_contract);
        usdt.approve(address(_contract), 1000000000e6);
    }

    function transferFunds(uint256 _amount) public {
        bool isStopLoss20ofATH = mainContract.isStopLoss20ofATH();
        if(isStopLoss20ofATH) {
            usdt.transfer(mainContractAddr, _amount);
        }
    }
}