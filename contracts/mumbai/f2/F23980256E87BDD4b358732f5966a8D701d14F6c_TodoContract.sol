// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract TodoContract {
    struct Notes {
        uint256 id;
        address owner;
        string note;
        bool completed;
    }

    event addNotes(address owner, uint256 id);
    event deleteNotes(uint256 _id, bool isDeleted);

    Notes[] private notes;

    mapping(uint256 => address) notesMapping;

    modifier onlyOwner(uint256 _id) {
        require(
            notes[_id - 1].owner == msg.sender,
            "Only owner can perform this action"
        );
        _;
    }

    function addNote(string memory _note) external {
        uint256 id = notes.length + 1;
        notes.push(Notes(id, msg.sender, _note, false));
        notesMapping[id] = msg.sender;
        emit addNotes(msg.sender, id);
    }

    function getNotes() external view returns (Notes[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == msg.sender) {
                count++;
            }
        }
        Notes[] memory myNotes = new Notes[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == msg.sender) {
                myNotes[index] = notes[i];
                index++;
            }
        }
        return myNotes;
    }

    function getNumberOfNotes() external view returns (uint256) {
        address owner = msg.sender;
        uint256 count = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner) {
                count++;
            }
        }
        return count;
    }

    function getNotesWithId(uint256 _id) external view returns (Notes memory) {
        Notes storage note = notes[_id - 1];
        require(
            note.owner == msg.sender,
            "Only note owner can access this note"
        );
        return note;
    }

    function toggleComplete(uint256 _id) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == msg.sender,
            "Only note owner can toggle completeness of this note"
        );
        note1.completed = !note1.completed;
    }

    function getCompletedNotes() external view returns (Notes[] memory) {
        address owner = msg.sender;
        Notes[] memory temp = new Notes[](notes.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == true) {
                temp[counter] = notes[i];
                counter++;
            }
        }
        Notes[] memory result = new Notes[](counter);
        for (uint256 i = 0; i < counter; i++) {
            result[i] = temp[i];
        }
        return result;
    }

    function getIncompleteNotes() external view returns (Notes[] memory) {
        address owner = msg.sender;
        uint256 counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == false) {
                counter++;
            }
        }
        Notes[] memory result = new Notes[](counter);
        counter = 0;
        for (uint256 i = 0; i < notes.length; i++) {
            if (notes[i].owner == owner && notes[i].completed == false) {
                result[counter] = notes[i];
                counter++;
            }
        }
        return result;
    }

    function updateNotes(uint256 _id, string memory content) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == msg.sender,
            "Only note owner can update this note"
        );
        note1.note = content;
    }

    function deleteNote(uint256 _id) external {
        Notes storage note1 = notes[_id - 1];
        require(
            note1.owner == msg.sender,
            "Only note owner can delete this note"
        );
        delete notes[_id - 1];
    }
}