// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract TuneAIv1 {
    /*
    New song event
    @param artist
    @param title
    @param songCID
    @param coverCID
     */
    event NewSong(
        address indexed owner,
        string artist,
        string title,
        string songCID,
        string coverCID
    );

    /*
      Track is a struct that declares the necessary values for a song
      @param owner: the address that uploaded the song
      @param artist: the artist name
      @param title: the song title
      @param ipfsURL: the IPFS url of the audio file 
      @param albumCover: the IPFS url for the album cover art
     */

    struct Track {
        address owner;
        string artist;
        string title;
        string songCID;
        string coverCID;
    }

    Track[] public tracks; // track all the Track's

    /*
    Function to upload a song
    @param _artist: artist name
    @param _title: song title
    @param _ipfsURL: the IPFS url for the song to play
    @param _albumCover: the IPFS url for the album cover
   */
    function uploadTrack(
        string memory _artist,
        string memory _title,
        string memory _songCID,
        string memory _coverCID
    ) external {
        string memory songIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _songCID)
        );
        string memory coverIPFSURL = string(
            abi.encodePacked("https://ipfs.io/ipfs/", _coverCID)
        );
        Track memory newTrack = Track(
            msg.sender,
            _artist,
            _title,
            songIPFSURL,
            coverIPFSURL
        );
        tracks.push(newTrack);
        emit NewSong(msg.sender, _artist, _title, songIPFSURL, coverIPFSURL);
    }

    /*
    Function to upload a song
    @param _id: the song id
   */
    function getTrack(
        uint256 _id
    )
        external
        view
        returns (string memory, string memory, string memory, string memory)
    {
        require(_id < tracks.length, "Invalid index");
        Track memory track = tracks[_id];
        return (track.artist, track.title, track.songCID, track.coverCID);
    }

    /*
    Function to view track IDs by a specific owner
    @param _owner: the address of who uploaded the song
   */
    function getTracksByOwner(
        address _owner
    ) external view returns (Track[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tracks.length; i++) {
            if (tracks[i].owner == _owner) {
                count++;
            }
        }
        Track[] memory result = new Track[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tracks.length; i++) {
            if (tracks[i].owner == _owner) {
                result[index] = tracks[i];
                index++;
            }
        }
        return result;
    }
}