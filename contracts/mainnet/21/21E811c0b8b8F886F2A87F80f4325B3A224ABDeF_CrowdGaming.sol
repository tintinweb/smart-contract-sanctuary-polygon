/**
 *Submitted for verification at polygonscan.com on 2023-04-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/*
    Custom errors for gas saving.
*/
error NotOwner();
error RateExceeded();
error InvalidLength();
error InvalidEndDate();
error InvalidStartDate();
error InvalidAmount();
error AlreadyClaimed();
error AlreadyCancelled();
error FailedCampaign();
error GoalMet();
error InvalidCampaign();

/**
  @title CrowdFunding is a fundraising contract, with ultra flexability, geared towards gamers
  @author Peter Mazzocco, co-founder SB LABS LLC

    This contract is pulled from an open-source contract I created: OpenFund
    https://github.com/petermazzocco/openfund

*/

contract CrowdGaming {
    /* 
        Events to subscribe to:
        Launch includes id, indexed owner, title, goal, description, startAt and endAt times
        Pledged and Refund index the id and pledger, and include the amount.
        Cancel, Withdraw and Highlight only include id
    */
    event Launch(
        uint id,
        address indexed owner,
        string title,
        uint goal,
        string description,
        uint256 startAt,
        uint256 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed pledger, uint amount);
    event Withdraw(uint id);
    event Refund(uint indexed id, address indexed pledger, uint amount);
    event Highlight(uint id);

    /* 
        Struct for Campaign 
        @param id for easier tracking in dApp
        @param owner address
        @param title of campaign
        @param description of campaign
        @param amount pledged to the campaign
        @param the goal of the campaign
        @param startAt is the starting time (in seconds since unix epoch)
        @param enAt is the ending time (in seconds since unix epoch)
        @param claimed if user has claimed the funds for successful campaign
        @param cancelled if a user has cancelled the campaign before launch
        @param OPTIONAL: highlighted if a user has boosted their campaign (for front end purposes)
    */
    struct Campaign {
        uint id;
        address owner;
        string title;
        string description;
        uint pledged;
        uint goal;
        uint256 startAt;
        uint256 endAt;
        bool claimed;
        bool cancelled;
        bool highlighted;
    }

    // State variables
    uint public totalCampaigns; // track total campaigns
    mapping(uint => Campaign) public campaigns; // track all campaign ids
    mapping(uint => mapping(address => uint)) public pledgedAmount; // track address amount pledged to a campaign
    mapping(address => uint[]) public ownerCampaigns; // track campaigns owned by address
    mapping(address => uint[]) public donorCampaigns; // track campaigns donated to by an address
    address public contractOwner; // address for who owns the contract
    mapping(uint => uint) public donationFunds; // track funds received through donate function
    mapping(uint => bool) public highlightedCampaigns; // track campaign ids that are highlighted
    uint public boostPrice; // price to boost campaign (can be modified)
    uint public rateLimit; // the amount of time between launching campaigns (can be modified)
    uint public campaignLength; // the length of campaigns (can be modified)
    mapping(address => uint) public lastLaunchTime; // track campaign launch time to prevent spamming
    uint public successfulCampaigns; // track successful campaigns for analytics

    /*
        @param _contractOwner - place the address of who will own the contract upon deployment
        @param _boostPrice - place the amount if costs to highlight/boost a campaign (optional can be removed)
        @param _rateLimite - place a rate limit for campaigns created to prevent spamming and DoS attacks - 24 hours = 846000
        @param _campaignLength - place the maximum amount of time in seconds for a campaigns length - 30 days = 2592000 
    */

    constructor(
        address _contractOwner,
        uint _boostPrice,
        uint _rateLimit,
        uint _campaignLength
    ) {
        contractOwner = _contractOwner;
        boostPrice = _boostPrice;
        rateLimit = _rateLimit;
        campaignLength = _campaignLength;
    }

    /*  
        This function allows people to launch campaigns securely and with requirements like 
        30 day caps and rateLimits set during deploy.

        @param _title The title of the campaign
        @param _description The description of the campaign 
        @param _goal The goal of the campaign
        @param _startAt The start at time in seconds since unix epoch
        @param _endAt The start at time in seconds since unix epoch
    */
    function launchCampaign(
        string calldata _title,
        string calldata _description,
        uint _goal,
        uint256 _startAt,
        uint256 _endAt
    ) external {
        if (_startAt < block.timestamp) {
            revert InvalidStartDate();
        }
        if (_endAt < _startAt) {
            revert InvalidEndDate();
        }
        if (_endAt - _startAt > campaignLength) {
            revert InvalidLength();
        }
        if (_goal <= 0) {
            revert InvalidAmount();
        }
        if (block.timestamp < lastLaunchTime[msg.sender] + rateLimit) {
            revert RateExceeded();
        }
        lastLaunchTime[msg.sender] = block.timestamp;
        totalCampaigns++;
        campaigns[totalCampaigns] = Campaign({
            id: totalCampaigns,
            owner: msg.sender,
            title: _title,
            goal: _goal,
            pledged: 0,
            description: _description,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false,
            cancelled: false,
            highlighted: false
        });
        ownerCampaigns[msg.sender].push(totalCampaigns);
        emit Launch(
            totalCampaigns,
            msg.sender,
            _title,
            _goal,
            _description,
            _startAt,
            _endAt
        );
    }

    /*  
        This function allows people to cancel a campaign. 
        The campaign has to be set for a future date in order to be cancelled.

        @param _id takes in the campaign id to be cancelled
    */
    function cancelCampaign(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        if (msg.sender != campaign.owner) {
            revert NotOwner();
        }
        if (block.timestamp >= campaign.startAt) {
            revert InvalidStartDate();
        }
        delete campaigns[_id]; // Delete campaign
        campaigns[_id].cancelled = true; // Set cancelled to true so we can filter out on dApp
        emit Cancel(_id);
    }

    /*  
        This function allows people to pledged to a campaign

        @param _id takes in the campaign id to pledge to
    */
    function pledgeTo(uint _id) external payable {
        Campaign storage campaign = campaigns[_id];
        if (msg.value <= 0) {
            revert InvalidAmount();
        }
        if (block.timestamp < campaign.startAt) {
            revert InvalidStartDate();
        }
        if (block.timestamp > campaign.endAt) {
            revert InvalidEndDate();
        }
        // Prevent reentry
        campaign.pledged += msg.value;
        pledgedAmount[_id][msg.sender] += msg.value;
        donorCampaigns[msg.sender].push(_id);
        emit Pledge(_id, msg.sender, msg.value);
    }

    /*  
        This function allows campaign owners to withdraw from a campaign
        if the campaign goal has been met and the campaign has expired.

        @param _id takes in the campaign id for withdrawing
    */
    function withdrawFrom(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        if (msg.sender != campaign.owner) {
            revert NotOwner();
        }
        if (block.timestamp < campaign.endAt) {
            revert InvalidEndDate();
        }
        if (campaign.pledged < campaign.goal) {
            revert FailedCampaign();
        }
        if (campaign.claimed) {
            revert AlreadyClaimed();
        }
        campaign.claimed = true;
        uint amount = campaign.pledged; // Store the pledged amount
        campaign.pledged = 0; // Reset the pledged amount
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw funds");
        successfulCampaigns++; // add campaign to successful campaign variable
        emit Withdraw(_id);
    }

    /*  
        This function allows donors to refund from a failed campaign
        and requires the campaign is ended

        @param _id takes in the campaign id to be refunded from
    */
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        if (block.timestamp < campaign.endAt) {
            revert InvalidEndDate();
        }
        if (campaign.pledged >= campaign.goal) {
            revert GoalMet();
        }
        if (campaign.owner == address(0)) {
            revert InvalidCampaign();
        }
        // Prevent reentry
        uint balance = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw funds");
        emit Refund(_id, msg.sender, balance);
    }

    /*  
        This function allows people boost a campaign 
        You set the price of the "Boost" on deploy

        @param _id takes in the campaign id to boost
    */
    function boost(uint _id) external payable {
        Campaign storage campaign = campaigns[_id];
        if (msg.value != boostPrice) {
            revert InvalidAmount();
        }
        if (campaign.cancelled) {
            revert AlreadyCancelled();
        }
        if (block.timestamp < campaign.startAt) {
            revert InvalidStartDate();
        }
        if (block.timestamp >= campaign.endAt) {
            revert InvalidEndDate();
        }
        // Set highlighted to true
        campaign.highlighted = true;
        highlightedCampaigns[_id] = true;
        emit Highlight(_id);
        donationFunds[_id] += msg.value; // track the funds received through donate function
    }

    /*  
        This function allows only the contract owner to withdraw funds 
        that have been donated for boosting campaigns.

        This does not allow the contract owner to withdraw all funds from
        campaigns, just ones that come from Boosting a campaign.

        @param _id takes in the campaign id's of boost campaigns
    */
    function withdrawBoostFunds(uint _id) external {
        if (msg.sender != contractOwner) {
            revert NotOwner();
        }
        uint balance = donationFunds[_id];
        if (balance <= 0) {
            revert InvalidAmount();
        }
        donationFunds[_id] = 0; // Reset the balance
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Failed to withdraw funds");
    }

    /*  
        This function allows you to view who owns what campaign and is designed for
        easier UI/UX on a web app.

        @param _address takes in the address of the campaign owner
        @returns the ids from the ownerCampaigns array
    */
    function getOwnerCampaigns(
        address _owner
    ) external view returns (uint[] memory) {
        return ownerCampaigns[_owner];
    }

    /*  
        This function allows you to view who has donated to a campaign and is desinged
        for easier UI/UX on a web app.

        @param _address takes in the address of the donor
        @returns the ids from the donorCampaigns array
    */

    function getDonorDonations(
        address _donor
    ) external view returns (uint[] memory) {
        return donorCampaigns[_donor];
    }

    /* 
        UPDATE FUNCTIONS
        FOR CONTRACT OWNER ONLY - SB LABS LLC
    */

    /*
        This function allows the contract owner to update the price to boost a 
        campaign

        @param _boostPrice is the amount in WEI.
    */
    function updateBoostPrice(uint _boostPrice) external {
        if (msg.sender != contractOwner) {
            revert NotOwner();
        }
        boostPrice = _boostPrice;
    }

    /*
        This function allows the contract owner to update the owner of the contract

        @param _contractOwner sets a new owner address
    */
    function updateContractOwner(address _contractOwner) external {
        if (msg.sender != contractOwner) {
            revert NotOwner();
        }
        contractOwner = _contractOwner;
    }

    /*
        This function allows the contract owner to update the rate limit for campaigns 
        in a day for one owner

        @param _rateLimit is in seconds since unix epoch. 
            For reference, 24 hours is 86400 seconds
    */
    function updateRateLimit(uint _rateLimit) external {
        if (msg.sender != contractOwner) {
            revert NotOwner();
        }
        rateLimit = _rateLimit;
    }

    /*
        This function allows the contract owner to update the maximum length of campaigns

        @param _campaignLength is in seconds since unix epoch. 
            For reference, 30 days is 2592000 seconds
    */
    function updateCampaignLength(uint _campaignLength) external {
        if (msg.sender != contractOwner) {
            revert NotOwner();
        }
        campaignLength = _campaignLength;
    }
}