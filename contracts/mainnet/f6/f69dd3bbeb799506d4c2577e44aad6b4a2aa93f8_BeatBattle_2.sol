/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_2 {
    //declaration of varaibles
    mapping(address=> bool) Registered;
    int Counter=0;

    function GetRegistration() view public returns(bool){
        return Registered[msg.sender];
   }

    function SetRegistrationTrue() public {
        if (Counter < 5 && Registered[msg.sender] == false) {
            Registered[msg.sender] = true;
            Counter++;
        }
    }

    function SetRegistrationFalse() public {
        if (Registered[msg.sender] == true){
            Registered[msg.sender] = false;
            if (Counter>0){
            Counter--;
            }
        }
    }

    function GetCounter() view public returns(int){
        return Counter;
    }

}