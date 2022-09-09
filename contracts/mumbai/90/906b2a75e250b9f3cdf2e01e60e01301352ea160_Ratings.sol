/**
 *Submitted for verification at polygonscan.com on 2022-09-08
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
    }

    struct AggregateRating {
       uint256 Field1Total;
       uint256 Field2Total;
       uint256 Field3Total;
       uint256 Field4Total;
       uint256 Field5Total;
       uint256 Count;
    }

    struct Index {
        uint256 Position;
        bool Exists;
    }

    // Sites total ratings
    mapping(string => AggregateRating) _siteAggregates;

    // Sites individual ratings
    mapping(string => Rating[]) private _siteRatings;
    mapping(string => uint256) private _siteRatingCounts;

    // Users individual ratings
    mapping(address => Rating[]) private _userRatings;
    mapping(address => uint256) private _userRatingCounts;

    // Index mapping for sites/users individual ratings
    mapping(address => mapping(string => Index)) private _userSiteRatingIndex;
    mapping(string => mapping(address => Index)) private _siteUserRatingIndex;

    uint256 private _pageLimit = 50;

    // Add a new or replace and existing rating
    function AddRating(string memory site, Rating memory rating) public {
        // We check if there is already an index for this site/user
        Index memory useriSteIndex = _userSiteRatingIndex[msg.sender][site];

        // If it already exists then edit the existing
        if(useriSteIndex.Exists == true) _editRating(site, rating);

        // Otherwise add a new rating for site/user
        else _createRating(site, rating);          
    }

    // Gets an aggregate rating for a site
    function GetRating(string memory site) public view returns(AggregateRating memory aggregateRating){
        aggregateRating = _siteAggregates[site];
    }

    // Get a page of users ratings 
    function GetUserRatings(address userAddress, uint256 fromPosition, uint256 amount) public view returns(Rating[] memory ratings){
        // Validate page limit
        require(amount <= _pageLimit);

        // Create the page
        Rating[] memory pageOfRatings = new Rating[](amount);

        // Get the total amount remaining
        uint256 totalRatings = GetTotalUserRatings(userAddress);

        // Get total iterations left
        uint256 remaining = (totalRatings - (fromPosition + 1));

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = fromPosition;i < remaining;i++){
           // Get the rating
           Rating memory rating = _userRatings[userAddress][i];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;

           // If we have our amount, we can leave loop
           if(pageItemIndex > amount)
               return pageOfRatings;
        }

        return pageOfRatings;
    }

    // Get a page of a sites ratings 
    function GetSiteRatings(string memory site, uint256 fromPosition, uint256 amount) public view returns(Rating[] memory ratings){
        // Validate page limit
        require(amount <= _pageLimit);

        // Create the page
        Rating[] memory pageOfRatings = new Rating[](amount);

        // Get the total amount remaining
        uint256 totalRatings = GetTotalSiteRatings(site);

        // Get total iterations left
        uint256 remaining = (totalRatings - (fromPosition + 1));

        // Add each item to the page
        uint256 pageItemIndex = 0;
        for(uint256 i = fromPosition;i < remaining;i++){
           // Get the rating
           Rating memory rating = _siteRatings[site][i];

           // Add to page
           pageOfRatings[pageItemIndex] = rating;

           // Increment page item index
           pageItemIndex++;

           // If we have our amount, we can leave loop
           if(pageItemIndex > amount)
               return pageOfRatings;
        }

        return pageOfRatings;
    }

    // Get a page of a sites ratings 
    function GetTotalSiteRatings(string memory site) public view returns(uint256 total){
        return _siteRatingCounts[site];
    }

    // Get a page of a user ratings 
    function GetTotalUserRatings(address userAddress) public view returns(uint256 total){
        return _userRatingCounts[userAddress];
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
        Rating storage oldUserRating = _userRatings[msg.sender][userIndex.Position - 1];
        Rating storage oldSiteRating = _siteRatings[site][siteIndex.Position - 1];

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

       // Update site Rating
       oldSiteRating.Field1 = rating.Field1;
       oldSiteRating.Field2 = rating.Field2;
       oldSiteRating.Field3 = rating.Field3;
       oldSiteRating.Field4 = rating.Field4;
       oldSiteRating.Field5 = rating.Field5;
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

        aggregateRating.Count = aggregateRating.Count--;
    }
}