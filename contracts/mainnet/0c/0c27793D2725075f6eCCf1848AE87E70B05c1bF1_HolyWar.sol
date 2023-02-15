// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./GameManager.sol";
import "./VRFManager.sol";

/// @title HolyWar
contract HolyWar is AccessControlEnumerable, GameManager, VRFManager {
    struct PayoutArgs {
        address player;
        uint256 houseReleaseAmount;
        uint256 playerPayout;
        uint256 housePayout;
    }

    bytes32 public constant GAME_MANAGER_ROLE = keccak256("GAME_MANAGER_ROLE");

    mapping(uint256 => uint256) public gameByRequestId;

    uint256 public houseBalance;
    uint256 public houseHold;
    uint256 public constant RESERVE_RATIO = 2;
    uint256 public constant SIDEBET_RATIO = 10;

    event GameCreated(uint256 indexed _gameId);
    event ConfrontationDetected(uint256 indexed _gameId);
    event PlayerWins(uint256 indexed _gameId);
    event HouseWins(uint256 indexed _gameId);
    event PlayerSurrenders(uint256 indexed _gameId);
    event GoToWar(uint256 indexed _gameId);
    event GameVoid(uint256 indexed gameId);
    event HouseDeposit(uint256 _amount);
    event HouseWithdraw(uint256 _amount);

    constructor(
        address _vrfOracleContract,
        GameManagerConstructorArgs memory _gameManagerConstructorArgs
    ) VRFManager(_vrfOracleContract) GameManager(_gameManagerConstructorArgs) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(
            GAME_MANAGER_ROLE,
            0x012e8326acd4CF9DBBCa78f082a1A1C01ed2192F
        );
    }

    function startHolyWar() external payable {
        require(active, "startHolyWar: game not active");

        require(
            playerInGame[msg.sender] == 0,
            "startHolyWar: player already in game"
        );

        uint256 houseRequirement = msg.value * RESERVE_RATIO;

        require(
            houseBalance >= houseRequirement,
            "startHolyWar: House does not have enough funds to start game"
        );

        require(
            msg.value >= minimumAnte && msg.value <= maximumAnte,
            "startHolyWar: ante not within the min/max"
        );

        houseBalance -= houseRequirement;
        houseHold += houseRequirement;

        gameCounter++;
        _initializeGameData(
            gameCounter,
            msg.sender,
            msg.value,
            houseRequirement
        );
        emit GameCreated(gameCounter);
        _deal(gameCounter);
    }

    function surrender() external {
        uint256 gameId = playerInGame[msg.sender];

        require(gameId != 0, "surrender: player must be in game");

        require(
            gameData[gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "surrender: game must be on 'waiting on player decision' state"
        );

        gameData[gameId].state = GameState.COMPLETED;
        gameData[gameId].winner = Winner.SURRENDER;

        _payout(
            PayoutArgs({
                player: msg.sender,
                houseReleaseAmount: gameData[gameId].ante * RESERVE_RATIO,
                playerPayout: gameData[gameId].ante / 2,
                housePayout: (gameData[gameId].ante * (2 * RESERVE_RATIO + 1)) /
                    2
            })
        );

        _resetPlayerInGame(msg.sender);

        emit PlayerSurrenders(gameId);
    }

    /// @dev put in a side bet
    function goToWar() external payable {
        uint256 gameId = playerInGame[msg.sender];

        require(gameId != 0, "goToWar: player must be in game");

        require(
            gameData[gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "goToWar: game must be on 'waiting on player decision' state"
        );

        require(
            msg.value >= gameData[gameId].ante,
            "goToWar: msg.value must be at least the original ante"
        );

        uint256 sidebet = msg.value - gameData[gameId].ante;

        require(
            sidebet <= gameData[gameId].ante * 5,
            "goToWar: _sideBet cannot be more then 5 times the ante"
        );

        if (sidebet != 0) {
            _holdFundsForGotoWar(msg.value);
            gameData[gameId].sidebet += sidebet;
        }

        emit GoToWar(gameId);

        _deal(gameId);
    }

    function _deal(uint256 _gameId) private {
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
        uint256 requestId = IOracle(VRFOracleContract).requestRandomWords(
            _numberOfWords
        );

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
    ) internal override {
        uint256 gameId = gameByRequestId[_requestId];
        if (gameData[gameId].state == GameState.GETTING_VRF_1) {
            gameData[gameId].randomNumbers[0] = _randomWords[0];
            gameData[gameId].randomNumbers[1] = _randomWords[1];

            _shuffleDeck(2, gameId);

            uint256 playerCard = gameData[gameId].dealtCards[0] % 13;
            uint256 houseCard = gameData[gameId].dealtCards[1] % 13;

            if (playerCard == houseCard) {
                gameData[gameId].state = GameState.WAITING_ON_PLAYER_DECISION;
                emit ConfrontationDetected(gameId);
            } else if (playerCard > houseCard) {
                gameData[gameId].state = GameState.COMPLETED;
                gameData[gameId].winner = Winner.PLAYER;

                _payout(
                    PayoutArgs({
                        player: gameData[gameId].player,
                        houseReleaseAmount: gameData[gameId].ante *
                            RESERVE_RATIO,
                        playerPayout: gameData[gameId].ante * RESERVE_RATIO,
                        housePayout: gameData[gameId].ante
                    })
                );

                _resetPlayerInGame(gameData[gameId].player);
                emit PlayerWins(gameId);
            } else if (playerCard < houseCard) {
                gameData[gameId].state = GameState.COMPLETED;
                gameData[gameId].winner = Winner.HOUSE;

                _payout(
                    PayoutArgs({
                        player: gameData[gameId].player,
                        houseReleaseAmount: gameData[gameId].ante *
                            RESERVE_RATIO,
                        playerPayout: 0,
                        housePayout: (gameData[gameId].ante * RESERVE_RATIO) +
                            gameData[gameId].ante
                    })
                );

                _resetPlayerInGame(gameData[gameId].player);
                emit HouseWins(gameId);
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

            _shuffleDeck(8, gameId);

            uint256 playerCard = gameData[gameId].dealtCards[8] % 13;
            uint256 houseCard = gameData[gameId].dealtCards[9] % 13;

            gameData[gameId].state = GameState.COMPLETED;
            _resetPlayerInGame(gameData[gameId].player);

            if (playerCard == houseCard) {
                gameData[gameId].winner = Winner.PLAYER;

                _payout(
                    PayoutArgs({
                        player: gameData[gameId].player,
                        houseReleaseAmount: gameData[gameId].ante *
                            RESERVE_RATIO +
                            gameData[gameId].sidebet *
                            SIDEBET_RATIO,
                        playerPayout: gameData[gameId].ante *
                            4 +
                            gameData[gameId].sidebet *
                            11,
                        housePayout: 0
                    })
                );

                emit PlayerWins(gameId);
            } else if (playerCard > houseCard) {
                gameData[gameId].winner = Winner.PLAYER;

                _payout(
                    PayoutArgs({
                        player: gameData[gameId].player,
                        houseReleaseAmount: (gameData[gameId].ante *
                            RESERVE_RATIO) +
                            (gameData[gameId].sidebet * SIDEBET_RATIO),
                        playerPayout: gameData[gameId].ante * 3,
                        housePayout: gameData[gameId].ante +
                            gameData[gameId].sidebet *
                            11
                    })
                );

                emit PlayerWins(gameId);
            } else if (playerCard < houseCard) {
                gameData[gameId].winner = Winner.HOUSE;

                _payout(
                    PayoutArgs({
                        player: gameData[gameId].player,
                        houseReleaseAmount: (gameData[gameId].ante *
                            RESERVE_RATIO) +
                            (gameData[gameId].sidebet * SIDEBET_RATIO),
                        playerPayout: 0,
                        housePayout: (gameData[gameId].ante * 4) +
                            (gameData[gameId].sidebet * 11)
                    })
                );
                emit HouseWins(gameId);
            }
        }
    }

    function _shuffleDeck(uint256 _numberOfCards, uint256 _gameId) private {
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

    /// @param _gameId is the game number
    function capture(uint256 _gameId) external {
        require(_gameId != 0, "capture: player must be in game");

        require(
            block.timestamp >
                gameData[_gameId].gameStarted + gameData[_gameId].timeout,
            "capture: game did not expire"
        );

        require(
            gameData[_gameId].state == GameState.WAITING_ON_PLAYER_DECISION,
            "capture: game must be on 'waiting on player decision' state"
        );

        gameData[_gameId].state = GameState.COMPLETED;
        gameData[_gameId].winner = Winner.SURRENDER;
        uint256 ante = gameData[_gameId].ante;

        _payout(
            PayoutArgs({
                player: gameData[_gameId].player,
                houseReleaseAmount: ante * RESERVE_RATIO,
                playerPayout: ante / 2,
                housePayout: (ante * (2 * RESERVE_RATIO + 1)) / 2
            })
        );

        _resetPlayerInGame(gameData[_gameId].player);
        emit PlayerSurrenders(_gameId);
    }

    function _payout(PayoutArgs memory _payoutArgs) internal {
        require(
            houseHold >= _payoutArgs.houseReleaseAmount,
            "payout: insufficient house hold"
        );

        require(
            _payoutArgs.houseReleaseAmount != 0,
            "payout: house release amount must be greater than zero"
        );

        houseHold -= _payoutArgs.houseReleaseAmount;
        houseBalance += _payoutArgs.housePayout;
        if (_payoutArgs.playerPayout > 0) {
            require(payable(_payoutArgs.player).send(_payoutArgs.playerPayout));
        }
    }

    function _holdFundsForGotoWar(uint256 _sideBet) internal {
        houseBalance -= _sideBet * 10;
        houseHold += _sideBet * 10;
    }

    /// @notice This function deposits to the HOUSE BALANCE.
    /// @dev This will not credit your balance for sender.
    function houseDeposit() external payable {
        houseBalance += msg.value;

        emit HouseDeposit(msg.value);
    }

    /// @notice This function withdraws from the HOUSE BALANCE
    /// @dev only game manager role can call this function
    /// @param _destination the wallet address which you would like to send the funds to
    /// @param _amount how many tokens the house would like to withdraw
    function houseWithdraw(address _destination, uint256 _amount)
        external
        onlyRole(GAME_MANAGER_ROLE)
    {
        require(payable(_destination).send(_amount));
        houseBalance -= _amount;
        emit HouseWithdraw(_amount);
    }

    /// @param _gameId is the game number you want to void
    function voidGame(uint256 _gameId) external onlyRole(GAME_MANAGER_ROLE) {
        _voidGame(_gameId);
        houseBalance += gameData[_gameId].houseHold;
        houseHold -= gameData[_gameId].houseHold;
        require(
            payable(gameData[_gameId].player).send(
                gameData[_gameId].ante + gameData[_gameId].sidebet
            )
        );

        emit GameVoid(_gameId);
    }

    /// @param _seconds is how many seconds the new timeout should be
    function updateTimeout(uint256 _seconds)
        external
        onlyRole(GAME_MANAGER_ROLE)
    {
        _updateTimeout(_seconds);
    }

    /// @param _ante is the bet amount for minimum ante
    function updateMinimumAnte(uint256 _ante)
        external
        onlyRole(GAME_MANAGER_ROLE)
    {
        _updateMinimumAnte(_ante);
    }

    /// @param _ante is the bet amount for maximum ante
    function updateMaximumAnte(uint256 _ante)
        external
        onlyRole(GAME_MANAGER_ROLE)
    {
        _updateMaximumAnte(_ante);
    }

    /// @param _numberOfDecks is the number of new decks
    function updateNumberOfDecks(uint256 _numberOfDecks)
        external
        onlyRole(GAME_MANAGER_ROLE)
    {
        _updateNumberOfDecks(_numberOfDecks);
    }

    function toggleActive() external onlyRole(GAME_MANAGER_ROLE) {
        _toggleActive();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IOracle {
    function requestRandomWords(uint256 _numberOfWords)
        external
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IConsumer {
    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IOracle.sol";
import "./interfaces/IConsumer.sol";

contract VRFManager is IConsumer {
    address public VRFOracleContract;

    constructor(address _VRFOracleContract) {
        VRFOracleContract = _VRFOracleContract;
    }

    function fulfillRandomWords(uint256, uint256[] memory) internal virtual {}

    function rawFulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) external {
        require(
            msg.sender == VRFOracleContract,
            "rawFulfillRandomWords: only oracle can fulfill random words"
        );

        fulfillRandomWords(requestId, randomWords);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct GameData {
    GameState state;
    uint256 gameStarted;
    address player;
    uint256 ante;
    uint256 houseHold;
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
    COMPLETED,
    VOID
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
    uint256 minimumAnte;
    uint256 maximumAnte;
    uint256 numberOfDecks;
    uint256 timeout;
}

contract GameManager {
    uint256 public minimumAnte;
    uint256 public maximumAnte;
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
        minimumAnte = _gameManagerConstructorArgs.minimumAnte;
        maximumAnte = _gameManagerConstructorArgs.maximumAnte;
        numberOfDecks = _gameManagerConstructorArgs.numberOfDecks;
        timeout = _gameManagerConstructorArgs.timeout;
        active = true;
    }

    function _initializeGameData(
        uint256 _gameCounter,
        address _player,
        uint256 _ante,
        uint256 _houseHold
    ) internal {
        GameData storage g = gameData[_gameCounter];
        g.gameStarted = block.timestamp;
        g.player = _player;
        g.ante = _ante;
        g.houseHold = _houseHold;
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

    function _updateTimeout(uint256 _seconds) internal {
        timeout = _seconds;
        emit TimeoutUpdated(_seconds);
    }

    function _updateMinimumAnte(uint256 _minimumAnte) internal {
        minimumAnte = _minimumAnte;
        emit AnteMinimumUpdated(_minimumAnte);
    }

    function _updateMaximumAnte(uint256 _maximumAnte) internal {
        maximumAnte = _maximumAnte;
        emit AnteMaximumUpdated(_maximumAnte);
    }

    function _updateNumberOfDecks(uint256 _numberOfDecks) internal {
        require(
            _numberOfDecks != 0,
            "updateNumberOfDecks: number of decks must be greater than 0"
        );
        numberOfDecks = _numberOfDecks;
        emit NumberOfDecksUpdated(_numberOfDecks);
    }

    /// @param _gameId is the game number
    function _voidGame(uint256 _gameId) internal {
        require(
            gameData[_gameId].state == GameState.GETTING_VRF_1 ||
                gameData[_gameId].state == GameState.GETTING_VRF_2,
            "voidGame: game must be stuck in Getting VRF state"
        );
        gameData[_gameId].state = GameState.VOID;
        delete playerInGame[gameData[_gameId].player];
    }

    function _resetPlayerInGame(address _player) internal {
        delete playerInGame[_player];
    }

    function _toggleActive() internal {
        active = !active;
    }

    function getDeckByGame(uint256 _gameId)
        external
        view
        returns (uint256[] memory)
    {
        return gameData[_gameId].dealtCards;
    }

    function getRandomNumbersByGame(uint256 _gameId)
        external
        view
        returns (uint256[] memory)
    {
        return gameData[_gameId].randomNumbers;
    }

    function getRequestIdByGame(uint256 _gameId)
        external
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