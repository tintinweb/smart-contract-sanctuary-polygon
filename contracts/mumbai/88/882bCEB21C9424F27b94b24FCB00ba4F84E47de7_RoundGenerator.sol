/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// File: contracts/interfaces/IMatch.sol


pragma solidity ^0.8.9;

interface IMatch {
    // Events
    event VotedPlayer1(address supporter, uint amount);
    event VotedPlayer2(address supporter, uint amount);
    event SetWinnerPlayer1();
    event SetWinnerPlayer2();
    event SetPot(uint256 _pot);
    event setWithdrawal(address _supporter);
    event Draw();

    // Functions
    function votePlayer1(address supporter, uint amount) external;
    function votePlayer2(address supporter, uint amount) external;
    function setWinner() external returns (bool);
    function setPot(uint256 _pot) external;
    function votesPlayer1() external view returns (uint);
    function votesPlayer2() external view returns (uint);
    function supporterForPlayer1(address _supporter) external view returns (uint);
    function supporterForPlayer2(address _supporter) external view returns (uint);
    function getPlayer1() external view returns (bytes memory);
    function getPlayer2() external view returns (bytes memory);
    function getRound() external view returns (uint);
    function getWinner() external view returns (bytes memory);
    function getFinished() external view returns (bool);
    function getPot() external view returns (uint256);
    function setWithdrawalSupporter(address _supporter) external;
    function getWithdrawalSupporter(address _supporter) external view returns(bool);
}
// File: contracts/interfaces/ITournament.sol


pragma solidity ^0.8.9;

error JackpotPercentageMoreThan100();
error TournamentNotOpenToNewParticipants();
error MaximumNumberOfPlayersReached();
error SenderNotOwnerOfNFT();
error ContractNotApprovedToMoveNFT();
error TournamentNotEnded();
error NFTNotOnTournament();
error ActualOwnerHasTakenNFT();
error PlayerNotOwnerOfNFT();
error TournamentYetNotStarted();
error RoundAlreadyStarted();
error MatchIdNotFound();
error MatchAlreadyFinished();
error TournamentAlreadyFinished();
error MustVoteForOneOfPlayers();
error NotEnoughTokens();
error MustApproveTokensFirst();
error RoundNotFinished();
error AlreadySubmittedWithdrawal();
error TournamentNotInStartTime();
error RoundNotInStartTime();
error TransferUnsuccessful();
error YouDidNotGiveYourSupport(address _sender);
error ProblemOnWithdrawTokens();
error SenderIsNotTheOwner(address _sender);

interface ITournament {
    // View
    function getPlayer(uint _id) external view returns(bytes memory);
    function getPlayerId(bytes memory _player) external view returns(uint);
    function getNftOwner(uint256 _tokenId, address _nftContract)
        external
        view
        returns (address);

    //function getJackpotPublicGoods() external view returns (uint256, uint256);
    function getVariables() external view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256);

    // Mutators
    function startTournament(uint256 _now) external;

    function endTournament(uint256 _now) external;

    function startRound(uint256 _now) external;

    function vote(
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function endRound(uint256 _now) external  returns(bool);

    function claimFromMatch(uint256 _matchId, uint256 _round) external;

    // Events
    event RoundStarted(uint256 _round);
    event RoundEnded(uint256 _round);
    event Draw(uint256 _round, uint256 _match);
    event DepositNFTEvent(address indexed _player, uint256 _tokenId);
    event StartTournamentEvent(uint256 _now);
    event EndTournamentEvent(uint256 _now);
    event WithdrawNFTEvent(
        address indexed _player,
        address indexed _nftContract,
        uint256 _tokenId
    );
    event VoteInPlayerMatch(
        uint256 _round,
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _score2
    ); // emit when match score is set
    event WithdrawEvent(address _sender, uint256 _amount);
}

// File: contracts/interfaces/IRound.sol


pragma solidity ^0.8.9;

interface IRound {
    event VoteInPlayerMatch(
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount
    );
    event RoundEnded(uint256 _round);
    event RoundStarted(uint256 _round);

    function vote(
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount,
        address _sender
    ) external;

    function getWinners() external view returns (uint256[] memory);

    function endRound(uint256 _now) external returns (uint256[] memory, bool, bytes memory);

    function startRound() external;

    function getStarted() external view returns (bool);

    function getFinished() external view returns (bool);

    function getMatchFinished(uint256 _matchId) external view returns (bool);

    function getMatch(uint256 _matchId) external view returns (address);

    function getMatchesQty() external view returns (uint256);

    function withdrawTokens(address _sender, uint256 _amount)
        external
        returns (bool);

    function applyJackpot(uint256 _pot, bytes memory _tVar)
        external
        view
        returns (uint256, bytes memory);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/interfaces/IRoundGenerator.sol


pragma solidity ^0.8.9;

error TribeTokenInvalid(address _tribeToken);
// Interface
interface IRoundGenerator {
    event RoundCreated(address _contract);

    function createRound(
        bytes memory _players,
        uint256 _roundStart,
        uint256 roundDuration,
        uint256 _minutesOnDraw,
        bool instantStart,
        address _tournament,
        address _tribeToken
    ) external returns (address);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Match.sol


pragma solidity ^0.8.9;




contract Match is Ownable, IMatch {
    // Variables
    bytes private player1;
    bytes private player2;
    bytes private winner;
    uint256 private player1Votes;
    uint256 private player2Votes;
    uint256 public pot;
    uint private round;
    bool private finished;
    mapping(address => uint256) private votesForPlayer1;
    mapping(address => uint256) private votesForPlayer2;
    mapping(address => bool) private withdrawal;


    // Constructor
    constructor(
        bytes memory _player1,
        bytes memory _player2,
        uint _round
    ) {
        player1 = _player1;
        player2 = _player2;
        player1Votes = 0;
        player2Votes = 0;
        round = _round;
        finished = false;
    }

    // Vote for Player 1
    function votePlayer1(address supporter, uint256 amount) public onlyOwner {
        votesForPlayer1[supporter] += amount;
        player1Votes += amount;

        emit VotedPlayer1(supporter, amount);
    }

    // Vote for Player 2
    function votePlayer2(address supporter, uint256 amount) public onlyOwner {
        votesForPlayer2[supporter] += amount;
        player2Votes += amount;

        emit VotedPlayer2(supporter, amount);
    }

    // Set winner
    function setWinner() public onlyOwner returns (bool) {
        require(
            keccak256(winner) != keccak256(player1) &&
                keccak256(winner) != keccak256(player2),
            "Winner was already set"
        );

        if (player2Votes < player1Votes) {
            winner = player1;
            emit SetWinnerPlayer1();
            return true;
        } else if (player2Votes > player1Votes) {
            winner = player2;
            emit SetWinnerPlayer2();
            return true;
        } else {
            emit Draw();
            return false;
        }
    }

    // Set pot for this match
    function setPot(uint256 _pot) public onlyOwner{
        pot = _pot;
        finished = true;
        emit SetPot(_pot);
    }

    // Set supporter as submitted a withdrawal
    function setWithdrawalSupporter(address _supporter) public onlyOwner{
        withdrawal[ _supporter ] = true;
        emit setWithdrawal(_supporter);
    }

    /////////VIEW Functions

    // Returns true if supportes has submitted a withdrawal
    function getWithdrawalSupporter(address _supporter) public view returns(bool){
        return withdrawal[ _supporter ];
    }

    // Show votes for Player 1
    function votesPlayer1() public view returns (uint){
        return player1Votes;
    }

    // Show votes for Player 2
    function votesPlayer2() public view returns (uint){
        return player2Votes;
    }

    // Show votes for Player 1 by a supporter
    function supporterForPlayer1(address _supporter) public view returns (uint){
        return votesForPlayer1[_supporter];
    }

    // Show votes for Player 2 by a supporter
    function supporterForPlayer2(address _supporter) public view returns (uint){
        return votesForPlayer2[_supporter];
    }

    // Returns Player 1
    function getPlayer1() public view returns (bytes memory) {
        return player1;
    }

    // Returns Player 2
    function getPlayer2() public view returns (bytes memory) {
        return player2;
    }

    // Returns Round Number
    function getRound() public view returns (uint) {
        return round;
    }

    // Returns if it's finished or not
    function getFinished() public view returns (bool) {
        return finished;
    }

    // Returns the pot
    function getPot() public view returns (uint256) {
        return pot;
    }

    // Returns Winner
    function getWinner() public view returns (bytes memory) {
        require(
            keccak256(winner) == keccak256(player1) &&
                keccak256(winner) == keccak256(player2),
            "No winner was already set"
        );
        return winner;
    }
}

// File: contracts/Round.sol


pragma solidity ^0.8.9;






contract Round is Ownable, IRound {
    // States of the tournament
    enum StateRound {
        Waiting,
        Started,
        Finished
    }
    StateRound private roundStatus;

    ITournament internal tournament;
    IERC20 internal tribeToken;

    address[] internal matches;
    uint256[] private players;
    uint256[] private winners;
    uint256 private roundStart;
    uint256 private roundEnd;
    uint256 private minutesOnDraw;
    uint256 private roundNumber;

    // temp variables
    uint256[] internal temp;
    uint256[] internal temp2;

    constructor(
        bytes memory _players,
        uint256 _roundStart,
        uint256 roundDuration,
        uint256 _minutesOnDraw,
        bool instantStart,
        address _tournament,
        address _tribeToken
    ) {
        if (instantStart) roundStatus = StateRound.Started;
        else roundStatus = StateRound.Waiting;
        players = abi.decode(_players, (uint256[]));
        roundStart = _roundStart;
        roundEnd = _roundStart + roundDuration;
        roundNumber = 1;
        tournament = ITournament(_tournament);
        tribeToken = IERC20(_tribeToken);
        minutesOnDraw = _minutesOnDraw;
        Match _match;

        uint256 len = players.length;

        uint256 _tempNumber;

        for (uint256 i = 0; i < len; i++) {
            uint256 j = uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, players[i], i)
                )
            ) % len;
            _tempNumber = players[i];
            players[i] = players[j];
            players[j] = _tempNumber;
        }

        for (uint256 i = 0; i < len; i += 2) {
            _match = new Match(
                tournament.getPlayer(players[i]),
                tournament.getPlayer(players[i + 1]),
                roundNumber
            );
            matches.push(address(_match));
        }
    }

    // return if round has already started
    function getStarted() public view returns (bool) {
        return roundStatus != StateRound.Waiting;
    }

    // return if round has already finished
    function getFinished() public view returns (bool) {
        return roundStatus == StateRound.Finished;
    }

    // return if round has already started
    function getMatchFinished(uint256 _matchId) public view returns (bool) {
        return IMatch(matches[_matchId]).getFinished();
    }

    // start a round that has not started
    function startRound() public onlyOwner {
        roundStatus = StateRound.Started;
        emit RoundStarted(roundNumber);
    }

    //return the address of a Match contract
    function getMatch(uint256 _matchId) public view returns (address) {
        return matches[_matchId];
    }

    // Voting function
    function vote(
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount,
        address _sender
    ) public onlyOwner {
        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);
        if (
            keccak256(encodedNft) !=
            keccak256(IMatch(matches[_matchId]).getPlayer1()) &&
            keccak256(encodedNft) !=
            keccak256(IMatch(matches[_matchId]).getPlayer2())
        ) revert MustVoteForOneOfPlayers();

        if (tribeToken.balanceOf(_sender) < _amount) revert NotEnoughTokens();
        if (tribeToken.allowance(_sender, address(this)) < _amount)
            revert MustApproveTokensFirst();

        bool success = tribeToken.transferFrom(_sender, address(this), _amount);
        if (!success) revert TransferUnsuccessful();

        if (
            keccak256(encodedNft) ==
            keccak256(IMatch(matches[_matchId]).getPlayer1())
        ) {
            IMatch(matches[_matchId]).votePlayer1(_sender, _amount);
        } else {
            IMatch(matches[_matchId]).votePlayer2(_sender, _amount);
        }
        emit VoteInPlayerMatch(_matchId, _nftContract, _tokenId, _amount);
    }

    // Function to apply 0.5% tax and the percentage to the jackpot at the end of a round
    // the function also checks if it's the last round and applies the value for public goods
    function applyJackpot(uint256 _pot, bytes memory _tVar)
        public
        view
        onlyOwner
        returns (uint256, bytes memory)
    {
        if (msg.sender != address(tournament))
            revert SenderIsNotTheOwner(msg.sender);
        uint256 _fee = (_pot * 5) / 1000;
        uint256 _jackpot;
        uint256 _publicGoods;
        (
            uint256 fee_,
            uint256 round_,
            uint256 numRounds_,
            uint256 jackpot_,
            uint256 publicGoods_,
            uint256 jackpotPerc_,
            uint256 publicGoodsPerc_
        ) = abi.decode(
                _tVar,
                (uint256, uint256, uint256, uint256, uint256, uint256, uint256)
            );

        fee_ += _fee;
        _pot -= _pot - _fee;

        if (round_ < numRounds_) {
            _jackpot = (_pot * jackpotPerc_) / 100;
            _pot -= _jackpot;
            jackpot_ += _jackpot;
        } else {
            _fee = (jackpot_ * 2) / 100;
            fee_ += _fee;
            jackpot_ -= _fee;

            _publicGoods = (jackpot_ * publicGoodsPerc_) / 100;
            publicGoods_ += _publicGoods;
            jackpot_ -= _publicGoods;
            _pot += jackpot_;
        }

        return (
            _pot,
            abi.encode(
                fee_,
                round_,
                numRounds_,
                jackpot_,
                publicGoods_,
                jackpotPerc_,
                publicGoodsPerc_
            )
        );
    }

    // End round
    function endRound(uint256 _now)
        public
        onlyOwner
        returns (uint256[] memory, bool, bytes memory)
    {
        if (roundEnd < _now) revert RoundNotFinished();

        uint256 len = matches.length;
        IMatch MatchInterface;
        bool _draw = false;
        uint256 _pot;
        (uint256 _a,uint256 _b,uint256 _c,uint256 _d,uint256 _e,uint256 _f,uint256 _g) = tournament.getVariables();
        bytes memory _tVar = abi.encode( _a, _b, _c, _d, _e, _f, _g);

        for (uint256 i = 0; i < len; i++) {
            MatchInterface = IMatch(matches[i]);
            if (MatchInterface.setWinner() == false) _draw = true;
        }
        if (_draw) {
            roundEnd += minutesOnDraw;
            return (winners, _draw, _tVar);
        }

        for (uint256 i = 0; i < len; i++) {
            MatchInterface = IMatch(matches[i]);
            if (!MatchInterface.getFinished()) {
                uint256 randomWinner = uint256(
                    keccak256(
                        abi.encodePacked(block.difficulty, block.timestamp)
                    )
                ) % 2;
                if (randomWinner == 1) {
                    winners.push(
                        tournament.getPlayerId(MatchInterface.getPlayer1())
                    );
                    (_pot, _tVar) = applyJackpot(MatchInterface.votesPlayer2(), _tVar);
                } else {
                    winners.push(
                        tournament.getPlayerId(MatchInterface.getPlayer2())
                    );
                    (_pot, _tVar) = applyJackpot(MatchInterface.votesPlayer1(), _tVar);
                }
            } else if (
                (MatchInterface.votesPlayer1() >
                    MatchInterface.votesPlayer2()) &&
                !MatchInterface.getFinished()
            ) {
                winners.push(
                    tournament.getPlayerId(MatchInterface.getPlayer1())
                );
                (_pot, _tVar) = applyJackpot(MatchInterface.votesPlayer2(), _tVar);
            } else {
                winners.push(
                    tournament.getPlayerId(MatchInterface.getPlayer2())
                );
                (_pot, _tVar) = applyJackpot(MatchInterface.votesPlayer1(), _tVar);
            }
            MatchInterface.setPot(_pot);
        }
        emit RoundEnded(roundNumber);
        return (winners, _draw, _tVar);
    }

    // returning winners
    function getWinners() public view returns (uint256[] memory) {
        return winners;
    }

    // returning matches number
    function getMatchesQty() public view returns (uint256) {
        return matches.length;
    }

    // withdraw tribeTokens
    function withdrawTokens(address _sender, uint256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        return tribeToken.transfer(_sender, _amount);
    }
}

// File: contracts/RoundGenerator.sol


pragma solidity ^0.8.9;




contract RoundGenerator is Ownable, IRoundGenerator{
    constructor(address _tribeToken, address _tournamentGenerator) {
        if(_tribeToken == address(0)) revert TribeTokenInvalid(_tribeToken);

        transferOwnership(_tournamentGenerator);
    }

    address[] internal rounds;
    
    function createRound(
        bytes memory _players,
        uint256 _roundStart,
        uint256 _roundDuration,
        uint256 _minutesOnDraw,
        bool _instantStart,
        address _tournament,
        address _tribeToken
    ) public onlyOwner returns (address) {
        // Create new tournament
        Round t = new Round( _players, _roundStart, _roundDuration, _minutesOnDraw, _instantStart, _tournament, _tribeToken );
        address roundAddress = address(t);
        rounds.push(roundAddress);
        
        // Emit event
        emit RoundCreated(roundAddress);
        
        // Return address
        return roundAddress;
    }
}