//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import "./Game.sol";

/**
 * @title Main contract of the Lepricon Gamefi Platform;
 * @author Pedrojok01
 * @notice Allows to deploy new games & tracks all global variables per player;
 */

contract GameFactory is Pausable, Ownable {
    /* Storage:
     ************/

    address private admin; // Backend server
    address private paymentManager; // contract handling withdraw
    IERC20 private token;

    mapping(bytes32 => uint256) public getGameId; // Map games ID per game name
    mapping(uint256 => IGame) public getGameAddress; // Map games address per game ID
    mapping(address => uint256) private consecutiveLogin;
    IGame[] public gamesList; // Array containing all created games addresses

    event NewGameCreated(address owner, IGame indexed newGameAddress, uint256 indexed newGameID, bytes32 newGameName);
    event AdminAddressSet(address admin);
    event PaymentManagerAddressSet(address paymentManager);
    event TokenSet(IERC20 token);

    /* Functions:
     **************/

    /** 
     @dev Call this function to create a new game contract.
     @param gameName  Name of the new game. Can be chosen by user input.
    */
    function createNewGame(bytes32 gameName) external whenNotPaused returns (IGame) {
        uint256 gameID = gamesList.length;
        require(getGameAddress[gameID] == IGame(address(0)), "Game already exist");

        // call Game.sol constructor to create a new game
        IGame newGame = IGame(new Game(gameName, gameID, msg.sender, admin, paymentManager, token));

        getGameId[gameName] = gameID;
        getGameAddress[gameID] = newGame;
        gamesList.push(newGame);

        emit NewGameCreated(msg.sender, newGame, gameID, gameName);

        return newGame;
    }

    /** 
     @dev Call this function to batch-update all players Login status at once;
     @param _players Array of players' addresses;
     @param _loggedIn Array of players' login status for the past 24h;
    */
    function updatAllPlayersLogin(address[] calldata _players, bool[] calldata _loggedIn)
        external
        onlyOwner
        whenNotPaused
    {
        require(_players.length == _loggedIn.length, "Args don't match");
        uint256 array = _players.length;
        for (uint256 i = 0; i < array; i++) {
            if (_loggedIn[i]) {
                _updatePlayerLogin(_players[i]);
            }
        }
    }

    /* View Functions:
     *******************/
    /// @notice Return a game instance from a game ID;
    function getGamePerIndex(uint256 _gameId) external view returns (IGame) {
        return gamesList[_gameId];
    }

    /// @notice Get amount of games;
    function getNumberOfGames() external view returns (uint256) {
        return gamesList.length;
    }

    /// @notice Get player login status;
    function getLoginStatusOf(address _player) external view returns (uint256) {
        return consecutiveLogin[_player];
    }

    /// @notice Get total amount of sessions played on the platform;
    function getGlobalSessionsPlayed() external view returns (uint256) {
        uint256 array = gamesList.length;
        uint256 globalPlayed = 0;

        for (uint256 i = 0; i < array; i++) {
            IGame game = this.getGamePerIndex(i);
            globalPlayed += game.getTotalSessionsPlayed();
        }
        return globalPlayed;
    }

    /// @notice Get all stats per player;
    function getGlobalPlayerStats(address _player) external view returns (SharedStructs.GlobalPlayerStats memory) {
        SharedStructs.GlobalPlayerStats memory temp;
        temp.player = _player;
        uint256 array = gamesList.length;

        for (uint256 i = 0; i < array; i++) {
            IGame game = gamesList[i];
            SharedStructs.Player memory player = game.getPlayerStats(_player);
            temp.totalXp += player.xp;
            temp.totalSessionsPlayed += player.sessionsPlayed;
            temp.totalClaimable += player.claimable;
            temp.globalWon += player.totalWon;
        }
        temp.consecutiveLogin = consecutiveLogin[_player];
        return temp;
    }

    /// @notice Get all stats per player;
    function getGameIdPlayedPerPlayer(address _player) external view returns (IGame[] memory) {
        uint256 array = gamesList.length;
        IGame[] memory temp = new IGame[](array);
        uint256 index = 0;

        for (uint256 i = 0; i < array; i++) {
            IGame game = gamesList[i];
            bool isPlayer = game.isPlayerInGameId(_player);
            if (isPlayer) {
                temp[index] = game;
                index++;
            }
        }
        return temp;
    }

    /* Restricted:
     **************/

    /// @notice Allows to set the admin address (must be passed in game creation)
    function setAdmin(address _admin) external onlyOwner {
        require(_admin != address(0), "Address 0");
        admin = _admin;
        emit AdminAddressSet(_admin);
    }

    /// @notice Allows to set the PaymentManager address (must be passed in game creation)
    function setPaymentManager(address _paymentManager) external onlyOwner {
        require(_paymentManager != address(0), "Address 0");
        paymentManager = _paymentManager;
        emit PaymentManagerAddressSet(_paymentManager);
    }

    /// @notice Allows to set the PaymentManager address (must be passed in game creation)
    function setToken(IERC20 _token) external onlyOwner {
        token = _token;
        emit TokenSet(_token);
    }

    /* Private:
     ************/

    function _updatePlayerLogin(address _player) private {
        consecutiveLogin[_player]++;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// import "hardhat/console.sol";
import "./interfaces/IGame.sol";
import "./libraries/SharedStructs.sol";
import "./libraries/RewardStructure.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Deployed for each new game via the GameFactory;
 * @author @Pedrojok01
 * @notice Allows publishers to create a new contract for each new game
 */

contract Game is IGame, Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* Storage:
     ************/
    IERC20 private immutable token;
    address private constant FEE_RECEIVER = 0xB7B8E47423bF7191aedd3AE649Ef074C2406b52C; /// Lepricon Multisig address
    address private immutable admin; // = back-end server's address
    address private immutable paymentManager;

    bytes32 public gameName;
    uint256 public gameID;
    uint256 public activePlayersLastRanking;
    uint256 public numberOfPlayers = 0;

    mapping(address => SharedStructs.Player) public player;
    mapping(address => SharedStructs.NftsAllowed) public isNftAllowed;
    mapping(address => SharedStructs.NftStat) public nftStat;
    mapping(address => uint256) public playerIndex;
    mapping(uint256 => address) public playerAddress;

    /// @notice Triggered after each ranking reset
    event RankingReset(uint256 numOfPlayers, uint256 numOfActivePlayers, uint256 timestamp);
    event RewardsDistributed(address[10] top10, uint256 amountToDistribute, uint8[10] rewardStructure);

    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == admin || msg.sender == paymentManager, "Not authorized");
        _;
    }

    /* Constructor:
     ***************/

    constructor(
        bytes32 _gameName,
        uint256 _gameID,
        address _owner,
        address _admin,
        address _paymentManager,
        IERC20 _token
    ) {
        require(_admin != address(0), "Address 0");
        require(_paymentManager != address(0), "Address 0");

        gameName = _gameName;
        gameID = _gameID;
        admin = _admin;
        paymentManager = _paymentManager;
        token = _token;
        transferOwnership(_owner);
    }

    /* Functions:
     **************/

    /**
     * @notice Add a new player (when blockchain function unlocked);
     * @param _player Array of player's addresses to update;
     * @param _xp Player's XP gained off-chain until now;
     * @param _sessionsPlayed Player's total sessions played off-chain until now;
     * @param _claimable Player's claimable amount gained off-chain until now (also == totalWon);
     * @param _rankingScore Player's best weekly score off-chain until now;
     * @param _bestScore Player's best overall score off-chain until now;
     */
    function addNewPlayer(
        address _player,
        uint256 _xp,
        uint256 _sessionsPlayed,
        uint256 _claimable,
        uint256 _rankingScore,
        uint256 _bestScore
    ) external override onlyAuthorized whenNotPaused returns (uint256 userIndex) {
        require(_player != address(0), "Address 0");
        require(playerIndex[_player] == 0, "Existing user");

        numberOfPlayers++;
        userIndex = numberOfPlayers;
        playerIndex[_player] = userIndex;
        playerAddress[userIndex] = _player;

        player[_player].user = _player;
        player[_player].xp = _xp;
        player[_player].sessionsPlayed = _sessionsPlayed;
        player[_player].claimable = _claimable;
        player[_player].totalWon = _claimable;
        player[_player].rankingScore = _rankingScore;
        player[_player].bestScore = _bestScore;

        return userIndex;
    }

    /**
     * @notice Update all players stats at once
     * @param _players Array of player's addresses to update;
     * @param _numbers Array containing all data to be updated;
     */
    function updateAllPlayersStats(address[] calldata _players, uint256[] calldata _numbers)
        external
        override
        onlyAuthorized
        whenNotPaused
    {
        require(_players.length == (_numbers.length / 4), "Wrong parameters");
        uint256 array = _players.length;
        uint256 pointer = 0; //points to user's number in numbers array
        for (uint256 i = 0; i < array; i++) {
            _updatePlayerStats(
                _players[i],
                _numbers[pointer],
                _numbers[pointer + 1],
                _numbers[pointer + 2],
                _numbers[pointer + 3]
            );
            pointer += 4;
        }
    }

    /// @notice Reinitialize all players hebdo scores
    function resetAllrankingScores() external override onlyAuthorized whenNotPaused {
        uint256 numOfPlayers = numberOfPlayers;
        uint256 numOfActivePlayers = 0;
        for (uint256 i = 1; i <= numOfPlayers; i++) {
            address playerTemp = playerAddress[i];
            uint256 temp = _resetRankingScore(playerTemp);
            if (temp > 0) {
                numOfActivePlayers++;
            }
        }
        emit RankingReset(numOfPlayers, numOfActivePlayers, block.timestamp);
        activePlayersLastRanking = numOfActivePlayers;
    }

    /**
     * @notice Allows to distribute the weekly ranking rewards
     * @param _amountToDistribute The prize pool in L3P to be distributed
     * @param _number The number of players to rewards (see RewardStructure.sol for possible repartition)
     * ToDo: Prevent rounded number (_amountToDistribute != amountDistributed)
     */
    function distributeRewards(uint256 _amountToDistribute, uint8 _number)
        external
        override
        onlyAuthorized
        whenNotPaused
    {
        uint256 amountDistributed = 0;
        uint8[10] memory _rewardStructure = RewardStructure.getRewardStructure(_number);
        (address[10] memory _top10, ) = this.getTop10();
        uint256 array = _top10.length;

        for (uint256 i = 0; i < array; i++) {
            uint256 amountToTransfer = (_amountToDistribute * _rewardStructure[i]) / 100;
            if (amountToTransfer != 0) {
                amountDistributed += amountToTransfer;
                token.safeTransferFrom(admin, _top10[i], amountToTransfer);
            } else break;
        }
        assert(_amountToDistribute == amountDistributed);
        emit RewardsDistributed(_top10, _amountToDistribute, _rewardStructure);
    }

    /// @notice Reinitialize or update a player claimable amount during withdraw
    function resetClaimable(address _player, uint256 _amount)
        external
        override
        onlyAuthorized
        whenNotPaused
        returns (uint256 withdrawn)
    {
        uint256 balance = player[_player].claimable;

        if (_amount >= balance) {
            player[_player].claimable = 0;
            return balance;
        } else {
            player[_player].claimable -= _amount;
            return _amount;
        }
    }

    /* Functions related to NFT Boost:
     *********************************/

    /**
     * @notice Allows admin/owner to whitelist an NFT collection in the game;
     * @param _collection NFT collection address to be whitelisted;
     */
    function addAllowedCollection(address _collection) external override onlyAuthorized {
        isNftAllowed[_collection].nftContractAddress = _collection;
        isNftAllowed[_collection].isAllowed = true;
    }

    /**
     * @notice Allows admin/owner to blacklist an NFT collection in the game;
     * @param _collection NFT collection address to be blacklisted;
     */
    function removeAllowedCollection(address _collection) external override onlyAuthorized {
        isNftAllowed[_collection].isAllowed = false;
    }

    /// @notice See IGame interface;
    function setNftStatus(
        address _player,
        bool _isNFT,
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _nftBoost
    ) external override onlyAuthorized {
        _setNftStatus(_player, _isNFT, _nftContractAddress, _tokenId, _nftBoost);
    }

    /**
     * @notice Allows admin/owner to reset the NFT status of a player;
     * @param _player Player's address to reset;
     */
    function resetNftStatus(address _player) external override onlyAuthorized {
        require(_player != address(0), "Address 0");
        _resetNftStatus(_player);
    }

    /* Read Functions:
     *******************/

    /**
     * @notice Allows admin/owner to reset the NFT status of a player;
     * @param _player Player's address to check;
     */
    function isPlayerInGameId(address _player) external view override returns (bool) {
        if (player[_player].user != address(0)) {
            return true;
        } else return false;
    }

    /**
     * @notice Get all stats per player;
     * @param _player Player's address to check;
     */
    function getPlayerStats(address _player) external view override returns (SharedStructs.Player memory) {
        return player[_player];
    }

    /**
     * @notice Get Nft status per player;
     * @param _player Player's address to check;
     */
    function getPlayerNftStats(address _player) external view override returns (SharedStructs.NftStat memory) {
        return nftStat[_player];
    }

    /// @notice Get total amount of sessions played for this game;
    function getTotalSessionsPlayed() external view override returns (uint256) {
        uint256 numOfPlayers = numberOfPlayers;
        uint256 totalSessions = 0;
        for (uint256 i = 1; i <= numOfPlayers; i++) {
            address playerTemp = playerAddress[i];
            totalSessions += player[playerTemp].sessionsPlayed;
        }
        return totalSessions;
    }

    /// @notice Get Top 10 players
    function getTop10() external view override returns (address[10] memory, uint256[10] memory) {
        address[10] memory top10;
        uint256[10] memory scoreTemp;

        (top10[0], scoreTemp[0]) = _getHighestScore();

        for (uint256 i = 1; i < 9; i++) {
            (top10[i], scoreTemp[i]) = _getHighestBetween(top10[i - 1], scoreTemp[i - 1]);
        }
        return (top10, scoreTemp);
    }

    /* Private:
     ************/

    /**
     * @notice Private use;
     * @param _player Address of the player to update;
     * @param _sessionsPlayed Number of sessions played by the player since last update;
     * @param _xpWon Xp won by the player since last update;
     * @param _l3pWon L3P won by the player since last update;
     * @param _score Best score realized by the player since last update;
     */
    function _updatePlayerStats(
        address _player,
        uint256 _sessionsPlayed,
        uint256 _xpWon,
        uint256 _l3pWon,
        uint256 _score
    ) private onlyAuthorized whenNotPaused {
        SharedStructs.Player memory temp = player[_player];
        temp.xp += _xpWon;
        temp.sessionsPlayed += _sessionsPlayed;
        temp.claimable += _l3pWon;
        temp.totalWon += _l3pWon;
        temp.rankingScore = temp.rankingScore >= _score ? temp.rankingScore : _score;
        temp.bestScore = temp.bestScore >= _score ? temp.bestScore : _score;

        player[_player] = temp;
    }

    /**
     * @notice Private use;
     * @param _player Player's address to reset;
     */
    function _resetRankingScore(address _player) private returns (uint256) {
        uint256 oldScore = player[_player].rankingScore;
        if (oldScore > 0) {
            player[_player].rankingScore = 0;
        }
        return oldScore;
    }

    /**
     * @notice Private use;
     * @param _player Player's address to set;
     * @param _isNFT Is a NFT used?;
     * @param _nftContractAddress Nft contract's address if used;
     * @param _tokenId Nft token ID if used;
     * @param _nftBoost Nft perks/boost to be added;
     */
    function _setNftStatus(
        address _player,
        bool _isNFT,
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _nftBoost
    ) private {
        if (_isNFT) {
            // add boost to stakeholder NFT status and keep track of start day (since)
            nftStat[_player].isNft = true;
            nftStat[_player].nftContractAddress = _nftContractAddress;
            nftStat[_player].tokenId = _tokenId;
            nftStat[_player].boostValue = _nftBoost;
            nftStat[_player].since = block.timestamp;
        }
        // Reset only if needed (NFT sold/transfered)
        else if (nftStat[_player].isNft) {
            _resetNftStatus(_player);
        }
    }

    /**
     * @notice Private use;
     * @param _player Player's address to reset;
     */
    function _resetNftStatus(address _player) private {
        nftStat[_player].isNft = false;
        nftStat[_player].nftContractAddress = address(0);
        nftStat[_player].tokenId = 0;
        nftStat[_player].boostValue = 0;
        nftStat[_player].since = 0;
    }

    /* Utils:
     **********/

    /**
     * @notice Private use;
     * @notice Return the highest uint of a given array (no sort needed!)
     */
    function _getHighestScore() private view returns (address, uint256) {
        uint256 array = numberOfPlayers;
        uint256 highest = 0;
        address player1;
        for (uint256 i = 0; i < array; i++) {
            address playerTemp = playerAddress[i];
            uint256 scoreTemp = player[playerTemp].rankingScore;
            if (scoreTemp > highest) {
                highest = scoreTemp;
                player1 = playerTemp;
            }
        }
        return (player1, highest);
    }

    /**
     * @notice Private use;
     * @notice Return the second highest uint after the uint given as parameter (no sort needed!)
     * @notice The player's address associated with highest score is used to prevent collusion;
     */
    function _getHighestBetween(address _actualPlayer, uint256 _actualHighest) private view returns (address, uint256) {
        uint256 array = numberOfPlayers;
        uint256 secondHighest = 0;
        address playerTop10;
        for (uint256 i = 0; i < array; i++) {
            address playerTemp = playerAddress[i];
            uint256 scoreTemp = player[playerTemp].rankingScore;
            if (scoreTemp == _actualHighest) {
                // Prevent duplicate if same score
                if (playerTemp != _actualPlayer) {
                    secondHighest = scoreTemp;
                    playerTop10 = playerTemp;
                }
            } else if (scoreTemp > secondHighest && scoreTemp < _actualHighest) {
                secondHighest = scoreTemp;
                playerTop10 = playerTemp;
            }
        }
        return (playerTop10, secondHighest);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../libraries/SharedStructs.sol";

/**
 * @title Interface for Game.sol contract;
 * @author @Pedrojok01
 * @notice Allows the factory to communicate with each game;
 */

interface IGame {
    /**
     * @notice Add a new player  (when blockchain function unlocked)
     * @param _player Array of player's addresses to update;
     * @param _xp Player's XP gained off-chain until now;
     * @param _sessionsPlayed Player's total sessions played off-chain until now;
     * @param _claimable Player's claimable amount gained off-chain until now (also == totalWon);
     * @param _rankingScore Player's best weekly score off-chain until now;
     * @param _bestScore Player's best overall score off-chain until now;
     */
    function addNewPlayer(
        address _player,
        uint256 _xp,
        uint256 _sessionsPlayed,
        uint256 _claimable,
        uint256 _rankingScore,
        uint256 _bestScore
    ) external returns (uint256 userIndex);

    /**
     * @notice Update all players stats at once
     * @param _players Array of player's addresses to update;
     * @param _numbers Array containing all data to be updated. Numbers, in order, are:
     *  [uint256 _sessionsPlayed, uint256 _xpWon, uint256 _l3pWon, uint256 _score];
     */
    function updateAllPlayersStats(address[] calldata _players, uint256[] calldata _numbers) external;

    /// @notice Reinitialize all players hebdo scores
    function resetAllrankingScores() external;

    /**
     * @notice Distribute ranking rewards to Top players
     * @param _amountToDistribute Total amount of tokens to be distributed to the Top ranks;
     * @param _number Distribution repartition (see RewardStructure.sol library)
     */
    function distributeRewards(uint256 _amountToDistribute, uint8 _number) external;

    /**
     * @notice Reinitialize or update a player claimable amount after a withdraw;
     * @param _player Player's address;
     * @param _amount Amount withdrawn;
     */
    function resetClaimable(address _player, uint256 _amount) external returns (uint256 withdrawn);

    /* Functions related to NFT Boost:
     *********************************/

    /**
     * @notice Whitelist an NFts collection in a game;
     * @param _collection Contract address of the NFTs collection to be whitelisted;
     */
    function addAllowedCollection(address _collection) external;

    /**
     * @notice Blacklist an NFts collection in a game;
     * @param _collection Contract address of the NFTs collection to be blacklisted;
     */
    function removeAllowedCollection(address _collection) external;

    /**
     * @notice Whitelist an NFts collection in a game;
     * @param _account Player's address to update;
     * @param _isNFT Activate/desactivate the NFT's effect;
     * @param _nftContractAddress NFT's contract address;
     * @param _tokenId NFT's TokenID;
     * @param _nftBoost NFT's effect;
     */
    function setNftStatus(
        address _account,
        bool _isNFT,
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _nftBoost
    ) external;

    /// @notice Reinitialize a players NFT status
    /// @param _player Player's address to reset;
    function resetNftStatus(address _player) external;

    /* View Functions:
     *******************/

    /**
     * @notice Check is a player played a specific Game ID;
     * @param _player Player's address to be checked;
     * @return Bool True if player exist || False if not;
     */
    function isPlayerInGameId(address _player) external view returns (bool);

    /// @notice Get all stats per player;
    /// @param _player Player's address to be checked;
    function getPlayerStats(address _player) external view returns (SharedStructs.Player memory);

    /// @notice Get Nft status per player;
    /// @param _player Player's address to be checked;
    function getPlayerNftStats(address _player) external view returns (SharedStructs.NftStat memory);

    /// @notice Get total amount of sessions played for a game
    function getTotalSessionsPlayed() external view returns (uint256);

    /// @notice Get Top 10 players
    function getTop10() external view returns (address[10] memory, uint256[10] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Library shared between multiple contracts;
 * @author Pedrojok01
 * @notice Allows the contracts to interact with those struct;
 */

library SharedStructs {
    /// @notice Track all datas per player
    struct Player {
        address user;
        uint256 xp;
        uint256 sessionsPlayed;
        uint256 claimable;
        uint256 totalWon;
        uint256 rankingScore;
        uint256 bestScore;
    }

    /// @notice Tracks allowed NFT collections
    struct NftsAllowed {
        address nftContractAddress;
        bool isAllowed;
    }

    /// @notice Track the NFT status per player
    struct NftStat {
        bool isNft;
        address nftContractAddress;
        uint256 tokenId;
        uint256 boostValue;
        uint256 since;
    }

    /// @notice Allows to get the general stats per player
    struct GlobalPlayerStats {
        address player;
        uint256 totalXp;
        uint256 totalSessionsPlayed;
        uint256 totalClaimable;
        uint256 globalWon;
        uint256 consecutiveLogin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Get a specific distribution for an amount of players;
 * @author Pedrojok01
 * @notice Allows to change the rewards distribution depending on players's numbers.
 * @notice Edit the rewards structure to match any desired pattern.
 * @dev Return <rewards> - array containing the wanted repartition (numbers represent pourcentage)
 */

library RewardStructure {
    /// @dev Enter an integer to select the wanted repartition (3 || 5 || 10)
    function getRewardStructure(uint8 x) public pure returns (uint8[10] memory rewards) {
        require(x == 10 || x == 5 || x == 3, "invalid value");
        if (x == 10) {
            rewards = [31, 20, 15, 10, 8, 6, 4, 3, 2, 1];
        } else if (x == 5) {
            rewards = [45, 25, 15, 10, 5, 0, 0, 0, 0, 0];
        } else if (x == 3) {
            rewards = [50, 30, 20, 0, 0, 0, 0, 0, 0, 0];
        }
        return rewards;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}