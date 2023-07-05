// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockMultiSig {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function destroy(address _receiver) external {
        require(msg.sender == owner, "Reserve: not owner");
        selfdestruct(payable(_receiver));
    }

    fallback() external payable {}

    receive() external payable {}
}