// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract MyContract {
    struct Campaign{
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
        int rating;
        int countrate;
        string category;
        address[] commentors;
        string[] comments;
    }

    mapping(uint256=>Campaign) public campaigns;

    uint256 public count=0;
    int public commentcount=0;
    function create(address _owner,string memory _title,string memory _description,string memory _category,uint256 _target,uint256 _deadline,string memory _image) public returns(uint256){
        Campaign storage campaign=campaigns[count];
        require(campaign.deadline<block.timestamp,"The deadline should be a date in the future");

        campaign.owner=_owner;
        campaign.title=_title;
        campaign.description=_description;
        campaign.category=_category;
        campaign.target=_target;

        campaign.deadline=_deadline;
        campaign.amountCollected=0;
        campaign.rating=0;
        campaign.countrate=0;
        campaign.image=_image;
        count++;
        return count-1;

    }

    function donate(uint256 _id) public payable {
        uint256 amount=msg.value;

        Campaign storage campaign=campaigns[_id];

        campaign.donators.push(msg.sender);
        campaign.donations.push(amount);

        (bool sent,)=payable(campaign.owner).call{value:amount}("");

        if(sent){
            campaign.amountCollected=campaign.amountCollected+amount;
        }
    }

    function getDonators(uint256 _id) view public returns( address[] memory,uint256[] memory){
        return (campaigns[_id].donators,campaigns[_id].donations);
    }

    function NewComment(uint256 _id,string memory _com,int rate) public{
        commentcount++;

        Campaign storage campaign=campaigns[_id];

        campaign.commentors.push(msg.sender);
        campaign.comments.push(_com);
        campaign.countrate=campaign.countrate+rate;
        campaign.rating=campaign.countrate/commentcount;

        
    }

    function getComments(uint256 _id) view public returns( address[] memory,string[] memory){
        return (campaigns[_id].commentors,campaigns[_id].comments);
    }


    function getCampaigns() public view returns(Campaign[] memory){
        Campaign[] memory allCampaigns=new Campaign[](count);
        for(uint i=0;i<count;i++){
            Campaign storage item=campaigns[i];

            allCampaigns[i]=item;
        }
        return allCampaigns;
    }

}