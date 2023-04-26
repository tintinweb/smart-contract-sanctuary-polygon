/**
 *Submitted for verification at polygonscan.com on 2023-04-26
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.18;
pragma abicoder v2;

contract ForwarderFake {

    constructor() {
    }

    function execute(address from, address to, bytes calldata data, uint256 gas) external returns (bool success, bytes memory ret) {
        bytes memory callData = abi.encodePacked(data, from);
        
        require(gasleft()*63/64 > gas, "FWD: insufficient gas");
        
        (success,ret) = to.call{gas: gas, value: 0}(callData);

        require(success, "namlv");

        return (success,ret);
    }
}