// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IBalanceVaultV2.sol";
import "./utils/IStakingLevel.sol";
import "./utils/IVotingMultiplier.sol";

/**
 * @dev Use to conduct contest and stored vote and comment for contest's entry.
 * Has user related functions for adding user, verify user, update user role, update user ban status.
 * Has contest related functions for initializing new contest and adjusting existing contest.
 * Has entry related function for adding entry to existing contest.
 * Has a function to vote for entry in contest.
 * Has a function to comment for entry in contest.
 * Has reward related functions for retriving user reward value and claim user reward.
 * @notice Is pausable to prevent malicious behavior.
 */
contract Voting is Ownable, AccessControl, Pausable {
    struct User {
        address userAddress;
        uint256 role;
        bool verified;
        bool banned;
    }
    struct Vote {
        uint256 voteId;
        uint256 level;
        uint256 role;
        bool verified;
        uint256[] scores;
        uint256 time;
        uint256 rewardWeights;
    }
    struct Comment {
        uint256 commentId;
        uint256 level;
        uint256 role;
        bool verified;
        string message;
        uint256 time;
        uint256 rewardWeights;
    }
    struct Entry {
        string projectId;
        uint256[] totalScores;
        uint256[] totalScoresWeights;
        mapping(uint256 => Vote) voteByUserId;
        uint256 voteCount;
        uint256 voteReward;
        uint256 voteRewardWeights;
        mapping(uint256 => Comment) commentByUserId;
        uint256 commentCount;
        uint256 commentReward;
        uint256 commentRewardWeights;
    }
    struct Contest {
        string contestId;
        uint256 startDate;
        uint256 endDate;
        uint256 contestScoreType;
        uint256 totalVoteReward;
        uint256 totalClaimedVoteReward;
        uint256 totalCommentReward;
        uint256 totalClaimedCommentReward;
        mapping(string => uint256) entryIdByProjectId;
        mapping(uint256 => Entry) entryByEntryId;
        uint256 entryCount;
        mapping(uint256 => bool) contestUserClaimByUserId;
    }
    struct UserEntryReward {
        string projectId;
        uint256 entryVoteReward;
        uint256 entryCommentReward;
    }

    bytes32 public constant WORKER = keccak256("WORKER");

    IBalanceVaultV2 public balanceVault;
    IStakingLevel public stakingLevel;
    IVotingMultiplier public votingMultiplier;

    mapping(address => uint256) public userIdByAddress;
    mapping(uint256 => User) public userByUserId;
    mapping(string => Contest) public contestByContestId;
    uint256 internal latestUserId;
    uint256 public scoreMin;
    uint256 public scoreMax;
    uint256 public combineScoreMin;
    uint256 public combineScoreMax;
    uint256 public scoreType;
    uint256 public maxCommentLen;
    uint256 public roleType;
    bool public isWithdrawDelay;

    event UserAdded(address indexed userAddress, uint256 role, bool verified);
    event UserRoleUpdated(address indexed userAddress, uint256 role);
    event UserVerified(address indexed userAddress);
    event UserBanStatusUpdated(address indexed userAddress, bool banStatus);
    event UserAddressUpdated(
        address indexed userAddress,
        address indexed newUserAddress
    );
    event ContestInited(
        string indexed contestId,
        uint256 startDate,
        uint256 endDate
    );
    event ContestAdjusted(
        string indexed contestId,
        uint256 startDate,
        uint256 endDate
    );
    event ContestEntryAdded(
        string indexed contestId,
        string indexed projectId,
        address indexed userAddress,
        uint256 entryVoteReward,
        uint256 entryCommentReward
    );
    event Voted(
        string indexed contestId,
        string indexed projectId,
        address indexed userAddress,
        uint256[] scores
    );
    event Commented(
        string indexed contestId,
        string indexed projectId,
        address indexed userAddress,
        string message
    );
    event UserContestRewardClaimed(
        string indexed contestId,
        address indexed userAddress,
        uint256 voteClaimAmount,
        uint256 commentClaimAmount
    );
    event UserContestRewardTransfered(
        string indexed contestId,
        address indexed userAddress,
        uint256 voteTransferAmount,
        uint256 commentTransferAmount
    );
    event ScoreMinUpdated(uint256 scoreMin);
    event ScoreMaxUpdated(uint256 scoreMax);
    event CombineScoreMinUpdated(uint256 combineScoreMin);
    event CombineScoreMaxUpdated(uint256 combineScoreMax);
    event ScoreTypeUpdated(uint256 levelType);
    event MaxCommentLengthUpdated(uint256 maxCommentLen);
    event RoleTypeUpdated(uint256 roleType);
    event IsWithdrawDelayUpdated(bool isWithdrawDelay);
    event MultiplierAddressUpdated(address multiplierAddress);
    event BalanceVaultAddressUpdated(address balanceVaultAddress);
    event StakingLevelAddressUpdated(address stakingLevelAddress);

    /**
     * @dev Setup interface address, setup role for deployer and set default voting value.
     * @param _balanceVaultAddress - Contract balance vault address.
     * @param _multiplierAddress - Contract voting multiplier address.
     * @param _stakingLevelAddress - Contract staking level address.
     */
    constructor(
        address _balanceVaultAddress,
        address _multiplierAddress,
        address _stakingLevelAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);

        setBalanceVaultAddress(_balanceVaultAddress);
        setMultiplierAddress(_multiplierAddress);
        setStakingLevelAddress(_stakingLevelAddress);

        setScoreMin(1);
        setScoreMax(8);
        setCombineScoreMin(8);
        setCombineScoreMax(60);
        setScoreType(8);
        setMaxCommentLength(1000);
        setRoleType(3);
        setIsWithdrawDelay(true);
        votingMultiplier.setLevelType(stakingLevel.getStakeLevelRangeSize());
    }

    /**
     * @dev Allow when user registered (has userId).
     */
    modifier userExist(address _userAddress) {
        require(
            userIdByAddress[_userAddress] != 0,
            "[Voting.userExist] User not registered"
        );
        _;
    }

    /**
     * @dev Allow when user is valid (not banned).
     */
    modifier userValid(address _userAddress) {
        require(
            userIdByAddress[_userAddress] != 0 &&
                !userByUserId[userIdByAddress[_userAddress]].banned,
            "[Voting.userValid] Invalid user"
        );
        _;
    }

    /**
     * @dev Allow when user role valid.
     */
    modifier roleValid(uint256 _role) {
        require(
            (_role > 0 && _role <= roleType),
            "[Voting.roleValid] Invalid user role"
        );
        _;
    }

    /**
     * @dev Allow before contest started.
     */
    modifier beforeContestStarted(string calldata _contestId) {
        require(
            block.timestamp < contestByContestId[_contestId].startDate,
            "[Voting.beforeContestStarted] Contest already started"
        );
        _;
    }

    /**
     * @dev Allow after contest ended.
     */
    modifier afterContestEnded(string calldata _contestId) {
        require(
            block.timestamp >= contestByContestId[_contestId].endDate,
            "[Voting.afterContestEnded] Contest not ended yet"
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
        revert("[Voting] Revert receive function");
    }

    fallback() external payable {
        revert("[Voting] Revert fallback function");
    }

    /**
     * @dev Set voting in to pause state and unpause state.
     */
    function pauseVoting() external onlyOwner {
        _pause();
    }

    function unpauseVoting() external onlyOwner {
        _unpause();
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
    function setBalanceVaultAddress(address _balanceVaultAddress)
        public
        onlyOwner
    {
        balanceVault = IBalanceVaultV2(_balanceVaultAddress);
        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    /**
     * @dev Set new address for staking level using specify address.
     * @param _stakingLevelAddress - New address of staking level.
     */
    function setStakingLevelAddress(address _stakingLevelAddress)
        public
        onlyOwner
    {
        stakingLevel = IStakingLevel(_stakingLevelAddress);
        emit StakingLevelAddressUpdated(_stakingLevelAddress);
    }

    /**
     * @dev Update voting minimum score per type.
     * @param _scoreMin - Score min.
     */
    function setScoreMin(uint256 _scoreMin) public onlyOwner {
        scoreMin = _scoreMin;

        emit ScoreMinUpdated(_scoreMin);
    }

    /**
     * @dev Update voting maximum score per type.
     * @param _scoreMax - Score max.
     */
    function setScoreMax(uint256 _scoreMax) public onlyOwner {
        scoreMax = _scoreMax;

        emit ScoreMaxUpdated(_scoreMax);
    }

    /**
     * @dev Update voting combine score minimum.
     * @param _combineScoreMin - Combine score min.
     */
    function setCombineScoreMin(uint256 _combineScoreMin) public onlyOwner {
        combineScoreMin = _combineScoreMin;

        emit CombineScoreMinUpdated(_combineScoreMin);
    }

    /**
     * @dev Update voting combine score maximum.
     * @param _combineScoreMax - Combine score max.
     */
    function setCombineScoreMax(uint256 _combineScoreMax) public onlyOwner {
        combineScoreMax = _combineScoreMax;

        emit CombineScoreMaxUpdated(_combineScoreMax);
    }

    /**
     * @dev Update score type on voting and multiplier.
     * @param _scoreType - role type.
     */
    function setScoreType(uint256 _scoreType) public onlyOwner {
        votingMultiplier.setScoreType(_scoreType);
        scoreType = _scoreType;

        emit ScoreTypeUpdated(_scoreType);
    }

    /**
     * @dev Update role type on voting and multiplier.
     * @param _roleType - role type.
     */
    function setRoleType(uint256 _roleType) public onlyOwner {
        votingMultiplier.setRoleType(_roleType);
        roleType = _roleType;

        emit RoleTypeUpdated(_roleType);
    }

    /**
     * @dev Update maximum comment length limit.
     * @param _maxCommentLen - Maximum comment length.
     */
    function setMaxCommentLength(uint256 _maxCommentLen) public onlyOwner {
        maxCommentLen = _maxCommentLen;

        emit MaxCommentLengthUpdated(_maxCommentLen);
    }

    /**
     * @dev Update withdraw delay status to enable when user vote/comment.
     * @param _isWithdrawDelay - Wihdraw delay boolean.
     */
    function setIsWithdrawDelay(bool _isWithdrawDelay) public onlyOwner {
        isWithdrawDelay = _isWithdrawDelay;

        emit IsWithdrawDelayUpdated(_isWithdrawDelay);
    }

    /**
     * @dev Register single user for BE register UPO.
     * @param _userAddress - User address.
     * @param _role - User role.
     */
    function addUser(address _userAddress, uint256 _role)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        _registerUser(_userAddress, _role, false);
    }

    /**
     * @dev Register multiple user for contract setup.
     * @param _users - User struct array.
     */
    function batchAddUser(User[] calldata _users)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        for (uint256 i = 0; i < _users.length; i++) {
            _registerUser(
                _users[i].userAddress,
                _users[i].role,
                _users[i].verified
            );
        }
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
        User storage user = userByUserId[userIdByAddress[_userAddress]];
        require(!user.verified, "[Voting.verifyUser] User already verified");
        user.verified = true;

        emit UserVerified(_userAddress);
    }

    /**
     * @dev Update user role for WORKER.
     * @param _userAddress - User address.
     * @param _role - User role.
     */
    function adminUpdateUserRole(address _userAddress, uint256 _role)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        _updateUserRole(_userAddress, _role);
    }

    /**
     * @dev Ban specify user.
     * @param _userAddress - User address.
     */
    function banUser(address _userAddress)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        _updateUserBanStatus(_userAddress, true);
    }

    /**
     * @dev Unban specify user.
     * @param _userAddress - User address.
     */
    function unbanUser(address _userAddress)
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        _updateUserBanStatus(_userAddress, false);
    }

    /**
     * @dev Set new address for existing user.
     * @param _userAddress - Current user address.
     * @param _newUserAddress - New user address.
     * @notice Incase of emergency.
     */
    function setUserNewAddress(address _userAddress, address _newUserAddress)
        external
        whenNotPaused
        onlyRole(WORKER)
        userExist(_userAddress)
    {
        require(
            userIdByAddress[_newUserAddress] == 0,
            "[Voting.setUserNewAddress] New address cannot be registered address"
        );
        uint256 userId = userIdByAddress[_userAddress];
        delete userIdByAddress[_userAddress];
        userIdByAddress[_newUserAddress] = userId;
        userByUserId[userId].userAddress = _newUserAddress;

        emit UserAddressUpdated(_userAddress, _newUserAddress);
    }

    /**
     * @dev Initilize new contest.
     * @param _contestId - New contest id.
     * @param _startDate - Start date time stamp.
     * @param _endDate - End date time stamp.
     */
    function initContest(
        string calldata _contestId,
        uint256 _startDate,
        uint256 _endDate
    )
        external
        whenNotPaused
        onlyRole(WORKER)
        dateRangeValid(_startDate, _endDate)
    {
        require(
            bytes(_contestId).length > 0,
            "[Voting.initContest] Contest id length invalid"
        );
        Contest storage contest = contestByContestId[_contestId];
        require(
            bytes(contest.contestId).length == 0,
            "[Voting.initContest] Contest already initialized"
        );

        contest.contestId = _contestId;
        contest.startDate = _startDate;
        contest.endDate = _endDate;
        contest.contestScoreType = scoreType;

        emit ContestInited(_contestId, _startDate, _endDate);
    }

    /**
     * @dev Adjust existing contest with no entry.
     * @param _contestId - Existing contest id.
     * @param _startDate - New start date time stamp.
     * @param _endDate - New end date time stamp.
     */
    function adjustContest(
        string calldata _contestId,
        uint256 _startDate,
        uint256 _endDate
    )
        external
        whenNotPaused
        onlyRole(WORKER)
    {
        Contest storage contest = contestByContestId[_contestId];
        // require(
        //     contest.entryCount == 0,
        //     "[Voting.adjustContest] Cannot adjust contest with entry"
        // );
        contest.startDate = _startDate;
        contest.endDate = _endDate;

        emit ContestAdjusted(_contestId, _startDate, _endDate);
    }

    /**
     * @dev Add entry to existing contest using project id.
     * Add entry reward to contest reward.
     * @param _userAddress - User address.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     * @param _entryVoteReward - Entry vote reward.
     * @param _entryCommentReward - Entry comment reward.
     */
    function addContestEntry(
        string calldata _contestId,
        string calldata _projectId,
        address _userAddress,
        uint256 _entryVoteReward,
        uint256 _entryCommentReward
    ) external whenNotPaused onlyRole(WORKER) {
        Contest storage contest = contestByContestId[_contestId];
        require(
            bytes(contest.contestId).length > 0,
            "[Voting.addContestEntry] Contest not initialized yet"
        );
        require(
            contest.entryIdByProjectId[_projectId] == 0,
            "[Voting.addContestEntry] Entry already exist for specifiy project id"
        );
        contest.totalVoteReward += _entryVoteReward;
        contest.totalCommentReward += _entryCommentReward;
        contest.entryCount++;

        uint256 entryId = contest.entryCount;
        contest.entryIdByProjectId[_projectId] = entryId;
        Entry storage entry = contest.entryByEntryId[entryId];
        entry.projectId = _projectId;
        entry.voteReward = _entryVoteReward;
        entry.commentReward = _entryCommentReward;
        entry.totalScores = new uint256[](contest.contestScoreType);
        entry.totalScoresWeights = new uint256[](contest.contestScoreType);

        balanceVault.payWithUpo(
            _userAddress,
            _entryVoteReward + _entryCommentReward
        );

        emit ContestEntryAdded(
            _contestId,
            _projectId,
            _userAddress,
            _entryVoteReward,
            _entryCommentReward
        );
    }

    /**
     * @dev Update user role.
     * @param _role - User role.
     */
    function updateUserRole(uint256 _role) external whenNotPaused {
        _updateUserRole(msg.sender, _role);
    }

    /**
     * @dev Vote for contest entry.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     * @param _scores - Scores array for each type.
     */
    function voteForContestEntry(
        string calldata _contestId,
        string calldata _projectId,
        uint256[] calldata _scores
    ) external whenNotPaused userValid(msg.sender) {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[
            contest.entryIdByProjectId[_projectId]
        ];
        require(
            (block.timestamp >= contest.startDate &&
                block.timestamp < contest.endDate),
            "[Voting.inContestPeriod] Not in contest period"
        );
        require(
            bytes(entry.projectId).length != 0,
            "[Voting.contestEntryExist] Contest entry not exist for specifiy project id"
        );
        _updateVoteData(entry, msg.sender, _scores, contest.contestScoreType);
        if (isWithdrawDelay) {
            stakingLevel.setWithdrawDelay(msg.sender, contest.endDate);
        }

        emit Voted(_contestId, _projectId, msg.sender, _scores);
    }

    /**
     * @dev Comment for contest entry.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     * @param _message - Comment message.
     */
    function commentForContestEntry(
        string calldata _contestId,
        string calldata _projectId,
        string calldata _message
    ) external whenNotPaused userValid(msg.sender) {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[
            contest.entryIdByProjectId[_projectId]
        ];
        require(
            (block.timestamp >= contest.startDate &&
                block.timestamp < contest.endDate),
            "[Voting.inContestPeriod] Not in contest period"
        );
        require(
            bytes(entry.projectId).length != 0,
            "[Voting.contestEntryExist] Contest entry not exist for specifiy project id"
        );
        _updateCommentData(entry, msg.sender, _message);
        if (isWithdrawDelay) {
            stakingLevel.setWithdrawDelay(msg.sender, contest.endDate);
        }

        emit Commented(_contestId, _projectId, msg.sender, _message);
    }

    /**
     * @dev Claim reward of all entry in contest.
     * @param _contestId - Contest id.
     */
    function claimUserContestReward(string calldata _contestId)
        external
        whenNotPaused
        afterContestEnded(_contestId)
        userExist(msg.sender)
    {
        (
            uint256 contestUserVoteReward,
            uint256 contestUserCommentReward,
            bool contestUserClaimed,

        ) = getContestUserReward(_contestId, msg.sender);
        require(
            !contestUserClaimed,
            "[Voting.claimUserContestReward] User already claim contest reward"
        );
        require(
            contestUserVoteReward + contestUserCommentReward > 0,
            "[Voting.claimUserContestReward] No claimable contest reward"
        );
        Contest storage contest = contestByContestId[_contestId];
        contest.totalClaimedVoteReward += contestUserVoteReward;
        contest.totalClaimedCommentReward += contestUserCommentReward;
        contest.contestUserClaimByUserId[userIdByAddress[msg.sender]] = true;
        balanceVault.transferUpoToAddress(
            msg.sender,
            contestUserVoteReward + contestUserCommentReward
        );

        emit UserContestRewardClaimed(
            _contestId,
            msg.sender,
            contestUserVoteReward,
            contestUserCommentReward
        );
    }

    /**
     * @dev Transfer reward of all entry in contest to user.
     * @param _contestId - Contest id.
     * @notice Incase of emergency.
     */
    function transferUserContestReward(
        string calldata _contestId,
        address _userAddress,
        uint256 _contestUserVoteReward,
        uint256 _contestUserCommentReward
    ) external afterContestEnded(_contestId) userExist(_userAddress) {
        Contest storage contest = contestByContestId[_contestId];
        require(
            !contest.contestUserClaimByUserId[userIdByAddress[_userAddress]],
            "[Voting.transferUserContestReward] User already claim contest reward"
        );
        contest.totalClaimedVoteReward += _contestUserVoteReward;
        contest.totalClaimedCommentReward += _contestUserCommentReward;
        contest.contestUserClaimByUserId[userIdByAddress[_userAddress]] = true;
        balanceVault.transferUpoToAddress(
            _userAddress,
            _contestUserVoteReward + _contestUserCommentReward
        );

        emit UserContestRewardTransfered(
            _contestId,
            _userAddress,
            _contestUserVoteReward,
            _contestUserCommentReward
        );
    }

    /**
     * @dev Get infomation of voting user.
     * @param _userAddress - user address.
     */
    function getUserInfo(address _userAddress)
        external
        view
        returns (User memory)
    {
        return userByUserId[userIdByAddress[_userAddress]];
    }

    /**
     * @dev Get infomation in contest level.
     * @param _contestId - Contest id.
     */
    function getContestInfo(string calldata _contestId)
        external
        view
        returns (
            string memory contestId,
            uint256 startDate,
            uint256 endDate,
            uint256 contestScoreType,
            uint256 totalVoteReward,
            uint256 totalClaimedVoteReward,
            uint256 totalCommentReward,
            uint256 totalClaimedCommentReward,
            string[] memory entryList
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        contestId = contest.contestId;
        startDate = contest.startDate;
        endDate = contest.endDate;
        contestScoreType = contest.contestScoreType;
        totalVoteReward = contest.totalVoteReward;
        totalClaimedVoteReward = contest.totalClaimedVoteReward;
        totalCommentReward = contest.totalCommentReward;
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
     * @dev Get vote infomation in entry level.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     */
    function getEntryInfo(
        string calldata _contestId,
        string calldata _projectId
    )
        external
        view
        returns (
            string memory projectId,
            uint256[] memory totalScores,
            uint256[] memory totalScoresWeights,
            uint256 voteCount,
            uint256 voteReward,
            uint256 voteRewardWeights,
            uint256 commentCount,
            uint256 commentReward,
            uint256 commentRewardWeights
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[
            contest.entryIdByProjectId[_projectId]
        ];
        projectId = entry.projectId;
        totalScores = entry.totalScores;
        totalScoresWeights = entry.totalScoresWeights;
        voteCount = entry.voteCount;
        voteReward = entry.voteReward;
        voteRewardWeights = entry.voteRewardWeights;
        commentCount = entry.commentCount;
        commentReward = entry.commentReward;
        commentRewardWeights = entry.commentRewardWeights;
    }

    /**
     * @dev Get infomation in vote level.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     * @param _userAddress - User address.
     */
    function getVoteInfo(
        string calldata _contestId,
        string calldata _projectId,
        address _userAddress
    ) external view returns (Vote memory) {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[
            contest.entryIdByProjectId[_projectId]
        ];
        return entry.voteByUserId[userIdByAddress[_userAddress]];
    }

    /**
     * @dev Get infomation in comment level.
     * @param _contestId - Contest id.
     * @param _projectId - Project id of entry.
     * @param _userAddress - User address.
     */
    function getCommentInfo(
        string calldata _contestId,
        string calldata _projectId,
        address _userAddress
    ) external view returns (Comment memory) {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[
            contest.entryIdByProjectId[_projectId]
        ];
        return entry.commentByUserId[userIdByAddress[_userAddress]];
    }

    /**
     * @dev Get infomation user claim status of contest.
     * @param _contestId - Contest id.
     * @param _userAddress - user address.
     */
    function getContestUserClaimStatus(
        string calldata _contestId,
        address _userAddress
    ) external view returns (bool) {
        return
            contestByContestId[_contestId].contestUserClaimByUserId[
                userIdByAddress[_userAddress]
            ];
    }

    /**
     * @dev Get user contest reward data.
     * @param _contestId - Contest id.
     * @param _userAddress - User address.
     */
    function getContestUserReward(
        string calldata _contestId,
        address _userAddress
    )
        public
        view
        returns (
            uint256 contestUserVoteReward,
            uint256 contestUserCommentReward,
            bool contestUserClaimed,
            UserEntryReward[] memory userEntryRewardArr
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        userEntryRewardArr = new UserEntryReward[](contest.entryCount);
        contestUserClaimed = contest.contestUserClaimByUserId[
            userIdByAddress[_userAddress]
        ];
        uint256 userId = userIdByAddress[_userAddress];
        for (uint256 i = 0; i < contest.entryCount; i++) {
            Entry storage entry = contest.entryByEntryId[i + 1];
            uint256 entryVoteReward = calculateContestEntryReward(
                entry.voteReward,
                entry.voteRewardWeights,
                entry.voteByUserId[userId].rewardWeights
            );
            uint256 entryCommentReward = calculateContestEntryReward(
                entry.commentReward,
                entry.commentRewardWeights,
                entry.commentByUserId[userId].rewardWeights
            );

            contestUserVoteReward += entryVoteReward;
            contestUserCommentReward += entryCommentReward;
            userEntryRewardArr[i] = UserEntryReward(
                entry.projectId,
                entryVoteReward,
                entryCommentReward
            );
        }
    }

    /**
     * @dev Calculate reward from weight of vote/comment stored.
     * Formula: entryReward = rewardPerWeight * userWeights.
     * @param _entryReward - Entry total reward.
     * @param _entryRewardWeights - Entry toal reward weights.
     * @param _userRewardWeights - User reward weights.
     */
    function calculateContestEntryReward(
        uint256 _entryReward,
        uint256 _entryRewardWeights,
        uint256 _userRewardWeights
    ) public pure returns (uint256) {
        return
            _entryRewardWeights != 0
                ? (_entryReward * _userRewardWeights) / _entryRewardWeights
                : 0;
    }

    /**
     * @dev Register user using address and role.
     * @param _userAddress - User address.
     * @param _role - User role.
     */
    function _registerUser(
        address _userAddress,
        uint256 _role,
        bool _verified
    ) internal roleValid(_role) {
        require(
            userIdByAddress[_userAddress] == 0,
            "[Voting._registerUser] User already exist"
        );
        latestUserId++;
        userIdByAddress[_userAddress] = latestUserId;
        userByUserId[latestUserId] = User(
            _userAddress,
            _role,
            _verified,
            false
        );

        emit UserAdded(_userAddress, _role, _verified);
    }

    /**
     * @dev Update user role.
     * @param _role - User role.
     */
    function _updateUserRole(address _userAddress, uint256 _role)
        internal
        userExist(_userAddress)
        roleValid(_role)
    {
        userByUserId[userIdByAddress[_userAddress]].role = _role;

        emit UserRoleUpdated(_userAddress, _role);
    }

    /**
     * @dev Update user ban status.
     * @param _userAddress - User address.
     * @param _banStatus - Ban status.
     */
    function _updateUserBanStatus(address _userAddress, bool _banStatus)
        internal
        userExist(_userAddress)
    {
        userByUserId[userIdByAddress[_userAddress]].banned = _banStatus;

        emit UserBanStatusUpdated(_userAddress, _banStatus);
    }

    /**
     * @dev Return boolean whether each and sum of scores is valid.
     * @param _scores - Scores array.
     */
    function _isScoresValid(
        uint256 _contestScoreType,
        uint256[] calldata _scores
    ) internal view returns (bool) {
        if (_contestScoreType != _scores.length) {
            return false;
        } else {
            uint256 sum = 0;
            for (uint256 i = 0; i < _contestScoreType; i++) {
                uint256 score = _scores[i];
                if (score < scoreMin || score > scoreMax) {
                    return false;
                }
                sum += score;
            }
            return (sum <= combineScoreMax && sum >= combineScoreMin);
        }
    }

    /**
     * @dev Update vote for entry and vote.
     * @param _entry - Entry storage.
     * @param _userAddress - User address.
     * @param _scores - Scores array.
     * @notice Seperate from main function to prevent stack too deep.
     */
    function _updateVoteData(
        Entry storage _entry,
        address _userAddress,
        uint256[] calldata _scores,
        uint256 _contestScoreType
    ) internal {
        require(
            _isScoresValid(_contestScoreType, _scores),
            "[Voting.voteForContestEntry] Invalid scores array"
        );
        uint256 userId = userIdByAddress[_userAddress];
        Vote storage vote = _entry.voteByUserId[userId];
        require(
            vote.voteId == 0,
            "[Voting.voteForContestEntry] User already voted"
        );

        User memory user = userByUserId[userId];
        uint256 userLevel = stakingLevel.getUserStakeLevel(_userAddress);
        (bool isScoreValid, uint256[] memory scoresMult) = votingMultiplier
            .getScoreMultiplier(user.verified, user.role, userLevel);
        (bool isRewardValid, uint256 voteRewardWeight, ) = votingMultiplier
            .getRewardMultiplier(user.verified, user.role, userLevel);
        require(
            isScoreValid && isRewardValid,
            "[Voting.voteForContestEntry] Multiplier not valid"
        );

        // Update Entry Data
        for (uint256 i = 0; i < _entry.totalScores.length; i++) {
            _entry.totalScores[i] += (_scores[i] * scoresMult[i]);
            _entry.totalScoresWeights[i] += scoresMult[i];
        }
        _entry.voteCount++;
        _entry.voteRewardWeights += voteRewardWeight;

        // // Update Vote data
        vote.voteId = _entry.voteCount;
        vote.level = userLevel;
        vote.role = user.role;
        vote.verified = user.verified;
        vote.scores = _scores;
        vote.time = block.timestamp;
        vote.rewardWeights = voteRewardWeight;
    }

    /**
     * @dev Update comment for entry and comment.
     * @param _entry - Entry storage.
     * @param _userAddress - User address.
     * @param _message - Scores array.
     * @notice Seperate from main function to prevent stack too deep.
     */
    function _updateCommentData(
        Entry storage _entry,
        address _userAddress,
        string calldata _message
    ) internal {
        require(
            bytes(_message).length > 0 &&
                bytes(_message).length <= maxCommentLen,
            "[Voting.commentForContestEntry] Invalid message"
        );
        uint256 userId = userIdByAddress[_userAddress];
        Comment storage comment = _entry.commentByUserId[userId];
        require(
            comment.commentId == 0,
            "[Voting.commentForContestEntry] User already commented"
        );

        User memory user = userByUserId[userId];
        uint256 userLevel = stakingLevel.getUserStakeLevel(_userAddress);
        (bool isRewardValid, , uint256 commentRewardWeight) = votingMultiplier
            .getRewardMultiplier(user.verified, user.role, userLevel);
        require(
            isRewardValid,
            "[Voting.commentForContestEntry] Multiplier not valid"
        );

        // Update Entry Data
        _entry.commentCount++;
        _entry.commentRewardWeights += commentRewardWeight;

        // // Update Comment data
        comment.commentId = _entry.commentCount;
        comment.level = userLevel;
        comment.role = user.role;
        comment.verified = user.verified;
        comment.message = _message;
        comment.time = block.timestamp;
        comment.rewardWeights = commentRewardWeight;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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

interface IBalanceVaultV2 {
    // UPO
    function getBalance(address _userAddress) external view returns (uint256);
    function depositUpo(uint256 _upoAmount) external;
    function withdrawUpo(uint256 _upoAmount) external;
    function increaseBalance(address _userAddress, uint256 _upoAmount) external;
    function decreaseBalance(address _userAddress, uint256 _upoAmount) external;
    function payWithUpo(address _userAddress, uint256 _upoAmount) external;
    function transferUpoToAddress(address _userAddress, uint256 _upoAmount) external;

    // Token
    function getTokenBalance(address _userAddress, address _tokenAddress) external view returns (uint256);
    function depositToken(address _tokenAddress, uint256 _tokenAmount) external;
    function withdrawToken(address _tokenAddress, uint256 _tokenAmount) external;
    function increaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function decreaseTokenBalance(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function payWithToken(address _userAddress, address _tokenAddress, uint256 _upoAmount) external;
    function transferTokenToAddress(address _userAddress, address _tokenAddress, uint256 _tokenAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IStakingLevel {
    function addPoolReward(address _userAddress, uint256 _upoAmount) external;
    function setWithdrawDelay(address _userAddress, uint256 _endDate) external;
    function getUserStakeLevel(address _userAddress) external view returns (uint256);
    function getStakeLevelRangeSize() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVotingMultiplier{
    function setScoreType(uint256 _scoreType) external;
    function setRoleType(uint256 _roleType) external;
    function setLevelType(uint256 _levelType) external;
    function getScoreMultiplier(bool _verified, uint256 _role, uint256 _level) external view returns (bool isValid, uint256[] memory value);
    function getRewardMultiplier(bool _verified, uint256 _role, uint256 _level) external view returns (bool isValid, uint256 vote, uint256 comment);
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