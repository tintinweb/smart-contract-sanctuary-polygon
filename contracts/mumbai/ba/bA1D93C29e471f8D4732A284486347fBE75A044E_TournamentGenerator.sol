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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// File: contracts/access/Administrable.sol


pragma solidity ^0.8.9;


error NotAbleToDeposit();
error IsAlreadyAdministrator();
error IsNotAdministrator();
error IsOwner();

contract Administrable is Ownable {
    mapping(address => bool) private administrators;

    /**
     * @dev Constructor adds Owner as Administrator.
     */
    constructor() {
        administrators[msg.sender] = true;
    }

    /**
     * @dev Adds address newAdm on administrators mapping (if it's not already there).
     */
    function addAdministrator(address newAdm) public onlyOwner {
        if (administrators[newAdm]) revert IsAlreadyAdministrator();
        administrators[newAdm] = true;
    }

    /**
     * @dev Delete address oldAdm from administrators mapping. Owner is able to remove himself from Administrators. Use with caution.
     */
    function removeAdministrator(address oldAdm) public onlyOwner {
        if (!administrators[oldAdm]) revert IsNotAdministrator();

        delete administrators[oldAdm];
    }

    /**
     * @dev Throws if the sender is not administrator.
     */
    function _checkAdministrator() internal view virtual {
        if (!administrators[msg.sender]) revert IsNotAdministrator();
    }

    /**
     * @dev Throws if the sender is not administrator.
     */
    function checkIsAdministrator(address _address) public view returns(bool) {
        return administrators[_address];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyAdministrator() {
        _checkAdministrator();
        _;
    }
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

// File: contracts/Tournament.sol


pragma solidity ^0.8.9;








contract Tournament is ITournament {
    // States of the tournament
    enum StateTournament {
        Waiting,
        Started,
        Finished
    }
    StateTournament public tournamentStatus;

    // variables
    uint256 public startTime; // it will be 0 if the Tournament doen't have a Start Date
    uint256 public endTime;
    uint256 public roundDuration; // duration of each round
    uint256 public roundInterval; // interval between rounds
    uint256 public minutesOnDraw; // how many minutes will be added on Draw
    uint256 public maxPlayers;
    address private roundGenerator;
    address private tournamentGenerator;

    uint256 internal round; // current round
    uint256 public numRounds; // number of rounds

    uint256 internal jackpot; //jackpot for the last round
    uint256 internal publicGoods; // value of Public Goods for this tournament
    uint256 internal fee; //fee taken 0.5% at each round from loosers and 2% of final jackpot
    uint256 public jackpotPerc; //percentage of loosers that goes to jackpot each round
    uint256 public publicGoodsPerc; //percentage of jackpot that goes to publicGoods each round

    IERC20 internal tribeToken;

    uint256[] internal temp;

    // lists and mappings
    address[] public rounds;
    bytes[] public depositedNFTs;

    mapping(bytes => address) internal players; // says who's the owner of the NFT. It changes on match result
    mapping(bytes => uint256) internal depositedNftsIds;

    // constructor
    constructor(
        uint256 _startTime,
        uint256 _numRounds,
        uint256 _roundDuration,
        uint256 _roundInterval,
        uint256 _minutesOnDraw,
        uint256 _jackpotPerc,
        uint256 _publicGoodsPerc,
        address _tribeToken,
        address _roundGenerator
    ) {
        if (jackpotPerc > 100) revert JackpotPercentageMoreThan100();

        startTime = _startTime;
        endTime =
            _startTime +
            (_numRounds * _roundDuration) +
            ((_numRounds - 1) * _roundInterval);
        maxPlayers = 2**_numRounds;
        roundDuration = _roundDuration;
        tournamentStatus = StateTournament.Waiting;
        numRounds = _numRounds;
        roundInterval = _roundInterval;
        round = 1;
        jackpot = 0;
        fee = 0;
        // Public Goods needs to be at least 1%
        if (_publicGoodsPerc == 0) publicGoodsPerc = _publicGoodsPerc;
        else publicGoodsPerc = 1;

        jackpotPerc = _jackpotPerc;
        tribeToken = IERC20(_tribeToken);
        minutesOnDraw = _minutesOnDraw * 60 * 1000;
        tournamentGenerator = msg.sender;
        roundGenerator = _roundGenerator;
    }

    ///////////////////////////////// NFT
    // deposit function
    function depositNFT(uint256 _tokenId, address _nftContract) public {
        // checks if the deposit time is in the allowed timeframe
        if (tournamentStatus != StateTournament.Waiting)
            revert TournamentNotOpenToNewParticipants();

        if (depositedNFTs.length >= maxPlayers)
            revert MaximumNumberOfPlayersReached();

        //check if player is owner of the NFT
        IERC721 nftCollection = IERC721(_nftContract);
        if (nftCollection.ownerOf(_tokenId) != msg.sender)
            revert SenderNotOwnerOfNFT();

        //checks if the token is approved for depositing
        if (nftCollection.getApproved(_tokenId) != address(this))
            revert ContractNotApprovedToMoveNFT();

        // adds the player to the list of players
        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);
        players[encodedNft] = msg.sender;

        // adds the tokenId to the list of deposited NFTs and transfers the NFT to the contract
        depositedNFTs.push(encodedNft);
        depositedNftsIds[encodedNft] = depositedNFTs.length - 1;

        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        // verify if the Tournament have a start date
        if (startTime == 0) {
            startTournament(block.timestamp);
        }
        emit DepositNFTEvent(msg.sender, _tokenId);
    }

    // withdraw NFT function
    function withdrawNFT(uint256 _tokenId, address _nftContract) public {
        // checks if the tournament has ended
        if (tournamentStatus != StateTournament.Finished)
            revert TournamentNotEnded();

        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);

        // checks if the NFT is on the Tournament
        if (players[encodedNft] == address(0)) revert NFTNotOnTournament();

        IERC721 nftCollection = IERC721(_nftContract);
        // checks if the NFT is on the Tournament
        if (nftCollection.ownerOf(_tokenId) == address(this))
            revert ActualOwnerHasTakenNFT();

        // checks if the player is the owner of the NFT
        if (players[encodedNft] != msg.sender) revert PlayerNotOwnerOfNFT();

        // sends the NFT to the player
        nftCollection.safeTransferFrom(address(this), msg.sender, _tokenId);

        // removes the tokenId from the list of deposited NFTs
        emit WithdrawNFTEvent(msg.sender, _nftContract, _tokenId);
    }

    ///////////////////////////////// TOURNAMENT

    // start function
    function startTournament(uint256 _now) public {
        if(msg.sender != tournamentGenerator) revert SenderIsNotTheOwner(msg.sender);
        //checks if now is the time to start the tournament
        if ((startTime != 0) && (_now < startTime))
            revert TournamentNotInStartTime();
        tournamentStatus = StateTournament.Started;
        // checks if the maximum number of players is not reached
        if (depositedNFTs.length < maxPlayers) {
            tournamentStatus = StateTournament.Finished;
        } else {
            startRound(_now);
        }
        emit StartTournamentEvent(_now);
    }

    // end Tournament
    function endTournament(uint256 _now) public {
        if(msg.sender != tournamentGenerator) revert SenderIsNotTheOwner(msg.sender);
        // Check if the tournament has started
        if (tournamentStatus != StateTournament.Started)
            revert TournamentYetNotStarted();
        tournamentStatus = StateTournament.Finished;
        emit EndTournamentEvent(_now);
    }

    /////////////////////////////////  MATCHES

    // Start round
    function startRound(uint256 _now) public {
        if(msg.sender != tournamentGenerator) revert SenderIsNotTheOwner(msg.sender);
        if (tournamentStatus == StateTournament.Finished)
            revert TournamentAlreadyFinished();

        uint256 _roundStart = startTime +
            ((round - 2) * roundDuration) +
            (roundInterval * round);
        if (round == 1) _roundStart = startTime;
        else
            _roundStart =
                startTime +
                ((round - 2) * roundDuration) +
                (roundInterval * (round - 1));

        if (_roundStart < _now) revert RoundNotInStartTime();

        bytes memory _players;
        uint256[] memory _tempPlayers;
        temp = _tempPlayers;

        if(round==1){
            for(uint i=0; i>depositedNFTs.length; i++){
                temp.push(depositedNftsIds[depositedNFTs[i]]);
            }
            _players = abi.encode(temp);
            address _roundContract = IRoundGenerator(roundGenerator).createRound(
                _players, _roundStart, roundDuration, minutesOnDraw, true, address(this), address(tribeToken)
            );
            rounds.push(address(_roundContract));
        }
        else{
            IRound _prevRound = IRound(rounds[round-1]);
            if (_prevRound.getStarted()) revert RoundAlreadyStarted();
            _prevRound.startRound();
        }
        emit RoundStarted(round);
    }

    // Voting function
    function vote(
        uint256 _matchId,
        address _nftContract,
        uint256 _tokenId,
        uint256 _amount
    ) public {
        IRound _actualRound = IRound(rounds[round-1]);
        if (_actualRound.getMatch(_matchId) == address(0)) revert MatchIdNotFound();
        if (_actualRound.getMatchFinished(_matchId)) revert MatchAlreadyFinished();

        if (tournamentStatus == StateTournament.Finished)
            revert TournamentAlreadyFinished();

        _actualRound.vote(_matchId, _nftContract, _tokenId, _amount, msg.sender);

        emit VoteInPlayerMatch(round, _matchId, _nftContract, _tokenId, _amount);
    }

    // End round
    function endRound(uint256 _now) public returns(bool){
        if(msg.sender != tournamentGenerator) revert SenderIsNotTheOwner(msg.sender);
        bytes memory _players;
        bytes memory _tVar;
        bool _draw;
        uint256[] memory _winners;
        IRound _actualRound = IRound(rounds[round-1]);
        IMatch MatchInterface;

        uint256 _roundStart = _now + roundInterval;

        (_winners, _draw, _tVar) = _actualRound.endRound(_now);
        if(_draw) {
            endTime += minutesOnDraw;
            return false;
        }

        for (uint256 i = 0; i > _actualRound.getMatchesQty(); i++) {
            MatchInterface = IMatch(_actualRound.getMatch(i));

            if (
                keccak256(MatchInterface.getWinner()) ==
                keccak256(MatchInterface.getPlayer1())
            ) {
                players[MatchInterface.getPlayer2()] = players[
                    MatchInterface.getPlayer1()
                ];
            } else {
                players[MatchInterface.getPlayer1()] = players[
                    MatchInterface.getPlayer2()
                ];
            }
        }

        (fee,,,jackpot,publicGoods,,) = abi.decode(_tVar, (uint256,uint256,uint256,uint256,uint256,uint256,uint256));
        
        if (round == numRounds) {
            endTournament(_now);
        }else{
            _players = abi.encode(_winners);
            address _roundContract = IRoundGenerator(roundGenerator).createRound(
                _players, _roundStart, roundDuration, minutesOnDraw, false, address(this), address(tribeToken)
            );
            rounds.push(address(_roundContract));
        }
        emit RoundEnded(round);
        round++;
        return true;
    }

    // Claiming tokens from Match
    function claimFromMatch(uint256 _matchId, uint256 _roundId) public {
        IRound _round = IRound(rounds[_roundId]);
        IMatch MatchInterface = IMatch(_round.getMatch(_matchId));
        uint256 _winnerPot;
        uint256 _support;
        if (!_round.getFinished()) revert RoundNotFinished();
        if (MatchInterface.getWithdrawalSupporter(msg.sender)) revert AlreadySubmittedWithdrawal();

        if (
            keccak256(MatchInterface.getWinner()) ==
            keccak256(MatchInterface.getPlayer1())
        ) {
            _winnerPot = MatchInterface.votesPlayer1();
            _support = MatchInterface.supporterForPlayer1(msg.sender);
        } else {
            _winnerPot = MatchInterface.votesPlayer2();
            _support = MatchInterface.supporterForPlayer2(msg.sender);
        }
        if(_support == 0) revert YouDidNotGiveYourSupport(msg.sender);

        // calculate the amount of tokens to be withdrawn
        uint256 total = _support +
            ((_support / _winnerPot) * MatchInterface.getPot());

        // transfer total tokens to msg.sender
        if(!_round.withdrawTokens(msg.sender, total)) revert ProblemOnWithdrawTokens();

        // set wallet as withdrawal submitted getWithdrawalSupporter(address _supporter)
        MatchInterface.setWithdrawalSupporter(msg.sender);

        // emit event and log
        emit WithdrawEvent(msg.sender, total);
    }

    //////////////////////////// VIEW FUNCTIONS

    // decode depositedNFTs
    function decodeNFT(uint256 _index) private view returns (address, uint256) {
        address _nftContract;
        uint256 _tokenId;
        (_nftContract, _tokenId) = abi.decode(
            depositedNFTs[_index],
            (address, uint256)
        );
        return (_nftContract, _tokenId);
    }

    // function to return the player able to withdraw the NFT at the end of the Tournament
    function getNftOwner(uint256 _tokenId, address _nftContract)
        public
        view
        returns (address)
    {
        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);
        return players[encodedNft];
    }

    // returns the actual player based on its IDs
    function getPlayer(uint _id) public view returns(bytes memory){
        return depositedNFTs[_id];
    }

    // returns the actual player based on its IDs
    function getPlayerId(bytes memory _player) public view returns(uint){
        return depositedNftsIds[_player];
    }

    // get prizes related variables for the tournament
    function getVariables() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        return (fee,round,numRounds,jackpot,publicGoods,jackpotPerc,publicGoodsPerc);
    }
}

// File: contracts/interfaces/ITournamentGenerator.sol


pragma solidity ^0.8.9;

error InvalidTribeToken(address _tribeToken);
// Interface
interface ITournamentGenerator {
    event TournamentCreated(address _contract);
    event RoundGeneratorAdded(address _contract);
    event TournamentStarted(address _tournament);
    event TournamentFinished(address _tournament);
    event TournamentRoundStarted(address _tournament);
    event TournamentRoundFinished(address _tournament);

    function createTournament(
        uint256 _startTime,
        uint256 _numRounds,
        uint256 _roundDuration,
        uint256 _roundInterval,
        uint256 _minutesOnDraw,
        uint256 _jackpotPerc,
        uint256 _publicGoodsPerc
    ) external returns (address);

    function changeRoundGenerator(address _contract) external;

    //start a tournament 
    function startTournament(uint256 _now, address _tournament) external;

    //end a tournament 
    function endTournament(uint256 _now, address _tournament) external;

    //start actual round in a tournament 
    function startRound(uint256 _now, address _tournament) external;

    //end actual round in a tournament 
    function endRound(uint256 _now, address _tournament) external;
}

// File: contracts/TournamentGenerator.sol


pragma solidity ^0.8.9;





contract TournamentGenerator is Administrable, ITournamentGenerator {
    constructor(address _tribeToken) {
        if (_tribeToken == address(0)) revert InvalidTribeToken(_tribeToken);
        tribeToken = _tribeToken;
    }

    address tribeToken;
    address[] internal tournaments;
    address roundGenerator;

    function createTournament(
        uint256 _startTime,
        uint256 _numRounds,
        uint256 _roundDuration,
        uint256 _roundInterval,
        uint256 _minutesOnDraw,
        uint256 _jackpotPerc,
        uint256 _publicGoodsPerc
    ) public onlyAdministrator returns (address) {
        // Validate inputs
        require(_startTime > 0, "Start time must be greater than 0"); //
        require(_numRounds > 0, "Number of rounds must be greater than 0"); //
        require(_roundDuration > 0, "Round duration must be greater than 0"); //
        require(_roundInterval > 0, "Round interval must be greater than 0"); //
        require(_minutesOnDraw > 0, "Minutes on draw must be greater than 0"); //
        require( _jackpotPerc > 0 && _jackpotPerc <= 100, "Jackpot percentage must be greater than 0 and less than or equal to 100" ); //
        require( _publicGoodsPerc > 0 && _publicGoodsPerc <= 100, "Public goods percentage must be greater than 0 and less than or equal to 100" );

        // Create new tournament
        Tournament t = new Tournament(
            _startTime,
            _numRounds,
            _roundDuration,
            _roundInterval,
            _minutesOnDraw,
            _jackpotPerc,
            _publicGoodsPerc,
            tribeToken,
            roundGenerator
        );
        address tournamentAddress = address(t);
        tournaments.push(tournamentAddress);

        // Emit event
        emit TournamentCreated(tournamentAddress);

        // Return address
        return tournamentAddress;
    }

    // input the Round Generator contract
    function changeRoundGenerator(address _contract) public onlyAdministrator {
        roundGenerator = _contract;
        emit RoundGeneratorAdded(_contract);
    }

    //start a tournament 
    function startTournament(uint256 _now, address _tournament) public onlyAdministrator{
        ITournament(_tournament).startTournament(_now);
        emit TournamentStarted(_tournament);
    }

    //end a tournament 
    function endTournament(uint256 _now, address _tournament) public onlyAdministrator{
        ITournament(_tournament).endTournament(_now);
        emit TournamentFinished(_tournament);
    }

    //start actual round in a tournament 
    function startRound(uint256 _now, address _tournament) public onlyAdministrator{
        ITournament(_tournament).startRound(_now);
        emit TournamentRoundStarted(_tournament);
    }

    //end actual round in a tournament 
    function endRound(uint256 _now, address _tournament) public onlyAdministrator{
        ITournament(_tournament).endRound(_now);
        emit TournamentRoundFinished(_tournament);
    }
}