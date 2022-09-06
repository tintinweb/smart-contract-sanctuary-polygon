/**
 *Submitted for verification at polygonscan.com on 2022-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ratings
 * @dev Persists and manages ratings across the internet
 */
contract Ratings {

    struct Rating {
       uint256 Field1;
       uint256 Field2;
       uint256 Field3;
       uint256 Field4;
       uint256 Field5;
       uint256 Field6;
       uint256 Field7;
       uint256 Field8;
       uint256 Field9;
       uint256 Field10;
    }

    struct AggregateRating {
       uint256 Field1Total;
       uint256 Field2Total;
       uint256 Field3Total;
       uint256 Field4Total;
       uint256 Field5Total;
       uint256 Field6Total;
       uint256 Field7Total;
       uint256 Field8Total;
       uint256 Field9Total;
       uint256 Field10Total;
       uint256 Count;
    }

    struct Index {
        uint256 Position;
        bool Exists;
    }

    // Sites total ratings
    mapping(string => AggregateRating) _siteAggregates;

    // Sites individual ratings
    mapping(string => Rating[]) _siteRatings;
    mapping(string => uint256) _siteRatingCounts;

    // Users individual ratings
    mapping(address => Rating[]) _userRatings;
    mapping(address => uint256) _userRatingCounts;

    // Index mapping for sites/users individual ratings
    mapping(address => mapping(string => Index)) _userSiteRatingIndex;
    mapping(string => mapping(address => Index)) _siteUserRatingIndex;

    // Add a new or replace and existing rating
    function AddRating(string memory site, Rating memory rating) public {
        // We check if there is already an index for this site/user
        Index memory useriSteIndex = _userSiteRatingIndex[msg.sender][site];

        // If it already exists then edit the existing
        if(useriSteIndex.Exists) _editRating(site, rating);
        // Otherwise add a new rating for site/user
        else _createRating(site, rating);           
    }

    // Create a new rating for a site/user
    function _createRating(string memory site, Rating memory rating) private {
        // Update the total rating for the site
        _updateSiteAggregate(site, rating);

       // Add to site ratings
       Rating[] storage siteRatings = _siteRatings[site];
       siteRatings.push(rating);
       // Update the length of the ratings
       _siteRatingCounts[site] = siteRatings.length;

       // Add to user ratings
       Rating[] storage userRatings = _userRatings[msg.sender];
       userRatings.push(rating);
       // Update the length of the ratings
       _userRatingCounts[msg.sender] = userRatings.length;

       // Add indexes
       Index memory userSiteIndex = Index(siteRatings.length, true);
       _userSiteRatingIndex[msg.sender][site] = userSiteIndex; 
       Index memory siteUserIndex = Index(userRatings.length, true);
       _siteUserRatingIndex[site][msg.sender] = siteUserIndex; 
    }

    // Create a new rating for a site/user
    function _editRating(string memory site, Rating memory rating) private {
        // Get the index of the user/site rating
        Index memory userIndex = _userSiteRatingIndex[msg.sender][site];
        Index memory siteIndex = _siteUserRatingIndex[site][msg.sender];

        // Get the users existing rating for the site
        Rating storage oldUserRating = _userRatings[msg.sender][userIndex.Position];
        Rating storage oldSiteRating = _siteRatings[site][siteIndex.Position];

        // Remove old value
        _removeSiteAggregate(site, oldUserRating);

        // Update the total rating for the site
        _updateSiteAggregate(site, rating);

       // Update user rating
       oldUserRating.Field1 = rating.Field1;
       oldUserRating.Field2 = rating.Field2;
       oldUserRating.Field3 = rating.Field3;
       oldUserRating.Field4 = rating.Field4;
       oldUserRating.Field5 = rating.Field5;
       oldUserRating.Field6 = rating.Field6;
       oldUserRating.Field7 = rating.Field7;
       oldUserRating.Field8 = rating.Field8;
       oldUserRating.Field9 = rating.Field9;
       oldUserRating.Field10 = rating.Field10;

       // Update site Rating
       oldSiteRating.Field1 = rating.Field1;
       oldSiteRating.Field2 = rating.Field2;
       oldSiteRating.Field3 = rating.Field3;
       oldSiteRating.Field4 = rating.Field4;
       oldSiteRating.Field5 = rating.Field5;
       oldSiteRating.Field6 = rating.Field6;
       oldSiteRating.Field7 = rating.Field7;
       oldSiteRating.Field8 = rating.Field8;
       oldSiteRating.Field9 = rating.Field9;
       oldSiteRating.Field10 = rating.Field10;
    }

    // Update the total ratings for a site
    function _updateSiteAggregate(string memory site, Rating memory rating) private{
        // Get the aggregate to update
        AggregateRating storage aggregateRating = _siteAggregates[site];
        
        // Update the aggregate with extra info
        aggregateRating.Field1Total += rating.Field1;
        aggregateRating.Field2Total += rating.Field2;
        aggregateRating.Field3Total += rating.Field3;
        aggregateRating.Field4Total += rating.Field4;
        aggregateRating.Field5Total += rating.Field5;
        aggregateRating.Field6Total += rating.Field6;
        aggregateRating.Field7Total += rating.Field7;
        aggregateRating.Field8Total += rating.Field8;
        aggregateRating.Field9Total += rating.Field9;
        aggregateRating.Field10Total += rating.Field10;

        // Up the answer count
        aggregateRating.Count += 1;
    }

    // Update the total ratings for a site
    function _removeSiteAggregate(string memory site, Rating memory oldRating) private{
        // Get the aggregate to update
        AggregateRating storage aggregateRating = _siteAggregates[site];

        aggregateRating.Field1Total -= oldRating.Field1;
        aggregateRating.Field2Total -= oldRating.Field2;
        aggregateRating.Field3Total += oldRating.Field3;
        aggregateRating.Field4Total += oldRating.Field4;
        aggregateRating.Field5Total += oldRating.Field5;
        aggregateRating.Field6Total += oldRating.Field6;
        aggregateRating.Field7Total += oldRating.Field7;
        aggregateRating.Field8Total += oldRating.Field8;
        aggregateRating.Field9Total += oldRating.Field9;
        aggregateRating.Field10Total += oldRating.Field10;

        aggregateRating.Count = aggregateRating.Count--;
    }
}