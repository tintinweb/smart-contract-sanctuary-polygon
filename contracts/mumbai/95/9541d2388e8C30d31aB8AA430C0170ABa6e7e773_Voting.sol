// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/IBalanceVault.sol";
import "./utils/IVotingMultiplier.sol";

contract Voting is Ownable, AccessControl, Pausable {
    bytes32 public constant WORKER = keccak256("WORKER");
    uint256 public constant SCORE_TYPE = 8;
    uint256 public constant SCORE_MIN = 1;
    uint256 public constant SCORE_MAX = 8;
    uint256 public constant SCORE_TOTAL_MIN = 8;
    uint256 public constant SCORE_TOTAL_MAX = 60;
    address public multiplierAddress;
    address public balanceVaultAddress;
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
    }
    struct Comment {
        uint256 commentId;
        string message;
        uint256 time;
    }
    struct Entry {
        string projectId;
        uint256 voteCount;
        uint256[SCORE_TYPE] totalScores;
        uint256[SCORE_TYPE] totalWeights;
        uint256 commentCount;
        mapping(address => Vote) voteByAddress;
        mapping(address => Comment) commentByAddress;
    }
    struct Contest {
        string contestId;
        uint256 startDate;
        uint256 endDate;
        uint256 voteReward;
        uint256 rewardPerVote;
        mapping(address => uint256) userVoteReward;
        mapping(address => string[]) userVoteParticipation;
        uint256 commentReward;
        uint256 rewardPerComment;
        mapping(address => uint256) userCommentReward;
        mapping(address => string[]) userCommentParticipation;
        uint256 entryCount;
        uint256 entryFee;
        uint256 entryVoteRewardLimit;
        uint256 entryCommentRewardLimit;
        mapping(string => uint256) entryIdByProjectId;
        mapping(uint256 => Entry) entryByEntryId;
    }

    event UserAdded(address indexed userAddress);
    event UserRoleUpdated(address indexed userAddress, uint256 role);
    event UserVerified(address indexed userAddress);
    event ContestInited(string indexed contestId, uint256 startDate, uint256 endDate, uint256 entryFee, uint256 entryVoteRewardLimit, uint256 entryCommentRewardLimit);
    event ContestAdjusted(string indexed contestId, uint256 startDate, uint256 endDate, uint256 entryFee, uint256 entryVoteRewardLimit, uint256 entryCommentRewardLimit);
    event ContestEntryAdded(string indexed contestId, string indexed projectId, uint256 entryVoteReward, uint256 entryCommentReward);
    event Voted(string indexed contestId, string indexed projectId, address indexed userAddress, uint256[SCORE_TYPE] scores);
    event Commented(string indexed contestId, string indexed projectId, address indexed userAddress, string message);
    event UserContestVoteRewardAdded(string indexed contestId, address indexed userAddress, uint256 voteReward);
    event UserContestCommentRewardAdded(string indexed contestId, address indexed userAddress, uint256 commentReward);
    event UserContestRewardClaimed(string indexed contestId, address indexed userAddress, uint256 voteClaimAmount, uint256 commentClaimAmount);
    event MultiplierAddressUpdated(address newAddress);
    event BalanceVaultAddressUpdated(address newAddress);

    constructor(address _balanceVaultAddress, address _multiplierAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(WORKER, msg.sender);
        setBalanceVaultAddress(_balanceVaultAddress);
        setMultiplierAddress(_multiplierAddress);
    }

    modifier afterContestInited(string memory _contestId) {
        require(
            true, // bytes(contestByContestId[_contestId].contestId).length > 0,
            "[Voting.afterContestInited] Contest not initialized yet"
        );
        _;
    }
    modifier beforeContestStarted(string memory _contestId) {
        require(
            true, // block.timestamp < contestByContestId[_contestId].startDate,
            "[Voting.beforeContestStarted] Contest already started"
        );
        _;
    }
    modifier afterContestStarted(string memory _contestId) {
        require(
            true, // block.timestamp >= contestByContestId[_contestId].startDate,
            "[Voting.afterContestStarted] Contest not started yet"
        );
        _;
    }
    modifier beforeContestEnded(string memory _contestId) {
        require(
            true, // block.timestamp < contestByContestId[_contestId].endDate,
            "[Voting.beforeContestEnded] Contest already ended"
        );
        _;
    }
    modifier afterContestEnded(string memory _contestId) {
        require(
            true, // block.timestamp >= contestByContestId[_contestId].endDate,
            "[Voting.afterContestEnded] Contest not ended yet"
        );
        _;
    }
    modifier contestEntryExist(string memory _contestId, string memory _projectId) {
        require(
            true, // contestByContestId[_contestId].entryIdByProjectId[_projectId] != 0,
            "[Voting.contestEntryExist] Contest entry not exist for specifiy project id"
        );
        _;
    }
    modifier userExist(address _userAddress) {
        require(
            userByAddress[_userAddress].role != 0,
            "[Voting.userExist] User not registered"
        );
        _;
    }
    modifier roleValid(uint256 _role) {
        require(
            isRoleValid(_role),
            "[Voting.roleValid] Invalid user role"
        );
        _;
    }
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

    function isRoleValid(uint256 _role) internal view returns (bool) {
        IVotingMultiplier votingMultiplier = IVotingMultiplier(multiplierAddress);
        uint256 roleType = votingMultiplier.getRoleType();
        return (_role > 0 && _role <= roleType);
    }

    function addUser(address _userAddress, uint256 _role)
        external
        onlyRole(WORKER)
        roleValid(_role)
    {
        User storage user = userByAddress[_userAddress];
        require(user.role == 0, "[Voting.addUser] User already exist");
        user.role = _role;

        emit UserAdded(_userAddress);
        emit UserRoleUpdated(_userAddress, _role);
    }

    function verifyUser(address _userAddress)
        external
        onlyRole(WORKER)
        userExist(_userAddress)
    {
        User storage user = userByAddress[_userAddress];
        require(user.verified == false, "[Voting.verifyUser] User already verified");
        user.verified = true;

        emit UserVerified(_userAddress);
    }

    function updateUserRole(uint256 _role)
        external
        userExist(msg.sender)
        roleValid(_role)
    {
        User storage user = userByAddress[msg.sender];
        user.role = _role;

        emit UserRoleUpdated(msg.sender, _role);
    }

    function initContest(
        string memory _contestId,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _entryFee,
        uint256 _entryVoteRewardLimit,
        uint256 _entryCommentRewardLimit
    )
        external 
        onlyRole(WORKER)
        dateRangeValid(_startDate, _endDate)
    {
        require(bytes(_contestId).length > 0, "[Voting.initContest] Contest id length invalid");
        Contest storage contest = contestByContestId[_contestId];
        require(bytes(contest.contestId).length == 0, "[Voting.initContest] Contest already initialized");

        contest.contestId = _contestId;
        contest.startDate = _startDate;
        contest.endDate = _endDate;
        contest.entryFee = _entryFee;
        contest.entryVoteRewardLimit = _entryVoteRewardLimit;
        contest.entryCommentRewardLimit = _entryCommentRewardLimit;

        emit ContestInited(_contestId, _startDate, _endDate, _entryFee, _entryVoteRewardLimit, _entryCommentRewardLimit);
    }

    function adjustContest(
        string memory _contestId,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _entryFee,
        uint256 _entryVoteRewardLimit,
        uint256 _entryCommentRewardLimit
    )
        external
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
        contest.entryFee = _entryFee;
        contest.entryVoteRewardLimit = _entryVoteRewardLimit;
        contest.entryCommentRewardLimit = _entryCommentRewardLimit;

        emit ContestAdjusted(_contestId, _startDate, _endDate, _entryFee, _entryVoteRewardLimit, _entryCommentRewardLimit);
    }

    function addContestEntry(
        string memory _contestId,
        string memory _projectId,
        uint256 _entryVoteReward,
        uint256 _entryCommentReward
    )
        external
        onlyRole(WORKER)
        afterContestInited(_contestId)
        beforeContestStarted(_contestId)
    {
        Contest storage contest = contestByContestId[_contestId];
        require(contest.entryIdByProjectId[_projectId] == 0, "[Voting.addContestEntry] Entry already exist for specifiy project id");

        contest.entryCount++;
        uint256 entryId = contest.entryCount;
        contest.entryIdByProjectId[_projectId] = entryId;
        contest.entryByEntryId[entryId].projectId = _projectId;
        contest.voteReward += _entryVoteReward;
        contest.commentReward += _entryCommentReward;
        contest.rewardPerVote = contest.voteReward / contest.entryCount / contest.entryVoteRewardLimit;
        contest.rewardPerComment = contest.commentReward / contest.entryCount / contest.entryCommentRewardLimit;

        emit ContestEntryAdded(_contestId, _projectId, _entryVoteReward, _entryCommentReward);
    }

    function voteForContestEntry(
        string memory _contestId,
        string memory _projectId,
        address _userAddress,
        uint256[SCORE_TYPE] memory _scores
    )
        external
        onlyRole(WORKER)
        afterContestInited(_contestId)
        afterContestStarted(_contestId)
        beforeContestEnded(_contestId)
        contestEntryExist(_contestId, _projectId)
        userExist(_userAddress)
    {
        require(isScoresValid(_scores), "[Voting.voteForContestEntry] Invalid scores array");
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Vote storage vote = entry.voteByAddress[_userAddress];
        require(vote.voteId == 0, "[Voting.voteForContestEntry] User already voted");

        updateVoteData(contest, entry, vote, _userAddress, _scores);

        emit Voted(_contestId, _projectId, _userAddress, _scores);
    }

    function updateVoteData(
        Contest storage _contest,
        Entry storage _entry,
        Vote storage _vote,
        address _userAddress,
        uint256[SCORE_TYPE] memory _scores
    ) internal {
        User memory user = userByAddress[_userAddress];
        // TODO: replace by staking get level function
        uint256 level = 1;
        IVotingMultiplier votingMultiplier = IVotingMultiplier(multiplierAddress);
        uint256[SCORE_TYPE] memory multiplier = votingMultiplier.getMultiplier(user.verified, user.role, level);

        // Update Contest Data
        if (_entry.voteCount < _contest.entryVoteRewardLimit) {
            _contest.userVoteReward[_userAddress] += _contest.rewardPerVote;

            emit UserContestVoteRewardAdded(_contest.contestId, _userAddress, _contest.rewardPerVote);
        }
        _contest.userVoteParticipation[_userAddress].push(_entry.projectId);

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
    }

    function commentForContestEntry(
        string memory _contestId,
        string memory _projectId,
        address _userAddress,
        string memory _message
    )
        external
        onlyRole(WORKER)
        afterContestInited(_contestId)
        afterContestStarted(_contestId)
        beforeContestEnded(_contestId)
        contestEntryExist(_contestId, _projectId)
        userExist(_userAddress)
    {
        require(bytes(_message).length > 0, "[Voting.commentForContestEntry] Invalid message length");
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Comment storage comment = entry.commentByAddress[_userAddress];
        require(comment.commentId == 0, "[Voting.commentForContestEntry] User already commented");

        updateCommentData(contest, entry, comment, _userAddress, _message);

        emit Commented(_contestId, _projectId, _userAddress, _message);
    }

    function updateCommentData(
        Contest storage _contest,
        Entry storage _entry,
        Comment storage _comment,
        address _userAddress,
        string memory _message
    ) internal {
        // Update Contest Data
        if (_entry.commentCount < _contest.entryCommentRewardLimit) {
            _contest.userCommentReward[_userAddress] += _contest.rewardPerComment;

            emit UserContestCommentRewardAdded(_contest.contestId, _userAddress, _contest.rewardPerComment);
        }
        _contest.userCommentParticipation[_userAddress].push(_entry.projectId);

        // Update Entry Data
        _entry.commentCount++;

        // Update Vote data
        _comment.commentId = _entry.commentCount;
        _comment.time = block.timestamp;
        _comment.message = _message;
    }

    function claimUserContestReward(
        string memory _contestId,
        address _userAddress
    )
        external
        onlyRole(WORKER)
        afterContestInited(_contestId)
        afterContestEnded(_contestId)
        userExist(_userAddress)
        returns (
            uint256 voteReward,
            uint256 commentReward
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        voteReward = contest.userVoteReward[_userAddress];
        commentReward = contest.userCommentReward[_userAddress];
        uint256 claimAmount = voteReward + commentReward;
        require(claimAmount > 0, "[Voting.claimUserContestReward] No claimable reward for specify contestId and userAddress");
        IBalanceVault balanceVault = IBalanceVault(balanceVaultAddress);
        balanceVault.decreaseReward(claimAmount);
        balanceVault.increaseBalance(_userAddress, claimAmount);

        emit UserContestRewardClaimed(_contestId, _userAddress, voteReward, commentReward);
        delete contestByContestId[_contestId].userVoteReward[_userAddress];
        delete contestByContestId[_contestId].userCommentReward[_userAddress];
    }

    function getContestInfo(string memory _contestId)
        external
        view
        returns (
            uint256 startDate,
            uint256 endDate,
            uint256 voteReward,
            uint256 rewardPerVote,
            uint256 commentReward,
            uint256 rewardPerComment,
            uint256 entryFee,
            uint256 entryVoteRewardLimit,
            uint256 entryCommentRewardLimit,
            string[] memory entryList
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        startDate = contest.startDate;
        endDate = contest.endDate;
        voteReward = contest.voteReward;
        rewardPerVote = contest.rewardPerVote;
        commentReward = contest.commentReward;
        rewardPerComment = contest.rewardPerComment;
        entryFee = contest.entryFee;
        entryVoteRewardLimit = contest.entryVoteRewardLimit;
        entryCommentRewardLimit = contest.entryCommentRewardLimit;
        uint256 entryCount = contest.entryCount;
        string[] memory list = new string[](entryCount);
        for (uint256 i = 0; i < entryCount; i++) {
            uint256 entryId = i + 1;
            list[i] = contest.entryByEntryId[entryId].projectId;
        }
        entryList = list;
    }

    function getContestEntryFee(string memory _contestId) external view returns (uint256) {
        return contestByContestId[_contestId].entryFee;
    }

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
        userVoteParticipation = contest.userVoteParticipation[_userAddress];
        userCommentParticipation = contest.userCommentParticipation[_userAddress];
    }

    function getContestUserReward(
        string memory _contestId,
        address _userAddress
    ) external view
        returns (
            uint256 userVoteReward,
            uint256 userCommentReward
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        userVoteReward = contest.userVoteReward[_userAddress];
        userCommentReward = contest.userCommentReward[_userAddress];
    }

    function getEntryInfo(string memory _contestId, string memory _projectId)
        external
        view
        returns (
            string memory projectId,
            uint256 voteCount,
            uint256 commentCount,
            uint256[SCORE_TYPE] memory totalScores,
            uint256[SCORE_TYPE] memory totalWeights
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        projectId = entry.projectId;
        voteCount = entry.voteCount;
        commentCount = entry.commentCount;
        totalScores = entry.totalScores;
        totalWeights = entry.totalWeights;
    }

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
            uint256[SCORE_TYPE] memory scores
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
    }

    function getCommentInfo(
        string memory _contestId,
        string memory _projectId,
        address _userAddress
    )
        external
        view
        returns (
            uint256 commentId,
            string memory message,
            uint256 time
        )
    {
        Contest storage contest = contestByContestId[_contestId];
        Entry storage entry = contest.entryByEntryId[contest.entryIdByProjectId[_projectId]];
        Comment storage comment = entry.commentByAddress[_userAddress];
        commentId = comment.commentId;
        message = comment.message;
        time = comment.time;
    }

    function setMultiplierAddress(address _multiplierAddress) public onlyOwner {
        multiplierAddress = _multiplierAddress;
        emit MultiplierAddressUpdated(_multiplierAddress);
    }

    function setBalanceVaultAddress(address _balanceVaultAddress) public onlyOwner {
        balanceVaultAddress = _balanceVaultAddress;
        emit BalanceVaultAddressUpdated(_balanceVaultAddress);
    }

    function pauseVoting() external onlyOwner {
        _pause();
    }

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
    function getMultiplier(bool _verified, uint256 _role, uint256 _level) external view returns (uint256[8] memory);
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