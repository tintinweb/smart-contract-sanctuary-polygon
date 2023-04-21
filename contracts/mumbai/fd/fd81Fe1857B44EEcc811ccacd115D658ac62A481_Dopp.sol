// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Dopp {
    struct Campaign {
        uint id;
        string image;
        string name;
        string url;
        string description;
        uint amountReceived;
        bool goalAchieved;
        uint totalAmount;
        address payable author;
    }

    mapping(uint => Campaign) public campaigns;
    uint256 public campaignCount = 0;

    event CampaignCreated(
        uint256 id,
        string image,
        string name,
        string url,
        string description,
        uint256 totalAmount,
        address author
    );

    event FundsDonated(
        uint id,
        string name,
        string description,
        uint amount,
        address investor
    );

    function createCampaign(
        string memory _image,
        string memory _name,
        string memory _url,
        string memory _description,
        uint _totalAmount
    ) public {
        require(bytes(_image).length > 0, "Send Nudes!");
        require(bytes(_description).length > 0, "Describe bitch!!");
        require(bytes(_name).length > 0, "Name is Required!");
        require(_totalAmount > 0, "Ask money");

        campaigns[campaignCount] = Campaign(
            campaignCount,
            _image,
            _name,
            _url,
            _description,
            0,
            false,
            _totalAmount,
            payable(msg.sender)
        );

        campaignCount++;

        emit CampaignCreated(
            campaignCount - 1,
            _image,
            _name,
            _url,
            _description,
            _totalAmount,
            msg.sender
        );
    }

    function donateFunds(uint _id) public payable {
        require(msg.value > 0, "Send some money bitch!");
        require(!campaigns[_id].goalAchieved, "Goal already achieved.");

        uint netAmount = campaigns[_id].amountReceived + msg.value;

        campaigns[_id].amountReceived = netAmount;

        campaigns[_id].author.transfer(msg.value);

        if (netAmount >= campaigns[_id].totalAmount) {
            campaigns[_id].goalAchieved = true;
        }

        emit FundsDonated(
            _id,
            campaigns[_id].name,
            campaigns[_id].description,
            msg.value,
            msg.sender
        );
    }
}