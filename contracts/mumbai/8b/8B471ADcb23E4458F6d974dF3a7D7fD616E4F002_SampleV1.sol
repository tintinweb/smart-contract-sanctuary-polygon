// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

contract SampleV1 {
    address constant someAddr = address(0xdCad3a6d3569DF655070DEd06cb7A1b2Ccd1D3AF);

    struct Transfer {
        address from;
        address to;
        uint value;
    }

    Transfer[] public transfers;

    function return_address() public pure returns (address) {
        return someAddr;
    }
    function return_uint8(bool isMax) public pure returns (uint8) {
        if (isMax) {
            return type(uint8).max;
        } else {
            return 0;
        }
    }
    function return_uint64(bool isMax) public pure returns (uint64) {
        if (isMax) {
            return type(uint64).max;
        } else {
            return 0;
        }
    }
    function return_uint256(bool isMax) public pure returns (uint256) {
        if (isMax) {
            return type(uint256).max;
        } else {
            return 0;
        }
    }
    function return_string() public pure returns (string memory) {
        return "Hello World";
    }
    function return_transfer_max_value() public pure returns (Transfer memory) {
        return Transfer(someAddr, someAddr, type(uint256).max);
    }

    function return_transfer_zero_value() public pure returns (Transfer memory) {
        return Transfer(address(0), address(0), 0);
    }
    function return_multi_transfer(bool isMax, uint count) public pure returns (Transfer[] memory) {
        Transfer[] memory _transfers = new Transfer[](count);
        if (isMax) {
            for (uint i = 0; i < count; i++) {
               _transfers[i] = return_transfer_max_value();
            }
        } else {
            for (uint i = 0; i < count; i++) {
               _transfers[i] = return_transfer_zero_value();
            }
        }
        return _transfers;
    }

    function addTransfer(address from, address to, uint value) public {
        transfers.push(Transfer(from, to, value));
    }
    function addTransfers(Transfer[] memory inputs) public {
        for (uint i = 0; i < inputs.length; i++) {
            transfers.push(inputs[i]);
        }
    }
    function getTransferCount() public view returns (uint) {
        return transfers.length;
    }
    function getTransfers(uint from, uint count) public view returns (Transfer[] memory) {
        Transfer[] memory _transfers = new Transfer[](count);
        for (uint i = from; i < from + count; i++) {
            _transfers[i] = transfers[i];
        }
        return _transfers;
    }
    function removeAllTransfers() public {
        delete transfers;
    }
}