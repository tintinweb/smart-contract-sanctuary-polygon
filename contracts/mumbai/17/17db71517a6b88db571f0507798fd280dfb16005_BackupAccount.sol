// SPDX-License-Identifier: GPLv3

pragma solidity >=0.8.0;

import "./IERC20.sol";

interface PlayDSGInterface {
    function isStopLoss1() external view returns(bool);
}

contract BackupAccount {
    IERC20 public usdc;
    PlayDSGInterface public mainContract;
    address public mainContractAddr;
    address public owner;

    constructor(address _usdc) {
        usdc = IERC20(_usdc);
        owner = msg.sender;
    }

    function setContract(address _contract) public {
        require(mainContractAddr == address(0), "main contract already set");
        mainContractAddr = _contract;
        mainContract = PlayDSGInterface(_contract);
        usdc.approve(address(_contract), 10000000000e6);
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