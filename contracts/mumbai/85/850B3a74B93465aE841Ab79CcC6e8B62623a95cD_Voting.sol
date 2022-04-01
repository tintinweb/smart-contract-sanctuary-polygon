// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title Voting Contract
 */

contract Voting {
    using Counters for Counters.Counter;
    Counters.Counter private currentPostId;
    Counters.Counter private currentVoteId;

    event CreatePost(address, string memmory);
    event CreateVote(address, uint256, uint8);
    event EditVote(uint256, uint8);
    event DeleteVote(uint256);

    struct Post {
        uint256 id;
        bytes caption;
        uint256 timestamp;
        address author;
    }

    struct Vote {
        uint256 id;
        uint256 postId;
        uint256 timestamp;
        uint8 rating;
        address voter;
    }

    struct CreditUsage {
        uint256 lastReset;
        uint256 creditsUsed;
    }
    uint256 private constant MAX_LENGTH = 280;
    Post[] private postArray;
    mapping(uint256 => Vote) private votes;
    mapping(address => CreditUsage) private creditInfo;
    uint256[5] private ratingArray;
    uint256 private creditAmount;

    constructor(uint256[5] memory _ratingArray, uint256 _creditAmount) {
        ratingArray = _ratingArray;
        creditAmount = _creditAmount;
    }

    /// @notice get credit usage
    function getCreditUsage(address voter) external view returns (uint256, uint256) {
        return (creditInfo[voter].lastReset, creditInfo[voter].creditsUsed);
    }

    /// @notice create Post
    function createPost(address author, string memory caption) external {
        bytes memory captionBytes = bytes(caption);
        require(captionBytes.length <= MAX_LENGTH, "exceed caption length limit");
        currentPostId.increment();
        postArray.push(
            Post(
                currentPostId.current(),
                captionBytes,
                block.timestamp,
                author
            )
        );
        emit CreatePost(author, caption);
    }

    /// @notice createVote
    function createVote(address voter, uint256 postId, uint8 rating) external {
        require(postId <= currentPostId.current(), "postId is wrong");
        require(rating > 0 && rating <= 5, "rating is wrong");
        currentVoteId.increment();
        uint256 voteId = currentVoteId.current();
        votes[voteId] = Vote(
            voteId,
            postId,
            block.timestamp,
            rating,
            voter
        );
        
        CreditUsage storage usage = creditInfo[voter];
        if (block.timestamp - usage.lastReset > 1 days) {
            usage.lastReset = block.timestamp;
            usage.creditsUsed = 0;
        }
        require(
            usage.creditsUsed + ratingArray[rating - 1] <= creditAmount,
            "Exceed creditAmount given to user per day"
        );
        usage.creditsUsed += ratingArray[rating - 1];

        emit CreateVote(voter, postId, rating);
    }

    /// @notice editVote
    function editVote(uint256 voteId, uint8 rating) external {
        require(voteId <= currentVoteId.current(), "voteId is wrong");
        require(rating > 0 && rating <= 5, "rating is wrong");
        Vote storage vote = votes[voteId];
        require(vote.id > 0, "vote already removed!");
        uint8 originalRate = vote.rating;
        vote.rating = rating;

        CreditUsage storage usage = creditInfo[vote.voter];
        if (usage.creditsUsed >= ratingArray[originalRate - 1]) {
            usage.creditsUsed -= ratingArray[originalRate - 1];
            usage.creditsUsed += ratingArray[rating - 1];
        } else {
            usage.creditsUsed = 0;
        }

        emit EditVote(voteId, rating);
    }

    /// @notice deleteVote
    function deleteVote(uint256 voteId) external {
        require(voteId <= currentVoteId.current(), "voteId is wrong");
        require(votes[voteId].id > 0, "vote already removed!");
        uint8 originalRate = votes[voteId].rating;

        CreditUsage storage usage = creditInfo[votes[voteId].voter];
        if (usage.creditsUsed >= ratingArray[originalRate - 1]) {
            usage.creditsUsed -= ratingArray[originalRate - 1];
        } else {
            usage.creditsUsed = 0;
        }
        delete votes[voteId];

        emit DeleteVote(voteId);
    }
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