// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract Proxy {
    address logicContractAddress;

    constructor() {
        logicContractAddress = 0x6a63eC824E1121fac9A23af73761a6297D85C5eA;
    }

    function forward() external returns (bytes memory) {
        (bool success, bytes memory data) = logicContractAddress.delegatecall(
            msg.data
        );
        require(success);
        return data;
    }
}