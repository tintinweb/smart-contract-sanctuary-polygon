/**
 *Submitted for verification at polygonscan.com on 2023-06-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

contract crowdV2 {

    address owner;

    constructor(){
        owner=msg.sender;
    }

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
       uint numberOfDonations;
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
    mapping (address=> mapping(uint=>uint)) public timesDonatedById;

    uint256 startingId=0;

    function addCampaign( string memory name,
       uint dateEnding,
       string[] memory photos,
       string memory description,
       uint amountNeeded) public {
       (userStats[msg.sender].myCampaigns).push(startingId);
       campaigns.push(Campaign(startingId,name,msg.sender,block.timestamp,dateEnding,photos,description,amountNeeded,0,0,new address[](0),false,0));
       startingId++;
    }

    function editCampaign(uint id, string memory name,string[] memory photos,string memory description) public {
            require(campaigns[id].author==msg.sender,"You can edit your campaigns only!");
            campaigns[id].name=name;
            campaigns[id].photos=photos;
            campaigns[id].description=description;
    }    

    function pauseCampaign(uint id) public returns (string memory){
            require(campaigns[id].author==msg.sender,"You can edit your campaigns only!");
            campaigns[id].paused=!campaigns[id].paused;
            string memory state;
            if (campaigns[id].paused) state="paused"; else state="note paused";

            string memory part ="Campaign is cuurently ";
            string memory result = string(abi.encodePacked(part, state));
            return result;
    }

    function donate(uint amount, uint id) public payable {
        require(campaigns[id].paused==false,"Campaign is paused");
        require(amount>0,"You cannot donate 0");
        require(msg.value == amount);
        campaigns[id].onBalance+=amount;
        campaigns[id].raised+=amount;
        campaigns[id].numberOfDonations++;
        userStats[msg.sender].totalDonated+=amount;
        userStats[msg.sender].donationDetails[id]+=amount;
        timesDonatedById[msg.sender][id]++; 
        if (timesDonatedById[msg.sender][id]<1) {
            (userStats[msg.sender].donatedTo).push(id); 
        }
    }


    function donationsData(address user, uint id)public view returns (uint[] memory,uint) {
    return (userStats[user].donatedTo,userStats[user].donationDetails[id]);
    }

    function withdrawDonations(uint id,uint amount) public {
    require(campaigns[id].author==msg.sender,"That campaign is not yours");
    require(block.timestamp>campaigns[id].dateEnding,"Campaign has not ended yet");
    require(amount<campaigns[id].onBalance,"You don't have enough balance");
    payable(msg.sender).transfer(amount);
    campaigns[id].onBalance-=amount;
    }

    function myCampaings(address user)public view returns (uint[] memory) {
        return (userStats[user].myCampaigns);
    }


    //testnetRecovery
    function withdraw() public {
        require(msg.sender==owner);
        uint balance = address(this).balance;
        (bool sent, bytes memory data) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
     }

}