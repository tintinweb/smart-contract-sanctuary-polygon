// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Tweets {
  address public s_owner;
  uint256 private s_counter;

  struct tweet {
    address user;
    uint256 id;
    string text;
    string media;
  }

  event tweetCreated (
    address user,
    uint256 id,
    string text,
    string media
  );
    
  
  // tweet ids to content
  mapping(uint256 => tweet) s_Tweets;


  constructor() {
    s_counter = 0;
    s_owner = msg.sender;
  }

  function addTweet(
    string memory text,
    string memory media
  ) public payable {
    // preconditions
    require (msg.value == (1 ether), "Please submit 1 Matic");

    // state update
    tweet storage buildTweet = s_Tweets[s_counter];
    buildTweet.text = text;
    buildTweet.media = media;
    buildTweet.user = msg.sender;
    buildTweet.id = s_counter;

    // emit signal
    emit tweetCreated(
      buildTweet.user,
      buildTweet.id,
      buildTweet.text,
      buildTweet.media
    );

    // increment tweet id
    s_counter++;

    // transfer payment to owner address from contract
    payable(s_owner).transfer(msg.value);

  }

  function getTweet(uint256 id) public view returns (
    string memory,
    string memory,
    address
  ) {
    // preconditions
    require (id < s_counter, "tweet id DNE");

    // state query
    tweet storage t = s_Tweets[id];

    // return
    return (t.text, t.media, t.user);
  }
}