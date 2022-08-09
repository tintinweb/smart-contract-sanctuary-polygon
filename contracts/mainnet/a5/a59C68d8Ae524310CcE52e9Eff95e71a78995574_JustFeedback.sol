// SPDX-License-Identifier: MIT

pragma solidity 0.8.8;

contract JustFeedback {
  address public manager;

  struct Post {
    uint256 id;
    uint256 createdDate;
    address author;
    string text;
    uint256 upVotesCount;
    uint256 downVotesCount;
  }
  mapping(uint256 => mapping(address => bool)) public votesUp;
  mapping(uint256 => mapping(address => bool)) public votesDown;

  mapping(uint256 => Post) public posts;
  uint256 public postIndex;
  mapping(address => string) public addressToUsername;
  mapping(string => address) public usernameToAddress;
  address emptyAddress;
  mapping(address => uint256[]) public addressToPostIds;
  mapping(uint256 => bool) public transactionIds;

  event CreatePostEvent(
    address _msgSender,
    uint256 _id,
    uint256 _createdDate,
    string _text,
    uint256 _upVotesCount,
    uint256 _downVotesCount
  );
  event DeletePostEvent(address _msgSender, uint256 _id);
  event VoteEvent(
    address _msgSender,
    uint256 _postId,
    uint256 _upVotesCount,
    uint256 _downVotesCount
  );
  event UpdateUsernameEvent(address _msgSender, string _text);

  event AddTransactionIdEvent(uint256 _transactionId);

  constructor() {
    manager = msg.sender;
    postIndex = 0;
    emptyAddress = 0x0000000000000000000000000000000000000000;
  }

  function createPost(string memory _text) public {
    posts[postIndex].id = postIndex;
    posts[postIndex].createdDate = block.timestamp;
    posts[postIndex].author = msg.sender;
    posts[postIndex].text = _text;
    posts[postIndex].upVotesCount = 0;
    posts[postIndex].downVotesCount = 0;

    addressToPostIds[msg.sender].push(postIndex);

    emit CreatePostEvent(msg.sender, postIndex, block.timestamp, _text, 0, 0);

    postIndex += 1;
  }

  function deleteOwnPost(uint256 _postId) public {
    require(
      msg.sender == posts[_postId].author,
      "only the author can delete his posts"
    );

    delete posts[_postId];

    emit DeletePostEvent(msg.sender, _postId);
  }

  function votePost(uint256 _postId, bool _voteIsTypeUp) public {
    require(posts[_postId].author != emptyAddress, "post not created yet");
    require(posts[_postId].author != msg.sender, "the author cannot vote");
    if (_voteIsTypeUp) {
      require(!votesUp[_postId][msg.sender], "only one upVote for post");
    } else {
      require(!votesDown[_postId][msg.sender], "only one downVote for post");
    }

    if (_voteIsTypeUp) {
      votesUp[_postId][msg.sender] = true;
      posts[_postId].upVotesCount += 1;

      if (votesDown[_postId][msg.sender]) {
        votesDown[_postId][msg.sender] = false;
        posts[_postId].downVotesCount -= 1;
      }
    } else {
      votesDown[_postId][msg.sender] = true;
      posts[_postId].downVotesCount += 1;

      if (votesUp[_postId][msg.sender]) {
        votesUp[_postId][msg.sender] = false;
        posts[_postId].upVotesCount -= 1;
      }
    }

    emit VoteEvent(
      msg.sender,
      _postId,
      posts[_postId].upVotesCount,
      posts[_postId].downVotesCount
    );
  }

  function updateMyUsername(string memory _text) public {
    // no username -> delete
    if (bytes(_text).length == 0) {
      delete usernameToAddress[addressToUsername[msg.sender]];
      delete addressToUsername[msg.sender];
    } else {
      require(
        usernameToAddress[_text] == emptyAddress,
        "username already used"
      );

      // change of username -> delete previous
      if (bytes(addressToUsername[msg.sender]).length != 0) {
        usernameToAddress[addressToUsername[msg.sender]] = emptyAddress;
      }

      usernameToAddress[_text] = msg.sender;
      addressToUsername[msg.sender] = _text;
    }

    emit UpdateUsernameEvent(msg.sender, _text);
  }

  function addTransactionId(uint256 _transactionId) public {
    require(
      msg.sender == manager,
      "only the manager can add new transactionIds"
    );
    require(
      !transactionIds[_transactionId],
      "already saved this transactionId"
    );

    transactionIds[_transactionId] = true;

    emit AddTransactionIdEvent(_transactionId);
  }
}