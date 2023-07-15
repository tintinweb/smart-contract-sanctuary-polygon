// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IQuizz.sol";
import "./IQuizMaster.sol";
import "./QuizMasterStorage.sol";

contract QuizMaster is QuizMasterStorage {
    constructor() QuizMasterStorage() {}

    function getAddressById(uint256 id) public view returns (address) {
        return quizzes_[id].quizAddress;
    }

    function isQuizMaster() public view returns (bool) {
        if(quizMasters_[msg.sender].canPost)
            return true;
        return false;
    }
    // QuizMaster Functions

    function addClue(
        uint256 quizId,
        bytes32 answer,
        uint32 points,
        string memory hint
    ) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._addClue(answer, points, hint);
    }

    function openEntries(uint256 quizId) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._openEntries();
    }

    function setFee(uint256 quizId, uint256 fee) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._setFee(fee);
    }

    function setLimit(uint256 quizId, int limit) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._setLimit(limit);
    }

    function startQuiz(uint256 quizId, uint256 pot)
        external
        isQuizOwner(quizId)
    {
        IQuizz(address(quizzes_[quizId].quizAddress))._startQuiz(pot);
    }

    function endQuiz(uint256 quizId) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._endQuiz();
    }

    function cancelQuiz(uint256 quizId) external isQuizOwner(quizId) {
        IQuizz(address(quizzes_[quizId].quizAddress))._cancelQuiz();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQuizz {
    enum QuizState {
        CREATED,
        AVAILABLE,
        STARTED,
        ENDED,
        CANCELLED,
        STALEMATE
    }

    struct Clue {
        uint id;
        uint solvingTeam;
        uint32 points;
        address solvingMember;
        bytes32 answer;
        bool isSolved;
    }

    struct Team {
        uint id;
        uint32 score;
        string name;
        address[] members;
        address captain;
        bool active;
    }

    event ClueCreated(uint id, uint points, bytes32 answer, string hint);
    event StateChange(QuizState state, uint amount);
    event Withdraw(uint teamId);
    event Claim(uint teamId, uint32 score, uint teamWinnings, uint winningPerMember);
    event TeamEntry(uint id, string name, address[] members, address captain);
    event ChickenOut(uint id, string name);
    event SolveAttempt(
        uint clueId,
        uint teamId,
        address member,
        string attempt
    );
    event ClueSolved(
        uint clueId,
        uint teamId,
        address member,
        uint points,
        string answer
    );
    event FeeChange(
        uint256 fee
    );
    event LimitChange(
        int limit
    );

    // View functions
    function teamPoints(uint _teamId) external view returns (uint);

    function name() external view returns (string memory);

    function teamCount() external view returns (uint);

    function clueCount() external view returns (uint);

    function state() external view returns (QuizState);

    function teamLimit() external view returns (int);

    function teamMembers(uint teamId) external view returns (address[] memory);

    function assetAddress() external view returns (address);

    function fee() external view returns (uint256);

    function winningTeams() external view returns (uint256, uint256, uint256);

    // Team functions
    function addTeam(string memory name, address[] memory memberAddressList)
        external
        payable;

    function chickenOut() external;

    function claim() external;

    function withdraw() external;

    function submitAnswer(
        uint teamId,
        uint clueId,
        string memory answer
    ) external returns (bool);

    // State Management
    function _setFee(uint256 points) external;
    function _setLimit(int points) external;

    function _addClue(bytes32 answer, uint32 points, string memory hint) external;

    function _openEntries() external;

    function _startQuiz(uint256 pot) external;

    function _endQuiz() external;

    function _cancelQuiz() external;

    function _adminDrain(address to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQuizMaster {
    // State Management
    function addClue(
        uint256 quizId,
        bytes32 answer,
        uint points,
        string memory hint
    ) external;

    function openEntries(uint256 quizId) external;

    function setFee(uint256 quizId, uint256 fee) external;

    function setLimit(uint256 quizId, int limit) external;

    function startQuiz(uint256 quizId, uint256 pot) external;

    function endQuiz(uint256 quizId) external;

    function cancelQuiz(uint256 quizId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Quizz.sol";
import "./IQuizMasterStorage.sol";

contract QuizMasterStorage is IQuizMasterStorage, Ownable {
    mapping(uint256 => Quiz) internal quizzes_;
    mapping(address => QuizMaster) internal quizMasters_;

    uint256 private _masterCount;
    uint256 private _quizCount;

    modifier onlyQuizMaster() {
        require(quizMasters_[msg.sender].canPost, "Not a QuizMaster!");
        _;
    }

    modifier onlyOmni() {
        require(quizMasters_[msg.sender].isOmni, "Not an Omni-QuizMaster!");
        _;
    }

    modifier isQuizOwner(uint256 quizId) {
        require(quizzes_[quizId].quizMaster == msg.sender, "Not Quiz Owner!");
        _;
    }

    constructor() Ownable() {
        _masterCount = 1;
        _quizCount = 0;
        quizMasters_[msg.sender].name = "Deployer";
        quizMasters_[msg.sender].canPost = true;
        quizMasters_[msg.sender].isOmni = true;
        emit QuizMasterCreated("Deployer", msg.sender, address(0), true);
    }

    

    // Only Omni Functions
    function addQuizMaster(
        address quizMaster,
        string calldata name,
        bool isOmni
    ) public onlyOmni {
        _masterCount++;
        quizMasters_[quizMaster].canPost = true;
        quizMasters_[quizMaster].name = name;
        quizMasters_[quizMaster].isOmni = isOmni;
        emit QuizMasterCreated(name, quizMaster, msg.sender, isOmni);
    }

    function deployQuiz(
        string memory name,
        string memory description,
        uint256 fee,
        int teamLimit,
        address assetAddress
    ) public onlyQuizMaster returns (address) {
        Quizz quiz = (
            new Quizz(_quizCount, name, fee, teamLimit, assetAddress)
        );
        quizzes_[_quizCount] = (Quiz(name, address(quiz), msg.sender));
        _quizCount++;
        emit QuizCreated(
            _quizCount - 1,
            teamLimit,
            fee,
            address(quiz),
            name,
            description,
            msg.sender,
            assetAddress
        );
        return address(quiz);
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IQuizz.sol";


contract Quizz is IQuizz, Ownable {
    uint private _id;
    string private _name;
    int private _teamLimit;
    uint256 private _fee;
    uint256 private _pot;
    QuizState private _state;

    IERC20 private asset; //Make this any ERC20

    uint private _teamCount;
    uint private _activeTeamCount;
    Team[] private teams;

    uint private _clueCount;
    Clue[] private clues;

    uint32[] private topTeamsScores;

    mapping(address => uint256) deposits;

    mapping(uint256 => mapping(address => bool)) clueAttempts;
    mapping(address => uint256) captains;
    mapping(address => uint256) participants;

    modifier available() {
        require(_state == QuizState.AVAILABLE, "Quiz is not active");
        _;
    }

    modifier created() {
        require(
            _state == QuizState.CREATED || _state == QuizState.AVAILABLE,
            "Quiz is not available for new clues"
        );
        _;
    }

    modifier started() {
        require(_state == QuizState.STARTED, "Quiz has not started");
        _;
    }

    modifier notStarted() {
        require(_state != QuizState.STARTED, "Quiz has started");
        _;
    }

    modifier notEnded() {
        require(_state != QuizState.ENDED, "Quiz has ended");
        _;
    }

    modifier ended() {
        require(_state == QuizState.ENDED, "Quiz has not ended");
        _;
    }

    modifier isTeamUnique(address[] memory memberList) {
        require(unique(memberList) == true, "Team is not Unique");
        _;
    }

    modifier isCaptainOnList(address[] memory memberList) {
        require(
            contains(memberList, msg.sender) == false,
            "Team list cannot contain Captain"
        );
        _;
    }

    modifier canWithdraw() {
        require(
            _state == QuizState.CANCELLED || _state == QuizState.STALEMATE,
            "Can only withdraw if cancelled"
        );
        _;
    }

    modifier onlyCaptain() {
        require(
            teams[captains[msg.sender]].captain == msg.sender,
            "Not a captain!"
        );
        _;
    }

    modifier clueExists(uint clueId) {
        require(clueId <= _clueCount, "Clue does not exist!");
        _;
    }

    modifier notAttempted(uint clueId) {
        require(
            clueAttempts[clueId][msg.sender] == false,
            "You have attempted this clue!"
        );
        _;
    }

    modifier isPartOfTeam(uint teamId) {
        require(
            contains(teams[teamId].members, msg.sender) == true,
            "You are not part of this team!"
        );
        _;
    }

    modifier isTeamActive(uint teamId) {
        require(teams[teamId].active, "Team has chickened out!");
        _;
    }

    constructor(
        uint id,
        string memory name,
        uint256 fee,
        int teamLimit,
        address assetAddress
    ) Ownable() {
        require(teamLimit >= 2, "Limit cannot be less than 2");
        require(fee > 0, "Fee cannot be 0");
        _id = id;
        _name = name;
        _teamLimit = teamLimit;
        _fee = fee;
        _state = QuizState.CREATED;
        _teamCount = 0;
        _activeTeamCount = 0;
        _pot = 0;
        _clueCount = 0;
        asset = IERC20(assetAddress);
        address[] memory teamList = new address[](1);
        teamList[0] = address(0);
        topTeamsScores = new uint32[](3);
        teams.push(
            Team(_teamCount, 0, "QUIZMASTER", teamList, msg.sender, false)
        );
        _teamCount++;
    }

    // View Functions

    function teamPoints(uint _teamId) public view returns (uint) {
        uint points = 0;
        for (uint i = 0; i < clues.length; i++) {
            if (clues[i].isSolved && clues[i].solvingTeam == _teamId) {
                points += clues[i].points;
            }
        }
        return points;
    }

    function howManyWinners() public view returns (uint) {
        uint counter = 0;
        for(uint i = 0; i < _teamCount; i++) {
            if(isWinningTeam(i)) {
                counter++;
            }
        }
        return counter;
    }

    function isWinningTeam(uint teamId) public view returns (bool) {
        if(teams[teamId].score == 0 || teamId == 0 || !teams[teamId].active)
            return false;
        uint first;
        (first,,) = winningTeams();
        if(teams[teamId].score == teams[first].score)
            return true;
        return false;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function teamCount() public view returns (uint) {
        return _teamCount;
    }

    function clueCount() public view returns (uint) {
        return _clueCount;
    }

    function state() public view returns (QuizState) {
        return _state;
    }

    function teamLimit() public view returns (int) {
        return _teamLimit;
    }

    function teamMembers(uint teamId) public view returns (address[] memory) {
        return teams[teamId].members;
    }

    function assetAddress() public view returns (address) {
        return address(asset);
    }

    function fee() public view returns (uint256) {
        return _fee;
    }

    function winningTeams()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 first;
        uint256 second;
        uint256 third;

        for (uint i = 0; i < _teamCount; i++) {
            if (!teams[i].active)
                continue;
            if (topTeamsScores[0] == teams[i].score) {
                first = i;
                break;
            }
        }

        for (uint i = 0; i < _teamCount; i++) {
            if (!teams[i].active)
                continue;
            if (topTeamsScores[1] == teams[i].score && first != i) {
                second = i;
                break;
            }
        }

        for (uint i = 0; i < _teamCount; i++) {
            if (!teams[i].active)
                continue;
            if (
                topTeamsScores[2] == teams[i].score && first != i && second != i
            ) {
                third = i;
                break;
            }
        }

        return (first, second, third);
    }

    // State Changing Functions

    function addTeam(string memory name, address[] memory memberAddressList)
        external
        payable
        available
        isTeamUnique(memberAddressList)
        isCaptainOnList(memberAddressList)
    {
        require(
            uint256(memberAddressList.length + 1) <= uint256(_teamLimit),
            "Team limit exceeded"
        );
        require(memberAddressList.length > 0, "Team cannot be empty");
        for (uint j = 0; j < memberAddressList.length; j++) {
            require(
                memberAddressList[j] != address(0),
                "Address Zero cannot be used"
            );
            require(
                participants[memberAddressList[j]] == 0,
                "Team member already part of team"
            );
        }
        require(participants[msg.sender] == 0, "Captain is on a team already");
        require(
            asset.transferFrom(msg.sender, address(this), _fee),
            "Could not pay fee"
        ); //Captain Pays Fee

        _pot += _fee;
        for (uint i = 0; i < memberAddressList.length; i++) {
            participants[memberAddressList[i]] = _teamCount;
        }
        participants[msg.sender] = _teamCount;

        deposits[msg.sender] = _fee;

        teams.push(
            Team(_teamCount, 0, name, memberAddressList, msg.sender, true)
        );
        Team storage team = teams[_teamCount];
        team.members.push(msg.sender); // Adding Captain
        captains[msg.sender] = _teamCount;
        _teamCount++;
        _activeTeamCount++;

        emit TeamEntry(team.id, name, team.members, msg.sender);
    }

    function chickenOut() external notStarted onlyCaptain {
        require(captains[msg.sender] != 0, "No Team");
        require(deposits[msg.sender] != 0, "Already Removed Deposit");
        require(
            asset.transfer(msg.sender, _fee),
            "Could not remove assets"
        );
         _pot -= _fee;
        deposits[msg.sender] = 0;
        Team storage team = teams[captains[msg.sender]];
        team.active = false;
        captains[msg.sender] = 0;
        for(uint i = 0; i < team.members.length; i++){
            participants[team.members[i]] = 0;
        }
        _activeTeamCount--;
        emit ChickenOut(team.id, team.name);
    }

    function submitAnswer(
        uint teamId,
        uint clueId,
        string memory answer
    )
        external
        clueExists(clueId)
        notAttempted(clueId)
        isPartOfTeam(teamId)
        isTeamActive(teamId)
        started
        returns (bool)
    {
        require(clues[clueId].isSolved == false, "Clue has been solved!");
        clueAttempts[clueId][msg.sender] = true;
        emit SolveAttempt(clueId, teamId, msg.sender, answer);
        bytes32 answerHashed = keccak256(abi.encodePacked(answer));
        Clue storage clue = clues[clueId];
        bool isEqual = clue.answer == answerHashed;

        if (isEqual) {
            clue.isSolved = true;
            clue.solvingMember = msg.sender;
            clue.solvingTeam = teamId;
            teams[teamId].score += clue.points;
            refreshTopXOrdered(teams[teamId].score);
            emit ClueSolved(clueId, teamId, msg.sender, clue.points, answer);
            return true;
        }
        return false;
    }

    function claim() external onlyCaptain ended {
        require(teams[captains[msg.sender]].active, "Team is not active");
        require(captains[msg.sender] != 0, "No Team");
        require(deposits[msg.sender] != 0, "Already Claimed!");
        require(isWinningTeam(captains[msg.sender]), "Not a winning team");
        uint256 split = howManyWinners();

        if(asset.balanceOf(address(this)) > 0){
            uint256 teamWinnings = (_pot - (split * _fee)) / split;

            uint teamMemberLength = teams[captains[msg.sender]].members.length;
            uint captainShare = _fee +  teamWinnings/teamMemberLength;
             require(
                asset.transfer(msg.sender, captainShare),
                "Could not remove assets"
            );
            _pot -= captainShare;
            deposits[msg.sender] = 0;
            for(uint i = 0; i < teamMemberLength; i++){
                if(address(msg.sender) != address(teams[captains[msg.sender]].members[i])) {
                    require(
                        asset.transfer(address(teams[captains[msg.sender]].members[i]), teamWinnings/teamMemberLength),
                        "Could not remove assets"
                    );
                    _pot -= teamWinnings/teamMemberLength;
                }
            }

            teams[captains[msg.sender]].active = false;
            emit Claim(captains[msg.sender], teams[captains[msg.sender]].score, teamWinnings, teamWinnings/teamMemberLength);
        }  
    }

    function withdraw() external canWithdraw onlyCaptain {
        require(teams[captains[msg.sender]].active, "Team is not active");
        require(captains[msg.sender] != 0, "No Team");
        require(deposits[msg.sender] != 0, "Already Removed Deposit");
        require(
            asset.transfer(msg.sender, _fee),
            "Could not remove assets"
        );
        deposits[msg.sender] = 0;
        teams[captains[msg.sender]].active = false;

       emit Withdraw(captains[msg.sender]);
    }

    // QuizMaster Functions

    function _addClue(bytes32 answer, uint32 points, string memory hint)
        external
        onlyOwner
        created
    {
        Clue memory clue = Clue(
            _clueCount,
            0,
            points,
            address(0),
            answer,
            false
        );
        clues.push(clue);
        _clueCount++;
        emit ClueCreated(_clueCount - 1, points, answer, hint);
    }

    function _setFee(uint256 fee) external onlyOwner created {
        require(fee > 0, "Fee cannot be Zero");
        emit FeeChange(fee);
    }

    function _setLimit(int limit) external onlyOwner created {
        require(limit >= 2, "Limit cannot be less than 2");
        emit LimitChange(limit);
    }

    function _openEntries() external onlyOwner created {
        _state = QuizState.AVAILABLE;
        emit StateChange(QuizState.AVAILABLE, 0);
    }

    function _startQuiz(uint256 pot) external onlyOwner available {
        if (pot > 0) {
            require(
                asset.transferFrom(tx.origin, address(this), pot),
                "Cannot add pot"
            );
        }
        require(_clueCount != 0, "Add Clues");
        require(_activeTeamCount >= 2, "Minimum of Two Teams");
        _pot += pot;
        _state = QuizState.STARTED;

        emit StateChange(QuizState.STARTED, pot);
    }

    function _endQuiz() external onlyOwner started {
        if(topTeamsScores[0] == 0)
        {
            _state = QuizState.STALEMATE;
        } else {
            _state = QuizState.ENDED;
        }
        
        emit StateChange(_state, 0);
    }

    function _cancelQuiz() external onlyOwner notStarted {
        require(_state != QuizState.ENDED, "Quiz has ended");
        _state = QuizState.CANCELLED;
        emit StateChange(QuizState.CANCELLED, 0);
    }

    function _adminDrain(address to) external onlyOwner notStarted {
        require(
            asset.transferFrom(
                address(this),
                to,
                asset.balanceOf(address(this))
            )
        );
    }

    // Pure Functions
    function unique(address[] memory data) private pure returns (bool) {
        uint length = data.length;
        for (uint j = 0; j < length; j++) {
            if (data[j] == address(0)) return false;
            for (uint i = 0; i < length; i++) {
                if (i != j && data[j] == data[i]) {
                    return false;
                }
            }
        }
        return true;
    }

    function contains(address[] memory data, address candidate)
        internal
        pure
        returns (bool)
    {
        uint length = data.length;
        for (uint i = 0; i < length; i++) {
            if (candidate == data[i]) {
                return true;
            }
        }
        return false;
    }

    function refreshTopXOrdered(uint32 value) private {
        uint32 i = 0;
        /** get the index of the current max element **/
        for (i; i < topTeamsScores.length; i++) {
            if (topTeamsScores[i] < value) {
                break;
            }
        }
        if (topTeamsScores.length != 1) {
             /** shift the array of one position (getting rid of the last element) **/
            for (uint j = topTeamsScores.length - 1; j > i; j--) {
                topTeamsScores[j] = topTeamsScores[j - 1];
            }
        }
        /** update the new max element **/
        topTeamsScores[i] = value;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IQuizMasterStorage {
    struct Quiz {
        string name;
        address quizAddress;
        address quizMaster;
    }

    struct QuizMaster {
        string name;
        bool canPost;
        bool isOmni; //Can Add other Librarians
    }

    event QuizCreated(
        uint256 id,
        int teamLimity,
        uint256 fee,
        address quizAddress,
        string name,
        string description,
        address quizMaster,
        address assetAddress
    );
    event QuizMasterCreated(
        string name,
        address quizMasterAddress,
        address omniAddress,
        bool isOmni
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}