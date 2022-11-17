/**
 *Submitted for verification at polygonscan.com on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract NotesManager {
    struct Note {
        string title;
        string description;
    }

    mapping(address => Note[]) private Users;

    function saveNote(
        address _userAddress,
        string calldata _title,
        string calldata _description
    ) external {
        Users[_userAddress].push(
            Note({title: _title, description: _description})
        );
    }

    function getNote(address _userAddress, uint256 _notesIndex)
        external
        view
        returns (Note memory)
    {
        Note storage note = Users[_userAddress][_notesIndex];
        return note;
    }

    function updateNote(
        address _userAddress,
        uint256 _notesIndex,
        string calldata _title,
        string calldata _description
    ) external {
        Users[_userAddress][_notesIndex].title = _title;
        Users[_userAddress][_notesIndex].description = _description;
    }

    function deleteNote(address _userAddress, uint256 _notesIndex) external {
        delete Users[_userAddress][_notesIndex];
    }

    function getNotesCount(address _userAddress)
        external
        view
        returns (uint256)
    {
        return Users[_userAddress].length;
    }

    function getAllNotes(address _userAddress)
        external
        view
        returns (Note[] memory)
    {
        return Users[_userAddress];
    }
}