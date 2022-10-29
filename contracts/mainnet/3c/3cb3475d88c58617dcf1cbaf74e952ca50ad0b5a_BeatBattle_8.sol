/**
 *Submitted for verification at polygonscan.com on 2022-10-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BeatBattle_8 {
    mapping(address => bool) private _registered;
    uint256 private _counter = 0;

    struct Contestant {
        address _address;
        uint256 number;
        string date;
        string link;
    }

    Contestant[5] public contestants;

    function isRegistered(address _address) public view returns (bool) {
        return _registered[_address];
    }
    
    function GetRegistration() public view returns (bool) {
        return _registered[msg.sender];
    }

    function SetRegistrationTrue(string memory ueDate, string memory ueLink) public {
        require(_counter < 5, "BeatBattle_8::Exceeds maximum contestants");
        require(!_registered[msg.sender], "BeatBattle_8::Contestant exists");
        _registered[msg.sender] = true;
        contestants[_counter] = Contestant(msg.sender, _counter, ueDate, ueLink);
        _counter++;
    }

    function SetRegistrationFalse() public {
        require(_registered[msg.sender], "BeatBattle_8::Not registered");
        delete _registered[msg.sender];
        _counter--;
        for (uint256 i = 0; i < 5; i++) {
            if (contestants[i]._address == msg.sender) {
                delete contestants[i];
                break;
            }
        }
    }

    function GetCounter() public view returns (uint256) {
        return _counter;
    }
}