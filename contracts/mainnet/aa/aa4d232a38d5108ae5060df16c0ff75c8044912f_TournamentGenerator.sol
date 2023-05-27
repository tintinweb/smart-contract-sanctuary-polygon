/**
 *Submitted for verification at polygonscan.com on 2023-05-27
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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

// File: contracts/Tournament.sol


pragma solidity ^0.8.9;









contract Tournament is ITournament {
    // variables
    StateTournament public tournamentStatus;
    FeesClaimed private claimed;
    ITournamentHub private tournamentHub;

    uint256 public startTime; // it will be 0 if the Tournament doen't have a Start Date
    uint256 public override endTime;
    uint256 public override roundDuration; // duration of each round
    uint256 public override roundInterval; // interval between rounds
    uint256 public minutesOnDraw; // how many minutes will be added on Draw
    uint256 public maxPlayers;
    uint256 public override totalVoted;

    uint256 public override round; // current round
    uint256 public override numRounds; // number of rounds

    uint256 public override jackpot; //jackpot for the last round
    uint256 public override publicGoods; // value of Public Goods for this tournament
    uint256 public override fee; //fee taken 0.5% at each round from loosers and 2% of final jackpot
    uint256 public override jackpotPerc; //percentage of loosers that goes to jackpot each round
    uint256 public override publicGoodsPerc; //percentage of jackpot that goes to publicGoods each round

    IERC20 internal tribeToken;

    // lists and mappings
    address[] public override getRound;
    bytes[] public override getPlayer;

    mapping(bytes => address) public override getNftOwner; // says who's the owner of the NFT. It changes on match result
    mapping(bytes => bool) public override getNftUnlocked;
    mapping(bytes => uint256) public override getPlayerId;
    mapping(uint256 => uint256) public override totalVotes; // takes the total votes for a player on the tournament

    /**
     * @dev Constructor for the Tournament contract
     * @param _startTime is the time in timestamp milisseconds
     * @param _numRounds is the number of rounds
     * @param _roundDuration is the duration of each round in milisseconds
     * @param _roundInterval is the interval between rounds in milisseconds
     * @param _minutesOnDraw is the number of minutes added to the round duration when a draw happens
     * @param _jackpotPerc is the percentage of the match pot that goes to the jackpot
     * @param _publicGoodsPerc is the percentage of the jackpot that goes to public goods
     * @param _tournamentHub is the address of the TournamentHub contract
     */
    constructor(
        uint256 _startTime,
        uint256 _numRounds,
        uint256 _roundDuration,
        uint256 _roundInterval,
        uint256 _minutesOnDraw,
        uint256 _jackpotPerc,
        uint256 _publicGoodsPerc,
        address _tournamentHub
    ) {
        if (jackpotPerc > 100) jackpotPerc = 100;
        else jackpotPerc = _jackpotPerc;

        startTime = _startTime;
        endTime =
            _startTime +
            (_numRounds * _roundDuration) +
            ((_numRounds - 1) * _roundInterval);
        maxPlayers = 2**_numRounds;
        roundDuration = _roundDuration;
        tournamentStatus = StateTournament.Waiting;
        claimed = FeesClaimed.NotClaimed;
        numRounds = _numRounds;
        roundInterval = _roundInterval;
        round = 1;
        totalVoted = 0;
        jackpot = 0;
        fee = 0;
        publicGoods = 0;
        tournamentHub = ITournamentHub(_tournamentHub);

        // Public Goods needs to be at least 1%
        if (_publicGoodsPerc == 0) publicGoodsPerc = 1;
        else if (publicGoodsPerc > 100) publicGoodsPerc = 100;
        else publicGoodsPerc = _publicGoodsPerc;

        tribeToken = IERC20(tournamentHub.tribeXToken());
        minutesOnDraw = _minutesOnDraw;
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
     * @dev Throws if called by any account other than project contracts.
     */
    modifier onlyProject() {
        //Check authorization
        require(tournamentHub.checkProject(msg.sender), "T-02");
        _;
    }

    ///////////////////////////////// Tournament and round management

    /**
     * @dev Starts the tournament
     */
    function startTournament() public onlyAdministrator {
        require(tournamentStatus == StateTournament.Waiting, "T-08");

        // checks if the maximum number of players is not reached
        if (getPlayer.length < maxPlayers) {
            cancelTournament();
            return;
        } 

        IRoundGenerator _roundGenerator = IRoundGenerator(
            tournamentHub.roundGenerator()
        );
        address _roundContract = _roundGenerator.createRound(
            abi.encode(tournamentHub.retrieveRandomArray(maxPlayers)),
            startTime,
            roundDuration,
            minutesOnDraw,
            true,
            address(this)
        );
        getRound.push(_roundContract);
        //IRound(_roundContract).createMatches();
        emit RoundStarted(round);

        tournamentStatus = StateTournament.Started;
        emit StartTournamentEvent();
    }

    /**
     * @dev Ends the tournament
     */
    function cancelTournament() public onlyAdministrator {
        require(tournamentStatus == StateTournament.Waiting, "T-08");
        tournamentStatus = StateTournament.Canceled;
        tournamentHub.removeOnGoing(address(this));

        emit EndTournamentEvent();
    }

    /**
     * @dev Starts a round
     */
    function startRound() public onlyAdministrator {
        IRound(getRound[round - 1]).startRound();

        emit RoundStarted(round);
    }

    /**
     * @dev Ends a round
     * @return true if the round is ended, false if the round is not ended
     */
    function endRound() public onlyAdministrator returns (bool) {
        IRound _actualRound = IRound(getRound[round - 1]);
        bool _ended = _actualRound.endRound();
        if (!_ended) {
            endTime += minutesOnDraw;
            return false;
        }

        if (round == numRounds) {
            tournamentHub.removeOnGoing(address(this));
            (, , address _lastMatch) = abi.decode(
                _actualRound.matchesEncoded(0),
                (bytes, bytes, address)
            );

            getNftUnlocked[IMatch(_lastMatch).getWinner()] = true;
            tournamentStatus = StateTournament.Finished;

            emit EndTournamentEvent();
        } else round++;

        emit RoundEnded(round);
        return true;
    }

    /**
     * @dev Adds minutes on draw
     */
    function setDraw() public onlyProject {
        endTime += minutesOnDraw;
    }

    /**
     * @dev Updates some variables of the tournament
     * @param _tFee is the fee of the tournament
     * @param _tJackpot is the jackpot of the tournament
     * @param _tPublicGoods is the public goods of the tournament
     */
    function setVariables(
        uint256 _tFee,
        uint256 _tJackpot,
        uint256 _tPublicGoods
    ) public onlyProject {
        fee = _tFee;
        jackpot = _tJackpot;
        publicGoods = _tPublicGoods;
    }

    ///////////////////////////////// NFT and token deposits

    /**
     * @dev ERC721Receiver interface
     * Default function to handle NFTs
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @dev Adds a round to the tournament
     * @param _contract is the address of the round contract
     */
    function addRound(address _contract) public onlyProject {
        getRound.push(_contract);
    }

    /**
     * @dev Deposits an NFT to the tournament
     * @param _tokenId is the id of the NFT
     * @param _nftContract is the address of the NFT contract
     */
    function depositNFT(uint256 _tokenId, address _nftContract)
        public
        returns (
            uint256,
            address,
            uint256
        )
    {
        // checks if the deposit time is in the allowed timeframe
        require(tournamentStatus == StateTournament.Waiting, "T-03");
        require(getPlayer.length < maxPlayers, "T-04");

        // adds the player to the list of players
        bytes memory encodedNft = abi.encode(_nftContract, _tokenId);
        getNftOwner[encodedNft] = msg.sender;

        // adds the tokenId to the list of deposited NFTs and transfers the NFT to the contract
        getPlayer.push(encodedNft);
        getPlayerId[encodedNft] = getPlayer.length - 1;

        IERC721 nftCollection = IERC721(_nftContract);
        nftCollection.safeTransferFrom(msg.sender, address(this), _tokenId);

        // verify if the Tournament have a start date
        // if it's 0, so the tournament starts right in the moment
        if ((getPlayer.length == maxPlayers) && (startTime == 0)) {
            startTime = block.timestamp;
            endTime =
                startTime +
                (numRounds * roundDuration) +
                ((numRounds - 1) * roundInterval);
            startTournament();
        }
        emit DepositNFTEvent(getPlayer.length - 1, msg.sender, _tokenId);
        return (getPlayer.length - 1, msg.sender, _tokenId);
    }

    /**
     * @dev Returns the number of players in the tournament
     * @param _amount the amount of tokens to be added to the jackpot
     * @return jackpot the amount of tokens in jackpot
     */
    function increaseJackpot(uint256 _amount)
        public
        onlyAdministrator
        returns (uint256)
    {
        tribeToken.transferFrom(msg.sender, address(this), _amount);

        jackpot += _amount;
        emit jackpotIncreased(_amount);
        return jackpot;
    }

    /**
     * @dev Vote for a match
     * @param _matchId is the id of the match
     * @param _nftAddress is the address of the NFT contract
     * @param _tokenId is the id of the NFT
     * @param _amount is the amount of tokens to be used for voting
     * @return the amount of tokens used for voting
     */
    function vote(
        uint256 _matchId,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _amount
    ) public returns (uint256) {
        IRound _actualRound = IRound(getRound[round - 1]);
        address _matchAddress = _actualRound.getMatch(_matchId);

        _actualRound.validateVote(_matchAddress);

        IMatch MatchInterface = IMatch(_matchAddress);
        bytes memory encodedNft = abi.encode(_nftAddress, _tokenId);
        uint8 _playerInMatch;

        if (keccak256(encodedNft) == keccak256(MatchInterface.getPlayer1()))
            _playerInMatch = 1;
        else if (
            keccak256(encodedNft) == keccak256(MatchInterface.getPlayer2())
        ) _playerInMatch = 2;
        else return 0;

        tribeToken.transferFrom(msg.sender, address(this), _amount);
        MatchInterface.votePlayer(msg.sender, _playerInMatch, _amount);

        totalVoted += _amount;
        _actualRound.addVotes(_amount);

        emit VoteInPlayerMatch(round, _matchId, _amount);
        return _amount;
    }

    /////////////////////////////////  NFT and Tokens claim management

    /**
     * @dev Changes the owner of an NFT
     * @param _playerId is the id of the player
     * @param _newPlayerId is the id of the new player
     */
    function changeNftOwner(uint256 _playerId, uint256 _newPlayerId)
        public
        onlyProject
    {
        getNftOwner[getPlayer[_playerId]] = getNftOwner[
            getPlayer[_newPlayerId]
        ];
        getNftUnlocked[getPlayer[_playerId]] = true;
        emit OwnerOfNftChanged(_playerId, _newPlayerId);
    }

    /**
     * @dev Claim tokens from a match
     * @param _sender is the address of the sender
     * @param _total is the amount of tokens to be claimed
     */
    function claimTokens(address _sender, uint256 _total) public onlyProject {
        tribeToken.transfer(_sender, _total);
    }

    /**
     * @dev Claims an NFT from the tournament
     * @param _sender is the address of the player
     * @param _tokenId is the id of the NFT
     * @param _nftContract is the address of the NFT contract
     */
    function claimNFT(
        address _sender,
        address _nftContract,
        uint256 _tokenId
    ) public onlyProject {
        IERC721 nftCollection = IERC721(_nftContract);
        nftCollection.safeTransferFrom(address(this), _sender, _tokenId);
        emit WithdrawNFTEvent(_sender, _nftContract, _tokenId);
    }

    /**
     * @dev Claims the public goods and fees to project wallet
     */
    function claimPublicGoods() public onlyAdministrator {
        require(tournamentStatus == StateTournament.Finished, "T-15");
        require(claimed == FeesClaimed.NotClaimed, "T-07");
        IRound _actualRound = IRound(getRound[round - 1]);
        uint256 _lastRoundVotes = _actualRound.totalVoted();

        uint256 _balance = tribeToken.balanceOf(address(this));

        if(_lastRoundVotes==0) tribeToken.transfer(tournamentHub.jackpotWallet(), jackpot);

        tribeToken.transfer(tournamentHub.feeWallet(), fee);
        _balance -= fee;
        if (_balance < publicGoods) publicGoods = _balance;

        tribeToken.transfer(tournamentHub.publicGoodsWallet(), publicGoods);

        claimed = FeesClaimed.Claimed;
        emit PublicGoodsClaimed();
    }

    //////////////////////////// View functions

    /**
     * @dev Returns the matches of a round
     * @param _round is the number of the round
     * @return the matches of the round
     */
    function getMatches(uint256 _round) public view returns (bytes[] memory) {
        return IRound(getRound[_round - 1]).getMatchesEncoded();
    }

    /**
     * @dev Returns if the round is started
     * @return true if the round is started, false if the round is not started
     */
    function getRoundStart() public view returns (uint256) {
        return IRound(getRound[round - 1]).roundStart();
    }

    /**
     * @dev Returns if the round is ended
     * @return true if the round is ended, false if the round is not ended
     */
    function getRoundEnd() public view returns (uint256) {
        return IRound(getRound[round - 1]).roundEnd();
    }

    /**
     * @dev Returns the active players of a round
     * @param _round is the number of the round
     * @return array of active players Ids
     */
    function getPlayers(uint256 _round) public view returns (uint256[] memory) {
        return IRound(getRound[_round - 1]).getPlayers();
    }

    /**
     * @dev Returns the number of deposited NFTs
     * @return 0 for Waiting, 1 for Started and 2 for Finished
     */
    function getTournamentStatus() public view returns (uint8) {
        return uint8(tournamentStatus);
    }

    /**
     * @dev Returns the number of deposited NFTs
     * @return number of deposited NFTs
     */
    function depositedLength() public view returns (uint256) {
        return getPlayer.length;
    }
}

// File: contracts/interfaces/ITournamentGenerator.sol


pragma solidity ^0.8.9;

// Interface
interface ITournamentGenerator {
    event TournamentCreated(address);
    event TournamentHubChanged(address);

    function createTournament(
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external returns (address);

    function changeTournamentHub(address) external;
}

// File: contracts/TournamentGenerator.sol


pragma solidity ^0.8.9;





contract TournamentGenerator is ITournamentGenerator {
    ITournamentHub private tournamentHub;
    address[] public tournaments;
    bool public activated;
    address private deployer;

    constructor() {
        deployer = msg.sender;
    }

    /**
     * @dev Generates a new Tournament Contract.
     * @param _startTime Timestamp of the start of the tournament
     * @param _numRounds Number of rounds in the tournament
     * @param _roundDuration Duration of each round in timestamp milliseconds
     * @param _roundInterval Interval between rounds in timestamp milliseconds
     * @param _minutesOnDraw Minutes to add on match draw
     * @param _jackpotPerc Percentage of the jackpot
     * @param _publicGoodsPerc Percentage of the jackpot that goes to public goods
     * @return address of the new Tournament contract
     */
    function createTournament(
        uint256 _startTime,
        uint256 _numRounds,
        uint256 _roundDuration,
        uint256 _roundInterval,
        uint256 _minutesOnDraw,
        uint256 _jackpotPerc,
        uint256 _publicGoodsPerc
    ) public returns (address) {
        //Check if activated
        require(activated, "TG-01");
        //Check authorization
        require(tournamentHub.checkAdmin(msg.sender), "TG-02");

        if (_minutesOnDraw < 5) _minutesOnDraw = 5;
        if (_numRounds == 0) _numRounds = 1;
        if (_roundDuration == 0) _roundDuration = 21600000;
        if (_roundInterval == 0) _roundInterval = 21600000;

        // Create new tournament
        Tournament t = new Tournament(
            _startTime,
            _numRounds,
            _roundDuration,
            _roundInterval,
            _minutesOnDraw,
            _jackpotPerc,
            _publicGoodsPerc,
            address(tournamentHub)
        );
        address tournamentAddress = address(t);
        tournaments.push(tournamentAddress);
        tournamentHub.addContract(tournamentAddress);
        tournamentHub.addOnGoing(tournamentAddress);

        // Emit event
        emit TournamentCreated(tournamentAddress);

        // Return address
        return tournamentAddress;
    }

    /**
     * @dev Changes Tournament Hub contract and activates Generator
     * @param _contract Address of the new Tournament Hub contract
     */
    function changeTournamentHub(address _contract) public {
        // Check Permissions
        if (activated) require(tournamentHub.checkAdmin(msg.sender), "TG-02");
        else require(deployer == msg.sender, "TG-04");

        tournamentHub = ITournamentHub(_contract);
        activated = true;
        emit TournamentHubChanged(_contract);
    }
}