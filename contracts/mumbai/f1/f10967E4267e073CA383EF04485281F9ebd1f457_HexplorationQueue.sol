// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

//TODO:
// setup timer keeper for when all players don't sumbit moves

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./HexplorationStateUpdate.sol";

contract HexplorationQueue is AccessControlEnumerable, VRFConsumerBaseV2 {
    using Counters for Counters.Counter;
    Counters.Counter internal QUEUE_ID;
    CharacterCard internal CHARACTER_CARD;

    // VRF
    VRFCoordinatorV2Interface COORDINATOR;
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords = 1;

    event ProcessingPhaseChange(
        uint256 indexed gameID,
        uint256 timeStamp,
        ProcessingPhase newPhase
    );

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

    // Array of Queue IDs to be processed.
    uint256[] public processingQueue;

    // do we need these 2?
    mapping(uint256 => uint16) public currentQueuePosition; // ?? increases with each player in queue, then back to 0
    mapping(uint256 => uint16) public playThroughPosition; // ?? in case we need to batch this too... hopefully not.

    // mapping from game ID
    mapping(uint256 => uint256) public queueID; // mapping from game ID to it's queue, updates to 0 when finished

    // mappings from queue index
    mapping(uint256 => bool) public inProcessingQueue; // game queue is in processing queue
    mapping(uint256 => ProcessingPhase) public currentPhase; // processingPhase
    mapping(uint256 => uint256) public game; // mapping from queue ID to it's game ID
    mapping(uint256 => uint256[]) public players; // all players with moves to process
    mapping(uint256 => uint256) public totalPlayers; // total # of players who will be submitting
    mapping(uint256 => uint256) public randomness; // randomness delivered here at start of each phase processing

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

    function sumbitActionForPlayer(
        uint256 playerID,
        uint8 action,
        string[] memory options,
        string memory leftHand,
        string memory rightHand,
        uint256 _queueID
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
                _processAllActions(_queueID);
            }
            playerStatsAtSubmission[_queueID][playerID] = CHARACTER_CARD
                .getStats(game[_queueID], playerID);
        }
    }

    // Will get processed once keeper is available
    // and previous game queues have been processed
    function requestProcessActions(uint256 _queueID)
        public
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
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
        emit ProcessingPhaseChange(game[_queueID], block.timestamp, phase);
    }

    function setRandomNumber(uint256 randomNumber, uint256 _queueID)
        external
        onlyRole(GAMEPLAY_ROLE)
    {
        randomness[_queueID] = randomNumber;
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
            // request random number for phase
            requestRandomWords(_queueID);
        }
    }

    function requestRandomWords(uint256 _queueID) internal {
        uint256 reqID = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        randomnessRequestQueueID[reqID] = _queueID;

        // testing below, comment out uncomment VRF code above to enable chainlink vrf for production

        // uint256 reqID = _queueID;
        // randomnessRequestQueueID[reqID] = _queueID;
        // uint256 random = uint256(keccak256(abi.encode(block.timestamp, reqID)));
        // uint256[] memory randomWords = new uint256[](1);
        // randomWords[0] = random;
        // fulfillRandomWords(reqID, randomWords);
    }

    function fulfillRandomWords(uint256 requestID, uint256[] memory randomWords)
        internal
        override
    {
        uint256 qID = randomnessRequestQueueID[requestID];
        randomness[qID] = randomWords[0];
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Game Tokens
import "./DayNight.sol";
import "./Disaster.sol";
import "./Enemy.sol";
import "./Item.sol";
import "./PlayerStatus.sol";
import "./Artifact.sol";
import "./Relic.sol";

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

    DayNight public DAY_NIGHT_TOKEN;
    Disaster public DISASTER_TOKEN;
    Enemy public ENEMY_TOKEN;
    Item public ITEM_TOKEN;
    PlayerStatus public PLAYER_STATUS_TOKEN;
    Artifact public ARTIFACT_TOKEN;
    Relic public RELIC_TOKEN;

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
        DAY_NIGHT_TOKEN = DayNight(dayNightAddress);
        DISASTER_TOKEN = Disaster(disasterAddress);
        ENEMY_TOKEN = Enemy(enemyAddress);
        ITEM_TOKEN = Item(itemAddress);
        PLAYER_STATUS_TOKEN = PlayerStatus(playerStatusAddress);
        ARTIFACT_TOKEN = Artifact(artifactAddress);
        RELIC_TOKEN = Relic(relicAddress);
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

import "./GameToken.sol";

contract Relic is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](6);
        tokenTypes[0] = "Relic 1";
        tokenTypes[1] = "Relic 2";
        tokenTypes[2] = "Relic 3";
        tokenTypes[3] = "Relic 4";
        tokenTypes[4] = "Relic 5";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract PlayerStatus is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](2);
        tokenTypes[0] = "Stunned";
        tokenTypes[1] = "Burned";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract Item is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](38);
        tokenTypes[0] = "Small Ammo";
        tokenTypes[1] = "Large Ammo";
        tokenTypes[2] = "Batteries";
        tokenTypes[3] = "Shield";
        tokenTypes[4] = "Portal";
        tokenTypes[5] = "On";
        tokenTypes[6] = "Off";
        tokenTypes[7] = "Rusty Dagger";
        tokenTypes[8] = "Rusty Sword";
        tokenTypes[9] = "Rusty Pistol";
        tokenTypes[10] = "Rusty Rifle";
        tokenTypes[11] = "Shiny Dagger";
        tokenTypes[12] = "Shiny Sword";
        tokenTypes[13] = "Shiny Pistol";
        tokenTypes[14] = "Shiny Rifle";
        tokenTypes[15] = "Laser Dagger";
        tokenTypes[16] = "Laser Sword";
        tokenTypes[17] = "Laser Pistol";
        tokenTypes[18] = "Laser Rifle";
        tokenTypes[19] = "Glow stick";
        tokenTypes[20] = "Flashlight";
        tokenTypes[21] = "Flood light";
        tokenTypes[22] = "Nightvision Goggles";
        tokenTypes[23] = "Personal Shield";
        tokenTypes[24] = "Bubble Shield";
        tokenTypes[25] = "Frag Grenade";
        tokenTypes[26] = "Fire Grenade";
        tokenTypes[27] = "Shock Grenade";
        tokenTypes[28] = "HE Mortar";
        tokenTypes[29] = "Incendiary Mortar";
        tokenTypes[30] = "EMP Mortar";
        tokenTypes[31] = "Power Glove";
        tokenTypes[32] = "Remote Launch and Guidance System";
        tokenTypes[33] = "Teleporter Pack";
        tokenTypes[34] = "Campsite";
        tokenTypes[35] = "Engraved Tablet";
        tokenTypes[36] = "Sigil Gem";
        tokenTypes[37] = "Ancient Tome";
        addTokenTypes(tokenTypes);
    }
}

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
    // (0 is bank, player ID or 1 is active wallet)
    mapping(string => mapping(uint256 => mapping(uint256 => uint256)))
        public balance;

    // balance of a zone with all zones index of ID on game baord
    mapping(string => mapping(uint256 => mapping(uint256 => uint256)))
        public zoneBalance;
    mapping(string => bool) internal tokenTypeSet;
    string[] public tokenTypes;

    constructor(address controllerAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // controller is only one who can send tokens around
        _setupRole(CONTROLLER_ROLE, controllerAddress);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract Enemy is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](6);
        tokenTypes[0] = "Pirate";
        tokenTypes[1] = "Pirate Ship";
        tokenTypes[2] = "Deathbot";
        tokenTypes[3] = "Guardian";
        tokenTypes[4] = "Sandworm";
        tokenTypes[5] = "Dragon";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract Disaster is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](2);
        tokenTypes[0] = "Earthquake";
        tokenTypes[1] = "Volcano";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract DayNight is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](2);
        tokenTypes[0] = "Day";
        tokenTypes[1] = "Night";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./GameToken.sol";

contract Artifact is GameToken {
    constructor(address controllerAddress) GameToken(controllerAddress) {
        string[] memory tokenTypes = new string[](6);
        tokenTypes[0] = "Engraved Tablet";
        tokenTypes[1] = "Sigil Gem";
        tokenTypes[2] = "Ancient Tome";
        addTokenTypes(tokenTypes);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

import "../HexplorationBoard.sol";
import "../HexplorationZone.sol";
import "@luckymachines/game-core/contracts/src/v0.0/PlayerRegistry.sol";
import "./CharacterCard.sol";
import "../tokens/TokenInventory.sol";
import "../HexplorationQueue.sol";

library GameSummary {
    // Function called by frontent for game info
    function boardSize(address gameBoardAddress)
        public
        view
        returns (uint256 rows, uint256 columns)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        rows = board.gridHeight();
        columns = board.gridWidth();
    }

    function isRegistered(
        address gameBoardAddress,
        uint256 gameID,
        address playerAddress
    ) public view returns (bool) {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        return pr.isRegistered(gameID, playerAddress);
    }

    function getPlayerID(
        address gameBoardAddress,
        uint256 gameID,
        address playerAddress
    ) public view returns (uint256 playerID) {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        playerID = pr.playerID(gameID, playerAddress);
    }

    function currentGameplayQueue(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (uint256)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        HexplorationQueue q = HexplorationQueue(board.gameplayQueue());
        return q.queueID(gameID);
    }

    function currentPhase(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string memory phase)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        TokenInventory tokens = TokenInventory(board.tokenInventory());

        uint256 dayBalance = tokens.DAY_NIGHT_TOKEN().balance("Day", gameID, 1);
        phase = dayBalance > 0 ? "Day" : "Night";
    }

    function activeZones(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string[] memory zones, uint16[] memory tiles)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        string[] memory allZones = board.getZoneAliases();

        uint16 activeZoneCount = 0;
        for (uint256 i = 0; i < allZones.length; i++) {
            if (board.zoneEnabled(gameID, allZones[i])) {
                activeZoneCount++;
            }
        }
        zones = new string[](activeZoneCount);
        tiles = new uint16[](activeZoneCount);

        activeZoneCount = 0;
        for (uint256 i = 0; i < allZones.length; i++) {
            if (board.zoneEnabled(gameID, allZones[i])) {
                zones[activeZoneCount] = allZones[i];
                HexplorationZone hexZone = HexplorationZone(
                    board.hexZoneAddress()
                );
                tiles[activeZoneCount] = uint16(
                    hexZone.tile(gameID, allZones[i])
                );
                activeZoneCount++;
            }
        }
    }

    function landingSite(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string memory)
    {
        return HexplorationBoard(gameBoardAddress).initialPlayZone(gameID);
    }

    function allPlayerLocations(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (uint256[] memory, string[] memory)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        uint256 totalRegistrations = pr.totalRegistrations(gameID);
        uint256[] memory playerIDs = new uint256[](totalRegistrations);
        string[] memory playerZones = new string[](totalRegistrations);
        for (uint256 i = 0; i < totalRegistrations; i++) {
            playerIDs[i] = i + 1;
            playerZones[i] = board.currentPlayZone(gameID, i + 1);
        }
        return (playerIDs, playerZones);
    }

    // Functions called directly by players
    function currentLocation(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string memory)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        return board.currentPlayZone(gameID, pr.playerID(gameID, msg.sender));
    }

    function currentPlayerStats(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (
            uint8 movement,
            uint8 agility,
            uint8 dexterity
        )
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        CharacterCard cc = CharacterCard(board.characterCard());
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        uint256 playerID = pr.playerID(gameID, msg.sender);
        movement = cc.movement(gameID, playerID);
        agility = cc.agility(gameID, playerID);
        dexterity = cc.dexterity(gameID, playerID);
    }

    function currentHandInventory(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string memory leftHandItem, string memory rightHandItem)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        CharacterCard cc = CharacterCard(board.characterCard());
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        uint256 playerID = pr.playerID(gameID, msg.sender);
        leftHandItem = inventoryItemExists(
            cc.leftHandItem(gameID, playerID),
            board.tokenInventory(),
            gameID,
            PlayerRegistry(board.prAddress()).playerID(gameID, msg.sender)
        )
            ? cc.leftHandItem(gameID, playerID)
            : "";

        rightHandItem = inventoryItemExists(
            cc.rightHandItem(gameID, playerID),
            board.tokenInventory(),
            gameID,
            PlayerRegistry(board.prAddress()).playerID(gameID, msg.sender)
        )
            ? cc.rightHandItem(gameID, playerID)
            : "";
    }

    function activeInventory(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (
            string memory artifact,
            string memory status,
            string memory relic,
            bool shield,
            bool campsite
        )
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        CharacterCard cc = CharacterCard(board.characterCard());
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        uint256 playerID = pr.playerID(gameID, msg.sender);
        artifact = inventoryArtifactExists(
            cc.artifact(gameID, playerID),
            board.tokenInventory(),
            gameID,
            playerID
        )
            ? cc.artifact(gameID, playerID)
            : "";

        status = inventoryStatusExists(
            cc.status(gameID, playerID),
            board.tokenInventory(),
            gameID,
            playerID
        )
            ? cc.status(gameID, playerID)
            : "";

        relic = inventoryItemExists(
            cc.relic(gameID, playerID),
            board.tokenInventory(),
            gameID,
            playerID
        )
            ? cc.relic(gameID, playerID)
            : "";

        shield = inventoryItemExists(
            "Shield",
            board.tokenInventory(),
            gameID,
            playerID
        )
            ? true
            : false;

        campsite = inventoryItemExists(
            "Campsite",
            board.tokenInventory(),
            gameID,
            playerID
        )
            ? true
            : false;
    }

    function inactiveInventory(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string[] memory itemTypes, uint256[] memory itemBalances)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        TokenInventory ti = TokenInventory(board.tokenInventory());
        itemBalances = new uint256[](35);
        itemTypes = new string[](35);
        itemTypes[0] = "Small Ammo";
        itemTypes[1] = "Large Ammo";
        itemTypes[2] = "Batteries";
        itemTypes[3] = "Shield";
        itemTypes[4] = "Portal";
        itemTypes[5] = "On";
        itemTypes[6] = "Off";
        itemTypes[7] = "Rusty Dagger";
        itemTypes[8] = "Rusty Sword";
        itemTypes[9] = "Rusty Pistol";
        itemTypes[10] = "Rusty Rifle";
        itemTypes[11] = "Shiny Dagger";
        itemTypes[12] = "Shiny Sword";
        itemTypes[13] = "Shiny Pistol";
        itemTypes[14] = "Shiny Rifle";
        itemTypes[15] = "Laser Dagger";
        itemTypes[16] = "Laser Sword";
        itemTypes[17] = "Laser Pistol";
        itemTypes[18] = "Laser Rifle";
        itemTypes[19] = "Glow stick";
        itemTypes[20] = "Flashlight";
        itemTypes[21] = "Flood light";
        itemTypes[22] = "Nightvision Goggles";
        itemTypes[23] = "Personal Shield";
        itemTypes[24] = "Bubble Shield";
        itemTypes[25] = "Frag Grenade";
        itemTypes[26] = "Fire Grenade";
        itemTypes[27] = "Shock Grenade";
        itemTypes[28] = "HE Mortar";
        itemTypes[29] = "Incendiary Mortar";
        itemTypes[30] = "EMP Mortar";
        itemTypes[31] = "Power Glove";
        itemTypes[32] = "Remote Launch and Guidance System";
        itemTypes[33] = "Teleporter Pack";
        itemTypes[34] = "Campsite";
        uint256 playerID = pr.playerID(gameID, msg.sender);
        if (ti.holdsToken(playerID, TokenInventory.Token.Item, gameID)) {
            Item itemToken = ti.ITEM_TOKEN();
            string[] memory types = itemToken.getTokenTypes();
            for (uint256 i = 0; i < itemBalances.length; i++) {
                itemTypes[i] = types[i];
                itemBalances[i] = itemToken.balance(types[i], gameID, playerID);
            }
        }
        // uint256 campsiteBalance = ti.ITEM_TOKEN().balance(
        //     "Campsite",
        //     gameID,
        //     playerID
        // );
        // itemBalances[34] = campsiteBalance;
    }

    // Internal Stuff
    function inventoryItemExists(
        string memory tokenType,
        address inventoryAddress,
        uint256 gameID,
        uint256 holderID
    ) internal view returns (bool) {
        return
            TokenInventory(inventoryAddress).ITEM_TOKEN().balance(
                tokenType,
                gameID,
                holderID
            ) > 0;
    }

    function inventoryArtifactExists(
        string memory tokenType,
        address inventoryAddress,
        uint256 gameID,
        uint256 holderID
    ) internal view returns (bool) {
        return
            TokenInventory(inventoryAddress).ARTIFACT_TOKEN().balance(
                tokenType,
                gameID,
                holderID
            ) > 0;
    }

    function inventoryStatusExists(
        string memory tokenType,
        address inventoryAddress,
        uint256 gameID,
        uint256 holderID
    ) internal view returns (bool) {
        return
            TokenInventory(inventoryAddress).PLAYER_STATUS_TOKEN().balance(
                tokenType,
                gameID,
                holderID
            ) > 0;
    }

    function zoneIndex(address gameBoardAddress, string memory zoneAlias)
        internal
        view
        returns (uint256 index)
    {
        index = 1111111111111;
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        string[] memory allZones = board.getZoneAliases();
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

    // TODO:
    // Functions to complete

    function lastDayPhaseEvents(address gameBoardAddress, uint256 gameID)
        public
        returns (
            uint256[] memory playerIDs,
            string[] memory activeActionCardTypes,
            string[] memory activeActionCardsDrawn,
            string[] memory currentActiveActions,
            string[] memory activeActionCardResults,
            string[3][] memory activeActionCardInventoryChanges
        )
    {}

    function lastPlayerActions(address gameBoardAddress, uint256 gameID)
        public
        returns (
            uint256[] memory playerIDs,
            string[] memory activeActionCardTypes,
            string[] memory activeActionCardsDrawn,
            string[] memory currentActiveActions,
            string[] memory activeActionCardResults,
            string[3][] memory activeActionCardInventoryChanges
        )
    {
        // returns
        // playerIDs
        // activeActionCardType - // "Event","Ambush","Treasure"
        // activationActionCardsDrawn = card title of card drawn
        // currentActveActions - action doing that led to card draw
        // activeActionCardResults - outcomes of cards
        // activeActionCardInventoryChangs - item loss, item gain, hand loss (left/right)
    }

    // SHINY NEW FUNCTIONS!!!
    function getAvailableGameIDs(
        address gameBoardAddress,
        address gameRegistryAddress
    ) public view returns (uint256[] memory) {
        return
            HexplorationBoard(gameBoardAddress).openGames(gameRegistryAddress);
    }

    function isAtCampsite(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (bool atCampsite)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        string memory currentZone = board.currentPlayZone(
            gameID,
            pr.playerID(gameID, msg.sender)
        );
        uint256 index = zoneIndex(gameBoardAddress, currentZone);
        // zone balance...
        //mapping(string => mapping(uint256 => mapping(uint256 => uint256)))

        atCampsite =
            TokenInventory(board.tokenInventory()).ITEM_TOKEN().zoneBalance(
                "Campsite",
                gameID,
                index
            ) >
            0;
    }

    function activeAction(address gameBoardAddress, uint256 gameID)
        public
        view
        returns (string memory action)
    {
        HexplorationBoard board = HexplorationBoard(gameBoardAddress);
        CharacterCard cc = CharacterCard(board.characterCard());
        uint256 playerID = PlayerRegistry(board.prAddress()).playerID(
            gameID,
            msg.sender
        );
        CharacterCard.Action a = cc.action(gameID, playerID);

        action = "Idle";
        if (a == CharacterCard.Action.Move) {
            action = "Move";
        } else if (a == CharacterCard.Action.SetupCamp) {
            action = "Setup camp";
        } else if (a == CharacterCard.Action.BreakDownCamp) {
            action = "Break down camp";
        } else if (a == CharacterCard.Action.Dig) {
            action = "Dig";
        } else if (a == CharacterCard.Action.Rest) {
            action = "Rest";
        } else if (a == CharacterCard.Action.Help) {
            action = "Help";
        }
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
    uint8 constant MAX_MOVEMENT = 4;
    uint8 constant MAX_AGILITY = 4;
    uint8 constant MAX_DEXTERITY = 4;

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

    function getStats(uint256 gameID, uint256 playerID)
        public
        view
        returns (uint8[3] memory stats)
    {
        stats[0] = movement[gameID][playerID];
        stats[1] = agility[gameID][playerID];
        stats[2] = dexterity[gameID][playerID];
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
        movement[gameID][playerID] = movementValue;
    }

    function setAgility(
        uint8 agilityValue,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        agility[gameID][playerID] = agilityValue;
    }

    function setDexterity(
        uint8 dexterityValue,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        dexterity[gameID][playerID] = dexterityValue;
    }

    function setLeftHandItem(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        leftHandItem[gameID][playerID] = itemTokenType;
    }

    function setRightHandItem(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        rightHandItem[gameID][playerID] = itemTokenType;
    }

    function setArtifact(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        rightHandItem[gameID][playerID] = itemTokenType;
    }

    function setStatus(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        rightHandItem[gameID][playerID] = itemTokenType;
    }

    function setRelic(
        string memory itemTokenType,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        rightHandItem[gameID][playerID] = itemTokenType;
    }

    function setAction(
        Action _action,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        action[gameID][playerID] = _action;
    }

    function setActionResults(
        string memory actionCardType,
        string memory actionCardDrawn,
        string memory actionCardResult,
        string[3] memory actionCardInventoryChanges,
        uint256 gameID,
        uint256 playerID
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        activeActionCardType[gameID][playerID] = actionCardType;
        activeActionCardDrawn[gameID][playerID] = actionCardDrawn;
        activeActionCardResult[gameID][playerID] = actionCardResult;
        activeActionCardInventoryChanges[gameID][
            playerID
        ] = actionCardInventoryChanges;
    }
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
    mapping(string => string[3]) public handLoss;
    mapping(string => int256[3]) public movementX;
    mapping(string => int256[3]) public movementY;
    mapping(string => uint256[3]) public rollThresholds; // [0, 3, 4] what to roll to receive matching index of mapping
    mapping(string => string[3]) public outcomeDescription;
    mapping(string => uint256) public rollTypeRequired; // 0 = movement, 1 = agility, 2 = dexterity

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

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

    // this function does not provide randomness,
    // passing the same random word will yield the same draw.
    // randomness should come from controller

    // pass along movement, agility, dexterity rolls - will use whatever is appropriate
    function drawCard(uint256 randomWord, uint256[3] memory rollValues)
        public
        view
        virtual
        returns (
            string memory,
            int8,
            int8,
            int8,
            string memory,
            string memory,
            string memory,
            string memory
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
        return (
            card,
            movementAdjust[card][rollIndex],
            agilityAdjust[card][rollIndex],
            dexterityAdjust[card][rollIndex],
            itemLoss[card][rollIndex],
            itemGain[card][rollIndex],
            handLoss[card][rollIndex],
            outcomeDescription[card][rollIndex]
        );
    }

    function getDeck() public view returns (string[] memory) {
        return _cards;
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

    // Override for custom game
    // function _playerWillEnter(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _playerDidEnter(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _playerWillExit(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _playerDidExit(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _playersWillEnter(
    //     uint256 gameID,
    //     uint256 groupID,
    //     string memory zoneAlias
    // ) internal virtual {
    //     // called when batch of players are being entered from lobby or previous zone
    //     // individual player entries are called from _playerDidEnter
    // }

    // function _allPlayersEntered(
    //     uint256 gameID,
    //     uint256 groupID,
    //     string memory zoneAlias
    // ) internal virtual {
    //     // called after player group has all been entered
    // }

    // function _playerWillBeRemoved(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _playerWasRemoved(
    //     address playerAddress,
    //     uint256 gameID,
    //     string memory zoneAlias
    // ) internal virtual {}

    // function _customAction(
    //     string[] memory stringParams,
    //     address[] memory addressParams,
    //     uint256[] memory uintParams
    // ) internal virtual {
    //     // should definitiely do some checks when implementing this function
    //     // make sure the sender is correct and nothing malicious is going on
    // }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// TODO: start using this for state updating outside of controller
// Controller should only be used by users / UI directly sending
// commands. This does things that can only imagine...

// This should be only associated with one board...

import "./HexplorationController.sol";
import "./HexplorationBoard.sol";
import "./decks/CardDeck.sol";
import "./state/CharacterCard.sol";
import "./HexplorationGameplay.sol";

contract HexplorationStateUpdate is AccessControlEnumerable {
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

    event GamePhaseChange(
        uint256 indexed gameID,
        uint256 timeStamp,
        string newPhase
    );

    HexplorationBoard internal GAME_BOARD;
    CharacterCard internal CHARACTER_CARD;
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

    function postUpdates(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        // go through values and post everything, transfer all the tokens, and pray
        // use gamestate update contract to post everything
        updatePlayerPositions(updates, gameID);
        updatePlayerStats(updates, gameID);
        updatePlayerHands(updates, gameID);
        transferPlayerItems(updates, gameID);
        transferZoneItems(updates, gameID);
        applyActivityEffects(updates, gameID);
        updatePlayPhase(updates, gameID);
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
        string[] activeActionOptions;
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
            moveThroughPath(
                path,
                gameID,
                updates.playerPositionIDs[i],
                updates.randomness
            );
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
                gameID,
                updates.playerActiveActionIDs[i]
            );
        }
    }

    function transferPlayerItems(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
        for (uint256 i = 0; i < updates.playerTransfersTo.length; i++) {
            ti.ITEM_TOKEN().transfer(
                updates.playerTransferItemTypes[i],
                gameID,
                updates.playerTransfersFrom[i],
                updates.playerTransfersTo[i],
                updates.playerTransferQtys[i]
            );
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
                ti.ITEM_TOKEN().transferToZone(
                    tferItem,
                    gameID,
                    fromID,
                    toID,
                    tferQty
                );
            } else if (updates.zoneTransfersFrom[i] == 10000000000) {
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
        uint256 randomness
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        //TODO: pick tiles from deck

        HexplorationZone.Tile[] memory tiles = new HexplorationZone.Tile[](
            zonePath.length
        );
        uint256[] memory randomNumbers = new uint256[](zonePath.length);
        randomNumbers[0] = randomness;
        // TODO: expand to more random numbers for length of zone
        // use this when drawing from tile deck
        for (uint256 i = 0; i < zonePath.length; i++) {
            tiles[i] = i == 0 ? HexplorationZone.Tile.Jungle : i == 1
                ? HexplorationZone.Tile.Plains
                : HexplorationZone.Tile.Mountain;
        }

        GAME_BOARD.moveThroughPath(zonePath, playerID, gameID, tiles);
    }

    function updatePlayPhase(
        HexplorationGameplay.PlayUpdates memory updates,
        uint256 gameID
    ) internal {
        if (bytes(updates.gamePhase).length > 0) {
            emit GamePhaseChange(gameID, block.timestamp, updates.gamePhase);
            TokenInventory ti = TokenInventory(GAME_BOARD.tokenInventory());
            if (
                keccak256(abi.encodePacked(updates.gamePhase)) ==
                keccak256(abi.encodePacked("Day"))
            ) {
                // set to day
                ti.DAY_NIGHT_TOKEN().transfer("Day", gameID, 0, 1, 1);
                ti.DAY_NIGHT_TOKEN().transfer("Night", gameID, 1, 0, 1);
            } else {
                // set to night
                ti.DAY_NIGHT_TOKEN().transfer("Day", gameID, 1, 0, 1);
                ti.DAY_NIGHT_TOKEN().transfer("Night", gameID, 0, 1, 1);
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "./HexplorationQueue.sol";
import "./HexplorationStateUpdate.sol";
import "./state/GameSummary.sol";
import "./HexplorationBoard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "./decks/CardDeck.sol";

contract HexplorationGameplay is
    AccessControlEnumerable,
    KeeperCompatibleInterface
{
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");

    HexplorationQueue QUEUE;
    HexplorationStateUpdate GAME_STATE;
    HexplorationBoard GAME_BOARD;
    address gameSummaryAddress;
    CardDeck EVENT_DECK;
    CardDeck TREASURE_DECK;
    CardDeck AMBUSH_DECK;

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
        string[] activeActionOptions;
        uint256[] activeActionResults; // 0 = None, 1 = Event, 2 = Ambush, 3 = Treasure
        string[2][] activeActionResultCard; // Card for Event / ambush / treasure , outcome e.g. ["Dance with locals", "You're amazing!"]
        string[3][] activeActionInventoryChanges; // [item loss, item gain, hand loss]
        uint256 randomness;
    }

    constructor(
        address _gameSummaryAddress,
        address gameBoardAddress,
        address eventDeck,
        address treasureDeck,
        address ambushDeck
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        GAME_BOARD = HexplorationBoard(gameBoardAddress);
        gameSummaryAddress = _gameSummaryAddress;
        EVENT_DECK = CardDeck(eventDeck);
        TREASURE_DECK = CardDeck(treasureDeck);
        AMBUSH_DECK = CardDeck(ambushDeck);
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

    // Test keeper functions
    function needsUpkeep()
        public
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
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
        if (QUEUE.randomness(queueIDToUpdate) == 0) {
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

    function doUpkeep(bytes calldata performData)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
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
        if (processingPhase == 2) {
            processPlayerActions(queueID, summary);
        } else if (processingPhase == 3) {
            processPlayThrough(queueID, summary);
        }
    }

    // Keeper functions
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
            if (pq[i] != 0 && QUEUE.randomness(queueIDToUpdate) > 0) {
                queueIDToUpdate = pq[i];
                upkeepNeeded = true;
                break;
            }
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

            if (
                action == HexplorationQueue.Action.Dig ||
                action == HexplorationQueue.Action.Rest ||
                action == HexplorationQueue.Action.Help ||
                action == HexplorationQueue.Action.SetupCamp ||
                action == HexplorationQueue.Action.BreakDownCamp
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
        PlayUpdates memory playUpdates = playUpdatesForPlayerActionPhase(
            queueID,
            summary
        );
        GAME_STATE.postUpdates(playUpdates, gameID);
        QUEUE.setPhase(HexplorationQueue.ProcessingPhase.PlayThrough, queueID);
    }

    function processPlayThrough(uint256 queueID, DataSummary memory summary)
        internal
    {
        HexplorationQueue.ProcessingPhase phase = QUEUE.currentPhase(queueID);

        if (QUEUE.randomness(queueID) != 0) {
            if (phase == HexplorationQueue.ProcessingPhase.PlayThrough) {
                uint256 gameID = QUEUE.game(queueID);
                PlayUpdates memory playUpdates = playUpdatesForPlayThroughPhase(
                    queueID,
                    summary
                );
                // TODO: set this to true when game is finished
                bool gameComplete = false;
                GAME_STATE.postUpdates(playUpdates, gameID);
                QUEUE.finishProcessing(queueID, gameComplete);
            }
        }
    }

    function playUpdatesForPlayerActionPhase(
        uint256 queueID,
        DataSummary memory summary
    ) internal view returns (PlayUpdates memory) {
        PlayUpdates memory playUpdates;

        uint256[] memory playersInQueue = QUEUE.getAllPlayers(queueID);
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
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.Move
            ) {
                // return [player id, # spaces to move]

                playUpdates.playerPositionIDs[position] = playersInQueue[i];
                playUpdates.spacesToMove[position] = QUEUE
                    .getSubmissionOptions(queueID, playersInQueue[i])
                    .length;
                string[] memory options = QUEUE.getSubmissionOptions(
                    queueID,
                    playersInQueue[i]
                );
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
                bytes(QUEUE.submissionLeftHand(queueID, playersInQueue[i]))
                    .length > 0
            ) {
                // return [player id, r/l hand (0/1)]

                playUpdates.playerEquipIDs[position] = playersInQueue[i];
                playUpdates.playerEquipHands[position] = 0;
                playUpdates.playerEquips[position] = QUEUE.submissionLeftHand(
                    queueID,
                    playersInQueue[i]
                );
                position++;
            }
        }

        // RH equip
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                bytes(QUEUE.submissionRightHand(queueID, playersInQueue[i]))
                    .length > 0
            ) {
                // return [player id, r/l hand (0/1)]

                playUpdates.playerEquipIDs[position] = playersInQueue[i];
                playUpdates.playerEquipHands[position] = 1;
                playUpdates.playerEquips[position] = QUEUE.submissionRightHand(
                    queueID,
                    playersInQueue[i]
                );
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
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.SetupCamp
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
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.BreakDownCamp
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
        playUpdates.activeActionOptions = new string[](summary.activeActions);
        playUpdates.activeActionResults = new uint256[](summary.activeActions);
        playUpdates.activeActionResultCard = new string[2][](
            summary.activeActions
        );
        playUpdates.activeActionInventoryChanges = new string[3][](
            summary.activeActions
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
        for (uint256 i = 0; i < playersInQueue.length; i++) {
            if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.SetupCamp
            ) {
                playUpdates.activeActions[position] = "Setup camp";
                playUpdates.activeActionOptions[position] = "";
                playUpdates.playerActiveActionIDs[position] = playersInQueue[i];
                position++;
            } else if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.BreakDownCamp
            ) {
                playUpdates.activeActions[position] = "Break down camp";
                playUpdates.activeActionOptions[position] = "";
                position++;
            } else if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.Dig
            ) {
                playUpdates.activeActions[position] = "Dig";
                playUpdates.activeActionOptions[position] = "";
                playUpdates.activeActionResults[position] = dig(
                    queueID,
                    playersInQueue[i]
                );
                (
                    playUpdates.activeActionResultCard[position][0],
                    playUpdates.playerStatUpdates[playerStatPosition],
                    playUpdates.activeActionInventoryChanges[position][0],
                    playUpdates.activeActionInventoryChanges[position][1],
                    playUpdates.activeActionInventoryChanges[position][2],
                    playUpdates.activeActionResultCard[position][1]
                ) = drawCard(
                    playUpdates.activeActionResults[position],
                    queueID,
                    playersInQueue[i]
                );

                playerStatPosition++;
                position++;
            } else if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.Rest
            ) {
                playUpdates.activeActions[position] = "Rest";
                playUpdates.activeActionOptions[position] = QUEUE
                    .submissionOptions(queueID, playersInQueue[i], 0);

                playUpdates.playerStatUpdates[playerStatPosition] = rest(
                    queueID,
                    playersInQueue[i]
                );
                playerStatPosition++;
                position++;
            } else if (
                QUEUE.submissionAction(queueID, playersInQueue[i]) ==
                HexplorationQueue.Action.Help
            ) {
                // TODO: use this...
                playUpdates.activeActions[position] = "Help";
                playUpdates.activeActionOptions[position] = QUEUE
                    .submissionOptions(queueID, playersInQueue[i], 0);
                position++;
            }
        }
        playUpdates.randomness = QUEUE.randomness(queueID);

        // only need to store current action as digging, resting, and play out during play phase

        return playUpdates;
    }

    function playUpdatesForPlayThroughPhase(
        uint256 queueID,
        DataSummary memory summary
    ) internal view returns (PlayUpdates memory) {
        PlayUpdates memory playUpdates;
        // uint256[] memory playersInQueue = QUEUE.getAllPlayers(queueID);
        // uint256 position;

        TokenInventory tokens = TokenInventory(GAME_BOARD.tokenInventory());
        uint256 dayBalance = tokens.DAY_NIGHT_TOKEN().balance(
            "Day",
            QUEUE.game(queueID),
            1
        );
        playUpdates.gamePhase = dayBalance > 0 ? "Night" : "Day";

        /*
        // TODO: set this to true when game is finished
        bool gameComplete = false;

        uint256 gameID = QUEUE.game(queueID);
        //uint256 gameID = QUEUE.game(queueID);
        // uint256 totalPlayers = PlayerRegistry(GAME_BOARD.prAddress())
        //     .totalRegistrations(QUEUE.game(queueID));
        CharacterCard cc = CharacterCard(GAME_BOARD.characterCard());

        // setup endgame

        //TODO:
        // check current phase (day / night)
        string memory currentPhase = "Day";
        bool isDay = stringsMatch(currentPhase, "Day");
        bool setupEndGame = false;
        for (
            uint256 i = 0;
            i <
            PlayerRegistry(GAME_BOARD.prAddress()).totalRegistrations(
                QUEUE.game(queueID)
            );
            i++
        ) {
            uint256 playerID = i + 1;
            uint256 activeAction = uint256(
                QUEUE.activeAction(queueID, playerID)
            );
            if (activeAction == 4) {
                // dig
                if (stringsMatch(dig(queueID, playerID), "Treasure")) {
                    // dug treasure! pick treasure card
                    // if final artifact is found, setupEndGame = true;
                } else {
                    // dug ambush...
                    // play out consequences
                }
            } else if (activeAction == 5) {
                // rest
                string memory restChoice = QUEUE.submissionOptions(
                    queueID,
                    playerID,
                    0
                );
                if (stringsMatch(restChoice, "Movement")) {
                    // add 1 to movement
                } else if (stringsMatch(restChoice, "Agility")) {
                    // add 1 to agility
                } else if (stringsMatch(restChoice, "Dexterity")) {
                    // add 1 to dexterity
                }
            } else if (activeAction == 6) {
                //help
                // set player ID to help (options) as string choice
            }

            // to get current player stats...
            // cc.movement(gameID, playerID) => returns uint8
            // cc.agility(gameID, playerID) => returns uint8
            // cc.dexterity(gameID, playerID) => returns uint8

            //to subtract from player stats...
            //subToZero(uint256(playerStat), reductionAmount);
            // can submit numbers higher than max here, but won't actually get set to those
            // will get set to max if max exceeded
        }

        if (setupEndGame) {
            // setup end game...
        }
        // update Phase (Day / Night);
        playUpdates.gamePhase = isDay ? "Night" : "Day";

        if (isDay) {
            for (
                uint256 i = 0;
                i <
                PlayerRegistry(GAME_BOARD.prAddress()).totalRegistrations(
                    QUEUE.game(queueID)
                );
                i++
            ) {
                uint256 playerID = i + 1;
                // if Day,
                // roll D6
                // if EVEN - Choose Event Card + calculate results + save to data
                // if ODD - Choose Ambush Card + calculate results + save to data
            }
        }
        */
        return playUpdates;
    }

    function dig(uint256 queueID, uint256 playerID)
        public
        view
        returns (uint256 resultType)
    {
        // if digging available... (should be pre-checked)
        // roll dice (d6) for each player on space not resting

        uint256 playersOnSpace = QUEUE
            .getSubmissionOptions(queueID, playerID)
            .length - 1;
        string memory phase = QUEUE.getSubmissionOptions(queueID, playerID)[0];
        uint256 rollOutcome = d6Roll(
            playersOnSpace,
            queueID,
            playerID * block.timestamp
        );
        uint256 rollRequired = stringsMatch(phase, "Day") ? 4 : 5;
        resultType = rollOutcome < rollRequired ? 2 : 3;

        // if sum of rolls is greater than 5 during night win treasure
        // if sum of rolls is greater than 4 during day win treasure
        // return "Treasure" or "Ambush"
        // Result types: 0 = None, 1 = Event, 2 = Ambush, 3 = Treasure
    }

    function playerRolls(uint256 queueID, uint256 playerID)
        internal
        view
        returns (uint256[3] memory rolls)
    {
        uint8[3] memory playerStats = QUEUE.getStatsAtSubmission(
            queueID,
            playerID
        );
        rolls[0] = attributeRoll(
            playerStats[0],
            queueID,
            playerID * block.timestamp
        );
        rolls[1] = attributeRoll(
            playerStats[1],
            queueID,
            playerID * block.timestamp
        );
        rolls[2] = attributeRoll(
            playerStats[2],
            queueID,
            playerID * block.timestamp
        );
    }

    function rest(uint256 queueID, uint256 playerID)
        internal
        view
        returns (int8[3] memory stats)
    {
        string memory statToRest = QUEUE.getSubmissionOptions(
            queueID,
            playerID
        )[0];
        if (stringsMatch(statToRest, "Movement")) {
            stats[0] = 1;
        } else if (stringsMatch(statToRest, "Agility")) {
            stats[1] = 1;
        } else if (stringsMatch(statToRest, "Dexterity")) {
            stats[2] = 1;
        }
    }

    function drawCard(
        uint256 cardType,
        uint256 queueID,
        uint256 playerID
    )
        internal
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
        // get randomness from queue  QUEUE.randomness(queueID)
        // outputs should match up with what's returned from deck draw

        if (cardType == 1) {
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
            ) = EVENT_DECK.drawCard(
                QUEUE.randomness(queueID),
                playerRolls(queueID, playerID)
            );
        } else if (cardType == 2) {
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
            ) = AMBUSH_DECK.drawCard(
                QUEUE.randomness(queueID),
                playerRolls(queueID, playerID)
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
            ) = TREASURE_DECK.drawCard(
                QUEUE.randomness(queueID),
                playerRolls(queueID, playerID)
            );
        }
    }

    function attributeRoll(
        uint256 numDice,
        uint256 queueID,
        uint256 rollSeed
    ) public view returns (uint256 rollTotal) {
        uint8[] memory die = new uint8[](3);
        die[0] = 0;
        die[1] = 1;
        die[2] = 2;
        rollTotal = rollDice(queueID, die, numDice, rollSeed);
    }

    function d6Roll(
        uint256 numDice,
        uint256 queueID,
        uint256 rollSeed
    ) public view returns (uint256 rollTotal) {
        uint8[] memory die = new uint8[](6);
        die[0] = 1;
        die[1] = 2;
        die[2] = 3;
        die[3] = 4;
        die[4] = 5;
        die[5] = 6;
        rollTotal = rollDice(queueID, die, numDice, rollSeed);
    }

    function rollDice(
        uint256 queueID,
        uint8[] memory diceValues,
        uint256 diceQty,
        uint256 rollSeed
    ) internal view returns (uint256 rollTotal) {
        rollTotal = 0;
        uint256 randomness = QUEUE.randomness(queueID);
        for (uint256 i = 0; i < diceQty; i++) {
            rollTotal += diceValues[
                uint256(
                    keccak256(abi.encode(randomness, i * rollTotal, rollSeed))
                ) % diceValues.length
            ];
        }
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
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@luckymachines/game-core/contracts/src/v0.0/GameController.sol";
import "./HexplorationBoard.sol";
import "./HexplorationZone.sol";
import "./HexplorationQueue.sol";
import "./HexplorationStateUpdate.sol";
import "./state/CharacterCard.sol";
import "./tokens/TokenInventory.sol";

contract HexplorationController is GameController {
    // functions are meant to be called directly by players by default
    // we are adding the ability of a Controller Admin or Keeper to
    // execute the game aspects not directly controlled by players
    bytes32 public constant VERIFIED_CONTROLLER_ROLE =
        keccak256("VERIFIED_CONTROLLER_ROLE");

    HexplorationStateUpdate GAME_STATE;

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

    function setGameStateUpdate(address gsuAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        GAME_STATE = HexplorationStateUpdate(gsuAddress);
    }

    function addVerifiedController(address vcAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(VERIFIED_CONTROLLER_ROLE, vcAddress);
    }

    // Admin or Keeper Interactions

    function startGame(uint256 gameID, address boardAddress) public {
        HexplorationBoard board = HexplorationBoard(boardAddress);
        require(board.gameState(gameID) == 0, "game already started");

        PlayerRegistry pr = PlayerRegistry(board.prAddress());

        // Any registered player can start game once landing site has been set
        require(pr.isRegistered(gameID, msg.sender), "player not registered");
        board.lockRegistration(gameID);
        uint256 totalRegistrations = pr.totalRegistrations(gameID);

        string memory startZone = board.initialPlayZone(gameID);

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
        /*
        ti.ITEM_TOKEN().mint("Rusty Sword", gameID, 1000);
        ti.ITEM_TOKEN().mint("Rusty Rifle", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shiny Sword", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shiny Rifle", gameID, 1000);
        ti.ITEM_TOKEN().mint("Laser Sword", gameID, 1000);
        ti.ITEM_TOKEN().mint("Laser Rifle", gameID, 1000);
        ti.ITEM_TOKEN().mint("Glow stick", gameID, 1000);
        ti.ITEM_TOKEN().mint("Flashlight", gameID, 1000);
        ti.ITEM_TOKEN().mint("Flood light", gameID, 1000);
        ti.ITEM_TOKEN().mint("Nightvision Goggles", gameID, 1000);
        ti.ITEM_TOKEN().mint("Personal Shield", gameID, 1000);
        ti.ITEM_TOKEN().mint("Bubble Shield", gameID, 1000);
        ti.ITEM_TOKEN().mint("Frag Grenade", gameID, 1000);
        ti.ITEM_TOKEN().mint("Fire Grenade", gameID, 1000);
        ti.ITEM_TOKEN().mint("Shock Grenade", gameID, 1000);
        ti.ITEM_TOKEN().mint("HE Mortar", gameID, 1000);
        ti.ITEM_TOKEN().mint("Incendiary Mortar", gameID, 1000);
        ti.ITEM_TOKEN().mint("EMP Mortar", gameID, 1000);
        ti.ITEM_TOKEN().mint("Remote Launch and Guidance System", gameID, 1000);
        ti.ITEM_TOKEN().mint("Teleporter Pack", gameID, 1000);
        */
        ti.PLAYER_STATUS_TOKEN().mint("Stunned", gameID, 1000);
        ti.PLAYER_STATUS_TOKEN().mint("Burned", gameID, 1000);

        // Duplicate tokens, probably deprecating these?
        ti.ARTIFACT_TOKEN().mint("Engraved Tablet", gameID, 1000);
        ti.ARTIFACT_TOKEN().mint("Sigil Gem", gameID, 1000);
        ti.ARTIFACT_TOKEN().mint("Ancient Tome", gameID, 1000);

        ti.RELIC_TOKEN().mint("Relic 1", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 2", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 3", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 4", gameID, 1000);
        ti.RELIC_TOKEN().mint("Relic 5", gameID, 1000);
        // Transfer day token to board
        ti.DAY_NIGHT_TOKEN().transfer("Day", gameID, 0, 1, 1);

        for (uint256 i = 0; i < totalRegistrations; i++) {
            uint256 playerID = i + 1;
            address playerAddress = pr.playerAddress(gameID, playerID);
            board.enterPlayer(playerAddress, gameID, startZone);
            // Transfer campsite tokens to players
            ti.ITEM_TOKEN().transfer("Campsite", gameID, 0, playerID, 1);
        }
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
        q.startGame(qID);
    }

    //Player Interactions
    function registerForGame(uint256 gameID, address boardAddress) public {
        HexplorationBoard board = HexplorationBoard(boardAddress);
        board.registerPlayer(msg.sender, gameID);
        // TODO: set to official values
        CharacterCard(board.characterCard()).setStats(
            [4, 4, 4],
            gameID,
            PlayerRegistry(board.prAddress()).playerID(gameID, msg.sender)
        );
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
        HexplorationBoard board = HexplorationBoard(boardAddress);
        HexplorationQueue q = HexplorationQueue(board.gameplayQueue());
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        require(
            pr.playerAddress(gameID, playerID) == msg.sender,
            "PlayerID is not sender"
        );
        uint256 totalRegistrations = pr.totalRegistrations(gameID);
        uint256 qID = q.queueID(gameID);
        if (qID == 0) {
            qID = q.requestGameQueue(gameID, totalRegistrations);
        }
        require(qID != 0, "unable to set qID in controller");
        string memory cz = board.currentPlayZone(gameID, playerID);
        string[] memory newOptions;
        if (actionIndex == 4) {
            string memory phase = TokenInventory(board.tokenInventory())
                .DAY_NIGHT_TOKEN()
                .balance("Day", gameID, 1) > 0
                ? "Day"
                : "Night";
            // dig action, set options to # players on board
            uint256 activePlayersOnSpace = 0;
            for (uint256 i = 0; i < totalRegistrations; i++) {
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
            newOptions[0] = phase;
        } else {
            newOptions = options;
        }
        q.sumbitActionForPlayer(
            playerID,
            actionIndex,
            newOptions,
            leftHand,
            rightHand,
            qID
        );
    }

    function chooseLandingSite(
        string memory zoneChoice,
        uint256 gameID,
        address boardAddress
    ) public {
        // game rule: player 2 chooses on multiplayer game
        HexplorationBoard board = HexplorationBoard(boardAddress);
        PlayerRegistry pr = PlayerRegistry(board.prAddress());
        require(pr.isRegistered(gameID, msg.sender), "player not registered");

        if (pr.totalRegistrations(gameID) > 1) {
            require(
                pr.playerID(gameID, msg.sender) == 2,
                "P2 chooses landing site"
            );
        }
        board.enableZone(zoneChoice, HexplorationZone.Tile.LandingSite, gameID);
        // set landing site at space on board
        board.setInitialPlayZone(zoneChoice, gameID);

        //startGame(gameID, boardAddress);
    }

    // TODO: limit this to authorized game starters
    function requestNewGame(address gameRegistryAddress, address boardAddress)
        public
    {
        HexplorationBoard board = HexplorationBoard(boardAddress);
        board.requestNewGame(gameRegistryAddress);
    }

    function latestGame(address gameRegistryAddress, address boardAddress)
        public
        view
        returns (uint256)
    {
        return GameRegistry(gameRegistryAddress).latestGame(boardAddress);
    }

    // TODO: remove before launch
    // function getTestInventory(uint256 gameID, address boardAddress) public {
    //     // send some equippable items
    //     HexplorationBoard board = HexplorationBoard(boardAddress);
    //     TokenInventory ti = TokenInventory(board.tokenInventory());
    //     PlayerRegistry pr = PlayerRegistry(board.prAddress());
    //     ti.ITEM_TOKEN().transfer(
    //         "Shiny Rifle",
    //         gameID,
    //         0,
    //         pr.playerID(gameID, msg.sender),
    //         1
    //     );

    //     ti.ITEM_TOKEN().transfer(
    //         "Glow stick",
    //         gameID,
    //         0,
    //         pr.playerID(gameID, msg.sender),
    //         1
    //     );

    //     ti.ITEM_TOKEN().transfer(
    //         "Laser Dagger",
    //         gameID,
    //         0,
    //         pr.playerID(gameID, msg.sender),
    //         1
    //     );
    // }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import "@luckymachines/game-core/contracts/src/v0.0/custom_boards/HexGrid.sol";
import "./HexplorationZone.sol";

contract HexplorationBoard is HexGrid {
    // This role is a hybrid controller, assumes on chain verification of moves before submission

    uint256 private _randomness;
    HexplorationZone internal HEX_ZONE;
    address public characterCard;
    address public tokenInventory;
    address public gameplayQueue;
    // game ID => zone alias returns bool
    mapping(uint256 => mapping(string => bool)) public zoneEnabled;

    constructor(
        address adminAddress,
        uint256 gridWidth,
        uint256 gridHeight,
        address zoneAddress
    ) HexGrid(adminAddress, gridWidth, gridHeight, zoneAddress) {
        HEX_ZONE = HexplorationZone(zoneAddress);
    }

    function hexZoneAddress() public view returns (address) {
        return address(HEX_ZONE);
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

    function exitPlayer(
        address playerAddress,
        uint256 gameID,
        string memory zone
    ) external onlyRole(VERIFIED_CONTROLLER_ROLE) {
        HEX_ZONE.exitPlayer(playerAddress, gameID, zone);
    }

    function requestNewGame(address gameRegistryAddress)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        GameRegistry(gameRegistryAddress).registerGame();
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

    function setRandomness(uint256 randomness)
        external
        onlyRole(VERIFIED_CONTROLLER_ROLE)
    {
        _randomness = randomness;
    }

    function start(uint256 gameID) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        _gamesNeedUpdates.push(gameID);
    }

    function enableZone(
        string memory zoneAlias,
        HexplorationZone.Tile tile,
        uint256 gameID
    ) public onlyRole(VERIFIED_CONTROLLER_ROLE) {
        if (!zoneEnabled[gameID][zoneAlias]) {
            HEX_ZONE.setTile(tile, gameID, zoneAlias);
            zoneEnabled[gameID][zoneAlias] = true;
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
        returns (uint256[] memory)
    {
        uint256[] memory allGames = GameRegistry(gameRegistryAddress)
            .allGames();
        uint256 openGamesCount = 0;
        for (uint256 i = 0; i < allGames.length; i++) {
            uint256 gameID = allGames[i];

            if (
                PLAYER_REGISTRY.totalRegistrations(gameID) < 5 &&
                !PLAYER_REGISTRY.registrationLocked(gameID)
            ) {
                openGamesCount++;
            }
        }
        uint256 position = 0;
        uint256[] memory availableGames = new uint256[](openGamesCount);
        for (uint256 i = 0; i < allGames.length; i++) {
            uint256 gameID = allGames[i];
            if (
                PLAYER_REGISTRY.totalRegistrations(gameID) < 5 &&
                !PLAYER_REGISTRY.registrationLocked(gameID)
            ) {
                availableGames[position] = allGames[i];
                position++;
            }
        }
        return availableGames;
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
import "./GameBoard.sol";

// Registry is tied to one game board
// each registry can have custom rules for registration

contract PlayerRegistry is AccessControlEnumerable {
    bytes32 public constant GAME_BOARD_ROLE = keccak256("GAME_BOARD_ROLE");

    GameBoard internal GAME_BOARD;

    // Mappings from gameID
    //  or [game ID][player address]
    mapping(uint256 => mapping(address => bool)) public isRegistered;
    mapping(uint256 => mapping(address => uint256)) public playerID;
    mapping(uint256 => mapping(uint256 => address)) public playerAddress;
    mapping(uint256 => uint256) public totalRegistrations;
    mapping(uint256 => uint256) public registrationLimit;
    mapping(uint256 => bool) public registrationLocked;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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