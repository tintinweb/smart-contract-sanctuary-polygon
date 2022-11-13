// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./LiquidityVault.sol";
import "./LiquidityWarsVrf.sol";
import "./LiquidityWarsConfig.sol";

// Temporary
import "hardhat/console.sol";

/* Types */
struct PlayerParams {
    uint256 resources;
    uint256 numberOfLpTokens;
    //address playerAddress;
    Troop troops;
    uint16 farmLvl;
    uint16 barracksLvl;
    uint16 hideawayLvl;
    uint16 wallsLvl;
    Nation nation;
}

/* Errors */
error LiquidityWars__WrongInputValue();
error LiquidityWars__NotEnoughResources(uint256 resourcesRequired);
error LiquidityWars__WrongInfrastructure(Infrastructure building);
error LiquidityWars__NotLiquidityVaultCall();
error LiquidityWars__MsgSenderNotInGame();
error LiquidityWars__checkUpkeepError();

/** @title Game built with usage of Dex pool as a core of reward system.
 *  @author Kamil Palenik
 *  @notice The purpose is to attract more liquidity to certain DEX.
 *  @dev
 */
contract LiquidityWars is AutomationCompatibleInterface, Ownable {
    /* Consts - TODO interfaces for reading constants! */
    uint256 private constant INITIAL_RESOURCES = 1000;
    uint8 private constant MAX_NR_OF_LVLS = 50;
    uint8 private constant NEXT_BUILDING_COSTS = 25; //25% more than previous building level
    uint256 private constant INITIAL_BUILDING_COSTS = 200;
    uint256 private constant MAX_NUMBER_OF_PLAYERS = 16;
    uint256 private constant READY_CONDITIONS_MET = 0x1;
    uint256 private constant RUNNING_CONDITIONS_MET = 0x2;
    uint256 private constant TIME_NOT_ELAPSED = 0xFF;
    uint256 private constant RUNNING_CONDITIONS_NOT_MET = 0xFD;

    /* Variables - TODO make all public variables private and create getters */
    /* Params changeable by owner */
    uint256 private costOfAttack = 40;
    uint256 private distributionInterval;

    /* Variables */
    LiquidityWarsConfig configContract;
    LiquidityVault liquidityVaultContract;
    LiquidityWarsVrf liquidityVrfContract;

    GameState private gameState = GameState.READY; // TODO include state not configured ?
    bool private processing = false;

    uint256 public gameId; 
    uint256 private lastDistributed = 0;
    uint256 private totalSupplyOfResources = 0;
    uint256 private vaultResources = 0;
    mapping(address => PlayerParams) playerParams;
    address[] players;
    BuildingParams[] internal buildingsParams;

    /* Events */
    event AttackHappenned(
        address attacker,
        address defender,
        uint256 attackerTroopsSurvived,
        uint256 defenderTroopsSurvived,
        uint256 robbedResources,
        uint256 gameId
    );
    event ResourcesUpdated(uint256 gameId);
    event RakingUpdated(
        address playerAddr,
        uint256 playerResources,
        uint256 playerRaking,
        uint256 gameId
    );

    /* Modifiers */
    modifier onlyReady() {
        if (gameState != GameState.READY) {
            revert LiquidityVault__WrongGameState(gameState);
        }
        _;
    }

    modifier onlyRunning() {
        if (gameState != GameState.RUNNING) {
            revert LiquidityVault__WrongGameState(gameState);
        }
        _;
    }

    modifier onlyCalibrated() {
        if (!configContract.getCalibratioStatus()) {
            revert LiquidityVault__GameNotCalibrated();
        }
        _;
    }

    modifier nonReentrant() {
        require(processing == false, "Already processing");
        processing = true;
        _;
        processing = false;
    }

    modifier onlyLiquidityVault() {
        _assignLiquidityVaultContract();
        if (msg.sender != address(liquidityVaultContract)) {
            revert LiquidityWars__NotLiquidityVaultCall();
        }
        _;
    }

    /* Constructor */
    constructor(
        uint256 _distributionInterval,
        address _configAddress,
        address _VRFAddress
    ) {
        distributionInterval = _distributionInterval;
        configContract = LiquidityWarsConfig(_configAddress);
        liquidityVrfContract = LiquidityWarsVrf(_VRFAddress);
    }

    /* onlyOwner setters */
    function setCostsOfAttack(uint256 _costOfAttack) external onlyOwner {
        costOfAttack = _costOfAttack;
    }

    /* setters */
    function startGame(bytes memory _playersEncoded)
        external
        onlyLiquidityVault
    {
        gameId = block.timestamp;
        gameState = GameState.RUNNING;
        address[] memory _players = abi.decode(_playersEncoded, (address[]));
        for (uint256 i = 0; i < _players.length; i++) {
            _insertPlayer(_players[i]);
        }

        uint256 j = 0;
        BuildingParams memory buildingParam = configContract.getBuildingParam(
            j
        );

        while (buildingParam.initialAbility != 0) {
            console.log("Ability:%s", buildingParam.initialAbility);
            buildingsParams.push(buildingParam);
            j++;
            buildingParam = configContract.getBuildingParam(j);
        }
    }

    function endGame() external onlyLiquidityVault {
        gameState = GameState.READY;
        _ranking();
        _deleteDataFromPreviousGame();
    }

    function _ranking() private {
        uint256[] memory playerResources = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            playerResources[i] = getRatioOfResources(players[i]);
            // console.log("Player %s [%s]: %s", i, players[i], playerResources[i]);
        }
        uint256[] memory sortedPlayerResources = _sort(playerResources);
        
        for (uint256 i = 0; i < players.length; i++) {
            uint index = _findArrayIndex(playerResources, sortedPlayerResources[i]);
            // console.log("RakingUpdated: %s | %s | %s", players[index], sortedPlayerResources[i], i);
            emit RakingUpdated(players[index], sortedPlayerResources[i], i, gameId);
        }
    }

    function _deleteDataFromPreviousGame() private {
        for (uint256 i = 0; i < players.length; i++) {
            delete playerParams[players[i]];
        }
        delete players;
        totalSupplyOfResources = 0;
    }

    // Ref: https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
    function _sort(uint[] memory arr) private pure returns(uint[] memory) {
        uint[] memory copyArr = new uint[](arr.length);
        for(uint i = 0; i < arr.length; i++) {
            copyArr[i] = arr[i]; 
        }
       _quickSort(copyArr, int(0), int(copyArr.length - 1));
       return copyArr;
    }

    // Ref: https://towardsdatascience.com/an-overview-of-quicksort-algorithm-b9144e314a72
    function _quickSort(uint[] memory arr, int left, int right) private pure {
        int i = left;
        int j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] > pivot) i++;
            while (pivot > arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSort(arr, left, j);
        if (i < right)
            _quickSort(arr, i, right);
    }

    function _findArrayIndex(uint[] memory array, uint value) private pure returns(uint) {
        uint i = 0;
        while (array[i] != value) {
            i++;
        }
        return i;
    }

    // Hash tables - not necessary for the MVP ?
    function _insertPlayer(address _playerAddress) private {
        PlayerInfo memory playerInfo = liquidityVaultContract.getPlayerInfo(
            _playerAddress
        );
        players.push(_playerAddress);
        Troop memory newTroop = configContract.getTroopByTokenAddress(
            playerInfo.tokenAddress
        );
        playerParams[_playerAddress] = PlayerParams(
            INITIAL_RESOURCES,
            playerInfo.tokenAmount,
            //_playerAddress,
            newTroop,
            1,
            1,
            1,
            1,
            configContract.getNationByToken(playerInfo.tokenAddress)
        );
        console.log(
            "Initiated player: %s with farmlvl: %s",
            _playerAddress,
            playerParams[_playerAddress].farmLvl
        );
        totalSupplyOfResources += INITIAL_RESOURCES;
    }

    function _assignLiquidityVaultContract() private {
        liquidityVaultContract = LiquidityVault(
            configContract.getLiquidityVaultAddress()
        );
    }

    function _addResources(uint256 _amount, PlayerParams storage _player)
        private
    {
        console.log(
            "Player resources and total supply before: p %s, tot %s",
            _player.resources,
            totalSupplyOfResources
        );
        _player.resources += _amount;
        totalSupplyOfResources += _amount;
        console.log(
            "Player resources and total supply after: p %s, tot %s",
            _player.resources,
            totalSupplyOfResources
        );
    }

    function _deductResources(uint256 _amount, PlayerParams storage _player)
        private
    {
        _player.resources -= _amount;
        totalSupplyOfResources -= ((_amount * 9) / 10); // Burn 90%
        vaultResources += (_amount - ((_amount * 9) / 10)); // Transfer 10% to the vault
    }

    /**
     * @dev To be used in performUpkeep
     */
    function _distributeResources() private {
        address[] memory _players = players;
        uint256 resourcesToDistribute;
        for (uint256 i = 0; i < players.length; i++) {
            resourcesToDistribute = getBuildingAbility(
                playerParams[_players[i]].farmLvl,
                Infrastructure.FARM
            );
            console.log(
                "Resources to distribute for player %s: %s",
                i,
                resourcesToDistribute
            );
            _addResources(resourcesToDistribute, playerParams[_players[i]]);
        }
    }

    function trainTroops(uint256 _numberOfTroops) external onlyRunning {
        PlayerParams storage _player = playerParams[msg.sender];
        uint256 totalCosts = getTotalCostOfTroop(msg.sender) * _numberOfTroops;
        if (_player.resources <= totalCosts) {
            revert LiquidityWars__NotEnoughResources(totalCosts);
        }
        _player.troops.number += uint64(_numberOfTroops);
        console.log("Number of troops: %s", _player.troops.number);
        _deductResources(totalCosts, _player);
    }

    function upgradeBuilding(Infrastructure _building) external onlyRunning {
        if (playerParams[msg.sender].numberOfLpTokens == 0) {
            revert LiquidityWars__MsgSenderNotInGame();
        }
        PlayerParams storage _player = playerParams[msg.sender];

        uint256 costsOfUpgrade;

        if (_building == Infrastructure.FARM) {
            costsOfUpgrade = getCostOfUpgrade(_player.farmLvl + 1);
            if (_player.resources < costsOfUpgrade) {
                revert LiquidityWars__NotEnoughResources(_player.resources);
            }
            _deductResources(costsOfUpgrade, _player);
            _player.farmLvl++;
        } else if (_building == Infrastructure.BARRACKS) {
            costsOfUpgrade = getCostOfUpgrade(_player.barracksLvl + 1);
            if (_player.resources < costsOfUpgrade) {
                revert LiquidityWars__NotEnoughResources(_player.resources);
            }
            _deductResources(costsOfUpgrade, _player);
            _player.barracksLvl++;
        } else if (_building == Infrastructure.HIDEAWAY) {
            costsOfUpgrade = getCostOfUpgrade(_player.hideawayLvl + 1);
            if (_player.resources < costsOfUpgrade) {
                revert LiquidityWars__NotEnoughResources(_player.resources);
            }
            _deductResources(costsOfUpgrade, _player);
            _player.hideawayLvl++;
        } else if (_building == Infrastructure.WALLS) {
            costsOfUpgrade = getCostOfUpgrade(_player.wallsLvl + 1);
            if (_player.resources < costsOfUpgrade) {
                revert LiquidityWars__NotEnoughResources(_player.resources);
            }
            _deductResources(costsOfUpgrade, _player);
            _player.wallsLvl++;
        } else {
            revert LiquidityWars__WrongInfrastructure(_building);
        }
    }

    /**
     * @notice Function should be used to attack another player
     * @dev Function uses all the troops(the troops cannot be splitted due to resting time issues)
     * TODO - resting time !! Be carefull on stack too deep error !!
     */
    function attackPlayer(address _playerToAttack) external onlyRunning {
        PlayerParams memory attacker = playerParams[msg.sender];
        PlayerParams memory defender = playerParams[_playerToAttack];
        if (attacker.resources < costOfAttack) {
            revert LiquidityWars__NotEnoughResources(attacker.resources);
        }
        uint256 attackerTroopsSurvived = attacker.troops.number;
        uint256 defenderTroopsSurvived = defender.troops.number;
        uint256 defenderTroopDefense = defender.troops.defense +
            ((defender.troops.defense *
                getBuildingAbility(defender.wallsLvl, Infrastructure.WALLS)) /
                100);
        uint256 attackerTotalTroopHealth = attacker.troops.health *
            attacker.troops.number;
        uint256 defenderTotalTroopHealth = defender.troops.health *
            defender.troops.number;

        uint256 attackerFactor;
        uint256 defenderFactor;
        uint256 numberOfCombats;
        uint256 robbedResources;

        _deductResources(costOfAttack, playerParams[msg.sender]);
        (attackerFactor, defenderFactor, numberOfCombats) = liquidityVrfContract
            .getRandomFactorsForBattle();
        for (uint256 idx = numberOfCombats; idx > 0; idx--) {
            /* Defender defends himself first */
            attackerTotalTroopHealth -= ((defenderTroopDefense *
                defenderTroopsSurvived *
                defenderFactor) / 10); // divide by 10 because VRF factors are 10 times greater to avoid floating numbers
            attackerTroopsSurvived =
                attackerTotalTroopHealth /
                attacker.troops.health;
            defenderTotalTroopHealth -= ((attacker.troops.attack *
                attackerTroopsSurvived *
                attackerFactor) / 10); // divide by 10 because VRF factors are 10 times greater to avoid floating numbers
            defenderTroopsSurvived =
                defenderTotalTroopHealth /
                defender.troops.health;
        }
        playerParams[msg.sender].troops.number = uint64(attackerTroopsSurvived);
        playerParams[_playerToAttack].troops.number = uint64(
            defenderTroopsSurvived
        );

        robbedResources = _calculateRobbedResources(
            defender.resources,
            defender.hideawayLvl,
            (attackerTroopsSurvived * attacker.troops.capacity)
        );
        playerParams[msg.sender].resources += robbedResources;
        playerParams[_playerToAttack].resources -= robbedResources;
        emit AttackHappenned(
            msg.sender,
            _playerToAttack,
            attackerTroopsSurvived,
            defenderTroopsSurvived,
            robbedResources,
            gameId
        );
    }

    function _calculateRobbedResources(
        uint256 _defenderResources,
        uint16 _defenderHideawayLvl,
        uint256 _attackerCapacity
    ) private view returns (uint256) {
        uint256 robbedResources = 0;
        uint256 defenderAvailableResources = _defenderResources -
            getBuildingAbility(_defenderHideawayLvl, Infrastructure.HIDEAWAY);
        if (defenderAvailableResources > _attackerCapacity) {
            robbedResources = _attackerCapacity;
        } else {
            robbedResources = defenderAvailableResources;
        }
        return robbedResources;
    }

    /* getters */
    function getTotalCostOfTroop(address _playerAddress)
        public
        view
        returns (uint256)
    {
        PlayerParams memory _player = playerParams[_playerAddress];
        uint256 barracksCostReduction = (getBuildingAbility(
            _player.barracksLvl,
            Infrastructure.BARRACKS
        ) - buildingsParams[uint256(Infrastructure.BARRACKS)].initialAbility);
        return (configContract.getTroopByNation(_player.nation).cost -
            barracksCostReduction);
    }

    function getTroopAttributes(Nation _nation)
        external
        view
        returns (Troop memory)
    {
        return configContract.getTroopByNation(_nation);
    }

    function getCurrentBuildingLevel(Infrastructure _building)
        external
        view
        returns (uint256)
    {
        PlayerParams memory _player = playerParams[msg.sender];
        console.log(
            "Player: %s has farm level: %s",
            msg.sender,
            _player.farmLvl
        );
        if (_building == Infrastructure.FARM) {
            console.log(_player.farmLvl);
            return _player.farmLvl;
        } else if (_building == Infrastructure.BARRACKS) {
            return _player.barracksLvl;
        } else if (_building == Infrastructure.HIDEAWAY) {
            return _player.hideawayLvl;
        } else if (_building == Infrastructure.WALLS) {
            return _player.wallsLvl;
        } else {
            revert LiquidityWars__WrongInputValue();
        }
    }

    function getBuildingAbility(uint256 _level, Infrastructure _building)
        public
        view
        returns (uint256)
    {
        uint256 buildingAbility = buildingsParams[uint256(_building)]
            .initialAbility;
        console.log("1.Building Ability %s", buildingAbility);
        for (uint256 j = _level; j > 1; j--) {
            /* each farm level will increase resources to distribute */
            buildingAbility += ((buildingAbility *
                buildingsParams[uint256(_building)].bonus) / 100);
            console.log("2.Building Ability %s", buildingAbility);
        }
        return buildingAbility;
    }

    function getCostOfUpgrade(uint16 _level) public view returns (uint256) {
        uint256 costsOfUpgrade = INITIAL_BUILDING_COSTS;
        for (uint256 i = _level; i > 1; i--) {
            costsOfUpgrade += ((costsOfUpgrade * NEXT_BUILDING_COSTS) / 100);
            console.log("%s.Costs Of upgrades: %s", i, costsOfUpgrade);
        }
        return costsOfUpgrade;
    }

    function getTotalSupplyOfResources()
        external
        view
        onlyRunning
        returns (uint256)
    {
        return totalSupplyOfResources;
    }

    function getRatioOfResources(address _playerAddress)
        public
        view
        returns (uint256)
    {
        //10**10 is precision !!
        if (_playerAddress == address(liquidityVaultContract)) {
            return ((PRECISION * vaultResources) / totalSupplyOfResources);
        } else {
            return ((PRECISION * playerParams[_playerAddress].resources) /
                totalSupplyOfResources);
        }
    }

    function getVaultResources() external view returns (uint256) {
        return vaultResources;
    }

    function getPlayerResources(address _playerAddress)
        public
        view
        onlyRunning
        returns (uint256)
    {
        return playerParams[_playerAddress].resources;
    }

    function getVillageSize(address _playerAddress)
        public
        view
        onlyRunning
        returns (uint256)
    {
        PlayerParams memory player = playerParams[_playerAddress];
        return (player.resources +
            (uint256(
                player.farmLvl +
                    player.barracksLvl +
                    player.hideawayLvl +
                    player.wallsLvl
            ) * 100) +
            (uint256(player.troops.number) * 5));
    }

    function getNumberOfTroops() external view returns (uint256) {
        return playerParams[msg.sender].troops.number;
    }

    function getGameState() external view returns (GameState) {
        return gameState;
    }

    function getCurrentGameId() external view returns (uint256) {
        return gameId;
    }

    /** TODO:
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for the "upkeepNeeded" to return true for distribution:
     * I.The following should be true in order to return true:
     * 1.
     */
    function checkUpkeep(bytes memory checkData)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        performData = abi.encode(0);
        uint256 checkOption = abi.decode(checkData, (uint256));
        if (checkOption == 1) {
            if (gameState == GameState.RUNNING) {
                if (
                    (block.timestamp - lastDistributed) > distributionInterval
                ) {
                    upkeepNeeded = true;
                    performData = abi.encode(RUNNING_CONDITIONS_MET);
                } else {
                    performData = abi.encode(TIME_NOT_ELAPSED);
                }
            } else {
                performData = abi.encode(RUNNING_CONDITIONS_NOT_MET);
            }
        }
        return (upkeepNeeded, performData);
    }

    /**
     *
     * @dev
     */
    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded, bytes memory data) = checkUpkeep(abi.encode(1));
        uint256 checkOption = abi.decode(performData, (uint256));
        if ((abi.decode(data, (uint256)) != checkOption) || (!upkeepNeeded)) {
            revert LiquidityWars__checkUpkeepError();
        }
        if (checkOption == TIME_NOT_ELAPSED) {
            revert LiquidityVault__TimeNotPassed(
                (block.timestamp - lastDistributed),
                distributionInterval
            );
        }
        if (checkOption == RUNNING_CONDITIONS_MET) {
            uint256 idx;
            for (idx = 0; idx < players.length; idx++) {
                _distributeResources();
            }
            lastDistributed = block.timestamp;
            emit ResourcesUpdated(gameId);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityWarsConfig.sol";
import "./LiquidityWars.sol";
import "./Strategies.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

// Temporary
import "hardhat/console.sol";

/* Enums */
enum GameState {
    // Potential INIT state
    READY, // open to entry
    RUNNING // game is processing
    // SUSPENDED there is no game active or open entry
}
struct PlayerInfo {
    address tokenAddress;
    uint256 tokenAmount;
}

/* Errors */
error LiquidityVault__NotSufficientAmount(
    uint256 expectedAmount,
    uint256 amount
);
error LiquidityVault__WrongToken();
error LiquidityVault__NotValidAddress();
error LiquidityVault__NoEmptySlotsLeft();
error LiquidityVault__WrongGameState(GameState);
error LiquidityVault__TimeNotPassed(uint256, uint256);
error LiquidityVault__WrongAddress(address);
error LiquidityVault__GameNotCalibrated();
error LiquidityVault__PlayerAlreadyRegistered();
error LiquidityVault__checkUpkeepError();
error LiquidityVault__checkOptionWrong();

contract LiquidityVault is Ownable, AutomationCompatibleInterface {
    /* Consts */
    uint8 private constant MAX_NUMBER_OF_PLAYERS = 16;
    //uint256 private MINIMUM_LINK_AMOUNT = 10 * (10**18); //10 LINK
    uint256 private constant READY_CONDITIONS_MET = 0x1;
    uint256 private constant RUNNING_CONDITIONS_MET = 0x2;
    uint256 private constant TIME_NOT_ELAPSED = 0xFF;
    uint256 private constant NOT_ENOUGH_PLAYERS = 0xFE;

    address private immutable linkAddress;

    /* Calibrations */
    uint256 internal readyDuration = 3 days;
    uint256 internal gameDuration = 30 days;

    /*Events */
    event DepositDone();
    event RewardsDistributed();
    event GameStarted();
    event GameEnded();

    /* Variables */
    LiquidityWarsConfig private configContract;
    LiquidityWars private liquidityWarsContract;
    Strategies private immutable strategies;

    address[] private players;
    mapping(address => PlayerInfo) private playerInfo;
    uint256 private initRunningTime;
    uint256 private initReadyTime;
    uint256 private totalSupplyOfRewards = 0;
    GameState private gameState = GameState.READY; // TODO include state not configured ?
    bool private processing = false;

    /* Modifiers */
    modifier onlyReady() {
        if (gameState != GameState.READY) {
            revert LiquidityVault__WrongGameState(gameState);
        }
        _;
    }

    modifier onlyRunning() {
        if (gameState != GameState.RUNNING) {
            revert LiquidityVault__WrongGameState(gameState);
        }
        _;
    }

    modifier onlyCalibrated() {
        if (!configContract.getCalibratioStatus()) {
            revert LiquidityVault__GameNotCalibrated();
        }
        _;
    }

    modifier nonReentrant() {
        require(processing == false, "Already processing");
        processing = true;
        _;
        processing = false;
    }

    modifier onlyContractOrOwner() {
        if (msg.sender != address(this) && msg.sender != owner()) {
            revert LiquidityVault__WrongAddress(msg.sender);
        }
        _;
    }

    /* Constructor */
    constructor(
        address _linkAddress,
        address _configAddress,
        address _strategiesAddress
    ) {
        linkAddress = _linkAddress;
        initReadyTime = block.timestamp;
        configContract = LiquidityWarsConfig(_configAddress);
        strategies = Strategies(_strategiesAddress);
    }

    /* onlyOwner setters */
    /**
     * @dev used by the owner to set ready duration param
     *
     * @param _readyDuration - how long the game will wait for potential players to deposit LPs (default: 3 days)
     */
    function setReadyDuration(uint256 _readyDuration)
        external
        onlyOwner
        onlyReady
    {
        readyDuration = _readyDuration;
    }

    /**
     * @dev used by the owner to set game duration param
     *
     * @param _gameDuration - how long the game will last (default: 30 days)
     */
    function setGameDuration(uint256 _gameDuration)
        external
        onlyOwner
        onlyReady
    {
        gameDuration = _gameDuration;
    }

    // /**
    //  * @dev used by the owner to fund contract with LINK tokens required to use keepers and VRF
    //  *
    //  */
    // function fundLink(uint256 _amount) external onlyOwner returns (uint256) {
    //     IERC20 linkToken = IERC20(linkAddress);
    //     uint256 ownerBalance = linkToken.balanceOf(msg.sender);
    //     if (linkToken.balanceOf(msg.sender) == 0) {
    //         revert LiquidityVault__NotSufficientAmount(1, ownerBalance);
    //     }
    //     linkToken.transferFrom(msg.sender, address(this), _amount);
    //     return linkToken.balanceOf(address(this));
    // }

    /**
     * @notice Function used to start the game and change state machine to RUNNING. It shall be called by keepers.
     *
     */
    function startTheGame()
        private
        /* onlyContractOrOwner */
        onlyCalibrated
        onlyReady
    {
        address[] memory allowedTokens = configContract.getAllowedTokens();
        // uint256 _linkAmount = getTokensInContract(linkAddress);
        _assignLiquidityWarsContract();
        // if (_linkAmount <= MINIMUM_LINK_AMOUNT) {
        //     revert LiquidityVault__NotSufficientAmount(
        //         _linkAmount,
        //         MINIMUM_LINK_AMOUNT
        //     );
        // }

        //TODO for loop
        uint256 balance = IERC20(allowedTokens[0]).balanceOf(address(this));
        if (balance > 0) {
            IERC20(allowedTokens[0]).approve(address(strategies), balance);
            strategies.startStrategy(0, address(0), allowedTokens[0]);
        }

        initRunningTime = block.timestamp;
        gameState = GameState.RUNNING;
        liquidityWarsContract.startGame(abi.encode(players));
        emit GameStarted();
    }

    /**
     * @notice Function used to end the game and change state machine to READY. It shall be called by keepers.
     */
    function endTheGame()
        private
        /* onlyContractOrOwner */
        onlyRunning
    {
        address[] memory allowedTokens = configContract.getAllowedTokens();
        uint256 currentTime = block.timestamp - initRunningTime;
        if (currentTime <= gameDuration) {
            revert LiquidityVault__TimeNotPassed(currentTime, gameDuration);
        }
        gameState = GameState.READY;
        initReadyTime = block.timestamp;

        //TODO for loop
        // console.log("Stopping strategy");
        strategies.stopStrategy(0, address(0), allowedTokens[0]);
        totalSupplyOfRewards = IERC20(address(strategies)).balanceOf(
            address(this)
        );
        // console.log("Distributing..");
        distributeRewards(address(strategies));
        _deleteDataFromPreviousGame();
        liquidityWarsContract.endGame();
        emit GameEnded();
    }

    /* Setters */
    function _assignLiquidityWarsContract() private {
        liquidityWarsContract = LiquidityWars(
            configContract.getLiquidityWarsAddress()
        );
    }

    function _deleteDataFromPreviousGame() private {
        for (uint256 i = 0; i < players.length; i++) {
            delete playerInfo[players[i]];
        }
        delete players;
    }

    /**
     * @notice Function depositing LP token. Deposit is associated with registering in the game. Function register player in the game with initial params.
     *
     * @param _tokenAddress - token address which must be included in allowed tokens. It is associated with the nation.
     * @param _amount - should be greater or equal to expected amount calculated from getAmountOfLpTokensRequired
     */
    function depositLpToken(address _tokenAddress, uint256 _amount)
        public
        nonReentrant /* issue: can prevent paraller deployment of two different players */
        onlyCalibrated
        onlyReady
    {
        uint256 expectedAmount = configContract.getAmountOfLpTokensRequired(
            _tokenAddress
        );
        // console.log(
        //     "Checks... Expected amount is of token(%s): %s",
        //     _tokenAddress,
        //     expectedAmount
        // );
        console.log("Amount is: %s", _amount);
        if (!(configContract.checkIfTokenIsAllowed(_tokenAddress))) {
            revert LiquidityVault__WrongToken();
        }
        if (expectedAmount > _amount) {
            revert LiquidityVault__NotSufficientAmount(expectedAmount, _amount);
        }
        if (players.length >= MAX_NUMBER_OF_PLAYERS) {
            revert LiquidityVault__NoEmptySlotsLeft();
        }
        if (playerInfo[msg.sender].tokenAddress != address(0)) {
            revert LiquidityVault__PlayerAlreadyRegistered();
        }
        console.log("ERC20 transfers");
        IUniswapV2Pair _depositedToken = IUniswapV2Pair(_tokenAddress);
        uint256 _vaultBalance = _depositedToken.balanceOf(address(this));

        // console.log(
        //     "Player's allowance is: %s",
        //     _depositedToken.allowance(msg.sender, address(this))
        // );
        _depositedToken.transferFrom(msg.sender, address(this), _amount);

        // console.log("Assertion");
        // console.log(
        //     "Vault's balance is: %s",
        //     _depositedToken.balanceOf(address(this))
        // );
        // console.log("Amount is: %s", _amount);
        assert(
            _vaultBalance + _amount == _depositedToken.balanceOf(address(this))
        );
        // console.log("Pushing..");
        /* TODO ??: Hash table dependent on msg.sender instead simply pushing */
        // PlayerInfo
        //     memory newPlayer = totalSupplyOfResources += INITIAL_RESOURCES;
        players.push(msg.sender);
        playerInfo[msg.sender] = PlayerInfo(_tokenAddress, _amount);

        emit DepositDone();
    }

    function _claimTokens(address _playerAddress, uint256 _rewardsFromToken)
        private
        returns (uint256, uint256)
    {
        // console.log("Sender: %s, This: %s", msg.sender, address(this));
        // if (msg.sender != address(this)) {
        //     revert LiquidityVault__NotValidAddress();
        // }
        // Game State READY require ?
        uint256 numberLpTokensToClaim = playerInfo[_playerAddress].tokenAmount;
        // TODO: External LiquidityWar call getRewardsToClaim();
        uint256 rewardsToClaim = (_rewardsFromToken *
            liquidityWarsContract.getRatioOfResources(_playerAddress)) /
            PRECISION;
        // console.log(
        //     "Ratio of resources: %s",
        //     liquidityWarsContract.getRatioOfResources(_playerAddress)
        // );
        // console.log(
        //     "Rewards for player: %s to claim are: %s",
        //     _playerAddress,
        //     rewardsToClaim
        // );
        //  = totalSupplyOfRewards *
        //     (numberOfResources / totalSupplyOfResources);
        address tokenAddress = playerInfo[_playerAddress].tokenAddress;
        // players[playerAddressToId[_playerAddress]].numberOfLpTokens = 0;
        // players[playerAddressToId[_playerAddress]].resources = 0;
        IERC20 lpTokenToClaim = IERC20(tokenAddress);
        // console.log(
        //     "Contract LP balance: %s",
        //     lpTokenToClaim.balanceOf(address(this))
        // );
        // console.log("Transfering LP tokens (%s)...", numberLpTokensToClaim);
        lpTokenToClaim.approve(_playerAddress, numberLpTokensToClaim);
        lpTokenToClaim.transfer(_playerAddress, numberLpTokensToClaim);
        IERC20 rewardTokenToClaim = IERC20(
            configContract.getRewardTokenAddress()
        );
        rewardTokenToClaim.transfer(_playerAddress, rewardsToClaim);

        return (numberLpTokensToClaim, rewardsToClaim);
    }

    function claimRewardTokensFromProtocol()
        public
        onlyContractOrOwner
        returns (uint256)
    {
        uint256 rewardsToClaim = getTokensInContract(address(strategies));
        IUniswapV2Pair rewardTokenToClaim = IUniswapV2Pair(
            configContract.getRewardTokenAddress()
        );
        // vaultResources = 0;
        rewardTokenToClaim.transfer(
            owner(), // Temporary solution (should be multisig wallet)
            rewardsToClaim
        );
        return rewardsToClaim;
    }

    function distributeRewards(address _token) private {
        address[] memory _players = players;
        uint256 rewardsFromToken = IERC20(_token).balanceOf(address(this));
        // console.log(
        //     "Rewards from token: %s, total supply of rewards: %s",
        //     rewardsFromToken,
        //     totalSupplyOfRewards
        // );
        // assert(rewardsFromToken == totalSupplyOfRewards);
        for (uint256 i = 0; i < _players.length; i++) {
            _claimTokens(_players[i], rewardsFromToken);
        }
        claimRewardTokensFromProtocol();
        emit RewardsDistributed();
    }

    /* Getters */
    /**
     * @dev Function used to get information about token associated with player
     *
     * @param _playerAddress - address of the player we want to get token information about
     */
    function getTokenByPlayerAddress(address _playerAddress)
        public
        view
        returns (address)
    {
        return playerInfo[_playerAddress].tokenAddress;
    }

    /**
     * @dev Function used to get information about number of players registered or playing the game
     *
     */
    function getNumberOfPlayers() external view returns (uint256) {
        return players.length;
    }

    /**
     * @dev Function used to get time to game state change. It depends on the state of game.
     *
     */
    function getTimeToStartOrEndGame() external view returns (uint256) {
        if (gameState == GameState.READY) {
            if (readyDuration < (block.timestamp - initRunningTime)) {
                return 0;
            } else {
                return readyDuration - (block.timestamp - initReadyTime); // avoid polling, frontend should decrement on its own
            }
        } else if (gameState == GameState.RUNNING) {
            if (gameDuration < (block.timestamp - initRunningTime)) {
                return 0;
            } else {
                return gameDuration - (block.timestamp - initRunningTime);
            }
        } else {
            // Wrong state
            revert LiquidityVault__WrongGameState(gameState); // 2^256
        }
    }

    /**
     * @dev Function used to get amount of specific token inide the contract
     *
     * @param _tokenAddress - address of the token we want to get information about
     */
    function getTokensInContract(address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return IERC20(_tokenAddress).balanceOf(address(this));
    }

    function getGameState() external view returns (GameState) {
        return gameState;
    }

    /**
     * @dev Function used to retrieve player's info by passing _playerAddress of the array where the addresses are stored
     *
     * @param _playerAddress - address of the player we want to get information about
     */
    function getPlayerInfo(address _playerAddress)
        external
        view
        returns (PlayerInfo memory)
    {
        return playerInfo[_playerAddress];
    }

    function getReadyDuration() external view returns (uint256) {
        return readyDuration;
    }

    function getGameDuration() external view returns (uint256) {
        return gameDuration;
    }

    /**
     * @dev Function used to retrieve player address by passing id of the array where the addresses are stored
     *
     * @param _id - ordered place in the array where the address is
     */
    function getPlayerAddress(uint256 _id) external view returns (address) {
        return players[_id];
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for the "upkeepNeeded" to return true for distribution:
     * I.The following should be true in order to return true:
     * 1. Our time interval should have passed
     * 2. The game should have at least 2 players so have some LP tokens - in order to start the game !!
     * 3. Our subscription should be funded with LINK -> NOT DONE
     * 4. The game should be in "RUNNING" state
     * II.The following should be true to end the game:
     * 1. Our game duration should have passed
     * 2. The game should be in "RUNNING" state
     * 3. Our subscription should be funded with LINK -> NOT DONE
     *
     * @param checkData - used to determine which functionality should be done in the checkUpkeep function
     * (for now only one functionality available for checkData = abi.encode(1))
     */

    function checkUpkeep(bytes memory checkData)
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        performData = abi.encode(0);
        uint256 checkOption = abi.decode(checkData, (uint256));
        if (checkOption == 1) // Upkeep for game states
        {
            if (gameState == GameState.READY) {
                if (
                    ((block.timestamp - initReadyTime) >= readyDuration &&
                        players.length > 1)
                ) {
                    // The game is ready to start
                    upkeepNeeded = true;
                    performData = abi.encode(READY_CONDITIONS_MET);
                } else if ((block.timestamp - initReadyTime) < readyDuration) {
                    performData = abi.encode(TIME_NOT_ELAPSED);
                } else {
                    //players.length <= 1
                    performData = abi.encode(NOT_ENOUGH_PLAYERS);
                }
            } else {
                //gameState == GameState.RUNNING
                if (((block.timestamp - initRunningTime) >= gameDuration)) {
                    // game time passed -> end the game
                    upkeepNeeded = true;
                    performData = abi.encode(RUNNING_CONDITIONS_MET);
                } else {
                    performData = abi.encode(TIME_NOT_ELAPSED);
                }
            }
        }
        return (upkeepNeeded, performData);
    }

    /** @dev Function suppose to be called automatically by the chainlink keepers once
     * checkUpkeep returns true (condtition fulfilled). But it can also be called by other
     * actors and this is not an issue because it is build-in checks which will prevent
     * from calling during wrong conditions.
     *
     * @param performData - used to determine which functionality should be done in the performUpkeep function
     * and increase possibilities for debug by error codes
     */
    function performUpkeep(bytes calldata performData) external override {
        (bool upkeepNeeded, bytes memory data) = checkUpkeep(abi.encode(1));
        uint256 checkOption = abi.decode(performData, (uint256));

        // Prevents from calling by other actor when conditions from checkUpkeep are not met
        if ((abi.decode(data, (uint256)) != checkOption) || (!upkeepNeeded)) {
            revert LiquidityVault__checkUpkeepError();
        }

        // Error handling
        if (checkOption == TIME_NOT_ELAPSED) {
            revert LiquidityVault__TimeNotPassed(
                (block.timestamp - initReadyTime),
                readyDuration
            );
        } else if (
            checkOption != RUNNING_CONDITIONS_MET &&
            checkOption != READY_CONDITIONS_MET
        ) {
            revert LiquidityVault__checkOptionWrong();
        }

        // Main gameflow
        if (checkOption == READY_CONDITIONS_MET) {
            // all conditions met so start the game
            startTheGame();
        } else if (checkOption == RUNNING_CONDITIONS_MET) {
            // all conditions met so end the game
            endTheGame();
        }
    }

    function getMaxNumberOfplayers() public pure returns (uint256) {
        return MAX_NUMBER_OF_PLAYERS;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import './libraries/UniswapV2Library.sol';
import "./PriceConsumerV3.sol";

// Temporary
import "hardhat/console.sol";

/* Types */
struct Troop {
    uint64 number;
    uint32 cost;
    uint32 health;
    uint16 capacity;
    uint16 speed;
    uint16 defense;
    uint16 attack;
}

struct BuildingParams {
    uint256 initialAbility;
    uint256 bonus;
}

/* Enums */
enum Infrastructure {
    FARM,
    BARRACKS,
    HIDEAWAY,
    WALLS
}

enum Nation {
    ORKS,
    ELVES
}

uint256 constant PRECISION = 10**10;

/* Errors */
error LiquidityWarsConfig__WrongLengthOfArgs(uint256, uint256);

/**
 * @notice Contract used for rarely changeable and readable calibration cofigurations
 */
contract LiquidityWarsConfig is Ownable {
    /* constants */
    uint256 private constant LIQUIDITY_VAULT_ADDRESS_SET = 0x1;
    uint256 private constant LIQUIDITY_WARS_ADDRESS_SET = 0x2;
    uint256 private constant LP_TOKEN_ADDED = 0x4;
    uint256 private constant ROUTER_ADDED = 0x8;
    uint256 private constant TROOP_ADDED = 0x10;
    uint256 private constant REQUIRED_USD_DEFINED = 0x20;
    uint256 private constant REWARD_TOKEN_ADDRESS_ADDED = 0x40;
    uint256 internal constant BUILDING_PARAMS_DEFINED = 0x100;
    uint256 private constant FACTORY_ADDED = 0x200;
    uint256 private constant STAKING_CONTRACT_ADDRESS_ADDED = 0x400;
    uint256 private constant FULLY_CALIBRATED = (LIQUIDITY_VAULT_ADDRESS_SET |
        LIQUIDITY_WARS_ADDRESS_SET |
        LP_TOKEN_ADDED |
        ROUTER_ADDED |
        TROOP_ADDED |
        REQUIRED_USD_DEFINED |
        REWARD_TOKEN_ADDRESS_ADDED |
        BUILDING_PARAMS_DEFINED |
        // FACTORY_ADDED |
        STAKING_CONTRACT_ADDRESS_ADDED);

    /* calibrations */
    address[] private allowedTokens;
    address private routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // sushi router, mumbai
    // address private factoryAddress = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address private stakingContractAddress =
        0x0769fd68dFb93167989C6f7254cd0D766Fb2841F;
    address private rewardTokenAddress =
        0xe6b8a5CF854791412c1f6EFC7CAf629f5Df1c747; // usdc, mumbai
    address private liquidityVaultAddress;
    address private liquidityWarsAddress;
    mapping(address => Nation) private tokensToNation;
    mapping(address => uint256) private requiredAmountForToken;
    mapping(Nation => Troop) private nationToTroop;
    uint256 private usdRequiredAmount;
    uint256 private calibrationFlag = 0;
    BuildingParams[] private buildingsParams;
    PriceConsumerV3 private immutable priceFeed0;
    PriceConsumerV3 private immutable priceFeed1;

    constructor() {
        priceFeed0 = new PriceConsumerV3(
            0x12162c3E810393dEC01362aBf156D7ecf6159528 // LINK/MATIC
        );
        priceFeed1 = new PriceConsumerV3(
            0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada // MATIC/USD
        );
    }

    /**
     * @dev used by the owner to set luquidity vault address
     */
    function setLiquidityVaultAddress(address _liquidityVaultAddress)
        external
        onlyOwner
    {
        liquidityVaultAddress = _liquidityVaultAddress;
        calibrationFlag |= LIQUIDITY_VAULT_ADDRESS_SET;
    }

    /**
     * @dev used by the owner to set luquidity wars address
     */
    function setLiquidityWarsAddress(address _liquidityWarsAddress)
        external
        onlyOwner
    {
        liquidityWarsAddress = _liquidityWarsAddress;
        calibrationFlag |= LIQUIDITY_WARS_ADDRESS_SET;
    }

    /**
     * @dev used by the owner to add tokens allowed to deposit
     */
    function addTokensToAllowed(address _tokenAddress, Nation nation)
        external
        onlyOwner
        returns (bool)
    {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _tokenAddress) {
                return false; //Already exist
            }
        }
        allowedTokens.push(_tokenAddress);
        tokensToNation[_tokenAddress] = nation;
        calibrationFlag |= LP_TOKEN_ADDED;
        return true;
    }

    /**
     * @dev used by the owner to set router for swaps
     */
    function setRouter(address _routerAddress) external onlyOwner {
        routerAddress = _routerAddress;
        calibrationFlag |= ROUTER_ADDED;
    }

    // /**
    //  * @dev used by the owner to set factory for LPs
    //  */
    // function setFactory(address _factoryAddress) external onlyOwner {
    //     factoryAddress = _factoryAddress;
    //     calibrationFlag |= FACTORY_ADDED;
    // }

    /**
     * @dev used by the owner to set master chef for staking
     */
    function setStakingContractAddress(address _stakingContractAddress)
        external
        onlyOwner
    {
        stakingContractAddress = _stakingContractAddress;
        calibrationFlag |= STAKING_CONTRACT_ADDRESS_ADDED;
    }

    /**
     * @dev used by the owner to set troop atributes for certain nation
     */
    function setTroopToNation(
        uint32 cost,
        uint32 health,
        uint16 capacity,
        uint16 speed,
        uint16 defense,
        uint16 attack,
        Nation nation
    ) public onlyOwner {
        Troop memory newTroop = Troop(
            0, //number
            cost,
            health,
            capacity,
            speed,
            defense,
            attack
        );
        nationToTroop[nation] = newTroop;
        calibrationFlag |= TROOP_ADDED;
    }

    /**
     * @dev used by the owner to set required amount of usd to deposit reflected in LP tokens
     */
    function setUsdRequiredAmount(uint256 _usdAmount) public onlyOwner {
        usdRequiredAmount = _usdAmount; //8 DECIMALS
        calibrationFlag |= REQUIRED_USD_DEFINED;
    }

    /**
     * @dev used by the owner to set address of the token in which the rewards will be reflected and distributed
     * For tests it should be address og the strategies contract
     */
    function setRewardsTokenAddress(address _rewardsTokenAddress)
        external
        onlyOwner
    {
        rewardTokenAddress = _rewardsTokenAddress;
        calibrationFlag |= REWARD_TOKEN_ADDRESS_ADDED;
    }

    /**
     * @dev Default initial ability for buildings:
     * FARM: 1000, BARRACKS: 50, HIDEAWAY: 200, WALLS: 10
     * [1000, 50, 200, 10]
     * Default bonuses for buildings (in percentage):
     * FARM: 25, BARRACKS: 10, HIDEAWAY: 25, WALLS: 50
     * [25, 10, 25, 50]
     */
    function setBuildingParams(
        uint256[] memory _initialAbilities,
        uint256[] memory _bonuses
    ) external onlyOwner {
        if (_initialAbilities.length != _bonuses.length) {
            revert LiquidityWarsConfig__WrongLengthOfArgs(
                _initialAbilities.length,
                _bonuses.length
            );
        }
        for (uint256 i = 0; i < _initialAbilities.length; i++) {
            buildingsParams.push(
                BuildingParams(_initialAbilities[i], _bonuses[i])
            );
        }
        buildingsParams.push(BuildingParams(0, 0));
        calibrationFlag |= BUILDING_PARAMS_DEFINED;
    }

    /* Getters */
    function getLiquidityVaultAddress() external view returns (address) {
        return liquidityVaultAddress;
    }

    function getLiquidityWarsAddress() external view returns (address) {
        return liquidityWarsAddress;
    }

    function getCalibratioStatus() external view returns (bool) {
        return (FULLY_CALIBRATED == calibrationFlag);
    }

    function getNationByToken(address _tokenAddress)
        external
        view
        returns (Nation)
    {
        return tokensToNation[_tokenAddress];
    }

    function getTroopByNation(Nation _nation)
        external
        view
        returns (Troop memory)
    {
        return nationToTroop[_nation];
    }

    function getTroopByTokenAddress(address _tokenAddress)
        external
        view
        returns (Troop memory)
    {
        return nationToTroop[tokensToNation[_tokenAddress]];
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokens;
    }

    function getRewardTokenAddress() external view returns (address) {
        return rewardTokenAddress;
    }

    function getUsdRequiredAmount() external view returns (uint256) {
        return usdRequiredAmount;
    }

    function getAmountOfLpTokensRequired(address _tokenAddress)
        external
        view
        returns (uint256)
    {
        console.log(_tokenAddress);
        // address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // Uniswap Goerli
        // address token0 = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; //UNI token, Goerli
        // address token1 = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; //WETH token, Goerli

        // address factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f; // Uniswap Mainnet
        // address token0 = 0x514910771AF9Ca656af840dff83E8264EcF986CA; //LINK token, Mainnet
        // address token1 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //WETH token, Mainnet

        // address factory = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4; // Sushiswap Mumbai
        // address token0 = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; //LINK token, Mainnet
        // address token1 = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889; //WMATIC token, Mainnet

        // address _pairContractAddress = UniswapV2Library.pairFor(factory, token0, token1);
        // IUniswapV2Pair _pair = IUniswapV2Pair(_pairContractAddress);

        IUniswapV2Pair _pair = IUniswapV2Pair(_tokenAddress);
        uint256 totalSupply = IERC20(_tokenAddress).totalSupply();

        // address token0 = _pair.token0();
        // address token1 = _pair.token1();
        // console.log("token0:", ERC20(token0).symbol());
        // console.log("token1:", ERC20(token1).symbol());

        (uint112 reserve0, uint112 reserve1, ) = _pair.getReserves();
        // console.log("reserve0:", reserve0, "LINK");
        // console.log("reserve1:", reserve1, "MATIC");

        int256 price0 = priceFeed0.getLatestPrice(); // LINK/MATIC
        int256 price1 = priceFeed1.getLatestPrice(); // MATIC/USD
        // console.log("price0:", uint256(price0), "LINK/MATIC (18 dec)");
        // console.log("price1:", uint256(price1), "MATIC/USD (8 dec)");

        uint256 reserve0USD = (reserve0 * uint256(price0) * uint256(price1)) /
            1e26;
        uint256 reserve1USD = (reserve1 * uint256(price1)) / 1e8;
        // console.log("total value of LP:", reserve0USD+reserve1USD, "USD (18 dec)");
        // console.log("circulating supply of LP tokens:", totalSupply, "(18 dec)");

        uint256 priceLP = (1e8 * (reserve0USD + reserve1USD)) / totalSupply;
        // console.log("value of 1 LP:", priceLP, "USD (8 dec)");
        // console.log("usdRequiredAmount: ", usdRequiredAmount, "USD (8 dec)");

        uint256 amountOfLpTokensRequired = (1e18 * usdRequiredAmount) / priceLP;
        // console.log("amountOfLpTokensRequired:", amountOfLpTokensRequired, "(18 dec)");

        return amountOfLpTokensRequired;
    }

    function checkIfTokenIsAllowed(address _tokenAddress)
        external
        view
        returns (bool)
    {
        address[] memory _allowedTokens = allowedTokens;
        uint256 idx;
        for (idx = 0; idx < _allowedTokens.length; idx++) {
            if (_tokenAddress == _allowedTokens[idx]) {
                return true;
            }
        }
        return false;
    }

    function getBuildingParam(uint256 _id)
        external
        view
        returns (BuildingParams memory)
    {
        return buildingsParams[_id];
    }

    function getRouterAddress() external view returns (address) {
        return routerAddress;
    }

    // function getFactoryAddress() external view returns (address) {
    //     return factoryAddress;
    // }

    function getStakingContractAddress() external view returns (address) {
        return stakingContractAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Temporary
import "hardhat/console.sol";

interface ILiquidityWarsVrf {
    function getRandomFactorsForBattle()
        external
        returns (
            uint256 attackerFactor,
            uint256 defenderFactor,
            uint256 numberOfCombats
        );
}

/**
 * @title The LiquidityWarsVrf contract
 * @notice A contract that gets random values from Chainlink VRF V2
 */
contract LiquidityWarsVrf is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface immutable COORDINATOR;

    // Your subscription ID.
    uint64 immutable s_subscriptionId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 immutable s_keyHash;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 constant CALLBACK_GAS_LIMIT = 100000;

    // The default is 3, but you can set this higher.
    uint16 constant REQUEST_CONFIRMATIONS = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 constant NUM_WORDS = 2;

    uint256[] public s_randomWords;
    uint256 public s_requestId;
    bool public s_requestPending = false;

    event ReturnedRandomness(uint256[] randomWords);

    /**
     * @notice Constructor inherits VRFConsumerBaseV2
     *
     * @param subscriptionId - the subscription ID that this contract uses for funding requests
     * @param vrfCoordinator - coordinator, check https://docs.chain.link/docs/vrf-contracts/#configurations
     * @param keyHash - the gas lane to use, which specifies the maximum gas price to bump to
     */
    constructor(
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_subscriptionId = subscriptionId;
        //requestRandomWords();
        s_randomWords.push(block.timestamp);
        s_randomWords.push(block.difficulty);
    }

    /**
     * @notice Requests randomness
     * Assumes the subscription is funded sufficiently; "Words" refers to unit of data in Computer Science
     * Teves: in order for the chainlink tests to pass it is necessary to chenge the visibility to public
     */
    function requestRandomWords() public {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );
        s_requestPending = true;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     *
     * @param randomWords - array of random results from VRF Coordinator
     */
    function fulfillRandomWords(
        uint256, /* requestId */
        uint256[] memory randomWords
    ) internal override {
        s_randomWords = randomWords;
        s_requestPending = false;
        emit ReturnedRandomness(randomWords);
    }

    function requestForBattleFactors() external onlyOwner {
        if (!s_requestPending) {
            requestRandomWords();
        }
    }

    /**
     * @notice Function for getting randomized factors used in the battle system
     *
     * @return attackerFactor - factor used for attacker troops (range: 7 - 12) -> range should be lower for attacker
     * @return defenderFactor - factor used for defender troops (range: 8 - 13) -> range should be higher
     * @return numberOfCombats - number of combat series during the battle (how many iterations) (range: 2 - 5)
     */
    function getRandomFactorsForBattle()
        external
        view
        returns (
            uint256 attackerFactor,
            uint256 defenderFactor,
            uint256 numberOfCombats
        )
    {
        attackerFactor = (s_randomWords[1] % 6) + 7;
        defenderFactor = (s_randomWords[0] % 6) + 8;
        numberOfCombats = ((s_randomWords[0] + s_randomWords[1]) % 4) + 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LiquidityVault.sol";
import "./LiquidityWarsConfig.sol";
// Temporary
import "hardhat/console.sol";

error Strategies__NotLiquidityVaultCall();

contract Strategies is ERC20, Ownable {
    uint256 constant DIVIDER = 10**18;
    uint256 private initTime = 0;
    LiquidityVault liquidityVaultContract;
    LiquidityWarsConfig configContract;

    modifier onlyLiquidityVaultOrOwner() {
        _assignLiquidityVaultContract();
        if (
            msg.sender != address(liquidityVaultContract) &&
            msg.sender != owner()
        ) {
            revert Strategies__NotLiquidityVaultCall();
        }
        _;
    }

    constructor(address _configAddress) ERC20("RewardsToken", "REWARD") {
        configContract = LiquidityWarsConfig(_configAddress);
    }

    function _assignLiquidityVaultContract() private {
        liquidityVaultContract = LiquidityVault(
            configContract.getLiquidityVaultAddress()
        );
    }

    function startStrategy(
        uint256 _option,
        address _protocolAddress,
        address _lpTokenAddress
    ) external onlyLiquidityVaultOrOwner {
        uint256 balance = IERC20(_lpTokenAddress).balanceOf(msg.sender);
        IERC20(_lpTokenAddress).transferFrom(
            msg.sender,
            address(this),
            balance
        );
        if (_option == 0) {
            //Dummy strategy
            initTime = block.timestamp;
        } else if (_option == 1) {
            //Sushi strategy
        }
    }

    function stopStrategy(
        uint256 _option,
        address _protocolAddress,
        address _lpTokenAddress
    ) external onlyLiquidityVaultOrOwner {
        if (_option == 0) {
            //Dummy strategy

            uint256 balance = IERC20(_lpTokenAddress).balanceOf(address(this));

            uint256 rewards = getCurrentRewards(
                _option,
                _protocolAddress,
                _lpTokenAddress
            );
            // console.log("Minitng %s", rewards);
            _mint(msg.sender, rewards);
            // console.log(
            //     "Balance of %s is: %s",
            //     msg.sender,
            //     balanceOf(msg.sender)
            // );
            // console.log("Approving %s", balance);
            // IERC20(_lpTokenAddress).approve(msg.sender, balance);
            // console.log(
            //     "Transfering %s from %s to %s",
            //     balance,
            //     address(this),
            //     msg.sender
            // );
            // console.log(
            //     "Allowance: %s",
            //     IERC20(_lpTokenAddress).allowance(address(this), msg.sender)
            // );
            IERC20(_lpTokenAddress).transfer(msg.sender, balance);
        } else if (_option == 1) {
            //Sushi strategy
        }
    }

    function getCurrentRewards(
        uint256 _option,
        address _protocolAddress,
        address _lpTokenAddress
    ) public view returns (uint256) {
        uint256 rewards = 0;
        if (_option == 0) {
            //Dummy strategy
            rewards = (((block.timestamp - initTime) *
                IERC20(_lpTokenAddress).balanceOf(address(this))) / PRECISION);
            console.log("Rewards are: %s", rewards);
        } else if (_option == 1) {
            //Sushi strategy
        }
        return rewards;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title The PriceConsumerV3 contract
 * @notice Acontract that returns latest price from Chainlink Price Feeds
 */
contract PriceConsumerV3 {
    AggregatorV3Interface internal immutable priceFeed;

    /**
     * @notice Executes once when a contract is created to initialize state variables
     *
     * @param _priceFeed - Price Feed Address
     *
     * Goerli:
     *   ETH/USD -> 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     * Mainnet:
     *   LINK/USD -> 0x48731cF7e84dc94C5f84577882c14Be11a5B7456
     *   ETH/USD -> 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     *   DAI/USD -> 0x0d79df66BE487753B02D015Fb622DED7f0E9798d
     * Mumbai:
     *   LINK/MATIC -> 0x12162c3E810393dEC01362aBf156D7ecf6159528
     *   MATIC/USD -> 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
     * Price Feed Contract Addresses: https://docs.chain.link/docs/data-feeds/price-feeds/addresses/
     */
    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice Returns the latest price
     *
     * @return latest price
     */
    function getLatestPrice() public view returns (int256) {
        (
            /*uint80 roundID*/,
            int256 price,
            /*uint256 startedAt*/,
            /*uint256 timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     * @notice Returns the Price Feed address
     *
     * @return Price Feed address
     */
    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}