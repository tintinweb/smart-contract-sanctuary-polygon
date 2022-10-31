/**
 *Submitted for verification at polygonscan.com on 2022-10-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_12 {

    mapping(address=> uint256) votingTickets;

    uint256 private _counter = 0;

    struct Contestant {
        bool regestration;
        address _address;
        uint256 number;
        string date;
        string link;
        uint256 votes;
    }

    Contestant[5] public contestants;

    function GetRegistration() public view returns (bool value) {
        for (uint256 i=0; i<5; i++){
            if (msg.sender == contestants[i]._address){
                i=5;
                return value=true;
            }        
        }
        return value=false;
    }

    function SetRegistrationTrue(string memory ueDate, string memory ueLink) public {
        require(_counter < 5, "BeatBattle_12::Exceeds maximum contestants");
        for (uint256 i=0; i<5; i++){
            if(contestants[i].regestration == false){
                contestants[_counter].regestration = true;
                contestants[_counter]._address = msg.sender;
                contestants[_counter].number = _counter;
                contestants[_counter].date = ueDate;
                contestants[_counter].link = ueLink;
                _counter++;
                break;
            }
        }
    }

    function SetRegistrationFalse() public {
        for (uint256 i = 0; i < 5; i++) {
            if (contestants[i]._address == msg.sender) {
                delete contestants[i];
                _counter--;
                break;
            }
        }
    }

    function GetCounter() public view returns (uint256) {
        return _counter;
    }


    function GetContestants() public view returns (
        address address1, address address2, address address3, address address4, address address5,
        uint256 votes1, uint256 votes2, uint256 votes3, uint256 votes4, uint256 votes5
        ) {
               
        address1=contestants[0]._address;
        address2=contestants[1]._address;
        address3=contestants[2]._address;
        address4=contestants[3]._address;
        address5=contestants[4]._address;

        votes1=contestants[0].votes;
        votes2=contestants[1].votes;
        votes3=contestants[2].votes;
        votes4=contestants[3].votes;
        votes5=contestants[4].votes;

        return (
            address1, address2, address3, address4, address5,
            votes1, votes2, votes3, votes4, votes5
            );
    }


// لو أنت مشارك يبقي ملكش تدي صوت
// طب لو حد إدي أصوات وبعدين أشترك، هل ندور علي الأصوات دي ونخليها باطلة

    function Vote (address faddress) public {     
        
        if (votingTickets[msg.sender] <2){          
            for (uint256 i = 0; i < 5; i++) {
                if (contestants[i]._address == faddress) {
                    votingTickets[msg.sender]++; 
                    contestants[i].votes++;
                    break;
                }
            }
        }
    }
}