/**
 *Submitted for verification at polygonscan.com on 2023-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Deployer {

    constructor() payable {}

    function deploy(bytes memory _bytecode, address seller, address service, uint8 percentage) external payable returns (address addr) {

        uint256 value = msg.value;
        uint256 serviceValue = msg.value * percentage / 100;
        uint256 sellerValue = value - serviceValue;
        
        assembly {
            addr := create(0, add(_bytecode, 0x20), mload(_bytecode))
        }

        require (addr != address(0), 'deploy failed');

        payable(service).transfer(serviceValue);
        payable(seller).transfer(sellerValue);
        
    }

    receive() external payable {}
}