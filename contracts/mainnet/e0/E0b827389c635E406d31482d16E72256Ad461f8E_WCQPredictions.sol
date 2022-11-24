// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract WCQPredictions is Ownable {
    //  CONSTANTS
    uint32 matchDuration = 6300;
    uint8 totalMatches = 64;
    uint256 cost = 25 ether;

    //  VARIABLES
    address[] public participants;
    uint256 public Amount;
    bool ownerWithdrew;

    //  STRUCTS
    struct Match {
        uint8 teamA;
        uint8 teamB;
        uint8 AScore;
        uint8 BScore;
        bool ended;
        uint8 winner;
        uint32 startTimestamp;
    }
    struct Prediction {
        uint8 AScore;
        uint8 BScore;
        uint8 winner;
        bool filled;
    }
    struct Participant {
        address account;
        uint256 score;
        uint256 amount;
    }
    struct Winner {
        address account;
        uint256 amount;
        bool claimed;
    }
    //  MAPPINGS
    //      matchId> match
    mapping(uint8 => Match) matches;
    //      particip.>       matchId> Prediction
    mapping(address => mapping(uint8 => Prediction)) predictions;
    //      particip.> score
    mapping(address => uint256) scores;
    //      address  > is participant
    // mapping(uint256 => address) participantsByIndex;
    //      address  > registered
    mapping(address => bool) public registered;
    //      position > Winner
    mapping(uint256 => Winner) public podium;

    //  READS
    function pagesByChunkSize (uint256 _chunkSize) public view returns (uint256 _pages) {
        return (participants.length / _chunkSize) + 1;
    }

    //      Get user's predictions
    function getPredictions (address participant) public view returns (Prediction[] memory _predictions) {
        uint8 _totalMatches = totalMatches;
        Prediction[] memory array = new Prediction[](_totalMatches);
        for (uint256 i = 0; i < _totalMatches; i++) {
            array[uint8(i)] = predictions[participant][uint8(i + 1)];
        }
        return array;
    }
    //      Get all Matches
    function getMatches () public view returns (Match[] memory _matches) {
        uint8 _totalMatches = totalMatches;
        Match[] memory array = new Match[](_totalMatches);
        for (uint256 i = 0; i < _totalMatches; i++) {
            array[i] = matches[uint8(i + 1)];
        }
        return array;
    }
    //      Total score by user
    function currentScoreByUser(address participant) public view returns (Participant memory p) {
        uint256 score;
        uint8 _totalMatches = totalMatches;
        uint256 amount;
        for (uint8 i; i < _totalMatches; i++) {
            score += calculateScoreForMatch(i + 1, participant);
            amount += predictions[participant][i + 1].filled ? 1 : 0;
        }
        return Participant(participant, score, amount);
    }
    //      Get Scores by page (page size === chunk)
    function getAllScoresPaginated(uint256 page, uint256 chunk) public view returns (Participant[] memory _scores) {
        address[] memory _participants = participants;
        uint256 length = _participants.length >= page * chunk ? chunk : _participants.length - ((page - 1) * chunk);
        Participant[] memory scoresArray = new Participant[](length);
        uint256 base = (page - 1) * chunk;
        for (uint256 i = 0; i < scoresArray.length; i++) {
            scoresArray[i] = currentScoreByUser(_participants[i + base]);
        }
        return scoresArray;
    }

    //  WRITES
    //      Participate in event
    function participate() public payable {
        require(registered[msg.sender] == false, "You are already participating");
        require(msg.value >= cost, "You need to pay the Full Fee");
        participants.push(msg.sender);
        registered[msg.sender] = true;
    }

    //      Set Match Prediction
    function setPrediction(uint8 matchId, uint8 AScore, uint8 BScore, uint8 winner ) internal {
        require(registered[msg.sender], "You are not participating on the Event.");
        require(block.timestamp < matches[matchId].startTimestamp, "Game already started." );
        predictions[msg.sender][matchId] = Prediction(AScore, BScore, winner, true);
    }
    function setPredictionBatch(bytes[] calldata predictionsBytes) public {
        for (uint256 i = 0; i < predictionsBytes.length; i++) {
            (uint8 matchId, uint8 AScore, uint8 BScore, uint8 winner) = abi.decode(predictionsBytes[i], (uint8, uint8, uint8, uint8));
            setPrediction(matchId, AScore, BScore, winner);
        }
    }

    //  ONLY OWNER
    //      Set Match Details
    function setMatchDetails(uint8 matchId, uint8 teamA, uint8 teamB, uint32 startTimestamp) internal {
        Match storage thisMatch = matches[matchId];
        thisMatch.teamA = teamA;
        thisMatch.teamB = teamB;
        thisMatch.startTimestamp = startTimestamp;
    }
    function setMatchDetailsBatch(bytes[] calldata matchesBytes) public onlyOwner {
        for (uint256 i = 0; i < matchesBytes.length; i++) {
            (uint8 matchId, uint8 teamA, uint8 teamB, uint32 startTimestamp) = abi.decode(matchesBytes[i], (uint8, uint8, uint8, uint32));
            setMatchDetails(matchId, teamA, teamB, startTimestamp);
        }
    }

    //      Set Match Result
    function setResult(uint8 matchId, uint8 AScore, uint8 BScore, uint8 winner) internal {
        Match storage thisMatch = matches[matchId];
        require(block.timestamp > thisMatch.startTimestamp + matchDuration, "Can't set result of unfinished match.");
        thisMatch.AScore = AScore;
        thisMatch.BScore = BScore;
        thisMatch.ended = true;
        thisMatch.winner = winner;
    }
    function setResultBatch(bytes[] calldata resultsBytes) public onlyOwner {
        for (uint256 i = 0; i < resultsBytes.length; i++) {
            (uint8 matchId, uint8 AScore, uint8 BScore, uint8 winner) = abi.decode(resultsBytes[i], (uint8, uint8, uint8, uint8));
            setResult(matchId, AScore, BScore, winner);
        }
    }
    //      Set Podium, first and second place gets 60/30 prize
    function setPodium (address[] calldata winners) public onlyOwner {
        require(matches[totalMatches].ended, "Can't set podium if World Cup is not over.");
        uint256 contractBalance = address(this).balance;
        uint256 length = winners.length;
        for (uint256 i = 0; i < length; i++) {
            Winner storage winner = podium[0];
            winner.account = winners[i];
            winner.amount = (contractBalance / 5 * 3) - (i * contractBalance / 10 * 3);
        }
    }
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance / 10);
    }

    //  UTILS
    function calculateScoreForMatch(uint8 matchId, address participant) internal view returns (uint256 scoreForMatch) {
        Prediction memory thisPrediction = predictions[participant][matchId];
        if (!thisPrediction.filled) {
            return 0;
        }
        Match memory thisMatch = matches[matchId];
        if (!thisMatch.ended) {
            return 0;
        }
        uint256 score;
        //  1x2
        score += thisMatch.winner == thisPrediction.winner ? 5 : 0;
        //  Local goals
        score += thisMatch.AScore == thisPrediction.AScore ? 2 : 0;
        //  Visitor goals
        score += thisMatch.BScore == thisPrediction.BScore ? 2 : 0;
        //  Goals difference
        int8 matchDifference = int8(thisMatch.AScore) - int8(thisMatch.BScore);
        int8 predictionDifference = int8(thisPrediction.AScore) - int8(thisPrediction.BScore);
        score += matchDifference == predictionDifference ? 1 : 0;

        return score;
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