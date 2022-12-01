// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./IERC20.sol";

interface TestInterface {
    function isStopLoss1() external view returns(bool);
}

contract SupportFund {
    IERC20 public usdc;
    TestInterface public mainContract;
    address public mainContractAddr;
    address public owner;
    address[3] public feeReceivers;

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
        owner = msg.sender;
    }

    function setContract(address _contract) public {
        require(mainContractAddr == address(0), "main contract already set, cannot change now");
        mainContractAddr = _contract;
        mainContract = TestInterface(_contract);
        usdc.approve(address(_contract), 1000000000e6);
    }

    function transferFunds(uint256 _amount) public {
        require(msg.sender == owner, "Only owner can call");
        bool isStopLoss1 = mainContract.isStopLoss1();
        if(isStopLoss1) {
            usdc.transfer(mainContractAddr, _amount);
        }
    }

    function isStopLoss() public view returns(bool) {
        return mainContract.isStopLoss1();
    }
}