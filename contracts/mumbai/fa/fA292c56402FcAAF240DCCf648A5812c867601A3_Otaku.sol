/**
 *Submitted for verification at polygonscan.com on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Otaku {
  event NewMangaCreated(
    bytes32 mangaId,
    address profileId,
    uint256 mangaTimestamp,
    uint32 mangaStatus,
    string mangaDataCID
  );

  event NewEpisodeCreated(
    bytes32 mangaId,
    bytes32 episodeId,
    address profileId,
    uint256 episodeTimestamp,
    string episodeDataCID
  );

  event NewProfileCreated(
    address profileId,
    uint256 profileTimestamp,
    string profileDataCID
  );

  // Manga structure
  struct Manga {
    // manga ID
    bytes32 mangaId;
    // Wallet address(profileId) of the manga creator
    address profileId;
    uint256 mangaTimestamp;
    // Manga status - 0 (ongoing), 1 (completed)
    uint32 mangaStatus;
    string mangaDataCID;
    // Timestamp of when the manga has been created
    // Array of wallet addresses of users who are following the manga
    address[] mangaSubscribers;
    bytes32[] mangaEpisodes;
  }
  
  struct Episode {
    bytes32 mangaId;
    bytes32 episodeId;
    address profileId;
    uint256 episodeTimestamp;
    string episodeDataCID;
  }

  // Profile structure
  struct Profile {
    address profileId;
    uint256 profileTimestamp;
    string profileDataCID;
    bytes32[] profileMangas;
  }

  // Allow us to lookup mangas by ID
  mapping(bytes32 => Manga) public mangas;
  mapping(address => Profile) public profiles;
  mapping(bytes32 => Episode) public episodes;

  /* *
   * - Creates a new manga.
   * @param {uint256} mangaTimestamp: timestamp in ms of when the manga has been created
   * @param {string} mangaDataCID: reference to the IPFS hash containing the manga info
   * */
  function createNewManga(
    address profileId,
    uint256 mangaTimestamp,
    string calldata mangaDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // require profile exits to create new manga
    require(profiles[profileId].profileId == profileId, 'PROFILE DOES NOT EXIST');

    Profile storage profile = profiles[profileId];
    // generate an mangaID based on other things passed in to generate a hash
    // generates a unique mangaID by hashing together the values we passed
    bytes32 mangaId = keccak256(abi.encodePacked(msg.sender, address(this), mangaTimestamp));
    uint32 mangaStatus = 0;

    // arrays to track manga attendees
    address[] memory subscribers;
    bytes32[] memory mangaEpisodes;

    // Creates a new CreateManga struct and adds it to the mangas mapping
    mangas[mangaId] = Manga(
      mangaId,
      msg.sender,
      mangaTimestamp,
      mangaStatus,
      mangaDataCID,
      subscribers,
      mangaEpisodes
    );

    profile.profileMangas.push(mangaId);
    emit NewMangaCreated(mangaId, msg.sender, mangaTimestamp, mangaStatus, mangaDataCID);
  }

  /* *
   * - Creates a new episode.
   * @param {bytes32} mangaId: manga id to which it belongs
   * @param {uint256} episodeTimestamp: timestamp in ms of when the episode has been created
   * @param {string} episodeDataCID: reference to the IPFS hash containing the episode info
   * */
  function createNewEpisode(
    bytes32 mangaId,
    uint256 episodeTimestamp,
    string calldata episodeDataCID
  ) external {
    bytes32 episodeId = keccak256(abi.encodePacked(msg.sender, address(this), episodeTimestamp));

    Manga storage manga = mangas[mangaId];
    for (uint8 i = 0; i < manga.mangaEpisodes.length; i++) {
      require(manga.mangaEpisodes[i] != episodeId, 'ALREADY ADDED');
    }
    manga.mangaEpisodes.push(episodeId);
    // Creates a new CreateEpisode struct and adds it to the episodes mapping
    episodes[episodeId] = Episode(
      mangaId,
      episodeId,
      msg.sender,
      episodeTimestamp,
      episodeDataCID
    );
    emit NewEpisodeCreated(mangaId, episodeId, msg.sender, episodeTimestamp, episodeDataCID);
  }

  /* *
   * - Creates a new profile.
   * @param {uint256} profileTimestamp: timestamp in ms of when the profile has been created
   * @param {string} profileDataCID: reference to the IPFS hash containing the profile info
   * */
  function createNewProfile(
    uint256 profileTimestamp,
    string calldata profileDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an mangaID based on other things passed in to generate a hash
    bytes32[] memory profileMangas;

    // Creates a new CreateManga struct and adds it to the idToManga mapping
    profiles[msg.sender] = Profile(
      msg.sender,
      profileTimestamp,
      profileDataCID,
      profileMangas
    );
    emit NewProfileCreated(msg.sender, profileTimestamp, profileDataCID);
  }

  /** 
  * @dev Fetch all of the manga that the profile uploaded
  * @return _mangaUploaded Array of manga
  */
  function getUploadedMangaByProfile(address profileId) view external returns(Manga[] memory _mangaUploaded){
    bytes32[] memory mangaIds = profiles[profileId].profileMangas;
    
    for(uint i=0; i < mangaIds.length; i++){
      _mangaUploaded[i] = mangas[mangaIds[i]];
    }

    return _mangaUploaded;
  }
 
}