pragma solidity ^0.8.0;

contract GameDevBribeContract {
    struct EngagementData {
        uint256 timestamp;
        string adId;
        uint256 adImpressions;
    }

    struct Offer {
        address advertiser;
        uint256 amount;
        bool accepted;
    }

    mapping(address => mapping(address => EngagementData[])) public userEngagement;
    mapping(address => Offer) public highestEngagementOffers;

    event AnalyticsDataStored(
        address indexed developer,
        address indexed user,
        uint256 indexed index,
        uint256 timestamp,
        string adId,
        uint256 impressions
    );

    event OfferMade(
        address indexed developer,
        address indexed advertiser,
        uint256 amount
    );

    event OfferAccepted(
        address indexed developer,
        address indexed advertiser,
        uint256 amount
    );

    function storeEngagementData(
        address developer,
        string memory adId,
        uint256 impressions
    ) external {
        EngagementData memory newData = EngagementData({
            timestamp: block.timestamp,
            adId: adId,
            adImpressions: impressions
        });

        userEngagement[developer][msg.sender].push(newData);
        uint256 index = userEngagement[developer][msg.sender].length - 1;

        emit AnalyticsDataStored(
            developer,
            msg.sender,
            index,
            newData.timestamp,
            newData.adId,
            newData.adImpressions
        );

        updateHighestEngagementOffer(developer, msg.sender);
    }

    function updateHighestEngagementOffer(address developer, address user) internal {
        uint256 engagementCount = userEngagement[developer][user].length;
        uint256 currentHighestEngagementCount = userEngagement[developer][highestEngagementOffers[developer].advertiser].length;

        if (engagementCount > currentHighestEngagementCount) {
            highestEngagementOffers[developer] = Offer({
                advertiser: user,
                amount: 0,
                accepted: false
            });
        }
    }

    function makeOffer(address developer, uint256 amount) external payable {
        require(amount > 0, "Min amount needed");
        require(highestEngagementOffers[developer].advertiser != address(0), "Nothing found");

        highestEngagementOffers[developer].amount = amount;
        emit OfferMade(developer, msg.sender, amount);
    }

    function acceptOffer(address developer) external {
        Offer storage offer = highestEngagementOffers[developer];

        require(offer.advertiser != address(0), "No developer analytics to see here");
        require(offer.advertiser == msg.sender, "Only the dev can accpt an offer");
        require(offer.amount > 0, "No offer exsts yet");
        require(!offer.accepted, "Offer in progress, come back when you're sober");

        offer.accepted = true;
        emit OfferAccepted(developer, offer.advertiser, offer.amount);
    }
    
    function getEngagementDataCount(address developer, address user) external view returns (uint256) {
        return userEngagement[developer][user].length;
    }

    function getEngagementData(address developer, address user, uint256 index) external view returns (EngagementData memory) {
        require(index < userEngagement[developer][user].length, "Stack overflow");
        return userEngagement[developer][user][index];
    }
}