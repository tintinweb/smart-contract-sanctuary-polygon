// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./IERC20.sol";

interface web3DefiInterface {
    function isStopLoss20ofATH() external view returns(bool);
}

contract SupportFund {
    IERC20 public usdt;
    web3DefiInterface public mainContract;
    address public mainContractAddr;
    address public owner;

    constructor(address _usdt) {
        usdt = IERC20(_usdt);
        owner = msg.sender;
    }

    function setContract(address _contract) public {
        require(mainContractAddr == address(0), "main contract already set, cannot change now");
        mainContractAddr = _contract;
        mainContract = web3DefiInterface(_contract);
        usdt.approve(address(_contract), 1000000000e6);
    }

    function transferFunds(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can call");
        bool isStopLoss20ofATH = mainContract.isStopLoss20ofATH();
        if(isStopLoss20ofATH) {
            usdt.transfer(mainContractAddr, _amount);
        }
    }

    function isStopLoss() public view returns(bool) {
        return mainContract.isStopLoss20ofATH();
    }
}