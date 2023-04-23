// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract TodoContract {
    struct Notes {
        uint256 id;
        address username;
        string note;
        bool completed;
    }

    event addNotes(address owner, uint256 id);
    event deleteNotes(uint256 _id, bool isDeleted);

    Notes[] private notes;

    mapping(uint256 => address) notesMapping;
    
    function addNote(string memory _note) external {
        uint256 id = notes.length + 1;
        notes.push(Notes(id, msg.sender, _note, false));
        notesMapping[id] = msg.sender;
        emit addNotes(msg.sender, id);
    }

    function getNotes() external view returns (Notes[] memory) {
        return notes;
    }

    function getNumberOfNotes() external view returns (uint256) {
        return notes.length;
    }

    function getNotesWithId(uint256 _id) external view returns (Notes memory) {
        Notes storage note = notes[_id-1];
        return note;
    }

    function toggleComplete(uint256 _id) external {
        Notes storage note1 = notes[_id-1];
        if(note1.completed == true){
            note1.completed = false;
        }else{
            note1.completed = true;
        }
    }

    function updateNotes(uint256 _id, string memory content) external {      
        Notes storage note1 = notes[_id-1];

        note1.note = content;
    }
}