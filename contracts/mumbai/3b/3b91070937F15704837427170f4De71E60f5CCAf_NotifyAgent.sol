/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.17;

contract NotifyAgent {

     event SendNotification(address agent);

    function notify(address agent) public  {
        emit SendNotification(agent);
    }
}