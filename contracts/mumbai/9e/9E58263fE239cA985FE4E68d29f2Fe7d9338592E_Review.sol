/**
 *Submitted for verification at polygonscan.com on 2022-08-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
contract Review {
    struct ReviewStruct {
        address sender;
        string message;
        uint256 timestamp;
        uint8 rating;
    }

    event NewReview(
        string name,
        address sender,
        string message,
        uint256 timestamp,
        uint8 rating
    );

    mapping(string => ReviewStruct[]) public Reviews;

    constructor() {}

    function createReview(string memory name, string memory message,  uint8 rating
) external {

        require(rating >0 && rating < 6, "Rating must be between 1 and 5");
        ReviewStruct memory review = ReviewStruct(
            msg.sender,
            message,
            block.timestamp,
            rating
        );

        Reviews[name].push(review);
        emit NewReview(name, msg.sender, message, block.timestamp, rating);
    }

    function getReviews(string memory name)
        external
        view
        returns (ReviewStruct[] memory)
    {
        return Reviews[name];
    }
}