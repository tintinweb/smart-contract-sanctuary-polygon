/**
 *Submitted for verification at polygonscan.com on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Rate {
    /// @dev mapping that stores sitelink to ratingData
    mapping(string => RatingData[]) public siteToRatingData;

    struct RatingData {
        uint8 rating;
        string comment;
    }

    event Rating(address user, string sitelink, string comment, uint8 rating);

    /// @dev it will create a rating to a site if not present and if already present then it will be edited.
    function rating(
        string memory _sitelink,
        uint8 _rating,
        string memory _comment
    ) public {
        siteToRatingData[_sitelink].push(RatingData(_rating, _comment));
        emit Rating(msg.sender, _sitelink, _comment, _rating);
    }

    function getAllRatingData(string memory sitelink)
        public
        view
        returns (RatingData[] memory)
    {
        return siteToRatingData[sitelink];
    }

    function getRatingData(string memory sitelink, uint RatingID)
        public
        view
        returns (RatingData memory)
    {
        return siteToRatingData[sitelink][RatingID];
    }

    /// @dev it will delete the Rating
    function deleteRating(string memory _sitelink) public {
        delete siteToRatingData[_sitelink];
    }
}