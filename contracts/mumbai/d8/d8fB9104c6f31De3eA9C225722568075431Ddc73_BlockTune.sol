// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract BlockTune{
    address public owner;
   
    uint256 songsCounter;
    constructor() {
        songsCounter = 0;
        owner = msg.sender;
    }
  
    struct Song {
        uint256 songID;
        string songName;
        string songImage;
        string musicHash; 
        address payable songArtist; 
    }
    
    
   
    event SongCreated (
        uint256 songID,
        string songName,
        string songImage,
        string musicHash, 
        address payable songArtist );
    
    mapping(uint => Song) public songs;
    uint256[] public songIds;
    function storeSong(string memory songName,address payable songArtist,string memory musicHash,string memory songImage) public
        {
            Song storage newSong = songs[songsCounter];
            newSong.songName=songName;
            newSong.songArtist=songArtist;
            newSong.musicHash=musicHash;
            newSong.songImage=songImage;
            newSong.songID=songsCounter;
            songIds.push(songsCounter);
            emit SongCreated (
                songsCounter,
                songName,
                songImage,
                musicHash, 
                songArtist );
            songsCounter++;
        }

         function getSong(uint _songID)public view returns(Song memory){
                return songs[_songID];
        }

    
}