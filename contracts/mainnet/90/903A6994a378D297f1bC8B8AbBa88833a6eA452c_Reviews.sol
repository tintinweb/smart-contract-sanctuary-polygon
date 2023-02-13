// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Reviews {
    struct Review {
        uint8 stats;
        uint8 metter;
        string uriComment;
    }

    mapping(uint256 => mapping(address => Review)) public reviews;
    // post_id -> commenter -> reviews

    constructor() {
    }

    function postReview(uint256 postId, uint8 stats, uint8 metter, string calldata uriComment) public {
        // if (reviews[postId][msg.sender].stats > 0) {
        //     require(1 != 1, "already review for this post");
        // }
        Review memory review = Review (
            stats,
            metter,
            uriComment
        );
        reviews[postId][msg.sender] = review;
    }

}