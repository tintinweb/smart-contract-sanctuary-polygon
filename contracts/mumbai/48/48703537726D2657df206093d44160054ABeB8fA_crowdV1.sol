/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

contract crowdV1 {

    struct Campaign {
       uint id;
       string name;
       address author;
       uint dateAdded;
       uint dateEnding;
       string[] photos;
       string description;
       uint amountNeeded;
       uint raised;
       uint onBalance;
       address[] donators;
       bool paused;
    }

    Campaign[] public campaigns;

    struct stats{
        uint totalDonated;
        uint[] donatedTo;
        mapping (uint=>uint) donationDetails;
        uint[] myCampaigns;
        string nick;
    }

    mapping(address=>stats) public userStats;
    mapping ( address=> mapping(uint=>uint)) public timesDonatedById;

    uint256 startingId=0;

    function addCampaign( string memory name,
       uint dateEnding,
       string[] memory photos,
       string memory description,
       uint amountNeeded) public {
       (userStats[msg.sender].myCampaigns).push(startingId);
       campaigns.push(Campaign(startingId,name,msg.sender,block.timestamp,dateEnding,photos,description,amountNeeded,0,0,new address[](0),false));
       startingId++;
    }

    function donate(uint amount, uint id) public {
        require(campaigns[id].paused==false,"Campaign is paused");
        campaigns[id].onBalance+=amount;
        campaigns[id].raised+=amount;
        userStats[msg.sender].totalDonated+=amount;
        userStats[msg.sender].donationDetails[id]+=amount;
        timesDonatedById[msg.sender][id]++; 
        if (timesDonatedById[msg.sender][id]<1) {
            (userStats[msg.sender].donatedTo).push(id); 
        }
    }


    function donationsData(address korisnik, uint id)public view returns (uint[] memory,uint) {
    return (userStats[korisnik].donatedTo,userStats[korisnik].donationDetails[id]);
    }

    function withdrawDonations(uint id,uint amount) public {
    require(campaigns[id].author==msg.sender,"That campaign is not yours");
    campaigns[id].onBalance-=amount;
    }

    function myCamps(address korisnik)public view returns (uint[] memory) {
        return (userStats[korisnik].myCampaigns);
    }
}