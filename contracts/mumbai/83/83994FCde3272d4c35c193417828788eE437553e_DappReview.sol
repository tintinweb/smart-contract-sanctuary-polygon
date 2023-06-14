// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract DappReview {
    struct Review {
        uint8 rating;
        string content;
    }

    mapping(string => Review[]) public reviews;

    function addReview(string memory dapp, uint8 rating, string memory content) public {
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");
        reviews[dapp].push(Review(rating, content));
    }

    function getReviewCount(string memory dapp) public view returns (uint) {
        return reviews[dapp].length;
    }

    function getReview(string memory dapp, uint index) public view returns (uint8, string memory) {
        require(index < reviews[dapp].length, "Invalid review index");
        Review memory review = reviews[dapp][index];
        return (review.rating, review.content);
    }

    function getAllReviews(string memory dapp) public view returns (uint8[] memory, string[] memory) {
        uint length = reviews[dapp].length;

        uint8[] memory ratings = new uint8[](length);
        string[] memory contents = new string[](length);

        for (uint i = 0; i < length; i++) {
            Review memory review = reviews[dapp][i];
            ratings[i] = review.rating;
            contents[i] = review.content;
        }

        return (ratings, contents);
    }
}