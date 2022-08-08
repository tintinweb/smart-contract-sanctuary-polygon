/**
 *Submitted for verification at polygonscan.com on 2022-08-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract SubscriptionEthLive  {


// Events
    event SubscriptionCreation
    (
        address stream_host,
        uint256 streamer_id,
        string image_hash,
        string name,
        uint256 creation_time
    );

    event Registration
    (
        uint256 streamer_id,
        address participant_addr
    );

    event SponsorshipSubmited
    (
        uint256 streamer_id,
        uint256 value
    );

    event RatingSubmited
    (
        uint256 streamer_id,
        address reviewer_addr,
        address reviewed_addr,
        uint256 points
    );

    event CashOut
    (
        uint256 streamer_id,
        address participant_addr,
        uint256 reward
    );

    event SubscriptionReviewEnabled
    (
        uint256 streamer_id
    );

    event SubscriptionFinished
    (
        uint256 streamer_id
    );


    struct Subscription
    {
        address host_addr;
        SubscriptionState state;
        string image_hash;
        string name;
        uint256 pot;
        uint256 creation_time;
        uint256 enable_review_time;
    }

    struct Participant
    {
        address addr;
        uint256 points;
    }

    // Enums
    enum SubscriptionState { RegistrationOpen, ReviewEnabled, Finished }

    // Public variables
    mapping(uint256 => Subscription) public streamers; // Stores streamers data
    mapping(uint256 => mapping(address => Participant)) public streamer_participants; // Stores participant data
    // Rating history, enables correcting ratings and prevents rating
    mapping(uint256 => mapping(address => mapping(address => uint256))) public participant_ratings;
    uint256 public streamer_count; // Helps generating a new streamer id
    mapping(uint256 => mapping(address => bool)) public participant_has_cashed_out; // Helps preventing double cash out
    mapping(uint256 => uint256) public total_streamer_points; // Helps calculating pot splits
    uint256 entry_fee = 0.03 ether; // Subscription entry fee

    // Modifiers
    modifier paysEntryFee()
    {
        require(msg.value == entry_fee, "Amount not equal to pay fee");
        _;
    }

    modifier hasNotJoined(uint256 streamer_id)
    {
        require(streamer_participants[streamer_id][msg.sender].addr == address(0), "Participant has joined");
        _;
    }

    modifier hasJoined(uint256 streamer_id)
    {
        require(streamer_participants[streamer_id][msg.sender].addr != address(0), "Participant has not joined");
        _;
    }

    modifier participantExists(uint256 streamer_id, address participant_addr)
    {
        require(streamer_participants[streamer_id][participant_addr].addr != address(0), "Participant does not exists");
        _;
    }

    modifier pointsAreValid(uint256 points)
    {
        require(points <= 5, "Points are greater than 5");
        _;
    }

    modifier hasNotCashedOut(uint256 streamer_id, address participant_addr)
    {
        require(!participant_has_cashed_out[streamer_id][participant_addr], "Participant has already cashed out");
        _;
    }

    modifier isRegistrationOpen(uint256 streamer_id)
    {
        require(streamers[streamer_id].state == SubscriptionState.RegistrationOpen, "Subscription registration is not open");
        _;
    }

    modifier isReviewEnabled(uint256 streamer_id)
    {
        require(streamers[streamer_id].state == SubscriptionState.ReviewEnabled, "Subscription review is not enabled");
        _;
    }

    modifier isFinished(uint256 streamer_id)
    {
        require(streamers[streamer_id].state == SubscriptionState.Finished, "Subscription is not finished");
        _;
    }

    modifier isNotFinished(uint256 streamer_id)
    {
        require(streamers[streamer_id].state != SubscriptionState.Finished, "Subscription is finished");
        _;
    }

    modifier twoMonthFromCreation(uint256 streamer_id)
    {
        require(block.timestamp >= streamers[streamer_id].creation_time + 60 days, "time must be greater than 2 months");
        _;
    }

    modifier oneWeekFromReview(uint256 streamer_id)
    {
        require(block.timestamp >= streamers[streamer_id].enable_review_time + 7 days, "time must be greater than 1 week");
        _;
    }

    modifier isSubscriptionHost(uint256 streamer_id)
    {
        require(streamers[streamer_id].host_addr == msg.sender, "You are not the streamer host");
        _;
    }

    function createSubscription(string memory image_hash, string memory _name) public
    {
        streamer_count += 1;
        uint256 date_now = block.timestamp;
        streamers[streamer_count] = Subscription(msg.sender, SubscriptionState.RegistrationOpen, image_hash, _name, 0, date_now, date_now);
        emit SubscriptionCreation(msg.sender, streamer_count, image_hash,_name, date_now);
    }



    function join(
        uint256 streamer_id
    ) public payable paysEntryFee hasNotJoined(streamer_id) isRegistrationOpen(streamer_id)
    {
        Participant memory participant = Participant(msg.sender, 0);
        streamer_participants[streamer_id][msg.sender] = participant;
        emit Registration(streamer_id, msg.sender);
    }

    function sponsor(
        uint256 streamer_id
    ) public payable isNotFinished(streamer_id)
    {
        emit SponsorshipSubmited(streamer_id, msg.value);
    }



    function enableSubscriptionReview(uint256 streamer_id) public isSubscriptionHost(streamer_id)
    {
        streamers[streamer_id].state = SubscriptionState.ReviewEnabled;
        streamers[streamer_id].enable_review_time = block.timestamp;
        emit SubscriptionReviewEnabled(streamer_id);
    }

    function finishSubscription(uint256 streamer_id) public isSubscriptionHost(streamer_id)
    {
        streamers[streamer_id].state = SubscriptionState.Finished;
        emit SubscriptionFinished(streamer_id);
    }

    function forceFinishSubscription(uint256 streamer_id) public isRegistrationOpen(streamer_id) twoMonthFromCreation(streamer_id)
    {
        streamers[streamer_id].state = SubscriptionState.Finished;
        emit SubscriptionFinished(streamer_id);
    }

    function forceFinishSubscriptionFromReview(uint256 streamer_id) public isReviewEnabled(streamer_id) oneWeekFromReview(streamer_id)
    {
        streamers[streamer_id].state = SubscriptionState.Finished;
        emit SubscriptionFinished(streamer_id);
    }
}