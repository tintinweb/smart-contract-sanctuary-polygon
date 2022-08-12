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
    }

    event NewReview(
        string name,
        address sender,
        string message,
        uint256 timestamp
    );

    mapping(string => ReviewStruct[]) public Reviews;

    constructor() {}

    function createReview(string memory name, string memory message) external {
        ReviewStruct memory review = ReviewStruct(
            msg.sender,
            message,
            block.timestamp
        );

        Reviews[name].push(review);
        emit NewReview(name, msg.sender, message, block.timestamp);
    }

    function getReviews(string memory name)
        external
        view
        returns (ReviewStruct[] memory)
    {
        return Reviews[name];
    }
}