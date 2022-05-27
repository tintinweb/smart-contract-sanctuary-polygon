/**
 *Submitted for verification at polygonscan.com on 2022-05-26
*/

// SPDX-License-Identifier: MIT


pragma solidity 0.8.10;

interface IBloodTokenChild {
    function spend(uint256 amount, address sender, address recipient, address redirectAddress, uint256 redirectPercentage, uint256 burnPercentage) external;
}

contract TestBurnThroughProxy {

    IBloodTokenChild BloodTokenChild;

    constructor(address bloodTokenChildContractAddress) {
        BloodTokenChild = IBloodTokenChild(bloodTokenChildContractAddress);
    }

    function spendProxy(uint256 amount) external {
        BloodTokenChild.spend(amount, msg.sender, address(0), address(0), 0, 100);
    }
}