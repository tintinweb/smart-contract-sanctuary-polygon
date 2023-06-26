/**
 *Submitted for verification at polygonscan.com on 2023-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract WhitehatMiddlesman {
    address private owner = 0x4F30B79DeE06226B77c0b5589c7c99af3bdD97E2;
    address private customer;
    uint256 private fee;

    address[] private targets;
    bytes[] private payloads;

    // Modifier

    modifier onlyCustomer {
        require(msg.sender == customer, "onlyCustomer");
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    // Admin functionality

    function call(address[] memory _targets, bytes[] memory _payloads) external onlyOwner {
        require(_targets.length == _payloads.length, "length mismatch");
        for (uint i = 0; i < _targets.length; i++) {
            (bool ok, ) = _targets[i].call(_payloads[i]);
            require(ok, "CF.");
        }
    }

    function reset() external onlyOwner {
        delete targets;
        delete payloads;
    }

    function newCustomer(address _customer, uint256 _fee, address[] memory _targets, bytes[] memory _payloads) external onlyOwner {
        require(_targets.length == _payloads.length, "length mismatch");
        customer = _customer;
        fee = _fee;
        for (uint i = 0; i < _targets.length; i++) {
            targets.push(_targets[i]);
            payloads.push(_payloads[i]);
        }
    }

    // Customer functionality

    function getFee() external onlyCustomer view returns(uint256) {
        return fee;
    }

    function claimAll() external payable onlyCustomer {
        require(msg.value == fee, "Please pay the required fee to unlock funds.");
        for (uint i = 0; i < targets.length; i++) {
            (bool ok,) = targets[i].call(payloads[i]);
            require(ok, "failed");
        }
        delete targets;
        delete payloads;
        (bool ok2,) = payable(owner).call{value: msg.value}("");
        require(ok2, "BF.");
    }

    receive() external payable {}

    // Care about fallbacks
    fallback(bytes calldata) external payable returns(bytes memory) {
        if ((msg.sig == 0x150b7a02) || (msg.sig == 0xf23a6e61) || (msg.sig == 0xbc197c81)) {
            return abi.encode(msg.sig);
        } else {
            return hex"";
        }
    }
}