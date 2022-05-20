// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Notes {
    // main place for the Notes
    mapping(uint256 => mapping(bytes32 => string)) private _notes;
    // list of available notes of the user
    mapping(address => uint256[]) private _usrNotes;

    uint256 public totalNotes;

    event StoreNotes(address indexed nerd, uint256 isbn);

    // store new notes
    function Store(string memory secret_, string memory notes_) public virtual {
        uint256 isbn = calculatePair(secret_, notes_);
        bytes32 serial = keccak256(abi.encodePacked(secret_));
        _notes[isbn][serial] = notes_;

        _usrNotes[msg.sender].push(isbn);
        totalNotes += 1;

        emit StoreNotes(msg.sender, isbn);
    }

    // read the notes
    function Read(uint256 isbn, string memory secret_)
        public
        view
        virtual
        returns (string memory)
    {
        bytes32 serial = keccak256(abi.encodePacked(secret_));
				return _notes[isbn][serial];
    }

		// total of notes by the author
		function totalNotesFromAuthor(address nerd) public view virtual returns (uint256[] memory) {
			return _usrNotes[nerd];
		}

    // calculate `secret_` and `notes_` into uint256
    function calculatePair(string memory secret_, string memory notes_)
        internal
        virtual
        returns (uint256)
    {
        bytes32 b1 = keccak256(abi.encodePacked(secret_));
        bytes32 b2 = keccak256(abi.encodePacked(notes_));
        uint256 u1 = uint256(b1);
        uint256 u2 = uint256(b2);

        uint256 d = block.timestamp;
        uint256 r;

        if (u1 == u2) {
            u1 = u1 - d;
        }

        if (u1 < u2) {
            r = (u2 - u1) + d;
        } else {
            r = (u2 - u1) - d;
        }

        return r;
    }
}