// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract NoteContract {
    event AddNote(address receipient, uint taskId);
    event DeleteNote(uint taskId, bool isDeleted);

    struct Note {
        uint id;
        string text;
        bool isDeleted;
    }

    Note[] private notes;

    mapping(uint => address) noteToOwner;

    function addNote(string memory _text, bool _isDeleted) external {
        // this function will add notes on the mumbai blockchain
        uint noteId = notes.length;
        notes.push(Note(noteId, _text, _isDeleted));
        noteToOwner[noteId] = msg.sender;
        emit AddNote(msg.sender, noteId);
    }

    function getNotes() public view returns (Note[] memory) {
        // this function will get all the tasks belong to the sender
        Note[] memory temp = new Note[](notes.length);
        uint counter = 0;
        for (uint i = 0; i < notes.length; i++) {
            if (noteToOwner[i] == msg.sender && notes[i].isDeleted == false) {
                temp[counter] = notes[i];
                counter++;
            }
        }
        Note[] memory result = new Note[](counter);
        for (uint i = 0; i < counter; i++) {
            result[i] = temp[i];
        }
        return result;
    }

    function deleteNote(uint _id, bool _isDeleted) external {
        // this function will delete the note
        if (noteToOwner[_id] == msg.sender) {
            notes[_id].isDeleted = _isDeleted;
            emit DeleteNote(_id, _isDeleted);
        }
    }

    constructor() {}
}