// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

import "./interfaces/ISocialNetwork.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract SocialNetwork is ISocialNetwork {
    using Counters for Counters.Counter;
    Counters.Counter private _tweetIds;

    struct TweetData {
        string message;
        uint256 totalLike;
        uint256 time;
        address posterAddr;
    }

    // ツイートを格納するmapping変数
    mapping(uint256 => TweetData) public tweetDataMap;
    // ツイートに対していいねしたかどうかを格納するmapping変数
    mapping(address => mapping(uint256 => bool)) public likedTweet;

    event TweetPosted(address indexed posterAddr, string message, uint256 time, uint256 newId);
    event LikeToggled(address indexed sender, uint256 postId,bool isLike);

    function post(string memory _message) external {
        uint256 newId = _tweetIds.current();
        tweetDataMap[newId] = TweetData(_message, 0, block.timestamp, msg.sender);

        _tweetIds.increment();
        emit TweetPosted(msg.sender, _message, block.timestamp, newId);
    }

    function getLastPostId() public view returns (uint256) {
        return _tweetIds.current();
    }

    function getPost(uint256 _postId)
        public
        view
        returns (
            string memory message,
            uint256 totalLikes,
            uint256 time
        )
    {
        TweetData memory tweetData;
        uint256 lastId = _tweetIds.current();
        require(_postId <= lastId, "non existent id");
        tweetData = tweetDataMap[_postId];

        return (tweetData.message, tweetData.totalLike, tweetData.time);
    }

    function like(uint256 _postId) external {
        require(!likedTweet[msg.sender][_postId], "already liked");

        likedTweet[msg.sender][_postId] = true;
        tweetDataMap[_postId].totalLike ++;
        emit LikeToggled(msg.sender, _postId, true);
    }

    function unlike(uint256 _postId) external{
        require(likedTweet[msg.sender][_postId], "didn't like...");

        likedTweet[msg.sender][_postId] = false;
        tweetDataMap[_postId].totalLike --;
        emit LikeToggled(msg.sender, _postId, false);
    }

    // More functions
    function getAllPost() public view returns(TweetData [] memory, bool[] memory){
        uint256 lastPostId = getLastPostId();
        TweetData[] memory tweetData = new TweetData[](lastPostId);
        bool[] memory tweetLikedStatus = new bool[](lastPostId);
        for(uint256 i=0; i<lastPostId; i++){
            TweetData memory tweet = tweetDataMap[i];
            tweetData[i] = TweetData({
                message: tweet.message,
                totalLike: tweet.totalLike,
                time: tweet.time,
                posterAddr: tweet.posterAddr
            });

            tweetLikedStatus[i] = likedTweet[msg.sender][i];
        }
        return (tweetData, tweetLikedStatus);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface ISocialNetwork {
    // Post a message.
    // This posted data must be accessible by the post's id from the getter function that follows below.
    function post(string memory _message) external;

    // Returns id of the last post.
    function getLastPostId() external view returns (uint256);

    // Returns the data of the post by its id.
    function getPost(uint256 _postId)
        external
        view
        returns (
            string memory message,
            uint256 totalLikes,
            uint256 time
        );

    // Like a post by its id.
    function like(uint256 _postId) external;

    // Unlike a post by its id.
    function unlike(uint256 _postId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}