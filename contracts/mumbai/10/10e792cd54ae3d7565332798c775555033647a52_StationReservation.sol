/**
 *Submitted for verification at polygonscan.com on 2022-09-05
*/

// SPDX-License-Identifier: PUCRS

pragma solidity >= 0.7.3;

contract StationReservation {
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    constructor (){
        clearReservation();
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }

    function clearReservation() public {
        message = "## unreserved ##";
    }

}