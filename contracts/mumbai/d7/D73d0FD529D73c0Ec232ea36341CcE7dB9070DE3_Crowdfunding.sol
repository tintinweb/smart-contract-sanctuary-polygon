// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

enum State {
    Finished,
    Ongoing
}

struct Campaign {
    uint256 id;
    string name;
    uint256 goal;
    uint256 balance;
    address owner;
    uint256 donorsCount;
    uint256 deadline;
    string description;
    State state;
}

error NotTheOwnerOfContract();
error DonatedAmountMustBePositive();
error CampaignDoesNotExist();
error FailedToSendEther();
error NotTheOwnerOfCampaign();
error BalanceOfCampaignIsZero();
error DeadlineMustBeInFuture();
error CampaignFinished();
error CampaignNotFinished();

contract Crowdfunding {
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256))
        public userDonationPerCampaign;

    uint256 public indexOfCampaigns;
    address public owner;

    // declarations of events
    event CreateCampaign(
        uint256 id,
        string name,
        address owner,
        uint256 goal,
        uint256 deadline
    );
    event Donate(uint256 _idOfCampaign, address _address, uint256 _amount);
    event FundsClaimed(uint256 _idOfCampaign, address _owner, uint256 _amount);
    event EndCampaign(uint256 _idOfCampaign, address _owner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotTheOwnerOfContract();

        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    receive() external payable {}

    function createCampaign(
        string memory _nameOfCampaign,
        uint256 _goalOfCampaign,
        uint256 _deadline,
        string memory _description
    ) public {
        if (block.timestamp >= _deadline) revert DeadlineMustBeInFuture();

        campaigns[indexOfCampaigns] = Campaign({
            id: indexOfCampaigns,
            name: _nameOfCampaign,
            goal: _goalOfCampaign,
            balance: 0,
            donorsCount: 0,
            owner: msg.sender,
            deadline: _deadline,
            description: _description,
            state: State.Ongoing
        });

        ++indexOfCampaigns;

        emit CreateCampaign(
            indexOfCampaigns - 1,
            _nameOfCampaign,
            msg.sender,
            _goalOfCampaign,
            _deadline
        );
    }

    function donate(uint256 _idOfCampaign) public payable {
        if (msg.value <= 0) revert DonatedAmountMustBePositive();

        Campaign storage campaign = campaigns[_idOfCampaign];

        if (campaign.state != State.Ongoing) revert CampaignDoesNotExist();
        if (block.timestamp >= campaign.deadline) revert CampaignFinished();

        campaign.balance += msg.value;
        ++campaign.donorsCount;

        userDonationPerCampaign[_idOfCampaign][msg.sender] += msg.value;

        (bool send, ) = address(this).call{value: msg.value}("");
        if (send == false) revert FailedToSendEther();

        emit Donate(_idOfCampaign, msg.sender, msg.value);
    }

    function claimFundsFromCampaign(uint256 _idOfCampaign) public {
        Campaign storage campaign = campaigns[_idOfCampaign];

        if (campaign.state != State.Ongoing) revert CampaignDoesNotExist();
        if (msg.sender != campaign.owner) revert NotTheOwnerOfCampaign();
        if (campaign.balance <= 0) revert BalanceOfCampaignIsZero();

        uint256 balance = campaign.balance;
        campaign.balance = 0;

        (bool send, ) = msg.sender.call{value: balance}("");
        if (send == false) revert FailedToSendEther();

        emit FundsClaimed(_idOfCampaign, msg.sender, balance);
    }

    function endCampaign(uint256 _idOfCampaign) public {
        Campaign storage campaign = campaigns[_idOfCampaign];

        if (campaign.state != State.Ongoing) revert CampaignDoesNotExist();
        if (msg.sender != campaign.owner) revert NotTheOwnerOfCampaign();
        if (block.timestamp < campaign.deadline) revert CampaignNotFinished();

        if (campaign.balance > 0) {
            claimFundsFromCampaign(_idOfCampaign);
        }

        delete campaigns[_idOfCampaign];

        emit EndCampaign(_idOfCampaign, msg.sender);
    }

    function getCampaign(
        uint256 _idOfCampaign
    ) public view returns (Campaign memory) {
        return campaigns[_idOfCampaign];
    }

    function getBalanceOfContract() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserDonationPerCampaign(
        uint256 _idOfCampaign,
        address _user
    ) public view returns (uint256) {
        return userDonationPerCampaign[_idOfCampaign][_user];
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](indexOfCampaigns);

        for (uint256 i = 0; i < indexOfCampaigns; ++i) {
            _campaigns[i] = campaigns[i];
        }

        return _campaigns;
    }
}