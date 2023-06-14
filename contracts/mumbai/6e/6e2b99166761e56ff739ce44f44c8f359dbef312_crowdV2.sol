/**
 *Submitted for verification at polygonscan.com on 2023-06-13
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
        mapping (uint=>uint) amountDonated;
        uint[] campaignsByUser;
        string nick;   
    }

    mapping(address=>stats) public userStats;
    mapping (address=> mapping(uint=>uint)) private timesDonatedById;

    uint256 startingId=0;

    function addNick(address user, string memory _nick) public {
        require(user==msg.sender, "You can edit nick only for yourself");
        userStats[user].nick=_nick;
    }

    function addCampaign( string memory name,
        uint dateEnding,
        string[] memory photos,
        string memory description,
        uint amountNeeded) public {
        require(bytes(description).length < 1500, "Description should be up to 1500 characters long");
        (userStats[msg.sender].campaignsByUser).push(startingId);
        campaigns.push(Campaign(startingId,name,msg.sender,block.timestamp,dateEnding,photos,description,amountNeeded,0,0,new address[](0),false,0));
        startingId++;
    }

    function editCampaign(uint id, string memory name,string[] memory photos,string memory description) public {
        require(campaigns[id].author==msg.sender,"You can edit your campaigns only!");
        campaigns[id].name=name;
        campaigns[id].photos=photos;
        campaigns[id].description=description;
    }    

    function pauseCampaign(uint id) public {
        require(campaigns[id].author==msg.sender,"You can edit your campaigns only!");
        campaigns[id].paused=!campaigns[id].paused;
    }

    function isItPaused (uint id) public view returns(string memory) {
        return (campaigns[id].paused) ? "Campaign is paused at the moment" : "Campaign is not paused";
    }

    function donate(uint amount, uint id) public payable {
        require(campaigns[id].paused==false,"Campaign is paused");
        require(amount>0,"You cannot donate 0");
        require(msg.value == amount);
        campaigns[id].onBalance+=amount;
        campaigns[id].raised+=amount;
        campaigns[id].numberOfDonations++;
        (campaigns[id].donators).push(msg.sender);
        userStats[msg.sender].totalDonated+=amount;
        userStats[msg.sender].amountDonated[id]+=amount;
        if (timesDonatedById[msg.sender][id]<1) {
            (userStats[msg.sender].donatedTo).push(id); 
        }
        timesDonatedById[msg.sender][id]++; 
    }

    function contributionToExactCampaign(address user, uint id)public view returns (uint,uint) {
        return (timesDonatedById[msg.sender][id],userStats[user].amountDonated[id] );
    }

    function checkPhotosandDonators(uint id) public view returns (string[] memory, address[] memory ){
        return (campaigns[id].photos,campaigns[id].donators);
    }

    function viewUserDetails(address user, uint id) public view returns (uint[] memory, uint, uint[] memory){
        return (userStats[user].donatedTo,userStats[user].amountDonated[id],userStats[user].campaignsByUser);
    }

    function withdrawFunds(uint id,uint amount) public {
        require(campaigns[id].author==msg.sender,"That campaign is not yours");
        require(block.timestamp>campaigns[id].dateEnding,"Campaign has not ended yet");
        require(amount<=campaigns[id].onBalance,"You don't have enough balance");
        payable(msg.sender).transfer(amount);
        campaigns[id].onBalance-=amount;
    }

    function myCampaings(address user) public view returns (uint[] memory) {
        return (userStats[user].campaignsByUser);
    }

    //testnetRecovery
    function withdraw() public {
        require(msg.sender==owner);
        uint balance = address(this).balance;
        (bool sent, bytes memory data) = msg.sender.call{value: balance}("");
        require(sent, "Failed to send Ether");
     }
}