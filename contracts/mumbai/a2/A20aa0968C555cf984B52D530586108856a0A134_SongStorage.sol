//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./SharedDataStructures.sol";

contract SongStorage {
    SharedDataStructures.Song[] public songs;
    mapping(uint256 => address) public songToOwner;
    mapping(address => int256) public songOwnerCount;

    //@notice event for when a new song is made
    event NewSongCreated(string name, uint256 id, uint256 bpm);
    event SongEdited(string name, uint256 id);
    event SongDeleted(string name, uint256 id);
    event SongMinted(string name, uint256 id);

    function getAllSongs()
        public
        view
        returns (SharedDataStructures.Song[] memory)
    {
        return songs;
    }

    function getSongFromId(uint256 id)
        public
        view
        returns (
            string memory,
            bool,
            bool,
            bytes32[] memory,
            uint32,
            uint32
        )
    {
        require(id < songs.length);

        SharedDataStructures.Song memory currSong = songs[id];

        return (
            currSong.name,
            currSong.isMinted,
            currSong.isDeleted,
            currSong.notes,
            currSong.id,
            currSong.bpm
        );
    }

    function getNumberOfSongs() public view returns (uint32) {
        return uint32(songs.length);
    }

    function _getSongOwner(uint256 id) internal view returns (address) {
        return songToOwner[id];
    }

    modifier onlySongOwner(uint256 id) {
        require(msg.sender == _getSongOwner(id));
        _;
    }

    function _createSong(string memory _name, uint256 bpm)
        internal
        returns (uint256)
    {
        uint32 newId = getNumberOfSongs();
        //@notice set limit on number of songs a person can create to prevent bots etc.
        require(songOwnerCount[msg.sender] < 50);

        songs.push(
            SharedDataStructures.Song({
                name: _name,
                isMinted: false,
                isDeleted: false,
                notes: new bytes32[](0),
                id: newId,
                bpm: uint32(bpm)
            })
        );

        songToOwner[newId] = msg.sender;
        //@notice we don't need to check if this exists due to Solidity's design of mappings
        songOwnerCount[msg.sender]++;

        emit NewSongCreated(_name, newId, bpm);

        return newId;
    }

    //@notice returns the id of the newly created song
    function createNewSong(string memory _name, uint256 bpm)
        public
        returns (uint256)
    {
        return _createSong(_name, bpm);
    }

    //@notice creates a new song like above, but also adds notes to the songs. This is done to optimize gas
    //as opposed to calling createSong and then addNotes
    function createNewSongWithNotes(
        string memory _name,
        uint256 bpm,
        bytes32[] memory newNotes
    ) public returns (uint256) {
        uint256 id = _createSong(_name, bpm);

        SharedDataStructures.Song storage newSong = songs[id];
        newSong.notes = newNotes;

        return id;
    }

    function _addNotesToSong(uint256 id, bytes32[] memory newNotes)
        internal
        returns (bytes32[] memory)
    {
        //@notice ensure we're adding to a song that actually exists
        require(id < songs.length);
        //@notice for now, can only append 50 new notes at a time
        require(newNotes.length < 50);

        SharedDataStructures.Song storage currentSong = songs[id];

        require(!currentSong.isDeleted);
        require(!currentSong.isMinted);

        for (uint256 i = 0; i < newNotes.length; i++) {
            currentSong.notes.push(newNotes[i]);
        }

        emit SongEdited(currentSong.name, id);

        return currentSong.notes;
    }

    //@notice returns the full new song notes
    function addNotes(uint256 id, bytes32[] memory newNotes)
        public
        returns (bytes32[] memory)
    {
        return _addNotesToSong(id, newNotes);
    }

    function deleteSong(uint256 id) public onlySongOwner(id) {
        require(id < songs.length);
        require(!songs[id].isDeleted);

        songs[id].isDeleted = true;
        //@notice we delete the most expensive part of storing a song and bpm
        //which will no longer be used
        delete songs[id].notes;
        delete songs[id].bpm;

        emit SongDeleted(songs[id].name, id);
    }

    function mintSong(uint256 id) public {
        require(id < songs.length);
        require(!songs[id].isDeleted);

        songs[id].isMinted = true;

        emit SongMinted(songs[id].name, id);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SharedDataStructures {
    struct Song {
        string name;
        //@notice, a song that has been minted into an NFT and stored on the Permaweb
        //can no longer be added to it.
        bool isMinted;
        //@notice we keep a record of whether a song has been deleted or not
        //to avoid to having to make an expensive write to adjust ids of existing songs.
        //Instead, we set this boolean variable and delete notes.
        //Any interaction with this song checks that this is not deleted
        bool isDeleted;
        //@notice array of characters that compromise the notes of the song. These
        //get directly synthesized in the client by mapping them to actual notes.
        //We uses bytes32 since each character in a song is of a fixed size, and
        //this is more gas-optimized/cheaper
        bytes32[] notes;
        //@notice we use uint32 for struct packing
        uint32 id;
        uint32 bpm;
    }
}