/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT
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

// File: contracts/interfaces/IRoundGenerator.sol


pragma solidity ^0.8.9;

// Interface
interface IRoundGenerator {
    event RoundCreated(address);
    event TournamentHubChanged(address);

    function createRound(
        bytes memory,
        uint256,
        uint256,
        uint256,
        bool,
        address
    ) external returns (address);

    function changeTournamentHub(address) external;
}

// File: contracts/Round.sol


pragma solidity ^0.8.9;








contract Round is IRound {
    using SafeMath for uint256;
    StateRound public roundStatus;

    ITournament internal tournament;
    IMatchGenerator internal matchGenerator;
    ITournamentHub internal tournamentHub;

    address[] public override getMatch;
    uint256[] internal players;
    uint256[] internal winners;
    uint256 public override roundStart;
    uint256 public override roundEnd;
    uint256 internal minutesOnDraw;
    uint256 internal roundNumber;
    uint256 public override totalVoted;
    bool public draw;
    bytes[] public override matchesEncoded;

    // temp variables
    uint256[] internal temp;

    /**
     * @dev Constructor for Round contract
     * @param _players encoded players array
     * @param _roundStart Round start time in timestamp miliseconds
     * @param roundDuration Round duration in timestamp miliseconds
     * @param _minutesOnDraw Minutes to add on match draw
     * @param instantStart Instant start
     * @param _tournament Tournament contract address
     * @param _tournamentHub TournamentHub contract address
     */
    constructor(
        bytes memory _players,
        uint256 _roundStart,
        uint256 roundDuration,
        uint256 _minutesOnDraw,
        bool instantStart,
        address _tournament,
        address _tournamentHub
    ) {
        if (instantStart) roundStatus = StateRound.Started;
        else roundStatus = StateRound.Waiting;

        tournament = ITournament(_tournament);
        tournamentHub = ITournamentHub(_tournamentHub);
        matchGenerator = IMatchGenerator(tournamentHub.matchGenerator());

        players = abi.decode(_players, (uint256[]));
        roundStart = _roundStart;
        roundEnd = _roundStart.add(roundDuration);
        roundNumber = 1;
        minutesOnDraw = _minutesOnDraw;
        totalVoted = 0;
    }

    /**
     * @dev Throws if called by any account other than project contracts.
     */
    modifier onlyProject() {
        //Check authorization
        require(tournamentHub.checkProject(msg.sender), "R-01");
        _;
    }

    /**
     * @dev Throws if called by any account other than the administrator.
     */
    modifier onlyAdministrator() {
        // Check Permissions
        require(tournamentHub.checkAdmin(msg.sender), "T-01");
        _;
    }

    /**
     * @dev Create matches using the shuffled players array. It needs to be called by the administrator right after the round is created.
     */
    function createMatches() public onlyAdministrator {
        require(getMatch.length==0);
        bytes memory _player1;
        bytes memory _player2;

        address _match;
        uint256 _playersLength = players.length;
        for (uint256 i = 0; i < _playersLength; i += 2) {
            _player1 = tournament.getPlayer(players[i]);
            _player2 = tournament.getPlayer(players[i + 1]);
            _match = matchGenerator.createMatch(
                _player1,
                _player2,
                address(tournament),
                address(this),
                roundNumber
            );
            getMatch.push(_match);
            matchesEncoded.push(abi.encode(_player1, _player2, _match));
        }
    }

    /**
     * @dev Start this round
     */
    function startRound() public onlyProject {
        require(roundStatus == StateRound.Waiting, "R-02");

        roundStatus = StateRound.Started;
        emit RoundStarted();
    }

    /**
     * @dev End this round
     * @return bool true if round ended, false if round has a match draw
     */
    function endRound() public onlyProject returns (bool) {
        require(roundStatus == StateRound.Started, "R-03");
        uint256 len = getMatch.length;
        bytes memory _pot;
        bytes memory _tVar;
        uint256 _idPlayer1;
        uint256 _idPlayer2;
        bool _matchDraw;
        uint256 _tFee;
        uint256 _tJackpot;
        uint256 _tPublicGoods;
        uint256[] memory _emptyArray;
        temp = _emptyArray;
        draw = false;

        IMatch _match;

        for (uint256 i = 0; i < len; i++) {
            _match = IMatch(getMatch[i]);
            _matchDraw = false;

            _idPlayer1 = tournament.getPlayerId(_match.getPlayer1());
            _idPlayer2 = tournament.getPlayerId(_match.getPlayer2());

            if (_match.winnerId() == 0) {
                if (_match.setWinner() == false) {
                    _matchDraw = true;
                    draw = true;
                }

                if (!_matchDraw) {
                    if (_match.winnerId() == 1) {
                        temp.push(_idPlayer1);

                        tournament.changeNftOwner(_idPlayer2, _idPlayer1);

                        (_pot, _tVar) = applyJackpot(_match.votesPlayer2());
                        (_tFee, _tJackpot, _tPublicGoods) = abi.decode(
                            _tVar,
                            (uint256, uint256, uint256)
                        );
                        tournament.setVariables(
                            _tFee,
                            _tJackpot,
                            _tPublicGoods
                        );

                        _match.setPot(_pot);
                    } else {
                        temp.push(_idPlayer2);

                        tournament.changeNftOwner(_idPlayer1, _idPlayer2);

                        (_pot, _tVar) = applyJackpot(_match.votesPlayer1());
                        (_tFee, _tJackpot, _tPublicGoods) = abi.decode(
                            _tVar,
                            (uint256, uint256, uint256)
                        );
                        tournament.setVariables(
                            _tFee,
                            _tJackpot,
                            _tPublicGoods
                        );

                        _match.setPot(_pot);
                    }
                }
            } else if (_match.winnerId() == 1) temp.push(_idPlayer1);
            else if (_match.winnerId() == 2) temp.push(_idPlayer2);
        }
        if (draw) {
            roundEnd = roundEnd.add(minutesOnDraw);
            tournament.setDraw();
            return false;
        } else {
            winners = temp;

            if (tournament.round() != tournament.numRounds()) {
                address _roundContract = IRoundGenerator(
                    tournamentHub.roundGenerator()
                ).createRound(
                        abi.encode(winners),
                        roundEnd.add(tournament.roundInterval()),
                        tournament.roundDuration(),
                        minutesOnDraw,
                        false,
                        address(tournament)
                    );
                //IRound(_roundContract).createMatches();
                tournament.addRound(_roundContract);
            }
            roundStatus = StateRound.Finished;
            emit RoundEnded();
            return true;
        }
    }

    /**
     * @dev Validates if a match is able to receive votes
     * @param _matchAddress address of a match
     */
    function validateVote(address _matchAddress) public view {
        require(roundStatus == StateRound.Started, "R-03");
        IMatch MatchInterface = IMatch(_matchAddress);
        require(MatchInterface.winnerId() == 0, "R-04");
    }

    /**
     * @dev Add votes to the total of the round
     * @param _amount Amount of votes to add
     */
    function addVotes(uint256 _amount) public onlyProject {
        totalVoted = totalVoted.add(_amount);
    }

    /**
     * @dev Returns the list of winners of the round
     * @return uint256[] Array of winners
     */
    function getWinners() public view returns (uint256[] memory) {
        return winners;
    }

    /**
     * @dev Returns the list of players of the round
     * @return uint256[] Array of players
     */
    function getPlayers() public view returns (uint256[] memory) {
        return players;
    }

    /**
     * @dev Returns the number of matches of the round
     * @return uint256 Number of matches
     */
    function getMatchesQty() public view returns (uint256) {
        return getMatch.length;
    }

    /**
     * @dev Returns the list of matches encoded data of the round
     * @return bytes[] Array of matches data
     */
    function getMatchesEncoded() public view returns (bytes[] memory) {
        return matchesEncoded;
    }

    /**
     * @dev Returns if the round has already started
     * @return bool true if round has already started, false otherwise
     */
    function getStarted() public view returns (bool) {
        return roundStatus != StateRound.Waiting;
    }

    /**
     * @dev Returns if the round has already finished
     * @return bool true if round has already finished, false otherwise
     */
    function getFinished() public view returns (bool) {
        return roundStatus == StateRound.Finished;
    }

    /**
     * @dev Returns if the match has already finished
     * @return bool true if match has finished, false otherwise
     */
    function getMatchFinished(uint256 _matchId) public view returns (bool) {
        return IMatch(getMatch[_matchId]).getFinished();
    }

    /**
     * @dev Function calculates to apply 0.5% tax and the percentage to the jackpot at the end of a round
     * the function also checks if it's the last round and applies the value for public goods
     * @param _pot Amount of votes to apply the jackpot
     * @return uint256 The real pot to distribute
     * @return bytes Encoded data of the variables to update
     */
    function applyJackpot(
        uint256 _pot
    ) public view returns (bytes memory, bytes memory) {
        uint256 fee_ = tournament.fee();
        uint256 jackpot_ = tournament.jackpot();
        uint256 publicGoods_ = tournament.publicGoods();

        uint256 _fee = _pot.mul(5).div(1000);
        uint256 _jackpot;
        uint256 _publicGoods;
        uint256 _exitJackpot;

        fee_ = fee_.add(_fee);
        _pot = _pot.sub(_fee);

        if (tournament.round() == tournament.numRounds()) {
            _fee = jackpot_.mul(25).div(1000);
            fee_ = fee_.add(_fee);
            jackpot_ = jackpot_.sub(_fee);

            _publicGoods = jackpot_.mul(tournament.publicGoodsPerc()).div(100);
            publicGoods_ = publicGoods_.add(_publicGoods);
            jackpot_ = jackpot_.sub(_publicGoods);
            _exitJackpot = jackpot_;
        } else {
            _jackpot = _pot.mul(tournament.jackpotPerc()).div(100);
            _pot = _pot.sub(_jackpot);
            jackpot_ = jackpot_.add(_jackpot);
            _exitJackpot = 0;
        }

        return (
            abi.encode(_pot, _exitJackpot),
            abi.encode(fee_, jackpot_, publicGoods_)
        );
    }
}

// File: contracts/RoundGenerator.sol


pragma solidity ^0.8.9;





contract RoundGenerator is IRoundGenerator {
    address[] internal rounds;
    ITournamentHub public tournamentHub;
    bool public activated;
    address private deployer;

    constructor() {
        deployer = msg.sender;
    }

    /**
     * @dev Generates a new Round Contract.
     * @param _players Encoded NFT data of all players
     * @param _roundStart Timestamp of the start of the round
     * @param _roundDuration Duration of the round in timestamp milliseconds
     * @param _minutesOnDraw Minutes to add on match draw
     * @param _instantStart If true, the round starts immediately
     * @param _tournament Tournament contract address
     * @return address of the new Round contract
     */
    function createRound(
        bytes memory _players,
        uint256 _roundStart,
        uint256 _roundDuration,
        uint256 _minutesOnDraw,
        bool _instantStart,
        address _tournament
    ) public returns (address) {
        //Check if activated
        require(activated, "RG-01");
        //Check authorization
        require(tournamentHub.checkProject(msg.sender), "RG-02");

        // Create new tournament
        Round r = new Round(
            _players,
            _roundStart,
            _roundDuration,
            _minutesOnDraw,
            _instantStart,
            _tournament,
            address(tournamentHub)
        );
        address roundAddress = address(r);
        rounds.push(roundAddress);
        tournamentHub.addContract(roundAddress);

        emit RoundCreated(roundAddress);

        return roundAddress;
    }

    /**
     * @dev Changes Tournament Hub contract and activates Generator
     * @param _contract New Tournament Hub contract address
     */
    function changeTournamentHub(address _contract) public {
        // Check Permissions
        if (activated) require(tournamentHub.checkAdmin(msg.sender), "RG-02");
        else require(deployer == msg.sender, "RG-03.");

        tournamentHub = ITournamentHub(_contract);
        activated = true;
        emit TournamentHubChanged(_contract);
    }
}