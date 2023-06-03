/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT
// File: contracts/interfaces/ITournament.sol


pragma solidity ^0.8.9;

interface ITournament {
    // Events
    event RoundStarted(uint256);
    event RoundEnded(uint256);
    event Draw(uint256, uint256);
    event DepositNFTEvent(uint256, address indexed, uint256);
    event StartTournamentEvent();
    event EndTournamentEvent();
    event WithdrawNFTEvent(address indexed, address indexed, uint256);
    event VoteInPlayerMatch(uint256, uint256, uint256);
    event WithdrawEvent(address, uint256);
    event jackpotIncreased(uint256);
    event OwnerOfNftChanged(uint256, uint256);
    event PublicGoodsClaimed();

    // States of the tournament
    enum StateTournament {
        Waiting,
        Started,
        Finished,
        Canceled
    }

    enum FeesClaimed {
        NotClaimed,
        Claimed
    }

    // View
    function getNftOwner(bytes memory) external view returns (address);

    function getNftUnlocked(bytes memory) external view returns (bool);

    function getTournamentStatus() external view returns (uint8);

    function totalVoted() external view returns (uint256);

    function getPlayer(uint256) external view returns (bytes memory);

    function getPlayerId(bytes memory) external view returns (uint256);

    function numRounds() external view returns (uint256);

    function roundDuration() external view returns (uint256);

    function roundInterval() external view returns (uint256);

    function endTime() external view returns (uint256);

    function fee() external view returns (uint256);

    function round() external view returns (uint256);

    function jackpot() external view returns (uint256);

    function publicGoods() external view returns (uint256);

    function jackpotPerc() external view returns (uint256);

    function publicGoodsPerc() external view returns (uint256);

    function getRound(uint256) external view returns (address);

    function getMatches(uint256) external view returns (bytes[] memory);

    function getPlayers(uint256) external view returns (uint256[] memory);

    function totalVotes(uint256) external view returns (uint256);

    function depositedLength() external view returns (uint256);

    // Mutators
    function depositNFT(uint256, address)
        external
        returns (
            uint256,
            address,
            uint256
        );

    function changeNftOwner(uint256, uint256) external;

    function claimNFT(
        address,
        address,
        uint256
    ) external;

    function vote(
        uint256,
        address,
        uint256,
        uint256
    ) external returns (uint256);

    function increaseJackpot(uint256) external returns (uint256);

    function claimTokens(address, uint256) external;

    function claimPublicGoods() external;

    function startTournament() external;

    function cancelTournament() external;

    function setDraw() external;

    function setVariables(
        uint256,
        uint256,
        uint256
    ) external;

    function addRound(address) external;

    function startRound() external;

    function endRound() external returns (bool);
}

// File: contracts/interfaces/IRound.sol


pragma solidity ^0.8.9;

interface IRound {
    event VoteInPlayerMatch(uint256, address, uint256, uint256);
    event RoundEnded();
    event RoundStarted();
    event JackpotUpdated(uint256);

    // States of the tournament
    enum StateRound {
        Waiting,
        Started,
        Finished
    }

    // Mutators
    function createMatches() external;

    function startRound() external;

    function endRound() external returns (bool);
    
    function addVotes(uint256) external;

    // View functions
    function matchesEncoded(uint256) external view returns (bytes memory);

    function validateVote(address _matchAddress) external view;

    function getStarted() external view returns (bool);

    function getFinished() external view returns (bool);

    function getMatchFinished(uint256) external view returns (bool);

    function getMatch(uint256 _matchId) external view returns (address);

    function getMatchesQty() external view returns (uint256);

    function totalVoted() external view returns (uint256);

    function roundStart() external view returns (uint256);

    function roundEnd() external view returns (uint256);

    function applyJackpot(uint256)
        external
        view
        returns (bytes memory, bytes memory);

    function getWinners() external view returns (uint256[] memory);

    function getMatchesEncoded() external view returns (bytes[] memory);

    function getPlayers() external view returns (uint256[] memory);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/interfaces/IMatch.sol


pragma solidity ^0.8.9;

interface IMatch {
    // Events
    event VotedPlayer(address, uint8, uint256);
    event SetWinnerPlayer1();
    event SetWinnerPlayer2();
    event SetPot(uint256, uint256);
    event setWithdrawal(address);
    event Draw();

    // Functions
    function votePlayer(address, uint8, uint256) external;

    // Mutators
    function setWinner() external returns (bool);

    function setPot(bytes memory) external;

    function setWithdrawalSupporter(address) external;

    // View functions
    function votesPlayer1() external view returns (uint256);

    function votesPlayer2() external view returns (uint256);

    function supporterForPlayer1(address) external view returns (uint256);

    function supporterForPlayer2(address) external view returns (uint256);

    function getPlayer1() external view returns (bytes memory);

    function getPlayer2() external view returns (bytes memory);

    function getWinner() external view returns (bytes memory);

    function claimAmount(address) external view returns (bytes memory);

    function winnerId() external view returns (uint8);

    function getFinished() external view returns (bool);

    function getPot() external view returns (bytes memory);

    function getWithdrawalSupporter(address) external view returns (bool);
}

// File: contracts/interfaces/ITournamentHub.sol


pragma solidity ^0.8.9;

interface ITournamentHub {
    event ContractAdded(address);
    event TournamentGeneratorChanged(address);
    event RoundGeneratorChanged(address);
    event MatchGeneratorChanged(address);
    event TournamentMessagesChanged(address);
    event OnGoingTournamentAdded(address);
    event OnGoingTournamentRemoved(address);
    event TokenChanged(address);
    event PublicGoodsWalletChanged(address);
    event FeeWalletWalletChanged(address);
    event JackpotWalletWalletChanged(address);
    event AllNftClaimed(address);
    event AllTokensClaimed(address);
    event WithdrawNFTEvent(address indexed, address indexed, uint256);
    event WithdrawEvent(address, uint256);
    event BlacklistStatusChanged(address indexed, bool);
    event CheckStatusChanged(address indexed, bool);
    event DataFeedChanged(address indexed);

    //View
    function blacklistedNfts(address _address) external view returns (bool);

    function checkedNfts(address _address) external view returns (bool);

    function checkProject(address) external view returns (bool);

    function checkAdmin(address) external view returns (bool);

    function roundGenerator() external view returns (address);

    function matchGenerator() external view returns (address);

    function tournamentGenerator() external view returns (address);

    function publicGoodsWallet() external view returns (address);

    function feeWallet() external view returns (address);

    function jackpotWallet() external view returns (address);

    function tribeXToken() external view returns (address);

    function getOngoingSize() external view returns (uint256);

    function tournamentVariables(address) external view returns (bytes memory);

    function getTournamentJackpot(
        address _tournamentAddress
    ) external view returns (uint256);

    function jackpotVariables(
        address _tournamentAddress
    ) external view returns (bytes memory);

    function roundMatches(
        address _tournamentAddress
    ) external view returns (bytes[6] memory);

    //Mutators
    function setBlacklistStatus(address, bool) external;

    function setCheckStatus(address, bool) external;

    function addContract(address) external;

    function addOnGoing(address) external;

    function removeOnGoing(address) external;

    function changePriceFeed(address) external;

    function changeTournamentGenerator(address) external;

    function changeRoundGenerator(address) external;

    function changeMatchGenerator(address) external;

    function changePublicGoodsWallet(address) external;

    function changeFeesWallet(address) external;

    function retrieveRandomArray(uint256) external returns (uint256[] memory);

    function claimAllNfts(address _tournamentAddress) external;

    function claimAllTokens(address _tournamentAddress) external;

    function withdrawNFT(
        address _tournamentAddress,
        uint256 _tokenId,
        address _nftContract
    ) external;

    function claimFromMatch(
        address _tournamentAddress,
        uint256 _matchId,
        uint256 _roundNumber
    ) external;
}

// File: contracts/Match.sol


pragma solidity ^0.8.9;






contract Match is IMatch {
    using SafeMath for uint256;

    // Variables
    bytes public override getPlayer1;
    bytes public override getPlayer2;
    bytes public override getWinner;
    uint8 public override winnerId;
    bytes public override getPot;
    uint256 public override votesPlayer1;
    uint256 public override votesPlayer2;
    bool public override getFinished;
    bool internal draw = false;
    mapping(address => uint256) public override supporterForPlayer1;
    mapping(address => uint256) public override supporterForPlayer2;
    mapping(address => bool) public override getWithdrawalSupporter;
    ITournamentHub private tournamentHub;
    IRound private round;
    ITournament private tournament;

    // Constructor
    /**
     * @dev Constructor for Match contract
     * @param _player1 Player 1's encoded NFT data
     * @param _player2 Player 2's encoded NFT data
     * @param _tournamentHub TournamentHub contract address
     * @param _tournament Tournament contract address
     * @param _round Round contract address
     */
    constructor(
        bytes memory _player1,
        bytes memory _player2,
        address _tournamentHub,
        address _tournament,
        address _round
    ) {
        getPlayer1 = _player1;
        getPlayer2 = _player2;
        winnerId = 0;
        votesPlayer1 = 0;
        votesPlayer2 = 0;
        getFinished = false;

        tournamentHub = ITournamentHub(_tournamentHub);
        round = IRound(_round);
        tournament = ITournament(_tournament);
    }

    /**
     * @dev Throws if called by any account other than project contracts.
     */
    modifier onlyProject() {
        //Check authorization
        require(tournamentHub.checkProject(msg.sender), "M-01");
        _;
    }

    /**
     * @dev Function to register token quantity deposited to support player
     * @param _supporter Address of supporter
     * @param _playerInMatch Player in match (1 or 2)
     * @param _amount Amount of tokens deposited
     */
    function votePlayer(
        address _supporter,
        uint8 _playerInMatch,
        uint256 _amount
    ) public onlyProject {
        require((_playerInMatch == 1) || (_playerInMatch == 2), "M-02");
        require(!getFinished, "M-03");

        if (_playerInMatch == 1) {
            supporterForPlayer1[_supporter] = supporterForPlayer1[_supporter]
                .add(_amount);
            votesPlayer1 = votesPlayer1.add(_amount);
        } else {
            supporterForPlayer2[_supporter] = supporterForPlayer2[_supporter]
                .add(_amount);
            votesPlayer2 = votesPlayer2.add(_amount);
        }

        emit VotedPlayer(_supporter, _playerInMatch, _amount);
    }

    /**
     * @dev Function to set match's winner
     * @return bool True if winner is set, false if match is a draw
     */
    function setWinner() public onlyProject returns (bool) {
        if (winnerId != 0) return true;

        if (votesPlayer2 < votesPlayer1) {
            getWinner = getPlayer1;
            winnerId = 1;
            getFinished = true;
            emit SetWinnerPlayer1();
            return true;
        }
        if (votesPlayer2 > votesPlayer1) {
            getWinner = getPlayer2;
            winnerId = 2;
            getFinished = true;
            emit SetWinnerPlayer2();
            return true;
        }

        if (draw) {
            uint256 randomWinner = uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % 2;
            if (randomWinner == 0) {
                getWinner = getPlayer1;
                winnerId = 1;
                getFinished = true;
                emit SetWinnerPlayer1();
                return true;
            }
            getWinner = getPlayer2;
            winnerId = 2;
            getFinished = true;
            emit SetWinnerPlayer2();
            return true;
        }

        emit Draw();
        draw = true;
        return false;
    }

    /**
     * @dev Function to set the pot for this match
     * @param _pot Pot amount plus the jackpot of final round (before it, final round is 0)
     */
    function setPot(bytes memory _pot) public onlyProject {
        getPot = _pot;
        getFinished = true;
        (uint256 _exitPot, uint256 _exitJackpot) = abi.decode(
            _pot,
            (uint256, uint256)
        );
        emit SetPot(_exitPot, _exitJackpot);
    }

    /**
     * @dev Function to set supporter as submitted a withdrawal
     * @param _supporter Address of supporter
     */
    function setWithdrawalSupporter(address _supporter) public onlyProject {
        getWithdrawalSupporter[_supporter] = true;
        emit setWithdrawal(_supporter);
    }

    /**
     * @dev View function to calculate supporter's withdrawal
     * @param _sender Address of supporter
     * @return bytes containig 3 uint256 with the splitted value to claim
     */
    function claimAmount(address _sender) public view returns (bytes memory) {
        if (getWithdrawalSupporter[_sender]) return abi.encode(0, 0, 0);

        uint256 _percSupporter;
        uint256 _amount;
        uint256 _support;
        (uint256 _pot, uint256 _jackpot) = abi.decode(
            getPot,
            (uint256, uint256)
        );
        uint256 jackpot_;

        if (winnerId == 1) {
            _support = supporterForPlayer1[_sender];
            _percSupporter = _support.mul(1e18).div(votesPlayer1);
            _amount = _percSupporter.mul(_pot).div(1e18);
            jackpot_ = _percSupporter.mul(_jackpot).div(1e18);
        }

        if (winnerId == 2) {
            _support = supporterForPlayer2[_sender];
            _percSupporter = _support.mul(1e18).div(votesPlayer2);
            _amount = _percSupporter.mul(_pot).div(1e18);
            jackpot_ = _percSupporter.mul(_jackpot).div(1e18);
        }

        return abi.encode(_support, _amount, jackpot_);
    }
}

// File: contracts/interfaces/IMatchGenerator.sol


pragma solidity ^0.8.9;

interface IMatchGenerator {
    event MatchCreated(address);
    event TournamentHubChanged(address);

    function createMatch(
        bytes memory,
        bytes memory,
        address,
        address,
        uint256
    ) external returns (address);

    function getMatchData(address) external view returns (bytes memory);

    function changeTournamentHub(address) external;
}

// File: contracts/MatchGenerator.sol


pragma solidity ^0.8.9;





contract MatchGenerator is IMatchGenerator {
    address[] internal matches;
    mapping(address => bytes) internal matchesData;
    ITournamentHub internal tournamentHub;
    bool public activated;
    address private deployer;

    /**
     * @dev Constructor for MatchGenerator contract
     */
    constructor() {
        deployer = msg.sender;
    }

    /**
     * @dev Generates a new Match Contract.
     * @param _player1 Player 1's encoded NFT data
     * @param _player2 Player 2's encoded NFT data
     * @param _tournament Tournament contract address
     * @param _roundContract Round contract address
     * @param _roundNumber Round number
     * @return address of the new Match contract
     */
    function createMatch(
        bytes memory _player1,
        bytes memory _player2,
        address _tournament,
        address _roundContract,
        uint256 _roundNumber
    ) public returns (address) {
        //Check if activated
        require(activated, "MG-01");
        //Check authorization
        require(tournamentHub.checkProject(msg.sender), "MG-02");

        // Create new tournament
        Match m = new Match(
            _player1,
            _player2,
            address(tournamentHub),
            _tournament,
            _roundContract
        );
        address matchAddress = address(m);
        matches.push(matchAddress);
        matchesData[matchAddress] = abi.encode(_tournament, _roundNumber);
        tournamentHub.addContract(matchAddress);

        // Emit event
        emit MatchCreated(matchAddress);

        // Return address
        return matchAddress;
    }

    /**
     * @dev Retrieves all Matches data
     * @param _match Match contract address
     * @return Match data
     */
    function getMatchData(address _match) public view returns (bytes memory) {
        return matchesData[_match];
    }

    /**
     * @dev Changes Tournament Hub contract and activates Generator
     * @param _contract Tournament Hub contract address
     */
    function changeTournamentHub(address _contract) public {
        // Check Permissions
        if (activated) require(tournamentHub.checkAdmin(msg.sender), "MG-02");
        else require(deployer == msg.sender, "MG-03");

        tournamentHub = ITournamentHub(_contract);
        activated = true;
        emit TournamentHubChanged(_contract);
    }
}