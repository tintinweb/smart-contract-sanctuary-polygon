// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BatchTransfer {
    function batchTransfer(address[] memory _addrs, uint256 amount) public payable {
        require(msg.value == _addrs.length * amount);
        for(uint i = 0; i < _addrs.length; i++) {
            payable(_addrs[i]).transfer(amount);
        }
    }
}