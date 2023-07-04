/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Deployer {

    constructor() payable {}

    function deploy(bytes memory _bytecode) external payable returns (address addr) {

        assembly {
            addr := create(0, add(_bytecode, 0x20), mload(_bytecode))
        }

        require (addr != address(0), 'deploy failed');
    }

    receive() external payable {}
}