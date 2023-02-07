/**
 *Submitted for verification at polygonscan.com on 2023-02-07
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT



contract Counter {

    uint public counter;
    address public lastCaller;

    // constructor(address _forwarder) {
    //     _setTrustedForwarder(_forwarder);
    // }

    function versionRecipient() external  pure returns (string memory) {
        return "2.2.1";
    }

    function increment() public {
        counter++;
        lastCaller = msg.sender;
    }
}