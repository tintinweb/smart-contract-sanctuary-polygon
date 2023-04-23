pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

contract LineTweets {
  struct Tweet {
    uint256 id;
    address payable author;
    string message;
    uint256 likes;
    uint256 retweets;
    uint256 createdAt;
  }

  uint256 private nextTweetId = 1;
  mapping(uint256 => Tweet) private tweets;
  mapping(address => uint256[]) private tweetsOf;
  mapping(address => mapping(address => bool)) private followers;
  mapping(address => uint256) private followersCount;

  // uint256 public constant FOLLOW_PRICE = 150;
  // uint256 public constant LIKE_PRICE = 100;
  // uint256 public constant RETWEET_PRICE = 250;

  uint256 public constant FOLLOW_PRICE = 0.0015 ether;
  uint256 public constant LIKE_PRICE = 0.001 ether;
  uint256 public constant RETWEET_PRICE = 0.0025 ether;

  address public treasury;

  event TweetSent(uint256 id, address indexed author, string message, uint256 createdAt);

  constructor() {
    treasury = msg.sender;
  }

  function changeTreasury(address _treasury) external {
    require(msg.sender == treasury, "only treasury can change treasury");
    treasury = _treasury;
  }

  function tweet(string calldata message) external payable {
    tweets[nextTweetId] = Tweet(nextTweetId, payable(msg.sender), message, 0, 0, block.timestamp);
    tweetsOf[msg.sender].push(nextTweetId);
    emit TweetSent(nextTweetId, msg.sender, message, block.timestamp);
    nextTweetId++;
    payable(treasury).transfer(msg.value);
  }

  function like(uint256 _tweetId) external payable {
    require(msg.value == LIKE_PRICE, "must send 100 wei for like");
    Tweet storage t = tweets[_tweetId];
    payable(t.author).transfer(msg.value);
    t.likes++;
  }

  function follow(address payable _followed) external payable {
    require(msg.value == FOLLOW_PRICE, "must send 150 wei to follow");
    followers[_followed][msg.sender] = true;
    followersCount[_followed]++;
    payable(_followed).transfer(msg.value);
  }

  function unfollow(address payable _followed) external payable {
    followers[_followed][msg.sender] = false;
    followersCount[_followed]--;
  }

  function retweet(uint256 _tweetId) external payable {
    require(msg.value == RETWEET_PRICE, "must send 100 wei for retweet");
    Tweet storage t = tweets[_tweetId];
    t.retweets++;
    payable(t.author).transfer(msg.value);
  }

  function getTweets() public view returns (Tweet[] memory) {
    Tweet[] memory _tweets = new Tweet[](nextTweetId - 1);
    uint256 index = 0;
    for (uint256 i = 1; i < nextTweetId; i++) {
      Tweet storage t = tweets[i];
      _tweets[index++] = Tweet(t.id, t.author, t.message, t.likes, t.retweets, t.createdAt);
    }
    return _tweets;
  }

  function getTweetsOf(address _user, uint256 _count) external view returns (Tweet[] memory) {
    uint256[] storage tweetIds = tweetsOf[_user];
    uint256 count = tweetIds.length < _count ? tweetIds.length : _count;
    Tweet[] memory _tweets = new Tweet[](count);
    for (uint256 index = tweetIds.length - count; index < tweetIds.length; index++) {
      Tweet storage t = tweets[tweetIds[index]];
      _tweets[index - (tweetIds.length - count)] = Tweet(t.id, t.author, t.message, t.likes, t.retweets, t.createdAt);
    }
    return _tweets;
  }

  function isFollowing(address _followed) external view returns (bool) {
    return followers[_followed][msg.sender];
  }

  function getFollowersCount(address _followed) external view returns (uint256) {
    return followersCount[_followed];
  }
}