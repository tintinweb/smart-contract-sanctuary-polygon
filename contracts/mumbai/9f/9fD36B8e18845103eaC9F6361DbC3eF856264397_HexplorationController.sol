// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@luckymachines/game-core/contracts/src/v0.0/GameController.sol";
import "./HexplorationBoard.sol";
import "./HexplorationZone.sol";
import "./HexplorationQueue.sol";
import "./HexplorationStateUpdate.sol";
import "./CharacterCard.sol";
import "./TokenInventory.sol";
import "./GameEvents.sol";
import "./GameSetup.sol";
import "./GameWallets.sol";

contract HexplorationController is GameController, GameWallets {
    // functions are meant to be called directly by players by default
    // we are adding the ability of a Controller Admin or Keeper to
    // execute the game aspects not directly controlled by players
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");

    HexplorationStateUpdate GAME_STATE;
    GameEvents GAME_EVENTS;
    GameSetup GAME_SETUP;

    modifier onlyAdminVC() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(VERIFIED_CONTROLLER_ROLE, _msgSender()),
            "Admin or Keeper role required"
        );
        _;
    }

    constructor(address adminAddress) GameController(adminAddress) {}

    // Admin Functions

    function setGameEvents(address gameEventsAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_EVENTS = GameEvents(gameEventsAddress);
    }

    function setGameStateUpdate(address gsuAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_STATE = HexplorationStateUpdate(gsuAddress);
    }

    function setGameSetup(address gameSetupAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_SETUP = GameSetup(gameSetupAddress);
    }

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    //Player Interactions
    function registerForGame(uint256 gameID, address boardAddress) public {
        HexplorationBoard board = HexplorationBoard(boardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        board.registerPlayer(tx.origin, gameID);
        // TODO: set to official values
        CharacterCard(board.characterCard()).setStats(
            [4, 4, 4],
            gameID,
            pr.playerID(gameID, tx.origin)
        );
        // emit player joined
        GAME_EVENTS.emitGameRegistration(gameID, tx.origin);

        // If registry is full we can kick off game start...
        if (pr.totalRegistrations(gameID) == pr.registrationLimit(gameID)) {
            GAME_SETUP.allPlayersRegistered(gameID, boardAddress);
        }
    }

    function submitAction(
        uint256 playerID,
        uint8 actionIndex,
        string[] memory options,
        string memory leftHand,
        string memory rightHand,
        uint256 gameID,
        address boardAddress
    ) public {
        require(
            actionIsValid(
                actionIndex,
                options,
                leftHand,
                rightHand,
                gameID,
                boardAddress,
                playerID
            ),
            "Invalid action submitted"
        );
        HexplorationBoard board = HexplorationBoard(boardAddress);
        HexplorationQueue q = HexplorationQueue(board.gameplayQueue());
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        require(
            pr.playerAddress(gameID, playerID) == tx.origin,
            "PlayerID is not sender"
        );
        uint256 qID = q.queueID(gameID);
        if (qID == 0) {
            qID = q.requestGameQueue(gameID, pr.totalRegistrations(gameID));
        }
        require(qID != 0, "unable to set qID in controller");
        string memory cz = board.currentPlayZone(gameID, playerID);
        string[] memory newOptions;
        bool isDayPhase = TokenInventory(board.tokenInventory())
            .DAY_NIGHT_TOKEN()
            .balance("Day", gameID, GAME_BOARD_WALLET_ID) > 0
            ? true
            : false;
        if (actionIndex == 4) {
            // dig action, set options to # players on board
            uint256 activePlayersOnSpace = 0;
            for (uint256 i = 0; i < pr.totalRegistrations(gameID); i++) {
                if (
                    keccak256(
                        abi.encodePacked(board.currentPlayZone(gameID, i + 1))
                    ) == keccak256(abi.encodePacked(cz))
                ) {
                    activePlayersOnSpace++;
                }
                //currentPlayZone[gameID][playerID]
            }
            newOptions = new string[](activePlayersOnSpace + 1); // array length = players on space + 1
            newOptions[0] = isDayPhase ? "Day" : "Night";
        } else {
            newOptions = options;
        }

        q.submitActionForPlayer(
            playerID,
            actionIndex,
            newOptions,
            leftHand,
            rightHand,
            qID,
            isDayPhase
        );
    }

    // TODO: limit this to authorized game starters
    function requestNewGame(address gameRegistryAddress, address boardAddress)
        public
    {
        requestNewGame(gameRegistryAddress, boardAddress, 4);
    }

    function requestNewGame(
        address gameRegistryAddress,
        address boardAddress,
        uint256 totalPlayers
    ) public {
        HexplorationBoard board = HexplorationBoard(boardAddress);
        board.requestNewGame(gameRegistryAddress, totalPlayers);
    }

    // TODO: move this into game summary
    function latestGame(address gameRegistryAddress, address boardAddress)
        public
        view
        returns (uint256)
    {
        return GameRegistry(gameRegistryAddress).latestGame(boardAddress);
    }

    // internal
    // TODO: move these validation functions into rules
    function actionIsValid(
        uint8 actionIndex,
        string[] memory options,
        string memory leftHand,
        string memory rightHand,
        uint256 gameID,
        address gameBoardAddress,
        uint256 playerID
    ) internal view returns (bool isValid) {
        HexplorationBoard gameBoard = HexplorationBoard(gameBoardAddress);

        CharacterCard cc = CharacterCard(gameBoard.characterCard());
        if (gameBoard.gameOver(gameID) || cc.playerIsDead(gameID, playerID)) {
            return false;
        }
        isValid = true;
        string memory currentSpace = gameBoard.currentPlayZone(
            gameID,
            playerID
        );
        if (actionIndex == 4) {
            // TODO:
            // dig action
            if (gameBoard.artifactFound(gameID, currentSpace)) {
                // artifact already found at space, can't dig here
                isValid = false;
            } else if (
                bytes(
                    CharacterCard(gameBoard.characterCard()).artifact(
                        gameID,
                        playerID
                    )
                ).length > 0
            ) {
                // player already has artifact, can't dig
                isValid = false;
            }
        } else if (actionIndex == 1) {
            // moving
            // check options for valid movement
            // TODO: make sure # of spaces is within movement
            if (
                CharacterCard(gameBoard.characterCard()).movement(
                    gameID,
                    playerID
                ) < (options.length)
            ) {
                isValid = false;
            } else {
                // TODO:
                // ensure each movement zone has output to next movement zone
                // for (uint256 i = 0; i < options.length; i++) {
                //     if (
                //         i == 0 && !gameBoard.hasOutput(currentSpace, options[0])
                //     ) {
                //         isValid = false;
                //         break;
                //         // check that movement from current zone to option[0] is valid
                //     } else if (
                //         !gameBoard.hasOutput(options[i - 1], options[i])
                //     ) {
                //         // check that movement from option[i - 1] to option[i] is valid
                //         isValid = false;
                //         break;
                //     }
                // }
            }
        } else if (actionIndex == 2) {
            // setup camp
            TokenInventory tokenInventory = TokenInventory(
                gameBoard.tokenInventory()
            );
            if (
                tokenInventory.ITEM_TOKEN().balance(
                    "Campsite",
                    gameID,
                    playerID
                ) == 0
            ) {
                // campsite is not in player inventory
                isValid = false;
            } else if (
                tokenInventory.ITEM_TOKEN().zoneBalance(
                    "Campsite",
                    gameID,
                    zoneIndex(gameBoard.getZoneAliases(), currentSpace)
                ) > 0
            ) {
                // campsite is already on board space
                isValid = false;
            }
        } else if (actionIndex == 3) {
            // break down camp
            TokenInventory tokenInventory = TokenInventory(
                gameBoard.tokenInventory()
            );
            if (
                tokenInventory.ITEM_TOKEN().balance(
                    "Campsite",
                    gameID,
                    playerID
                ) > 0
            ) {
                // campsite is already in player inventory
                isValid = false;
            } else if (
                tokenInventory.ITEM_TOKEN().zoneBalance(
                    "Campsite",
                    gameID,
                    zoneIndex(gameBoard.getZoneAliases(), currentSpace)
                ) == 0
            ) {
                // campsite is not on board space
                isValid = false;
            }
        } else if (actionIndex == 5) {
            // rest
            if (
                TokenInventory(gameBoard.tokenInventory())
                    .ITEM_TOKEN()
                    .zoneBalance(
                        "Campsite",
                        gameID,
                        zoneIndex(gameBoard.getZoneAliases(), currentSpace)
                    ) == 0
            ) {
                // campsite is not on board space
                isValid = false;
            }
        } else if (actionIndex == 6) {
            // help
            // check that player being helped is on the same space
            // options[0] = player to help ("1","2","3", or "4")
            // options[1] = attribute to help ("Movement", "Agility", or "Dexterity")
            uint256 playerIDToHelp = stringsMatch(options[0], "1")
                ? 1
                : stringsMatch(options[0], "2")
                ? 2
                : stringsMatch(options[0], "3")
                ? 3
                : stringsMatch(options[0], "4")
                ? 4
                : 0;
            if (
                !stringsMatch(
                    currentSpace,
                    gameBoard.currentPlayZone(gameID, playerIDToHelp)
                )
            ) {
                // players are not on same space
                isValid = false;
            } else {
                // check that player can transfer attribute (> 1)
                // check that receiving player can increase attribute (< MAX)
                if (stringsMatch(options[1], "Movement")) {
                    if (
                        cc.movement(gameID, playerID) <= 1 ||
                        cc.movement(gameID, playerIDToHelp) == cc.MAX_MOVEMENT()
                    ) {
                        // player doesn't have movement attribute to transfer or
                        // recipient has full movement attribute
                        isValid = false;
                    }
                } else if (stringsMatch(options[1], "Agility")) {
                    if (
                        cc.agility(gameID, playerID) <= 1 ||
                        cc.agility(gameID, playerIDToHelp) == cc.MAX_AGILITY()
                    ) {
                        // player doesn't have agility attribute to transfer or
                        // recipient has full agility attribute
                        isValid = false;
                    }
                } else if (stringsMatch(options[1], "Dexterity")) {
                    if (
                        cc.dexterity(gameID, playerID) <= 1 ||
                        cc.dexterity(gameID, playerIDToHelp) ==
                        cc.MAX_DEXTERITY()
                    ) {
                        // player doesn't have dexterity attribute to transfer or
                        // recipient has full dexterity attribute
                        isValid = false;
                    }
                }
            }
        }
        if (bytes(leftHand).length > 0 && bytes(rightHand).length > 0) {
            // cannot equip both hands in one turn
            isValid = false;
        } else if (
            bytes(leftHand).length > 0 && !stringsMatch(leftHand, "None")
        ) {
            if (
                TokenInventory(gameBoard.tokenInventory()).ITEM_TOKEN().balance(
                    leftHand,
                    gameID,
                    playerID
                ) == 0
            ) {
                // item not in inventory
                isValid = false;
            }
        } else if (
            bytes(rightHand).length > 0 && !stringsMatch(rightHand, "None")
        ) {
            if (
                TokenInventory(gameBoard.tokenInventory()).ITEM_TOKEN().balance(
                    rightHand,
                    gameID,
                    playerID
                ) == 0
            ) {
                // item not in inventory
                isValid = false;
            }
        }
    }

    function stringsMatch(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function zoneIndex(string[] memory allZones, string memory zoneAlias)
        internal
        pure
        returns (uint256 index)
    {
        index = 1111111111111;
        for (uint256 i = 0; i < allZones.length; i++) {
            if (
                keccak256(abi.encodePacked(zoneAlias)) ==
                keccak256(abi.encodePacked(allZones[i]))
            ) {
                index = i;
                break;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@luckymachines/game-core/contracts/src/v0.0/custom_boards/HexGrid.sol";
import "./HexplorationZone.sol";

contract HexplorationBoard is HexGrid {
    // This role is a hybrid controller, assumes on chain verification of moves before submission

    HexplorationZone internal HEX_ZONE;
    address public characterCard;
    address public tokenInventory;
    address public gameplayQueue;
    // mapping from gameID
    mapping(uint256 => bool) public gameOver;
    // game ID => zone alias
    mapping(uint256 => mapping(string => bool)) public zoneEnabled;
    mapping(uint256 => mapping(string => bool)) public artifactFound; // can only dig on space if false
    // game ID => playerID
    mapping(uint256 => mapping(uint256 => string[])) public artifactsRetrieved; // get artifacts retrieved by player ID

    constructor(
        address adminAddress,
        uint256 _gridWidth,
        uint256 _gridHeight,
        address _zoneAddress
    ) HexGrid(adminAddress, _gridWidth, _gridHeight, _zoneAddress) {
        HEX_ZONE = HexplorationZone(_zoneAddress);
    }

    function hexZoneAddress() public view returns (address) {
        return address(HEX_ZONE);
    }

    function getAliasAddress(uint256 gameID, string memory zAlias)
        public
        view
        returns (address)
    {
        return zoneAlias[gameID][zAlias];
    }

    function getArtifactsRetrieved(uint256 gameID, uint256 playerID)
        public
        view
        returns (string[] memory)
    {
        return artifactsRetrieved[gameID][playerID];
    }

    function hasOutput(string memory fromZone, string memory toZone)
        public
        view
        returns (bool zoneHasOutput)
    {
        string[] memory outputs = getOutputs(0, fromZone);
        zoneHasOutput = false;
        for (uint256 i = 0; i < outputs.length; i++) {
            if (
                keccak256(abi.encode(outputs[i])) ==
                keccak256(abi.encode(toZone))
            ) {
                zoneHasOutput = true;
                break;
            }
        }
    }

    // VERIFIED CONTROLLER functions
    // We can assume these have been pre-verified
    function setCharacterCard(address characterCardAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        characterCard = characterCardAddress;
    }

    function setTokenInventory(address tokenInventoryAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        tokenInventory = tokenInventoryAddress;
    }

    function setGameplayQueue(address gameplayQueueAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        gameplayQueue = gameplayQueueAddress;
    }

    function setPlayerRegistry(address playerRegistryAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PLAYER_REGISTRY = PlayerRegistry(playerRegistryAddress);
    }

    function setArtifactFound(uint256 gameID, string memory _zoneAlias)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        artifactFound[gameID][_zoneAlias] = true;
    }

    function setArtifactRetrieved(
        uint256 gameID,
        uint256 playerID,
        string memory artifact
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        artifactsRetrieved[gameID][playerID].push(artifact);
    }

    function setGameOver(uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        gameOver[gameID] = true;
    }

    function registerPlayer(address playerAddress, uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        PLAYER_REGISTRY.registerPlayer(playerAddress, gameID);
    }

    function lockRegistration(uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        PLAYER_REGISTRY.lockRegistration(gameID);
    }

    function enterPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zone
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        HEX_ZONE.enterPlayer(playerAddress, gameID, zone);
    }

    /*
// TODO: call this when player credits run out
    function exitPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zone
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        HEX_ZONE.exitPlayer(playerAddress, gameID, zone);
    }
*/
    function requestNewGame(address gameRegistryAddress, uint256 maxPlayers)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        uint256 gameSize = maxPlayers > 4 ? 4 : maxPlayers == 0
            ? 1
            : maxPlayers;
        uint256 gameID = GameRegistry(gameRegistryAddress).registerGame();
        // TODO: set this to whatever size rooms we want (up to 4)
        PLAYER_REGISTRY.setRegistrationLimit(gameSize, gameID);
    }

    function setGameState(uint256 gs, uint256 gameID)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        // 0 start
        // 1 inititalizing
        // 2 initialized
        gameState[gameID] = gs;
    }

    function start(uint256 gameID) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        _gamesNeedUpdates.push(gameID);
    }

    function enableZone(
        string memory _zoneAlias,
        HexplorationZone.Tile tile,
        uint256 gameID
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        if (!zoneEnabled[gameID][_zoneAlias]) {
            HEX_ZONE.setTile(tile, gameID, _zoneAlias);
            zoneEnabled[gameID][_zoneAlias] = true;
        }
    }

    // pass path and what tiles should be
    // pass current zone as first argument
    function moveThroughPath(
        string[] memory zonePath,
        uint256 playerID,
        uint256 gameID,
        HexplorationZone.Tile[] memory tiles
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        string memory currentZone = currentPlayZone[gameID][playerID];
        address playerAddress = PLAYER_REGISTRY.playerAddress(gameID, playerID);
        HEX_ZONE.exitPlayer(playerAddress, gameID, currentZone);
        HEX_ZONE.enterPlayer(
            playerAddress,
            gameID,
            zonePath[zonePath.length - 1]
        );
        for (uint256 i = 0; i < zonePath.length; i++) {
            enableZone(zonePath[i], tiles[i], gameID);
        }
    }

    function openGames(address gameRegistryAddress)
        public
        view
        returns (
            uint256[] memory availableGames,
            uint256[] memory playerLimit,
            uint256[] memory currentRegistrations
        )
    {
        uint256[] memory allGames = GameRegistry(gameRegistryAddress)
            .allGames();
        uint256 openGamesCount = 0;
        for (uint256 i = 0; i < allGames.length; i++) {
            uint256 gameID = allGames[i];

            if (
                PLAYER_REGISTRY.totalRegistrations(gameID) <
                PLAYER_REGISTRY.registrationLimit(gameID) &&
                !PLAYER_REGISTRY.registrationLocked(gameID)
            ) {
                openGamesCount++;
            }
        }
        uint256 position = 0;
        availableGames = new uint256[](openGamesCount);
        playerLimit = new uint256[](openGamesCount);
        currentRegistrations = new uint256[](openGamesCount);
        for (uint256 i = 0; i < allGames.length; i++) {
            uint256 gameID = allGames[i];
            uint256 registrationLimit = PLAYER_REGISTRY.registrationLimit(
                gameID
            );
            uint256 totalRegistrations = PLAYER_REGISTRY.totalRegistrations(
                gameID
            );
            if (
                totalRegistrations < registrationLimit &&
                !PLAYER_REGISTRY.registrationLocked(gameID)
            ) {
                availableGames[position] = gameID;
                playerLimit[position] = registrationLimit;
                currentRegistrations[position] = totalRegistrations;
                position++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@luckymachines/game-core/contracts/src/v0.0/PlayZone.sol";

contract HexplorationZone is PlayZone {
    enum Tile {
        Default,
        Jungle,
        Plains,
        Desert,
        Mountain,
        LandingSite,
        RelicMystery,
        Relic1,
        Relic2,
        Relic3,
        Relic4,
        Relic5
    }

    // Mappings from game ID => zone alias
    mapping(uint256 => mapping(string => Tile)) public tile;
    mapping(uint256 => mapping(string => bool)) public tileIsSet;

    constructor(
        address _rulesetAddress,
        address _gameRegistryAddress,
        address adminAddress,
        address factoryAddress
    )
        PlayZone(
            _rulesetAddress,
            _gameRegistryAddress,
            adminAddress,
            factoryAddress
        )
    {}

    function setTile(
        Tile _tile,
        uint256 gameID,
        string memory zoneAlias
    ) public onlyRole(GAME_BOARD_ROLE) {
        tile[gameID][zoneAlias] = _tile;
        tileIsSet[gameID][zoneAlias] = true;
    }

    function playerCanEnter(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) public view override returns (bool canEnter) {
        canEnter = super.playerCanEnter(playerAddress, gameID, zoneAlias);
    }

    function playerCanExit(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) public view override returns (bool canExit) {
        canExit = super.playerCanExit(playerAddress, gameID, zoneAlias);
    }

    /*
    function _playerDidExit(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal override {
        // TODO:
        // update player registry with game info so player isn't registered for game anymore
        // this can be called if player credits run out
    }
*/
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//TODO:
// setup timer keeper for when all players don't submit moves

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./HexplorationStateUpdate.sol";
import "./GameEvents.sol";

contract HexplorationQueue is AccessControlEnumerable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter internal QUEUE_ID;
    CharacterCard internal CHARACTER_CARD;
    GameEvents internal GAME_EVENTS;

    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    enum ProcessingPhase {
        Start,
        Submission,
        Processing,
        PlayThrough,
        Processed,
        Closed
    }
    enum Action {
        Idle,
        Move,
        SetupCamp,
        BreakDownCamp,
        Dig,
        Rest,
        Help
    }

    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");
    bytes32 public constant GAMEPLAY_ROLE = keccak256("GAMEPLAY_ROLE");

    //////////////////////////////////////////////
    // For testing only. Do not use in production
    bool _testMode;
    uint256[] _testRandomness;
    //////////////////////////////////////////////

    // Array of Queue IDs to be processed.
    uint256[] public processingQueue;

    // do we need these 2?
    mapping(uint256 => uint16) public currentQueuePosition; // ?? increases with each player in queue, then back to 0
    mapping(uint256 => uint16) public playThroughPosition; // ?? in case we need to batch this too... hopefully not.

    // mapping from game ID
    mapping(uint256 => uint256) public queueID; // mapping from game ID to it's queue, updates to 0 when finished

    // Idle player tracking
    // mapping from gameID => playerID
    mapping(uint256 => mapping(uint256 => uint256)) public idleTurns;
    // increase by one every time turn processed
    // reset each player with something in queue to 0

    // mappings from queue index
    mapping(uint256 => bool) public inProcessingQueue; // game queue is in processing queue
    mapping(uint256 => ProcessingPhase) public currentPhase; // processingPhase
    mapping(uint256 => uint256) public game; // mapping from queue ID to its game ID
    mapping(uint256 => uint256[]) public players; // all players with moves to process
    mapping(uint256 => uint256) public totalPlayers; // total # of players who will be submitting
    mapping(uint256 => uint256[41]) public randomness; // randomness delivered here at start of each phase processing
    mapping(uint256 => bool[41]) public randomNeeds; // which slots requested randomness
    mapping(uint256 => uint256) public totalRandomWords; // how many random words to request from VRF
    mapping(uint256 => bool) public isDayPhase; // if queue is running during day phase
    // mappings from queue index => player id
    mapping(uint256 => mapping(uint256 => Action)) public submissionAction;
    mapping(uint256 => mapping(uint256 => string[])) public submissionOptions;
    mapping(uint256 => mapping(uint256 => string)) public submissionLeftHand;
    mapping(uint256 => mapping(uint256 => string)) public submissionRightHand;
    mapping(uint256 => mapping(uint256 => bool)) public playerSubmitted;
    mapping(uint256 => mapping(uint256 => uint8[3]))
        public playerStatsAtSubmission;

    // current action, so we know what to process during play through phase
    mapping(uint256 => mapping(uint256 => Action)) public activeAction; // defaults to idle

    // From request ID => queue ID
    mapping(uint256 => uint256) internal randomnessRequestQueueID; // ID set before randomness delivered

    constructor(
        address gameplayAddress,
        address characterCard,
        uint64 _vrfSubscriptionID,
        address _vrfCoordinator,
        bytes32 _keyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(GAMEPLAY_ROLE, gameplayAddress);
        QUEUE_ID.increment(); // start at 1
        CHARACTER_CARD = CharacterCard(characterCard);
        s_subscriptionId = _vrfSubscriptionID;
        s_keyHash = _keyHash;
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
    }

    // Can set multiple VCs, one for manual pushing, one for keeper
    function addVerifiedController(address controllerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, controllerAddress);
    }

    function setGameEvents(address gameEventsAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_EVENTS = GameEvents(gameEventsAddress);
    }

    // Used to check if contract is in testing mode
    function getTestRandomness()
        public
        view
        returns (bool usingTestRandomness, uint256[] memory testRandomness)
    {
        usingTestRandomness = _testMode;
        testRandomness = _testRandomness;
    }

    function isInTestMode() public view returns (bool testMode) {
        testMode = _testMode;
    }

    function getRandomness(uint256 _queueID)
        public
        view
        returns (uint256[41] memory)
    {
        return randomness[_queueID];
    }

    // pass total # players making submissions
    // total can be less than actual totalPlayers in game
    function requestGameQueue(uint256 gameID, uint256 _totalPlayers)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
        returns (uint256)
    {
        return _requestGameQueue(gameID, _totalPlayers);
    }

    // Sent from controller

    function startGame(uint256 _queueID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        currentPhase[_queueID] = ProcessingPhase.Submission;
    }

    function submitActionForPlayer(
        uint256 playerID,
        uint8 action,
        string[] memory options,
        string memory leftHand,
        string memory rightHand,
        uint256 _queueID,
        bool _isDayPhase
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        require(
            currentPhase[_queueID] == ProcessingPhase.Submission,
            "Not submission phase"
        );
        if (!playerSubmitted[_queueID][playerID]) {
            submissionAction[_queueID][playerID] = Action(action);
            submissionOptions[_queueID][playerID] = options;
            submissionLeftHand[_queueID][playerID] = leftHand;
            submissionRightHand[_queueID][playerID] = rightHand;

            players[_queueID].push(playerID);
            playerSubmitted[_queueID][playerID] = true;
            // automatically add to queue if last player to submit move
            if (players[_queueID].length >= totalPlayers[_queueID]) {
                // set to opposite of current phase since this check will be done during next phase
                isDayPhase[_queueID] = !_isDayPhase;
                _processAllActions(_queueID);
            }
            playerStatsAtSubmission[_queueID][playerID] = CHARACTER_CARD
                .getStats(game[_queueID], playerID);

            GAME_EVENTS.emitActionSubmit(
                game[_queueID],
                playerID,
                uint256(action)
            );
        }
    }

    // Will get processed once keeper is available
    // and previous game queues have been processed
    function requestProcessActions(uint256 _queueID, bool _isDayPhase)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        isDayPhase[_queueID] = !_isDayPhase;
        _processAllActions(_queueID);
    }

    function getAllPlayers(uint256 _queueID)
        public
        view
        returns (uint256[] memory)
    {
        return players[_queueID];
    }

    function getSubmissionOptions(uint256 _queueID, uint256 _playerID)
        public
        view
        returns (string[] memory)
    {
        return submissionOptions[_queueID][_playerID];
    }

    function getStatsAtSubmission(uint256 _queueID, uint256 _playerID)
        public
        view
        returns (uint8[3] memory)
    {
        return playerStatsAtSubmission[_queueID][_playerID];
    }

    function getProcessingQueue() public view returns (uint256[] memory) {
        return processingQueue;
    }

    // Gameplay interactions
    function setPhase(ProcessingPhase phase, uint256 _queueID)
        external
        onlyRole(GAMEPLAY_ROLE)
    {
        currentPhase[_queueID] = phase;
        GAME_EVENTS.emitProcessingPhaseChange(game[_queueID], uint256(phase));
        if (phase == ProcessingPhase.Processing) {
            GAME_EVENTS.emitTurnProcessingStart(game[_queueID]);
        }
    }

    function setRandomNumbers(
        uint256[41] memory randomNumbers,
        uint256 _queueID
    ) external onlyRole(GAMEPLAY_ROLE) {
        randomness[_queueID] = randomNumbers;
    }

    function requestNewQueueID(uint256 _queueID)
        external
        onlyRole(GAMEPLAY_ROLE)
    {
        uint256 g = game[_queueID];
        uint256 tp = totalPlayers[_queueID];
        queueID[g] = _requestGameQueue(g, tp);
    }

    function finishProcessing(uint256 _queueID, bool gameComplete)
        public
        onlyRole(GAMEPLAY_ROLE)
    {
        _setProcessingComplete(_queueID, gameComplete);
    }

    function _setProcessingComplete(uint256 _queueID, bool gameComplete)
        internal
    {
        uint256 g = game[_queueID];
        currentPhase[_queueID] = ProcessingPhase.Processed;
        queueID[g] = 0;
        inProcessingQueue[_queueID] = false;
        for (uint256 i = 0; i < processingQueue.length; i++) {
            if (processingQueue[i] == _queueID) {
                processingQueue[i] = 0;
                break;
            }
        }
        if (!gameComplete) {
            // get new queue ID for next set of player actions
            uint256 tp = totalPlayers[_queueID];
            uint256 newQueueID = _requestGameQueue(g, tp);
            queueID[g] = newQueueID;
            currentPhase[newQueueID] = ProcessingPhase.Submission;
        }
    }

    // Internal
    function _processAllActions(uint256 _queueID) internal {
        // Can only add unique unprocessed game queues into processing queue
        if (
            !inProcessingQueue[_queueID] &&
            currentPhase[_queueID] == ProcessingPhase.Submission
        ) {
            processingQueue.push(_queueID);
            inProcessingQueue[_queueID] = true;
            currentPhase[_queueID] = ProcessingPhase.Processing;

            // update idleness
            _updateIdleness(_queueID);

            // request random number for phase
            requestRandomWords(_queueID);
        }
    }

    function _updateIdleness(uint256 _queueID) internal {
        uint256 gameID = game[_queueID];
        for (uint256 i = 1; i < 5; i++) {
            if (playerSubmitted[_queueID][i]) {
                idleTurns[gameID][i] = 0;
            } else {
                idleTurns[gameID][i] += 1;
            }
        }
    }

    function requestRandomWords(uint256 _queueID) internal {
        setRandomNeeds(_queueID);

        // uint256 reqID = COORDINATOR.requestRandomWords(
        //     s_keyHash,
        //     s_subscriptionId,
        //     requestConfirmations,
        //     callbackGasLimit,
        //     totalRandomWords[_queueID]
        // );

        // randomnessRequestQueueID[reqID] = _queueID;

        // testing below, uncomment VRF code above to enable chainlink vrf for production
        // & comment testing code out
        uint256 reqID = _queueID;
        randomnessRequestQueueID[reqID] = _queueID;
        uint256 random = uint256(keccak256(abi.encode(block.timestamp, reqID)));
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = random;
        fulfillRandomWords(reqID, randomWords);
    }

    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
        internal
        override
    {
        uint256 qID = randomnessRequestQueueID[requestID];
        if (_testMode) {
            processRandomWords(qID, _testRandomness);
        } else {
            processRandomWords(qID, randomWords);
        }
    }

    function setRandomNeeds(uint256 _queueID) internal {
        // set bools in _randomNeeds for each test
        uint256[] memory _players = players[_queueID];
        bool[41] storage _randomNeeds = randomNeeds[_queueID];
        uint256 numbersNeeded = 1;
        for (uint256 i = 0; i < _players.length; i++) {
            uint256 playerID = _players[i];
            uint256 startingIndex;

            if (submissionAction[_queueID][playerID] == Action.Dig) {
                // is player digging?
                ////        1       2          3        4
                //// set [0,1,2], [3,4,5], [6,7,8], or [9,10,11]
                startingIndex = playerID == 1 ? 0 : playerID == 2
                    ? 3
                    : playerID == 3
                    ? 6
                    : 9;
                _randomNeeds[startingIndex] = true;
                _randomNeeds[startingIndex + 1] = true;
                _randomNeeds[startingIndex + 2] = true;
                numbersNeeded += 3;
            } else if (submissionAction[_queueID][playerID] == Action.Move) {
                // is player moving? // limited to 4 random values for movement (might need more)
                ////        1               2           3                   4
                //// set [25,26,27,28], [29,30,31,32], [33,34,35,36], or [37,38,39,40]
                startingIndex = playerID == 1 ? 25 : playerID == 2
                    ? 29
                    : playerID == 3
                    ? 33
                    : 37;
                _randomNeeds[startingIndex] = true;
                _randomNeeds[startingIndex + 1] = true;
                _randomNeeds[startingIndex + 2] = true;
                _randomNeeds[startingIndex + 3] = true;
                numbersNeeded += 4;
            }

            if (isDayPhase[_queueID]) {
                // is it day time?
                ////        1           2           3               4
                //// set [13,14,15], [16,17,18], [19,20,21], or [22,23,24]
                startingIndex = playerID == 1 ? 13 : playerID == 2
                    ? 16
                    : playerID == 3
                    ? 19
                    : 22;
                _randomNeeds[startingIndex] = true;
                _randomNeeds[startingIndex + 1] = true;
                _randomNeeds[startingIndex + 2] = true;
                numbersNeeded += 3;
            }
        }

        //// set 12 (dig dispute / flag that randomness was delivered)
        _randomNeeds[12] = true;
        totalRandomWords[_queueID] = numbersNeeded;
    }

    function processRandomWords(uint256 _queueID, uint256[] memory randomWords)
        internal
    {
        bool[41] memory _randomNeeds = randomNeeds[_queueID];
        uint256 position = 0;
        for (uint256 i = 0; i < _randomNeeds.length; i++) {
            if (_randomNeeds[i]) {
                randomness[_queueID][i] = randomWords[position];
                position++;
            }
        }
    }

    function _requestGameQueue(uint256 gameID, uint256 _totalPlayers)
        internal
        returns (uint256)
    {
        require(queueID[gameID] == 0, "queue already set");
        uint256 newQueueID = QUEUE_ID.current();
        game[newQueueID] = gameID;
        queueID[gameID] = newQueueID;
        totalPlayers[newQueueID] = _totalPlayers;
        QUEUE_ID.increment();
        return newQueueID;
    }

    // Admin functions
    function setTestRandomness(
        bool useTestRandomness,
        uint256[] memory testRandomness
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _testMode = useTestRandomness;
        _testRandomness = testRandomness;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CharacterCard is AccessControlEnumerable {
    enum Action {
        Idle,
        Move,
        SetupCamp,
        BreakDownCamp,
        Dig,
        Rest,
        Help
    }

    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");
    uint8 public constant MAX_MOVEMENT = 4;
    uint8 public constant MAX_AGILITY = 4;
    uint8 public constant MAX_DEXTERITY = 4;

    address public itemToken;
    address public artifactToken;
    address public relicToken;
    // game id => player ID
    mapping(uint256 => mapping(uint256 => uint8)) public movement;
    mapping(uint256 => mapping(uint256 => uint8)) public agility;
    mapping(uint256 => mapping(uint256 => uint8)) public dexterity;
    mapping(uint256 => mapping(uint256 => Action)) public action; // set to enumerated list
    //// the following assign a token type, player must still hold balance to use item
    mapping(uint256 => mapping(uint256 => string)) public leftHandItem;
    mapping(uint256 => mapping(uint256 => string)) public rightHandItem;
    mapping(uint256 => mapping(uint256 => string)) public artifact;
    mapping(uint256 => mapping(uint256 => string)) public status;
    mapping(uint256 => mapping(uint256 => string)) public relic;
    // results of current action
    mapping(uint256 => mapping(uint256 => string)) public activeActionCardType;
    mapping(uint256 => mapping(uint256 => string)) public activeActionCardDrawn;
    mapping(uint256 => mapping(uint256 => string))
        public activeActionCardResult;
    mapping(uint256 => mapping(uint256 => string[3]))
        public activeActionCardInventoryChanges;
    mapping(uint256 => mapping(uint256 => int8[3]))
        public activeActionStatUpdates;
    // results of latest day phase
    mapping(uint256 => mapping(uint256 => string))
        public dayPhaseActionCardType;
    mapping(uint256 => mapping(uint256 => string))
        public dayPhaseActionCardDrawn;
    mapping(uint256 => mapping(uint256 => string))
        public dayPhaseActionCardResult;
    mapping(uint256 => mapping(uint256 => string[3]))
        public dayPhaseActionCardInventoryChanges;
    mapping(uint256 => mapping(uint256 => int8[3]))
        public dayPhaseActionStatUpdates;

    constructor(
        address itemTokenAddress,
        address artifactTokenAddress,
        address relicTokenAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        itemToken = itemTokenAddress;
        artifactToken = artifactTokenAddress;
        relicToken = relicTokenAddress;
    }

    function addVerifiedController(address controllerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, controllerAddress);
    }

    function isVC(address testAddress) public view returns (bool) {
        return hasRole(VERIFIED_CONTROLLER_ROLE, testAddress);
    }

    function getStats(uint256 gameID, uint256 playerID)
        public
        view
        returns (uint8[3] memory stats)
    {
        stats[0] = movement[gameID][playerID];
        stats[1] = agility[gameID][playerID];
        stats[2] = dexterity[gameID][playerID];
    }

    function getInventoryChanges(uint256 gameID, uint256 playerID)
        public
        view
        returns (string[3] memory)
    {
        return activeActionCardInventoryChanges[gameID][playerID];
    }

    function getDayPhaseInventoryChanges(uint256 gameID, uint256 playerID)
        public
        view
        returns (string[3] memory)
    {
        return dayPhaseActionCardInventoryChanges[gameID][playerID];
    }

    function getStatUpdates(uint256 gameID, uint256 playerID)
        public
        view
        returns (int8[3] memory)
    {
        return activeActionStatUpdates[gameID][playerID];
    }

    function getDayPhaseStatUpdates(uint256 gameID, uint256 playerID)
        public
        view
        returns (int8[3] memory)
    {
        return dayPhaseActionStatUpdates[gameID][playerID];
    }

    function playerIsDead(uint256 gameID, uint256 playerID)
        public
        view
        returns (bool)
    {
        if (
            movement[gameID][playerID] == 0 ||
            agility[gameID][playerID] == 0 ||
            dexterity[gameID][playerID] == 0
        ) {
            return true;
        } else {
            return false;
        }
    }

    // Controller functions
    function resetActiveActions(uint256 gameID, uint256 totalPlayers)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        for (uint256 i = 1; i < totalPlayers + 1; i++) {
            // i = player ID
            activeActionCardType[gameID][i] = "";
            activeActionCardDrawn[gameID][i] = "";
            activeActionCardResult[gameID][i] = "";
            activeActionCardInventoryChanges[gameID][i] = ["", "", ""];
            activeActionStatUpdates[gameID][i] = [int8(0), int8(0), int8(0)];
        }
    }

    function resetDayPhaseActions(uint256 gameID, uint256 totalPlayers)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        for (uint256 i = 1; i < totalPlayers + 1; i++) {
            // i = player ID
            dayPhaseActionCardType[gameID][i] = "";
            dayPhaseActionCardDrawn[gameID][i] = "";
            dayPhaseActionCardResult[gameID][i] = "";
            dayPhaseActionCardInventoryChanges[gameID][i] = ["", "", ""];
            dayPhaseActionStatUpdates[gameID][i] = [int8(0), int8(0), int8(0)];
        }
    }

    function setStats(
        uint8[3] memory stats,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        // set all stats at once [movement, agility, dexterity]
        movement[gameID][playerID] = stats[0] > MAX_MOVEMENT
            ? MAX_MOVEMENT
            : stats[0];
        agility[gameID][playerID] = stats[1] > MAX_AGILITY
            ? MAX_AGILITY
            : stats[1];
        dexterity[gameID][playerID] = stats[2] > MAX_DEXTERITY
            ? MAX_DEXTERITY
            : stats[2];
    }

    function setMovement(
        uint8 movementValue,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        movement[gameID][playerID] = movementValue > MAX_MOVEMENT
            ? MAX_MOVEMENT
            : movementValue;
    }

    function setAgility(
        uint8 agilityValue,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        agility[gameID][playerID] = agilityValue > MAX_AGILITY
            ? MAX_AGILITY
            : agilityValue;
    }

    function setDexterity(
        uint8 dexterityValue,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        dexterity[gameID][playerID] = dexterityValue > MAX_DEXTERITY
            ? MAX_DEXTERITY
            : dexterityValue;
    }

    function setLeftHandItem(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        if (
            keccak256(abi.encode(itemTokenType)) !=
            keccak256(abi.encode("None"))
        ) {
            leftHandItem[gameID][playerID] = itemTokenType;
        } else {
            // "None" was passed, which empties out hand
            leftHandItem[gameID][playerID] = "";
        }
    }

    function setRightHandItem(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        if (
            keccak256(abi.encode(itemTokenType)) !=
            keccak256(abi.encode("None"))
        ) {
            rightHandItem[gameID][playerID] = itemTokenType;
        } else {
            // "None" was passed, which empties out hand
            rightHandItem[gameID][playerID] = "";
        }
    }

    function setArtifact(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        artifact[gameID][playerID] = itemTokenType;
    }

    function setStatus(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        status[gameID][playerID] = itemTokenType;
    }

    function setRelic(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        relic[gameID][playerID] = itemTokenType;
    }

    function setAction(
        Action _action,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        action[gameID][playerID] = _action;
    }

    function setAction(
        string memory _action,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        Action a = Action.Idle;
        if (compare(_action, "Move")) {
            a = Action.Move;
        } else if (compare(_action, "Setup camp")) {
            a = Action.SetupCamp;
        } else if (compare(_action, "Break down camp")) {
            a = Action.BreakDownCamp;
        } else if (compare(_action, "Dig")) {
            a = Action.Dig;
        } else if (compare(_action, "Rest")) {
            a = Action.Rest;
        } else if (compare(_action, "Help")) {
            a = Action.Help;
        }
        action[gameID][playerID] = a;
    }

    // TODO: make sure everything calling these sends stat updates too
    function setActionResults(
        string memory actionCardType,
        string memory actionCardDrawn,
        string memory actionCardResult,
        string[3] memory actionCardInventoryChanges,
        int8[3] memory actionCardStatUpdates,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        activeActionCardType[gameID][playerID] = actionCardType;
        activeActionCardDrawn[gameID][playerID] = actionCardDrawn;
        activeActionCardResult[gameID][playerID] = actionCardResult;
        activeActionCardInventoryChanges[gameID][
            playerID
        ] = actionCardInventoryChanges;
        activeActionStatUpdates[gameID][playerID] = actionCardStatUpdates;
    }

    function setDayPhaseResults(
        string memory cardType,
        string memory cardDrawn,
        string memory cardResult,
        string[3] memory cardInventoryChanges,
        int8[3] memory cardStatUpdates,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        dayPhaseActionCardType[gameID][playerID] = cardType;
        dayPhaseActionCardDrawn[gameID][playerID] = cardDrawn;
        dayPhaseActionCardResult[gameID][playerID] = cardResult;
        dayPhaseActionCardInventoryChanges[gameID][
            playerID
        ] = cardInventoryChanges;
        dayPhaseActionStatUpdates[gameID][playerID] = cardStatUpdates;
    }

    function compare(string memory s1, string memory s2)
        public
        pure
        returns (bool isMatch)
    {
        isMatch =
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract GameEvents is AccessControlEnumerable {
    bytes32 public constant EVENT_SENDER_ROLE = keccak256("EVENT_SENDER_ROLE");

    event ActionSubmit(
        uint256 indexed gameID,
        uint256 playerID,
        uint256 actionID,
        uint256 timeStamp
    );
    event EndGameStarted(
        uint256 indexed gameID,
        uint256 timeStamp,
        string scenario
    );
    event GameOver(uint256 indexed gameID, uint256 timeStamp);
    event GamePhaseChange(
        uint256 indexed gameID,
        uint256 timeStamp,
        string newPhase
    );
    event GameRegistration(uint256 indexed gameID, address playerAddress);
    event GameStart(uint256 indexed gameID, uint256 timeStamp);
    event LandingSiteSet(uint256 indexed gameID, string landingSite);
    event PlayerIdleKick(
        uint256 indexed gameID,
        uint256 playerID,
        uint256 timeStamp
    );
    event ProcessingPhaseChange(
        uint256 indexed gameID,
        uint256 timeStamp,
        uint256 newPhase
    );
    event TurnProcessingStart(uint256 indexed gameID, uint256 timeStamp);

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // Event emitters
    function emitActionSubmit(
        uint256 gameID,
        uint256 playerID,
        uint256 actionID
    ) external onlyRole(EVENT_SENDER_ROLE) {
        emit ActionSubmit(gameID, playerID, actionID, block.timestamp);
    }

    function emitEndGameStarted(uint256 gameID, string memory scenario)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit EndGameStarted(gameID, block.timestamp, scenario);
    }

    function emitGameOver(uint256 gameID) external onlyRole(EVENT_SENDER_ROLE) {
        emit GameOver(gameID, block.timestamp);
    }

    function emitGamePhaseChange(uint256 gameID, string memory newPhase)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit GamePhaseChange(gameID, block.timestamp, newPhase);
    }

    function emitGameRegistration(uint256 gameID, address playerAddress)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit GameRegistration(gameID, playerAddress);
    }

    function emitGameStart(uint256 gameID)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit GameStart(gameID, block.timestamp);
    }

    function emitLandingSiteSet(uint256 gameID, string memory _landingSite)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit LandingSiteSet(gameID, _landingSite);
    }

    function emitPlayerIdleKick(uint256 gameID, uint256 playerID)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit PlayerIdleKick(gameID, playerID, block.timestamp);
    }

    function emitProcessingPhaseChange(uint256 gameID, uint256 newPhase)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit ProcessingPhaseChange(gameID, block.timestamp, newPhase);
    }

    function emitTurnProcessingStart(uint256 gameID)
        external
        onlyRole(EVENT_SENDER_ROLE)
    {
        emit TurnProcessingStart(gameID, block.timestamp);
    }

    function addEventSender(address eventSenderAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(EVENT_SENDER_ROLE, eventSenderAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Game Tokens
import "./GameToken.sol";

contract TokenInventory is AccessControlEnumerable {
    enum Token {
        DayNight,
        Disaster,
        Enemy,
        Item,
        PlayerStatus,
        Artifact,
        Relic
    }

    GameToken public DAY_NIGHT_TOKEN;
    GameToken public DISASTER_TOKEN;
    GameToken public ENEMY_TOKEN;
    GameToken public ITEM_TOKEN;
    GameToken public PLAYER_STATUS_TOKEN;
    GameToken public ARTIFACT_TOKEN;
    GameToken public RELIC_TOKEN;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function setTokenAddresses(
        address dayNightAddress,
        address disasterAddress,
        address enemyAddress,
        address itemAddress,
        address playerStatusAddress,
        address artifactAddress,
        address relicAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        DAY_NIGHT_TOKEN = GameToken(dayNightAddress);
        DISASTER_TOKEN = GameToken(disasterAddress);
        ENEMY_TOKEN = GameToken(enemyAddress);
        ITEM_TOKEN = GameToken(itemAddress);
        PLAYER_STATUS_TOKEN = GameToken(playerStatusAddress);
        ARTIFACT_TOKEN = GameToken(artifactAddress);
        RELIC_TOKEN = GameToken(relicAddress);
    }

    function holdsToken(
        uint256 holderID,
        Token token,
        uint256 gameID
    ) public view returns (bool hasBalance) {
        hasBalance = false;
        string[] memory allTypes;
        if (token == Token.DayNight) {
            allTypes = DAY_NIGHT_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (
                    DAY_NIGHT_TOKEN.balance(allTypes[i], gameID, holderID) > 0
                ) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.Disaster) {
            allTypes = DISASTER_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (DISASTER_TOKEN.balance(allTypes[i], gameID, holderID) > 0) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.Enemy) {
            allTypes = ENEMY_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (ENEMY_TOKEN.balance(allTypes[i], gameID, holderID) > 0) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.Item) {
            allTypes = ITEM_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (ITEM_TOKEN.balance(allTypes[i], gameID, holderID) > 0) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.PlayerStatus) {
            allTypes = PLAYER_STATUS_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (
                    PLAYER_STATUS_TOKEN.balance(allTypes[i], gameID, holderID) >
                    0
                ) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.Artifact) {
            allTypes = ARTIFACT_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (ARTIFACT_TOKEN.balance(allTypes[i], gameID, holderID) > 0) {
                    hasBalance = true;
                    break;
                }
            }
        } else if (token == Token.Relic) {
            allTypes = RELIC_TOKEN.getTokenTypes();
            for (uint256 i = 0; i < allTypes.length; i++) {
                if (RELIC_TOKEN.balance(allTypes[i], gameID, holderID) > 0) {
                    hasBalance = true;
                    break;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// TODO: start using this for state updating outside of controller
// Controller should only be used by users / UI directly sending
// commands. This does things that can only imagine...

// This should be only associated with one board...

import "./HexplorationController.sol";
import "./HexplorationBoard.sol";
import "./CardDeck.sol";
import "./CharacterCard.sol";
import "./HexplorationGameplay.sol";
import "./GameEvents.sol";
import "./RandomIndices.sol";
import "./GameWallets.sol";

contract HexplorationStateUpdate is
    AccessControlEnumerable,
    RandomIndices,
    GameWallets
{
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");
    /*
    Controller can access all game tokens with the following methods:

    function mint(
        string memory tokenType,
        uint256 gameID,
        uint256 quantity
    )

    function transfer(
        string memory tokenType,
        uint256 gameID,
        uint256 fromID,
        uint256 toID,
        uint256 quantity
    )
*/

    HexplorationBoard internal GAME_BOARD;
    CharacterCard internal CHARACTER_CARD;
    GameEvents internal GAME_EVENTS;

    modifier onlyAdminVC() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) ||
                hasRole(VERIFIED_CONTROLLER_ROLE, _msgSender()),
            "Admin or Keeper role required"
        );
        _;
    }

    // set other addresses going to need here
    // decks, tokens?
    constructor(address gameBoardAddress, address characterCardAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        GAME_BOARD = HexplorationBoard(gameBoardAddress);
        CHARACTER_CARD = CharacterCard(characterCardAddress);
    }

    // Admin Functions

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    function setGameEvents(address gameEventsAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_EVENTS = GameEvents(gameEventsAddress);
    }

    function postUpdates(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        // go through values and post everything, transfer all the tokens, and pray
        // use gamestate update contract to post everything
        // CHARACTER_CARD.resetActiveActions(
        //     gameID,
        //     GAME_EVENTS.totalPlayers(address(GAME_BOARD), gameID)
        // );
        updatePlayerPositions(updates, gameID);
        updatePlayerStats(updates, gameID);
        updatePlayerHands(updates, gameID);
        transferPlayerItems(updates, gameID);
        transferZoneItems(updates, gameID);
        applyActivityEffects(updates, gameID);
        updatePlayPhase(updates, gameID);

        checkGameOver(gameID);
    }

    function postUpdates(
        HexplorationGameplay.PlayUpdates memory updates,
        HexplorationGameplay.PlayUpdates memory dayPhaseUpdates,
        uint256 gameID
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        // Only reset day phase actions here
        // this only gets called on day phase playthroughs
        // active actions already reset / reprocessed at this point
        // CHARACTER_CARD.resetDayPhaseActions(
        //     gameID,
        //     GAME_EVENTS.totalPlayers(address(GAME_BOARD), gameID)
        // );
        updatePlayerPositions(updates, gameID);
        updatePlayerStats(updates, gameID);
        updatePlayerHands(updates, gameID);
        transferPlayerItems(updates, gameID);
        transferZoneItems(updates, gameID);
        applyActivityEffects(updates, gameID);
        updatePlayPhase(updates, gameID);

        if (!checkGameOver(gameID)) {
            // Then process day phase updates
            /*
        // string memory card;
        // int8[3] memory stats;
        // string memory itemTypeLoss;
        // string memory itemTypeGain;
        // string memory handLoss;
        // string memory outcome;
        (
            dayPhaseUpdates.activeActionResultCard[i][0],
            dayPhaseUpdates.playerStatUpdates[i],
            dayPhaseUpdates.activeActionInventoryChanges[i][0],
            dayPhaseUpdates.activeActionInventoryChanges[i][1],
            dayPhaseUpdates.activeActionInventoryChanges[i][2],
            dayPhaseUpdates.activeActionResultCard[i][1] = draw card
        */

            applyDayPhaseEffects(dayPhaseUpdates, gameID);
            updatePlayerStats(dayPhaseUpdates, gameID);
            updatePlayerHands(dayPhaseUpdates, gameID);
            transferPlayerItems(dayPhaseUpdates, gameID);
            transferZoneItems(dayPhaseUpdates, gameID);
            checkGameOver((gameID));
        }
    }

    /*
    struct PlayUpdates {
        uint256[] playerPositionIDs;
        uint256[] spacesToMove;
        uint256[] playerEquipIDs;
        uint256[] playerEquipHands;
        uint256[] zoneTransfersTo;
        uint256[] zoneTransfersFrom;
        uint256[] zoneTransferQtys;
        uint256[] playerTransfersTo;
        uint256[] playerTransfersFrom;
        uint256[] playerTransferQtys;
        uint256[] playerStatUpdateIDs;
        int8[3][] playerStatUpdates; // amount to adjust, not final value
        uint256[] playerActiveActionIDs;
        string gamePhase;
        string[7][] playerMovementOptions; // TODO: set this to max # of spaces possible
        string[] playerEquips;
        string[] zoneTransferItemTypes;
        string[] playerTransferItemTypes;
        string[] activeActions;
        string[][] activeActionOptions;
        uint256[] activeActionResults; // 0 = None, 1 = Event, 2 = Ambush, 3 = Treasure
        string[2][] activeActionResultCard; // Card for Event / ambush / treasure , outcome e.g. ["Dance with locals", "You're amazing!"]
        string[3][] activeActionInventoryChange; // [item loss, item gain, hand loss]
        uint256 randomness;
    }
    */

    function updatePlayerPositions(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        for (uint256 i = 0; i < updates.playerPositionIDs.length; i++) {
            uint256 spacesToMove = updates.spacesToMove[i];
            string[] memory path = new string[](spacesToMove);
            for (uint256 j = 0; j < spacesToMove; j++) {
                path[j] = updates.playerMovementOptions[i][j];
            }
            uint256 playerID = updates.playerPositionIDs[i];
            uint256[] memory revealRandomness = new uint256[](4);
            if (playerID == 1) {
                revealRandomness[0] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal1)
                ];
                revealRandomness[1] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal2)
                ];
                revealRandomness[2] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal3)
                ];
                revealRandomness[3] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal4)
                ];
            } else if (playerID == 2) {
                revealRandomness[0] = updates.randomness[
                    uint256(RandomIndex.P2TileReveal1)
                ];
                revealRandomness[1] = updates.randomness[
                    uint256(RandomIndex.P2TileReveal2)
                ];
                revealRandomness[2] = updates.randomness[
                    uint256(RandomIndex.P2TileReveal3)
                ];
                revealRandomness[3] = updates.randomness[
                    uint256(RandomIndex.P2TileReveal4)
                ];
            } else if (playerID == 3) {
                revealRandomness[0] = updates.randomness[
                    uint256(RandomIndex.P3TileReveal1)
                ];
                revealRandomness[1] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal2)
                ];
                revealRandomness[2] = updates.randomness[
                    uint256(RandomIndex.P1TileReveal3)
                ];
                revealRandomness[3] = updates.randomness[
                    uint256(RandomIndex.P3TileReveal4)
                ];
            } else if (playerID == 4) {
                revealRandomness[0] = updates.randomness[
                    uint256(RandomIndex.P4TileReveal1)
                ];
                revealRandomness[1] = updates.randomness[
                    uint256(RandomIndex.P4TileReveal2)
                ];
                revealRandomness[2] = updates.randomness[
                    uint256(RandomIndex.P4TileReveal3)
                ];
                revealRandomness[3] = updates.randomness[
                    uint256(RandomIndex.P4TileReveal4)
                ];
            }

            moveThroughPath(path, gameID, playerID, revealRandomness);
        }
    }

    function updatePlayerStats(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        for (uint256 i = 0; i < updates.playerStatUpdateIDs.length; i++) {
            uint256 playerID = updates.playerStatUpdateIDs[i];
            uint8[3] memory currentStats = CHARACTER_CARD.getStats(
                gameID,
                playerID
            );
            uint8[3] memory stats;
            // Subtracts from updates down to zero, may set higher than max, will get limited upon setting on CC
            stats[0] = updates.playerStatUpdates[i][0] < 0
                ? subToZero(
                    currentStats[0],
                    absoluteValue(updates.playerStatUpdates[i][0])
                )
                : currentStats[0] + uint8(updates.playerStatUpdates[i][0]);
            stats[1] = updates.playerStatUpdates[i][1] < 0
                ? subToZero(
                    currentStats[1],
                    absoluteValue(updates.playerStatUpdates[i][1])
                )
                : currentStats[1] + uint8(updates.playerStatUpdates[i][1]);
            stats[2] = updates.playerStatUpdates[i][2] < 0
                ? subToZero(
                    currentStats[2],
                    absoluteValue(updates.playerStatUpdates[i][2])
                )
                : currentStats[2] + uint8(updates.playerStatUpdates[i][2]);
            CHARACTER_CARD.setStats(stats, gameID, playerID);
        }
    }

    function updatePlayerHands(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        // TODO: transfer item to bank if in inventory + removing from hand
        for (uint256 i = 0; i < updates.playerEquipIDs.length; i++) {
            bool leftHand = updates.playerEquipHands[i] == 0;
            if (leftHand) {
                CHARACTER_CARD.setLeftHandItem(
                    updates.playerEquips[i],
                    gameID,
                    updates.playerEquipIDs[i]
                );
            } else {
                CHARACTER_CARD.setRightHandItem(
                    updates.playerEquips[i],
                    gameID,
                    updates.playerEquipIDs[i]
                );
            }
        }
    }

    function applyActivityEffects(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        for (uint256 i = 0; i < updates.activeActions.length; i++) {
            CHARACTER_CARD.setAction(
                updates.activeActions[i],
                gameID,
                updates.playerActiveActionIDs[i]
            );
            uint256 cardTypeID = updates.activeActionResults[i];
            string memory cardType;
            if (cardTypeID == 1) {
                cardType = "Event";
            } else if (cardTypeID == 2) {
                cardType = "Ambush";
            } else if (cardTypeID == 3) {
                cardType = "Treasure";
            } else {
                cardType = "None";
            }
            CHARACTER_CARD.setActionResults(
                cardType,
                updates.activeActionResultCard[i][0],
                updates.activeActionResultCard[i][1],
                updates.activeActionInventoryChanges[i],
                updates.playerStatUpdates.length > i
                    ? updates.playerStatUpdates[i]
                    : [int8(0), int8(0), int8(0)],
                gameID,
                updates.playerActiveActionIDs[i]
            );
        }
    }

    function applyDayPhaseEffects(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        for (uint256 i = 0; i < updates.activeActions.length; i++) {
            uint256 cardTypeID = updates.activeActionResults[i];
            string memory cardType;
            if (cardTypeID == 1) {
                cardType = "Event";
            } else if (cardTypeID == 2) {
                cardType = "Ambush";
            } else if (cardTypeID == 3) {
                cardType = "Treasure";
            } else {
                cardType = "None";
            }
            CHARACTER_CARD.setDayPhaseResults(
                cardType,
                updates.activeActionResultCard[i][0],
                updates.activeActionResultCard[i][1],
                updates.activeActionInventoryChanges[i],
                updates.playerStatUpdates[i],
                gameID,
                updates.playerActiveActionIDs[i]
            );
        }
    }

    function transferPlayerItems(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        // Transfers to / from players (item gains / losses)
        TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
        for (uint256 i = 0; i < updates.playerTransfersTo.length; i++) {
            if (
                updates.playerTransfersFrom[i] != 0 ||
                updates.playerTransfersTo[i] != 0
            ) {
                if (
                    ti.ITEM_TOKEN().balance(
                        updates.playerTransferItemTypes[i],
                        gameID,
                        updates.playerTransfersFrom[i]
                    ) >= updates.playerTransferQtys[i]
                ) {
                    // transfer item to player or to bank
                    ti.ITEM_TOKEN().transfer(
                        updates.playerTransferItemTypes[i],
                        gameID,
                        updates.playerTransfersFrom[i],
                        updates.playerTransfersTo[i],
                        updates.playerTransferQtys[i]
                    );
                    // check if item is artifact
                    if (itemIsArtifact(updates.playerTransferItemTypes[i])) {
                        // set artifact for player
                        CHARACTER_CARD.setArtifact(
                            updates.playerTransferItemTypes[i],
                            gameID,
                            updates.playerTransfersTo[i]
                        );
                        GAME_BOARD.setArtifactFound(
                            gameID,
                            GAME_BOARD.currentPlayZone(
                                gameID,
                                updates.playerTransfersTo[i]
                            )
                        );
                    }
                }
            }
        }
        // Hand losses
        for (uint256 i = 0; i < updates.playerHandLossIDs.length; i++) {
            uint256 playerID = updates.playerHandLossIDs[i];
            if (updates.playerHandLosses[i] == 1) {
                // Right hand loss
                string memory rightHandItem = CHARACTER_CARD.rightHandItem(
                    gameID,
                    playerID
                );
                if (
                    ti.ITEM_TOKEN().balance(rightHandItem, gameID, playerID) > 0
                ) {
                    // Transfer to bank
                    ti.ITEM_TOKEN().transfer(
                        rightHandItem,
                        gameID,
                        playerID,
                        0,
                        1
                    );
                }
                // set hand to empty
                CHARACTER_CARD.setRightHandItem(
                    "",
                    gameID,
                    updates.playerHandLossIDs[i]
                );
            } else {
                // Left hand loss
                string memory leftHandItem = CHARACTER_CARD.leftHandItem(
                    gameID,
                    playerID
                );
                if (
                    ti.ITEM_TOKEN().balance(leftHandItem, gameID, playerID) > 0
                ) {
                    // Transfer to bank
                    ti.ITEM_TOKEN().transfer(
                        leftHandItem,
                        gameID,
                        playerID,
                        0,
                        1
                    );
                }
                // set hand to empty
                CHARACTER_CARD.setLeftHandItem(
                    "",
                    gameID,
                    updates.playerHandLossIDs[i]
                );
            }
        }
    }

    function transferZoneItems(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        // these are all current zone to player or player to current zone
        // we don't cover the zone to zone or player to other zone transfer cases yet
        TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
        for (uint256 i = 0; i < updates.zoneTransfersTo.length; i++) {
            // If to == current zone, from = playerID
            // if from == current zone, to = playerID
            uint256 toID = updates.zoneTransfersTo[i] == 10000000000
                ? currentZoneIndex(gameID, updates.zoneTransfersFrom[i])
                : updates.zoneTransfersTo[i];
            uint256 fromID = updates.zoneTransfersFrom[i] == 10000000000
                ? currentZoneIndex(gameID, updates.zoneTransfersTo[i])
                : updates.zoneTransfersFrom[i];
            uint256 tferQty = updates.zoneTransferQtys[i];
            string memory tferItem = updates.zoneTransferItemTypes[i];
            if (updates.zoneTransfersTo[i] == 10000000000) {
                // Player transferring item to zone
                ti.ITEM_TOKEN().transferToZone(
                    tferItem,
                    gameID,
                    fromID,
                    toID,
                    tferQty
                );
            } else if (updates.zoneTransfersFrom[i] == 10000000000) {
                // Zone transferring item to player
                ti.ITEM_TOKEN().transferFromZone(
                    tferItem,
                    gameID,
                    fromID,
                    toID,
                    tferQty
                );
            }
        }
    }

    function currentZoneIndex(uint256 gameID, uint256 playerID)
        internal
        view
        returns (uint256 index)
    {
        string memory zoneAlias = GAME_BOARD.currentPlayZone(gameID, playerID);
        string[] memory allZones = GAME_BOARD.getZoneAliases();
        index = 1111111111111;
        for (uint256 i = 0; i < allZones.length; i++) {
            if (
                keccak256(abi.encodePacked(zoneAlias)) ==
                keccak256(abi.encodePacked(allZones[i]))
            ) {
                index = i;
                break;
            }
        }
    }

    function moveThroughPath(
        string[] memory zonePath,
        uint256 gameID,
        uint256 playerID,
        uint256[] memory randomness
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        HexplorationZone.Tile[] memory tiles = new HexplorationZone.Tile[](
            zonePath.length > 4 ? 4 : zonePath.length
        );

        for (uint256 i = 0; i < tiles.length; i++) {
            // Need # 1 - 4 for tile selection
            tiles[i] = HexplorationZone.Tile(((randomness[i]) % 4) + 1);
        }

        GAME_BOARD.moveThroughPath(zonePath, playerID, gameID, tiles);

        if (
            stringsMatch(
                zonePath[zonePath.length - 1],
                GAME_BOARD.initialPlayZone(gameID)
            ) && playerHasArtifact(gameID, playerID)
        ) {
            // last space is at ship and player holds artifact
            dropArtifactAtShip(gameID, playerID);
        }
    }

    function updatePlayPhase(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        if (bytes(updates.gamePhase).length > 0) {
            GAME_EVENTS.emitGamePhaseChange(gameID, updates.gamePhase);
            TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
            if (
                keccak256(abi.encodePacked(updates.gamePhase)) ==
                keccak256(abi.encodePacked("Day"))
            ) {
                // set to day
                /*
                transfer(
        string memory tokenType,
        uint256 gameID,
        uint256 fromID,
        uint256 toID,
        uint256 quantity
                */
                ti.DAY_NIGHT_TOKEN().transfer(
                    "Day",
                    gameID,
                    0,
                    GAME_BOARD_WALLET_ID,
                    1
                );
                ti.DAY_NIGHT_TOKEN().transfer(
                    "Night",
                    gameID,
                    GAME_BOARD_WALLET_ID,
                    0,
                    1
                );
            } else {
                // set to night
                ti.DAY_NIGHT_TOKEN().transfer(
                    "Day",
                    gameID,
                    GAME_BOARD_WALLET_ID,
                    0,
                    1
                );
                ti.DAY_NIGHT_TOKEN().transfer(
                    "Night",
                    gameID,
                    0,
                    GAME_BOARD_WALLET_ID,
                    1
                );
            }
        }
    }

    // Utility
    // returns a - b or 0 if negative;
    function subToZero(uint8 a, uint8 b)
        internal
        pure
        returns (uint8 difference)
    {
        difference = a > b ? a - b : 0;
    }

    function absoluteValue(int8 x) internal pure returns (uint8 absX) {
        absX = x >= 0 ? uint8(x) : uint8(-x);
    }

    function stringsMatch(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function itemIsArtifact(string memory itemType)
        internal
        pure
        returns (bool)
    {
        return (stringsMatch(itemType, "Engraved Tablet") ||
            stringsMatch(itemType, "Sigil Gem") ||
            stringsMatch(itemType, "Ancient Tome"));
    }

    function itemIsCampsite(string memory itemType)
        internal
        pure
        returns (bool)
    {
        return stringsMatch(itemType, "Campsite");
    }

    function playerHasArtifact(uint256 gameID, uint256 playerID)
        internal
        view
        returns (bool)
    {
        return bytes(CHARACTER_CARD.artifact(gameID, playerID)).length > 0;
    }

    function dropArtifactAtShip(uint256 gameID, uint256 playerID) internal {
        // Transfer artifact to ship wallet
        TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
        string memory artifact = CHARACTER_CARD.artifact(gameID, playerID);
        ti.ITEM_TOKEN().transfer(artifact, gameID, playerID, SHIP_WALLET_ID, 1);
        GAME_BOARD.setArtifactRetrieved(gameID, playerID, artifact);
        // remove artifact from character card
        CHARACTER_CARD.setArtifact("", gameID, playerID);
    }

    function checkGameOver(uint256 gameID) internal returns (bool gameOver) {
        // checks if all players are dead, and if so ends game
        gameOver = true;
        for (uint256 i = 0; i < 4; i++) {
            if (!CHARACTER_CARD.playerIsDead(gameID, i + 1)) {
                gameOver = false;
                break;
            }
        }
        if (gameOver) {
            // set game over
            GAME_BOARD.setGameOver(gameID);
            // emit event
            GAME_EVENTS.emitGameOver(gameID);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

abstract contract GameWallets {
    uint256 constant GAME_BOARD_WALLET_ID = 1000000;
    uint256 constant SHIP_WALLET_ID = 2000000;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./HexplorationBoard.sol";
import "./HexplorationQueue.sol";
import "./CharacterCard.sol";
import "./TokenInventory.sol";
import "./GameEvents.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./GameWallets.sol";

contract GameSetup is AccessControlEnumerable, VRFConsumerBaseV2, GameWallets {
    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }
    // Mappings from request ID
    mapping(uint256 => RequestStatus) public randomnessRequests; /* requestId --> requestStatus */
    mapping(uint256 => uint256) public gameIDs;
    mapping(uint256 => address) public gameBoardAddresses;

    // Mappings from game ID
    mapping(uint256 => uint256) public requestIDs;

    GameEvents GAME_EVENTS;
    VRFCoordinatorV2Interface COORDINATOR;

    uint64 subscriptionId;

    // past requests Id.
    uint256[] public requestIDHistory;
    uint256 public lastRequestId;

    bytes32 keyHash;
    uint32 callbackGasLimit = 2500000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 2;

    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");

    bool public testingEnabled;

    constructor(
        uint64 _vrfSubscriptionID,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _vrfSubscriptionID;
        keyHash = _vrfKeyHash;
    }

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    function setGameEvents(address gameEventsAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_EVENTS = GameEvents(gameEventsAddress);
    }

    function setVRFSubscriptionID(uint64 _subscriptionID)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        subscriptionId = _subscriptionID;
    }

    function setTestingEnabled(bool enabled)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        testingEnabled = enabled;
    }

    function allPlayersRegistered(uint256 gameID, address boardAddress)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        // lock registration
        HexplorationBoard board = HexplorationBoard(boardAddress);
        require(board.gameState(gameID) == 0, "game already started");
        board.lockRegistration(gameID);
        if (testingEnabled) {
            testRequestRandomWords(gameID, boardAddress);
        } else {
            requestRandomWords(gameID, boardAddress);
        }
    }

    function requestRandomWords(uint256 gameID, address boardAddress)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        randomnessRequests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        gameIDs[requestId] = gameID;
        gameBoardAddresses[requestId] = boardAddress;
        requestIDs[gameID] = requestId;
        requestIDHistory.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    // If testing is enabled, this will get called. It is on the tester to also call testFulfillRandomWords
    function testRequestRandomWords(uint256 gameID, address boardAddress)
        internal
        returns (uint256 requestId)
    {
        requestId = gameID;
        randomnessRequests[requestId] = RequestStatus({
            randomWords: new uint256[](0),
            exists: true,
            fulfilled: false
        });
        gameIDs[requestId] = gameID;
        gameBoardAddresses[requestId] = boardAddress;
        requestIDs[gameID] = requestId;
        requestIDHistory.push(requestId);
        lastRequestId = requestId;
        emit RequestSent(requestId, numWords);
        return requestId;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        require(randomnessRequests[_requestId].exists, "request not found");
        randomnessRequests[_requestId].fulfilled = true;
        randomnessRequests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        mintGameTokens(_requestId);
        chooseLandingSite(_requestId);
        startGame(_requestId);
    }

    function testFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(randomnessRequests[_requestId].exists, "request not found");
        randomnessRequests[_requestId].fulfilled = true;
        randomnessRequests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        mintGameTokens(_requestId);
        chooseLandingSite(_requestId);
        startGame(_requestId);
    }

    function getRequestStatus(uint256 _requestId)
        external
        view
        returns (bool fulfilled, uint256[] memory randomWords)
    {
        require(randomnessRequests[_requestId].exists, "request not found");
        RequestStatus memory request = randomnessRequests[_requestId];
        return (request.fulfilled, request.randomWords);
    }

    function chooseLandingSite(uint256 requestID) internal {
        uint256 gameID = gameIDs[requestID];
        address boardAddress = gameBoardAddresses[requestID];
        HexplorationBoard board = HexplorationBoard(boardAddress);

        string[] memory allZones = board.getZoneAliases();
        // should have 2 random values stored, using second value
        string memory zoneChoice = allZones[
            randomnessRequests[requestID].randomWords[1] % allZones.length
        ];

        // PlayerRegistry pr = PlayerRegistry(board.prAddress());

        board.enableZone(zoneChoice, HexplorationZone.Tile.LandingSite, gameID);
        // set landing site at space on board
        board.setInitialPlayZone(zoneChoice, gameID);

        GAME_EVENTS.emitLandingSiteSet(gameID, zoneChoice);
    }

    function startGame(uint256 requestID) internal {
        uint256 gameID = gameIDs[requestID];
        address boardAddress = gameBoardAddresses[requestID];
        HexplorationBoard board = HexplorationBoard(boardAddress);
        require(board.gameState(gameID) == 0, "game already started");

        PlayerRegistry pr = PlayerRegistry(board.prAddress());

        // set game to initialized
        board.setGameState(2, gameID);

        HexplorationQueue q = HexplorationQueue(board.gameplayQueue());

        uint256 qID = q.queueID(gameID);
        if (qID == 0) {
            qID = q.requestGameQueue(
                gameID,
                uint16(pr.totalRegistrations(gameID))
            );
        }

        string memory startZone = board.initialPlayZone(gameID);
        for (uint256 i = 0; i < pr.totalRegistrations(gameID); i++) {
            uint256 playerID = i + 1;
            address playerAddress = pr.playerAddress(gameID, playerID);
            board.enterPlayer(playerAddress, gameID, startZone);
        }

        q.startGame(qID);

        GAME_EVENTS.emitGameStart(gameID);
    }

    function mintGameTokens(uint256 requestID) internal {
        uint256 gameID = gameIDs[requestID];
        HexplorationBoard board = HexplorationBoard(
            gameBoardAddresses[requestID]
        );
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        uint256 totalRegistrations = pr.totalRegistrations(gameID);

        TokenInventory ti = TokenInventory(board.tokenInventory());
        // mint game tokens (maybe mint on demand instead...)
        // minting full game set here
        ti.DAY_NIGHT_TOKEN().mint("Day", gameID, 1);
        ti.DAY_NIGHT_TOKEN().mint("Night", gameID, 1);
        ti.DISASTER_TOKEN().mint("Earthquake", gameID, 1000);
        ti.DISASTER_TOKEN().mint("Volcano", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Pirate", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Pirate Ship", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Deathbot", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Guardian", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Sandworm", gameID, 1000);
        ti.ENEMY_TOKEN().mint("Dragon", gameID, 1000);
        ti.ITEM_TOKEN().mint("Small Ammo", gameID, 1000);
        ti.ITEM_TOKEN().mint("Large Ammo", gameID, 1000);
        ti.ITEM_TOKEN().mint("Batteries", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shield", gameID, 1000);
        ti.ITEM_TOKEN().mint("Portal", gameID, 1000);
        ti.ITEM_TOKEN().mint("On", gameID, 1000);
        ti.ITEM_TOKEN().mint("Off", gameID, 1000);
        ti.ITEM_TOKEN().mint("Rusty Dagger", gameID, 1000);
        ti.ITEM_TOKEN().mint("Rusty Pistol", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shiny Dagger", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shiny Pistol", gameID, 1000);
        ti.ITEM_TOKEN().mint("Laser Dagger", gameID, 1000);
        ti.ITEM_TOKEN().mint("Laser Pistol", gameID, 1000);
        ti.ITEM_TOKEN().mint("Power Glove", gameID, 1000);
        ti.ITEM_TOKEN().mint("Engraved Tablet", gameID, 1000);
        ti.ITEM_TOKEN().mint("Sigil Gem", gameID, 1000);
        ti.ITEM_TOKEN().mint("Ancient Tome", gameID, 1000);
        ti.ITEM_TOKEN().mint("Campsite", gameID, 1000);
        ti.PLAYER_STATUS_TOKEN().mint("Stunned", gameID, 1000);
        ti.PLAYER_STATUS_TOKEN().mint("Burned", gameID, 1000);

        // Duplicate tokens, deprecating these
        /*
        ti.ARTIFACT_TOKEN().mint("Engraved Tablet", gameID, 1000);
        ti.ARTIFACT_TOKEN().mint("Sigil Gem", gameID, 1000);
        ti.ARTIFACT_TOKEN().mint("Ancient Tome", gameID, 1000);
        */
        ti.RELIC_TOKEN().mint("Relic 1", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 2", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 3", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 4", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 5", gameID, 1000);

        // Transfer day token to board
        ti.DAY_NIGHT_TOKEN().transfer(
            "Day",
            gameID,
            0,
            GAME_BOARD_WALLET_ID,
            1
        );

        for (uint256 i = 0; i < totalRegistrations; i++) {
            uint256 playerID = i + 1;
            // Transfer campsite tokens to players
            ti.ITEM_TOKEN().transfer("Campsite", gameID, 0, playerID, 1);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./PlayZone.sol";
import "./GameBoard.sol";

contract GameController is AccessControlEnumerable {
    constructor(address adminAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    function exitToPath(
        uint256 pathIndex,
        uint256 gameID,
        address gameBoardAddress
    ) public {
        // called directly by player
        GameBoard(gameBoardAddress).exitToPath(gameID, msg.sender, pathIndex);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "../GameBoard.sol";
import "../libraries/XYCoords.sol";

contract HexGrid is GameBoard {
    uint256 public gridWidth;
    uint256 public gridHeight;
    address public zoneAddress;

    string[] public zoneAliases;

    constructor(
        address adminAddress,
        uint256 _gridWidth,
        uint256 _gridHeight,
        address _zoneAddress
    ) GameBoard(adminAddress) {
        gridWidth = _gridWidth;
        gridHeight = _gridHeight;
        zoneAddress = _zoneAddress;
    }

    function createGrid() public virtual onlyFactoryGM {
        if (zoneAliases.length == 0) {
            address[] memory addresses = new address[](gridWidth * gridHeight);

            zoneAliases = XYCoordinates.coordinates(gridHeight, gridWidth);

            for (uint256 i = 0; i < addresses.length; i++) {
                addresses[i] = zoneAddress;
            }
            // game ID 0 will be prototype for rest of games
            _addZones(addresses, zoneAliases, 0);
        }
    }

    function getZoneAliases() public view returns (string[] memory) {
        return zoneAliases;
    }

    function getInputs(uint256 gameID, string memory _zoneAlias)
        public
        view
        override
        returns (string[] memory zoneInputs)
    {
        string[] memory gameInputs = playZoneInputs[gameID][_zoneAlias];
        string[] memory defaultInputs = playZoneInputs[0][_zoneAlias];
        if (gameInputs.length > 0) {
            string[] memory aliases = new string[](
                gameInputs.length + defaultInputs.length
            );
            for (uint256 i = 0; i < aliases.length; i++) {
                if (i < defaultInputs.length) {
                    aliases[i] = defaultInputs[i];
                } else {
                    aliases[i] = gameInputs[i - defaultInputs.length];
                }
                zoneInputs = aliases;
            }
        } else {
            zoneInputs = defaultInputs;
        }
    }

    function getOutputs(uint256 gameID, string memory _zoneAlias)
        public
        view
        override
        returns (string[] memory zoneOutputs)
    {
        string[] memory gameOutputs = playZoneOutputs[gameID][_zoneAlias];
        string[] memory defaultOutputs = playZoneOutputs[0][_zoneAlias];
        if (gameOutputs.length > 0) {
            string[] memory aliases = new string[](
                gameOutputs.length + defaultOutputs.length
            );
            for (uint256 i = 0; i < aliases.length; i++) {
                if (i < defaultOutputs.length) {
                    aliases[i] = defaultOutputs[i];
                } else {
                    aliases[i] = gameOutputs[i - defaultOutputs.length];
                }
                zoneOutputs = aliases;
            }
        } else {
            zoneOutputs = defaultOutputs;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./Ruleset.sol";
import "./GameBoard.sol";
import "./GameRegistry.sol";

contract PlayZone is AccessControlEnumerable {
    bytes32 public constant GAME_BOARD_ROLE = keccak256("GAME_BOARD_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    Ruleset internal RULESET;
    address public gameRegistryAddress;
    address public rulesetAddress;
    uint256 public rulesetVersion;

    // Mappings from GameID => alias (set in gameboard)
    mapping(uint256 => mapping(string => uint256)) public ruleset; // returns ruleset ID
    mapping(uint256 => mapping(string => uint256)) public entryCount;
    mapping(uint256 => mapping(string => uint256)) public playerCount;
    mapping(uint256 => mapping(string => uint256)) public exitCount;
    mapping(uint256 => mapping(string => mapping(address => bool)))
        internal playerInZone;

    // right now players can interact with zone,
    // zone cannot perform action on all players
    // as no list of players is stored here
    // May be able to query game board for list of players if necessary

    // integrated custom game contract may have this capability, but
    // zone itself can only check if player is allowed to play and
    // ensure total number of players is correct

    // game board may attempt to exit player
    // zone logic will determine if this is allowed

    modifier onlyFactoryAdmin() {
        require(
            hasRole(FACTORY_ROLE, _msgSender()) ||
                hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Game Master or Factory role required"
        );
        _;
    }

    constructor(
        address _rulesetAddress,
        address _gameRegistryAddress,
        address adminAddress,
        address factoryAddress
    ) {
        RULESET = Ruleset(_rulesetAddress);
        gameRegistryAddress = _gameRegistryAddress;
        rulesetAddress = _rulesetAddress;
        rulesetVersion = RULESET.version();
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        if (factoryAddress != address(0)) {
            _setupRole(FACTORY_ROLE, factoryAddress);
        }
    }

    function addGameBoard(address gameBoardAddress) public onlyFactoryAdmin {
        _setupRole(GAME_BOARD_ROLE, gameBoardAddress);
    }

    function removeGameBoard(address gameBoardAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(GAME_BOARD_ROLE, gameBoardAddress);
    }

    function addController(address controllerAddress) public onlyFactoryAdmin {
        _setupRole(CONTROLLER_ROLE, controllerAddress);
    }

    function removeController(address controllerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _revokeRole(CONTROLLER_ROLE, controllerAddress);
    }

    function setRules(
        uint256 rulesetID,
        uint256 gameID,
        string memory zoneAlias
    ) public onlyFactoryAdmin {
        ruleset[gameID][zoneAlias] = rulesetID;
    }

    // Player functions
    function attemptExit(
        uint256 exitPathIndex,
        uint256 gameID,
        address gameBoardAddress
    ) public {
        GameBoard(gameBoardAddress).exitToPath(
            gameID,
            msg.sender,
            exitPathIndex
        );
    }

    function attemptExitFor(
        address playerAddress,
        uint256 exitPathIndex,
        uint256 gameID,
        string memory zoneAlias,
        address gameBoardAddress
    ) public {
        require(
            playerCanExit(playerAddress, gameID, zoneAlias),
            "player cannot exit zone"
        );
        bool exitSuccess = GameBoard(gameBoardAddress).exitToPath(
            gameID,
            playerAddress,
            exitPathIndex
        );
        require(exitSuccess, "player unable to enter on exit");
    }

    // Validation etc is done on the custom contract in _customAction()
    function performCustomAction(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory uintParams
    ) public {
        _customAction(stringParams, addressParams, uintParams);
    }

    function playersInZone() public view returns (uint256[] memory) {
        // cycle through registry, return list of players in zone
    }

    // TODO: figure this out...
    // function resetZone() public onlyRole(???) {}

    function playerInPlayableState(address playerAddress, uint256 gameID)
        internal
        view
        returns (bool playable)
    {
        address gameBoard = GameRegistry(gameRegistryAddress).gameBoard(gameID);
        if (GameBoard(gameBoard).gameState(gameID) > 1) {
            playable = true;
        } else {
            playable = false;
        }

        // TODO: check for transit group action
    }

    // OVERRIDE HUB FUNCTIONS

    function playerCanEnter(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) public view virtual returns (bool canEnter) {
        canEnter = true;
        //canEnter = playerInPlayableState(playerAddress, gameID);
        if (playerInZone[gameID][zoneAlias][playerAddress]) {
            // already here, can't enter again
            canEnter = false;
        } else {
            uint256 rulesetID = ruleset[gameID][zoneAlias];
            if (rulesetID != 0) {
                // check against rules if set
                if (
                    RULESET.rules(rulesetID, 0) &&
                    playerCount[gameID][zoneAlias] >=
                    RULESET.maxCapacity(rulesetID)
                ) {
                    canEnter = false;
                } else if (
                    RULESET.rules(rulesetID, 1) &&
                    entryCount[gameID][zoneAlias] >=
                    RULESET.maxEntrySize(rulesetID)
                ) {
                    canEnter = false;
                }
            }
        }
        //TODO: make sure payout on exit / entry can be paid before allowing entry
    }

    function playerCanExit(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) public view virtual returns (bool canExit) {
        canExit = true;
        //canExit = playerInPlayableState(playerAddress, gameID);

        if (!playerInZone[gameID][zoneAlias][playerAddress]) {
            // not here, can't exit if already gone
            canExit = false;
        } else {
            uint256 rulesetID = ruleset[gameID][zoneAlias];
            if (rulesetID != 0) {
                if (
                    RULESET.rules(rulesetID, 2) &&
                    exitCount[gameID][zoneAlias] >=
                    RULESET.maxExitSize(rulesetID)
                ) {
                    canExit = false;
                }
            }
        }
    }

    function enterPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) external onlyRole(GAME_BOARD_ROLE) {
        require(
            playerCanEnter(playerAddress, gameID, zoneAlias),
            "player cannot enter zone"
        );
        _enterPlayer(playerAddress, gameID, zoneAlias);
    }

    function exitPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) external onlyRole(GAME_BOARD_ROLE) {
        require(
            playerCanExit(playerAddress, gameID, zoneAlias),
            "player cannot exit zone"
        );
        _exitPlayer(playerAddress, gameID, zoneAlias);
    }

    // used when a player is entirely removed from game, e.g. runs out of credits
    function removePlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) external onlyRole(GAME_BOARD_ROLE) {
        _removePlayer(playerAddress, gameID, zoneAlias);
    }

    function _enterPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal {
        _playerWillEnter(playerAddress, gameID, zoneAlias);
        //TODO:
        // payout on entry if set and balance allows
        playerInZone[gameID][zoneAlias][playerAddress] = true;
        playerCount[gameID][zoneAlias]++;
        entryCount[gameID][zoneAlias]++;
        // tell game board to update player position
        address gbAddress = GameRegistry(gameRegistryAddress).gameBoard(gameID);
        GameBoard(gbAddress).playerEnteredZone(
            gameID,
            playerAddress,
            zoneAlias
        );
        _playerDidEnter(playerAddress, gameID, zoneAlias);
    }

    function _exitPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal {
        _playerWillExit(playerAddress, gameID, zoneAlias);
        playerInZone[gameID][zoneAlias][playerAddress] = false;
        playerCount[gameID][zoneAlias] = playerCount[gameID][zoneAlias] > 0
            ? playerCount[gameID][zoneAlias] - 1
            : 0;
        exitCount[gameID][zoneAlias]++;
        //TODO:
        // payout on exit if set and balance allows
        _playerDidExit(playerAddress, gameID, zoneAlias);
    }

    function _removePlayer(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal {
        // TODO: remove from current location on game board
        _playerWillBeRemoved(playerAddress, gameID, zoneAlias);
        playerCount[gameID][zoneAlias] = playerCount[gameID][zoneAlias] > 0
            ? playerCount[gameID][zoneAlias] - 1
            : 0;
        _playerWasRemoved(playerAddress, gameID, zoneAlias);
    }

    // Override for custom game
    function _playerWillEnter(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _playerDidEnter(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _playerWillExit(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _playerDidExit(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _playersWillEnter(
        uint256 gameID,
        uint256 groupID,
        string memory zoneAlias
    ) internal virtual {
        // called when batch of players are being entered from lobby or previous zone
        // individual player entries are called from _playerDidEnter
    }

    function _allPlayersEntered(
        uint256 gameID,
        uint256 groupID,
        string memory zoneAlias
    ) internal virtual {
        // called after player group has all been entered
    }

    function _playerWillBeRemoved(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _playerWasRemoved(
        address playerAddress,
        uint256 gameID,
        string memory zoneAlias
    ) internal virtual {}

    function _customAction(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory uintParams
    ) internal virtual {
        // should definitiely do some checks when implementing this function
        // make sure the sender is correct and nothing malicious is going on
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Ruleset is AccessControlEnumerable {
    using Counters for Counters.Counter;
    bytes32 public constant GAME_MASTER_ROLE = keccak256("GAME_MASTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");

    Counters.Counter internal _rulsetIdTracker;

    uint256 public version = 1;

    // Mapping from Ruleset ID
    mapping(uint256 => bool[]) public rules;
    mapping(uint256 => bool) public locked;
    mapping(uint256 => address) public payoutToken; // if not set will default to native token
    mapping(uint256 => uint256) public maxCapacity;
    mapping(uint256 => uint256) public maxEntrySize;
    mapping(uint256 => uint256) public maxExitSize;
    mapping(uint256 => uint256) public entryPayoutAmount;
    mapping(uint256 => uint256) public exitPayoutAmount;

    uint256 constant RULE_VALUES = 5;

    modifier onlyFactoryGM() {
        require(
            hasRole(FACTORY_ROLE, _msgSender()) ||
                hasRole(GAME_MASTER_ROLE, _msgSender()),
            "Game Master or Factory role required"
        );
        _;
    }

    constructor(address adminAddress, address factoryAddress) {
        // Admin set as game master
        // Can revoke role if desired
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(GAME_MASTER_ROLE, adminAddress);
        if (factoryAddress != address(0)) {
            _setupRole(FACTORY_ROLE, factoryAddress);
        }
        _rulsetIdTracker.increment(); // Start Rulset IDs @ 1

        // TODO: create ruleset @ 0 default rules, used when none is set
    }

    // Rules
    /*
    0 = use max capacity
    1 = use max entry size
    2 = use max exit size
    3 = payout on entry
    4 = payout on exit
    */

    function createRulesetFromFactory(
        bool[] memory ruleFlags,
        address tokenAddress,
        uint256[] memory ruleValues,
        bool lockAfterSet
    ) external onlyRole(FACTORY_ROLE) returns (uint256 rulesetID) {
        rulesetID = _rulsetIdTracker.current();
        setAllRules(ruleValues, rulesetID);
        payoutToken[rulesetID] = tokenAddress;
        locked[rulesetID] = lockAfterSet;
        createRuleset(ruleFlags);
    }

    function createRuleset(bool[] memory ruleFlags) public onlyFactoryGM {
        rules[_rulsetIdTracker.current()] = ruleFlags;
        _rulsetIdTracker.increment();
    }

    function getAllRules(uint256 rulesetID)
        public
        view
        returns (bool[] memory)
    {
        return rules[rulesetID];
    }

    function setAllRules(uint256[] memory ruleValues, uint256 rulesetID)
        public
        onlyFactoryGM
    {
        require(ruleValues.length == RULE_VALUES, "invalid number of rules");
        //[maxCapacity, maxEntrySize, maxExitSize, entryPayoutAmount, exitPayoutAmount]
        maxCapacity[rulesetID] = ruleValues[0];
        maxEntrySize[rulesetID] = ruleValues[1];
        maxExitSize[rulesetID] = ruleValues[2];
        entryPayoutAmount[rulesetID] = ruleValues[3];
        exitPayoutAmount[rulesetID] = ruleValues[4];
    }

    function setPayoutToken(address tokenAddress, uint256 rulesetID)
        public
        onlyFactoryGM
    {
        require(!locked[rulesetID], "rules locked");
        payoutToken[rulesetID] = tokenAddress;
    }

    // This will permanently lock this ruleset
    function lockRules(uint256 rulesetID) public onlyFactoryGM {
        locked[rulesetID] = true;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// universal registry, for all games across boards

contract GameRegistry is AccessControlEnumerable {
    using Counters for Counters.Counter;
    Counters.Counter internal _gameIdTracker;
    bytes32 public constant GAME_BOARD_ROLE = keccak256("GAME_BOARD_ROLE");
    // mapping from game board address to all game IDs
    mapping(address => uint256[]) public gameIDs;
    // mappings from Game ID
    mapping(uint256 => address) public gameBoard;

    constructor(address adminAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _gameIdTracker.increment();
    }

    function addGameBoard(address gameBoardAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(GAME_BOARD_ROLE, gameBoardAddress);
    }

    function registerGame()
        external
        onlyRole(GAME_BOARD_ROLE)
        returns (uint256 gameID)
    {
        gameID = _gameIdTracker.current();
        gameBoard[gameID] = _msgSender();
        gameIDs[_msgSender()].push(gameID);

        _gameIdTracker.increment();
    }

    function allGames()
        external
        view
        onlyRole(GAME_BOARD_ROLE)
        returns (uint256[] memory)
    {
        return gameIDs[_msgSender()];
    }

    function latestGame(address gameBoardAddress)
        public
        view
        returns (uint256 gameID)
    {
        gameID = 0;
        uint256 l = gameIDs[gameBoardAddress].length;
        if (l > 0) {
            uint256[] memory ids = gameIDs[gameBoardAddress];
            gameID = ids[l - 1];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PlayerRegistry.sol";
import "./GameRegistry.sol";
import "./PlayZone.sol";

contract GameBoard is AccessControlEnumerable {
    using Counters for Counters.Counter;
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");
    bytes32 public constant GAME_MASTER_ROLE = keccak256("GAME_MASTER_ROLE");
    bytes32 public constant FACTORY_ROLE = keccak256("FACTORY_ROLE");
    bytes32 public constant PLAY_ZONE_ROLE = keccak256("PLAY_ZONE_ROLE");
    PlayerRegistry internal PLAYER_REGISTRY;

    uint256 public constant MAX_BATCH_SIZE = 200;

    uint256[] internal _gamesNeedUpdates;

    // Mappings from GameID
    mapping(uint256 => uint256) public gameState; // 0 = start, 1=continue initializing, 2=initialized
    mapping(uint256 => uint256) public lastEntryPlayerID;
    // Play zones + connections
    // playZones[gameID] = array of play zone addresses
    // TODO:
    // make sure these aliases work instead of addresses
    mapping(uint256 => string[]) public playZones;
    mapping(uint256 => string) public initialPlayZone;
    mapping(uint256 => mapping(string => address)) public zoneAlias; // returns address of zone alias
    // playZoneInputs[gameID][zone alias] = array of inputs for given zone
    mapping(uint256 => mapping(string => string[])) public playZoneInputs;
    // playZoneOutputs[gameID][zone alias] = array of outputs for given zone
    mapping(uint256 => mapping(string => string[])) public playZoneOutputs;

    // Player Registry
    // playerRegistry[gameID] = player registry ID for game
    mapping(uint256 => uint256) public playerRegistry;

    // Player positions
    // currentPlayZone[gameID][playerID] = alias of zone (playZones[gameID]) player is in
    mapping(uint256 => mapping(uint256 => string)) public currentPlayZone;
    mapping(uint256 => uint256[]) public entryQueue; //overflow if playzone 0 cannot be entered

    modifier onlyFactoryGM() {
        require(
            hasRole(FACTORY_ROLE, _msgSender()) ||
                hasRole(GAME_MASTER_ROLE, _msgSender()),
            "Game Master or Factory role required"
        );
        _;
    }

    constructor(address adminAddress) {
        // Admin set as game master
        // Can revoke role if desired
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(GAME_MASTER_ROLE, adminAddress);
    }

    function prAddress() public view returns (address) {
        return address(PLAYER_REGISTRY);
    }

    function createGame(
        address _playerRegistry,
        address _gameRegistry,
        address[] memory playZoneAddresses,
        string[] memory zoneAliases
    ) public onlyFactoryGM returns (uint256 gameID) {
        require(
            playZoneAddresses.length == zoneAliases.length,
            "addresses & aliases different lengths"
        );
        // first play zone is default / entry point
        if (playZoneAddresses.length > 0) {
            _addZones(playZoneAddresses, zoneAliases, gameID);
        }
        PLAYER_REGISTRY = PlayerRegistry(_playerRegistry);
        gameID = GameRegistry(_gameRegistry).registerGame();
    }

    function createGame(address _playerRegistry, address _gameRegistry)
        public
        onlyFactoryGM
        returns (uint256 gameID)
    {
        PLAYER_REGISTRY = PlayerRegistry(_playerRegistry);
        gameID = GameRegistry(_gameRegistry).registerGame();
    }

    function addFactory(address factoryAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setupRole(FACTORY_ROLE, factoryAddress);
    }

    function isFactory(address factoryAddress)
        public
        view
        returns (bool factoryIsAuthorized)
    {
        factoryIsAuthorized = hasRole(FACTORY_ROLE, factoryAddress);
    }

    // adds zones to be used in game, only add 1 per address, use aliases for zone variations
    function addZones(
        address[] memory playZoneAddresses,
        string[] memory zoneAliases,
        uint256 gameID
    ) public onlyRole(GAME_MASTER_ROLE) {
        require(
            playZoneAddresses.length == zoneAliases.length,
            "addresses & aliases different lengths"
        );
        _addZones(playZoneAddresses, zoneAliases, gameID);
    }

    function _addZones(
        address[] memory playZoneAddresses,
        string[] memory zoneAliases,
        uint256 gameID
    ) internal {
        for (uint256 i = 0; i < playZoneAddresses.length; i++) {
            playZones[gameID].push(zoneAliases[i]);
            zoneAlias[gameID][zoneAliases[i]] = playZoneAddresses[i];
            if (!hasRole(PLAY_ZONE_ROLE, playZoneAddresses[i])) {
                _setupRole(PLAY_ZONE_ROLE, playZoneAddresses[i]);
            }
        }
    }

    function addKeeper(address keeperAddress)
        public
        onlyRole(GAME_MASTER_ROLE)
    {
        _setupRole(VERIFIED_CONTROLLER_ROLE, keeperAddress);
    }

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    function setInitialPlayZone(string memory initialZone, uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        require(
            gameState[gameID] == 0,
            "can't set initial zone, game already started"
        );
        initialPlayZone[gameID] = initialZone;
    }

    function startGame(uint256 gameID) public onlyRole(GAME_MASTER_ROLE) {
        // lock registration
        //_startGameInit(gameID);
        // set needs loop
        _gamesNeedUpdates.push(gameID);
    }

    function setPlayerInactive(uint256 _playerID, uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        PLAYER_REGISTRY.setPlayerInactive(_playerID, gameID);
    }

    function setPlayerActive(uint256 _playerID, uint256 gameID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        PLAYER_REGISTRY.setPlayerActive(_playerID, gameID);
    }

    function needsUpdate() public view returns (bool doesNeedUpdate) {
        doesNeedUpdate = false;
        for (uint256 i = 0; i < _gamesNeedUpdates.length; i++) {
            if (_gamesNeedUpdates[i] != 0) {
                doesNeedUpdate = true;
                break;
            }
        }
    }

    function runUpdate() public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        uint256 gameToUpdate;
        uint256 gameIndex;
        for (uint256 i = 0; i < _gamesNeedUpdates.length; i++) {
            if (_gamesNeedUpdates[i] != 0) {
                gameToUpdate = _gamesNeedUpdates[i];
                gameIndex = i;
                break;
            }
        }
        // get state of game
        if (gameState[gameToUpdate] == 0) {
            _startGameInit(gameToUpdate);
        } else if (gameState[gameToUpdate] == 1) {
            _continueGameInit(gameToUpdate);
        }
        // state might be updated now
        if (gameState[gameToUpdate] > 1) {
            _gamesNeedUpdates[gameIndex] = 0;
        }
        // otherwise everything is set and should be okay...
        // TODO:
        // check transit groups once those are enabled
    }

    function cleanQueue() public {
        // remove 0s from queue
    }

    // game state // 0 start game, 1 continue init, 2 initialized
    function _startGameInit(uint256 gameID) internal {
        PLAYER_REGISTRY.lockRegistration(gameID);
        gameState[gameID] = 1;
    }

    function _continueGameInit(uint256 gameID) internal {
        string memory za = bytes(initialPlayZone[gameID]).length != 0
            ? initialPlayZone[gameID]
            : playZones[gameID][0];
        address zoneAddress = zoneAlias[gameID][za];
        PlayZone pz = PlayZone(zoneAddress);

        for (
            uint256 i = 0;
            i < PLAYER_REGISTRY.totalRegistrations(gameID);
            i++
        ) {
            uint256 playerID = i + 1;
            address playerAddress = PLAYER_REGISTRY.playerAddress(
                gameID,
                playerID
            );
            if (pz.playerCanEnter(playerAddress, gameID, za)) {
                pz.enterPlayer(playerAddress, gameID, za);
            } else {
                entryQueue[gameID].push(playerID);
            }
        }

        gameState[gameID] = 2;
    }

    function getOverflowQueue(uint256 gameID)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        return entryQueue[gameID];
    }

    function getPlayZones(uint256 gameID)
        public
        view
        virtual
        returns (string[] memory)
    {
        return playZones[gameID];
    }

    function getInputs(uint256 gameID, string memory _zoneAlias)
        public
        view
        virtual
        returns (string[] memory zoneInputs)
    {
        zoneInputs = playZoneInputs[gameID][_zoneAlias];
    }

    function getOutputs(uint256 gameID, string memory _zoneAlias)
        public
        view
        virtual
        returns (string[] memory zoneOutputs)
    {
        zoneOutputs = playZoneOutputs[gameID][_zoneAlias];
    }

    function addZoneConnections(uint256 gameID, string[2][] memory connections)
        public
        onlyRole(GAME_MASTER_ROLE)
    {
        // connections = [from zone alias, to zone alias]
        require(
            connectionZonesValid(gameID, connections),
            "not all zone indeces valid"
        );
        for (uint256 i = 0; i < connections.length; i++) {
            playZoneOutputs[gameID][connections[i][0]].push(connections[i][1]);
            playZoneInputs[gameID][connections[i][1]].push(connections[i][0]);
        }
    }

    function removeZoneConnections(
        uint256 gameID,
        string[] memory inputAliases,
        uint256[] memory inputs,
        string[] memory outputAliases,
        uint256[] memory outputs
    ) public onlyRole(GAME_MASTER_ROLE) {
        /* This is done differently from adding zones and can break connections

        Use with caution!

        inputs = [zone index, input index]
        outputs = [zone index, output index]
        */
        require(
            inputs.length == outputs.length,
            "inputs / outputs length mismatch"
        );
        require(
            connectionInputsValid(gameID, inputAliases, inputs),
            "inputs invalid"
        );
        require(
            connectionOutputsValid(gameID, outputAliases, outputs),
            "outputs invalid"
        );
        for (uint256 i = 0; i < inputs.length; i++) {
            //TODO:
            // remove input from zone inputs[i][0] at index inputs[i][1]
            // remove output from zone outputs[i][0] at index outputs[i][1]
        }
    }

    function exitToPath(
        uint256 gameID,
        address playerAddress,
        uint256 pathIndex
    ) external virtual returns (bool exitSuccess) {
        // TODO: make sure zone calling is same as zone player is trying to exit
        uint256 playerID = PLAYER_REGISTRY.playerID(gameID, playerAddress);
        string memory originZoneAlias = currentPlayZone[gameID][playerID];
        string[] memory outputs = getOutputs(gameID, originZoneAlias);
        uint256 availablePaths = outputs.length;
        require(availablePaths > 0, "No exit paths available");

        exitSuccess = false;

        PlayZone originPlayZone = PlayZone(zoneAlias[gameID][originZoneAlias]);

        uint256 path = pathIndex > availablePaths ? 0 : pathIndex;
        string memory destinationZoneAlias = outputs[path];
        PlayZone destinationPlayZone = PlayZone(
            zoneAlias[gameID][destinationZoneAlias]
        );

        if (
            originPlayZone.playerCanExit(
                playerAddress,
                gameID,
                originZoneAlias
            ) &&
            destinationPlayZone.playerCanEnter(
                playerAddress,
                gameID,
                destinationZoneAlias
            )
        ) {
            originPlayZone.exitPlayer(playerAddress, gameID, originZoneAlias);
            destinationPlayZone.enterPlayer(
                playerAddress,
                gameID,
                destinationZoneAlias
            );
            currentPlayZone[gameID][playerID] = destinationZoneAlias;
            exitSuccess = true;
        }
    }

    function playerEnteredZone(
        uint256 gameID,
        address playerAddress,
        string memory _zoneAlias
    ) external onlyRole(PLAY_ZONE_ROLE) {
        uint256 playerID = PLAYER_REGISTRY.playerID(gameID, playerAddress);
        currentPlayZone[gameID][playerID] = _zoneAlias;
    }

    // TODO: implement mass transit
    // can set as many of these up as needed for mass transit
    function queueExitToPaths(
        uint256 gameID,
        address[] memory playerAddresses,
        uint256[] memory pathIndices,
        uint256 transitID
    ) public onlyRole(PLAY_ZONE_ROLE) {}

    function startTransit(uint256 transitID) public onlyRole(PLAY_ZONE_ROLE) {}

    function _progressTransit(uint256 transitID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        // moves group transit along, marks as complete at finish
    }

    function connectionZonesValid(
        uint256 gameID,
        string[2][] memory connections
    ) internal view returns (bool isValid) {
        // checks that all aliases passed exist
        for (uint256 i = 0; i < connections.length; i++) {
            isValid = true;
            if (
                zoneAlias[gameID][connections[i][0]] == address(0) ||
                zoneAlias[gameID][connections[i][1]] == address(0)
            ) {
                isValid = false;
                break;
            }
        }
    }

    function connectionInputsValid(
        uint256 gameID,
        string[] memory aliases,
        uint256[] memory inputs
    ) internal view returns (bool isValid) {
        // checks that inputs exist
        // inputs = [zone alias, input index]

        isValid = true;
        for (uint256 i = 0; i < inputs.length; i++) {
            if (
                //playZoneInputs[gameID][zone alias] = array of input aliases for given zone
                playZoneInputs[gameID][aliases[i]].length >= inputs[i] + 1
            ) {
                isValid = false;
                break;
            }
        }
    }

    function connectionOutputsValid(
        uint256 gameID,
        string[] memory aliases,
        uint256[] memory outputs
    ) internal view returns (bool isValid) {
        // outputs = [zone alias, output index]
        isValid = true;
        for (uint256 i = 0; i < outputs.length; i++) {
            if (playZoneOutputs[gameID][aliases[i]].length >= outputs[i] + 1) {
                isValid = false;
                break;
            }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./GameBoard.sol";

// Registry is tied to one game board
// each registry can have custom rules for registration

contract PlayerRegistry is AccessControlEnumerable {
    bytes32 public constant GAME_BOARD_ROLE = keccak256("GAME_BOARD_ROLE");

    GameBoard internal GAME_BOARD;

    // Mappings from gameID
    //  or [game ID][player address]
    mapping(uint256 => uint256) public totalRegistrations;
    mapping(uint256 => uint256) public registrationLimit;
    mapping(uint256 => bool) public registrationLocked;
    mapping(uint256 => mapping(address => bool)) public isRegistered;
    mapping(uint256 => mapping(address => uint256)) public playerID;

    // Mappings from gameID => playerID
    mapping(uint256 => mapping(uint256 => address)) public playerAddress;
    mapping(uint256 => mapping(uint256 => bool)) public isActive;

    constructor(address gameBoardAddress, address adminAddress) {
        GAME_BOARD = GameBoard(gameBoardAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        _setupRole(GAME_BOARD_ROLE, gameBoardAddress);
    }

    function canRegister(address _playerAddress, uint256 gameID)
        public
        view
        returns (bool)
    {
        return _canRegister(_playerAddress, gameID);
    }

    function register(uint256 gameID) public {
        require(
            _canRegister(msg.sender, gameID),
            "Player not qualified to register"
        );
        _register(gameID, msg.sender);
    }

    function registerPlayer(address _playerAddress, uint256 gameID)
        public
        onlyRole(GAME_BOARD_ROLE)
    {
        require(
            _canRegister(_playerAddress, gameID),
            "Player not qualified to register"
        );
        _register(gameID, _playerAddress);
    }

    function setRegistrationLimit(uint256 limit, uint256 gameID)
        public
        onlyRole(GAME_BOARD_ROLE)
    {
        registrationLimit[gameID] = limit;
    }

    function setPlayerInactive(uint256 _playerID, uint256 gameID)
        external
        onlyRole(GAME_BOARD_ROLE)
    {
        isActive[gameID][_playerID] = false;
    }

    function setPlayerActive(uint256 _playerID, uint256 gameID)
        external
        onlyRole(GAME_BOARD_ROLE)
    {
        isActive[gameID][_playerID] = true;
    }

    function playerAddressesInRange(
        uint256 startingID,
        uint256 maxID,
        uint256 gameID
    ) public view returns (address[] memory) {
        require(
            startingID <= totalRegistrations[gameID],
            "starting ID out of bounds"
        );
        require(maxID >= startingID, "maxID < startingID");
        // require starting ID exists
        uint256 actualMaxID = maxID;
        uint256 size = actualMaxID - startingID + 1;
        address[] memory players = new address[](size);
        for (uint256 i = startingID; i < startingID + size; i++) {
            uint256 index = startingID - i;
            players[index] = playerAddress[gameID][i];
        }
        return players;
    }

    // function registerPlayers(address[] memory playerAddresses, uint256 gameID)
    //     public
    //     onlyRole(REGISTRAR_ROLE)
    // {
    //     require(
    //         _canRegister(playerAddress, gameID),
    //         "Player not qualified to register"
    //     );
    //     isRegistered[gameID][playerAddress] = true;
    // }

    function lockRegistration(uint256 gameID)
        external
        onlyRole(GAME_BOARD_ROLE)
    {
        registrationLocked[gameID] = true;
    }

    function _register(uint256 gameID, address player) internal {
        if (!isRegistered[gameID][player]) {
            isRegistered[gameID][player] = true;
            uint256 newID = totalRegistrations[gameID] + 1; // IDs start @ 1
            totalRegistrations[gameID] = newID;
            playerID[gameID][player] = newID;
            playerAddress[gameID][newID] = player;
            isActive[gameID][newID] = true;
        }
    }

    // override for custom registration behavior
    function _canRegister(address _playerAddress, uint256 gameID)
        internal
        view
        virtual
        returns (bool playerCanRegister)
    {
        playerCanRegister = (_playerAddress == address(0) ||
            registrationLocked[gameID])
            ? false
            : (registrationLimit[gameID] == 0 ||
                registrationLimit[gameID] > totalRegistrations[gameID])
            ? true
            : false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

library XYCoordinates {
    function coordinates(uint256 numRows, uint256 numColumns)
        public
        pure
        returns (string[] memory)
    {
        string[] memory allCoords = new string[](numRows * numColumns);
        string[51] memory nums = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31",
            "32",
            "33",
            "34",
            "35",
            "36",
            "37",
            "38",
            "39",
            "40",
            "41",
            "42",
            "43",
            "44",
            "45",
            "46",
            "47",
            "48",
            "49",
            "50"
        ];
        uint256 curIndex = 0;
        for (uint256 i = 0; i < numColumns; i++) {
            for (uint256 j = 0; j < numRows; j++) {
                allCoords[curIndex] = string(
                    abi.encodePacked(nums[i], ",", nums[j])
                );
                curIndex++;
            }
        }
        return allCoords;
    }
}

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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract CardDeck is AccessControlEnumerable {
    // This is an infinite deck, cards drawn are not removed from deck
    // We can set card "quantities" for desireable probability

    // controller role should be set to a controller contract
    // not used by default, provided if going to make custom deck with limited access
    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");

    string[] private _cards;

    // mappings from card name
    // should all store same size array of values, even if empty
    mapping(string => string) public description;
    mapping(string => uint16) public quantity;
    mapping(string => int8[3]) public movementAdjust;
    mapping(string => int8[3]) public agilityAdjust;
    mapping(string => int8[3]) public dexterityAdjust;
    mapping(string => string[3]) public itemGain;
    mapping(string => string[3]) public itemLoss;
    mapping(string => string[3]) public handLoss; // ["Left", "Right", ""];
    mapping(string => int256[3]) public movementX;
    mapping(string => int256[3]) public movementY;
    mapping(string => uint256[3]) public rollThresholds; // [0, 3, 4] what to roll to receive matching index of mapping
    mapping(string => string[3]) public outcomeDescription;
    mapping(string => uint256) public rollTypeRequired; // 0 = movement, 1 = agility, 2 = dexterity

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // this function does not provide randomness,
    // passing the same random word will yield the same draw.
    // randomness should come from controller

    // pass along movement, agility, dexterity rolls - will use whatever is appropriate
    function drawCard(uint256 randomWord, uint256[3] memory rollValues)
        public
        view
        virtual
        returns (
            string memory _card,
            int8 _movementAdjust,
            int8 _agilityAdjust,
            int8 _dexterityAdjust,
            string memory _itemLoss,
            string memory _itemGain,
            string memory _handLoss,
            string memory _outcomeDescription
        )
    {
        uint256 cardIndex = randomWord % _cards.length;
        string memory card = _cards[cardIndex];
        // TODO:
        // find index of roll ()
        uint256 rollIndex = 0;
        uint256 rollType = rollTypeRequired[card];
        uint256 rollValue = rollValues[rollType];
        uint256[3] memory thresholds = rollThresholds[card];
        for (uint256 i = thresholds.length - 1; i >= 0; i--) {
            if (rollValue >= thresholds[i]) {
                rollIndex = i;
                break;
            }
            if (i == 0) {
                break;
            }
        }
        // match index with all attributes
        // return (
        //     card,
        //     movementAdjust[card][rollIndex],
        //     agilityAdjust[card][rollIndex],
        //     dexterityAdjust[card][rollIndex],
        //     itemLoss[card][rollIndex],
        //     itemGain[card][rollIndex],
        //     handLoss[card][rollIndex],
        //     outcomeDescription[card][rollIndex]
        // );
        _card = card;
        _movementAdjust = movementAdjust[card][rollIndex];
        _agilityAdjust = agilityAdjust[card][rollIndex];
        _dexterityAdjust = dexterityAdjust[card][rollIndex];
        _itemLoss = itemLoss[card][rollIndex];
        _itemGain = itemGain[card][rollIndex];
        _handLoss = handLoss[card][rollIndex];
        _outcomeDescription = outcomeDescription[card][rollIndex];
    }

    function getDeck() public view returns (string[] memory) {
        return _cards;
    }

    // Admin Functions
    function addCards(
        string[] memory titles,
        string[] memory descriptions,
        uint16[] memory quantities
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            titles.length == descriptions.length &&
                titles.length == quantities.length,
            "array quantity mismatch"
        );
        for (uint256 i = 0; i < titles.length; i++) {
            // only add if not already added and set quantity is not 0
            string memory title = titles[i];
            if (quantity[title] == 0 && quantities[i] != 0) {
                _cards.push(title);
                description[title] = descriptions[i];
                quantity[title] = quantities[i];
            }
        }
    }

    function addCardsWithItemGains(
        string[] memory titles,
        string[] memory descriptions,
        uint16[] memory quantities,
        string[3][] memory itemGains,
        string[3][] memory itemLosses,
        string[3][] memory outcomeDescriptions
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            titles.length == descriptions.length &&
                titles.length == quantities.length,
            "array quantity mismatch"
        );
        for (uint256 i = 0; i < titles.length; i++) {
            // only add if not already added and set quantity is not 0
            string memory title = titles[i];
            if (quantity[title] == 0 && quantities[i] != 0) {
                _cards.push(title);
                description[title] = descriptions[i];
                quantity[title] = quantities[i];
                itemGain[title] = itemGains[i];
                itemLoss[title] = itemLosses[i];
                outcomeDescription[title] = outcomeDescriptions[i];
            }
        }
    }

    function addCardsWithStatAdjustments(
        string[] memory titles,
        string[] memory descriptions,
        uint16[] memory quantities,
        uint256[3][] memory rollThresholdValues,
        string[3][] memory outcomeDescriptions,
        int8[3][] memory movementAdjustments,
        int8[3][] memory agilityAdjustments,
        int8[3][] memory dexterityAdjustments,
        uint256[] memory rollTypesRequired
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            titles.length == descriptions.length &&
                titles.length == quantities.length,
            "array quantity mismatch"
        );
        for (uint256 i = 0; i < titles.length; i++) {
            // only add if not already added and set quantity is not 0
            string memory title = titles[i];
            if (quantity[title] == 0 && quantities[i] != 0) {
                _cards.push(title);
                description[title] = descriptions[i];
                quantity[title] = quantities[i];
                rollThresholds[title] = rollThresholdValues[i];
                outcomeDescription[title] = outcomeDescriptions[i];
                movementAdjust[title] = movementAdjustments[i];
                agilityAdjust[title] = agilityAdjustments[i];
                dexterityAdjust[title] = dexterityAdjustments[i];
                rollTypeRequired[title] = rollTypesRequired[i];
            }
        }
    }

    function setDescription(string memory _description, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        description[_cardName] = _description;
    }

    function setQuantity(uint16 _quantity, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        quantity[_cardName] = _quantity;
    }

    function setMovementAdjust(
        int8[3] memory _movementAdjust,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        movementAdjust[_cardName] = _movementAdjust;
    }

    function setAgilityAdjust(
        int8[3] memory _agilityAdjust,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        agilityAdjust[_cardName] = _agilityAdjust;
    }

    function setDexterityAdjust(
        int8[3] memory _dexterityAdjust,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dexterityAdjust[_cardName] = _dexterityAdjust;
    }

    function setItemGain(string[3] memory _itemGain, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        itemGain[_cardName] = _itemGain;
    }

    function setItemLoss(string[3] memory _itemLoss, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        itemLoss[_cardName] = _itemLoss;
    }

    function setHandLoss(string[3] memory _handLoss, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        //["Left","Left","Right"];
        // or ["", "", "Right"];
        handLoss[_cardName] = _handLoss;
    }

    function setMovementX(int256[3] memory _movementX, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        movementX[_cardName] = _movementX;
    }

    function setMovementY(int256[3] memory _movementY, string memory _cardName)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        movementY[_cardName] = _movementY;
    }

    function setRollThresholds(
        uint256[3] memory _rollThresholds,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rollThresholds[_cardName] = _rollThresholds;
    }

    function setOutcomeDescription(
        string[3] memory _outcomeDescription,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        outcomeDescription[_cardName] = _outcomeDescription;
    }

    function setRollTypeRequired(
        uint256 _rollTypeRequired,
        string memory _cardName
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        rollTypeRequired[_cardName] = _rollTypeRequired;
    }

    function changeCardTitle(
        string memory originalTitle,
        string memory newTitle
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        int8[3] memory resetInt8x3 = [int8(0), int8(0), int8(0)];
        int256[3] memory resetInt256x3 = [int256(0), int256(0), int256(0)];

        description[newTitle] = description[originalTitle];
        description[originalTitle] = "";

        quantity[newTitle] = quantity[originalTitle];
        quantity[originalTitle] = 0;

        movementAdjust[newTitle] = movementAdjust[originalTitle];
        movementAdjust[originalTitle] = resetInt8x3;

        agilityAdjust[newTitle] = agilityAdjust[originalTitle];
        agilityAdjust[originalTitle] = resetInt8x3;

        dexterityAdjust[newTitle] = dexterityAdjust[originalTitle];
        dexterityAdjust[originalTitle] = resetInt8x3;

        itemGain[newTitle] = itemGain[originalTitle];
        itemGain[originalTitle] = ["", "", ""];

        itemLoss[newTitle] = itemLoss[originalTitle];
        itemLoss[originalTitle] = ["", "", ""];

        handLoss[newTitle] = handLoss[originalTitle];
        handLoss[originalTitle] = ["", "", ""];

        movementX[newTitle] = movementX[originalTitle];
        movementX[originalTitle] = resetInt256x3;

        movementY[newTitle] = movementY[originalTitle];
        movementY[originalTitle] = resetInt256x3;

        rollThresholds[newTitle] = rollThresholds[originalTitle];
        rollThresholds[originalTitle] = [0, 0, 0];

        outcomeDescription[newTitle] = outcomeDescription[originalTitle];
        outcomeDescription[originalTitle] = ["", "", ""];

        rollTypeRequired[newTitle] = rollTypeRequired[originalTitle];
        rollTypeRequired[originalTitle] = 0;
    }

    /*
    mapping(string => uint256[3]) public rollThresholds; // [0, 3, 4] what to roll to receive matching index of mapping
    mapping(string => string[3]) public outcomeDescription;
    mapping(string => uint256) public rollTypeRequired;
    */
    function getDescription(string memory cardTitle)
        public
        view
        returns (string memory)
    {
        return description[cardTitle];
    }

    function getQuantity(string memory cardTitle) public view returns (uint16) {
        return quantity[cardTitle];
    }

    function getMovementAdjust(string memory cardTitle)
        public
        view
        returns (int8[3] memory)
    {
        return movementAdjust[cardTitle];
    }

    function getAgilityAdjust(string memory cardTitle)
        public
        view
        returns (int8[3] memory)
    {
        return agilityAdjust[cardTitle];
    }

    function getDexterityAdjust(string memory cardTitle)
        public
        view
        returns (int8[3] memory)
    {
        return dexterityAdjust[cardTitle];
    }

    function getItemGain(string memory cardTitle)
        public
        view
        returns (string[3] memory)
    {
        return itemGain[cardTitle];
    }

    function getItemLoss(string memory cardTitle)
        public
        view
        returns (string[3] memory)
    {
        return itemLoss[cardTitle];
    }

    function getHandLoss(string memory cardTitle)
        public
        view
        returns (string[3] memory)
    {
        return handLoss[cardTitle];
    }

    function getMovementX(string memory cardTitle)
        public
        view
        returns (int256[3] memory)
    {
        return movementX[cardTitle];
    }

    function getMovementY(string memory cardTitle)
        public
        view
        returns (int256[3] memory)
    {
        return movementY[cardTitle];
    }

    function getRollThresholds(string memory cardTitle)
        public
        view
        returns (uint256[3] memory)
    {
        return rollThresholds[cardTitle];
    }

    function getOutcomeDescription(string memory cardTitle)
        public
        view
        returns (string[3] memory)
    {
        return outcomeDescription[cardTitle];
    }

    function getRollTypeRequired(string memory cardTitle)
        public
        view
        returns (uint256)
    {
        return rollTypeRequired[cardTitle];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

abstract contract RandomIndices {
    enum RandomIndex {
        P1DigPassFail,
        P1DigCardDraw,
        P1DigCardOutcome,
        P2DigPassFail,
        P2DigCardDraw,
        P2DigCardOutcome,
        P3DigPassFail,
        P3DigCardDraw,
        P3DigCardOutcome,
        P4DigPassFail,
        P4DigCardDraw,
        P4DigCardOutcome,
        TieDispute,
        P1DayEventType,
        P1DayEventCardDraw,
        P1DayEventRoll,
        P2DayEventType,
        P2DayEventCardDraw,
        P2DayEventRoll,
        P3DayEventType,
        P3DayEventCardDraw,
        P3DayEventRoll,
        P4DayEventType,
        P4DayEventCardDraw,
        P4DayEventRoll,
        P1TileReveal1,
        P1TileReveal2,
        P1TileReveal3,
        P1TileReveal4,
        P2TileReveal1,
        P2TileReveal2,
        P2TileReveal3,
        P2TileReveal4,
        P3TileReveal1,
        P3TileReveal2,
        P3TileReveal3,
        P3TileReveal4,
        P4TileReveal1,
        P4TileReveal2,
        P4TileReveal3,
        P4TileReveal4
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./HexplorationQueue.sol";
import "./HexplorationStateUpdate.sol";
// import "./state/GameSummary.sol";
import "./HexplorationBoard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./RollDraw.sol";
import "./HexplorationGameplayUpdates.sol";
import "./GameWallets.sol";

contract HexplorationGameplay is
    AccessControlEnumerable,
    KeeperCompatibleInterface,
    GameWallets
{
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");

    HexplorationQueue QUEUE;
    HexplorationStateUpdate GAME_STATE;
    HexplorationBoard GAME_BOARD;
    RollDraw ROLL_DRAW;
    uint256 constant LEFT_HAND = 0;
    uint256 constant RIGHT_HAND = 1;

    // Mapping from QueueID to updates needed to run
    //mapping(uint256 => bool) public readyForKeeper;
    mapping(uint256 => bool) public updatesComplete;

    struct DataSummary {
        uint256 playerPositionUpdates;
        uint256 playerEquips;
        uint256 zoneTransfers;
        uint256 activeActions;
        uint256 playerTransfers;
        uint256 playerStatUpdates;
    }

    struct PlayUpdates {
        uint256[] playerPositionIDs;
        uint256[] spacesToMove;
        uint256[] playerEquipIDs;
        uint256[] playerEquipHands; // 0:left, 1:right
        uint256[] playerHandLossIDs;
        uint256[] playerHandLosses; // 0:left, 1:right
        uint256[] zoneTransfersTo;
        uint256[] zoneTransfersFrom;
        uint256[] zoneTransferQtys;
        uint256[] playerTransfersTo;
        uint256[] playerTransfersFrom;
        uint256[] playerTransferQtys;
        uint256[] playerStatUpdateIDs;
        int8[3][] playerStatUpdates; // amount to adjust, not final value
        uint256[] playerActiveActionIDs;
        string gamePhase;
        string[7][] playerMovementOptions; // TODO: set this to max # of spaces possible
        string[] playerEquips;
        string[] zoneTransferItemTypes;
        string[] playerTransferItemTypes;
        string[] activeActions;
        string[][] activeActionOptions;
        uint256[] activeActionResults; // 0 = None, 1 = Event, 2 = Ambush, 3 = Treasure
        string[2][] activeActionResultCard; // Card for Event / ambush / treasure , outcome e.g. ["Dance with locals", "You're amazing!"]
        string[3][] activeActionInventoryChanges; // [item loss, item gain, hand loss]
        uint256[41] randomness;
        bool setupEndgame;
    }

    constructor(address gameBoardAddress, address _rollDrawAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        GAME_BOARD = HexplorationBoard(gameBoardAddress);
        ROLL_DRAW = RollDraw(_rollDrawAddress);
    }

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    function setQueue(address queueContract)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QUEUE = HexplorationQueue(queueContract);
        _setupRole(VERIFIED_CONTROLLER_ROLE, queueContract);
    }

    function setGameStateUpdate(address gsuAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_STATE = HexplorationStateUpdate(gsuAddress);
    }

    // Keeper functions
    function getSummaryForUpkeep(bytes calldata performData)
        external
        pure
        returns (
            DataSummary memory summary,
            uint256 queueID,
            uint256 processingPhase
        )
    {
        (
            queueID,
            processingPhase,
            summary.playerPositionUpdates,
            summary.playerStatUpdates,
            summary.playerEquips,
            summary.zoneTransfers,
            summary.playerTransfers,
            summary.activeActions
        ) = abi.decode(
            performData,
            (
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256
            )
        );
    }

    function performUpkeep(bytes calldata performData) external override {
        DataSummary memory summary;
        uint256 queueID;
        uint256 processingPhase;
        (
            queueID,
            processingPhase,
            summary.playerPositionUpdates,
            summary.playerStatUpdates,
            summary.playerEquips,
            summary.zoneTransfers,
            summary.playerTransfers,
            summary.activeActions
        ) = abi.decode(
            performData,
            (
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256,
                uint256
            )
        );
        require(QUEUE.randomness(queueID, 12) != 0, "Randomness not delivered");
        for (uint256 i = 0; i < QUEUE.getAllPlayers(queueID).length; i++) {
            uint256 playerID = i + 1;
            ROLL_DRAW.setRandomnessForPlayer(
                playerID,
                queueID,
                QUEUE.isDayPhase(queueID)
            );
        }
        if (processingPhase == 2) {
            processPlayerActions(queueID, summary);
        } else if (processingPhase == 3) {
            processPlayThrough(queueID, summary);
        }
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // check for list of queues that need updates...
        upkeepNeeded = false;
        uint256 queueIDToUpdate = 0;
        uint256[] memory pq = QUEUE.getProcessingQueue();
        for (uint256 i = 0; i < pq.length; i++) {
            if (pq[i] != 0) {
                queueIDToUpdate = pq[i];
                upkeepNeeded = true;
                break;
            }
        }
        // Checks for randomness returned.
        // randomness[12] will have randomness delivered every turn
        if (QUEUE.randomness(queueIDToUpdate, 12) == 0) {
            upkeepNeeded = false;
        }

        HexplorationQueue.ProcessingPhase phase = QUEUE.currentPhase(
            queueIDToUpdate
        );
        // 2 = processing, 3 = play through, 4 = processed
        if (phase == HexplorationQueue.ProcessingPhase.Processing) {
            performData = getUpdateInfo(queueIDToUpdate, 2);
        } else if (phase == HexplorationQueue.ProcessingPhase.PlayThrough) {
            performData = getUpdateInfo(queueIDToUpdate, 3);
        } else {
            performData = getUpdateInfo(queueIDToUpdate, 4);
        }
    }

    function getUpdateInfo(uint256 queueID, uint256 processingPhase)
        internal
        view
        returns (bytes memory)
    {
        DataSummary memory data = DataSummary(0, 0, 0, 0, 0, 0);
        uint256[] memory playersInQueue = QUEUE.getAllPlayers(queueID);
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            uint256 playerID = playersInQueue[i];
            HexplorationQueue.Action action = QUEUE.submissionAction(
                queueID,
                playerID
            );
            if (action == HexplorationQueue.Action.Move) {
                data.playerPositionUpdates += 1;
            }
            if (bytes(QUEUE.submissionLeftHand(queueID, playerID)).length > 0) {
                data.playerEquips += 1;
            }
            if (
                bytes(QUEUE.submissionRightHand(queueID, playerID)).length > 0
            ) {
                data.playerEquips += 1;
            }
            if (
                action == HexplorationQueue.Action.SetupCamp ||
                action == HexplorationQueue.Action.BreakDownCamp
            ) {
                data.zoneTransfers += 1;
            }

            if (action == HexplorationQueue.Action.Dig) {
                data.playerTransfers += 1;
            }

            if (
                action == HexplorationQueue.Action.Dig ||
                action == HexplorationQueue.Action.Rest ||
                action == HexplorationQueue.Action.Help ||
                action == HexplorationQueue.Action.SetupCamp ||
                action == HexplorationQueue.Action.BreakDownCamp ||
                action == HexplorationQueue.Action.Move
            ) {
                data.activeActions += 1;
            }

            if (
                action == HexplorationQueue.Action.Dig ||
                action == HexplorationQueue.Action.Rest
            ) {
                data.playerStatUpdates += 1;
            }
        }
        return (
            abi.encode(
                queueID,
                processingPhase,
                data.playerPositionUpdates,
                data.playerStatUpdates,
                data.playerEquips,
                data.zoneTransfers,
                data.playerTransfers,
                data.activeActions
            )
        );
    }

    function processPlayerActions(uint256 queueID, DataSummary memory summary)
        internal
    {
        uint256 gameID = QUEUE.game(queueID);
        // TODO: save update struct with all the actions from queue (what was originally the ints array)
        PlayUpdates memory playUpdates = HexplorationGameplayUpdates
            .playUpdatesForPlayerActionPhase(
                address(QUEUE),
                queueID,
                address(ROLL_DRAW),
                summary
            );
        string[4] memory playerZones = [
            GAME_BOARD.currentPlayZone(gameID, 1),
            GAME_BOARD.currentPlayZone(gameID, 2),
            GAME_BOARD.currentPlayZone(gameID, 3),
            GAME_BOARD.currentPlayZone(gameID, 4)
        ];

        playUpdates = resolveCampSetupDisputes(
            playUpdates,
            gameID,
            playerZones
        );
        playUpdates = resolveCampBreakDownDisputes(
            playUpdates,
            gameID,
            playerZones
        );
        playUpdates = resolveDigDisputes(playUpdates, gameID, playerZones);
        GAME_STATE.postUpdates(playUpdates, gameID);
        QUEUE.setPhase(HexplorationQueue.ProcessingPhase.PlayThrough, queueID);
    }

    function processPlayThrough(uint256 queueID, DataSummary memory summary)
        internal
    {
        HexplorationQueue.ProcessingPhase phase = QUEUE.currentPhase(queueID);

        if (QUEUE.randomness(queueID, 12) != 0) {
            if (phase == HexplorationQueue.ProcessingPhase.PlayThrough) {
                uint256 gameID = QUEUE.game(queueID);
                PlayUpdates memory playUpdates = HexplorationGameplayUpdates
                    .playUpdatesForPlayThroughPhase(
                        address(QUEUE),
                        queueID,
                        address(GAME_BOARD),
                        address(ROLL_DRAW)
                    );
                if (stringsMatch(playUpdates.gamePhase, "Day")) {
                    PlayUpdates
                        memory dayPhaseUpdates = HexplorationGameplayUpdates
                            .dayPhaseUpdatesForPlayThroughPhase(
                                address(QUEUE),
                                queueID,
                                gameID,
                                address(GAME_BOARD),
                                address(ROLL_DRAW)
                            );
                    GAME_STATE.postUpdates(
                        playUpdates,
                        dayPhaseUpdates,
                        gameID
                    );
                } else {
                    GAME_STATE.postUpdates(playUpdates, gameID);
                }

                // PlayUpdates
                //     memory dayPhaseUpdates = dayPhaseUpdatesForPlayThroughPhase(
                //         queueID,
                //         summary
                //     );
                // TODO: set this to true when game is finished
                bool gameComplete = false;
                QUEUE.finishProcessing(queueID, gameComplete);
            }
        }
    }

    // Internal

    // Pass play zones in order P1, P2, P3, P4
    function resolveCampSetupDisputes(
        PlayUpdates memory playUpdates,
        uint256 gameID,
        string[4] memory currentPlayZones
    ) internal view returns (PlayUpdates memory) {
        uint256 randomness = QUEUE.randomness(
            QUEUE.queueID(gameID),
            uint256(RandomIndices.RandomIndex.TieDispute)
        );
        // campsite disputes hardcoded for max 2 disputes
        // with 4 players, no more than 2 disputes will ever occur (1-3 or 2-2 splits)
        string[2] memory campsiteSetupDisputes; //[map space, map space]
        uint256[2] memory campsiteSetups; // number of setups at each of the dispute zones
        for (uint256 i = 0; i < playUpdates.zoneTransfersTo.length; i++) {
            // If to == current zone, from = playerID
            // if from == current zone, to = playerID
            if (
                playUpdates.zoneTransfersTo[i] == 10000000000 &&
                stringsMatch(playUpdates.zoneTransferItemTypes[i], "Campsite")
            ) {
                // Sets up to 2 zones for potential disputes
                if (bytes(campsiteSetupDisputes[0]).length == 0) {
                    campsiteSetupDisputes[0] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.zoneTransfersFrom[i]
                    );
                } else if (
                    bytes(campsiteSetupDisputes[1]).length == 0 &&
                    !stringsMatch(
                        currentPlayZones[playUpdates.zoneTransfersFrom[i] - 1],
                        campsiteSetupDisputes[0]
                    )
                ) {
                    campsiteSetupDisputes[1] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.zoneTransfersFrom[i]
                    );
                }
                uint256 currentIndex = stringsMatch(
                    campsiteSetupDisputes[0],
                    currentPlayZones[playUpdates.zoneTransfersFrom[i] - 1]
                )
                    ? 0
                    : 1;
                campsiteSetups[currentIndex]++;
                //campsiteSetupPlayers[i] = playUpdates.zoneTransfersFrom[i];
            }
        }

        uint256[][2] memory campsiteSetupPlayers;
        campsiteSetupPlayers[0] = new uint256[](campsiteSetups[0]);
        campsiteSetupPlayers[1] = new uint256[](campsiteSetups[1]);
        uint256[][2] memory campsiteSetupIndices;
        campsiteSetupIndices[0] = new uint256[](campsiteSetups[0]);
        campsiteSetupIndices[1] = new uint256[](campsiteSetups[1]);
        uint256[2] memory positions;

        if (campsiteSetups[0] > 1 || campsiteSetups[1] > 1) {
            for (uint256 i = 0; i < playUpdates.zoneTransfersTo.length; i++) {
                if (
                    playUpdates.zoneTransfersTo[i] == 10000000000 &&
                    stringsMatch(
                        playUpdates.zoneTransferItemTypes[i],
                        "Campsite"
                    )
                ) {
                    // Player transferring campsite to zone (setting up camp)
                    uint256 currentIndex = stringsMatch(
                        campsiteSetupDisputes[0],
                        currentPlayZones[playUpdates.zoneTransfersFrom[i] - 1]
                    )
                        ? 0
                        : 1;
                    campsiteSetupPlayers[currentIndex][
                        positions[currentIndex]
                    ] = playUpdates.zoneTransfersFrom[i];
                    campsiteSetupIndices[currentIndex][
                        positions[currentIndex]
                    ] = i;
                    positions[currentIndex]++;
                }
            }

            // pick winner
            uint256[2] memory campsiteSetupDisputeWinners;
            campsiteSetupDisputeWinners[0] = campsiteSetupPlayers[0].length > 0
                ? campsiteSetupPlayers[0][
                    randomness % campsiteSetupPlayers[0].length
                ]
                : 0;
            // campsiteSetupDisputeWinners[0] = campsiteSetupPlayers[0][0]; // p1
            // campsiteSetupDisputeWinners[0] = campsiteSetupPlayers[0][1]; // p3
            // campsiteSetupDisputeWinners[0] = campsiteSetupPlayers[0][2]; // p4
            campsiteSetupDisputeWinners[1] = campsiteSetupPlayers[1].length > 0
                ? campsiteSetupPlayers[1][
                    randomness % campsiteSetupPlayers[1].length
                ]
                : 0;
            for (uint256 i = 0; i < campsiteSetupPlayers[0].length; i++) {
                if (
                    campsiteSetupPlayers[0][i] != campsiteSetupDisputeWinners[0]
                ) {
                    // disable transfer for non-winner
                    playUpdates.zoneTransfersTo[campsiteSetupIndices[0][i]] = 0;
                    playUpdates.zoneTransfersFrom[
                        campsiteSetupIndices[0][i]
                    ] = 0;
                    playUpdates.zoneTransferQtys[
                        campsiteSetupIndices[0][i]
                    ] = 0;
                }
            }
            for (uint256 i = 0; i < campsiteSetupPlayers[1].length; i++) {
                if (
                    campsiteSetupPlayers[1][i] != campsiteSetupDisputeWinners[1]
                ) {
                    // disable transfer for non-winner
                    playUpdates.zoneTransfersTo[campsiteSetupIndices[1][i]] = 0;
                    playUpdates.zoneTransfersFrom[
                        campsiteSetupIndices[1][i]
                    ] = 0;
                    playUpdates.zoneTransferQtys[
                        campsiteSetupIndices[1][i]
                    ] = 0;
                }
            }
        }

        return playUpdates;
    }

    function resolveCampBreakDownDisputes(
        PlayUpdates memory playUpdates,
        uint256 gameID,
        string[4] memory currentPlayZones
    ) internal view returns (PlayUpdates memory) {
        uint256 randomness = QUEUE.randomness(
            QUEUE.queueID(gameID),
            uint256(RandomIndices.RandomIndex.TieDispute)
        );
        // campsite disputes hardcoded for max 2 disputes
        // with 4 players, no more than 2 disputes will ever occur (1-3 or 2-2 splits)
        string[2] memory campsiteBreakDownDisputes; //[zone, zone]
        uint256[2] memory campsiteBreakDowns;
        for (uint256 i = 0; i < playUpdates.zoneTransfersFrom.length; i++) {
            // If to == current zone, from = playerID
            // if from == current zone, to = playerID
            if (
                playUpdates.zoneTransfersFrom[i] == 10000000000 &&
                stringsMatch(playUpdates.zoneTransferItemTypes[i], "Campsite")
            ) {
                // Sets up to 2 zones for potential disputes
                if (bytes(campsiteBreakDownDisputes[0]).length == 0) {
                    campsiteBreakDownDisputes[0] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.zoneTransfersTo[i]
                    );
                } else if (
                    bytes(campsiteBreakDownDisputes[1]).length == 0 &&
                    !stringsMatch(
                        currentPlayZones[playUpdates.zoneTransfersTo[i] - 1],
                        campsiteBreakDownDisputes[0]
                    )
                ) {
                    campsiteBreakDownDisputes[1] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.zoneTransfersTo[i]
                    );
                }
                uint256 currentIndex = stringsMatch(
                    campsiteBreakDownDisputes[0],
                    currentPlayZones[playUpdates.zoneTransfersTo[i] - 1]
                )
                    ? 0
                    : 1;
                campsiteBreakDowns[currentIndex]++;
                //campsiteSetupPlayers[i] = playUpdates.zoneTransfersTo[i];
            }
        }

        uint256[][2] memory campsiteBreakDownPlayers;
        campsiteBreakDownPlayers[0] = new uint256[](campsiteBreakDowns[0]);
        campsiteBreakDownPlayers[1] = new uint256[](campsiteBreakDowns[1]);
        uint256[][2] memory campsiteBreakDownIndices;
        campsiteBreakDownIndices[0] = new uint256[](campsiteBreakDowns[0]);
        campsiteBreakDownIndices[1] = new uint256[](campsiteBreakDowns[1]);
        uint256[2] memory positions;

        if (campsiteBreakDowns[0] > 1 || campsiteBreakDowns[1] > 1) {
            for (uint256 i = 0; i < playUpdates.zoneTransfersFrom.length; i++) {
                if (
                    playUpdates.zoneTransfersFrom[i] == 10000000000 &&
                    stringsMatch(
                        playUpdates.zoneTransferItemTypes[i],
                        "Campsite"
                    )
                ) {
                    // Player transferring campsite to zone (setting up camp)
                    uint256 currentIndex = stringsMatch(
                        campsiteBreakDownDisputes[0],
                        currentPlayZones[playUpdates.zoneTransfersTo[i] - 1]
                    )
                        ? 0
                        : 1;
                    campsiteBreakDownPlayers[currentIndex][
                        positions[currentIndex]
                    ] = playUpdates.zoneTransfersTo[i];
                    campsiteBreakDownIndices[currentIndex][
                        positions[currentIndex]
                    ] = i;
                    positions[currentIndex]++;
                }
            }

            // pick winner
            uint256[2] memory campsiteBreakDownDisputeWinners;
            campsiteBreakDownDisputeWinners[0] = campsiteBreakDownPlayers[0]
                .length > 0
                ? campsiteBreakDownPlayers[0][
                    randomness % campsiteBreakDownPlayers[0].length
                ]
                : 0;
            campsiteBreakDownDisputeWinners[1] = campsiteBreakDownPlayers[1]
                .length > 0
                ? campsiteBreakDownPlayers[1][
                    randomness % campsiteBreakDownPlayers[1].length
                ]
                : 0;
            for (uint256 i = 0; i < campsiteBreakDownPlayers[0].length; i++) {
                if (
                    campsiteBreakDownPlayers[0][i] !=
                    campsiteBreakDownDisputeWinners[0]
                ) {
                    // disable transfer for non-winner
                    playUpdates.zoneTransfersTo[
                        campsiteBreakDownIndices[0][i]
                    ] = 0;
                    playUpdates.zoneTransfersFrom[
                        campsiteBreakDownIndices[0][i]
                    ] = 0;
                    playUpdates.zoneTransferQtys[
                        campsiteBreakDownIndices[0][i]
                    ] = 0;
                }
            }
            for (uint256 i = 0; i < campsiteBreakDownPlayers[1].length; i++) {
                if (
                    campsiteBreakDownPlayers[1][i] !=
                    campsiteBreakDownDisputeWinners[1]
                ) {
                    // disable transfer for non-winner
                    playUpdates.zoneTransfersTo[
                        campsiteBreakDownIndices[1][i]
                    ] = 0;
                    playUpdates.zoneTransfersFrom[
                        campsiteBreakDownIndices[1][i]
                    ] = 0;
                    playUpdates.zoneTransferQtys[
                        campsiteBreakDownIndices[1][i]
                    ] = 0;
                }
            }
        }

        return playUpdates;
    }

    function resolveDigDisputes(
        PlayUpdates memory playUpdates,
        uint256 gameID,
        string[4] memory currentPlayZones
    ) internal view returns (PlayUpdates memory) {
        uint256 randomness = QUEUE.randomness(
            QUEUE.queueID(gameID),
            uint256(RandomIndices.RandomIndex.TieDispute)
        );
        // campsite disputes hardcoded for max 2 disputes
        // with 4 players, no more than 2 disputes will ever occur (1-3 or 2-2 splits)
        string[2] memory digDisputes; //[map space, map space]
        uint256[2] memory digs; // number of digs at each of the dispute zones

        //        playUpdates.playerTransfersTo[position] = playersInQueue[i];
        //        playUpdates.playerTransfersFrom[position] = 0;
        for (uint256 i = 0; i < playUpdates.playerTransfersTo.length; i++) {
            if (
                playUpdates.playerTransfersTo[i] != 0 &&
                itemIsArtifact(playUpdates.playerTransferItemTypes[i])
            ) {
                // player has dug an artifact
                // Sets up to 2 zones for potential disputes
                if (bytes(digDisputes[0]).length == 0) {
                    digDisputes[0] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.playerTransfersTo[i]
                    );
                } else if (
                    bytes(digDisputes[1]).length == 0 &&
                    !stringsMatch(
                        currentPlayZones[playUpdates.playerTransfersTo[i] - 1],
                        digDisputes[0]
                    )
                ) {
                    digDisputes[1] = GAME_BOARD.currentPlayZone(
                        gameID,
                        playUpdates.playerTransfersTo[i]
                    );
                }
                uint256 currentIndex = stringsMatch(
                    digDisputes[0],
                    currentPlayZones[playUpdates.playerTransfersTo[i] - 1]
                )
                    ? 0
                    : 1;
                digs[currentIndex]++;
                //campsiteSetupPlayers[i] = playUpdates.zoneTransfersFrom[i];
            }
        }

        uint256[][2] memory digPlayers;
        digPlayers[0] = new uint256[](digs[0]);
        digPlayers[1] = new uint256[](digs[1]);
        uint256[][2] memory digIndices;
        digIndices[0] = new uint256[](digs[0]);
        digIndices[1] = new uint256[](digs[1]);
        uint256[2] memory positions;

        if (digs[0] > 1 || digs[1] > 1) {
            for (uint256 i = 0; i < playUpdates.playerTransfersTo.length; i++) {
                if (
                    playUpdates.playerTransfersTo[i] != 0 &&
                    itemIsArtifact(playUpdates.playerTransferItemTypes[i])
                ) {
                    // Player receiving artifact from dig
                    uint256 currentIndex = stringsMatch(
                        digDisputes[0],
                        currentPlayZones[playUpdates.playerTransfersTo[i] - 1]
                    )
                        ? 0
                        : 1;
                    digPlayers[currentIndex][
                        positions[currentIndex]
                    ] = playUpdates.playerTransfersTo[i];
                    digIndices[currentIndex][positions[currentIndex]] = i;
                    positions[currentIndex]++;
                }
            }

            // pick winner
            uint256[2] memory digDisputeWinners;
            digDisputeWinners[0] = digPlayers[0].length > 0
                ? digPlayers[0][randomness % digPlayers[0].length]
                : 0;
            digDisputeWinners[1] = digPlayers[1].length > 0
                ? digPlayers[1][randomness % digPlayers[1].length]
                : 0;
            for (uint256 i = 0; i < digPlayers[0].length; i++) {
                if (digPlayers[0][i] != digDisputeWinners[0]) {
                    // disable transfer for non-winner
                    playUpdates.playerTransfersTo[digIndices[0][i]] = 0;
                    playUpdates.playerTransfersFrom[digIndices[0][i]] = 0;
                    playUpdates.playerTransferQtys[digIndices[0][i]] = 0;
                }
            }
            for (uint256 i = 0; i < digPlayers[1].length; i++) {
                if (digPlayers[1][i] != digDisputeWinners[1]) {
                    // disable transfer for non-winner
                    playUpdates.playerTransfersTo[digIndices[1][i]] = 0;
                    playUpdates.playerTransfersFrom[digIndices[1][i]] = 0;
                    playUpdates.playerTransferQtys[digIndices[1][i]] = 0;
                }
            }
        }

        return playUpdates;
    }

    function _setupEndGame(uint256 gameID) internal {
        // TODO:
        // setup end game...
    }

    // Utilities
    function stringsMatch(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }

    function itemIsArtifact(string memory itemType)
        internal
        pure
        returns (bool)
    {
        return (stringsMatch(itemType, "Engraved Tablet") ||
            stringsMatch(itemType, "Sigil Gem") ||
            stringsMatch(itemType, "Ancient Tome"));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./HexplorationQueue.sol";
import "./HexplorationGameplay.sol";
import "./HexplorationBoard.sol";
import "./RollDraw.sol";
import "./TokenInventory.sol";
import "./CharacterCard.sol";
import "./RandomIndices.sol";

library HexplorationGameplayUpdates {
    uint256 public constant GAME_BOARD_WALLET_ID = 1000000;
    uint256 public constant LEFT_HAND = 0;
    uint256 public constant RIGHT_HAND = 1;

    function playUpdatesForPlayerActionPhase(
        address queueAddress,
        uint256 queueID,
        address rollDrawAddress,
        bytes memory summaryData
    ) public view returns (HexplorationGameplay.PlayUpdates memory) {
        HexplorationGameplay.DataSummary memory summary = abi.decode(
            summaryData,
            (HexplorationGameplay.DataSummary)
        );
        return
            playUpdatesForPlayerActionPhase(
                queueAddress,
                queueID,
                rollDrawAddress,
                summary
            );
    }

    function playUpdatesForPlayerActionPhase(
        address queueAddress,
        uint256 queueID,
        address rollDrawAddress,
        HexplorationGameplay.DataSummary memory summary
    ) public view returns (HexplorationGameplay.PlayUpdates memory) {
        HexplorationGameplay.PlayUpdates memory playUpdates;
        uint256[] memory playersInQueue = HexplorationQueue(queueAddress)
            .getAllPlayers(queueID);
        uint256 position;
        // uint256 maxMovementPerPlayer = 7;
        // Movement
        playUpdates.playerPositionIDs = new uint256[](
            summary.playerPositionUpdates
        );
        playUpdates.spacesToMove = new uint256[](summary.playerPositionUpdates);
        playUpdates.playerMovementOptions = new string[7][](
            summary.playerPositionUpdates
        );
        position = 0;
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.Move
            ) {
                // return [player id, # spaces to move]

                playUpdates.playerPositionIDs[position] = playersInQueue[i];
                playUpdates.spacesToMove[position] = HexplorationQueue(
                    queueAddress
                ).getSubmissionOptions(queueID, playersInQueue[i]).length;
                string[] memory options = HexplorationQueue(queueAddress)
                    .getSubmissionOptions(queueID, playersInQueue[i]);
                for (uint256 j = 0; j < 7; j++) {
                    playUpdates.playerMovementOptions[position][j] = j <
                        options.length
                        ? options[j]
                        : "";
                }
                position++;
            }
        }

        // LH equip
        playUpdates.playerEquipIDs = new uint256[](summary.playerEquips);
        playUpdates.playerEquipHands = new uint256[](summary.playerEquips);
        playUpdates.playerEquips = new string[](summary.playerEquips);
        position = 0;
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                bytes(
                    HexplorationQueue(queueAddress).submissionLeftHand(
                        queueID,
                        playersInQueue[i]
                    )
                ).length > 0
            ) {
                // return [player id, r/l hand (0/1)]

                playUpdates.playerEquipIDs[position] = playersInQueue[i];
                playUpdates.playerEquipHands[position] = 0;
                playUpdates.playerEquips[position] = HexplorationQueue(
                    queueAddress
                ).submissionLeftHand(queueID, playersInQueue[i]);
                position++;
            }
        }

        // RH equip
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                bytes(
                    HexplorationQueue(queueAddress).submissionRightHand(
                        queueID,
                        playersInQueue[i]
                    )
                ).length > 0
            ) {
                // return [player id, r/l hand (0/1)]

                playUpdates.playerEquipIDs[position] = playersInQueue[i];
                playUpdates.playerEquipHands[position] = 1;
                playUpdates.playerEquips[position] = HexplorationQueue(
                    queueAddress
                ).submissionRightHand(queueID, playersInQueue[i]);
                position++;
            }
        }

        // Camp actions
        playUpdates.zoneTransfersTo = new uint256[](summary.zoneTransfers);
        playUpdates.zoneTransfersFrom = new uint256[](summary.zoneTransfers);
        playUpdates.zoneTransferQtys = new uint256[](summary.zoneTransfers);
        playUpdates.zoneTransferItemTypes = new string[](summary.zoneTransfers);
        position = 0;
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.SetupCamp
            ) {
                // setup camp
                // transfer from player to zone
                // return [to ID, from ID, quantity]
                // Transfer 1 campsite from player to current zone

                playUpdates.zoneTransfersTo[position] = 10000000000; //10000000000 represents current play zone of player
                playUpdates.zoneTransfersFrom[position] = playersInQueue[i];
                playUpdates.zoneTransferQtys[position] = 1;
                playUpdates.zoneTransferItemTypes[position] = "Campsite";
                position++;
            }
        }

        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.BreakDownCamp
            ) {
                // break down camp
                // transfer from zone to player
                playUpdates.zoneTransfersTo[position] = playersInQueue[i];
                playUpdates.zoneTransfersFrom[position] = 10000000000;
                playUpdates.zoneTransferQtys[position] = 1;
                playUpdates.zoneTransferItemTypes[position] = "Campsite";
                position++;
            }
        }

        playUpdates.playerActiveActionIDs = new uint256[](
            summary.activeActions
        );
        playUpdates.activeActions = new string[](summary.activeActions);
        playUpdates.activeActionOptions = new string[][](summary.activeActions);
        playUpdates.activeActionResults = new uint256[](summary.activeActions);
        playUpdates.activeActionResultCard = new string[2][](
            summary.activeActions
        );
        playUpdates.activeActionInventoryChanges = new string[3][](
            summary.activeActions
        );
        playUpdates.playerHandLossIDs = new uint256[](summary.playerTransfers);
        playUpdates.playerHandLosses = new uint256[](summary.playerTransfers);

        playUpdates.playerStatUpdateIDs = new uint256[](
            summary.playerStatUpdates
        );
        playUpdates.playerStatUpdates = new int8[3][](
            summary.playerStatUpdates
        );
        playUpdates.playerTransfersTo = new uint256[](summary.playerTransfers);
        playUpdates.playerTransfersFrom = new uint256[](
            summary.playerTransfers
        );
        playUpdates.playerTransferQtys = new uint256[](summary.playerTransfers);
        playUpdates.playerTransferItemTypes = new string[](
            summary.playerTransfers
        );

        position = 0;
        // increase with each one added...
        uint256 playerStatPosition = 0;
        // Draw cards for dig this phase
        /*
         else if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.Move
            ) {
                // TODO: use this...
                playUpdates.activeActions[position] = "Move";
                playUpdates.activeActionOptions[position] = QUEUE
                    .getSubmissionOptions(queueID, playersInQueue[i]);
                position++;
            }
        */
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.SetupCamp
            ) {
                playUpdates.activeActions[position] = "Setup camp";
                playUpdates.activeActionOptions[position] = new string[](0);
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                position++;
            } else if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.BreakDownCamp
            ) {
                playUpdates.activeActions[position] = "Break down camp";
                playUpdates.activeActionOptions[position] = new string[](0);
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                position++;
            } else if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.Dig
            ) {
                playUpdates.activeActions[position] = "Dig";
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                playUpdates.activeActionOptions[position] = new string[](0);
                playUpdates.activeActionResults[position] = uint256(
                    dig(
                        queueAddress,
                        queueID,
                        rollDrawAddress,
                        playersInQueue[i]
                    )
                );
                (
                    playUpdates.activeActionResultCard[position][0],
                    playUpdates.playerStatUpdates[position],
                    playUpdates.activeActionInventoryChanges[position][0],
                    playUpdates.activeActionInventoryChanges[position][1],
                    playUpdates.activeActionInventoryChanges[position][2],
                    playUpdates.activeActionResultCard[position][1]
                ) = RollDraw(rollDrawAddress).drawCard(
                    RollDraw.CardType(
                        playUpdates.activeActionResults[position]
                    ),
                    queueID,
                    playersInQueue[i],
                    false,
                    true
                );

                if (
                    bytes(playUpdates.activeActionInventoryChanges[position][0])
                        .length > 0
                ) {
                    // item loss
                    playUpdates.playerTransferItemTypes[position] = playUpdates
                        .activeActionInventoryChanges[position][0];
                    playUpdates.playerTransfersTo[position] = 0;
                    playUpdates.playerTransfersFrom[position] = playersInQueue[
                        i
                    ];
                    playUpdates.playerTransferQtys[position] = 1;
                    // TODO: check if we need this...
                    playUpdates.playerStatUpdateIDs[position] = playersInQueue[
                        i
                    ];
                } else if (
                    bytes(playUpdates.activeActionInventoryChanges[position][1])
                        .length > 0
                ) {
                    // item gain
                    playUpdates.playerTransferItemTypes[position] = playUpdates
                        .activeActionInventoryChanges[position][1];
                    playUpdates.playerTransfersTo[position] = playersInQueue[i];
                    playUpdates.playerTransfersFrom[position] = 0;
                    playUpdates.playerTransferQtys[position] = 1;
                    // TODO: check if we need this...
                    playUpdates.playerStatUpdateIDs[position] = playersInQueue[
                        i
                    ];
                } else if (
                    bytes(playUpdates.activeActionInventoryChanges[position][2])
                        .length > 0
                ) {
                    // hand loss

                    playUpdates.playerHandLossIDs[position] = playersInQueue[i];
                    playUpdates.playerHandLosses[position] = stringsMatch(
                        playUpdates.activeActionInventoryChanges[position][2],
                        "Right"
                    )
                        ? 1
                        : 0;
                }

                playerStatPosition++;
                position++;
            } else if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.Rest
            ) {
                playUpdates.activeActions[position] = "Rest";
                playUpdates.activeActionOptions[position] = HexplorationQueue(
                    queueAddress
                ).getSubmissionOptions(queueID, playersInQueue[i]);
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                playUpdates.playerStatUpdates[playerStatPosition] = rest(
                    queueAddress,
                    queueID,
                    playersInQueue[i]
                );
                playUpdates.playerStatUpdateIDs[
                    playerStatPosition
                ] = playersInQueue[i];
                playerStatPosition++;
                position++;
            } else if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.Help
            ) {
                // TODO: use this...
                playUpdates.activeActions[position] = "Help";
                playUpdates.activeActionOptions[position] = HexplorationQueue(
                    queueAddress
                ).getSubmissionOptions(queueID, playersInQueue[i]);
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                position++;
            } else if (
                HexplorationQueue(queueAddress).submissionAction(
                    queueID,
                    playersInQueue[i]
                ) == HexplorationQueue.Action.Move
            ) {
                playUpdates.activeActions[position] = "Move";
                playUpdates.activeActionOptions[position] = HexplorationQueue(
                    queueAddress
                ).getSubmissionOptions(queueID, playersInQueue[i]);
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                position++;
            }
        }
        playUpdates.randomness = HexplorationQueue(queueAddress).getRandomness(
            queueID
        );

        return playUpdates;
    }

    function playUpdatesForPlayThroughPhase(
        address queueAddress,
        uint256 queueID,
        address gameBoardAddress,
        address rollDrawAddress
    ) public view returns (HexplorationGameplay.PlayUpdates memory) {
        HexplorationGameplay.PlayUpdates memory playUpdates;

        // uint256[] memory playersInQueue = QUEUE.getAllPlayers(queueID);
        // uint256 position;

        uint256 gameID = HexplorationQueue(queueAddress).game(queueID);
        uint256 totalPlayers = PlayerRegistry(
            HexplorationBoard(gameBoardAddress).prAddress()
        ).totalRegistrations(gameID);

        playUpdates.gamePhase = TokenInventory(
            HexplorationBoard(gameBoardAddress).tokenInventory()
        ).DAY_NIGHT_TOKEN().balance("Day", gameID, GAME_BOARD_WALLET_ID) > 0
            ? "Night"
            : "Day";

        // uint256 totalPlayers = PlayerRegistry(GAME_BOARD.prAddress())
        //     .totalRegistrations(gameID);

        for (uint256 i = 0; i < totalPlayers; i++) {
            uint256 playerID = i + 1;
            // These are already processed... Don't need to reprocess.
            // HexplorationQueue.Action activeAction = HexplorationQueue(
            //     queueAddress
            // ).activeAction(queueID, playerID);
            /*
            if (activeAction == HexplorationQueue.Action.Dig) {
                // dig
                if (
                    dig(queueAddress, queueID, rollDrawAddress, playerID) ==
                    RollDraw.CardType.Treasure
                ) {
                    // TODO:
                    // dug treasure!
                    // pick treasure card
                    // if final artifact is found, playUpdates.setupEndgame = true;
                } else {
                    // TODO:
                    // dug ambush...
                    // play out consequences
                }
            } else if (activeAction == HexplorationQueue.Action.Rest) {
                // rest
                string memory restChoice = HexplorationQueue(queueAddress)
                    .submissionOptions(queueID, playerID, 0);
                if (stringsMatch(restChoice, "Movement")) {
                    // TODO:
                    // add 1 to movement
                } else if (stringsMatch(restChoice, "Agility")) {
                    // TODO:
                    // add 1 to agility
                } else if (stringsMatch(restChoice, "Dexterity")) {
                    // TODO:
                    // add 1 to dexterity
                }
            } else if (activeAction == HexplorationQueue.Action.Help) {
                // help
                // TODO:
                // set player ID to help (options) as string choice
            }
            */

            // to get current player stats...
            //CharacterCard cc = CharacterCard(GAME_BOARD.characterCard());
            // cc.movement(gameID, playerID) => returns uint8
            // cc.agility(gameID, playerID) => returns uint8
            // cc.dexterity(gameID, playerID) => returns uint8

            //to subtract from player stats...
            //subToZero(uint256(playerStat), reductionAmount);
            // can submit numbers higher than max here, but won't actually get set to those
            // will get set to max if max exceeded
        }

        // Day phase events, processed before players can submit choices

        // return (playUpdates, dayPhaseUpdates);
        return playUpdates;
    }

    function dayPhaseUpdatesForPlayThroughPhase(
        address queueAddress,
        uint256 queueID,
        uint256 gameID,
        address gameBoardAddress,
        address rollDrawAddress
    ) public view returns (HexplorationGameplay.PlayUpdates memory) {
        HexplorationGameplay.PlayUpdates memory dayPhaseUpdates;
        uint256 totalPlayers = PlayerRegistry(
            HexplorationBoard(gameBoardAddress).prAddress()
        ).totalRegistrations(gameID);
        // if (
        //     TokenInventory(HexplorationBoard(gameBoardAddress).tokenInventory())
        //         .DAY_NIGHT_TOKEN()
        //         .balance("Day", gameID, GAME_BOARD_WALLET_ID) > 0
        // ) {
        //updates.activeActions
        //updates.playerActiveActionIDs
        dayPhaseUpdates.randomness = HexplorationQueue(queueAddress)
            .getRandomness(queueID);
        dayPhaseUpdates.activeActions = new string[](totalPlayers);
        dayPhaseUpdates.playerActiveActionIDs = new uint256[](totalPlayers);
        for (uint256 i = 0; i < totalPlayers; i++) {
            // every player will have some update for this
            dayPhaseUpdates.playerActiveActionIDs[i] = i + 1;
        }
        dayPhaseUpdates.activeActionResults = new uint256[](totalPlayers);
        dayPhaseUpdates.activeActionResultCard = new string[2][](totalPlayers);
        dayPhaseUpdates.playerStatUpdateIDs = new uint256[](totalPlayers);
        dayPhaseUpdates.playerStatUpdates = new int8[3][](totalPlayers);
        dayPhaseUpdates.activeActionInventoryChanges = new string[3][](
            totalPlayers
        );
        dayPhaseUpdates.playerTransferItemTypes = new string[](totalPlayers);
        dayPhaseUpdates.playerTransfersFrom = new uint256[](totalPlayers);
        dayPhaseUpdates.playerTransfersTo = new uint256[](totalPlayers);
        dayPhaseUpdates.playerTransferQtys = new uint256[](totalPlayers);
        dayPhaseUpdates.playerEquipIDs = new uint256[](totalPlayers);
        dayPhaseUpdates.playerEquipHands = new uint256[](totalPlayers);
        dayPhaseUpdates.playerEquips = new string[](totalPlayers);

        for (uint256 i = 0; i < totalPlayers; i++) {
            uint256 playerID = i + 1;
            if (
                !CharacterCard(
                    HexplorationBoard(gameBoardAddress).characterCard()
                ).playerIsDead(gameID, playerID)
            ) {
                RandomIndices.RandomIndex randomIndex = playerID == 1
                    ? RandomIndices.RandomIndex.P1DayEventType
                    : playerID == 2
                    ? RandomIndices.RandomIndex.P2DayEventType
                    : playerID == 3
                    ? RandomIndices.RandomIndex.P3DayEventType
                    : RandomIndices.RandomIndex.P4DayEventType;
                // roll D6
                if (
                    ((
                        RollDraw(rollDrawAddress).d6Roll(
                            1,
                            queueID,
                            uint256(randomIndex)
                        )
                    ) % 2) == 0
                ) {
                    // even roll
                    // draw event card
                    int8[3] memory stats;
                    // TODO:
                    // set player randomness by here (not in this view function)
                    (
                        dayPhaseUpdates.activeActionResultCard[i][0],
                        stats,
                        dayPhaseUpdates.activeActionInventoryChanges[i][0],
                        dayPhaseUpdates.activeActionInventoryChanges[i][1],
                        dayPhaseUpdates.activeActionInventoryChanges[i][2],
                        dayPhaseUpdates.activeActionResultCard[i][1]
                    ) = RollDraw(rollDrawAddress).drawCard(
                        RollDraw.CardType.Event,
                        queueID,
                        playerID,
                        true,
                        true
                    );
                    dayPhaseUpdates.playerStatUpdates[i] = stats;
                    dayPhaseUpdates.activeActionResults[i] = 1;
                    dayPhaseUpdates.playerStatUpdateIDs[i] = playerID;
                } else {
                    // odd roll
                    // draw ambush card
                    // TODO:
                    // set player randomness by here (not in this view function)
                    int8[3] memory stats;
                    (
                        dayPhaseUpdates.activeActionResultCard[i][0],
                        stats,
                        dayPhaseUpdates.activeActionInventoryChanges[i][0],
                        dayPhaseUpdates.activeActionInventoryChanges[i][1],
                        dayPhaseUpdates.activeActionInventoryChanges[i][2],
                        dayPhaseUpdates.activeActionResultCard[i][1]
                    ) = RollDraw(rollDrawAddress).drawCard(
                        RollDraw.CardType.Ambush,
                        queueID,
                        playerID,
                        true,
                        true
                    );
                    dayPhaseUpdates.playerStatUpdates[i] = stats;
                    dayPhaseUpdates.activeActionResults[i] = 2;
                    dayPhaseUpdates.playerStatUpdateIDs[i] = playerID;
                }

                // string memory loseItemInventory = dayPhaseUpdates
                //     .activeActionInventoryChanges[i][0];
                // string memory handLossInventory = dayPhaseUpdates
                //     .activeActionInventoryChanges[i][2];

                if (
                    !stringsMatch(
                        dayPhaseUpdates.activeActionInventoryChanges[i][0],
                        ""
                    )
                ) {
                    // set item loss

                    // dayPhaseUpdates.playerActiveActionIDs[i] = playerID;
                    dayPhaseUpdates.playerTransferItemTypes[i] = dayPhaseUpdates
                        .activeActionInventoryChanges[i][0];
                    dayPhaseUpdates.playerTransfersTo[i] = 0;
                    dayPhaseUpdates.playerTransfersFrom[i] = playerID;
                    dayPhaseUpdates.playerTransferQtys[i] = 1;
                }

                if (
                    !stringsMatch(
                        dayPhaseUpdates.activeActionInventoryChanges[i][1],
                        ""
                    )
                ) {
                    // Set item gain
                    // dayPhaseUpdates.playerActiveActionIDs[i] = playerID;
                    dayPhaseUpdates.playerTransferItemTypes[i] = dayPhaseUpdates
                        .activeActionInventoryChanges[i][1];
                    dayPhaseUpdates.playerTransfersFrom[i] = 0;
                    dayPhaseUpdates.playerTransfersTo[i] = playerID;
                    dayPhaseUpdates.playerTransferQtys[i] = 1;
                }

                if (
                    !stringsMatch(
                        dayPhaseUpdates.activeActionInventoryChanges[i][2],
                        ""
                    )
                ) {
                    // set hand loss if item is in hand
                    string memory handItem = itemInHand(
                        dayPhaseUpdates.activeActionInventoryChanges[i][2],
                        playerID,
                        gameID,
                        gameBoardAddress
                    );
                    if (
                        !stringsMatch(handItem, "") &&
                        TokenInventory(
                            HexplorationBoard(gameBoardAddress).tokenInventory()
                        ).ITEM_TOKEN().balance(handItem, gameID, playerID) >
                        0
                    ) {
                        // dayPhaseUpdates.playerActiveActionIDs[i] = playerID;
                        dayPhaseUpdates.playerTransferItemTypes[i] = handItem;
                        dayPhaseUpdates.playerTransfersTo[i] = 0;
                        dayPhaseUpdates.playerTransfersFrom[i] = playerID;
                        dayPhaseUpdates.playerTransferQtys[i] = 1;
                        dayPhaseUpdates.playerEquipIDs[i] = playerID;
                        dayPhaseUpdates.playerEquipHands[i] = stringsMatch(
                            dayPhaseUpdates.activeActionInventoryChanges[i][2],
                            "Left"
                        )
                            ? LEFT_HAND
                            : RIGHT_HAND;
                        // no need to set playerEquips, this is already set to empty string, which will remove from hand
                    }
                }
            }
        }
        return dayPhaseUpdates;
    }

    function itemInHand(
        string memory whichHand,
        uint256 playerID,
        uint256 gameID,
        address gameBoardAddress
    ) public view returns (string memory item) {
        item = "";
        if (stringsMatch(whichHand, "Left")) {
            item = CharacterCard(
                HexplorationBoard(gameBoardAddress).characterCard()
            ).leftHandItem(gameID, playerID);
        } else if (stringsMatch(whichHand, "Right")) {
            item = CharacterCard(
                HexplorationBoard(gameBoardAddress).characterCard()
            ).rightHandItem(gameID, playerID);
        }
    }

    function dig(
        address queueAddress,
        uint256 queueID,
        address rollDrawAddress,
        uint256 playerID
    ) internal view returns (RollDraw.CardType resultType) {
        // if digging available... (should be pre-checked)
        // TODO:
        // roll dice (d6) for each player on space not resting

        uint256 playersOnSpace = HexplorationQueue(queueAddress)
            .getSubmissionOptions(queueID, playerID)
            .length - 1;
        string memory phase = HexplorationQueue(queueAddress)
            .getSubmissionOptions(queueID, playerID)[0];
        RandomIndices.RandomIndex randomIndex = playerID == 1
            ? RandomIndices.RandomIndex.P1DigPassFail
            : playerID == 2
            ? RandomIndices.RandomIndex.P2DigPassFail
            : playerID == 3
            ? RandomIndices.RandomIndex.P3DigPassFail
            : RandomIndices.RandomIndex.P4DigPassFail;
        uint256 rollOutcome = RollDraw(rollDrawAddress).d6Roll(
            playersOnSpace,
            queueID,
            uint256(randomIndex)
        );
        uint256 rollRequired = stringsMatch(phase, "Day") ? 4 : 5;
        resultType = rollOutcome < rollRequired
            ? RollDraw.CardType.Ambush
            : RollDraw.CardType.Treasure;

        // if sum of rolls is greater than 5 during night win treasure
        // if sum of rolls is greater than 4 during day win treasure
        // return "Treasure" or "Ambush"
        // Result types: 0 = None, 1 = Event, 2 = Ambush, 3 = Treasure
    }

    function rest(
        address queueAddress,
        uint256 queueID,
        uint256 playerID
    ) internal view returns (int8[3] memory stats) {
        string memory statToRest = HexplorationQueue(queueAddress)
            .getSubmissionOptions(queueID, playerID)[0];
        if (stringsMatch(statToRest, "Movement")) {
            stats[0] = 1;
        } else if (stringsMatch(statToRest, "Agility")) {
            stats[1] = 1;
        } else if (stringsMatch(statToRest, "Dexterity")) {
            stats[2] = 1;
        }
    }

    function stringsMatch(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./CardDeck.sol";
import "./HexplorationQueue.sol";
import "./RandomIndices.sol";

contract RollDraw is AccessControlEnumerable, RandomIndices {
    CardDeck EVENT_DECK;
    CardDeck TREASURE_DECK;
    CardDeck AMBUSH_DECK;
    HexplorationQueue QUEUE;

    enum CardType {
        None,
        Event,
        Ambush,
        Treasure
    }

    // Mapping from queue ID => player ID
    mapping(uint256 => mapping(uint256 => uint256)) _drawRandomness;
    mapping(uint256 => mapping(uint256 => uint256[3])) _playerRolls;
    mapping(uint256 => mapping(uint256 => uint256)) _dayPhaseDrawRandomness;
    mapping(uint256 => mapping(uint256 => uint256[3])) _dayPhaseRolls;

    constructor(
        address eventDeckAddress,
        address treasureDeckAddress,
        address ambushDeckAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        EVENT_DECK = CardDeck(eventDeckAddress);
        TREASURE_DECK = CardDeck(treasureDeckAddress);
        AMBUSH_DECK = CardDeck(ambushDeckAddress);
    }

    function setQueue(address queueAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QUEUE = HexplorationQueue(queueAddress);
    }

    // TODO: set access control for this, this should not be public, it changes the state
    // Set hexploration gameplay to be verified controller
    function setRandomnessForPlayer(
        uint256 playerID,
        uint256 queueID,
        bool dayEvent
    ) public {
        uint256 drawIndex;
        uint256 rollIndex;
        (drawIndex, rollIndex) = randomIndicesForPlayer(playerID, false);
        uint256 dayPhaseDrawIndex;
        uint256 dayPhaseRollIndex;
        if (dayEvent) {
            (dayPhaseDrawIndex, dayPhaseRollIndex) = randomIndicesForPlayer(
                playerID,
                true
            );
            _dayPhaseDrawRandomness[queueID][playerID] = QUEUE.randomness(
                queueID,
                dayPhaseDrawIndex
            );
            _dayPhaseRolls[queueID][playerID] = playerRolls(
                queueID,
                playerID,
                dayPhaseRollIndex
            );
        }

        _drawRandomness[queueID][playerID] = QUEUE.randomness(
            queueID,
            drawIndex
        );

        _playerRolls[queueID][playerID] = playerRolls(
            queueID,
            playerID,
            rollIndex
        );
    }

    // public get functions
    /*
    mapping(uint256 => mapping(uint256 => uint256)) _drawRandomness;
    mapping(uint256 => mapping(uint256 => uint256[3])) _playerRolls;
    mapping(uint256 => mapping(uint256 => uint256)) _dayPhaseDrawRandomness;
    mapping(uint256 => mapping(uint256 => uint256[3])) _dayPhaseRolls;
    */
    function getDrawRandomness(uint256 queueID, uint256 playerID)
        public
        view
        returns (uint256)
    {
        return _drawRandomness[queueID][playerID];
    }

    function getPlayerRolls(uint256 queueID, uint256 playerID)
        public
        view
        returns (uint256[3] memory)
    {
        return _playerRolls[queueID][playerID];
    }

    function getDayPhaseDrawRandomness(uint256 queueID, uint256 playerID)
        public
        view
        returns (uint256)
    {
        return _dayPhaseDrawRandomness[queueID][playerID];
    }

    function getDayPhaseRolls(uint256 queueID, uint256 playerID)
        public
        view
        returns (uint256[3] memory)
    {
        return _dayPhaseRolls[queueID][playerID];
    }

    function randomIndicesForPlayer(uint256 playerID, bool dayEvent)
        internal
        pure
        returns (uint256 drawRandomnessIndex, uint256 rollRandomnessIndex)
    {
        RandomIndex _drawRandomnessIndex;
        RandomIndex _rollRandomnessIndex;
        if (dayEvent) {
            if (playerID == 1) {
                _drawRandomnessIndex = RandomIndex.P1DayEventCardDraw;
                _rollRandomnessIndex = RandomIndex.P1DayEventRoll;
            } else if (playerID == 2) {
                _drawRandomnessIndex = RandomIndex.P2DayEventCardDraw;
                _rollRandomnessIndex = RandomIndex.P2DayEventRoll;
            } else if (playerID == 3) {
                _drawRandomnessIndex = RandomIndex.P3DayEventCardDraw;
                _rollRandomnessIndex = RandomIndex.P3DayEventRoll;
            } else {
                _drawRandomnessIndex = RandomIndex.P4DayEventCardDraw;
                _rollRandomnessIndex = RandomIndex.P4DayEventRoll;
            }
        } else {
            if (playerID == 1) {
                _drawRandomnessIndex = RandomIndex.P1DigCardDraw;
                _rollRandomnessIndex = RandomIndex.P1DigCardOutcome;
            } else if (playerID == 2) {
                _drawRandomnessIndex = RandomIndex.P2DigCardDraw;
                _rollRandomnessIndex = RandomIndex.P2DigCardOutcome;
            } else if (playerID == 3) {
                _drawRandomnessIndex = RandomIndex.P3DigCardDraw;
                _rollRandomnessIndex = RandomIndex.P3DigCardOutcome;
            } else {
                _drawRandomnessIndex = RandomIndex.P4DigCardDraw;
                _rollRandomnessIndex = RandomIndex.P4DigCardOutcome;
            }
        }
        drawRandomnessIndex = uint256(_drawRandomnessIndex);
        rollRandomnessIndex = uint256(_rollRandomnessIndex);
    }

    function drawCard(
        CardType cardType,
        uint256 queueID,
        uint256 playerID,
        bool dayPhase
    )
        public
        view
        returns (
            string memory card,
            int8 movementAdjust,
            int8 agilityAdjust,
            int8 dexterityAdjust,
            string memory itemTypeLoss,
            string memory itemTypeGain,
            string memory handLoss,
            string memory outcome
        )
    {
        // get randomness from queue QUEUE.randomness(queueID)
        // outputs should match up with what's returned from deck draw

        if (cardType == CardType.Event) {
            // draw from event deck
            (
                card,
                movementAdjust,
                agilityAdjust,
                dexterityAdjust,
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? EVENT_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : EVENT_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        } else if (cardType == CardType.Ambush) {
            // draw from ambush deck
            (
                card,
                movementAdjust,
                agilityAdjust,
                dexterityAdjust,
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? AMBUSH_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : AMBUSH_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        } else {
            // draw from treasure deck
            (
                card,
                movementAdjust,
                agilityAdjust,
                dexterityAdjust,
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? TREASURE_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : TREASURE_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        }
    }

    function drawCard(
        CardType cardType,
        uint256 queueID,
        uint256 playerID,
        bool dayPhase,
        bool /* return stats as int8[3] */
    )
        public
        view
        returns (
            string memory card,
            int8[3] memory stats,
            string memory itemTypeLoss,
            string memory itemTypeGain,
            string memory handLoss,
            string memory outcome
        )
    {
        if (cardType == CardType.Event) {
            // draw from event deck
            (
                card,
                stats[0],
                stats[1],
                stats[2],
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? EVENT_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : EVENT_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        } else if (cardType == CardType.Ambush) {
            // draw from ambush deck
            (
                card,
                stats[0],
                stats[1],
                stats[2],
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? AMBUSH_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : AMBUSH_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        } else {
            // draw from treasure deck
            (
                card,
                stats[0],
                stats[1],
                stats[2],
                itemTypeLoss,
                itemTypeGain,
                handLoss,
                outcome
            ) = dayPhase
                ? TREASURE_DECK.drawCard(
                    _dayPhaseDrawRandomness[queueID][playerID],
                    _dayPhaseRolls[queueID][playerID]
                )
                : TREASURE_DECK.drawCard(
                    _drawRandomness[queueID][playerID],
                    _playerRolls[queueID][playerID]
                );
        }
    }

    function attributeRoll(
        uint256 numDice,
        uint256 queueID,
        uint256 randomnessIndex
    ) public view returns (uint256 rollTotal) {
        uint8[] memory die = new uint8[](3);
        die[0] = 0;
        die[1] = 1;
        die[2] = 2;
        rollTotal = _rollDice(queueID, die, numDice, randomnessIndex);
    }

    function d6Roll(
        uint256 numDice,
        uint256 queueID,
        uint256 randomnessIndex
    ) public view returns (uint256 rollTotal) {
        uint8[] memory die = new uint8[](6);
        die[0] = 1;
        die[1] = 2;
        die[2] = 3;
        die[3] = 4;
        die[4] = 5;
        die[5] = 6;
        rollTotal = _rollDice(queueID, die, numDice, randomnessIndex);
    }

    function _rollDice(
        uint256 queueID,
        uint8[] memory diceValues,
        uint256 diceQty,
        uint256 randomnessIndex
    ) internal view returns (uint256 rollTotal) {
        rollTotal = 0;
        // Simulated dice roll, get max possible roll value and use randomness to get total
        uint256 maxValue = uint256(diceValues[0]);
        for (uint256 i = 1; i < diceValues.length; i++) {
            if (diceValues[i] > diceValues[i - 1]) {
                maxValue = uint256(diceValues[i]);
            }
        }
        rollTotal =
            QUEUE.randomness(queueID, randomnessIndex) %
            ((maxValue * diceQty) + 1);
    }

    function playerRolls(
        uint256 queueID,
        uint256 playerID,
        uint256 randomnessIndex
    ) internal view returns (uint256[3] memory rolls) {
        // TODO: update to use randomness provided, no roll seeds
        // use same randomness for all rolls, only one will be used but all 3 are prepared
        uint8[3] memory playerStats = QUEUE.getStatsAtSubmission(
            queueID,
            playerID
        );
        rolls[0] = attributeRoll(playerStats[0], queueID, randomnessIndex);
        rolls[1] = attributeRoll(playerStats[1], queueID, randomnessIndex);
        rolls[2] = attributeRoll(playerStats[2], queueID, randomnessIndex);
    }

    // function getRollSeed(uint256 playerID) public view returns (uint256 seed) {
    //     if (QUEUE.isInTestMode()) {
    //         seed = playerID;
    //     } else {
    //         seed = playerID * block.timestamp;
    //     }
    // }

    // function getRollSeeds(uint256 playerID, uint256 numSeeds)
    //     public
    //     view
    //     returns (uint256[] memory seeds)
    // {
    //     seeds = new uint256[](numSeeds);
    //     if (QUEUE.isInTestMode()) {
    //         for (uint256 i = 0; i < numSeeds; i++) {
    //             seeds[i] = playerID + i;
    //         }
    //     } else {
    //         for (uint256 i = 0; i < numSeeds; i++) {
    //             seeds[i] = (playerID + (4 * playerID)) * i * block.timestamp;
    //         }
    //     }
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Allows a collection of tokens to be created within a token group or contract
// these tokens exclusively for in game use and by default only controllable by
// a game controller
contract GameToken is AccessControlEnumerable {
    event Transfer(
        uint256 indexed gameID,
        uint256 indexed fromID,
        uint256 indexed toID,
        address controller,
        string tokenType,
        uint256 value
    );

    event TransferToZone(
        uint256 indexed gameID,
        uint256 indexed fromID,
        uint256 indexed toZoneIndex,
        address controller,
        string tokenType,
        uint256 value
    );

    event TransferFromZone(
        uint256 indexed gameID,
        uint256 indexed fromZoneIndex,
        uint256 indexed toID,
        address controller,
        string tokenType,
        uint256 value
    );

    event TransferZoneToZone(
        uint256 indexed gameID,
        uint256 indexed fromZoneIndex,
        uint256 indexed toZoneIndex,
        address controller,
        string tokenType,
        uint256 value
    );

    bytes32 public constant CONTROLLER_ROLE = keccak256("CONTROLLER_ROLE");
    // tokenType => game ID => id =>
    // (0 is bank, player ID or 1000000 is active wallet)
    mapping(string => mapping(uint256 => mapping(uint256 => uint256)))
        public balance;

    // balance of a zone with all zones index of ID on game baord
    mapping(string => mapping(uint256 => mapping(uint256 => uint256)))
        public zoneBalance;
    mapping(string => bool) internal tokenTypeSet;
    string[] public tokenTypes;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function addController(address controllerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(CONTROLLER_ROLE, controllerAddress);
    }

    function addTokenTypes(string[] memory _tokenTypes)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < _tokenTypes.length; i++) {
            string memory tokenType = _tokenTypes[i];
            string[] storage tTypes = tokenTypes;
            if (!tokenTypeSet[tokenType]) {
                tTypes.push(tokenType);
                tokenTypeSet[tokenType] = true;
            }
        }
    }

    function mint(
        string memory tokenType,
        uint256 gameID,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(tokenTypeSet[tokenType], "Token type not set");
        balance[tokenType][gameID][0] = quantity;
    }

    function mintTo(
        uint256 recipient,
        string memory tokenType,
        uint256 gameID,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(tokenTypeSet[tokenType], "Token type not set");
        balance[tokenType][gameID][recipient] = quantity;
    }

    // from ID + to ID can be player IDs or any other ID used in game.
    // use transferToZone or transferFromZone if not going between board and player
    function transfer(
        string memory tokenType,
        uint256 gameID,
        uint256 fromID,
        uint256 toID,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(
            balance[tokenType][gameID][fromID] >= quantity,
            "from balance too low"
        );
        balance[tokenType][gameID][toID] += quantity;
        balance[tokenType][gameID][fromID] -= quantity;
        emit Transfer(gameID, fromID, toID, _msgSender(), tokenType, quantity);
    }

    function transferToZone(
        string memory tokenType,
        uint256 gameID,
        uint256 fromID,
        uint256 toZoneIndex,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(
            balance[tokenType][gameID][fromID] >= quantity,
            "from balance too low"
        );
        zoneBalance[tokenType][gameID][toZoneIndex] += quantity;
        balance[tokenType][gameID][fromID] -= quantity;
        emit TransferToZone(
            gameID,
            fromID,
            toZoneIndex,
            _msgSender(),
            tokenType,
            quantity
        );
    }

    function transferFromZone(
        string memory tokenType,
        uint256 gameID,
        uint256 fromZoneIndex,
        uint256 toID,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(
            zoneBalance[tokenType][gameID][fromZoneIndex] >= quantity,
            "from balance too low"
        );
        balance[tokenType][gameID][toID] += quantity;
        zoneBalance[tokenType][gameID][fromZoneIndex] -= quantity;
        emit TransferFromZone(
            gameID,
            fromZoneIndex,
            toID,
            _msgSender(),
            tokenType,
            quantity
        );
    }

    function transferZoneToZone(
        string memory tokenType,
        uint256 gameID,
        uint256 fromZoneIndex,
        uint256 toZoneIndex,
        uint256 quantity
    ) public onlyRole(CONTROLLER_ROLE) {
        require(
            zoneBalance[tokenType][gameID][fromZoneIndex] >= quantity,
            "from balance too low"
        );
        zoneBalance[tokenType][gameID][toZoneIndex] += quantity;
        zoneBalance[tokenType][gameID][fromZoneIndex] -= quantity;
        emit Transfer(
            gameID,
            fromZoneIndex,
            toZoneIndex,
            _msgSender(),
            tokenType,
            quantity
        );
    }

    function getTokenTypes() public view returns (string[] memory) {
        return tokenTypes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KeeperBase {
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

interface KeeperCompatibleInterface {
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