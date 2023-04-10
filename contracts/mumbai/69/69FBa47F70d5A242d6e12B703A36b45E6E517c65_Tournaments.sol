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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Tournaments is Ownable {

    struct User {
        address user;
        uint256 score;
    }
    
    struct Tournament {
        uint256 id;
        uint256 lobbySize;
        uint256 startTime;
        uint256 endTime;
    }

    mapping(uint => User[]) public tourParticipants;
    
    Tournament[] public tournaments;

    uint public constant tourDuration = 600; // 10 minutes
    
    event TournamentAdded(uint256 id, uint256 lobbySize);
    event UserJoinedTournament(uint256 tournamentId, address user);
    event TournamentStarted(uint256 tournamentId);

    constructor() {

    }

    function addTournament(uint256 _lobbySize) public onlyOwner {
        uint256 id = tournaments.length + 1;
        tournaments.push(Tournament(id, _lobbySize, 0, 0));
        emit TournamentAdded(id, _lobbySize);
    }

    modifier joinModi(uint256 _tournamentId) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(tournament.startTime == 0, "Tournament is already started!");
        require(tourParticipants[_tournamentId].length < tournament.lobbySize, "Tournament is full");
        User[] memory users = tourParticipants[_tournamentId];
        for (uint256 i = 0; i < users.length; i++) {
            if (users[i].user == msg.sender) {
                revert("You are already joined!");
            }
        }
        _;
    }

    modifier addScoreModi(uint256 _tournamentId) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(tournament.startTime != 0, "Tournament is not started yet!");
        require(block.timestamp < tournament.endTime, "Tournament is already ended!");
        _;
    }

    function getSingleTournament(uint256 _tournamentId) public view returns(Tournament memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        return tournament;
    }
    
    function getActiveTournaments() public view returns (Tournament[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                count++;
            }
        }
        Tournament[] memory activeTournaments= new Tournament[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (tournaments[i].startTime == 0 && tournaments[i].endTime == 0) {
                activeTournaments[index] = tournaments[i];
                index++;
            }
        }
        return activeTournaments;
    }

    function getOngoingTournaments() public view returns (Tournament[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (block.timestamp >= tournaments[i].startTime && tournaments[i].startTime != 0 && block.timestamp <= tournaments[i].endTime && tournaments[i].endTime != 0) {
                count++;
            }
        }
        Tournament[] memory onGoingTournaments= new Tournament[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < tournaments.length; i++) {
            if (block.timestamp >= tournaments[i].startTime && tournaments[i].startTime != 0 && block.timestamp <= tournaments[i].endTime && tournaments[i].endTime != 0) {
                onGoingTournaments[index] = tournaments[i];
                index++;
            }
        }
        return onGoingTournaments;
    }
    
    function joinTournament(uint256 _tournamentId) public joinModi(_tournamentId) returns(bool) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        tourParticipants[_tournamentId].push(User(msg.sender, 0));

        emit UserJoinedTournament(_tournamentId, msg.sender);
        if (tourParticipants[_tournamentId].length == tournament.lobbySize) {
            tournament.startTime = block.timestamp;
            tournament.endTime = block.timestamp + tourDuration;
            tournaments[_tournamentId - 1] = tournament;
            emit TournamentStarted(_tournamentId);
        }
        return true;
    }

    function getTourParticipants(uint _tournamentId) public view returns(User[] memory) {
        User[] memory participants = tourParticipants[_tournamentId];
        return participants;
    }

    function addScore(uint256 _tournamentId, address _user, uint _score) public addScoreModi(_tournamentId) onlyOwner returns(bool _done) {
        User[] memory user = tourParticipants[_tournamentId];
   
        for (uint256 i = 0; i < user.length; i++) {
            if (user[i].user == _user) {
                tourParticipants[_tournamentId][i].score = user[i].score + _score;
                return(true);
            }
        }
    }
    
    function getLeaderboard(uint256 _tournamentId) public view returns(User[] memory) {
        Tournament memory tournament = tournaments[_tournamentId - 1];
        require(block.timestamp > tournament.endTime && tournament.endTime != 0, "Tournament has not ended yet");
        User[] memory sortedParticipants = sortParticipants(tourParticipants[_tournamentId]);
        return sortedParticipants;
    }
    
    function sortParticipants(User[] memory _participants) private pure returns (User[] memory) {
        for (uint256 i = 0; i < _participants.length - 1; i++) {
            for (uint256 j = i + 1; j < _participants.length; j++) {
                if (_participants[i].score < _participants[j].score) {
                    uint256 tempScore = _participants[i].score;
                    address tempAddress = _participants[i].user;
                    _participants[i].score = _participants[j].score;
                    _participants[i].user = _participants[j].user;
                    _participants[i].score = tempScore;
                    _participants[j].user = tempAddress;
                }
            }
        }
        return _participants;
    }
}