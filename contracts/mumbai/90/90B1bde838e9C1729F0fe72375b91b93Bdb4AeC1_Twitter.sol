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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";

interface OldTwitter {
    function getTweet(
        uint _id
    ) external view returns (string memory, string memory, address);
}

/**
 * # Features
 * - store the tweets in a mapping of address => Tweet
 * - handle the logic for when we don't receive a pic url
 * - Tweet consist of author, message, imageUrl
 */
contract Twitter {
    Counters.Counter public tweetsCounter;
    address public immutable owner;

    // address 123 post new tweet => addressToTweets[123][addressToCounter[123]] = Tweet => addressToCounter[123]++
    mapping(address => mapping(uint => Tweet)) public addressToTweets;
    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) addressToTweetId;

    struct Tweet {
        string message;
        string imageUrl;
    }

    event TweetCreated(
        address indexed tweeter,
        string tweetMsg,
        string tweetImg
    );

    constructor() {
        owner = msg.sender;
    }

    function postTweet(
        string memory _message,
        string memory _imageUrl
    ) external {
        bool validTweet = bytes(_message).length > 0 ||
            bytes(_imageUrl).length > 0;
        require(validTweet, "tweet must either have a message or imageUrl");

        uint currIndex = addressToTweetId[msg.sender].current();
        addressToTweetId[msg.sender].increment();
        addressToTweets[msg.sender][currIndex] = Tweet({
            message: _message,
            imageUrl: _imageUrl
        });

        emit TweetCreated({
            tweeter: msg.sender,
            tweetMsg: _message,
            tweetImg: _imageUrl
        });
    }

    // * Modifers
    modifier OnlyOwner() {
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    // * Contract migration of data available in https://mumbai.polygonscan.com/address/0x4B0a24db3a6e5F5247a7868C02230f8F1ba0c9D1
    function migrateData(address oldTwitterAdx) external OnlyOwner {
        OldTwitter oldTwitterInstance = OldTwitter(oldTwitterAdx);

        // I personally know there's only 2 tweets, so...
        // id 0 & id 1
        for (uint8 i = 0; i < 2; i++) {
            // get tweet data
            (
                string memory twitMsg,
                string memory tweetImg,
                address sender
            ) = oldTwitterInstance.getTweet(i);

            // create a new one in this contract
            uint tweetId = addressToTweetId[sender].current();
            addressToTweetId[sender].increment();

            addressToTweets[sender][tweetId] = Tweet({
                message: twitMsg,
                imageUrl: tweetImg
            });

            emit TweetCreated({
                tweeter: sender,
                tweetMsg: twitMsg,
                tweetImg: tweetImg
            });
        }
    }
}