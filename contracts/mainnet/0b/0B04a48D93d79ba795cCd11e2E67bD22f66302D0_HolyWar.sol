// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./GameManager.sol";
import "./VRFManager.sol";
import "./TreasuryManager.sol";

contract HolyWar is
    AccessControlEnumerable,
    GameManager,
    VRFManager,
    TreasuryManager,
    ERC2771Context
{
    bytes32 public constant GAME_MANAGER_ROLE = keccak256("GAME_MANAGER_ROLE");

    mapping(uint256 => uint256) public gameByRequestId;

    event GameCreated(
        uint256 indexed _gameId,
        address indexed _player,
        address _tokenContract, 
        uint256 _ante
    );

    event ConfrontationDetected(uint256 indexed _gameId, uint256[] cards);

    event PlayerWins(
        uint256 indexed _gameId,
        address indexed _player,
        uint256 _payout,
        uint256[] cards
    );
    event HouseWins(uint256 indexed _gameId, uint256 _payout, uint256[] cards);

    event PlayerSurrenders(
        uint256 indexed _gameId,
        address indexed _player
    );

    event GoToWar(uint256 indexed _gameId, address indexed _player, uint256 _sideBet);

    constructor(
        address _forwarder,
        address _vrfOracleContract,
        ITreasury _treasuryContract,
        GameManagerConstructorArgs memory _gameManagerConstructorArgs
    )
        ERC2771Context(_forwarder)
        VRFManager(_vrfOracleContract)
        TreasuryManager(_treasuryContract)
        GameManager(_gameManagerConstructorArgs)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function startHolyWar(uint256 _ante, address _tokenContract) public {
        require(active, "startHolyWar: game not active");

        address sender = _msgSender();

        require(
            playerInGame[sender] == 0,
            "startHolyWar: player already in game"
        );

        require(
            _ante >= minimumAnte[_tokenContract] && _ante <= maximumAnte[_tokenContract],
            "startHolyWar: ante not within the min/max"
        );

        holdFundsToStartGame(sender, _tokenContract, _ante);

        gameCounter++;
        initializeGameData(gameCounter, sender, _tokenContract, _ante);
        emit GameCreated(gameCounter, sender, _tokenContract, _ante);
        deal(gameCounter);
    }

    function surrender() public {
        address sender = _msgSender();
        uint256 gameId = playerInGame[sender];

        require(gameId != 0, "PlayerDecision: player must be in game");

        require(
            gameData[gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "PlayerDecision: game must be on 'waiting on player decision' state"
        );

        gameData[gameId].state = GameState.COMPLETED;
        gameData[gameId].winner = Winner.SURRENDER;

        // single player payout
        singlePlayerPayout(SinglePlayerPayoutArgs({
            _player: sender,
            _tokenContract: gameData[gameId].tokenContract,
            _playerReleaseAmount: gameData[gameId].ante,
            _houseReleaseAmount: gameData[gameId].ante * 2,
            _playerPayout: gameData[gameId].ante / 2,
            _housePayout: (gameData[gameId].ante * 5) / 2
        }));

        resetPlayerInGame(sender);

        emit PlayerSurrenders(
            gameId,
            sender
        );
    }

    function goToWar(uint256 _sideBet) public {
        address sender = _msgSender();
        uint256 gameId = playerInGame[sender];

        require(gameId != 0, "PlayerDecision: player must be in game");

        require(
            gameData[gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "PlayerDecision: game must be on 'waiting on player decision' state"
        );

        holdFundsForGotoWar(
            sender,
            gameData[gameId].tokenContract,
            gameData[gameId].ante,
            _sideBet
        );

        gameData[gameId].sidebet += _sideBet;

        emit GoToWar(
            gameId,
            sender,
            _sideBet
        );

        deal(gameId);
    }

    function deal(uint256 _gameId) private {

        if (gameData[_gameId].state == GameState.WAITING) {
            gameData[_gameId].state = GameState.GETTING_VRF_1;
            requestRandomWords(_gameId, 2);
        } else if (
            gameData[_gameId].state == GameState.WAITING_ON_PLAYER_DECISION
        ) {
            gameData[_gameId].state = GameState.GETTING_VRF_2;
            requestRandomWords(_gameId, 8);
        }
    }

    function requestRandomWords(uint256 _gameId, uint32 _numberOfWords)
        private
    {
        uint256 requestId = IOracle(VRFOracleContract).requestRandomWords(_numberOfWords);

        gameByRequestId[requestId] = _gameId;
        if (gameData[_gameId].state == GameState.GETTING_VRF_1) {
            gameData[_gameId].requestId[0] = requestId;
        } else if (gameData[_gameId].state == GameState.GETTING_VRF_2) {
            gameData[_gameId].requestId[1] = requestId;
        }
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) 
        internal
        override 
    {
        uint256 gameId = gameByRequestId[_requestId];
        if (gameData[gameId].state == GameState.GETTING_VRF_1) {

            gameData[gameId].randomNumbers[0] = _randomWords[0];
            gameData[gameId].randomNumbers[1] = _randomWords[1];

            shuffleDeck(2, gameId);

            uint256 playerCard = gameData[gameId].dealtCards[0] % 13;
            uint256 houseCard = gameData[gameId].dealtCards[1] % 13;

            if (playerCard == houseCard) {
                gameData[gameId].state = GameState.WAITING_ON_PLAYER_DECISION;
                emit ConfrontationDetected(gameId, gameData[gameId].dealtCards);
            } 

            else if (playerCard > houseCard) {

                gameData[gameId].state = GameState.COMPLETED;
                gameData[gameId].winner = Winner.PLAYER;

                singlePlayerPayout(SinglePlayerPayoutArgs({
                    _player: gameData[gameId].player,
                    _tokenContract: gameData[gameId].tokenContract,
                    _playerReleaseAmount: gameData[gameId].ante,
                    _houseReleaseAmount: gameData[gameId].ante * 2,
                    _playerPayout: gameData[gameId].ante * 2,
                    _housePayout: gameData[gameId].ante
                }));

                resetPlayerInGame(gameData[gameId].player);
                emit PlayerWins(
                    gameId,
                    gameData[gameId].player,
                    gameData[gameId].ante * 2,
                    gameData[gameId].dealtCards
                );

            } 

            else if (playerCard < houseCard) {
                
                gameData[gameId].state = GameState.COMPLETED;
                gameData[gameId].winner = Winner.HOUSE;

                singlePlayerPayout(SinglePlayerPayoutArgs({
                    _player: gameData[gameId].player,
                    _tokenContract: gameData[gameId].tokenContract,
                    _playerReleaseAmount: gameData[gameId].ante,
                    _houseReleaseAmount: gameData[gameId].ante * 2,
                    _playerPayout: 0,
                    _housePayout: gameData[gameId].ante * 3
                }));

                resetPlayerInGame(gameData[gameId].player);
                emit HouseWins(gameId, gameData[gameId].ante * 3, gameData[gameId].dealtCards);
            }

         
        } else if (gameData[gameId].state == GameState.GETTING_VRF_2) {
      
            gameData[gameId].randomNumbers[2] = _randomWords[0];
            gameData[gameId].randomNumbers[3] = _randomWords[1];
            gameData[gameId].randomNumbers[4] = _randomWords[2];
            gameData[gameId].randomNumbers[5] = _randomWords[3];
            gameData[gameId].randomNumbers[6] = _randomWords[4];
            gameData[gameId].randomNumbers[7] = _randomWords[5];
            gameData[gameId].randomNumbers[8] = _randomWords[6];
            gameData[gameId].randomNumbers[9] = _randomWords[7];

            shuffleDeck(8, gameId);

            uint256 playerCard = gameData[gameId].dealtCards[8] % 13;
            uint256 houseCard = gameData[gameId].dealtCards[9] % 13;

            gameData[gameId].state = GameState.COMPLETED;
            resetPlayerInGame(gameData[gameId].player);

            uint256 sidebet = gameData[gameId].sidebet;
            uint256 ante = gameData[gameId].ante;

            if (playerCard == houseCard) {
                uint256 payout = ante * 4 + sidebet * 11;
                gameData[gameId].winner = Winner.PLAYER;

                singlePlayerPayout(SinglePlayerPayoutArgs({
                    _player: gameData[gameId].player,
                    _tokenContract: gameData[gameId].tokenContract,
                    _playerReleaseAmount: ante * 2 + sidebet,
                    _houseReleaseAmount: ante * 2 + sidebet * 10,
                    _playerPayout: ante * 4 + sidebet * 11,
                    _housePayout: 0
                }));

                emit PlayerWins(
                    gameId,
                    gameData[gameId].player,
                    payout,
                    gameData[gameId].dealtCards
                );
            } 
            
            else if (playerCard > houseCard) {
                uint256 payout = ante * 3;
                gameData[gameId].winner = Winner.PLAYER;

                singlePlayerPayout(SinglePlayerPayoutArgs({
                    _player: gameData[gameId].player,
                    _tokenContract: gameData[gameId].tokenContract,
                    _playerReleaseAmount: (ante * 2) + sidebet,
                    _houseReleaseAmount: (ante * 2) + (sidebet * 10),
                    _playerPayout: ante * 3,
                    _housePayout: ante + (sidebet * 11)
                }));

                emit PlayerWins(
                    gameId,
                    gameData[gameId].player,
                    payout,
                    gameData[gameId].dealtCards
                );
            } else if (playerCard < houseCard) {
                gameData[gameId].winner = Winner.HOUSE;

                singlePlayerPayout(SinglePlayerPayoutArgs({
                    _player: gameData[gameId].player,
                    _tokenContract: gameData[gameId].tokenContract,
                    _playerReleaseAmount: (ante * 2) + sidebet,
                    _houseReleaseAmount: (ante * 2) + (sidebet * 10),
                    _playerPayout: 0,
                    _housePayout: (ante * 4) + (sidebet * 11)
                }));

                emit HouseWins(gameId, (ante * 4) + (sidebet * 11), gameData[gameId].dealtCards);
            }
        }
    }

    function shuffleDeck(uint256 _numberOfCards, uint256 _gameId) private {
        GameData storage g = gameData[_gameId];
        uint256 startingIndex = g.drawIndex;
        uint256 cardsRemaining = g.numberOfCards - startingIndex;

        for (; g.drawIndex < startingIndex + _numberOfCards; ) {
            uint256 randomNum = gameData[_gameId].randomNumbers[g.drawIndex] %
                cardsRemaining;

            uint256 index = g.deckCache[randomNum] == 0
                ? randomNum
                : g.deckCache[randomNum];

            g.deckCache[randomNum] = g.deckCache[cardsRemaining - 1] == 0
                ? cardsRemaining - 1
                : g.deckCache[cardsRemaining - 1];

            g.dealtCards[g.drawIndex] = index;
            unchecked {
                --cardsRemaining;
                ++g.drawIndex;
            }
        }
    }

    function capture(uint256 _gameId) public {
        require(_gameId != 0, "PlayerDecision: player must be in game");

        require(
            block.timestamp >
                gameData[_gameId].gameStarted + gameData[_gameId].timeout,
            "expireDecision: game did not expire"
        );

        require(
            gameData[_gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "PlayerDecision: game must be on 'waiting on player decision' state"
        );

        gameData[_gameId].state = GameState.COMPLETED;
        gameData[_gameId].winner = Winner.SURRENDER;
        uint256 ante = gameData[_gameId].ante;

        singlePlayerPayout(SinglePlayerPayoutArgs({
            _player: gameData[_gameId].player,
            _tokenContract: gameData[_gameId].tokenContract,
            _playerReleaseAmount: ante,
            _houseReleaseAmount: ante * 2,
            _playerPayout: ante / 2,
            _housePayout: (ante * 5) / 2
        }));

        resetPlayerInGame(gameData[_gameId].player);
        emit PlayerSurrenders(
            _gameId,
            gameData[_gameId].player
        );
    }

    function updateTimeout(uint256 _seconds)
        public
        override
        onlyRole(GAME_MANAGER_ROLE)
    {
        super.updateTimeout(_seconds);
    }

    function updateMinimumAnte(address _tokenContract, uint256 _ante)
        public
        override
        onlyRole(GAME_MANAGER_ROLE)
    {
        super.updateMinimumAnte(_tokenContract, _ante);
    }

    function updateMaximumAnte(address _tokenContract, uint256 _ante)
        public
        override
        onlyRole(GAME_MANAGER_ROLE)
    {
        super.updateMaximumAnte(_tokenContract, _ante);
    }

    function updateNumberOfDecks(uint256 _numberOfDecks)
        public
        override
        onlyRole(GAME_MANAGER_ROLE)
    {
        super.updateNumberOfDecks(_numberOfDecks);
    }

    function toggleActive() public override onlyRole(GAME_MANAGER_ROLE) {
        super.toggleActive();
    }

    function _msgSender()
        internal
        view
        override(ERC2771Context, Context)
        returns (address sender)
    {
        return ERC2771Context._msgSender();
    }

    function _msgData()
        internal
        view
        override(ERC2771Context, Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

abstract contract ITreasury {

    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => uint256)) public holds;
    mapping(address => uint256) public houseBalances;
    mapping(address => uint256) public houseHolds;

    function holdPlayerFunds(
        address _player,
        address _tokenContract,
        uint256 _amount
    ) external virtual;
    function holdHouseFunds(address _tokenContract, uint256 _amount) external virtual;
    function releasePlayerHold(address _player, address _tokenContract, uint256 _amount) external virtual;
    function releaseHouseHold(address _tokenContract, uint256 _amount) external virtual;
    function creditPlayerBalance(address _player, address _tokenContract, uint256 _amount) external virtual;
    function creditHouseBalance(address _tokenContract, uint256 _amount) external virtual;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IOracle {

    function requestRandomWords(uint256 _numberOfWords) external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IConsumer {

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IOracle.sol";
import "./interfaces/IConsumer.sol";

contract VRFManager is IConsumer {

    address public VRFOracleContract;

    constructor(address _VRFOracleContract){
        VRFOracleContract = _VRFOracleContract; 
    }

    function updateOracleContract(address _VRFOracleContract) external virtual {
        VRFOracleContract = _VRFOracleContract;
    }

    function fulfillRandomWords(uint256, uint256[] memory)
        internal
        virtual
    {}

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        
        require(msg.sender == VRFOracleContract, "rawFulfillRandomWords: only oracle can fulfill random words");

        fulfillRandomWords(requestId, randomWords);

    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./interfaces/ITreasury.sol";

struct SinglePlayerPayoutArgs{
    address _player;
    address _tokenContract;
    uint256 _playerReleaseAmount;
    uint256 _houseReleaseAmount;
    uint256 _playerPayout;
    uint256 _housePayout;
}

contract TreasuryManager {

    ITreasury public treasuryContract;

    constructor(ITreasury _treasuryContract){
        treasuryContract = _treasuryContract;
    }

    function holdFundsToStartGame(address _player, address _tokenContract, uint256 _ante) internal {

        treasuryContract.holdPlayerFunds(_player, _tokenContract, _ante);
        treasuryContract.holdHouseFunds(_tokenContract, _ante * 2);

    }

    function holdFundsForGotoWar(address _player, address _tokenContract, uint256 _ante, uint256 _sideBet) internal {
        treasuryContract.holdPlayerFunds(_player, _tokenContract, _ante + _sideBet);
        treasuryContract.holdHouseFunds(_tokenContract, _sideBet * 10);
    }

    function refund(address _player, address _tokenContract, uint256 _playerAmount, uint256 _houseAmount) internal {

        treasuryContract.releaseHouseHold(_tokenContract, _houseAmount);
        treasuryContract.creditHouseBalance(_tokenContract, _houseAmount);
        treasuryContract.releasePlayerHold(_player, _tokenContract, _playerAmount);
        treasuryContract.creditPlayerBalance(_player, _tokenContract, _playerAmount);

    }

    function singlePlayerPayout(
        SinglePlayerPayoutArgs memory _singlePlayerPayoutArgs
    ) internal {
        
        require(
            treasuryContract.houseHolds(_singlePlayerPayoutArgs._tokenContract) >= _singlePlayerPayoutArgs._houseReleaseAmount,
            "payout: insufficient house hold"
        );

        require(
            _singlePlayerPayoutArgs._houseReleaseAmount != 0,
            "payout: house release amount must be greater than zero"
        );

        // treasuryContract.houseHolds(_singlePlayerPayoutArgs._tokenContract) -= _singlePlayerPayoutArgs._houseReleaseAmount;
        treasuryContract.releaseHouseHold(_singlePlayerPayoutArgs._tokenContract, _singlePlayerPayoutArgs._houseReleaseAmount);
        
        // treasuryContract.houseBalances(_singlePlayerPayoutArgs._tokenContract) += _singlePlayerPayoutArgs._housePayout;
        treasuryContract.creditHouseBalance(_singlePlayerPayoutArgs._tokenContract, _singlePlayerPayoutArgs._housePayout);

        uint256 totalReleased = _singlePlayerPayoutArgs._houseReleaseAmount + _singlePlayerPayoutArgs._playerReleaseAmount;
        uint256 totalPayout = _singlePlayerPayoutArgs._housePayout + _singlePlayerPayoutArgs._playerPayout;

        require(
            treasuryContract.holds(_singlePlayerPayoutArgs._player, _singlePlayerPayoutArgs._tokenContract) >= _singlePlayerPayoutArgs._playerReleaseAmount,
            "payout: insufficient player hold"
        );

        require(
            _singlePlayerPayoutArgs._playerReleaseAmount != 0,
            "payout: player release amount must be greater than zero"
        );

        // treasuryContract.holds(_singlePlayerPayoutArgs._player, _singlePlayerPayoutArgs._tokenContract) -= _singlePlayerPayoutArgs._playerReleaseAmount;
        treasuryContract.releasePlayerHold(_singlePlayerPayoutArgs._player, _singlePlayerPayoutArgs._tokenContract, _singlePlayerPayoutArgs._playerReleaseAmount);
        
        // treasuryContract.balances[_singlePlayerPayoutArgs._player][_singlePlayerPayoutArgs._tokenContract] += _singlePlayerPayoutArgs._playerPayout;
        treasuryContract.creditPlayerBalance(_singlePlayerPayoutArgs._player, _singlePlayerPayoutArgs._tokenContract, _singlePlayerPayoutArgs._playerPayout);

        require(
            totalPayout == totalReleased,
            "payout: held funds do not match payouts"
        );
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.14;

struct GameData {
    GameState state;
    uint256 gameStarted;
    address player;
    address tokenContract;
    uint256 ante;
    uint256 sidebet;
    uint256 timeout;
    uint256 numberOfCards;
    uint256 drawIndex;
    mapping(uint256 => uint256) deckCache;
    uint256[] dealtCards;
    uint256[] randomNumbers;
    Winner winner;
    PlayerDecision playerDecision;
    uint256[] requestId;
}

enum GameState {
    WAITING,
    GETTING_VRF_1,
    WAITING_ON_PLAYER_DECISION,
    GETTING_VRF_2,
    COMPLETED
}

enum Winner {
    NOT_SET,
    PLAYER,
    HOUSE,
    SURRENDER,
    CAPTURED_FUNDS
}

enum PlayerDecision {
    PRAY,
    RETREAT,
    WAR
}

struct GameManagerConstructorArgs {
    uint256[] minimumAnte;
    uint256[] maximumAnte;
    address[] approvedTokens;
    uint256 numberOfDecks;
    uint256 timeout;
}

contract GameManager {
    mapping(address => uint256) public minimumAnte;
    mapping(address => uint256) public maximumAnte;
    uint256 public numberOfDecks;
    uint256 public timeout;

    uint256 public gameCounter;
    mapping(uint256 => GameData) public gameData;
    mapping(address => uint256) public playerInGame;

    bool public active;

    event TimeoutUpdated(uint256 _seconds);
    event AnteMinimumUpdated(uint256 _ante);
    event AnteMaximumUpdated(uint256 _ante);
    event NumberOfDecksUpdated(uint256 _numberOfDecks);

    constructor(GameManagerConstructorArgs memory _gameManagerConstructorArgs) {

        uint256 expectedLength = _gameManagerConstructorArgs.approvedTokens.length;


        require(
            _gameManagerConstructorArgs.minimumAnte.length == expectedLength && 
            _gameManagerConstructorArgs.maximumAnte.length == expectedLength,
            "GameManager: minimum and maximum ante arrays must match token contract array"
        );

        uint256 i;
        for(; i < expectedLength;){
            
            minimumAnte[_gameManagerConstructorArgs.approvedTokens[i]] = _gameManagerConstructorArgs.minimumAnte[i];
            maximumAnte[_gameManagerConstructorArgs.approvedTokens[i]] = _gameManagerConstructorArgs.maximumAnte[i];
            
            unchecked {
                i++;
            }
        }

        numberOfDecks = _gameManagerConstructorArgs.numberOfDecks;
        timeout = _gameManagerConstructorArgs.timeout;
        active = true;
    }

    function initializeGameData(
        uint256 _gameCounter,
        address _player,
        address _tokenContract,
        uint256 _ante
    ) internal {
        GameData storage g = gameData[_gameCounter];
        g.gameStarted = block.timestamp;
        g.player = _player;
        g.tokenContract = _tokenContract;
        g.ante = _ante;
        g.sidebet = 0;
        g.timeout = timeout;
        g.numberOfCards = numberOfDecks * 52;
        g.dealtCards = new uint256[](10);
        g.randomNumbers = new uint256[](10);
        g.winner = Winner.NOT_SET;
        g.playerDecision = PlayerDecision.PRAY;
        g.requestId = new uint256[](2);

        playerInGame[_player] = _gameCounter;
    }

    function updateTimeout(uint256 _seconds) public virtual {
        timeout = _seconds;
        emit TimeoutUpdated(_seconds);
    }

    function updateMinimumAnte(address _tokenContract, uint256 _minimumAnte) public virtual {
        minimumAnte[_tokenContract] = _minimumAnte;
        emit AnteMinimumUpdated(_minimumAnte);
    }

    function updateMaximumAnte(address _tokenContract, uint256 _maximumAnte) public virtual {
        maximumAnte[_tokenContract] = _maximumAnte;
        emit AnteMaximumUpdated(_maximumAnte);
    }

    function updateNumberOfDecks(uint256 _numberOfDecks) public virtual {
        require(
            _numberOfDecks != 0,
            "updateNumberOfDecks: number of decks must be greater than 0"
        );
        numberOfDecks = _numberOfDecks;
        emit NumberOfDecksUpdated(_numberOfDecks);
    }

    function resetPlayerInGame(address _player) internal {
        delete playerInGame[_player];
    }

    function toggleActive() public virtual {
        active = !active;
    }

    function getDeckByGame(uint256 _gameId)
        public
        view
        returns (uint256[] memory)
    {
        return gameData[_gameId].dealtCards;
    }

    function getRandomNumbersByGame(uint256 _gameId)
        public
        view
        returns (uint256[] memory)
    {
        return gameData[_gameId].randomNumbers;
    }

    function getRequestIdByGame(uint256 _gameId)
        public
        view
        returns (uint256[] memory)
    {
        return gameData[_gameId].requestId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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