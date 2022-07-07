// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IBalanceVault.sol";
import "./utils/IVotingMultiplier.sol";
import "./utils/IStakingLevel.sol";

/**
 * @dev Use to conduct contest and stored vote and comment for contest's entry.
 * Has user related functions for adding user, verify user and update user role.
 * Has contest related functions for initializing new contest and adjusting existing contest.
 * Has one entry related function for adding entry to existing contest.
 * Has a function to vote in user stead.
 * Has a function to comment in user stead.
 * Has reward related functions for retriving user reward value and claim user reward.
 * @notice Is pausable to prevent malicious behavior.
 * @notice Utilize balance vault to minimize gas cost in reward distribution.
 */
contract Voting is Ownable, AccessControl, Pausable {
    bytes32 public constant WORKER = keccak256("WORKER");
    uint256 public constant SCORE_TYPE = 8;
    uint256 public constant SCORE_MIN = 1;
    uint256 public constant SCORE_MAX = 8;
    uint256 public constant SCORE_TOTAL_MIN = 8;
    uint256 public constant SCORE_TOTAL_MAX = 60;
    IVotingMultiplier public votingMultiplier;
    IBalanceVault public balanceVault;
    IStakingLevel public stakingLevel;
    mapping(address => User) public userByAddress;
    mapping(string => Contest) public contestByContestId;

    struct User {
        uint256 role;
        bool verified;
    }
    struct Vote {
        uint256 voteId;
        uint256 level;
        uint256 role;
        bool verified;
        uint256 time;
        uint256[SCORE_TYPE] scores;
        uint256 reward;
    }
    struct Comment {
        uint256 commentId;
        uint256 level;
        uint256 role;
        bool verified;
        uint256 time;
        string message;
        uint256 reward;
    }
    struct Entry {
        string projectId;
        uint256[SCORE_TYPE] totalScores;
        uint256[SCORE_TYPE] totalWeights;
        mapping(address => Vote) voteByAddress;
        uint256 voteCount;
        uint256 voteReward;
        uint256 debtVoteReward;
        uint256 rewardPerVote;
        uint256 lastRewardVoteId;
        mapping(address => Comment) commentByAddress;
        uint256 commentCount;
        uint256 commentReward;
        uint256 debtCommentReward;
        uint256 rewardPerComment;
        uint256 lastRewardCommentId;
    }
    struct Contest {
        string contestId;
        uint256 startDate;
        uint256 endDate;
        uint256 totalVoteReward;
        uint256 totalDebtVoteReward;
        uint256 totalClaimedVoteReward;
        uint256 totalCommentReward;
        uint256 totalDebtCommentReward;
        uint256 totalClaimedCommentReward;
        uint256 entryCount;
        mapping(string => uint256) entryIdByProjectId;
        mapping(uint256 => Entry) entryByEntryId;
        mapping(address => ContestUserInfo) contestUserInfoByAddress;
    }
    struct ContestUserInfo {
        uint256 userVoteReward;
        string[] userVoteParticipation;
        uint256 userCommentReward;
        string[] userCommentParticipation;
        bool userClaimed;
    }
    struct UserEntryReward {
        string projectId;
        uint256 entryVoteReward;
        uint256 entryCommentReward;
    }

    event UserAdded(address indexed userAddress);
    event UserRoleUpdated(address indexed userAddress, uint256 role);
    event UserVerified(address indexed userAddress);
    event ContestInited(string indexed contestId, uint256 startDate, uint256 endDate);
    event ContestAdjusted(string indexed contestId, uint256 startDate, uint256 endDate);
    event ContestEntryAdded(string indexed contestId, string indexed projectId, uint256 entryVoteReward, uint256 entryCommentReward, uint256 entryBasePerVoteReward, uint256 entryBasePerCommentReward);
    event Voted(string indexed contestId, string indexed projectId, address indexed userAddress, uint256[SCORE_TYPE] scores);
    event Commented(string indexed contestId, string indexed projectId, address indexed userAddress, string message);
    event UserContestVoteRewardAdded(string indexed contestId, address indexed userAddress, uint256 voteReward);
    event UserContestCommentRewardAdded(string indexed contestId, address indexed userAddress, uint256 commentReward);
    event UserContestRewardClaimed(string indexed contestId, address indexed userAddress, uint256 voteClaimAmount, uint256 commentClaimAmount);
    event MultiplierAddressUpdated(address newAddress);
    event BalanceVaultAddressUpdated(address newAddress);
    event StakingLevelAddressUpdated(address newAddress);

    /** 
    * @dev Set the address of balance vault and voting multiplier.
    * Setup role for deployer.
    * @param _balanceVaultAddress - Contract balance vault address.
    * @param _multiplierAddress - Contract voting multiplier address.
    */
    constructor(address _balanceVaultAddress, address _multiplierAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);
        setBalanceVaultAddress(_balanceVaultAddress);
        setMultiplierAddress(_multiplierAddress);
    }

    /**
    * @dev Allow when contest is initilized.
    */
    modifier afterContestInited(string memory _contestId) {
        require(
            bytes(contestByContestId[_contestId].contestId).length > 0,
            "[Voting.afterContestInited] Contest not initialized yet"
        );
        _;
    }
    /**
    * @dev Allow when contest not started.
    */
    modifier beforeContestStarted(string memory _contestId) {
        require(
            block.timestamp < contestByContestId[_contestId].startDate,
            "[Voting.beforeContestStarted] Contest already started"
        );
        _;
    }
    /**
    * @dev Allow when in contest period.
    */
    modifier inContestPeriod(string memory _contestId) {
        require(
            (block.timestamp >= contestByContestId[_contestId].startDate && block.timestamp < contestByContestId[_contestId].endDate),
            "[Voting.inContestPeriod] Not in contest period"
        );
        _;
    }
    /**
    * @dev Allow when contest has ended.
    */
    modifier afterContestEnded(string memory _contestId) {
        require(
            block.timestamp >= contestByContestId[_contestId].endDate,
            "[Voting.afterContestEnded] Contest not ended yet"
        );
        _;
    }
    /**
    * @dev Allow when specify project id of entry exist in contest.
    */
    modifier contestEntryExist(string memory _contestId, string memory _projectId) {
        require(
            contestByContestId[_contestId].entryIdByProjectId[_projectId] != 0,
            "[Voting.contestEntryExist] Contest entry not exist for specifiy project id"
        );
        _;
    }
    /**
    * @dev Allow when user registered (has role).
    */
    modifier userExist(address _userAddress) {
        require(
            userByAddress[_userAddress].role != 0,
            "[Voting.userExist] User not registered"
        );
        _;
    }
    /**
    * @dev Allow when user role valid.
    */
    modifier roleValid(uint256 _role) {
        require(
            isRoleValid(_role),
            "[Voting.roleValid] Invalid user role"
        );
        _;
    }
    /**
    * @dev Allow when date range valid and be in future.
    */
    modifier dateRangeValid(uint256 _startDate, uint256 _endDate) {
        require(
            (_startDate > block.timestamp && _endDate > block.timestamp),
            "[Voting.dateRangeValid] Start and end date should not be in the past"
        );
        require(
            _startDate < _endDate,
             "[Voting.dateRangeValid] Start date should be less than end date"
        );
        _;
    }

    /**
     * @dev Revert receive and fallback functions.
     */
    receive() external payable {
        revert("[Voting] Revert receive function.");
    }
    fallback() external payable {
        revert("[Voting] Revert fallback function.");
    }

    /** 
    * @dev Return boolean whether each and sum of scores is valid.
    * @param _scores - Scores array.
    */
    function isScoresValid(uint256[SCORE_TYPE] memory _scores)
        internal
        pure
        returns (bool)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < _scores.length; i++) {
            uint256 score = _scores[i];
            if (score < SCORE_MIN || score > SCORE_MAX) {
                return false;
            }
            sum += score;
        }
        return (sum <= SCORE_TOTAL_MAX && sum >= SCORE_TOTAL_MIN);
    }

    /** 
    * @dev Return boolean whether role is valid.
    * @param _role - User role.
    */
    function isRoleValid(uint256 _role) internal view returns (bool) {
        uint256 roleType = votingMultiplier.getRoleType();
        return (_role > 0 && _role <= roleType);
    }

    /** 
    * @dev Register user using address and role.
    * @param _userAddress - User address.
    * @param _role - User role.
    */
    function addUser(address _userAddress, uint256 _role)
        external
        whenNotPaused
        onlyRole(WORKER)
        roleValid(_role)
    {
        User storage user = userByAddress[_userAddress];
        require(user.role == 0, "[Voting.addUser] User already exist");
        user.role = _role;

        emit UserAdded(_userAddress);
        emit UserRoleUpdated(_userAddress, _role);
    }

    /** 
    * @dev Update user to verified user (judge).
    * @param _userAddress - User address.
    */
    function verifyUser(address _userAddress)
        external
        whenNotPaused
        onlyRole(WORKER)
        userExist(_userAddress)
    {
        User storage user = userByAddress[_userAddress];
        require(user.verified == false, "[Voting.verifyUser] User already verified");
        user.verified = true;

        emit UserVerified(_userAddress);
    }

    /** 
    * @dev Update user role.
    * @param _role - User role.
    */
    function updateUserRole(uint256 _role)
        external
        whenNotPaused
        userExist(msg.sender)
        roleValid(_role)
    {
        User storage user = userByAddress[msg.sender];
        user.role = _role;

        emit UserRoleUpdated(msg.sender, _role);
    }

    /** 
    * @dev Initilize new contest.
    * @param _contestId - New contest id.
    * @param _startDate - Start date time stamp.
    * @param _endDate - End date time stamp.
    */
    function initContest(
        string memory _contestId,
        uint256 _startDate,
        uint256 _endDate
    )
        external 
        whenNotPaused
        onlyRole(WORKER)
        dateRangeValid(_startDate, _endDate)
    {
        require(bytes(_contestId).length > 0, "[Voting.initContest] Contest id length invalid");
        Contest storage contest = contestByContestId[_contestId];
        require(bytes(contest.contestId).length == 0, "[Voting.initContest] Contest already initialized");

        contest.contestId = _contestId;
        contest.startDate = _startDate;
        contest.endDate = _endDate;

        emit ContestInited(_contestId, _startDate, _endDate);
    }

    /** 
    * @dev Adjust existing contest with no entry.
    * @param _contestId - Existing contest id.
    * @param _startDate - New start date time stamp.
    * @param _endDate - New end date time stamp.
    */
    function adjustContest(
        string memory _contestId,
        uint256 _startDate,
        uint256 _endDate
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        afterContestInited(_contestId)
        beforeContestStarted(_contestId)
        dateRangeValid(_startDate, _endDate)
    {
        Contest storage contest = contestByContestId[_contestId];
        require(
            contest.entryCount == 0,
             "[Voting.adjustContest] Cannot adjust contest with entry"
        );
        contest.startDate = _startDate;
        contest.endDate = _endDate;

        emit ContestAdjusted(_contestId, _startDate, _endDate);
    }

    /** 
    * @dev Add entry to existing contest using project id.
    * Add entry reward to contest reward.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    * @param _entryVoteReward - Calculated vote reward to be added to contest.
    * @param _entryCommentReward - Calculated comment reward to be added to contest.
    */
    function addContestEntry(
        string memory _contestId,
        string memory _projectId,
        uint256 _entryVoteReward,
        uint256 _entryCommentReward,
        uint256 _entryRewardPerVote,
        uint256 _entryRewardPerComment
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        afterContestInited(_contestId)
    {
        Contest storage contest = contestByContestId[_contestId];
        require(contest.entryIdByProjectId[_projectId] == 0, "[Voting.addContestEntry] Entry already exist for specifiy project id");
        contest.totalVoteReward += _entryVoteReward;
        contest.totalCommentReward += _entryCommentReward;
        contest.entryCount++;

        uint256 entryId = contest.entryCount;
        contest.entryIdByProjectId[_projectId] = entryId;
        Entry storage entry = contest.entryByEntryId[entryId];
        entry.projectId = _projectId;
        entry.voteReward = _entryVoteReward;
        entry.commentReward = _entryCommentReward;
        entry.rewardPerVote = _entryRewardPerVote;
        entry.rewardPerComment = _entryRewardPerComment;

        emit ContestEntryAdded(_contestId, _projectId, _entryVoteReward, _entryCommentReward, _entryRewardPerVote, _entryRewardPerComment);
    }

    /** 
    * @dev Vote for contest entry in user stead.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    * @param _userAddress - User address.
    * @param _scores - Scores array represent each attribute.
    */
    function voteForContestEntry(
        string memory _contestId,
        string memory _projectId,
        address _userAddress,
        uint256[SCORE_TYPE] memory _scores
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        afterContestInited(_contestId)
        inContestPeriod(_contestId)
        contestEntryExist(_contestId, _projectId)
        userExist(_userAddress)
    {
        require(isScoresValid(_scores), "[Voting.voteForContestEntry] Invalid scores array");
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Vote storage vote = entry.voteByAddress[_userAddress];
        require(vote.voteId == 0, "[Voting.voteForContestEntry] User already voted");

        updateVoteData(contest, entry, vote, _userAddress, _scores);
        stakingLevel.setWithdrawDelay(_userAddress, contest.endDate);

        emit Voted(_contestId, _projectId, _userAddress, _scores);
    }

    /** 
    * @dev Update vote data for contest, entry and vote.
    * Contest - Add project id to user vote participation.
    * Contest - Add user vote reward if eligible.
    * Entry - Add calculated scores to total.
    * Entry - Count vote.
    * Vote - Store raw scores and vote related data.
    * @param _contest - Voted contest storage.
    * @param _entry - Voted entry storage of project id.
    * @param _vote - User vote storage.
    * @param _userAddress - User address.
    * @param _scores - Scores array.
    * @notice Seperate from main function to avoid stack too deep.
    */
    function updateVoteData(
        Contest storage _contest,
        Entry storage _entry,
        Vote storage _vote,
        address _userAddress,
        uint256[SCORE_TYPE] memory _scores
    ) internal {
        User memory user = userByAddress[_userAddress];
        ContestUserInfo storage contestUserInfo = _contest.contestUserInfoByAddress[_userAddress];
        uint256 level = stakingLevel.getUserStakeLevel(_userAddress);
        uint256[SCORE_TYPE] memory multiplier = votingMultiplier.getScoreMultiplier(user.verified, user.role, level);
        (uint256 voteMult, ,uint256 multPrecision ) = votingMultiplier.getRewardMultiplier(user.verified, level);
        uint256 calRewardPerVote = (_entry.rewardPerVote * voteMult) / multPrecision;

        // Update Contest Data
        contestUserInfo.userVoteParticipation.push(_entry.projectId);

        // Update Entry Data
        for (uint256 i = 0; i < SCORE_TYPE; i++) {
            uint256 calScore = _scores[i] * multiplier[i];
            _entry.totalScores[i] += calScore;
            _entry.totalWeights[i] += multiplier[i];
        }
        _entry.voteCount++;

        // Update Vote data
        _vote.voteId = _entry.voteCount;
        _vote.level = level;
        _vote.role = user.role;
        _vote.verified = user.verified;
        _vote.time = block.timestamp;
        _vote.scores = _scores;

        // Update Reward data
        if (_entry.lastRewardVoteId == 0) {
            // Track reward data on each data level
            _contest.totalDebtVoteReward += calRewardPerVote;
            contestUserInfo.userVoteReward += calRewardPerVote;
            _entry.debtVoteReward += calRewardPerVote;
            _vote.reward = calRewardPerVote;

            // Set last reward id if updated debt more than or equal reward
            if(_entry.debtVoteReward >= _entry.voteReward) {
                _entry.lastRewardVoteId = _entry.voteCount;
            }

            emit UserContestVoteRewardAdded(_contest.contestId, _userAddress, calRewardPerVote);
        }
    }

    /** 
    * @dev Comment for contest entry in user stead.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    * @param _userAddress - User address.
    * @param _message - Comment message.
    */
    function commentForContestEntry(
        string memory _contestId,
        string memory _projectId,
        address _userAddress,
        string memory _message
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        afterContestInited(_contestId)
        inContestPeriod(_contestId)
        contestEntryExist(_contestId, _projectId)
        userExist(_userAddress)
    {
        require((bytes(_message).length > 0 && bytes(_message).length <= 1000), "[Voting.commentForContestEntry] Invalid message length");
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Comment storage comment = entry.commentByAddress[_userAddress];
        require(comment.commentId == 0, "[Voting.commentForContestEntry] User already commented");

        updateCommentData(contest, entry, comment, _userAddress, _message);
        stakingLevel.setWithdrawDelay(_userAddress, contest.endDate);

        emit Commented(_contestId, _projectId, _userAddress, _message);
    }

    /** 
    * @dev Update comment data for contest, entry and comment.
    * Contest - Add project id to user comment participation.
    * Contest - Add user comment reward if eligible.
    * Entry - Count comment.
    * Vote - Store message and comment related data.
    * @param _contest - Voted contest storage.
    * @param _entry - Voted entry storage of project id.
    * @param _comment - User comment storage.
    * @param _userAddress - User address.
    * @param _message - Comment message.
    * @notice Seperate from main function to avoid stack too deep.
    */
    function updateCommentData(
        Contest storage _contest,
        Entry storage _entry,
        Comment storage _comment,
        address _userAddress,
        string memory _message
    ) internal {
        User memory user = userByAddress[_userAddress];
        ContestUserInfo storage contestUserInfo = _contest.contestUserInfoByAddress[_userAddress];
        uint256 level = stakingLevel.getUserStakeLevel(_userAddress);
        (, uint256 commentMult ,uint256 multPrecision ) = votingMultiplier.getRewardMultiplier(user.verified, level);
        uint256 calRewardPerComment = (_entry.rewardPerComment * commentMult) / multPrecision;

        // Update Contest Data
        contestUserInfo.userCommentParticipation.push(_entry.projectId);

        // Update Entry Data
        _entry.commentCount++;

        // Update Comment data
        _comment.commentId = _entry.commentCount;
        _comment.level = level;
        _comment.role = user.role;
        _comment.verified = user.verified;
        _comment.time = block.timestamp;
        _comment.message = _message;

        // Update Reward Data
        if (_entry.lastRewardCommentId == 0) {
            // Track reward data on each data level
            _contest.totalDebtCommentReward += calRewardPerComment;
            contestUserInfo.userCommentReward += calRewardPerComment;
            _entry.debtCommentReward += calRewardPerComment;
            _comment.reward = calRewardPerComment;

            // Set last reward id if updated debt more than or equal reward
            if(_entry.debtCommentReward >= _entry.commentReward) {
                _entry.lastRewardCommentId = _entry.commentCount;
            }

            emit UserContestCommentRewardAdded(_contest.contestId, _userAddress, calRewardPerComment);
        }
    }

    /** 
    * @dev Claim contest reward for user by transfering to balance vault.
    * @param _contestId - Contest id.
    * @param _userAddress - User address.
    */
    function claimUserContestReward(
        string memory _contestId,
        address _userAddress
    )
        external
        onlyRole(WORKER)
        afterContestInited(_contestId)
        afterContestEnded(_contestId)
        userExist(_userAddress)
    {
        Contest storage contest = contestByContestId[_contestId];
        ContestUserInfo storage contestUserInfo = contest.contestUserInfoByAddress[_userAddress];
        require(!contestUserInfo.userClaimed, "[Voting.claimUserContestReward] User already claim contest reward");
        
        uint256 claimAmount = contestUserInfo.userVoteReward + contestUserInfo.userCommentReward;
        require(claimAmount > 0, "[Voting.claimUserContestReward] No claimable contest reward");
        contest.totalClaimedVoteReward += contestUserInfo.userVoteReward;
        contest.totalClaimedCommentReward += contestUserInfo.userCommentReward;
        contestUserInfo.userClaimed = true;
        balanceVault.decreaseReward(claimAmount);
        balanceVault.increaseBalance(_userAddress, claimAmount);

        emit UserContestRewardClaimed(_contestId, _userAddress, contestUserInfo.userVoteReward, contestUserInfo.userCommentReward);
    }

    /** 
    * @dev Get infomation in contest level.
    * @param _contestId - Contest id.
    */
    function getContestInfo(string memory _contestId)
        external
        view
        returns (
            uint256 startDate,
            uint256 endDate,
            uint256 totalVoteReward,
            uint256 totalDebtVoteReward,
            uint256 totalClaimedVoteReward,
            uint256 totalCommentReward,
            uint256 totalDebtCommentReward,
            uint256 totalClaimedCommentReward,
            string[] memory entryList
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        startDate = contest.startDate;
        endDate = contest.endDate;
        totalVoteReward = contest.totalVoteReward;
        totalDebtVoteReward = contest.totalDebtVoteReward;
        totalClaimedVoteReward = contest.totalClaimedVoteReward;
        totalCommentReward = contest.totalCommentReward;
        totalDebtCommentReward = contest.totalDebtCommentReward;
        totalClaimedCommentReward = contest.totalClaimedCommentReward;

        uint256 entryCount = contest.entryCount;
        string[] memory list = new string[](entryCount);
        for (uint256 i = 0; i < entryCount; i++) {
            uint256 entryId = i + 1;
            list[i] = contest.entryByEntryId[entryId].projectId;
        }
        entryList = list;
    }

    /** 
    * @dev Get contest partication of user.
    * @param _contestId - Contest id.
    * @param _userAddress - User address.
    */
    function getContestUserParticipation(
        string memory _contestId,
        address _userAddress
    ) external view
        returns (
            string[] memory userVoteParticipation,
            string[] memory userCommentParticipation
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        ContestUserInfo storage contestUserInfo = contest.contestUserInfoByAddress[_userAddress];
        userVoteParticipation = contestUserInfo.userVoteParticipation;
        userCommentParticipation = contestUserInfo.userCommentParticipation;
    }

    /** 
    * @dev Get claimable contest reward for user.
    * @param _contestId - Contest id.
    * @param _userAddress - User address.
    * @notice Utilize block scoping to prevent stack too deep.
    */
    function getContestUserReward(
        string memory _contestId,
        address _userAddress
    ) external view
        returns (
            uint256 userVoteReward,
            uint256 userCommentReward,
            bool userClaimed,
            UserEntryReward[] memory userEntriesReward
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        userVoteReward = contest.contestUserInfoByAddress[_userAddress].userVoteReward;
        userCommentReward = contest.contestUserInfoByAddress[_userAddress].userCommentReward;
        userClaimed = contest.contestUserInfoByAddress[_userAddress].userClaimed;

        // Create set of projectId set length to maximum possible
        string[] memory setProjectId = new string[](contest.entryCount);
        uint256 setProjectIdLength;
        // Create unique array of projectId from vote and comment participation array
        {
            string[] memory userVotes = contest.contestUserInfoByAddress[_userAddress].userVoteParticipation;
            string[] memory userComments = contest.contestUserInfoByAddress[_userAddress].userCommentParticipation;
            if(userVotes.length > 0) {
                // If user voted add all vote array member to set
                for (uint256 i = 0; i < userVotes.length; i++) {
                    setProjectId[setProjectIdLength] = userVotes[i];
                    setProjectIdLength++;
                }
                
                // Add non-exist projectId from comment into set
                for (uint256 i = 0; i < userComments.length; i++) {
                    string memory projectId = userComments[i];
                    bool isExist;
                    for (uint256 j = 0; j < userVotes.length; j++) {
                        string memory existProjectId = userVotes[j];
                        if(keccak256(bytes(projectId)) == keccak256(bytes(existProjectId))) {
                            isExist = true;
                            break;
                        }
                    }
                    if(!isExist) {
                        setProjectId[setProjectIdLength] = projectId;
                        setProjectIdLength++;
                    }
                }
            } else {
                // else use comment as set projectId
                setProjectId = userComments;
                setProjectIdLength = userComments.length;
            }
        }
        UserEntryReward[] memory list = new UserEntryReward[](setProjectIdLength);
        // Create user entries reward from unique array
        {
            uint256 listLength = 0;
            for (uint256 i = 0; i < setProjectIdLength; i++) {
                Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[setProjectId[i]]];
                list[listLength] = UserEntryReward(
                    setProjectId[i],
                    entry.voteByAddress[_userAddress].reward,
                    entry.commentByAddress[_userAddress].reward
                );
                listLength++;
            }
        }
        userEntriesReward = list;
    }

    /** 
    * @dev Get vote infomation in entry level.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    */
    function getEntryVoteInfo(string memory _contestId, string memory _projectId)
        external
        view
        returns (
            uint256 voteCount,
            uint256 voteReward,
            uint256 debtVoteReward,
            uint256 rewardPerVote,
            uint256 lastRewardVoteId,
            uint256[SCORE_TYPE] memory totalScores,
            uint256[SCORE_TYPE] memory totalWeights
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        voteCount = entry.voteCount;
        voteReward = entry.voteReward;
        debtVoteReward = entry.debtVoteReward;
        rewardPerVote = entry.rewardPerVote;
        lastRewardVoteId = entry.lastRewardVoteId;
        totalScores = entry.totalScores;
        totalWeights = entry.totalWeights;
    }

    /** 
    * @dev Get comment infomation in entry level.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    */
    function getEntryCommentInfo(string memory _contestId, string memory _projectId)
        external
        view
        returns (
            uint256 commentCount,
            uint256 commentReward,
            uint256 debtCommentReward,
            uint256 rewardPerComment,
            uint256 lastRewardCommentId
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        commentCount = entry.commentCount;
        commentReward = entry.commentReward;
        debtCommentReward = entry.debtCommentReward;
        rewardPerComment = entry.rewardPerComment;
        lastRewardCommentId = entry.lastRewardCommentId;
    }

    /** 
    * @dev Get infomation in vote level.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    * @param _userAddress - User address.
    */
    function getVoteInfo(
        string memory _contestId,
        string memory _projectId,
        address _userAddress
    )
        external
        view
        returns (
            uint256 voteId,
            uint256 level,
            uint256 role,
            bool verified,
            uint256 time,
            uint256[SCORE_TYPE] memory scores,
            uint256 reward
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Vote storage vote = entry.voteByAddress[_userAddress];
        voteId = vote.voteId;
        level = vote.level;
        role = vote.role;
        verified = vote.verified;
        scores = vote.scores;
        time = vote.time;
        reward = vote.reward;
    }

    /** 
    * @dev Get infomation in comment level.
    * @param _contestId - Contest id.
    * @param _projectId - Project id of entry.
    * @param _userAddress - User address.
    */
    function getCommentInfo(
        string memory _contestId,
        string memory _projectId,
        address _userAddress
    )
        external
        view
        returns (
            uint256 commentId,
            uint256 level,
            uint256 role,
            bool verified,
            uint256 time,
            string memory message,
            uint256 reward
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Comment storage comment = entry.commentByAddress[_userAddress];
        commentId = comment.commentId;
        level = comment.level;
        role = comment.role;
        verified = comment.verified;
        time = comment.time;
        message = comment.message;
        reward = comment.reward;
    }

    /** 
    * @dev Set new address for voting multiplier using specify address.
    * @param _multiplierAddress - New address of voting multiplier.
    */
    function setMultiplierAddress(address _multiplierAddress) public onlyOwner {
        votingMultiplier = IVotingMultiplier(_multiplierAddress);
        emit MultiplierAddressUpdated(_multiplierAddress);
    }

    /** 
    * @dev Set new address for balance vault using specify address.
    * @param _balanceVaultAddress - New address of balance vault.
    */
    function setBalanceVaultAddress(address _balanceVaultAddress) public onlyOwner {
        balanceVault = IBalanceVault(_balanceVaultAddress);
        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    /** 
    * @dev Set new address for staking level using specify address.
    * @param _stakingLevelAddress - New address of staking level.
    */
    function setStakingLevelAddress(address _stakingLevelAddress) public onlyOwner {
        stakingLevel = IStakingLevel(_stakingLevelAddress);
        emit StakingLevelAddressUpdated(_stakingLevelAddress);
    }

    /**
     * @dev Set voting in to pause state (only claim reward function and getter is allowed).
     */
    function pauseVoting() external onlyOwner {
        _pause();
    }

    /**
     * @dev Set voting in to normal state.
     */
    function unpauseVoting() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IBalanceVault{
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function increaseReward(uint256 _upoAmount) external;
    function decreaseReward(uint256 _upoAmount) external;
    function getBalance(address _userAddress) external view returns (uint256);
    function getReward() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVotingMultiplier{
    function getRoleType() external view returns (uint256);
    function getLevelType() external view returns (uint256);
    function getScoreMultiplier(bool _verified, uint256 _role, uint256 _level) external view returns (uint256[8] memory);
    function getRewardMultiplier(bool _verified, uint256 _level) external view returns (uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IStakingLevel {
    function getUserStakeLevel(address _userAddress) external view returns (uint256);
    function setWithdrawDelay(address _userAddress, uint256 _endDate) external;
    function addPoolReward(uint256 _upoAmount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}