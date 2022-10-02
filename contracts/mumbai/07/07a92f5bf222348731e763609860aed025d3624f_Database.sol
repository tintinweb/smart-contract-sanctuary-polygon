/**
 *Submitted for verification at polygonscan.com on 2022-10-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
                                   
contract Database {
  mapping(address => string) public albums;
  mapping(address => string[]) public songs;

  constructor() {}

  event RegisterAlbum(string name, address indexed contractAddress);
  event AddSongToAlum(string name, string album_name, address indexed contractAddress);
  event UpdateSongOnAlbum(string name, uint index, string album_name, address indexed contractAddress);

  function registerAlbum(string calldata name, address contractAddress) external {
    require(bytes(name).length !=  0, "Invalid album name");
    albums[contractAddress] = name;
  }

  function addSongsToAlbum (string[] calldata names, address contractAddress) external {
    uint256 len = names.length;
    for(uint i = 0 ;i < len ; i ++) {
      require(bytes(names[i]).length !=  0, "Invalid song name");
      songs[contractAddress].push(names[i]);
      emit AddSongToAlum(names[i], albums[contractAddress], contractAddress);
    }
  }

  function editSongOnAlbum (uint256 index, string calldata newName, address contractAddress) external {
    require(index < songs[contractAddress].length, "Song not exist");
    songs[contractAddress][index] = newName;
    emit UpdateSongOnAlbum(newName, index, albums[contractAddress], contractAddress);
  }

  function getSongsInAlbum (address contractAddress) public view returns(string[] memory) {
    return songs[contractAddress];
  }
}