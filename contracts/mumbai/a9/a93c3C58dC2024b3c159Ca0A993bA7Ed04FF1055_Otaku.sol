/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Otaku {
  event NewMangaCreated(
    bytes32 id,
    address profileAddress,
    uint256 timestamp,
    uint32 status,
    string dataCID
  );

  event NewEpisodeCreated(
    bytes32 id,
    bytes32 mangaId,
    address profileAddress,
    uint256 timestamp,
    string dataCID
  );

  event NewProfileCreated(
    address profileAddress,
    uint256 timestamp,
    string dataCID
  );

  // Manga structure
  struct Manga {
    // manga ID
    bytes32 id;
    // Profile address of the manga creator
    address profileAddress;
    uint256 timestamp;
    // Manga status - 0 (ongoing), 1 (completed)
    uint32 status;
    string dataCID;
    // Timestamp of when the manga has been created
    // Array of wallet addresses of users who are following the manga
    address[] subscribers;
    bytes32[] episodesIds;
  }
  
  struct Episode {
    bytes32 id;
    bytes32 mangaId;
    address profileAddress;
    uint256 timestamp;
    string dataCID;
  }

  // Profile structure
  struct Profile {
    address id;
    uint256 timestamp;
    string dataCID;
    bytes32[] mangaIds;
  }

  // Allow us to lookup manga by id, profiles by address and episodes by id
  mapping(bytes32 => Manga) public manga;
  mapping(address => Profile) public profiles;
  mapping(bytes32 => Episode) public episodes;
 
  /* *
   * - Creates a new manga.
   * @param {address} profileAddress: address of the profile creator
   * @param {uint256} timestamp: timestamp in ms of when the manga has been created
   * @param {string} dataCID: reference to the IPFS hash containing the manga info
   * */
  function createManga(
    address profileAddress,
    uint256 timestamp,
    string calldata dataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // require profile exits to create new manga
    //require(profiles[profileAddress].length > 0, 'PROFILE DOES NOT EXIST');

    Profile storage profile = profiles[profileAddress];
    // generate an mangaID based on other things passed in to generate a hash
    // generates a unique mangaID by hashing together the values we passed
    bytes32 id = keccak256(abi.encodePacked(msg.sender, address(this), timestamp));
    uint32 status = 0;

    // arrays to track manga attendees
    address[] memory subscribers;
    bytes32[] memory episodesIds;

    // Creates a new CreateManga struct and adds it to the mangas mapping
    manga[id] = Manga(
      id,
      msg.sender,
      timestamp,
      status,
      dataCID,
      subscribers,
      episodesIds
    );

    profile.mangaIds.push(id);
    emit NewMangaCreated(id, msg.sender, timestamp, status, dataCID);
  }

  /* *
   * - Creates a new episode.
   * @param {bytes32} mangaId: manga id to which it belongs
   * @param {uint256} episodeTimestamp: timestamp in ms of when the episode has been created
   * @param {string} episodeDataCID: reference to the IPFS hash containing the episode info
   * */
  function createEpisode(
    bytes32 mangaId,
    uint256 timestamp,
    string calldata dataCID
  ) external {
    bytes32 id = keccak256(abi.encodePacked(msg.sender, address(this), timestamp));

    Manga storage _manga = manga[mangaId];
    for (uint8 i = 0; i < _manga.episodesIds.length; i++) {
      require(_manga.episodesIds[i] != id, 'ALREADY ADDED');
    }
    _manga.episodesIds.push(id);
    // Creates a new CreateEpisode struct and adds it to the episodes mapping
    episodes[id] = Episode(
      id,
      mangaId,
      msg.sender,
      timestamp,
      dataCID
    );
    emit NewEpisodeCreated(id, mangaId, msg.sender, timestamp, dataCID);
  }
    

  /* *
   * - Creates a new profile.
   * @param {uint256} timestamp: timestamp in ms of when the profile has been created
   * @param {string} dataCID: reference to the IPFS hash containing the profile info
   * */
  function createProfile(
    uint256 timestamp,
    string calldata dataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an mangaID based on other things passed in to generate a hash
    bytes32[] memory mangaIds;

    // Creates a new CreateManga struct and adds it to the idToManga mapping
    profiles[msg.sender] = Profile(
      msg.sender,
      timestamp,
      dataCID,
      mangaIds
    );
    emit NewProfileCreated(msg.sender, timestamp, dataCID);
  }

  /** 
  * @dev Fetch all data of a profile
  * @return _profile Profile
  */
  function getProfileByAddress(address profileAddress) view external returns(Profile memory _profile){
    return profiles[profileAddress];
  }

  /** 
  * @dev Fetch all mangas of a profile
  * @return _profileManga Array of manga
  */
  function getMangaByProfile(address profileAddress) view external returns(Manga[] memory){
    bytes32[] memory mangaIds = profiles[profileAddress].mangaIds;
    Manga[] memory _profileManga = new Manga[](mangaIds.length);
    for (uint i = 0; i < mangaIds.length; i++) {
      _profileManga[i] = manga[mangaIds[0]];
    }
    return _profileManga;
  }

  /** 
  * @dev Fetch all episodes of a manga
  * @return _mangaEpisodes Array of episodes
  */
  function getMangaEpisodes(bytes32 mangaId) view external returns(Episode[] memory){
    bytes32[] memory episodesIds = manga[mangaId].episodesIds;
    Episode[] memory _mangaEpisodes = new Episode[](episodesIds.length);
    for (uint i = 0; i < episodesIds.length; i++) {
      _mangaEpisodes[i] = episodes[episodesIds[0]];
    }
    return _mangaEpisodes;
  }
 
}