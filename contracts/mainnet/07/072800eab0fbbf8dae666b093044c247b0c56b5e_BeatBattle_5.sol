/**
 *Submitted for verification at polygonscan.com on 2022-10-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_5 {
    //declaration of varaibles
    mapping(address=> bool) Registered;
    uint Counter=0;

    struct Contestant{
        uint Number;
        string ID;
        string Date;
        string Link;
    }
  
    Contestant[5] public Contestants;

    function GetRegistration() view public returns(bool){
        return Registered[msg.sender];
    }

    function SetRegistrationTrue(string calldata UEID, string calldata UEDate, string calldata UELink) public {
        if (Counter < 5 && Registered[msg.sender] == false) {
            Registered[msg.sender] = true;

            Contestants[Counter].ID=UEID;
            Contestants[Counter].Date=UEDate;
            Contestants[Counter].Link=UELink;

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

    
    function GetCounter() view public returns(uint){
        return Counter;
    }
}