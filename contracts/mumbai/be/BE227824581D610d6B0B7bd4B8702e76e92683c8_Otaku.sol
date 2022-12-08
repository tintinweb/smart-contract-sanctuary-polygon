/**
 *Submitted for verification at polygonscan.com on 2022-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Otaku {
  event NewWebtoonCreated(
    bytes32 webtoonId,
    address creatorAddress,
    uint256 webtoonTimestamp,
    string webtoonDataCID
  );

  event NewEpisodeCreated(
    bytes32 episodeId,
    bytes32 webtoonId,
    address creatorAddress,
    uint256 episodeTimestamp,
    string episodeDataCID
  );

  event NewProfileCreated(
    bytes32 profileId,
    address profileAddress,
    uint256 profileTimestamp,
    string profileDataCID
  );

  // Webtoon structure
  struct CreateWebtoon {
    // webtoon ID
    bytes32 webtoonId;
    string webtoonDataCID;
    // Wallet address of the webtoon creator
    address webtoonOwner;
    // Timestamp of when the webtoon has been created
    uint256 webtoonTimestamp;
    // Array of wallet addresses of users who are following the webtoon
    address[] subscribers;
    bytes32[] episodes;
  }

  // Profile structure
  struct CreateProfile {
    bytes32 profileId;
    string profileDataCID;
    address profileOwner;
    uint256 profileTimestamp;
  }

  // Episode structure
  struct CreateEpisode {
    // Episode ID
    bytes32 episodeId;
    // Webtoon id to which it belongs
    bytes32 webtoonId;
    string episodeDataCID;
    // Wallet address of the webtoon creator
    address episodeOwner;
    // Timestamp of when the episode has been created
    uint256 episodeTimestamp;
  }
  // Allow us to lookup webtoons by ID
  mapping(bytes32 => CreateWebtoon) public idToWebtoon;
  mapping(bytes32 => CreateProfile) public idToProfile;
  mapping(bytes32 => CreateEpisode) public idToEpisode;

  /* *
   * - Creates a new webtoon.
   * @param {uint256} webtoonTimestamp: timestamp in ms of when the webtoon has been created
   * @param {string} webtoonDataCID: reference to the IPFS hash containing the webtoon info
   * */
  function createNewWebtoon(
    uint256 webtoonTimestamp,
    string calldata webtoonDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an webtoonID based on other things passed in to generate a hash
    // generates a unique webtoonID by hashing together the values we passed
    bytes32 webtoonId = keccak256(abi.encodePacked(msg.sender, address(this), webtoonTimestamp));

    // arrays to track webtoon attendees
    address[] memory subscribers;
    bytes32[] memory episodes;

    // Creates a new CreateWebtoon struct and adds it to the idToWebtoon mapping
    idToWebtoon[webtoonId] = CreateWebtoon(
      webtoonId,
      webtoonDataCID,
      msg.sender,
      webtoonTimestamp,
      subscribers,
      episodes
    );
    emit NewWebtoonCreated(webtoonId, msg.sender, webtoonTimestamp, webtoonDataCID);
  }

  /* *
   * - Creates a new webtoon.
   * @param {uint256} webtoonTimestamp: timestamp in ms of when the webtoon has been created
   * @param {string} webtoonDataCID: reference to the IPFS hash containing the webtoon info
   * */
  function createNewProfile(
    uint256 profileTimestamp,
    string calldata profileDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an webtoonID based on other things passed in to generate a hash
    // generates a unique webtoonID by hashing together the values we passed
    bytes32 profileId = keccak256(abi.encodePacked(msg.sender, address(this), profileTimestamp));

    // Creates a new CreateWebtoon struct and adds it to the idToWebtoon mapping
    idToProfile[profileId] = CreateProfile(
      profileId,
      profileDataCID,
      msg.sender,
      profileTimestamp
    );
    emit NewProfileCreated(profileId, msg.sender, profileTimestamp, profileDataCID);
  }

  /* *
   * - Creates a new episode.
   * @param {uint256} episodeTimestamp: timestamp in ms of when the webtoon has been created
   * @param {string} webtoonDataCID: reference to the IPFS hash containing the webtoon info
   * */
  function createNewEpisode(
    bytes32 webtoonId,
    uint256 episodeTimestamp,
    string calldata episodeDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an episodeID based on other things passed in to generate a hash
    // generates a unique episodeID by hashing together the values we passed
    CreateWebtoon storage myWebtoon = idToWebtoon[webtoonId];
    bytes32 episodeId = keccak256(abi.encodePacked(msg.sender, address(this), episodeTimestamp, webtoonId));

    // require that msg.sender isn't already in myEvent.confirmedRSVPs AKA hasn't already RSVP'd
    for (uint8 i = 0; i < myWebtoon.episodes.length; i++) {
      require(myWebtoon.episodes[i] != episodeId, 'ALREADY ADDED TO WEBTOON');
    }

    // Creates a new CreateEpisode struct and adds it to the idToEpisode mapping
    idToEpisode[episodeId] = CreateEpisode(
      episodeId,
      webtoonId,
      episodeDataCID,
      msg.sender,
      episodeTimestamp
    );

    myWebtoon.episodes.push(episodeId);
    emit NewEpisodeCreated(episodeId, webtoonId, msg.sender, episodeTimestamp, episodeDataCID);
  }

 
}