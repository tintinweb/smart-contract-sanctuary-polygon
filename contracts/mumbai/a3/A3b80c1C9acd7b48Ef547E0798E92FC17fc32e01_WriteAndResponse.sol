// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract WriteAndResponse {

    struct Note {
        address addr;
        string note;
    }

    mapping (uint => Note) public notes;

    uint256 public  countNotes = 0; 

    function store(
        string calldata _note
    ) external  returns (uint256) {
        uint256 noteId = countNotes;
        notes[countNotes] = Note (msg.sender, _note);
        countNotes++;
        return noteId;
    }

    function getCountNotes() external view returns(uint256) {
        return countNotes;
    }

}