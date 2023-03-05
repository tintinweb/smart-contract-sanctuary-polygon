//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CommonLib.sol";
import "./RewardLib.sol";
import "./AchievementLib.sol";
import "./AchievementCommonLib.sol";
import "../interfaces/IPeeranhaToken.sol";
import "../interfaces/IPeeranhaCommunity.sol";
import "../interfaces/IPeeranhaContent.sol";


/// @title Users
/// @notice Provides information about registered user
/// @dev Users information is stored in the mapping on the main contract
library UserLib {
  int32 constant START_USER_RATING = 10;
  bytes32 constant DEFAULT_IPFS = bytes32(0xc09b19f65afd0df610c90ea00120bccd1fc1b8c6e7cdbe440376ee13e156a5bc);

  int16 constant MINIMUM_RATING = -300;
  int16 constant POST_QUESTION_ALLOWED = 0;
  int16 constant POST_REPLY_ALLOWED = 0;
  int16 constant POST_COMMENT_ALLOWED = 35;
  int16 constant POST_OWN_COMMENT_ALLOWED = 0;

  int16 constant UPVOTE_POST_ALLOWED = 35;
  int16 constant DOWNVOTE_POST_ALLOWED = 100;
  int16 constant UPVOTE_REPLY_ALLOWED = 35;
  int16 constant DOWNVOTE_REPLY_ALLOWED = 100;
  int16 constant VOTE_COMMENT_ALLOWED = 0;
  int16 constant CANCEL_VOTE = 0;

  int16 constant UPDATE_PROFILE_ALLOWED = 0;

  uint8 constant ENERGY_DOWNVOTE_QUESTION = 5;
  uint8 constant ENERGY_DOWNVOTE_ANSWER = 3;
  uint8 constant ENERGY_DOWNVOTE_COMMENT = 2;
  uint8 constant ENERGY_UPVOTE_QUESTION = 1;
  uint8 constant ENERGY_UPVOTE_ANSWER = 1;
  uint8 constant ENERGY_VOTE_COMMENT = 1;
  uint8 constant ENERGY_FORUM_VOTE_CANCEL = 1;
  uint8 constant ENERGY_POST_QUESTION = 10;
  uint8 constant ENERGY_POST_ANSWER = 6;
  uint8 constant ENERGY_POST_COMMENT = 4;
  uint8 constant ENERGY_MODIFY_ITEM = 2;
  uint8 constant ENERGY_DELETE_ITEM = 2;

  uint8 constant ENERGY_MARK_REPLY_AS_CORRECT = 1;
  uint8 constant ENERGY_UPDATE_PROFILE = 1;
  uint8 constant ENERGY_CREATE_TAG = 75;            // only Admin
  uint8 constant ENERGY_CREATE_COMMUNITY = 125;     // only admin
  uint8 constant ENERGY_FOLLOW_COMMUNITY = 1;
  uint8 constant ENERGY_REPORT_PROFILE = 5;         //
  uint8 constant ENERGY_REPORT_QUESTION = 3;        //
  uint8 constant ENERGY_REPORT_ANSWER = 2;          //
  uint8 constant ENERGY_REPORT_COMMENT = 1;         //

  struct User {
    CommonLib.IpfsHash ipfsDoc;
    uint16 energy;
    uint16 lastUpdatePeriod;
    uint32[] followedCommunities;
    bytes32[] roles;
  }

  struct UserRatingCollection {
    mapping(address => CommunityRatingForUser) communityRatingForUser;
  }

  struct CommunityRatingForUser {
    mapping(uint32 => UserRating) userRating;   //uint32 - community id
    uint16[] rewardPeriods; // periods when the rating was changed
    mapping(uint16 => RewardLib.UserPeriodRewards) userPeriodRewards; // period
  }

  struct UserRating {
    int32 rating;
    bool isActive;
  }

  struct DataUpdateUserRating {
    uint32 ratingToReward;
    uint32 penalty;
    int32 changeRating;
    int32 ratingToRewardChange;
  }


  /// users The mapping containing all users
  struct UserContext {
    UserLib.UserCollection users;     // rename to usersCollection
    UserLib.UserRatingCollection userRatingCollection;
    RewardLib.PeriodRewardContainer periodRewardContainer;
    AchievementLib.AchievementsContainer achievementsContainer;
    
    IPeeranhaToken peeranhaToken;
    IPeeranhaCommunity peeranhaCommunity;
    IPeeranhaContent peeranhaContent;
  }
  
  struct UserCollection {
    mapping(address => User) users;
    address[] userList;
  }

  struct UserRatingChange {
    address user;
    int32 rating;
  }

  struct UserDelegationCollection {
    mapping(address => uint) userDelegations;
    address delegateUser;
  }

  enum Action {
    NONE,
    PublicationPost,
    PublicationReply,
    PublicationComment,
    EditItem,
    DeleteItem,
    UpVotePost,
    DownVotePost,
    UpVoteReply,
    DownVoteReply,
    VoteComment,
    CancelVote,
    BestReply,
    UpdateProfile,
    FollowCommunity
  }

  enum ActionRole {
    NONE,
    Bot,
    Admin,
    Dispatcher,
    AdminOrCommunityModerator,
    AdminOrCommunityAdmin,
    CommunityAdmin,
    CommunityModerator
  }

  event UserCreated(address indexed userAddress);
  event UserUpdated(address indexed userAddress);
  event FollowedCommunity(address indexed userAddress, uint32 indexed communityId);
  event UnfollowedCommunity(address indexed userAddress, uint32 indexed communityId);


  /// @notice Create new user info record
  /// @param self The mapping containing all users
  /// @param userAddress Address of the user to create 
  /// @param ipfsHash IPFS hash of document with user information
  function create(
    UserCollection storage self,
    address userAddress,
    bytes32 ipfsHash
  ) internal {
    // TODO CHECK ipfsHash ? not null
    require(self.users[userAddress].ipfsDoc.hash == bytes32(0x0), "user_exists");

    User storage user = self.users[userAddress];
    user.ipfsDoc.hash = ipfsHash;
    user.energy = getStatusEnergy();
    user.lastUpdatePeriod = RewardLib.getPeriod();

    self.userList.push(userAddress);

    emit UserCreated(userAddress);
  }

  /// @notice Create new user info record
  /// @param self The mapping containing all users
  /// @param userAddress Address of the user to create 
  function createIfDoesNotExist(
    UserCollection storage self,
    address userAddress
  ) internal {
    if (!UserLib.isExists(self, userAddress)) {
      UserLib.create(self, userAddress, DEFAULT_IPFS);
    }
  }

  /// @notice Update new user info record
  /// @param userContext All information about users
  /// @param userAddress Address of the user to update
  /// @param ipfsHash IPFS hash of document with user information
  function update(
    UserContext storage userContext,
    address userAddress,
    bytes32 ipfsHash
  ) internal {
    // TODO CHECK ipfsHash ? not null
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.UpdateProfile
    );
    user.ipfsDoc.hash = ipfsHash;   // todo add check? gas

    emit UserUpdated(userAddress);
  }

  /// @notice User follows community
  /// @param userContext All information about users
  /// @param userAddress Address of the user to update
  /// @param communityId User follows om this community
  function followCommunity(
    UserContext storage userContext,
    address userAddress,
    uint32 communityId
  ) public {
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.FollowCommunity
    );

    bool isAdded;
    for (uint i; i < user.followedCommunities.length; i++) {
      require(user.followedCommunities[i] != communityId, "already_followed");

      if (user.followedCommunities[i] == 0 && !isAdded) {
        user.followedCommunities[i] = communityId;
        isAdded = true;
      }
    }
    if (!isAdded)
      user.followedCommunities.push(communityId);

    emit FollowedCommunity(userAddress, communityId);
  }

  /// @notice User unfollows community
  /// @param userContext The mapping containing all users
  /// @param userAddress Address of the user to update
  /// @param communityId User follows om this community
  function unfollowCommunity(
    UserContext storage userContext,
    address userAddress,
    uint32 communityId
  ) public {
    User storage user = checkRatingAndEnergy(
      userContext,
      userAddress,
      userAddress,
      0,
      Action.FollowCommunity
    );

    for (uint i; i < user.followedCommunities.length; i++) {
      if (user.followedCommunities[i] == communityId) {
        delete user.followedCommunities[i]; //method rewrite to 0
        
        emit UnfollowedCommunity(userAddress, communityId);
        return;
      }
    }
    revert("comm_not_followed");
  }

  /// @notice Get the number of users
  /// @param self The mapping containing all users
  function getUsersCount(UserCollection storage self) internal view returns (uint256 count) {
    return self.userList.length;
  }

  /// @notice Get user info by index
  /// @param self The mapping containing all users
  /// @param index Index of the user to get
  function getUserByIndex(UserCollection storage self, uint256 index) internal view returns (User storage) {
    address addr = self.userList[index];
    return self.users[addr];
  }

  /// @notice Get user info by address
  /// @param self The mapping containing all users
  /// @param addr Address of the user to get
  function getUserByAddress(UserCollection storage self, address addr) internal view returns (User storage) {
    User storage user = self.users[addr];
    require(user.ipfsDoc.hash != bytes32(0x0), "user_not_found");
    return user;
  }

  function getUserRating(UserRatingCollection storage self, address addr, uint32 communityId) internal view returns (int32) {
    return self.communityRatingForUser[addr].userRating[communityId].rating;
  }

  function getUserRatingCollection(UserRatingCollection storage self, address addr, uint32 communityId) internal view returns (UserRating memory) {
    return self.communityRatingForUser[addr].userRating[communityId];
  }

  /// @notice Check user existence
  /// @param self The mapping containing all users
  /// @param addr Address of the user to check
  function isExists(UserCollection storage self, address addr) internal view returns (bool) {
    return self.users[addr].ipfsDoc.hash != bytes32(0x0);
  }

  function updateUsersRating(UserLib.UserContext storage userContext, AchievementLib.AchievementsMetadata storage achievementsMetadata, UserRatingChange[] memory usersRating, uint32 communityId) public {
    for (uint i; i < usersRating.length; i++) {
      updateUserRating(userContext, achievementsMetadata, usersRating[i].user, usersRating[i].rating, communityId);
    }
  }

  function updateUserRating(UserLib.UserContext storage userContext, AchievementLib.AchievementsMetadata storage achievementsMetadata, address userAddr, int32 rating, uint32 communityId) public {
    if (rating == 0) return;
    updateRatingBase(userContext, achievementsMetadata, userAddr, rating, communityId);
  }

  function updateRatingBase(UserContext storage userContext, AchievementLib.AchievementsMetadata storage achievementsMetadata, address userAddr, int32 rating, uint32 communityId) public {
    uint16 currentPeriod = RewardLib.getPeriod();
    
    CommunityRatingForUser storage userCommunityRating = userContext.userRatingCollection.communityRatingForUser[userAddr];
    // Initialize user rating in the community if this is the first rating change
    if (!userCommunityRating.userRating[communityId].isActive) {
      userCommunityRating.userRating[communityId].rating = START_USER_RATING;
      userCommunityRating.userRating[communityId].isActive = true;
    }

    uint256 pastPeriodsCount = userCommunityRating.rewardPeriods.length;
    
    // If this is the first user rating change in any community
    if (pastPeriodsCount == 0 || userCommunityRating.rewardPeriods[pastPeriodsCount - 1] != currentPeriod) {
      RewardLib.PeriodRewardShares storage periodRewardShares = userContext.periodRewardContainer.periodRewardShares[currentPeriod];
      periodRewardShares.activeUsersInPeriod.push(userAddr);
      userCommunityRating.rewardPeriods.push(currentPeriod);
    } else {  // rewrite
      pastPeriodsCount--;
    }

    RewardLib.UserPeriodRewards storage userPeriodRewards = userCommunityRating.userPeriodRewards[currentPeriod];
    RewardLib.PeriodRating storage userPeriodCommuntiyRating = userPeriodRewards.periodRating[communityId];

    // If this is the first user rating change in this period for current community
    if (!userPeriodCommuntiyRating.isActive) {
      userPeriodRewards.rewardCommunities.push(communityId);
    }

    uint16 previousPeriod;
    if(pastPeriodsCount > 0) {
      previousPeriod = userCommunityRating.rewardPeriods[pastPeriodsCount - 1];
    } else {
      // this means that there is no other previous period
      previousPeriod = currentPeriod;
    }

    updateUserPeriodRating(userContext, userCommunityRating, userAddr, rating, communityId, currentPeriod, previousPeriod);

    userCommunityRating.userRating[communityId].rating += rating;

    if (rating > 0) {
      AchievementCommonLib.AchievementsType[] memory newArray = new AchievementCommonLib.AchievementsType[](2);
      newArray[0] = AchievementCommonLib.AchievementsType.Rating;
      newArray[1] = AchievementCommonLib.AchievementsType.SoulRating; // {} ???
      AchievementLib.updateUserAchievements(userContext.achievementsContainer, achievementsMetadata, userAddr, newArray, int64(userCommunityRating.userRating[communityId].rating), communityId);
    }
  }

  function updateUserPeriodRating(UserContext storage userContext, CommunityRatingForUser storage userCommunityRating, address userAddr, int32 rating, uint32 communityId, uint16 currentPeriod, uint16 previousPeriod) private {
    RewardLib.PeriodRating storage currentPeriodRating = userCommunityRating.userPeriodRewards[currentPeriod].periodRating[communityId];
    bool isFirstTransactionInPeriod = !currentPeriodRating.isActive;

    DataUpdateUserRating memory dataUpdateUserRatingCurrentPeriod;
    dataUpdateUserRatingCurrentPeriod.ratingToReward = currentPeriodRating.ratingToReward;
    dataUpdateUserRatingCurrentPeriod.penalty = currentPeriodRating.penalty;
    
    if (currentPeriod == previousPeriod) {   //first period rating?
      dataUpdateUserRatingCurrentPeriod.changeRating = rating;

    } else {
      RewardLib.PeriodRating storage previousPeriodRating = userCommunityRating.userPeriodRewards[previousPeriod].periodRating[communityId];
      
      DataUpdateUserRating memory dataUpdateUserRatingPreviousPeriod;
      dataUpdateUserRatingPreviousPeriod.ratingToReward = previousPeriodRating.ratingToReward;
      dataUpdateUserRatingPreviousPeriod.penalty = previousPeriodRating.penalty;
      
      if (previousPeriod != currentPeriod - 1) {
        if (isFirstTransactionInPeriod && dataUpdateUserRatingPreviousPeriod.penalty > dataUpdateUserRatingPreviousPeriod.ratingToReward) {
          dataUpdateUserRatingCurrentPeriod.changeRating = rating + CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
        } else {
          dataUpdateUserRatingCurrentPeriod.changeRating = rating;
        }
      } else {
        if (isFirstTransactionInPeriod && dataUpdateUserRatingPreviousPeriod.penalty > dataUpdateUserRatingPreviousPeriod.ratingToReward) {
          dataUpdateUserRatingCurrentPeriod.changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
        }

        int32 differentRatingPreviousPeriod; // name    // move to if()?
        int32 differentRatingCurrentPeriod;
        if (rating > 0 && dataUpdateUserRatingPreviousPeriod.penalty > 0) {
          if (dataUpdateUserRatingPreviousPeriod.ratingToReward == 0) {
            dataUpdateUserRatingCurrentPeriod.changeRating += rating;
          } else {
            differentRatingPreviousPeriod = rating - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
            if (differentRatingPreviousPeriod >= 0) {
              dataUpdateUserRatingPreviousPeriod.changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty);
              dataUpdateUserRatingCurrentPeriod.changeRating = differentRatingPreviousPeriod;
            } else {
              dataUpdateUserRatingPreviousPeriod.changeRating = rating;
            }
          }
        } else if (rating < 0 && dataUpdateUserRatingPreviousPeriod.ratingToReward > dataUpdateUserRatingPreviousPeriod.penalty) {

          differentRatingCurrentPeriod = CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty) - rating;   // penalty is always positive, we need add rating to penalty
          if (differentRatingCurrentPeriod > CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward)) {
            dataUpdateUserRatingCurrentPeriod.changeRating -= CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty);  // - current ratingToReward
            dataUpdateUserRatingPreviousPeriod.changeRating = rating - dataUpdateUserRatingCurrentPeriod.changeRating;                                       // + previous penalty
            if (CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) < CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) - dataUpdateUserRatingPreviousPeriod.changeRating) {
              int32 extraPenalty = CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - dataUpdateUserRatingPreviousPeriod.changeRating;
              dataUpdateUserRatingPreviousPeriod.changeRating += extraPenalty;  // - extra previous penalty
              dataUpdateUserRatingCurrentPeriod.changeRating -= extraPenalty;   // + extra current penalty
            }
          } else {
            dataUpdateUserRatingCurrentPeriod.changeRating = rating;
            // dataUpdateUserRatingCurrentPeriod.changeRating += 0;
          }
        } else {
          dataUpdateUserRatingCurrentPeriod.changeRating += rating;
        }
      }

      if (dataUpdateUserRatingPreviousPeriod.changeRating != 0) {
        if (dataUpdateUserRatingPreviousPeriod.changeRating > 0) previousPeriodRating.penalty -= CommonLib.toUInt32FromInt32(dataUpdateUserRatingPreviousPeriod.changeRating);
        else previousPeriodRating.penalty += CommonLib.toUInt32FromInt32(-dataUpdateUserRatingPreviousPeriod.changeRating);

        dataUpdateUserRatingPreviousPeriod.ratingToRewardChange = getRatingToRewardChange(CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty), CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingPreviousPeriod.penalty) + dataUpdateUserRatingPreviousPeriod.changeRating);
        if (dataUpdateUserRatingPreviousPeriod.ratingToRewardChange > 0) {
          userContext.periodRewardContainer.periodRewardShares[previousPeriod].totalRewardShares += CommonLib.toUInt32FromInt32(getRewardShare(userContext, userAddr, previousPeriod, dataUpdateUserRatingPreviousPeriod.ratingToRewardChange));
        } else {
          userContext.periodRewardContainer.periodRewardShares[previousPeriod].totalRewardShares -= CommonLib.toUInt32FromInt32(-getRewardShare(userContext, userAddr, previousPeriod, dataUpdateUserRatingPreviousPeriod.ratingToRewardChange));
        }
      }
    }

    if (dataUpdateUserRatingCurrentPeriod.changeRating != 0) {
      dataUpdateUserRatingCurrentPeriod.ratingToRewardChange = getRatingToRewardChange(CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty), CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty) + dataUpdateUserRatingCurrentPeriod.changeRating);
      if (dataUpdateUserRatingCurrentPeriod.ratingToRewardChange > 0) {
        userContext.periodRewardContainer.periodRewardShares[currentPeriod].totalRewardShares += CommonLib.toUInt32FromInt32(getRewardShare(userContext, userAddr, currentPeriod, dataUpdateUserRatingCurrentPeriod.ratingToRewardChange));
      } else {
        userContext.periodRewardContainer.periodRewardShares[currentPeriod].totalRewardShares -= CommonLib.toUInt32FromInt32(-getRewardShare(userContext, userAddr, currentPeriod, dataUpdateUserRatingCurrentPeriod.ratingToRewardChange));
      }

      int32 changeRating;
      if (dataUpdateUserRatingCurrentPeriod.changeRating > 0) {
        changeRating = dataUpdateUserRatingCurrentPeriod.changeRating - CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.penalty);
        if (changeRating >= 0) {
          currentPeriodRating.penalty = 0;
          currentPeriodRating.ratingToReward += CommonLib.toUInt32FromInt32(changeRating);
        } else {
          currentPeriodRating.penalty = CommonLib.toUInt32FromInt32(-changeRating);
        }

      } else if (dataUpdateUserRatingCurrentPeriod.changeRating < 0) {
        changeRating = CommonLib.toInt32FromUint256(dataUpdateUserRatingCurrentPeriod.ratingToReward) + dataUpdateUserRatingCurrentPeriod.changeRating;
        if (changeRating <= 0) {
          currentPeriodRating.ratingToReward = 0;
          currentPeriodRating.penalty += CommonLib.toUInt32FromInt32(-changeRating);
        } else {
          currentPeriodRating.ratingToReward = CommonLib.toUInt32FromInt32(changeRating);
        }
      }
    }

    // Activate period rating for community if this is the first change
    if (isFirstTransactionInPeriod) {
      currentPeriodRating.isActive = true;
    }
  }

  function getRewardShare(UserLib.UserContext storage userContext, address userAddr, uint16 period, int32 rating) private view returns (int32) { // FIX
    return CommonLib.toInt32FromUint256(userContext.peeranhaToken.getBoost(userAddr, period)) * rating;
  }

  function getRatingToRewardChange(int32 previosRatingToReward, int32 newRatingToReward) private pure returns (int32) {
    if (previosRatingToReward >= 0 && newRatingToReward >= 0) return newRatingToReward - previosRatingToReward;
    else if(previosRatingToReward > 0 && newRatingToReward < 0) return -previosRatingToReward;
    else if(previosRatingToReward < 0 && newRatingToReward > 0) return newRatingToReward;
    return 0; // from negative to negative
  }

  function checkRatingAndEnergy(
    UserContext storage userContext,
    address actionCaller,
    address dataUser,
    uint32 communityId,
    Action action
  )
    internal 
    returns (User storage)
  {
    UserLib.User storage user = UserLib.getUserByAddress(userContext.users, actionCaller);
    int32 userRating = UserLib.getUserRating(userContext.userRatingCollection, actionCaller, communityId);
        
    (int16 ratingAllowed, string memory message, uint8 energy) = getRatingAndRatingForAction(actionCaller, dataUser, action);
    require(userRating >= ratingAllowed, message);
    reduceEnergy(user, energy);

    return user;
  }

  function getRatingAndRatingForAction( // TODO getRatingAndRatingForAction -> getRatingAndEnergyForAction
    address actionCaller,
    address dataUser,
    Action action
  ) private pure returns (int16 ratingAllowed, string memory message, uint8 energy) {
    if (action == Action.NONE) {
    } else if (action == Action.PublicationPost) {
      ratingAllowed = POST_QUESTION_ALLOWED;
      message = "low_rating_post";
      energy = ENERGY_POST_QUESTION;

    } else if (action == Action.PublicationReply) {
      ratingAllowed = POST_REPLY_ALLOWED;
      message = "low_rating_reply";
      energy = ENERGY_POST_ANSWER;

    } else if (action == Action.PublicationComment) {
      if (actionCaller == dataUser) {
        ratingAllowed = POST_OWN_COMMENT_ALLOWED;
      } else {
        ratingAllowed = POST_COMMENT_ALLOWED;
      }
      message = "low_rating_comment";
      energy = ENERGY_POST_COMMENT;

    } else if (action == Action.EditItem) {
      require(actionCaller == dataUser, "not_allowed_edit");
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_edit";
      energy = ENERGY_MODIFY_ITEM;

    } else if (action == Action.DeleteItem) {
      require(actionCaller == dataUser, "not_allowed_delete");
      ratingAllowed = 0;
      message = "low_rating_delete"; // delete own item?
      energy = ENERGY_DELETE_ITEM;

    } else if (action == Action.UpVotePost) {
      require(actionCaller != dataUser, "not_allowed_vote_post");   // toDO unittest post/reply/comment upvote+downvote
      ratingAllowed = UPVOTE_POST_ALLOWED;
      message = "low_rating_upvote_post";
      energy = ENERGY_UPVOTE_QUESTION;

    } else if (action == Action.UpVoteReply) {
      require(actionCaller != dataUser, "not_allowed_vote_reply");
      ratingAllowed = UPVOTE_REPLY_ALLOWED;
      message = "low_rating_upvote_reply";
      energy = ENERGY_UPVOTE_ANSWER;

    } else if (action == Action.VoteComment) {
      require(actionCaller != dataUser, "not_allowed_vote_comment");
      ratingAllowed = VOTE_COMMENT_ALLOWED;
      message = "low_rating_vote_comment";
      energy = ENERGY_VOTE_COMMENT;

    } else if (action == Action.DownVotePost) {
      require(actionCaller != dataUser, "not_allowed_vote_post");
      ratingAllowed = DOWNVOTE_POST_ALLOWED;
      message = "low_rating_downvote_post";
      energy = ENERGY_DOWNVOTE_QUESTION;

    } else if (action == Action.DownVoteReply) {
      require(actionCaller != dataUser, "not_allowed_vote_reply");
      ratingAllowed = DOWNVOTE_REPLY_ALLOWED;
      message = "low_rating_downvote_reply";
      energy = ENERGY_DOWNVOTE_ANSWER;

    } else if (action == Action.CancelVote) {
      ratingAllowed = CANCEL_VOTE;
      message = "low_rating_cancel_vote";
      energy = ENERGY_FORUM_VOTE_CANCEL;

    } else if (action == Action.BestReply) {
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_mark_best";
      energy = ENERGY_MARK_REPLY_AS_CORRECT;

    } else if (action == Action.UpdateProfile) {
      energy = ENERGY_UPDATE_PROFILE;
      message = "low_update_profile";   //TODO uniTest

    } else if (action == Action.FollowCommunity) {
      ratingAllowed = MINIMUM_RATING;
      message = "low_rating_follow_comm";
      energy = ENERGY_FOLLOW_COMMUNITY;

    } else {
      revert("not_allowed_action");
    }
  }

  function reduceEnergy(UserLib.User storage user, uint8 energy) internal {    
    uint16 currentPeriod = RewardLib.getPeriod();
    uint32 periodsHavePassed = currentPeriod - user.lastUpdatePeriod;

    uint16 userEnergy;
    if (periodsHavePassed == 0) {
      userEnergy = user.energy;
    } else {
      userEnergy = getStatusEnergy();
      user.lastUpdatePeriod = currentPeriod;
    }

    require(userEnergy >= energy, "low_energy");
    user.energy = userEnergy - energy;
  }

  function getStatusEnergy() internal pure returns (uint16) {
    return 1000;
  }

  function getPeriodRewardShares(UserContext storage userContext, uint16 period) internal view returns(RewardLib.PeriodRewardShares memory) {
    return userContext.periodRewardContainer.periodRewardShares[period];
  }

  function getUserRewardCommunities(UserContext storage userContext, address user, uint16 rewardPeriod) internal view returns(uint32[] memory) {
    return userContext.userRatingCollection.communityRatingForUser[user].userPeriodRewards[rewardPeriod].rewardCommunities;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/// @title CommonLib
/// @notice
/// @dev
library CommonLib {
  uint16 constant QUICK_REPLY_TIME_SECONDS = 900; // 6
  address public constant BOT_ADDRESS = 0x0000000000000000000000000000000000000001;

  enum MessengerType {
      Unknown,
      Telegram,
      Discord,
      Slack
  }

  struct IpfsHash {
      bytes32 hash;
      bytes32 hash2; // Not currently used and added for the future compatibility
  }

  /// @notice get timestamp in uint32 format
  function getTimestamp() internal view returns (uint32) {
    return SafeCastUpgradeable.toUint32(block.timestamp);
  }

  function toInt32(int value) internal pure returns (int32) {
    return SafeCastUpgradeable.toInt32(value);
  }

  function toInt32FromUint256(uint256 value) internal pure returns (int32) {
    int256 buffValue = SafeCastUpgradeable.toInt256(value);
    return SafeCastUpgradeable.toInt32(buffValue);
  }

  function toUInt32FromInt32(int256 value) internal pure returns (uint32) {
    uint256 buffValue = SafeCastUpgradeable.toUint256(value);
    return SafeCastUpgradeable.toUint32(buffValue);
  }

  /**
  * @dev Returns the largest of two numbers.
  */
  function maxInt32(int32 a, int32 b) internal pure returns (int32) {
    return a >= b ? a : b;
  }

  /**
  * @dev Returns the smallest of two numbers.
  */
  function minInt32(int32 a, int32 b) internal pure returns (int32) {
    return a < b ? a : b;
  }

  function minUint256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function isEmptyIpfs (
      bytes32 hash
  ) internal pure returns(bool) {
      return hash == bytes32(0x0);
  }

  function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
    bytes memory tempEmptyStringTest = bytes(source);
    if (tempEmptyStringTest.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
  }

  function composeMessengerSenderProperty(MessengerType messengerType, string memory handle) internal pure returns (bytes32 result) {
    return bytes32(uint256(messengerType)) | stringToBytes32(handle);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CommonLib.sol";
import "./UserLib.sol";


/// @title RewardLib
/// @notice
/// @dev
library RewardLib {
  uint256 constant PERIOD_LENGTH = 3600;          // 7 day = 1 period //
  uint256 constant START_PERIOD_TIME = 1666375400;  // June 15, 2022 12:00:00 AM GMT

  struct PeriodRating {
    uint32 ratingToReward;
    uint32 penalty;
    bool isActive;
  }

  struct PeriodRewardContainer {
    mapping(uint16 => PeriodRewardShares) periodRewardShares; // period
  }

  struct PeriodRewardShares {
    uint256 totalRewardShares;
    address[] activeUsersInPeriod;
  }

  struct UserPeriodRewards {
    uint32[] rewardCommunities;
    mapping(uint32 => PeriodRating) periodRating;  //communityID
  }


  /// @notice Get current perion
  function getPeriod() internal view returns (uint16) {
    return uint16((CommonLib.getTimestamp() - START_PERIOD_TIME) / PERIOD_LENGTH);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPeeranhaNFT.sol";
import "./AchievementCommonLib.sol";


/// @title AchievementLib
/// @notice
/// @dev
library AchievementLib {
  struct AchievementConfig {
    uint64 factCount;
    uint64 maxCount;
    int64 lowerBound;
    AchievementCommonLib.AchievementsType achievementsType;
  }

  struct AchievementsContainer {
    mapping(uint64 => AchievementConfig) achievementsConfigs;
    mapping(address => mapping(uint64 => bool)) userAchievementsIssued;
    uint64 achievementsCount;
    IPeeranhaNFT peeranhaNFT;
  }

  struct AchievementsMetadata {
    mapping(uint64 => AchievementMetadata) metadata;  // achievementId
  }

  struct AchievementMetadata {
    mapping(uint8 => bytes32) properties;
    uint32 communityId;
  }

  function configureNewAchievement(
    AchievementsContainer storage achievementsContainer,
    AchievementsMetadata storage achievementsMetadata,
    uint64 maxCount,
    int64 lowerBound,
    string memory achievementURI,
    uint32 communityId,
    AchievementCommonLib.AchievementsType achievementsType
  ) 
    internal 
  {
    uint64 achievementId = ++achievementsContainer.achievementsCount;
    AchievementLib.AchievementConfig storage achievementConfig = achievementsContainer.achievementsConfigs[achievementId];
    achievementConfig.maxCount = maxCount;
    achievementConfig.lowerBound = lowerBound;
    achievementConfig.achievementsType = achievementsType;
    if (communityId != 0) {
      achievementsMetadata.metadata[achievementId].communityId = communityId;
    }

    achievementsContainer.peeranhaNFT.configureNewAchievementNFT(achievementId, maxCount, achievementURI, achievementsType);
  }

  function updateUserAchievements(
    AchievementsContainer storage achievementsContainer,
    AchievementsMetadata storage achievementsMetadata,
    address user,
    AchievementCommonLib.AchievementsType[] memory achievementsTypes,
    int64 currentValue,
    uint32 communityId
  )
    internal
  {
    AchievementConfig storage achievementConfig;
    for (uint64 i = 1; i <= achievementsContainer.achievementsCount; i++) { /// optimize ??
      achievementConfig = achievementsContainer.achievementsConfigs[i];
      
      for (uint j; j < achievementsTypes.length; j++) {
        if(achievementsTypes[j] == achievementConfig.achievementsType) {
          if (
            achievementsMetadata.metadata[i].communityId != communityId &&
            achievementsMetadata.metadata[i].communityId != 0
          ) continue;
          if (!AchievementCommonLib.isAchievementAvailable(achievementConfig.maxCount, achievementConfig.factCount)) continue;
          if (achievementConfig.lowerBound > currentValue) continue;
          if (achievementsContainer.userAchievementsIssued[user][i]) continue; //already issued
          achievementConfig.factCount++;
          achievementsContainer.userAchievementsIssued[user][i] = true;
          achievementsContainer.peeranhaNFT.mint(user, i);
        }
      }
    }
  }

  function mintManualNFT(
    AchievementsContainer storage achievementsContainer,
    address user,
    uint64 achievementId
  )
    internal
  {
    AchievementConfig storage achievementConfig = achievementsContainer.achievementsConfigs[achievementId];
    require(achievementConfig.achievementsType == AchievementCommonLib.AchievementsType.Manual, "you_can_not_mint_the_type");
    require(!achievementsContainer.userAchievementsIssued[user][achievementId], "already issued");
    
    achievementConfig.factCount++;
    achievementsContainer.userAchievementsIssued[user][achievementId] = true;
    achievementsContainer.peeranhaNFT.mint(user, achievementId);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./NFTLib.sol";

/// @title AchievementCommonLib
/// @notice
/// @dev
library AchievementCommonLib {
  enum AchievementsType { Rating, Manual, SoulRating }

  function isAchievementAvailable(uint64 maxCount, uint64 factCount) internal pure returns (bool) {
    return maxCount > factCount || (maxCount == 0 && factCount < NFTLib.POOL_NFT);
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;


interface IPeeranhaToken {
  function getBoost(address user, uint16 period) external view returns (uint256);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;


interface IPeeranhaCommunity {
    function onlyExistingAndNotFrozenCommunity(uint32 communityId) external;
    function checkTags(uint32 communityId, uint8[] memory tags) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;

import "../libraries/PostLib.sol";
import "../libraries/CommonLib.sol";

interface IPeeranhaContent {
    function createPost(address user, uint32 communityId, bytes32 ipfsHash, PostLib.PostType postType, uint8[] memory tags) external;
    function createPostByBot(uint32 communityId, bytes32 ipfsHash, PostLib.PostType postType, uint8[] memory tags, CommonLib.MessengerType messengerType, string memory handle) external;
    function createReply(address user, uint256 postId, uint16 parentReplyId, bytes32 ipfsHash, bool isOfficialReply) external;
    function createReplyByBot(uint256 postId, bytes32 ipfsHash, CommonLib.MessengerType messengerType, string memory handle) external;
    function createComment(address user, uint256 postId, uint16 parentReplyId, bytes32 ipfsHash) external;
    function editPost(address user, uint256 postId, bytes32 ipfsHash, uint8[] memory tags, uint32 communityId, PostLib.PostType postType) external;
    function editReply(address user, uint256 postId, uint16 parentReplyId, bytes32 ipfsHash, bool isOfficialReply) external;
    function editComment(address user, uint256 postId, uint16 parentReplyId, uint8 commentId, bytes32 ipfsHash) external;
    function deletePost(address user, uint256 postId) external;
    function deleteReply(address user, uint256 postId, uint16 replyId) external;
    function deleteComment(address user, uint256 postId, uint16 parentReplyId, uint8 commentId) external;
    function changeStatusBestReply(address user, uint256 postId, uint16 replyId) external;
    function voteItem(address user, uint256 postId, uint16 replyId, uint8 commentId, bool isUpvote) external;
    function updateDocumentationTree(address user, uint32 communityId, bytes32 documentationTreeIpfsHash) external;
    function createTranslations(address user, uint256 postId, uint16 replyId, uint8 commentId, PostLib.Language[] memory languages, bytes32[] memory ipfsHashs) external;
    function editTranslations(address user, uint256 postId, uint16 replyId, uint8 commentId, PostLib.Language[] memory languages, bytes32[] memory ipfsHashs) external;
    function deleteTranslations(address user, uint256 postId, uint16 replyId, uint8 commentId, PostLib.Language[] memory languages) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
pragma abicoder v2;

import "../libraries/AchievementCommonLib.sol";


interface IPeeranhaNFT {
  function mint(address user, uint64 achievementId) external;
  function configureNewAchievementNFT(
    uint64 achievementId,
    uint64 maxCount,
    string memory achievementURI,
    AchievementCommonLib.AchievementsType achievementsType) external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./AchievementCommonLib.sol";


/// @title NFTLib
/// @notice
/// @dev
library NFTLib {
  uint32 constant POOL_NFT = 1000000;

  struct AchievementNFTsConfigs {
    uint64 factCount;
    uint64 maxCount;
    string achievementURI;
    AchievementCommonLib.AchievementsType achievementsType;
  }

  struct AchievementNFTsContainer {
    mapping(uint64 => AchievementNFTsConfigs) achievementsNFTConfigs;
    uint64 achievementsCount;
  }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./VoteLib.sol";
import "./UserLib.sol";
import "./CommonLib.sol";
import "./AchievementLib.sol";
import "../interfaces/IPeeranhaUser.sol";
import "../interfaces/IPeeranhaCommunity.sol";

/// @title PostLib
/// @notice Provides information about operation with posts
/// @dev posts information is stored in the mapping on the main contract
library PostLib  {
    using UserLib for UserLib.UserCollection;
    uint256 constant DELETE_TIME = 3600;    //7 days
    uint32 constant DEFAULT_COMMUNITY = 6;

    int8 constant DIRECTION_DOWNVOTE = 2;
    int8 constant DIRECTION_CANCEL_DOWNVOTE = -2;
    int8 constant DIRECTION_UPVOTE = 1;
    int8 constant DIRECTION_CANCEL_UPVOTE = -1;

    enum PostType { ExpertPost, CommonPost, Tutorial }
    enum TypeContent { Post, Reply, Comment }
    enum Language { English, Chinese, Spanish, Vietnamese }
    enum ItemProperties { MessengerSender }
    uint256 constant LANGUAGE_LENGTH = 4;       // Update after add new language

    struct Comment {
        CommonLib.IpfsHash ipfsDoc;
        address author;
        int32 rating;
        uint32 postTime;
        uint8 propertyCount;
        bool isDeleted;
    }

    struct CommentContainer {
        Comment info;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct Reply {
        CommonLib.IpfsHash ipfsDoc;
        address author;
        int32 rating;
        uint32 postTime;
        uint16 parentReplyId;
        uint8 commentCount;
        uint8 propertyCount;

        bool isFirstReply;
        bool isQuickReply;
        bool isDeleted;
    }

    struct ReplyContainer {
        Reply info;
        mapping(uint8 => CommentContainer) comments;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct DocumentationTree {
        mapping(uint32 => CommonLib.IpfsHash) ipfsDoc;
    }

    struct Post {
        PostType postType;
        address author;
        int32 rating;
        uint32 postTime;
        uint32 communityId;

        uint16 officialReply;
        uint16 bestReply;
        uint8 propertyCount;
        uint8 commentCount;
        uint16 replyCount;
        uint16 deletedReplyCount;
        bool isDeleted;

        uint8[] tags;
        CommonLib.IpfsHash ipfsDoc;
    }

    struct PostContainer {
        Post info;
        mapping(uint16 => ReplyContainer) replies;
        mapping(uint8 => CommentContainer) comments;
        mapping(uint8 => bytes32) properties;
        mapping(address => int256) historyVotes;
        address[] votedUsers;
    }

    struct PostCollection {
        mapping(uint256 => PostContainer) posts;
        uint256 postCount;
        IPeeranhaCommunity peeranhaCommunity;
        IPeeranhaUser peeranhaUser; 
    }

    struct TranslationCollection {
        mapping(bytes32 => TranslationContainer) translations;
    }

    struct Translation {
        CommonLib.IpfsHash ipfsDoc;
        address author;
        uint32 postTime;
        int32 rating;
        bool isDeleted;
    }
    
    struct TranslationContainer {
        Translation info;
        mapping(uint8 => bytes32) properties;
    }

    event PostCreated(address indexed user, uint32 indexed communityId, uint256 indexed postId); 
    event ReplyCreated(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint16 replyId);
    event CommentCreated(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event PostEdited(address indexed user, uint256 indexed postId);
    event ReplyEdited(address indexed user, uint256 indexed postId, uint16 replyId);
    event CommentEdited(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event PostDeleted(address indexed user, uint256 indexed postId);
    event ReplyDeleted(address indexed user, uint256 indexed postId, uint16 replyId);
    event CommentDeleted(address indexed user, uint256 indexed postId, uint16 parentReplyId, uint8 commentId);
    event StatusBestReplyChanged(address indexed user, uint256 indexed postId, uint16 replyId);
    event ForumItemVoted(address indexed user, uint256 indexed postId, uint16 replyId, uint8 commentId, int8 voteDirection);
    event ChangePostType(address indexed user, uint256 indexed postId, PostType newPostType);   // dont delete (for indexing)
    event TranslationCreated(address indexed user, uint256 indexed postId, uint16 replyId, uint8 commentId, Language language);
    event TranslationEdited(address indexed user, uint256 indexed postId, uint16 replyId, uint8 commentId, Language language);
    event TranslationDeleted(address indexed user, uint256 indexed postId, uint16 replyId, uint8 commentId, Language language);
    event SetDocumentationTree(address indexed userAddr, uint32 indexed communityId);
    event PostTypeChanged(address indexed user, uint256 indexed postId, PostType oldPostType);
    event PostCommunityChanged(address indexed user, uint256 indexed postId, uint32 indexed oldCommunityId);

    /// @notice Publication post 
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the post
    /// @param communityId Community where the post will be ask
    /// @param ipfsHash IPFS hash of document with post information
    /// @param postType Type of post
    /// @param tags Tags in post (min 1 tag)
    /// @param metadata metadata for bot property
    function createPost(
        PostCollection storage self,
        address userAddr,
        uint32 communityId, 
        bytes32 ipfsHash,
        PostType postType,
        uint8[] memory tags,
        bytes32 metadata
    ) public {
        self.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(communityId);
        self.peeranhaCommunity.checkTags(communityId, tags);
        
        self.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            communityId,
            UserLib.Action.PublicationPost,
            UserLib.ActionRole.NONE,
            true
        );

        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");

        PostContainer storage post = self.posts[++self.postCount];

        require(tags.length > 0, "At least one tag is required.");
        post.info.tags = tags;

        post.info.ipfsDoc.hash = ipfsHash;
        post.info.postType = postType;
        post.info.author = userAddr;
        post.info.postTime = CommonLib.getTimestamp();
        post.info.communityId = communityId;
        post.properties[uint8(ItemProperties.MessengerSender)] = metadata;

        emit PostCreated(userAddr, communityId, self.postCount);
    }

    /// @notice Publication post
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the post
    /// @param communityId Community where the post will be ask
    /// @param ipfsHash IPFS hash of document with post information
    /// @param messengerType The type of messenger from which the action was called
    /// @param handle Nickname of the user who triggered the action
    function createPostByBot(
        PostCollection storage self,
        address userAddr,
        uint32 communityId,
        bytes32 ipfsHash,
        PostType postType,
        uint8[] memory tags,
        CommonLib.MessengerType messengerType,
        string memory handle
    ) public {
        self.peeranhaUser.checkHasRole(userAddr, UserLib.ActionRole.Bot, 0);
        createPost(self, CommonLib.BOT_ADDRESS, communityId, ipfsHash, postType, tags, CommonLib.composeMessengerSenderProperty(messengerType, handle));
    }

    /// @notice Post reply
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the reply
    /// @param postId The post where the reply will be post
    /// @param parentReplyId The reply where the reply will be post
    /// @param ipfsHash IPFS hash of document with reply information
    /// @param isOfficialReply Flag is showing "official reply" or not
    /// @param metadata metadata for bot property
    function createReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        bytes32 ipfsHash,
        bool isOfficialReply,
        bytes32 metadata
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(postContainer.info.postType != PostType.Tutorial, 
            "You can not publish replies in tutorial.");

        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.PublicationReply,
            parentReplyId == 0 && isOfficialReply ? 
                UserLib.ActionRole.CommunityAdmin :
                UserLib.ActionRole.NONE,
            true
        );

        /*  
            Check gas one more 
            isOfficialReply ? UserLib.Action.publicationOfficialReply : UserLib.Action.PublicationReply
            remove: require((UserLib.hasRole(userContex ...
            20k in gas contract, +20 gas in common reply (-20 in official reply), but Avg gas -20 ?
         */
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");
        require(
            parentReplyId == 0, 
            "User is forbidden to reply on reply for Expert and Common type of posts"
        ); // unit tests (reply on reply)

        ReplyContainer storage replyContainer;
        if (postContainer.info.postType == PostType.ExpertPost || postContainer.info.postType == PostType.CommonPost) {
            uint16 countReplies = uint16(postContainer.info.replyCount);

            for (uint16 i = 1; i <= countReplies; i++) {
                replyContainer = getReplyContainer(postContainer, i);
                require(
                    (userAddr != replyContainer.info.author && userAddr != CommonLib.BOT_ADDRESS) || 
                    replyContainer.properties[uint8(ItemProperties.MessengerSender)] != metadata || 
                    replyContainer.info.isDeleted,
                    "Users can not publish 2 replies for expert and common posts.");
            }
        }

        replyContainer = postContainer.replies[++postContainer.info.replyCount];
        uint32 timestamp = CommonLib.getTimestamp();
        if (parentReplyId == 0) {
            if (isOfficialReply) {
                postContainer.info.officialReply = postContainer.info.replyCount;
            }

            if (postContainer.info.postType != PostType.Tutorial && postContainer.info.author != userAddr) {
                if (getActiveReplyCount(postContainer) == 1) {
                    replyContainer.info.isFirstReply = true;
                    self.peeranhaUser.updateUserRating(userAddr, VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.FirstReply), postContainer.info.communityId);
                }
                if (timestamp - postContainer.info.postTime < CommonLib.QUICK_REPLY_TIME_SECONDS) {
                    replyContainer.info.isQuickReply = true;
                    self.peeranhaUser.updateUserRating(userAddr, VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.QuickReply), postContainer.info.communityId);
                }
            }
        } else {
          getReplyContainerSafe(postContainer, parentReplyId);
          replyContainer.info.parentReplyId = parentReplyId;  
        }

        replyContainer.info.author = userAddr;
        replyContainer.info.ipfsDoc.hash = ipfsHash;
        replyContainer.info.postTime = timestamp;
        replyContainer.properties[uint8(ItemProperties.MessengerSender)] = metadata;

        emit ReplyCreated(userAddr, postId, parentReplyId, postContainer.info.replyCount);
    }

    /// @notice Post reply
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the reply
    /// @param postId The post where the reply will be post
    /// @param ipfsHash IPFS hash of document with reply information
    /// @param messengerType The type of messenger from which the action was called
    /// @param handle Nickname of the user who triggered the action
    function createReplyByBot(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        bytes32 ipfsHash,
        CommonLib.MessengerType messengerType,
        string memory handle
    ) public {
        self.peeranhaUser.checkHasRole(userAddr, UserLib.ActionRole.Bot, 0);
        createReply(self, CommonLib.BOT_ADDRESS, postId, 0, ipfsHash, false, CommonLib.composeMessengerSenderProperty(messengerType, handle));
    }

    /// @notice Post comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param parentReplyId The reply where the comment will be post
    /// @param ipfsHash IPFS hash of document with comment information
    function createComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        bytes32 ipfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");

        Comment storage comment;
        uint8 commentId;            // struct? gas
        address author;

        if (parentReplyId == 0) {
            commentId = ++postContainer.info.commentCount;
            comment = postContainer.comments[commentId].info;
            author = postContainer.info.author;
        } else {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, parentReplyId);
            commentId = ++replyContainer.info.commentCount;
            comment = replyContainer.comments[commentId].info;
            if (postContainer.info.author == userAddr)
                author = userAddr;
            else
                author = replyContainer.info.author;
        }

        self.peeranhaUser.checkActionRole(
            userAddr,
            author,
            postContainer.info.communityId,
            UserLib.Action.PublicationComment,
            UserLib.ActionRole.NONE,
            true
        );

        comment.author = userAddr;
        comment.ipfsDoc.hash = ipfsHash;
        comment.postTime = CommonLib.getTimestamp();

        emit CommentCreated(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Edit post
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param ipfsHash IPFS hash of document with post information
    /// @param tags New tags in post (empty array if tags dont change)
    /// @param communityId New community Id (current community id if dont change)
    /// @param postType New post type (current community Id if dont change)
    function editPost(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        bytes32 ipfsHash,
        uint8[] memory tags,
        uint32 communityId, 
        PostType postType
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        if(userAddr == postContainer.info.author) {
            self.peeranhaUser.checkActionRole(
                userAddr,
                postContainer.info.author,
                postContainer.info.communityId,
                UserLib.Action.EditItem,
                UserLib.ActionRole.NONE,
                false
            );
            require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");
            if(postContainer.info.ipfsDoc.hash != ipfsHash)
                postContainer.info.ipfsDoc.hash = ipfsHash;

        } else {
            require(postContainer.info.ipfsDoc.hash == ipfsHash, "Not_allowed_edit_not_author");
            if (communityId != postContainer.info.communityId && communityId != DEFAULT_COMMUNITY && !self.peeranhaUser.isProtocolAdmin(userAddr)) {
                revert("Error_change_communityId");
            }
            self.peeranhaUser.checkActionRole(
                userAddr,
                postContainer.info.author,
                postContainer.info.communityId,
                UserLib.Action.NONE,
                UserLib.ActionRole.AdminOrCommunityModerator,
                false
            );
        }


        if (postContainer.info.communityId != communityId) {
            emit PostCommunityChanged(userAddr, postId, postContainer.info.communityId);
            changePostCommunity(self, postContainer, communityId);
        }
        if (postContainer.info.postType != postType) {
            emit PostTypeChanged(userAddr, postId, postContainer.info.postType);
            changePostType(self, postContainer, postType);
        }
        if (tags.length > 0) {
            self.peeranhaCommunity.checkTags(postContainer.info.communityId, tags);
            postContainer.info.tags = tags;
        }

        emit PostEdited(userAddr, postId);
    }

    /// @notice Edit reply
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param replyId The reply which will be change
    /// @param ipfsHash IPFS hash of document with reply information
    function editReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        bytes32 ipfsHash,
        bool isOfficialReply
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            replyContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.EditItem,
            isOfficialReply ? UserLib.ActionRole.CommunityAdmin : 
                UserLib.ActionRole.NONE,
            false
        );
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");
        require(userAddr == replyContainer.info.author, "You can not edit this Reply. It is not your.");

        if (replyContainer.info.ipfsDoc.hash != ipfsHash)
            replyContainer.info.ipfsDoc.hash = ipfsHash;

        if (isOfficialReply) {
            postContainer.info.officialReply = replyId;
        } else if (postContainer.info.officialReply == replyId) {
            postContainer.info.officialReply = 0;
        }

        emit ReplyEdited(userAddr, postId, replyId);
    }

    /// @notice Edit comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the comment
    /// @param postId The post where the comment will be post
    /// @param parentReplyId The reply where the reply will be edit
    /// @param commentId The comment which will be change
    /// @param ipfsHash IPFS hash of document with comment information
    function editComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId,
        bytes32 ipfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        CommentContainer storage commentContainer = getCommentContainerSafe(postContainer, parentReplyId, commentId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            commentContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.EditItem,
            UserLib.ActionRole.NONE,
            false
        );
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");
        require(userAddr == commentContainer.info.author, "You can not edit this comment. It is not your.");

        if (commentContainer.info.ipfsDoc.hash != ipfsHash)
            commentContainer.info.ipfsDoc.hash = ipfsHash;
        
        emit CommentEdited(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Delete post
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes post
    /// @param postId Post which will be deleted
    function deletePost(
        PostCollection storage self,
        address userAddr,
        uint256 postId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );

        uint256 time = CommonLib.getTimestamp();
        if (time - postContainer.info.postTime < DELETE_TIME || userAddr == postContainer.info.author) {
            VoteLib.StructRating memory typeRating = getTypesRating(postContainer.info.postType);
            (int32 positive, int32 negative) = getHistoryInformations(postContainer.historyVotes, postContainer.votedUsers);

            int32 changeUserRating = typeRating.upvotedPost * positive + typeRating.downvotedPost * negative;
            if (changeUserRating > 0) {
                self.peeranhaUser.updateUserRating(
                    postContainer.info.author,
                    -changeUserRating,
                    postContainer.info.communityId
                );
            }
        }
        if (postContainer.info.bestReply != 0) {
            self.peeranhaUser.updateUserRating(postContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postContainer.info.postType, VoteLib.ResourceAction.AcceptedReply), postContainer.info.communityId);
        }

        if (time - postContainer.info.postTime < DELETE_TIME) {
            for (uint16 i = 1; i <= postContainer.info.replyCount; i++) {
                deductReplyRating(self, postContainer.info.postType, postContainer.replies[i], postContainer.info.bestReply == i, postContainer.info.communityId);
            }
        }

        if (userAddr == postContainer.info.author)
            self.peeranhaUser.updateUserRating(postContainer.info.author, VoteLib.DeleteOwnPost, postContainer.info.communityId);
        else
            self.peeranhaUser.updateUserRating(postContainer.info.author, VoteLib.ModeratorDeletePost, postContainer.info.communityId);

        postContainer.info.isDeleted = true;
        emit PostDeleted(userAddr, postId);
    }

    /// @notice Delete reply
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes reply
    /// @param postId The post where will be deleted reply
    /// @param replyId Reply which will be deleted
    function deleteReply(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            replyContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );

        uint256 time = CommonLib.getTimestamp();
        if (time - replyContainer.info.postTime < DELETE_TIME || userAddr == replyContainer.info.author) {
            deductReplyRating(
                self,
                postContainer.info.postType,
                replyContainer,
                replyContainer.info.parentReplyId == 0 && postContainer.info.bestReply == replyId,
                postContainer.info.communityId
            );
        }
        if (userAddr == replyContainer.info.author)
            self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.DeleteOwnReply, postContainer.info.communityId);
        else
            self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.ModeratorDeleteReply, postContainer.info.communityId);

        replyContainer.info.isDeleted = true;
        postContainer.info.deletedReplyCount++;
        if (postContainer.info.bestReply == replyId)
            postContainer.info.bestReply = 0;

        if (postContainer.info.officialReply == replyId)
            postContainer.info.officialReply = 0;

        emit ReplyDeleted(userAddr, postId, replyId);
    }

    /// @notice Take reply rating from the author
    /// @param postType Type post: expert, common, tutorial
    /// @param replyContainer Reply from which the rating is taken
    function deductReplyRating (
        PostCollection storage self,
        PostType postType,
        ReplyContainer storage replyContainer,
        bool isBestReply,
        uint32 communityId
    ) private {
        if (CommonLib.isEmptyIpfs(replyContainer.info.ipfsDoc.hash) || replyContainer.info.isDeleted)
            return;

        int32 changeReplyAuthorRating;
        if (replyContainer.info.rating >= 0) {
            if (replyContainer.info.isFirstReply) {
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply);
            }
            if (replyContainer.info.isQuickReply) {
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply);
            }
            if (isBestReply && postType != PostType.Tutorial) { // todo: need? postType != PostType.Tutorial
                changeReplyAuthorRating += -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply);
            }
        }

        // change user rating considering reply rating
        VoteLib.StructRating memory typeRating = getTypesRating(postType);
        (int32 positive, int32 negative) = getHistoryInformations(replyContainer.historyVotes, replyContainer.votedUsers);
        int32 changeUserRating = typeRating.upvotedReply * positive + typeRating.downvotedReply * negative;
        if (changeUserRating > 0) {
            changeReplyAuthorRating += -changeUserRating;
        }

        if (changeReplyAuthorRating != 0) {
            self.peeranhaUser.updateUserRating(
                replyContainer.info.author, 
                changeReplyAuthorRating,
                communityId
            );
        }
    }

    /// @notice Delete comment
    /// @param self The mapping containing all posts
    /// @param userAddr User who deletes comment
    /// @param postId The post where will be deleted comment
    /// @param parentReplyId The reply where the reply will be deleted
    /// @param commentId Comment which will be deleted
    function deleteComment(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        CommentContainer storage commentContainer = getCommentContainerSafe(postContainer, parentReplyId, commentId);
        self.peeranhaUser.checkActionRole(
            userAddr,
            commentContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.DeleteItem,
            UserLib.ActionRole.NONE,
            false
        );

        if (userAddr != commentContainer.info.author)
            self.peeranhaUser.updateUserRating(commentContainer.info.author, VoteLib.ModeratorDeleteComment, postContainer.info.communityId);

        commentContainer.info.isDeleted = true;
        emit CommentDeleted(userAddr, postId, parentReplyId, commentId);
    }

    /// @notice Change status best reply
    /// @param self The mapping containing all posts
    /// @param userAddr Who called action
    /// @param postId The post where will be change reply status
    /// @param replyId Reply which will change status
    function changeStatusBestReply (
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId
    ) public {
        PostContainer storage postContainer = getPostContainer(self, postId);
        require(postContainer.info.author == userAddr, "Only owner by post can change statust best reply.");
        ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);

        if (postContainer.info.bestReply == replyId) {
            updateRatingForBestReply(self, postContainer.info.postType, userAddr, replyContainer.info.author, false, postContainer.info.communityId);
            postContainer.info.bestReply = 0;
        } else {
            if (postContainer.info.bestReply != 0) {
                ReplyContainer storage oldBestReplyContainer = getReplyContainerSafe(postContainer, postContainer.info.bestReply);

                updateRatingForBestReply(self, postContainer.info.postType, userAddr, oldBestReplyContainer.info.author, false, postContainer.info.communityId);
            }

            updateRatingForBestReply(self, postContainer.info.postType, userAddr, replyContainer.info.author, true, postContainer.info.communityId);
            postContainer.info.bestReply = replyId;
        }
        self.peeranhaUser.checkActionRole(
            userAddr,
            postContainer.info.author,
            postContainer.info.communityId,
            UserLib.Action.BestReply,
            UserLib.ActionRole.NONE,
            false
        );  // unit test (forum)

        emit StatusBestReplyChanged(userAddr, postId, postContainer.info.bestReply);
    }

    function updateRatingForBestReply (
        PostCollection storage self,
        PostType postType,
        address authorPost,
        address authorReply,
        bool isMark,
        uint32 communityId
    ) private {
        if (authorPost != authorReply) {
            self.peeranhaUser.updateUserRating(
                authorPost, 
                isMark ?
                    VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptedReply) :
                    -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptedReply),
                communityId
            );

            self.peeranhaUser.updateUserRating(
                authorReply,
                isMark ?
                    VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply) :
                    -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.AcceptReply),
                communityId
            );
        }
    }

    /// @notice Vote for post, reply or comment
    /// @param self The mapping containing all posts
    /// @param userAddr Who called action
    /// @param postId Post where will be change rating
    /// @param replyId Reply which will be change rating
    /// @param commentId Comment which will be change rating
    /// @param isUpvote Upvote or downvote
    function voteForumItem(
        PostCollection storage self,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        bool isUpvote
    ) internal {
        PostContainer storage postContainer = getPostContainer(self, postId);
        PostType postType = postContainer.info.postType;

        int8 voteDirection;
        if (commentId != 0) {
            CommentContainer storage commentContainer = getCommentContainerSafe(postContainer, replyId, commentId);
            require(userAddr != commentContainer.info.author, "error_vote_comment");
            voteDirection = voteComment(self, commentContainer, postContainer.info.communityId, userAddr, isUpvote);

        } else if (replyId != 0) {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
            require(userAddr != replyContainer.info.author, "error_vote_reply");
            voteDirection = voteReply(self, replyContainer, postContainer.info.communityId, userAddr, postType, isUpvote);


        } else {
            require(userAddr != postContainer.info.author, "error_vote_post");
            voteDirection = votePost(self, postContainer, userAddr, postType, isUpvote);
        }

        emit ForumItemVoted(userAddr, postId, replyId, commentId, voteDirection);
    }

    // @notice Vote for post
    /// @param self The mapping containing all posts
    /// @param postContainer Post where will be change rating
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    function votePost(
        PostCollection storage self,
        PostContainer storage postContainer,
        address votedUser,
        PostType postType,
        bool isUpvote
    ) private returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, postContainer.historyVotes, isUpvote, postContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            postContainer.info.author,
            postContainer.info.communityId,
            isCancel ?
                UserLib.Action.CancelVote :
                (ratingChange > 0 ?
                    UserLib.Action.UpVotePost :
                    UserLib.Action.DownVotePost
                ),
            UserLib.ActionRole.NONE,
            false
        ); 

        vote(self, postContainer.info.author, votedUser, postType, isUpvote, ratingChange, TypeContent.Post, postContainer.info.communityId);
        postContainer.info.rating += ratingChange;
        
        return isCancel ?
            (ratingChange > 0 ?
                DIRECTION_CANCEL_DOWNVOTE :
                DIRECTION_CANCEL_UPVOTE 
            ) :
            (ratingChange > 0 ?
                DIRECTION_UPVOTE :
                DIRECTION_DOWNVOTE
            );
    }
 
    // @notice Vote for reply
    /// @param self The mapping containing all posts
    /// @param replyContainer Reply where will be change rating
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    function voteReply(
        PostCollection storage self,
        ReplyContainer storage replyContainer,
        uint32 communityId,
        address votedUser,
        PostType postType,
        bool isUpvote
    ) private returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, replyContainer.historyVotes, isUpvote, replyContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            replyContainer.info.author,
            communityId,
            isCancel ?
                UserLib.Action.CancelVote :
                (ratingChange > 0 ?
                    UserLib.Action.UpVoteReply :
                    UserLib.Action.DownVoteReply
                ),
            UserLib.ActionRole.NONE,
            false
        ); 

        vote(self, replyContainer.info.author, votedUser, postType, isUpvote, ratingChange, TypeContent.Reply, communityId);
        int32 oldRating = replyContainer.info.rating;
        replyContainer.info.rating += ratingChange;
        int32 newRating = replyContainer.info.rating; // or oldRating + ratingChange gas

        if (replyContainer.info.isFirstReply) {
            if (oldRating < 0 && newRating >= 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply), communityId);
            } else if (oldRating >= 0 && newRating < 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.FirstReply), communityId);
            }
        }

        if (replyContainer.info.isQuickReply) {
            if (oldRating < 0 && newRating >= 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply), communityId);
            } else if (oldRating >= 0 && newRating < 0) {
                self.peeranhaUser.updateUserRating(replyContainer.info.author, -VoteLib.getUserRatingChangeForReplyAction(postType, VoteLib.ResourceAction.QuickReply), communityId);
            }
        }

        return isCancel ?
            (ratingChange > 0 ?
                DIRECTION_CANCEL_DOWNVOTE :
                DIRECTION_CANCEL_UPVOTE 
            ) :
            (ratingChange > 0 ?
                DIRECTION_UPVOTE :
                DIRECTION_DOWNVOTE
            );
    }

    // @notice Vote for comment
    /// @param self The mapping containing all posts
    /// @param commentContainer Comment where will be change rating
    /// @param votedUser User who voted
    /// @param isUpvote Upvote or downvote
    function voteComment(
        PostCollection storage self,
        CommentContainer storage commentContainer,
        uint32 communityId,
        address votedUser,
        bool isUpvote
    ) private returns (int8) {
        (int32 ratingChange, bool isCancel) = VoteLib.getForumItemRatingChange(votedUser, commentContainer.historyVotes, isUpvote, commentContainer.votedUsers);
        self.peeranhaUser.checkActionRole(
            votedUser,
            commentContainer.info.author,
            communityId,
            isCancel ? 
                UserLib.Action.CancelVote :
                UserLib.Action.VoteComment,
            UserLib.ActionRole.NONE,
            false
        );

        commentContainer.info.rating += ratingChange;

        return isCancel ?
            (ratingChange > 0 ?
                DIRECTION_CANCEL_DOWNVOTE :
                DIRECTION_CANCEL_UPVOTE 
            ) :
            (ratingChange > 0 ?
                DIRECTION_UPVOTE :
                DIRECTION_DOWNVOTE
            );
    }

    // @notice Сount users' rating after voting per a reply or post
    /// @param self The mapping containing all posts
    /// @param author Author post, reply or comment where voted
    /// @param votedUser User who voted
    /// @param postType Type post expert, common, tutorial
    /// @param isUpvote Upvote or downvote
    /// @param ratingChanged The value shows how the rating of a post or reply has changed.
    /// @param typeContent Type content post, reply or comment
    function vote(
        PostCollection storage self,
        address author,
        address votedUser,
        PostType postType,
        bool isUpvote,
        int32 ratingChanged,
        TypeContent typeContent,
        uint32 communityId
    ) private {
       UserLib.UserRatingChange[] memory usersRating = new UserLib.UserRatingChange[](2);

        if (isUpvote) {
            usersRating[0].user = author;
            usersRating[0].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Upvoted, typeContent);

            if (ratingChanged == 2) {
                usersRating[0].rating += VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvoted, typeContent) * -1;

                usersRating[1].user = votedUser;
                usersRating[1].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvote, typeContent) * -1; 
            }

            if (ratingChanged < 0) {
                usersRating[0].rating *= -1;
                usersRating[1].rating *= -1;
            } 
        } else {
            usersRating[0].user = author;
            usersRating[0].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvoted, typeContent);

            usersRating[1].user = votedUser;
            usersRating[1].rating = VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Downvote, typeContent);

            if (ratingChanged == -2) {
                usersRating[0].rating += VoteLib.getUserRatingChange(postType, VoteLib.ResourceAction.Upvoted, typeContent) * -1;
            }

            if (ratingChanged > 0) {
                usersRating[0].rating *= -1;
                usersRating[1].rating *= -1;  
            }
        }
        self.peeranhaUser.updateUsersRating(usersRating, communityId);
    }

    // @notice Change postType for post and recalculation rating for all users who were active in the post
    /// @param self The mapping containing all posts
    /// @param postContainer Post where changing post type
    /// @param newPostType New post type
    function changePostType(
        PostCollection storage self,
        PostContainer storage postContainer,
        PostType newPostType
    ) private {
        PostType oldPostType = postContainer.info.postType;
        require(newPostType != PostType.Tutorial || getActiveReplyCount(postContainer) == 0, "Error_postType");
        
        VoteLib.StructRating memory oldTypeRating = getTypesRating(oldPostType);
        VoteLib.StructRating memory newTypeRating = getTypesRating(newPostType);

        (int32 positive, int32 negative) = getHistoryInformations(postContainer.historyVotes, postContainer.votedUsers);
        int32 changePostAuthorRating = (newTypeRating.upvotedPost - oldTypeRating.upvotedPost) * positive +
                                (newTypeRating.downvotedPost - oldTypeRating.downvotedPost) * negative;

        uint16 bestReplyId = postContainer.info.bestReply;
        for (uint16 replyId = 1; replyId <= postContainer.info.replyCount; replyId++) {
            ReplyContainer storage replyContainer = getReplyContainer(postContainer, replyId);
            if (replyContainer.info.isDeleted) continue;
            (positive, negative) = getHistoryInformations(replyContainer.historyVotes, replyContainer.votedUsers);

            int32 changeReplyAuthorRating = (newTypeRating.upvotedReply - oldTypeRating.upvotedReply) * positive +
                (newTypeRating.downvotedReply - oldTypeRating.downvotedReply) * negative;

            if (replyContainer.info.rating >= 0) {
                if (replyContainer.info.isFirstReply) {
                    changeReplyAuthorRating += newTypeRating.firstReply - oldTypeRating.firstReply;
                }
                if (replyContainer.info.isQuickReply) {
                    changeReplyAuthorRating += newTypeRating.quickReply - oldTypeRating.quickReply;
                }
            }
            if (bestReplyId == replyId) {
                changeReplyAuthorRating += newTypeRating.acceptReply - oldTypeRating.acceptReply;
                changePostAuthorRating += newTypeRating.acceptedReply - oldTypeRating.acceptedReply;
            }
            self.peeranhaUser.updateUserRating(replyContainer.info.author, changeReplyAuthorRating, postContainer.info.communityId);
        }
        self.peeranhaUser.updateUserRating(postContainer.info.author, changePostAuthorRating, postContainer.info.communityId);
        postContainer.info.postType = newPostType;
    }

    // @notice Change communityId for post and recalculation rating for all users who were active in the post
    /// @param self The mapping containing all posts
    /// @param postContainer Post where changing post type
    /// @param newCommunityId New community id for post
    function changePostCommunity(
        PostCollection storage self,
        PostContainer storage postContainer,
        uint32 newCommunityId
    ) private {
        self.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(newCommunityId);
        uint32 oldCommunityId = postContainer.info.communityId;
        PostType postType = postContainer.info.postType;
        VoteLib.StructRating memory typeRating = getTypesRating(postType);

        (int32 positive, int32 negative) = getHistoryInformations(postContainer.historyVotes, postContainer.votedUsers);
        int32 changePostAuthorRating = typeRating.upvotedPost * positive + typeRating.downvotedPost * negative;

        uint16 bestReplyId = postContainer.info.bestReply;
        for (uint16 replyId = 1; replyId <= postContainer.info.replyCount; replyId++) {
            ReplyContainer storage replyContainer = getReplyContainer(postContainer, replyId);
            if (replyContainer.info.isDeleted) continue;
            (positive, negative) = getHistoryInformations(replyContainer.historyVotes, replyContainer.votedUsers);

            int32 changeReplyAuthorRating = typeRating.upvotedReply * positive + typeRating.downvotedReply * negative;
            if (replyContainer.info.rating >= 0) {
                if (replyContainer.info.isFirstReply) {
                    changeReplyAuthorRating += typeRating.firstReply;
                }
                if (replyContainer.info.isQuickReply) {
                    changeReplyAuthorRating += typeRating.quickReply;
                }
            }
            if (bestReplyId == replyId) {
                changeReplyAuthorRating += typeRating.acceptReply;
                changePostAuthorRating += typeRating.acceptedReply;
            }

            self.peeranhaUser.updateUserRating(replyContainer.info.author, -changeReplyAuthorRating, oldCommunityId);
            self.peeranhaUser.updateUserRating(replyContainer.info.author, changeReplyAuthorRating, newCommunityId);
        }

        self.peeranhaUser.updateUserRating(postContainer.info.author, -changePostAuthorRating, oldCommunityId);
        self.peeranhaUser.updateUserRating(postContainer.info.author, changePostAuthorRating, newCommunityId);
        postContainer.info.communityId = newCommunityId;
    }

    // @notice update documentation ipfs tree
    /// @param self The mapping containing all documentationTrees
    /// @param postCollection The mapping containing all posts
    /// @param userAddr Author documentation
    /// @param communityId Community where the documentation will be update
    /// @param documentationTreeIpfsHash IPFS hash of document with documentation in tree
    function updateDocumentationTree(
        DocumentationTree storage self,
        PostCollection storage postCollection,
        address userAddr,
        uint32 communityId, 
        bytes32 documentationTreeIpfsHash
    ) public {
        postCollection.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(communityId);
        postCollection.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            communityId,
            UserLib.Action.NONE,
            UserLib.ActionRole.CommunityAdmin,
            false
        );

        self.ipfsDoc[communityId].hash = documentationTreeIpfsHash;
        emit SetDocumentationTree(userAddr, communityId);
    }

    /// @notice Save translation for post, reply or comment
    /// @param self The mapping containing all translations
    /// @param postId Post where will be init translation
    /// @param replyId Reply which will be init translation
    /// @param commentId Comment which will be init translation
    /// @param language The translation language
    /// @param userAddr Who called action
    /// @param ipfsHash IPFS hash of document with translation information
    function initTranslation(
        TranslationCollection storage self,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language language,
        address userAddr,
        bytes32 ipfsHash
    ) private {
        require(!CommonLib.isEmptyIpfs(ipfsHash), "Invalid_ipfsHash");      // todo test
        bytes32 item = getTranslationItemHash(postId, replyId, commentId, language);

        TranslationContainer storage translationContainer = self.translations[item];
        translationContainer.info.ipfsDoc.hash = ipfsHash;
        translationContainer.info.author = userAddr;
        translationContainer.info.postTime = CommonLib.getTimestamp();

        emit TranslationCreated(userAddr, postId, replyId, commentId, language);
    }

    /// @notice Validate translation params (is exist post/reply/comment and chech permission)
    /// @param postCollection The mapping containing all posts
    /// @param postId Post which is checked for existence
    /// @param replyId Reply which is checked for existence
    /// @param commentId Comment which is checked for existence
    /// @param userAddr Who called action. User must have community admin/community moderator or admin role
    function validateTranslationParams(
        PostCollection storage postCollection,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        address userAddr
    ) private {
        PostContainer storage postContainer = getPostContainer(postCollection, postId);
        postCollection.peeranhaCommunity.onlyExistingAndNotFrozenCommunity(postContainer.info.communityId);
        if (replyId != 0)
            getReplyContainerSafe(postContainer, replyId);
        if (commentId != 0)
            getCommentContainerSafe(postContainer, replyId, commentId);

        postCollection.peeranhaUser.checkActionRole(
            userAddr,
            userAddr,
            postContainer.info.communityId,
            UserLib.Action.NONE,
            UserLib.ActionRole.CommunityAdmin,      // todo: add test
            false
        );
    }

    /// @notice Create several translations
    /// @param self The mapping containing all translation
    /// @param postCollection The mapping containing all posts
    /// @param userAddr Author of the translation
    /// @param postId The post where the translation will be post
    /// @param replyId The reply where the translation will be post
    /// @param commentId The reply where the translation will be post
    /// @param languages The array of translations
    /// @param ipfsHashs The array IPFS hashs of document with translation information
    function createTranslations(
        TranslationCollection storage self,
        PostLib.PostCollection storage postCollection,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language[] memory languages,
        bytes32[] memory ipfsHashs
    ) internal {
        validateTranslationParams(postCollection, postId, replyId, commentId, userAddr);

        require(languages.length == ipfsHashs.length, "Error_array");
        for (uint32 i; i < languages.length; i++) {
            initTranslation( self, postId, replyId, commentId, languages[i], userAddr, ipfsHashs[i]);
        }
    }

    /// @notice Edit several translations
    /// @param self The mapping containing all translation
    /// @param postCollection The mapping containing all posts
    /// @param userAddr Author of the translation
    /// @param postId The post where the translation will be edit
    /// @param replyId The reply where the translation will be edit
    /// @param commentId The reply where the translation will be edit
    /// @param languages The array of translations
    /// @param ipfsHashs The array IPFS hashs of document with translation information
    function editTranslations(
        TranslationCollection storage self,
        PostLib.PostCollection storage postCollection,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language[] memory languages,
        bytes32[] memory ipfsHashs
    ) internal {
        validateTranslationParams(postCollection, postId, replyId, commentId, userAddr);

        require(languages.length == ipfsHashs.length, "Error_array");
        for (uint32 i; i < languages.length; i++) {
            require(!CommonLib.isEmptyIpfs(ipfsHashs[i]), "Invalid_ipfsHash");
            TranslationContainer storage translationContainer = getTranslationSafe(self, postId, replyId, commentId, languages[i]);
            translationContainer.info.ipfsDoc.hash = ipfsHashs[i];

            emit TranslationEdited(userAddr, postId, replyId, commentId, languages[i]);
        } 
    }

    /// @notice Delete several translations
    /// @param self The mapping containing all translation
    /// @param postCollection The mapping containing all posts
    /// @param userAddr Author of the translation
    /// @param postId The post where the translation will be delete
    /// @param replyId The reply where the translation will be delete
    /// @param commentId The reply where the translation will be delete
    /// @param languages The array of translations
    function deleteTranslations(
        TranslationCollection storage self,
        PostLib.PostCollection storage postCollection,
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language[] memory languages
    ) internal {
        validateTranslationParams(postCollection, postId, replyId, commentId, userAddr);

        for (uint32 i; i < languages.length; i++) {
            TranslationContainer storage translationContainer = getTranslationSafe(self, postId, replyId, commentId, languages[i]);
            translationContainer.info.isDeleted = true;

            emit TranslationDeleted(userAddr, postId, replyId, commentId, languages[i]);
        } 
    }

    /// @notice Return translation hash
    /// @param postId The post Id
    /// @param replyId The reply Id
    /// @param commentId The reply Id
    /// @param language The lenguage
    function getTranslationItemHash(
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language language
    ) private pure returns (bytes32) {
        return bytes32(postId << 192 | uint256(replyId) << 128 | uint256(commentId) << 64 | uint256(language));
    }  

    function updateDocumentationTreeByPost(
        DocumentationTree storage self,
        PostCollection storage postCollection,
        address userAddr,
        uint256 postId,
        bytes32 documentationTreeIpfsHash
    ) public {
        PostContainer storage postContainer = getPostContainer(postCollection, postId);
        updateDocumentationTree(self, postCollection, userAddr, postContainer.info.communityId, documentationTreeIpfsHash);
    }

    function getTypesRating(        //name?
        PostType postType
    ) private pure returns (VoteLib.StructRating memory) {
        if (postType == PostType.ExpertPost)
            return VoteLib.getExpertRating();
        else if (postType == PostType.CommonPost)
            return VoteLib.getCommonRating();
        else if (postType == PostType.Tutorial)
            return VoteLib.getTutorialRating();
        
        revert("Invalid_post_type");
    }

    /// @notice Return post
    /// @param self The mapping containing all posts
    /// @param postId The postId which need find
    function getPostContainer(
        PostCollection storage self,
        uint256 postId
    ) public view returns (PostContainer storage) {
        PostContainer storage post = self.posts[postId];
        require(!CommonLib.isEmptyIpfs(post.info.ipfsDoc.hash), "Post_not_exist.");
        require(!post.info.isDeleted, "Post_deleted.");
        
        return post;
    }

    /// @notice Return reply, the reply is not checked on delete one
    /// @param postContainer The post where is the reply
    /// @param replyId The replyId which need find
    function getReplyContainer(
        PostContainer storage postContainer,
        uint16 replyId
    ) public view returns (ReplyContainer storage) {
        ReplyContainer storage replyContainer = postContainer.replies[replyId];

        require(!CommonLib.isEmptyIpfs(replyContainer.info.ipfsDoc.hash), "Reply_not_exist.");
        return replyContainer;
    }

    /// @notice Return reply, the reply is checked on delete one
    /// @param postContainer The post where is the reply
    /// @param replyId The replyId which need find
    function getReplyContainerSafe(
        PostContainer storage postContainer,
        uint16 replyId
    ) public view returns (ReplyContainer storage) {
        ReplyContainer storage replyContainer = getReplyContainer(postContainer, replyId);
        require(!replyContainer.info.isDeleted, "Reply_deleted.");

        return replyContainer;
    }

    /// @notice Return comment, the comment is not checked on delete one
    /// @param postContainer The post where is the comment
    /// @param parentReplyId The parent reply
    /// @param commentId The commentId which need find
    function getCommentContainer(
        PostContainer storage postContainer,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (CommentContainer storage) {
        CommentContainer storage commentContainer;

        if (parentReplyId == 0) {
            commentContainer = postContainer.comments[commentId];  
        } else {
            ReplyContainer storage reply = getReplyContainerSafe(postContainer, parentReplyId);
            commentContainer = reply.comments[commentId];
        }
        require(!CommonLib.isEmptyIpfs(commentContainer.info.ipfsDoc.hash), "Comment_not_exist.");

        return commentContainer;
    }

    /// @notice Return comment, the comment is checked on delete one
    /// @param postContainer The post where is the comment
    /// @param parentReplyId The parent reply
    /// @param commentId The commentId which need find
    function getCommentContainerSafe(
        PostContainer storage postContainer,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (CommentContainer storage) {
        CommentContainer storage commentContainer = getCommentContainer(postContainer, parentReplyId, commentId);

        require(!commentContainer.info.isDeleted, "Comment_deleted.");
        return commentContainer;
    }

    /// @notice Return post for unit tests
    /// @param self The mapping containing all posts
    /// @param postId The post which need find
    function getPost(
        PostCollection storage self,
        uint256 postId
    ) public view returns (Post memory) {        
        return self.posts[postId].info;
    }

    /// @notice Return reply for unit tests
    /// @param self The mapping containing all posts
    /// @param postId The post where is the reply
    /// @param replyId The reply which need find
    function getReply(
        PostCollection storage self, 
        uint256 postId, 
        uint16 replyId
    ) public view returns (Reply memory) {
        PostContainer storage postContainer = self.posts[postId];
        return getReplyContainer(postContainer, replyId).info;
    }

    /// @notice Return property for item
    /// @param self The mapping containing all posts
    /// @param postId Post where is the reply
    /// @param replyId The parent reply
    /// @param commentId The comment which need find
    function getItemProperty(
        PostCollection storage self,
        uint8 propertyId,
        uint256 postId, 
        uint16 replyId,
        uint8 commentId
    ) public view returns (bytes32) {
        PostContainer storage postContainer = getPostContainer(self, postId);

        if (commentId != 0) {
            CommentContainer storage commentContainer = getCommentContainerSafe(postContainer, replyId, commentId);
            return commentContainer.properties[propertyId];

        } else if (replyId != 0) {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
            return replyContainer.properties[propertyId];

        }
        return postContainer.properties[propertyId];
    }

    /// @notice Return comment for unit tests
    /// @param self The mapping containing all posts
    /// @param postId Post where is the reply
    /// @param parentReplyId The parent reply
    /// @param commentId The comment which need find
    function getComment(
        PostCollection storage self, 
        uint256 postId,
        uint16 parentReplyId,
        uint8 commentId
    ) public view returns (Comment memory) {
        PostContainer storage postContainer = self.posts[postId];          // todo: return storage -> memory?
        return getCommentContainer(postContainer, parentReplyId, commentId).info;
    }

    /// @notice Return replies count
    /// @param postContainer post where get replies count
    function getActiveReplyCount(
        PostContainer storage postContainer
    ) private view returns (uint16) {
        return postContainer.info.replyCount - postContainer.info.deletedReplyCount;
    }

    /// @notice Get flag status vote (upvote/dovnvote) for post/reply/comment
    /// @param self The mapping containing all posts
    /// @param userAddr Author of the vote
    /// @param postId The post where need to get flag status
    /// @param replyId The reply where need to get flag status
    /// @param commentId The comment where need to get flag status
    // return value:
    // downVote = -1
    // NONE = 0
    // upVote = 1
    function getStatusHistory(
        PostCollection storage self, 
        address userAddr,
        uint256 postId,
        uint16 replyId,
        uint8 commentId
    ) public view returns (int256) {
        PostContainer storage postContainer = getPostContainer(self, postId);

        int256 statusHistory;
        if (commentId != 0) {
            CommentContainer storage commentContainer = getCommentContainerSafe(postContainer, replyId, commentId);
            statusHistory = commentContainer.historyVotes[userAddr];
        } else if (replyId != 0) {
            ReplyContainer storage replyContainer = getReplyContainerSafe(postContainer, replyId);
            statusHistory = replyContainer.historyVotes[userAddr];
        } else {
            statusHistory = postContainer.historyVotes[userAddr];
        }

        return statusHistory;
    }

    /// @notice Get count upvotes and downvotes in item
    /// @param historyVotes history votes
    /// @param votedUsers Array voted users
    function getHistoryInformations(
        mapping(address => int256) storage historyVotes,
        address[] storage votedUsers
    ) private view returns (int32, int32) {
        int32 positive;
        int32 negative;
        uint256 countVotedUsers = votedUsers.length;
        for (uint256 i; i < countVotedUsers; i++) {
            if (historyVotes[votedUsers[i]] == 1) positive++;
            else if (historyVotes[votedUsers[i]] == -1) negative++;
        }
        return (positive, negative);
    }

    /// @notice Return translation, the translation is checked on delete one
    /// @param self The mapping containing all translations
    /// @param postId The post where need to get translation
    /// @param replyId The reply where need to get translation
    /// @param commentId The comment where need to get translation
    /// @param language The translation which need find
    function getTranslationSafe(
        TranslationCollection storage self,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language language
    ) private view returns (TranslationContainer storage) {
        bytes32 item = getTranslationItemHash(postId, replyId, commentId, language);
        TranslationContainer storage translationContainer = self.translations[item];
        require(!CommonLib.isEmptyIpfs(translationContainer.info.ipfsDoc.hash), "Translation_not_exist."); // todo: tests
        require(!translationContainer.info.isDeleted, "Translation_deleted.");                         // todo: tests
        
        return translationContainer;
    }

    /// @notice Return translation
    /// @param self The mapping containing all translations
    /// @param postId The post where need to get translation
    /// @param replyId The reply where need to get translation
    /// @param commentId The comment where need to get translation
    /// @param language The translation which need find
    function getTranslation(
        TranslationCollection storage self,
        uint256 postId,
        uint16 replyId,
        uint8 commentId,
        Language language
    ) internal view returns (Translation memory) {
        bytes32 item = getTranslationItemHash(postId, replyId, commentId, language);
        return self.translations[item].info;
    }

    /// @notice Return all translations for post/reply/comment
    /// @param self The mapping containing all translations
    /// @param postId The post where need to get translation
    /// @param replyId The reply where need to get translation
    /// @param commentId The comment where need to get translation
    function getTranslations(
        TranslationCollection storage self,
        uint256 postId,
        uint16 replyId,
        uint8 commentId
    ) internal view returns (Translation[] memory) {
        Translation[] memory translation = new Translation[](uint256(LANGUAGE_LENGTH));

        for (uint256 i; i < uint(LANGUAGE_LENGTH); i++) {
            bytes32 item = getTranslationItemHash(postId, replyId, commentId, Language(uint(i)));
            translation[i] = self.translations[item].info;
        }
        return translation;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./PostLib.sol";


/// @title VoteLib
/// @notice Provides information about operation with posts                     //
/// @dev posts information is stored in the mapping on the main contract        ///
library VoteLib  {
    enum ResourceAction { Downvote, Upvoted, Downvoted, AcceptReply, AcceptedReply, FirstReply, QuickReply }

    struct StructRating {
        int32 upvotedPost;
        int32 downvotedPost;

        int32 upvotedReply;
        int32 downvotedReply;
        int32 firstReply;
        int32 quickReply;
        int32 acceptReply;
        int32 acceptedReply;
    }

    function getExpertRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedExpertPost,
           downvotedPost: DownvotedExpertPost,

           upvotedReply: UpvotedExpertReply,
           downvotedReply: DownvotedExpertReply,
           firstReply: FirstExpertReply,
           quickReply: QuickExpertReply,
           acceptReply: AcceptExpertReply,
           acceptedReply: AcceptedExpertReply
        });
    }

    function getCommonRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedCommonPost,
           downvotedPost: DownvotedCommonPost,

           upvotedReply: UpvotedCommonReply,
           downvotedReply: DownvotedCommonReply,
           firstReply: FirstCommonReply,
           quickReply: QuickCommonReply,
           acceptReply: AcceptCommonReply,
           acceptedReply: AcceptedCommonReply
        });
    }

    function getTutorialRating() internal pure returns (StructRating memory) {
        return StructRating({
           upvotedPost: UpvotedTutorial,
           downvotedPost: DownvotedTutorial,

           upvotedReply: 0,
           downvotedReply: 0,
           firstReply: 0,
           quickReply: 0,
           acceptReply: 0,
           acceptedReply: 0
        });
    }

    // give proper names to constaints, e.g. DOWNVOTE_EXPERT_POST
    //expert post
    int32 constant DownvoteExpertPost = -1;
    int32 constant UpvotedExpertPost = 5;
    int32 constant DownvotedExpertPost = -2;

    //common post 
    int32 constant DownvoteCommonPost = -1;
    int32 constant UpvotedCommonPost = 1;
    int32 constant DownvotedCommonPost = -1;

    //tutorial 
    int32 constant DownvoteTutorial = -1;
    int32 constant UpvotedTutorial = 5;
    int32 constant DownvotedTutorial = -2;

    int32 constant DeleteOwnPost = -1;
    int32 constant ModeratorDeletePost = -2;

/////////////////////////////////////////////////////////////////////////////

    //expert reply
    int32 constant DownvoteExpertReply = -1;
    int32 constant UpvotedExpertReply = 10;
    int32 constant DownvotedExpertReply = -2;
    int32 constant AcceptExpertReply = 15;
    int32 constant AcceptedExpertReply = 2;
    int32 constant FirstExpertReply = 5;
    int32 constant QuickExpertReply = 5;

    //common reply 
    int32 constant DownvoteCommonReply = -1;
    int32 constant UpvotedCommonReply = 1;
    int32 constant DownvotedCommonReply = -1;
    int32 constant AcceptCommonReply = 3;
    int32 constant AcceptedCommonReply = 1;
    int32 constant FirstCommonReply = 1;
    int32 constant QuickCommonReply = 1;
    
    int32 constant DeleteOwnReply = -1;
    int32 constant ModeratorDeleteReply = -2;            // to do

/////////////////////////////////////////////////////////////////////////////////

    int32 constant ModeratorDeleteComment = -1;

    /// @notice Get value Rating for post action
    /// @param postType Type post: expertPost, commonPost, tutorial
    /// @param resourceAction Rating action: Downvote, Upvoted, Downvoted
    function getUserRatingChangeForPostAction(
        PostLib.PostType postType,
        ResourceAction resourceAction
    ) internal pure returns (int32) {
 
        if (PostLib.PostType.ExpertPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteExpertPost;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedExpertPost;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedExpertPost;

        } else if (PostLib.PostType.CommonPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteCommonPost;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedCommonPost;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedCommonPost;

        } else if (PostLib.PostType.Tutorial == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteTutorial;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedTutorial;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedTutorial;

        }
        
        revert("Invalid_post_type");
    }

    /// @notice Get value Rating for rating action
    /// @param postType Type post: expertPost, commonPost, tutorial
    /// @param resourceAction Rating action: Downvote, Upvoted, Downvoted, AcceptReply...
    function getUserRatingChangeForReplyAction(
        PostLib.PostType postType,
        ResourceAction resourceAction
    ) internal pure returns (int32) {
 
        if (PostLib.PostType.ExpertPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteExpertReply;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedExpertReply;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedExpertReply;
            else if (ResourceAction.AcceptReply == resourceAction) return AcceptExpertReply;
            else if (ResourceAction.AcceptedReply == resourceAction) return AcceptedExpertReply;
            else if (ResourceAction.FirstReply == resourceAction) return FirstExpertReply;
            else if (ResourceAction.QuickReply == resourceAction) return QuickExpertReply;

        } else if (PostLib.PostType.CommonPost == postType) {
            if (ResourceAction.Downvote == resourceAction) return DownvoteCommonReply;
            else if (ResourceAction.Upvoted == resourceAction) return UpvotedCommonReply;
            else if (ResourceAction.Downvoted == resourceAction) return DownvotedCommonReply;
            else if (ResourceAction.AcceptReply == resourceAction) return AcceptCommonReply;
            else if (ResourceAction.AcceptedReply == resourceAction) return AcceptedCommonReply;
            else if (ResourceAction.FirstReply == resourceAction) return FirstCommonReply;
            else if (ResourceAction.QuickReply == resourceAction) return QuickCommonReply;

        } else if (PostLib.PostType.Tutorial == postType) {
            return 0;
        }
        
        revert("invalid_resource_type");
    }

    function getUserRatingChange(
        PostLib.PostType postType,
        ResourceAction resourceAction,
        PostLib.TypeContent typeContent
    ) internal pure returns (int32) {
        if (PostLib.TypeContent.Post == typeContent) {
            return getUserRatingChangeForPostAction(postType, resourceAction);
        } else if (PostLib.TypeContent.Reply == typeContent) {
            return getUserRatingChangeForReplyAction(postType, resourceAction);
        }
        return 0;
    }

    /// @notice Get vote history
    /// @param user user who voted for content
    /// @param historyVote history vote all users
    // return value:
    // downVote = -1
    // NONE = 0
    // upVote = 1
    function getHistoryVote(
        address user,
        mapping(address => int256) storage historyVote
    ) private view returns (int256) {
        return historyVote[user];
    }

    /// @notice .
    /// @param actionAddress user who voted for content
    /// @param historyVotes history vote all users
    /// @param isUpvote Upvote or downvote
    /// @param votedUsers the list users who voted
    // return value:
    // fromUpVoteToDownVote = -2
    // cancel downVote = 1  && upVote = 1       !!!!
    // cancel upVote = -1   && downVote = -1    !!!!
    // fromDownVoteToUpVote = 2
    function getForumItemRatingChange(
        address actionAddress,
        mapping(address => int256) storage historyVotes,
        bool isUpvote,
        address[] storage votedUsers
    ) internal returns (int32, bool) {
        int history = getHistoryVote(actionAddress, historyVotes);
        int32 ratingChange;
        bool isCancel;
        
        if (isUpvote) {
            if (history == -1) {
                historyVotes[actionAddress] = 1;
                ratingChange = 2;
            } else if (history == 0) {
                historyVotes[actionAddress] = 1;
                ratingChange = 1;
                votedUsers.push(actionAddress);
            } else {
                historyVotes[actionAddress] = 0;
                ratingChange = -1;
                isCancel = true;
            }
        } else {
            if (history == -1) {
                historyVotes[actionAddress] = 0;
                ratingChange = 1;
                isCancel = true;
            } else if (history == 0) {
                historyVotes[actionAddress] = -1;
                ratingChange = -1;
                votedUsers.push(actionAddress);
            } else {
                historyVotes[actionAddress] = -1;
                ratingChange = -2;
            }
        }

        if (isCancel) {
            uint256 votedUsersLength = votedUsers.length;
            for (uint256 i; i < votedUsersLength; i++) {
                if (votedUsers[i] == actionAddress) {
                    delete votedUsers[i];
                    break;
                }
            }
        }

        return (ratingChange, isCancel);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;
import "../libraries/UserLib.sol";
import "../libraries/RewardLib.sol";
pragma abicoder v2;


interface IPeeranhaUser {
    function onlyDispatcher(address sender) external;
    function createUser(address user, bytes32 ipfsHash) external;
    function updateUser(address user, bytes32 ipfsHash) external;
    function followCommunity(address user, uint32 communityId) external;
    function unfollowCommunity(address user, uint32 communityId) external;
    function initCommunityAdminPermission(address user, uint32 communityId) external;
    function giveCommunityAdminPermission(address user, address userAddr, uint32 communityId) external;
    function checkActionRole(address actionCaller, address dataUser, uint32 communityId, UserLib.Action action, UserLib.ActionRole actionRole, bool isCreate) external;
    function isProtocolAdmin(address userAddr) external view returns (bool);
    function checkHasRole(address actionCaller, UserLib.ActionRole actionRole, uint32 communityId) external view;
    function getRatingToReward(address user, uint16 period, uint32 communityId) external view returns (int32);
    function getPeriodRewardShares(uint16 period) external view returns(RewardLib.PeriodRewardShares memory);
    function getUserRewardCommunities(address user, uint16 rewardPeriod) external view returns(uint32[] memory);
    function updateUserRating(address userAddr, int32 rating, uint32 communityId) external;
    function updateUsersRating(UserLib.UserRatingChange[] memory usersRating, uint32 communityId) external;
}