/**
 *Submitted for verification at polygonscan.com on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_10 {
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
        require(_counter < 5, "BeatBattle_10::Exceeds maximum contestants");
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

    function GetContestants(uint i) public view returns (address faddress, string memory fdate, uint256 fvotes) {
        faddress=contestants[i]._address;
        fdate=contestants[i].date;
        fvotes=contestants[i].votes;

        return (faddress,fdate,fvotes);
    }

    function Vote (address faddress) public {
        for (uint256 i = 0; i < 5; i++) {
            if (contestants[i]._address == faddress) {
                contestants[i].votes++;
                break;
            }
        }
    }
}