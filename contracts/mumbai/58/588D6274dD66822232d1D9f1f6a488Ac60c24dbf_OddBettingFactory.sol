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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

struct Competition {
    string firstTeam;
    string secondTeam;
    uint256 validBefore;
    uint256 validAfter;
    bool isFinished;
    bool startEntry;
    uint256 firstRatio;
    uint256 secondRatio;
    uint256 totalBets;
    uint256 competitionId;
}

struct JoinedDetail {
    uint256 competitionId;
    uint256 betId;
}

// Prediction can be of 1,2.3
// 1 for first Team
// 2 for secondTeam
// 3 for Draw

struct Bet {
    address firstPlayer;
    address secondPlayer;
    uint256 firstPlayerBidAmount;
    uint256 secondPlayerBidAmount;
    uint256 firstPlayerPrediction;
    uint256 secondPlayerPrediction;
    bool isClaimed;
    bool firstPlayerDrawFund;
    bool secondPlayerDrawFund;
}

contract OddBettingFactory is Ownable, ReentrancyGuard {
    uint256 public startId = 0;
    mapping(address => mapping(uint256 => uint256[])) public joinedIndex;
    mapping(address => uint256[]) public joinedCompetition;
    // mapping with competition id
    mapping(uint256 => Competition) public competitions;

    uint256 public minimumBetAmount = 10000000;

    // mapping of competition with total bet
    mapping(uint256 => uint256) public totalBets;

    mapping(address => JoinedDetail[]) public joinedDetails;

    // mapping of competitionid => betid
    mapping(uint256 => mapping(uint256 => Bet)) public bets;

    /**
     * Create Tournament
     */
    function createTournament(
        string memory firstTeam,
        string memory secondTeam,
        uint256 validAfter,
        uint256 validBefore,
        uint256 firstRatio,
        uint256 secondRatio
    ) public {
        require(
            validBefore > validAfter && validAfter > block.timestamp,
            "Time Need To Be In Future"
        );
        Competition storage competition = competitions[startId];
        competition.validAfter = validAfter;
        competition.validBefore = validBefore;
        competition.firstTeam = firstTeam;
        competition.secondTeam = secondTeam;
        competition.firstRatio = firstRatio;
        competition.secondRatio = secondRatio;
        competition.competitionId = startId++;
    }

    function getCompetition(
        uint256 startIndex
    ) public view returns (Competition[] memory) {
        Competition[] memory savedCompetitions = new Competition[](
            startId - startIndex
        );
        for (uint index = startIndex; index < startId - startIndex; index++) {
            savedCompetitions[index] = competitions[index];
        }
        return savedCompetitions;
    }

    function getBets(
        uint256 competitionId
    ) external view returns (Bet[] memory activeBets) {
        Competition memory competition = competitions[competitionId];
        for (uint256 index = 0; index < competition.totalBets; index++) {
            Bet memory bet = bets[competitionId][index];
            if (bet.secondPlayer == address(0)) {
                activeBets[activeBets.length] = bet;
            }
        }
    }

    function changeMinimumBet(uint256 _minimumBetAmount) public onlyOwner {
        minimumBetAmount = _minimumBetAmount;
    }

    function createBet(
        uint256 competitionId,
        uint256 prediction
    ) public payable nonReentrant {
        Competition storage competition = competitions[competitionId];
        require(
            competition.validAfter < block.timestamp &&
                competition.validBefore > block.timestamp &&
                !competition.isFinished,
            "You cannot join to this competition"
        );
        require(
            prediction == 1 || prediction == 2,
            "Prediction Number must be 1, 2"
        );
        require(msg.value > minimumBetAmount, "Require MinimumBet");
        uint256 currentCompetitionBet = totalBets[competitionId]++;
        Bet storage bet = bets[competitionId][currentCompetitionBet];
        bet.firstPlayer = msg.sender;
        bet.firstPlayerBidAmount = msg.value;
        bet.firstPlayerPrediction = prediction;
        bet.secondPlayerBidAmount =
            (msg.value * competition.secondRatio) /
            competition.firstRatio;
        competition.totalBets++;
    }

    function joinBet(
        uint256 competitionId,
        uint256 betId,
        uint256 prediction
    ) public payable nonReentrant {
        Competition memory competition = competitions[competitionId];
        require(
            competition.validAfter < block.timestamp &&
                competition.validBefore > block.timestamp,
            "You cannot join to this competition"
        );
        require(
            prediction == 1 || prediction == 2,
            "Prediction Number must be 1, 2"
        );

        Bet storage bet = bets[competitionId][betId];
        require(
            bet.firstPlayerPrediction != prediction &&
                bet.firstPlayer != msg.sender &&
                bet.firstPlayerPrediction != 0,
            "You cannot Join This Bet"
        );
        require(bet.secondPlayerPrediction == 0, "Bet Already Filled");
        require(
            bet.secondPlayerBidAmount <= msg.value,
            "Bet Amount Cannot be Less"
        );
        bet.secondPlayer = msg.sender;
        bet.secondPlayerPrediction = prediction;
        //joinedDetails[msg.sender].push(JoinedDetail(competitionId, betId));
    }
}