// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

struct Transaction {
    uint256 amount;
    address recipient;
    string description;
}

struct Donation {
    uint256 amount;
    address donor;
}

struct Campaign {
    uint256 id;
    string name;
    uint256 goal;
    uint256 balance;
    address owner;
    uint256 donationsCount;
    uint256 deadline;
    string description;
    bool isNotFinished;
    string imageURL;
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
error InsufficientFunds();
error AmountMustBePositive();
error DescriptionCannotBeEmpty();
error CannotSendFundsToAddressZero();
error CannotSendFundsToOwner();

contract Crowdfunding {
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256))
        public userDonationPerCampaign;
    mapping(uint256 => Donation[]) public donationsPerCampaign;
    mapping(uint256 => Transaction[]) public transactionsPerCampaign;
    uint256 public indexOfCampaigns;
    address public owner;

    // declarations of events
    event CreateCampaign(
        uint256 id,
        string name,
        address owner,
        uint256 goal,
        uint256 deadline,
        string description
    );
    event Donate(uint256 _idOfCampaign, address _address, uint256 _amount);
    event UsedFunds(
        uint256 _idOfCampaign,
        address _owner,
        uint256 _amount,
        string _description,
        address _recipient
    );
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
        string memory _description,
        string memory _imageURL
    ) public {
        if (block.timestamp >= _deadline) revert DeadlineMustBeInFuture();

        campaigns[indexOfCampaigns] = Campaign({
            id: indexOfCampaigns,
            name: _nameOfCampaign,
            goal: _goalOfCampaign,
            balance: 0,
            owner: msg.sender,
            donationsCount: 0,
            deadline: _deadline,
            description: _description,
            isNotFinished: true,
            imageURL: _imageURL
        });

        ++indexOfCampaigns;

        emit CreateCampaign(
            indexOfCampaigns - 1,
            _nameOfCampaign,
            msg.sender,
            _goalOfCampaign,
            _deadline,
            _description
        );
    }

    function donate(uint256 _idOfCampaign) public payable {
        if (msg.value <= 0) revert DonatedAmountMustBePositive();

        Campaign storage campaign = campaigns[_idOfCampaign];

        if (!campaign.isNotFinished) revert CampaignDoesNotExist();
        if (block.timestamp >= campaign.deadline) revert CampaignFinished();

        campaign.balance += msg.value;
        ++campaign.donationsCount;

        userDonationPerCampaign[_idOfCampaign][msg.sender] += msg.value;
        donationsPerCampaign[_idOfCampaign].push(
            Donation({amount: msg.value, donor: msg.sender})
        );

        (bool send, ) = address(this).call{value: msg.value}("");
        if (send == false) revert FailedToSendEther();

        emit Donate(_idOfCampaign, msg.sender, msg.value);
    }

    function endCampaign(uint256 _idOfCampaign) public {
        Campaign storage campaign = campaigns[_idOfCampaign];

        if (!campaign.isNotFinished) revert CampaignDoesNotExist();
        if (msg.sender != campaign.owner) revert NotTheOwnerOfCampaign();
        if (block.timestamp < campaign.deadline) revert CampaignNotFinished();

        campaign.isNotFinished = false;

        emit EndCampaign(_idOfCampaign, msg.sender);
    }

    function useFunds(
        uint256 _idOfCampaign,
        uint256 _amount,
        string memory _description,
        address payable recipient
    ) public {
        Campaign storage campaign = campaigns[_idOfCampaign];

        if (campaign.isNotFinished) revert CampaignNotFinished();
        if (msg.sender != campaign.owner) revert NotTheOwnerOfCampaign();
        if (campaign.balance <= 0) revert BalanceOfCampaignIsZero();
        if (_amount == 0) revert AmountMustBePositive();
        if (_amount > campaign.balance) revert InsufficientFunds();
        if (bytes(_description).length == 0) revert DescriptionCannotBeEmpty();
        if (recipient == address(0)) revert CannotSendFundsToAddressZero();
        if (recipient == campaign.owner) revert CannotSendFundsToOwner();

        campaign.balance -= _amount;
        transactionsPerCampaign[_idOfCampaign].push(
            Transaction({
                amount: _amount,
                recipient: recipient,
                description: _description
            })
        );

        (bool send, ) = recipient.call{value: _amount}("");

        if (send == false) revert FailedToSendEther();

        emit UsedFunds(
            _idOfCampaign,
            msg.sender,
            _amount,
            _description,
            recipient
        );
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

    function getDonationsPerCampaign(
        uint256 _idOfCampaign
    ) public view returns (Donation[] memory) {
        return donationsPerCampaign[_idOfCampaign];
    }

    function getTransactionsPerCampaign(
        uint256 _idOfCampaign
    ) public view returns (Transaction[] memory) {
        return transactionsPerCampaign[_idOfCampaign];
    }
}