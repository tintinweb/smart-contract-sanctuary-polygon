/**
 *Submitted for verification at polygonscan.com on 2023-07-06
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SendMany {
    event NativeTransfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    function sendMany(
        address payable[] calldata _addresses
    ) public payable returns (uint256) {
        uint256 amountPerAddress = msg.value / _addresses.length;
        require(amountPerAddress > 0, "value not enough");
        require(
            amountPerAddress * _addresses.length == msg.value,
            "value cannot split into n addresses"
        );
        uint256 i;

        for (i = 0; i < _addresses.length; i++) {
            (bool sent, ) = _addresses[i].call{value: amountPerAddress}("");
            if (!sent) {
                return i;
            }
            emit NativeTransfer(msg.sender, _addresses[i], amountPerAddress);
        }

        return i;
    }
}