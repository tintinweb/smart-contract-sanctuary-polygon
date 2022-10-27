/**
 *Submitted for verification at polygonscan.com on 2022-10-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_0 {
    //declaration of varaibles
    mapping(address=> bool) Registered;
    
    function GetRegistration() view public returns(bool){
        return Registered[msg.sender];
    }

    function SetRegistrationTrue() public {
        Registered[msg.sender] = true;
    }

    function SetRegistrationFalse() public {
        Registered[msg.sender] = false;
    }

}