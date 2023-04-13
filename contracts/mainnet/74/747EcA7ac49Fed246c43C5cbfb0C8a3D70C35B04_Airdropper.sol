// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

contract Airdropper {
    function distribute(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) public payable {
        require(addresses.length == amounts.length, "Length mismatch");

        uint256 remaining = msg.value;

        uint256 i;
        for (i; i < addresses.length; ++i) {
            require(remaining >= amounts[i], "Insufficient funds");
            remaining -= amounts[i];

            (bool sent, ) = payable(addresses[i]).call{value: amounts[i]}("");

            require(sent, "Send failed");
        }

        require(remaining == 0, "Balance remaining");
    }
}