// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TestTestTest {
    struct User {
        address userAddress;
        uint256 totalRequests; // Number of design review requests
        uint256 totalReviews; // Number of reviews provided
    }

    struct PostDesign {
        uint256 id;
        address owner;
        string info; // IPFS hash with some info, like: title, description and image url
        uint256 reward; // deposit reward for feedback providers
        uint256 reviewCount; // number of reviews received
        bool isCompleted; // flag to indicate if feedback reward is completed
        uint256[] reviewIds; // array to store review IDs for this design
    }

    struct ReviewDesign {
        uint256 id;
        address reviewer;
        uint256 designId;
        string comment; // IPFS hash for the comment
        uint256 posX; // X-coordinate for pinning comment on the image
        uint256 posY; // Y-coordinate for pinning comment on the image
        bool isRewarded; // flag to indicate if the reviewer has received the reward
        uint256 votes; // number of upvotes received
    }

    // Events
    event DesignCreated(
        uint256 designId,
        address owner,
        string info,
        uint256 reward
    );
    event ReviewCreated(
        uint256 reviewId,
        address reviewer,
        uint256 designId,
        string comment,
        uint256 posX,
        uint256 posY
    );
    event ReviewUpvoted(uint256 reviewId, address voter);
    event RewardClaimed(
        uint256 indexed designId,
        uint256 indexed reviewId,
        address indexed reviewer
    );

    // Mapping to store user data
    mapping(address => User) public users;

    // Mapping to store design data by design ID
    mapping(uint256 => PostDesign) public designs;

    // Mapping to store review data by review ID
    mapping(uint256 => ReviewDesign) public reviews;

    // Mapping to store user votes (prevents double voting)
    // mapping[reviewId][voterAddress] => hasVoted
    mapping(uint256 => mapping(address => bool)) public userVotes;

    uint256 public designCounter;
    uint256 public reviewCounter;

    function createDesign(string memory _info, uint256 _reward) public payable {
        require(msg.value == _reward, "Incorrect reward amount sent.");

        designCounter++;

        // Update user data
        User storage user = users[msg.sender];
        user.userAddress = msg.sender;
        user.totalRequests++;

        // Create new design struct
        designs[designCounter] = PostDesign(
            designCounter,
            msg.sender,
            _info,
            _reward,
            0,
            false,
            new uint256[](0)
        );

        emit DesignCreated(designCounter, msg.sender, _info, _reward);
    }

    function createReview(
        uint256 _designId,
        string memory _comment,
        uint256 _posX,
        uint256 _posY
    ) public {
        require(
            designs[_designId].isCompleted == false,
            "Design feedback process is completed."
        );

        reviewCounter++;

        // update user data
        User storage user = users[msg.sender];
        user.userAddress = msg.sender;
        user.totalReviews++;

        // Create new review
        reviews[reviewCounter] = ReviewDesign(
            reviewCounter,
            msg.sender,
            _designId,
            _comment,
            _posX,
            _posY,
            false,
            0
        );

        // Update review counter and add review ID to the design's reviewIds array
        designs[_designId].reviewCount++;
        designs[_designId].reviewIds.push(reviewCounter);

        emit ReviewCreated(
            reviewCounter,
            msg.sender,
            _designId,
            _comment,
            _posX,
            _posY
        );
    }

    // Get the reviews IDs for a design
    function getReviewIds(
        uint256 _designId
    ) public view returns (uint256[] memory) {
        return designs[_designId].reviewIds;
    }

    function upvoteReview(uint256 _reviewId) public {
        require(
            userVotes[_reviewId][msg.sender] == false,
            "User has already voted for this review."
        );

        // Update the number of votes for the review
        reviews[_reviewId].votes++;

        // Mark that the user has voted for this review
        userVotes[_reviewId][msg.sender] = true;

        emit ReviewUpvoted(_reviewId, msg.sender);
    }

    function claimReward(uint256 _designId) public {
        PostDesign storage design = designs[_designId];
        require(
            !design.isCompleted,
            "Rewards have already been claimed for this design."
        );
        require(design.reward > 0, "Reward amount must be greater than zero.");

        uint256[] memory topReviews = new uint256[](5);
        for (uint256 i = 0; i < design.reviewIds.length; i++) {
            uint256 currentReviewId = design.reviewIds[i];
            uint256 currentReviewVotes = reviews[currentReviewId].votes;

            for (uint256 j = 0; j < 5; j++) {
                if (currentReviewVotes > reviews[topReviews[j]].votes) {
                    for (uint256 k = 4; k > j; k--) {
                        topReviews[k] = topReviews[k - 1];
                    }
                    topReviews[j] = currentReviewId;
                    break;
                }
            }
        }

        uint256 userReviewPosition = 6; // Position outside of the top 5
        for (uint256 i = 0; i < 5; i++) {
            if (reviews[topReviews[i]].reviewer == msg.sender) {
                userReviewPosition = i;
                break;
            }
        }

        require(
            userReviewPosition < 5,
            "The user is not among the top 5 reviewers."
        );
        require(
            !reviews[topReviews[userReviewPosition]].isRewarded,
            "The user has already claimed the reward."
        );

        uint256 rewardAmount = design.reward / 5;
        payable(msg.sender).transfer(rewardAmount);

        // Decrease the remaining reward in the design
        design.reward -= rewardAmount;

        // Mark the review as rewarded
        reviews[topReviews[userReviewPosition]].isRewarded = true;

        bool allRewardsClaimed = true;
        for (uint256 i = 0; i < 5; i++) {
            if (!reviews[topReviews[i]].isRewarded) {
                allRewardsClaimed = false;
                break;
            }
        }

        if (allRewardsClaimed) {
            design.isCompleted = true;
        }

        emit RewardClaimed(
            _designId,
            reviews[topReviews[userReviewPosition]].id,
            msg.sender
        );
    }
}