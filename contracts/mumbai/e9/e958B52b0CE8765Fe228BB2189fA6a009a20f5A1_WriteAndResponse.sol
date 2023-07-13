// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract WriteAndResponse {

    struct Note {
        address addr;
        string note;
    }

    mapping (uint => Note) public notes;

    uint256 public  countNotes = 0; 

    event onStoreNote(
        address indexed _from,
        uint256 indexed _noteId,
        string _note
    );

    function store(
        string calldata _note
    ) external  returns (uint256) {
        uint256 noteId = countNotes;
        notes[countNotes] = Note (msg.sender, _note);
        countNotes++;
        return noteId;
    }

    function store2(
        string calldata _note
    ) external  {
        uint256 noteId = countNotes;
        notes[countNotes] = Note (msg.sender, _note);
        countNotes++;
        emit onStoreNote(
            msg.sender,
            noteId,
            _note
        );
    }

    function getCountNotes() external view returns(uint256) {
        return countNotes;
    }

}