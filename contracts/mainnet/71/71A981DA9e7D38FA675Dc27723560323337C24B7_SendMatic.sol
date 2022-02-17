//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SendMatic {
    function sendViaCall(address[] calldata _recipients, uint256[] calldata _amounts)
        external
        payable
    {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.

        for (uint256 i = 0; i < _recipients.length; i++) {
            (bool sent, ) = _recipients[i].call{value: _amounts[i]}("");
            require(sent, "Failed to send Ether");
        }
    }
}