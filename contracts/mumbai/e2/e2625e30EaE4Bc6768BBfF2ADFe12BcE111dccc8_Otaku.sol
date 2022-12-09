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
    uint32 webtoonStatus,
    string webtoonDataCID
  );

  event NewEpisodeCreated(
    bytes32 episodeId,
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
    // Webtoon status - 0 (ongoing), 1 (completed)
    uint32 webtoonStatus;
    // Array of wallet addresses of users who are following the webtoon
    address[] subscribers;
    bytes32[] episodes;
  }
  
  struct CreateEpisode {
    bytes32 episodeId;
    string episodeDataCID;
    address episodeOwner;
    uint256 episodeTimestamp;
  }

  // Profile structure
  struct CreateProfile {
    bytes32 profileId;
    string profileDataCID;
    address profileOwner;
    uint256 profileTimestamp;
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
    uint32 webtoonStatus = 0;

    // arrays to track webtoon attendees
    address[] memory subscribers;
    bytes32[] memory episodes;

    // Creates a new CreateWebtoon struct and adds it to the idToWebtoon mapping
    idToWebtoon[webtoonId] = CreateWebtoon(
      webtoonId,
      webtoonDataCID,
      msg.sender,
      webtoonTimestamp,
      webtoonStatus,
      subscribers,
      episodes
    );
    emit NewWebtoonCreated(webtoonId, msg.sender, webtoonTimestamp, webtoonStatus, webtoonDataCID);
  }

  /* *
   * - Creates a new episode.
   * @param {uint256} episodeTimestamp: timestamp in ms of when the episode has been created
   * @param {string} episodeDataCID: reference to the IPFS hash containing the episode info
   * */
  function createNewEpisodeWebtoon(
    uint256 episodeTimestamp,
    string calldata episodeDataCID
  ) external {
    // `external` sets the function visibility to external since it is highly performant and saves on gas.

    // generate an episodeID based on other things passed in to generate a hash
    // generates a unique episodeID by hashing together the values we passed
    bytes32 episodeId = keccak256(abi.encodePacked(msg.sender, address(this), episodeTimestamp));

    // Creates a new CreateEpisode struct and adds it to the idToEpisode mapping
    idToEpisode[episodeId] = CreateEpisode(
      episodeId,
      episodeDataCID,
      msg.sender,
      episodeTimestamp
    );
    emit NewEpisodeCreated(episodeId, msg.sender, episodeTimestamp, episodeDataCID);
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
 
}