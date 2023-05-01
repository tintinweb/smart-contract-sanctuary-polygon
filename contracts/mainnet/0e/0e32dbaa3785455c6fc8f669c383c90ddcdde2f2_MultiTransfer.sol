/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

// SPDX-License-Identifier: GPL-3.0
// GitHub: @livingcorpse25

pragma solidity >=0.8.2 <0.9.0;

contract MultiTransfer {
    constructor() {}

    function safeTransferFunds(address[] calldata _addresses, uint[] calldata _amounts) public payable {
        uint _total = 0;
        uint _valueSent = 0;

        require(_addresses.length == _amounts.length, "The array of adresses must be the same length as the array of amounts");

        for (uint i = 0; i < _amounts.length; i++) {
            _total += _amounts[i];
        }

        require(_total <= msg.value, "Insufficient funds");

        for (uint i = 0; i < _addresses.length; i++) {
            (bool sent, ) = _addresses[i].call{value: _amounts[i]}("");

            require(sent, "Unable to send funds to one of the wallets");

            _valueSent += _amounts[i];
        }

        if (_valueSent < msg.value) {
            (bool sent, ) = address(msg.sender).call{value: msg.value - _valueSent}("");

            require(sent, "Unable to send funds back to the sender");
        }
    }
}