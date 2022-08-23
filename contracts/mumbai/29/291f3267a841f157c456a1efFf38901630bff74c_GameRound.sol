// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;
import "@luckymachines/railway/contracts/Hub.sol";
import "@luckymachines/railway/contracts/RailYard.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./Questions.sol";
import "./ScoreKeeper.sol";
import "./GameController.sol";
import "./HivemindKeeper.sol";

contract GameRound is Hub, VRFConsumerBaseV2 {
    // VRF settings
    VRFCoordinatorV2Interface COORDINATOR;
    uint32 constant callbackGasLimit = 200000;
    uint64 s_subscriptionId;
    bytes32 keyHash;
    address vrfCoordinator;
    uint16 constant requestConfirmations = 3;
    uint32 constant numWords = 1;

    bytes32 public KEEPER_ROLE = keccak256("KEEPER_ROLE");

    // Mapping from request id
    mapping(uint256 => uint256) railcarRequestID;

    uint256 _queueType;

    uint256 constant maxRevealBonus = 1000;
    uint256 constant maxFastRevealBonus = 1000;
    uint256 constant submissionPoints = 100;
    uint256 constant winningPoints = 3000;
    string public hubName;
    string public nextRoundHub;
    uint256 public roundTimeLimit = 900; // in seconds (15 minute default)

    enum GamePhase {
        Pregame,
        Question,
        Reveal,
        Completed
    }

    Questions internal QUESTIONS;
    ScoreKeeper internal SCORE_KEEPER;
    GameController internal GAME_CONTROLLER;
    RailYard internal RAIL_YARD;
    HivemindKeeper internal HIVEMIND_KEEPER;

    // mapping from railcar ID
    mapping(uint256 => uint256) internal _gameID;

    // mapping from game ID
    mapping(uint256 => string) internal question;
    mapping(uint256 => string[4]) internal responses;
    mapping(uint256 => uint256[]) public winningChoiceIndex;
    mapping(uint256 => uint256) public roundStartTime;
    mapping(uint256 => uint256) public revealStartTime;
    mapping(uint256 => uint256[4]) public responseScores; // how many people chose each response
    mapping(uint256 => GamePhase) public phase;
    mapping(uint256 => uint256) public totalResponses;
    mapping(uint256 => uint256) public totalReveals;
    mapping(uint256 => uint256) public railcar;
    mapping(uint256 => uint256) public questionSeed;

    // from game ID => player
    mapping(uint256 => mapping(address => bytes32)) public hashedAnswer;
    mapping(uint256 => mapping(address => uint256)) public revealedIndex; // index of crowd guess
    mapping(uint256 => mapping(address => bool)) public answersRevealed;
    mapping(uint256 => mapping(address => bool)) public roundWinner;

    constructor(
        string memory thisHub,
        string memory nextHub,
        address questionsAddress,
        address scoreKeeperAddress,
        address gameControllerAddress,
        address railYardAddress,
        address hubRegistryAddress,
        address hubAdmin,
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subscriptionID
    ) Hub(hubRegistryAddress, hubAdmin) VRFConsumerBaseV2(_vrfCoordinator) {
        // VRF
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        s_subscriptionId = _subscriptionID;
        keyHash = _keyHash;
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName(thisHub, hubID);
        hubName = thisHub;
        nextRoundHub = nextHub;
        QUESTIONS = Questions(questionsAddress);
        SCORE_KEEPER = ScoreKeeper(scoreKeeperAddress);
        GAME_CONTROLLER = GameController(gameControllerAddress);
        RAIL_YARD = RailYard(railYardAddress);
    }

    function setHivemindKeeper(address hivemindKeeperAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        HIVEMIND_KEEPER = HivemindKeeper(hivemindKeeperAddress);
    }

    function setQueueType(uint256 queueType)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _queueType = queueType;
    }

    // Player functions
    function getQuestion(uint256 gameID)
        public
        view
        returns (string memory q, string[4] memory choices)
    {
        q = question[gameID];
        choices = responses[gameID];
    }

    function getResponseScores(uint256 gameID)
        public
        view
        returns (uint256[4] memory)
    {
        return responseScores[gameID];
    }

    function getWinningChoiceIndex(uint256 gameID)
        public
        view
        returns (uint256[] memory)
    {
        return winningChoiceIndex[gameID];
    }

    // submit answers (will be stored in secret)
    function submitAnswers(bytes32 _hashedAnswer, uint256 gameID) public {
        address player = tx.origin;
        require(playerIsInHub(gameID, player), "Player is not in this hub");
        require(
            phase[gameID] == GamePhase.Question,
            "Game not in question phase"
        );
        require(
            block.timestamp < roundStartTime[gameID] + roundTimeLimit,
            "Cannot submit answers. Round time limit has passed."
        );
        hashedAnswer[gameID][player] = _hashedAnswer;
        totalResponses[gameID]++;
        SCORE_KEEPER.increaseScore(submissionPoints, gameID, player);
        if (totalResponses[gameID] >= GAME_CONTROLLER.getPlayerCount(gameID)) {
            updatePhase(gameID);
        }
    }

    // reveal answers / first gets most points
    function revealAnswers(
        string memory questionAnswer,
        string memory crowdAnswer,
        string memory secretPhrase,
        uint256 gameID
    ) public {
        address player = tx.origin;
        require(playerIsInHub(gameID, player), "Player is not in this hub");
        require(phase[gameID] == GamePhase.Reveal, "Game not in reveal phase");
        require(
            !answersRevealed[gameID][player],
            "Player already revealed answers"
        );

        // These must be the exact same values as sent to submit answers or play is not valid
        bytes32 hashedReveal = keccak256(
            abi.encode(questionAnswer, crowdAnswer, secretPhrase)
        );
        bool hashesMatch = hashedAnswer[gameID][player] == hashedReveal;
        require(hashesMatch, "revealed answers don't match original answers");

        uint256 pIndex = indexOfResponse(gameID, questionAnswer);
        uint256 cIndex = indexOfResponse(gameID, crowdAnswer);
        if (pIndex < 4) {
            // if choice was valid, add to collective scores (player response counts)
            responseScores[gameID][pIndex] += 1;
            answersRevealed[gameID][player] = true;
            revealedIndex[gameID][player] = cIndex;
            uint256 timeSinceRevealStart = block.timestamp -
                revealStartTime[gameID];
            uint256 fastRevealBonus = maxFastRevealBonus > timeSinceRevealStart
                ? maxFastRevealBonus - timeSinceRevealStart
                : 0;
            SCORE_KEEPER.increaseScore(fastRevealBonus, gameID, player);
        }

        totalReveals[gameID]++;
        if (totalReveals[gameID] >= GAME_CONTROLLER.getPlayerCount(gameID)) {
            updatePhase(gameID);
        }
    }

    // Public functions

    function needsUpdate(uint256 gameID) public view returns (bool) {
        if (
            (phase[gameID] == GamePhase.Question &&
                block.timestamp >= (roundStartTime[gameID] + roundTimeLimit)) ||
            (phase[gameID] == GamePhase.Reveal &&
                block.timestamp >= (revealStartTime[gameID] + roundTimeLimit))
        ) {
            return true;
        } else {
            return false;
        }
    }

    function updatePhase(uint256 gameID) public {
        if (phase[gameID] == GamePhase.Question) {
            if (
                block.timestamp >= (roundStartTime[gameID] + roundTimeLimit) ||
                totalResponses[gameID] >= GAME_CONTROLLER.getPlayerCount(gameID)
            ) {
                revealStartTime[gameID] = block.timestamp;
                phase[gameID] = GamePhase.Reveal;
                GAME_CONTROLLER.revealStart(
                    hubName,
                    block.timestamp,
                    gameID,
                    GAME_CONTROLLER.getRailcarID(gameID)
                );
            }
        } else if (phase[gameID] == GamePhase.Reveal) {
            if (
                block.timestamp >= (revealStartTime[gameID] + roundTimeLimit) ||
                totalReveals[gameID] >= GAME_CONTROLLER.getPlayerCount(gameID)
            ) {
                uint256 railcarID = GAME_CONTROLLER.getRailcarID(gameID);
                phase[gameID] = GamePhase.Completed;

                // assign points to winners
                findWinners(railcarID);

                HIVEMIND_KEEPER.deregisterGameRound(
                    gameID,
                    HivemindKeeper.Queue(_queueType)
                );

                GAME_CONTROLLER.roundEnd(
                    hubName,
                    block.timestamp,
                    gameID,
                    railcarID
                );

                exitPlayersToNextRound(railcarID);
            }
        }
    }

    // VRF Functions
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 gameID = _gameID[railcarRequestID[requestId]];
        questionSeed[gameID] = randomWords[0];
        HIVEMIND_KEEPER.addActionToQueue(
            HivemindKeeper.Action.StartRound,
            HivemindKeeper.Queue(_queueType),
            gameID
        );
    }

    // Internal
    function _groupDidEnter(uint256 railcarID) internal override {
        super._groupDidEnter(railcarID);
        uint256 gameID = SCORE_KEEPER.gameIDFromRailcar(railcarID);
        _gameID[railcarID] = gameID;
        railcar[gameID] = railcarID;
        phase[gameID] = GamePhase.Question;
        SCORE_KEEPER.setLatestRound(hubName, gameID);
        roundStartTime[gameID] = block.timestamp;
        uint256 requestID = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        railcarRequestID[requestID] = railcarID;

        // Test with timestamp as faux randomness
        // questionSeed[gameID] = block.timestamp;
        // startNewRound(gameID);
    }

    // after randomness delivered...
    function startNewRound(uint256 gameID) public onlyRole(KEEPER_ROLE) {
        if (questionSeed[gameID] != 0) {
            (question[gameID], responses[gameID]) = QUESTIONS
                .getQuestionWithSeed(questionSeed[gameID]);

            HIVEMIND_KEEPER.registerGameRound(
                gameID,
                HivemindKeeper.Queue(_queueType)
            );

            GAME_CONTROLLER.roundStart(
                hubName,
                block.timestamp,
                gameID,
                railcar[gameID]
            );
        }
    }

    function exitPlayersToNextRound(uint256 railcarID) internal {
        _sendGroupToHub(railcarID, nextRoundHub);
    }

    function playerIsInHub(uint256 gameID, address playerAddress)
        internal
        view
        returns (bool)
    {
        return RAIL_YARD.isMember(railcar[gameID], playerAddress);
    }

    function indexOfResponse(uint256 gameID, string memory response)
        internal
        view
        returns (uint256 index)
    {
        index = 4; // this is returned if nothing matches
        if (!stringsMatch(response, "")) {
            if (stringsMatch(response, responses[gameID][0])) {
                index = 0;
            } else if (stringsMatch(response, responses[gameID][1])) {
                index = 1;
            } else if (stringsMatch(response, responses[gameID][2])) {
                index = 2;
            } else if (stringsMatch(response, responses[gameID][3])) {
                index = 3;
            }
        }
    }

    function stringsMatch(string memory s1, string memory s2)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(s1)) == keccak256(abi.encode(s2));
    }

    function findWinners(uint256 railcarID) internal {
        uint256 gameID = _gameID[railcarID];
        if (
            responseScores[gameID][0] >= responseScores[gameID][1] &&
            responseScores[gameID][0] >= responseScores[gameID][2] &&
            responseScores[gameID][0] >= responseScores[gameID][3]
        ) {
            winningChoiceIndex[gameID].push(0);
        }
        if (
            responseScores[gameID][1] >= responseScores[gameID][0] &&
            responseScores[gameID][1] >= responseScores[gameID][2] &&
            responseScores[gameID][1] >= responseScores[gameID][3]
        ) {
            winningChoiceIndex[gameID].push(1);
        }
        if (
            responseScores[gameID][2] >= responseScores[gameID][0] &&
            responseScores[gameID][2] >= responseScores[gameID][1] &&
            responseScores[gameID][2] >= responseScores[gameID][3]
        ) {
            winningChoiceIndex[gameID].push(2);
        }
        if (
            responseScores[gameID][3] >= responseScores[gameID][0] &&
            responseScores[gameID][3] >= responseScores[gameID][1] &&
            responseScores[gameID][3] >= responseScores[gameID][2]
        ) {
            winningChoiceIndex[gameID].push(3);
        }
        if (winningChoiceIndex[gameID].length == 0) {
            winningChoiceIndex[gameID].push(10);
        }

        address[] memory players = RAIL_YARD.getRailcarMembers(railcarID);
        if (winningChoiceIndex[gameID].length == 4) {
            // everyone wins
            for (uint256 i = 0; i < players.length; i++) {
                SCORE_KEEPER.increaseScore(winningPoints, gameID, players[i]);
                roundWinner[gameID][players[i]] = true;
            }
        } else if (winningChoiceIndex[gameID][0] == 10) {
            // no winning choice
        } else {
            for (uint256 i = 0; i < players.length; i++) {
                for (
                    uint256 j = 0;
                    j < winningChoiceIndex[gameID].length;
                    j++
                ) {
                    if (
                        revealedIndex[gameID][players[i]] ==
                        winningChoiceIndex[gameID][j]
                    ) {
                        SCORE_KEEPER.increaseScore(
                            winningPoints,
                            gameID,
                            players[i]
                        );
                        roundWinner[gameID][players[i]] = true;
                        break;
                    }
                }
            }
        }
    }

    // Admin functions

    function setQuestionsAddress(address questionsAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        QUESTIONS = Questions(questionsAddress);
    }

    function addKeeper(address keeperAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(KEEPER_ROLE, keeperAddress);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./HubRegistry.sol";

contract Hub is AccessControlEnumerable {
    // mapping from hub IDs
    mapping(uint256 => bool) public inputAllowed; // set other hubs to allow input
    mapping(uint256 => bool) public inputActive;
    uint256[] internal _hubInputs;
    uint256[] internal _hubOutputs;

    // mappings from user addresses
    mapping(address => bool) public userIsInHub;

    // mappings from railcar IDs
    mapping(uint256 => bool) public groupIsInHub;

    // or set it allow all inputs;
    bool public allowAllInputs;
    HubRegistry public REGISTRY;

    event UserDidExit(address indexed user);
    event UserDidEnter(address indexed user);
    event UserTransited(
        address indexed user,
        address indexed origin,
        address indexed destination
    );
    event GroupDidExit(uint256 indexed railcarID);
    event GroupDidEnter(uint256 indexed railcarID);
    event GroupTransited(
        uint256 indexed railcarID,
        address indexed origin,
        address indexed destination
    );

    modifier onlyAuthorizedHub() {
        require(
            allowAllInputs ||
                inputAllowed[REGISTRY.idFromAddress(_msgSender())],
            "hub not authorized"
        );
        _;
    }

    constructor(address hubRegistryAddress, address hubAdmin) {
        REGISTRY = HubRegistry(hubRegistryAddress);
        _register();
        _setupRole(DEFAULT_ADMIN_ROLE, hubAdmin);
    }

    function hubInputs() public view returns (uint256[] memory inputs) {
        inputs = _hubInputs;
    }

    function hubOutputs() public view returns (uint256[] memory outputs) {
        outputs = _hubOutputs;
    }

    // Hub to Hub communication
    function addInput() public onlyAuthorizedHub {
        // get hub ID of sender
        uint256 hubID = REGISTRY.idFromAddress(_msgSender());
        _hubInputs.push(hubID);
        inputActive[hubID] = true;
    }

    function enterUser(address userAddress) public virtual onlyAuthorizedHub {
        require(
            inputActive[REGISTRY.idFromAddress(_msgSender())],
            "origin hub not set as input"
        );
        require(_userCanEnter(userAddress), "user unable to enter");
        _userWillEnter(userAddress);
        _userDidEnter(userAddress);
    }

    function enterGroup(uint256 railcarID) public virtual onlyAuthorizedHub {
        require(
            inputActive[REGISTRY.idFromAddress(_msgSender())],
            "origin hub not set as input"
        );
        require(_groupCanEnter(railcarID), "group unable to enter");
        _groupWillEnter(railcarID);
        _groupDidEnter(railcarID);
    }

    function removeInput() external onlyAuthorizedHub {
        uint256 hubID = REGISTRY.idFromAddress(_msgSender());
        _hubInputs.push(hubID);
        //TODO: remove input
        inputActive[hubID] = false;
    }

    // Admin

    function setAllowAllInputs(bool allowAll)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        allowAllInputs = allowAll;
    }

    function setInputsAllowed(uint256[] memory hubIDs, bool[] memory allowed)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint256 i = 0; i < hubIDs.length; i++) {
            inputAllowed[hubIDs[i]] = allowed[i];
        }
    }

    function addHubConnections(uint256[] memory outputs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(_connectionHubsValid(outputs), "not all hub indeces valid");
        for (uint256 i = 0; i < outputs.length; i++) {
            // Set self as input on other hub
            Hub hub = Hub(REGISTRY.hubAddress(outputs[i]));
            hub.addInput();
            // Set outputs from this hub
            _hubOutputs.push(outputs[i]);
        }
    }

    function removeHubConnectionsTo(uint256[] memory connectedHubIDs)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        /* 
        Can only remove output connections originating from self
        Inputs must be removed from the outputting hub
        */

        for (uint256 i = 0; i < connectedHubIDs.length; i++) {
            Hub hub = Hub(REGISTRY.hubAddress(connectedHubIDs[i]));
            hub.removeInput();
            //TODO:
            // remove output from self - connectedHubIDs[i]
        }
    }

    // Override for custom behaviors
    function _userCanEnter(address userAddress)
        internal
        view
        virtual
        returns (bool)
    {
        if (!userIsInHub[userAddress]) {
            return true;
        } else {
            // user already in hub
            return false;
        }
    }

    function _userCanExit(address userAddress)
        internal
        view
        virtual
        returns (bool)
    {
        if (userIsInHub[userAddress]) {
            return true;
        } else {
            // user is not here, cannot exit
            return false;
        }
    }

    function _groupCanEnter(uint256 railcarID)
        internal
        view
        virtual
        returns (bool)
    {
        // todo: verify railcar ID is valid (sender is owner)
        // railcar passengers should all add themselves to car
        if (!groupIsInHub[railcarID]) {
            return true;
        } else {
            // group is already in hub
            return false;
        }
    }

    function _groupCanExit(uint256 railcarID)
        internal
        view
        virtual
        returns (bool)
    {
        if (groupIsInHub[railcarID]) {
            return true;
        } else {
            // group is not here, cannot exit
            return false;
        }
    }

    function _userWillEnter(address userAddress) internal virtual {}

    function _userDidEnter(address userAddress) internal virtual {
        emit UserDidEnter(userAddress);
        userIsInHub[userAddress] = true;
    }

    function _userWillExit(address userAddress) internal virtual {}

    function _userDidExit(address userAddress) internal virtual {
        emit UserDidExit(userAddress);
        userIsInHub[userAddress] = false;
    }

    function _groupWillEnter(uint256 railcarID) internal virtual {}

    function _groupDidEnter(uint256 railcarID) internal virtual {
        emit GroupDidEnter(railcarID);
        groupIsInHub[railcarID] = true;
    }

    function _groupWillExit(uint256 railcarID) internal virtual {}

    function _groupDidExit(uint256 railcarID) internal virtual {
        emit GroupDidExit(railcarID);
        groupIsInHub[railcarID] = false;
    }

    // Internal
    function _startUserHere(address userAddress) internal {
        require(_userCanEnter(userAddress), "user unable to enter");
        _userWillEnter(userAddress);
        _userDidEnter(userAddress);
    }

    function _sendUserToHub(address userAddress, uint256 hubID) internal {
        _userWillExit(userAddress);
        address hubAddress = REGISTRY.hubAddress(hubID);
        Hub(hubAddress).enterUser(userAddress);
        _userDidExit(userAddress);
        emit UserTransited(userAddress, address(this), hubAddress);
    }

    function _sendUserToHub(address userAddress, string memory hubName)
        internal
    {
        _userWillExit(userAddress);
        address hubAddress = REGISTRY.addressFromName(hubName);
        Hub(hubAddress).enterUser(userAddress);
        _userDidExit(userAddress);
        emit UserTransited(userAddress, address(this), hubAddress);
    }

    function _sendGroupToHub(uint256 railcarID, uint256 hubID) internal {
        require(_groupCanExit(railcarID), "group unable to exit");
        _groupWillExit(railcarID);
        address hubAddress = REGISTRY.hubAddress(hubID);
        Hub(hubAddress).enterGroup(railcarID);
        _groupDidExit(railcarID);
        emit GroupTransited(railcarID, address(this), hubAddress);
    }

    function _sendGroupToHub(uint256 railcarID, string memory hubName)
        internal
    {
        require(_groupCanExit(railcarID), "group unable to exit");
        _groupWillExit(railcarID);
        address hubAddress = REGISTRY.addressFromName(hubName);
        Hub(hubAddress).enterGroup(railcarID);
        _groupDidExit(railcarID);
        emit GroupTransited(railcarID, address(this), hubAddress);
    }

    function _register() internal {
        require(REGISTRY.hubCanRegister(address(this)), "can't register");
        REGISTRY.register();
    }

    function _connectionHubsValid(uint256[] memory outputs)
        internal
        view
        returns (bool isValid)
    {
        // checks that all IDs passed exist
        isValid = true;
        for (uint256 i = 0; i < outputs.length; i++) {
            if (REGISTRY.hubAddress(outputs[i]) == address(0)) {
                isValid = false;
                break;
            }
        }
    }

    function _isAllowedInput(uint256 hubID) internal view returns (bool) {
        Hub hubToCheck = Hub(REGISTRY.hubAddress(hubID));
        bool allowed = (hubToCheck.allowAllInputs() ||
            hubToCheck.inputAllowed(_hubID()))
            ? true
            : false;
        return allowed;
    }

    function _hubID() internal view returns (uint256) {
        return REGISTRY.idFromAddress(address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

// Members can join a group railcar
// or Hub can create one with specific addresses

contract RailYard is AccessControlEnumerable {
    struct Railcar {
        address[] members;
        uint256 memberLimit;
        address owner;
        address operator;
        uint256[] intStorage;
        string[] stringStorage;
    }

    // Mappings from railcar id
    mapping(uint256 => Railcar) public railcar;

    // Mapping from member address
    mapping(address => uint256[]) public railcars;
    mapping(address => uint256[]) public ownedRailcars;

    // Mapping from railcar id => member address
    mapping(uint256 => mapping(address => bool)) public isMember;
    mapping(uint256 => mapping(address => uint256)) public memberIndex;

    uint256 public totalRailcars;
    uint256 public creationFee;
    uint256 public storageFee;

    constructor(address adminAddress) {
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
    }

    function canCreateRailcar(address _address)
        public
        view
        returns (bool canCreate)
    {
        canCreate = _canCreate(_address);
    }

    function createRailcar(uint256 limit)
        public
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _msgSender(), limit);
        railcarID = totalRailcars;
    }

    function createRailcar(uint256 limit, uint256[] memory storageValues)
        public
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _msgSender(), limit, storageValues);
        railcarID = totalRailcars;
    }

    function createRailcar(address[] memory _members)
        external
        payable
        returns (uint256 railcarID)
    {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(_msgSender(), _msgSender(), _members.length, _members);
        railcarID = totalRailcars;
    }

    function createRailcar(
        address ownerAddress,
        address operatorAddress,
        uint256 limit
    ) public payable returns (uint256 railcarID) {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(ownerAddress, operatorAddress, limit);
        railcarID = totalRailcars;
    }

    function createRailcar(
        address ownerAddress,
        address operatorAddress,
        address[] memory _members
    ) external payable returns (uint256 railcarID) {
        require(_canCreate(_msgSender()), "Sender not qualified to create");
        require(msg.value >= creationFee, "Creation fee required");
        _createRailcar(
            ownerAddress,
            operatorAddress,
            _members.length,
            _members
        );
        railcarID = totalRailcars;
    }

    function getCreatedRailcars() public view returns (uint256[] memory) {
        return ownedRailcars[_msgSender()];
    }

    function getRailcars() public view returns (uint256[] memory) {
        return railcars[_msgSender()];
    }

    // Railcar summary functions
    // struct Railcar {
    //     address[] members;
    //     uint256 memberLimit;
    //     address owner;
    //     address operator;
    //     mapping(address => bool) isMember;
    //     mapping(address => uint256) memberIndex; // for removing members without looping
    //     uint256[] intStorage;
    //     string[] stringStorage;
    // }
    function getRailcarMembers(uint256 railcarID)
        public
        view
        returns (address[] memory)
    {
        return railcar[railcarID].members;
    }

    function getRailcarMemberLimit(uint256 railcarID)
        public
        view
        returns (uint256)
    {
        return railcar[railcarID].memberLimit;
    }

    function getRailcarOwner(uint256 railcarID) public view returns (address) {
        return railcar[railcarID].owner;
    }

    function getRailcarOperator(uint256 railcarID)
        public
        view
        returns (address)
    {
        return railcar[railcarID].operator;
    }

    function getRailcarIntStorage(uint256 railcarID)
        public
        view
        returns (uint256[] memory)
    {
        return railcar[railcarID].intStorage;
    }

    function getRailcarStringStorage(uint256 railcarID)
        public
        view
        returns (string[] memory)
    {
        return railcar[railcarID].stringStorage;
    }

    // Railcar Owner functions
    function setOperator(address operator, uint256 railcarID) public {
        Railcar storage r = railcar[railcarID];
        require(r.owner == _msgSender(), "only owner can assign operator");
        r.operator = operator;
    }

    // Railcar Owner / Operator functions
    function joinRailcar(uint256 railcarID, address userAddress) public {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can call joinRailcar directly"
        );
        _joinRailcar(railcarID, userAddress);
    }

    function leaveRailcar(uint256 railcarID, address userAddress) public {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can call leaveRailcar directly"
        );
        _leaveRailcar(railcarID, userAddress);
    }

    function addStorage(uint256 railcarID, string[] memory strings)
        public
        payable
    {
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can add storage"
        );
        require(msg.value >= storageFee, "Storage fee required");
        Railcar storage r = railcar[railcarID];
        r.stringStorage = strings;
    }

    function addStorage(uint256 railcarID, uint256[] memory ints)
        public
        payable
    {
        require(msg.value >= storageFee, "Storage fee required");
        require(
            railcar[railcarID].owner == _msgSender() ||
                railcar[railcarID].operator == _msgSender(),
            "only owner or operator can add storage"
        );
        Railcar storage r = railcar[railcarID];
        r.intStorage = ints;
    }

    // Admin
    function setCreationFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        creationFee = fee;
    }

    function setStorageFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        storageFee = fee;
    }

    // Internal
    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        uint256[] memory storageValues
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        r.intStorage = storageValues;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        string[] memory storageValues
    ) internal {
        totalRailcars++;
        Railcar storage r = railcar[totalRailcars];
        r.memberLimit = limit;
        r.owner = _ownerAddress;
        r.operator = _operatorAddress;
        r.stringStorage = storageValues;
        ownedRailcars[_ownerAddress].push(totalRailcars);
    }

    function _createRailcar(
        address _ownerAddress,
        address _operatorAddress,
        uint256 limit,
        address[] memory _members
    ) internal {
        // Create a railcar with members
        _createRailcar(_ownerAddress, _operatorAddress, limit);
        uint256 validMembers = limit < _members.length
            ? limit
            : _members.length;
        for (uint256 i = 0; i < validMembers; i++) {
            _joinRailcar(totalRailcars, _members[i]);
        }
    }

    function _canCreate(address creatorAddress)
        internal
        view
        virtual
        returns (bool canCreate)
    {
        canCreate = (creatorAddress == address(0)) ? false : true;
    }

    function _joinRailcar(uint256 railcarID, address userAddress) internal {
        if (!isMember[railcarID][userAddress]) {
            Railcar storage r = railcar[railcarID];
            r.members.push(userAddress);
            memberIndex[railcarID][userAddress] = r.members.length - 1;
            isMember[railcarID][userAddress] = true;
            railcars[userAddress].push(railcarID);
        }
    }

    function _leaveRailcar(uint256 railcarID, address userAddress) internal {
        if (!isMember[railcarID][userAddress]) {
            Railcar storage r = railcar[railcarID];
            delete r.members[memberIndex[railcarID][userAddress]];
            isMember[railcarID][userAddress] = false;
            memberIndex[railcarID][userAddress] = 0;
            // TODO:
            // delete from array of railcars - railcars[userAddress] will still have railcar ID
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

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract Questions is AccessControlEnumerable {
    bytes32 public GAME_ROUND_ROLE = keccak256("GAME_ROUND_ROLE");

    string[] private _questions;
    string[4][] private _responses;

    constructor(string[] memory questions, string[4][] memory responses) {
        require(
            questions.length == responses.length,
            "question + response length mismatch"
        );
        _questions = questions;
        _responses = responses;
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getQuestionWithSeed(uint256 seed)
        public
        view
        onlyRole(GAME_ROUND_ROLE)
        returns (string memory q, string[4] memory r)
    {
        uint256 index = seed % _questions.length;
        q = _questions[index];
        r = _responses[index];
    }

    // Admin
    function grantGameRoundRole(address gameRoundAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(GAME_ROUND_ROLE, gameRoundAddress);
    }

    function addQuestion(string memory question, string[4] memory responses)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _questions.push(question);
        _responses.push(responses);
    }

    function replaceQuestion(
        uint256 index,
        string memory question,
        string[4] memory responses
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(index < _questions.length, "index out of bounds of questions");
        _questions[index] = question;
        _responses[index] = responses;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Stores scores and game state for each player
// Only authorized game round contracts can update state

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "hardhat/console.sol";

contract ScoreKeeper is AccessControlEnumerable {
    bytes32 public SCORE_SETTER_ROLE = keccak256("SCORE_SETTER_ROLE");

    // Mapping from game ID
    mapping(uint256 => string) public latestRound;
    mapping(uint256 => uint256) public prizePool;
    // Mapping from game ID => player address
    mapping(uint256 => mapping(address => uint256)) public playerScore;
    // Mapping from player address
    mapping(address => uint256) public currentGameID;
    mapping(address => bool) public playerInActiveGame;
    // Mapping from railcar ID
    mapping(uint256 => uint256) public gameIDFromRailcar;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function grantScoreSetterRole(address scoreSetterAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(SCORE_SETTER_ROLE, scoreSetterAddress);
    }

    function increaseScore(
        uint256 points,
        uint256 gameID,
        address playerAddress
    ) external onlyRole(SCORE_SETTER_ROLE) {
        playerScore[gameID][playerAddress] += points;
    }

    function increasePrizePool(uint256 valueIncrease, uint256 gameID)
        external
        onlyRole(SCORE_SETTER_ROLE)
    {
        prizePool[gameID] += valueIncrease;
    }

    function setLatestRound(string memory hubName, uint256 gameID)
        external
        onlyRole(SCORE_SETTER_ROLE)
    {
        latestRound[gameID] = hubName;
    }

    function setGameID(uint256 gameID, address playerAddress)
        external
        onlyRole(SCORE_SETTER_ROLE)
    {
        currentGameID[playerAddress] = gameID;
        playerInActiveGame[playerAddress] = true;
    }

    function setGameID(
        uint256 gameID,
        address playerAddress,
        uint256 railcarID
    ) external onlyRole(SCORE_SETTER_ROLE) {
        currentGameID[playerAddress] = gameID;
        playerInActiveGame[playerAddress] = true;
        gameIDFromRailcar[railcarID] = gameID;
    }

    function removePlayerFromActiveGame(address playerAddress)
        external
        onlyRole(SCORE_SETTER_ROLE)
    {
        currentGameID[playerAddress] = 0;
        playerInActiveGame[playerAddress] = false;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@luckymachines/railway/contracts/HubRegistry.sol";
import "@luckymachines/railway/contracts/RailYard.sol";
import "./Lobby.sol";
import "./GameRound.sol";
import "./ScoreKeeper.sol";
import "./Winners.sol";

contract GameController is AccessControlEnumerable {
    Lobby internal LOBBY;
    ScoreKeeper internal SCORE_KEEPER;
    HubRegistry internal HUB_REGISTRY;
    RailYard internal RAIL_YARD;

    bytes32 public EVENT_SENDER_ROLE = keccak256("EVENT_SENDER_ROLE");

    event RoundStart(
        string hubAlias,
        uint256 startTime,
        uint256 gameID,
        uint256 groupID
    );

    event RevealStart(
        string hubAlias,
        uint256 startTime,
        uint256 gameID,
        uint256 groupID
    );

    event RoundEnd(
        string hubAlias,
        uint256 timestamp,
        uint256 gameID,
        uint256 groupID
    );

    event EnterWinners(uint256 timestamp, uint256 gameID, uint256 groupID);

    constructor(
        address lobbyAddress,
        address scoreKeeperAddress,
        address railYardAddress,
        address HubRegistryAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        LOBBY = Lobby(lobbyAddress);
        SCORE_KEEPER = ScoreKeeper(scoreKeeperAddress);
        RAIL_YARD = RailYard(railYardAddress);
        HUB_REGISTRY = HubRegistry(HubRegistryAddress);
    }

    // Player Interactions
    function joinGame() public payable {
        LOBBY.joinGame();
    }

    function submitAnswers(
        bytes32 _hashedAnswer,
        uint256 gameID,
        string memory hubAlias
    ) public {
        GameRound(HUB_REGISTRY.addressFromName(hubAlias)).submitAnswers(
            _hashedAnswer,
            gameID
        );
    }

    function revealAnswers(
        string memory questionAnswer,
        string memory crowdAnswer,
        string memory secretPhrase,
        uint256 gameID,
        string memory hubAlias
    ) public {
        GameRound(HUB_REGISTRY.addressFromName(hubAlias)).revealAnswers(
            questionAnswer,
            crowdAnswer,
            secretPhrase,
            gameID
        );
    }

    function checkPayout() public view returns (uint256 payoutAmount) {
        uint256 gameID = getCurrentGame(_msgSender());
        payoutAmount = _winnersHub().getPayoutAmount(
            gameID,
            getScore(gameID, _msgSender())
        );
    }

    function checkPayout(address playerAddress)
        public
        view
        returns (uint256 payoutAmount)
    {
        uint256 gameID = getCurrentGame(playerAddress);
        payoutAmount = _winnersHub().getPayoutAmount(
            gameID,
            getScore(gameID, playerAddress)
        );
    }

    function claimPrize(uint256 gameID, uint256 finalScore) public {
        _winnersHub().claimWinnings(gameID, finalScore);
    }

    function abandonActiveGame() public {
        SCORE_KEEPER.removePlayerFromActiveGame(_msgSender());
    }

    // Game Summary Functions
    // Player specific functions
    // called directly by player or by passing player address as last argument
    function getScore(uint256 gameID)
        public
        view
        returns (uint256 playerScore)
    {
        playerScore = SCORE_KEEPER.playerScore(gameID, _msgSender());
    }

    function getScore(uint256 gameID, address playerAddress)
        public
        view
        returns (uint256 playerScore)
    {
        playerScore = SCORE_KEEPER.playerScore(gameID, playerAddress);
    }

    function getIsInActiveGame() public view returns (bool inActiveGame) {
        inActiveGame = SCORE_KEEPER.playerInActiveGame(_msgSender());
    }

    function getIsInActiveGame(address playerAddress)
        public
        view
        returns (bool inActiveGame)
    {
        inActiveGame = SCORE_KEEPER.playerInActiveGame(playerAddress);
    }

    function getCurrentGame() public view returns (uint256 gameID) {
        gameID = SCORE_KEEPER.currentGameID(_msgSender());
    }

    function getCurrentGame(address playerAddress)
        public
        view
        returns (uint256 gameID)
    {
        gameID = SCORE_KEEPER.currentGameID(playerAddress);
    }

    function getCurrentGame(uint256 railcarID)
        public
        view
        returns (uint256 gameID)
    {
        gameID = SCORE_KEEPER.gameIDFromRailcar(railcarID);
    }

    function getFinalRanking(uint256 gameID)
        public
        view
        returns (uint256 rank)
    {
        rank = _winnersHub().getFinalRank(gameID, _msgSender());
    }

    function getFinalRanking(uint256 gameID, address playerAddress)
        public
        view
        returns (uint256 rank)
    {
        rank = _winnersHub().getFinalRank(gameID, playerAddress);
    }

    // Game specific functions
    function getPlayerCount(uint256 gameID)
        public
        view
        returns (uint256 playerCount)
    {
        playerCount = LOBBY.playerCount(gameID);
    }

    function getLatestRound(uint256 gameID)
        public
        view
        returns (string memory hubAlias)
    {
        hubAlias = SCORE_KEEPER.latestRound(gameID);
    }

    function getRailcarID(uint256 gameID)
        public
        view
        returns (uint256 railcarID)
    {
        railcarID = LOBBY.railcarID(gameID);
    }

    function getRailcarMembers(uint256 railcarID)
        public
        view
        returns (address[] memory members)
    {
        members = RAIL_YARD.getRailcarMembers(railcarID);
    }

    function getQuestion(string memory hubAlias, uint256 gameID)
        public
        view
        returns (string memory q, string[4] memory choices)
    {
        return
            GameRound(HUB_REGISTRY.addressFromName(hubAlias)).getQuestion(
                gameID
            );
    }

    function getPlayerGuess(
        string memory hubAlias,
        uint256 gameID,
        address playerAddress
    ) public view returns (uint256 guessIndex) {
        guessIndex = GameRound(HUB_REGISTRY.addressFromName(hubAlias))
            .revealedIndex(gameID, playerAddress);
    }

    function getResponseScores(string memory hubAlias, uint256 gameID)
        public
        view
        returns (uint256[4] memory responseScores)
    {
        responseScores = GameRound(HUB_REGISTRY.addressFromName(hubAlias))
            .getResponseScores(gameID);
    }

    function getWinningIndex(string memory hubAlias, uint256 gameID)
        public
        view
        returns (uint256[] memory winningIndex)
    {
        winningIndex = GameRound(HUB_REGISTRY.addressFromName(hubAlias))
            .getWinningChoiceIndex(gameID);
    }

    function getPrizePool(uint256 gameID) public view returns (uint256 pool) {
        pool = SCORE_KEEPER.prizePool(gameID);
    }

    // Event triggers
    function roundStart(
        string memory hubAlias,
        uint256 timestamp,
        uint256 gameID,
        uint256 railcarID
    ) external onlyRole(EVENT_SENDER_ROLE) {
        emit RoundStart(hubAlias, timestamp, gameID, railcarID);
    }

    function revealStart(
        string memory hubAlias,
        uint256 timestamp,
        uint256 gameID,
        uint256 railcarID
    ) external onlyRole(EVENT_SENDER_ROLE) {
        emit RevealStart(hubAlias, timestamp, gameID, railcarID);
    }

    function roundEnd(
        string memory hubAlias,
        uint256 timestamp,
        uint256 gameID,
        uint256 railcarID
    ) external onlyRole(EVENT_SENDER_ROLE) {
        emit RoundEnd(hubAlias, timestamp, gameID, railcarID);
    }

    function enterWinners(
        uint256 timestamp,
        uint256 gameID,
        uint256 railcarID
    ) external onlyRole(EVENT_SENDER_ROLE) {
        emit EnterWinners(timestamp, gameID, railcarID);
    }

    // Admin functions
    function addEventSender(address eventSenderAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(EVENT_SENDER_ROLE, eventSenderAddress);
    }

    // Internal functions
    function _winnersHub() internal view returns (Winners winnersHub) {
        winnersHub = Winners(HUB_REGISTRY.addressFromName("hivemind.winners"));
    }

    // set railcar operator to current hub at each entry
    // move railcar to next hub?
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "./GameRound.sol";
import "./Winners.sol";
import "./Lobby.sol";

contract HivemindKeeper is KeeperCompatibleInterface, AccessControlEnumerable {
    enum Queue {
        Lobby,
        Round1,
        Round2,
        Round3,
        Round4,
        Winners
    }
    enum Action {
        None,
        StartGame,
        StartRound,
        UpdatePhase,
        Clean,
        FindWinners
    }

    uint256 constant LOBBY_INDEX = 10000000000;
    uint256 constant ROUND_1_INDEX = 20000000000;
    uint256 constant ROUND_2_INDEX = 30000000000;
    uint256 constant ROUND_3_INDEX = 40000000000;
    uint256 constant ROUND_4_INDEX = 50000000000;
    uint256 constant WINNERS_INDEX = 60000000000;

    bytes32 public QUEUE_ROLE = keccak256("QUEUE_ROLE");

    uint256[][] private _completedUpdates;
    Lobby LOBBY;
    GameRound ROUND_1;
    GameRound ROUND_2;
    GameRound ROUND_3;
    GameRound ROUND_4;
    Winners WINNERS;
    // Mapping from Queue enum
    mapping(Queue => uint256[]) public queue; // index of games that need update
    mapping(Queue => uint256) public queueIndex; // index of queue to be passed for certain upkeeps
    // Mapping from Queue enum => game id
    mapping(Queue => mapping(uint256 => Action)) public action; // Action to be performed on queue for game
    uint256[2][] public registeredGameRounds;

    constructor(
        address lobbyAddress,
        address round1Address,
        address round2Address,
        address round3Address,
        address round4Address,
        address winnersAddress
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        LOBBY = Lobby(lobbyAddress);
        ROUND_1 = GameRound(round1Address);
        ROUND_2 = GameRound(round2Address);
        ROUND_3 = GameRound(round3Address);
        ROUND_4 = GameRound(round4Address);
        WINNERS = Winners(winnersAddress);
        queueIndex[Queue.Lobby] = LOBBY_INDEX;
        queueIndex[Queue.Round1] = ROUND_1_INDEX;
        queueIndex[Queue.Round2] = ROUND_2_INDEX;
        queueIndex[Queue.Round3] = ROUND_3_INDEX;
        queueIndex[Queue.Round4] = ROUND_4_INDEX;
        queueIndex[Queue.Winners] = WINNERS_INDEX;
    }

    function getQueue(uint256 queueType)
        public
        view
        returns (uint256[] memory)
    {
        return queue[Queue(queueType)];
    }

    // Queue Role functions
    function addActionToQueue(
        Action actionType,
        Queue queueType,
        uint256 gameID
    ) public onlyRole(QUEUE_ROLE) {
        _addActionToQueue(actionType, queueType, gameID);
    }

    function registerGameRound(uint256 gameID, Queue roundQueue)
        public
        onlyRole(QUEUE_ROLE)
    {
        registeredGameRounds.push([gameID, uint256(roundQueue)]);
    }

    function deregisterGameRound(uint256 gameID, Queue roundQueue)
        public
        onlyRole(QUEUE_ROLE)
    {
        int256 indexMatch = -1;
        for (uint256 i = 0; i < registeredGameRounds.length; i++) {
            if (
                registeredGameRounds[i][0] == gameID &&
                registeredGameRounds[i][1] == uint256(roundQueue)
            ) {
                indexMatch = int256(i);
                break;
            }
            if (registeredGameRounds[i][0] == 0) {
                break;
            }
        }
        if (indexMatch > -1) {
            uint256 index = uint256(indexMatch);
            //delete registeredGameRounds[index];

            for (uint256 j = index; j < registeredGameRounds.length - 1; j++) {
                registeredGameRounds[j] = registeredGameRounds[j + 1];
                if (registeredGameRounds[j][0] == 0 && gameID != 0) {
                    // we are past the end of the values we want
                    break;
                }
            }
            delete registeredGameRounds[registeredGameRounds.length - 1];
        }
    }

    // Chainlink Keeper functions
    function checkUpkeep(bytes calldata)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = false;
        performData = bytes("");
        Queue _queue;
        Action _action;
        uint256 _queueIndex;
        bool needsUpdate;
        uint256 gameID;
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Lobby
        );
        if (needsUpdate) {
            _queue = Queue.Lobby;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Round1
        );
        if (needsUpdate) {
            _queue = Queue.Round1;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Round2
        );
        if (needsUpdate) {
            _queue = Queue.Round2;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Round3
        );
        if (needsUpdate) {
            _queue = Queue.Round3;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Round4
        );
        if (needsUpdate) {
            _queue = Queue.Round4;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queueIndex, _action, gameID) = _queueNeedsUpdate(
            Queue.Winners
        );
        if (needsUpdate) {
            _queue = Queue.Winners;
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(_action),
                _queueIndex,
                gameID
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        (needsUpdate, _queue) = _queueNeedsClean();
        if (needsUpdate) {
            upkeepNeeded = true;
            performData = abi.encode(
                uint256(_queue),
                uint256(Action.Clean),
                0,
                0
            );
            // save everything to performData
            return (upkeepNeeded, performData);
        }
        // set check data to which queue to update from, which index
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 _queue;
        uint256 _action;
        uint256 _queueIndex;
        uint256 _gameID;
        (_queue, _action, _queueIndex, _gameID) = abi.decode(
            performData,
            (uint256, uint256, uint256, uint256)
        );
        Queue q = Queue(_queue);
        Action a = Action(_action);

        uint256[] memory newUpdate = new uint256[](4);
        newUpdate[0] = _queue;
        newUpdate[1] = _action;
        newUpdate[2] = _queueIndex;
        newUpdate[3] = _gameID;
        _completedUpdates.push(newUpdate);

        bool canUpdate = _verifyCanUpdate(q, a, _queueIndex, _gameID);
        if (canUpdate) {
            /* Possible Actions:
                StartGame,
                StartRound,
                StartReveal,
                EndRound,
                Clean,
                FindWinners
            */
            // do upkeep...
            if (q == Queue.Lobby) {
                // Lobby
                if (a == Action.StartGame) {
                    LOBBY.startGame();
                } else if (a == Action.Clean) {
                    // Clean Queue
                }
            } else if (q == Queue.Round1) {
                // Round 1
                if (a == Action.StartRound) {
                    ROUND_1.startNewRound(_gameID);
                } else if (a == Action.UpdatePhase) {
                    ROUND_1.updatePhase(_gameID);
                } else if (a == Action.Clean) {
                    // Clean Queue
                }
            } else if (q == Queue.Round2) {
                // Round 2
                if (a == Action.StartRound) {
                    // Start Round
                    ROUND_2.startNewRound(_gameID);
                } else if (a == Action.UpdatePhase) {
                    ROUND_2.updatePhase(_gameID);
                } else if (a == Action.Clean) {
                    // Clean Queue
                }
            } else if (q == Queue.Round3) {
                // Round 3
                if (a == Action.StartRound) {
                    // Start Round
                    ROUND_3.startNewRound(_gameID);
                } else if (a == Action.UpdatePhase) {
                    ROUND_3.updatePhase(_gameID);
                } else if (a == Action.Clean) {
                    // Clean Queue
                }
            } else if (q == Queue.Round4) {
                // Round 4
                if (a == Action.StartRound) {
                    // Start Round
                    ROUND_4.startNewRound(_gameID);
                } else if (a == Action.UpdatePhase) {
                    ROUND_4.updatePhase(_gameID);
                } else if (a == Action.Clean) {
                    // Clean Queue
                }
            } else if (q == Queue.Winners) {
                // Winners
                if (a == Action.FindWinners) {
                    // find winners
                } else if (a == Action.Clean) {
                    // clean queue
                }
            }
            // then reset queue
            if (_queueIndex < LOBBY_INDEX) {
                queue[q][_queueIndex] = 0;
            }
            action[q][_gameID] = Action.None;
        }
    }

    function getUpdates() public view returns (uint256[][] memory updates) {
        updates = _completedUpdates;
    }

    function keeperCanUpdate(bytes calldata performData)
        public
        view
        returns (bool)
    {
        uint256 _queue;
        uint256 _action;
        uint256 _queueIndex;
        uint256 _gameID;
        (_queue, _action, _queueIndex, _gameID) = abi.decode(
            performData,
            (uint256, uint256, uint256, uint256)
        );
        Queue q = Queue(_queue);
        Action a = Action(_action);

        return _verifyCanUpdate(q, a, _queueIndex, _gameID);
    }

    // Internal checks
    function _queueNeedsClean()
        internal
        view
        returns (bool needClean, Queue queueType)
    {
        // TODO: check if we want to clean any zero filled queues...
    }

    function _queueNeedsUpdate(Queue queueType)
        internal
        view
        returns (
            bool needsUpdate,
            uint256 index,
            Action queueAction,
            uint256 gameID
        )
    {
        needsUpdate = false;
        index = 0;
        queueAction = Action(0);
        // check for self-reported update needs first
        for (uint256 i = 0; i < queue[queueType].length; i++) {
            uint256 _gameID = queue[queueType][i];
            if (_gameID != 0) {
                needsUpdate = true;
                index = i;
                queueAction = action[queueType][_gameID];
                gameID = _gameID;
                break;
            }
        }
        if (needsUpdate) {
            return (needsUpdate, index, queueAction, gameID);
        }

        // then check for "stuck" contracts
        // Lobby
        if (LOBBY.canStart()) {
            needsUpdate = true;
            index = LOBBY_INDEX;
            queueAction = Action.StartGame;
            return (needsUpdate, index, queueAction, LOBBY.currentGame());
        }

        // Game Rounds
        for (uint256 i = 0; i < registeredGameRounds.length; i++) {
            if (
                registeredGameRounds[i][0] > 0 && registeredGameRounds[i][1] > 0
            ) {
                needsUpdate = _checkGameRoundNeedsUpdate(
                    registeredGameRounds[i][0],
                    Queue(registeredGameRounds[i][1])
                );
            }
            if (needsUpdate) {
                index = queueIndex[Queue(registeredGameRounds[i][1])];
                queueAction = Action.UpdatePhase;
                return (
                    needsUpdate,
                    index,
                    queueAction,
                    registeredGameRounds[i][0]
                );
            }
        }
    }

    function _checkGameRoundNeedsUpdate(uint256 gameID, Queue roundQueue)
        internal
        view
        returns (bool needsUpdate)
    {
        needsUpdate = false;
        if (roundQueue == Queue.Round1) {
            needsUpdate = ROUND_1.needsUpdate(gameID);
        } else if (roundQueue == Queue.Round2) {
            needsUpdate = ROUND_2.needsUpdate(gameID);
        } else if (roundQueue == Queue.Round3) {
            needsUpdate = ROUND_3.needsUpdate(gameID);
        } else if (roundQueue == Queue.Round4) {
            needsUpdate = ROUND_4.needsUpdate(gameID);
        }
    }

    function _verifyCanUpdate(
        Queue queueType,
        Action queueAction,
        uint256 _queueIndex,
        uint256 gameID
    ) internal view returns (bool canUpdate) {
        canUpdate = false;
        if (queueAction != Action.None) {
            if (_queueIndex == LOBBY_INDEX) {
                canUpdate = LOBBY.canStart();
            } else if (
                _queueIndex < LOBBY_INDEX &&
                queue[queueType][_queueIndex] != 0 &&
                queue[queueType][_queueIndex] == gameID
            ) {
                canUpdate = true;
            } else if (
                _queueIndex == ROUND_1_INDEX ||
                _queueIndex == ROUND_2_INDEX ||
                _queueIndex == ROUND_3_INDEX ||
                _queueIndex == ROUND_4_INDEX
            ) {
                // This can always be true, if not possible to update,
                // this will complete without updating anything
                // and be removed from the queue
                canUpdate = true;
            } else if (_queueIndex == WINNERS_INDEX) {
                // TODO:
                // Check if this can be updated...
                canUpdate = true;
            }
        }
    }

    function _addActionToQueue(
        Action actionType,
        Queue queueType,
        uint256 gameID
    ) internal {
        queue[queueType].push(gameID);
        action[queueType][gameID] = actionType;
    }

    // Admin Functions
    function addQueueRole(address queueRoleAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        grantRole(QUEUE_ROLE, queueRoleAddress);
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
pragma solidity ^0.8.6;

// NOTE:
/*
This is a simplified version of the registry for local testing only.
Official Hub Registries have been deployed to testnets so HubRegistry contracts 
should not be deployed. This registry does not encompass all of the complex
behavior of the official registry, though it is sufficient for local testing.
*/

import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "./ValidCharacters.sol";

contract HubRegistry is AccessControlEnumerableUpgradeable {
    bytes32 public HUB_ROLE;
    bytes32 public TRUST_SCORE_SETTER_ROLE;

    // Mappings from hub name
    mapping(string => address) public addressFromName;
    mapping(string => uint256) public idFromName;

    // Mappings from hub id
    mapping(uint256 => string) public hubName;
    mapping(uint256 => address) public hubAddress;
    mapping(uint256 => uint256) public trustScore;

    // Mapping from hub address
    mapping(address => bool) public isRegistered;
    mapping(address => uint256) public idFromAddress;

    uint256 public totalRegistrations;
    uint256 public registrationFee;
    uint256 public namingFee;

    ValidCharacters private VC;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address adminAddress, address validCharactersAddress)
        public
        initializer
    {
        HUB_ROLE = keccak256("HUB_ROLE");
        TRUST_SCORE_SETTER_ROLE = keccak256("TRUST_SCORE_SETTER_ROLE");
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        VC = ValidCharacters(validCharactersAddress);
    }

    function hubCanRegister(address _hubAddress)
        public
        view
        returns (bool canRegister)
    {
        canRegister = _canRegister(_hubAddress);
    }

    function nameIsAvailable(string memory _hubName)
        public
        view
        returns (bool available)
    {
        available = idFromName[_hubName] == 0 ? true : false;
    }

    function hubAddressesInRange(uint256 startingID, uint256 maxID)
        public
        view
        returns (address[] memory)
    {
        require(startingID <= totalRegistrations, "starting ID out of bounds");
        require(maxID >= startingID, "maxID < startingID");
        // require starting ID exists
        uint256 actualMaxID = maxID;
        uint256 size = actualMaxID - startingID + 1;
        address[] memory hubs = new address[](size);
        for (uint256 i = startingID; i < startingID + size; i++) {
            uint256 index = startingID - i;
            hubs[index] = hubAddress[i];
        }
        return hubs;
    }

    // Called directly from hub
    function register() external payable {
        require(_canRegister(_msgSender()), "Hub not qualified to register");
        require(msg.value >= registrationFee, "registration fee required");
        _register(_msgSender());
    }

    function setName(string memory _hubName, uint256 hubID)
        external
        payable
        onlyRole(HUB_ROLE)
    {
        require(VC.matches(_hubName));
        require(msg.value >= namingFee, "naming fee required");
        require(_msgSender() == hubAddress[hubID], "hubID for sender is wrong");
        require(nameIsAvailable(_hubName), "name unavailable");
        addressFromName[_hubName] = hubAddress[hubID];
        idFromName[_hubName] = hubID;
        hubName[hubID] = _hubName;
    }

    // Trust Score Setter
    function setTrustScore(uint256 score, uint256 hubID)
        external
        onlyRole(TRUST_SCORE_SETTER_ROLE)
    {
        trustScore[hubID] = score;
    }

    // Admin
    function setRegistrationFee(uint256 fee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        registrationFee = fee;
    }

    function setNamingFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registrationFee = fee;
    }

    // Internal
    function _register(address _hubAddress) internal {
        if (!isRegistered[_hubAddress]) {
            isRegistered[_hubAddress] = true;
            uint256 newID = totalRegistrations + 1; // IDs start @ 1
            totalRegistrations = newID;
            hubAddress[newID] = _hubAddress;
            idFromAddress[_hubAddress] = newID;
            _setupRole(HUB_ROLE, _hubAddress);
        }
    }

    function _canRegister(address _hubAddress)
        internal
        view
        virtual
        returns (bool canRegister)
    {
        canRegister = (_hubAddress == address(0)) ? false : true;
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract ValidCharacters {
    struct State {
        bool accepts;
        function(bytes1) internal pure returns (State memory) func;
    }

    string public constant regex = "[a-z0-9._-]+";

    function s0(bytes1 c) internal pure returns (State memory) {
        c = c;
        return State(false, s0);
    }

    function s1(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s2);
        }

        return State(false, s0);
    }

    function s2(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s3);
        }

        return State(false, s0);
    }

    function s3(bytes1 c) internal pure returns (State memory) {
        uint8 uc = uint8(c);
        if (
            uc == 45 ||
            uc == 46 ||
            (uc >= 48 && uc <= 57) ||
            uc == 95 ||
            (uc >= 97 && uc <= 122)
        ) {
            return State(true, s3);
        }

        return State(false, s0);
    }

    function matches(string memory input) public pure returns (bool) {
        State memory cur = State(false, s1);

        for (uint256 i = 0; i < bytes(input).length; i++) {
            bytes1 c = bytes(input)[i];

            cur = cur.func(c);
        }

        return cur.accepts;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
library EnumerableSetUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
interface IERC165Upgradeable {
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

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
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

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
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

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
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

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
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

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
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

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
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

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
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

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
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

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
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

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@luckymachines/railway/contracts/Hub.sol";
import "@luckymachines/railway/contracts/RailYard.sol";
import "hardhat/console.sol";
import "./ScoreKeeper.sol";
import "./GameRound.sol";

contract Lobby is Hub {
    ScoreKeeper private SCORE_KEEPER;
    RailYard private RAIL_YARD;
    address private _gameControllerAddress;
    uint256 private _currentGameID;
    bool private _needsNewGameID; // set to true when game has started

    uint256 public timeLimitToJoin = 300; // Countdown starts after 2nd player joins
    uint256 public playerLimit = 20; // game automatically starts if player limit reached
    uint256 public joinCountdownStartTime;
    string public gameHub;

    uint256 public entryFee;
    uint256 public adminFee;

    uint256 constant HUNDRED_YEARS = 3153600000;

    // Mapping from game id
    mapping(uint256 => uint256) public playerCount;
    mapping(uint256 => uint256) public railcarID;

    constructor(
        string memory hubName,
        address scoreKeeperAddress,
        address railYardAddress,
        string memory gameStartHub,
        address hubRegistryAddress,
        address hubAdmin
    ) Hub(hubRegistryAddress, hubAdmin) {
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName(hubName, hubID);
        inputAllowed[hubID] = true; // allow input from self to start railcars here
        SCORE_KEEPER = ScoreKeeper(scoreKeeperAddress);
        RAIL_YARD = RailYard(railYardAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _needsNewGameID = true;
        gameHub = gameStartHub;
        joinCountdownStartTime = block.timestamp + HUNDRED_YEARS;
    }

    function joinGame() public payable {
        address player = tx.origin;
        require(
            !SCORE_KEEPER.playerInActiveGame(player),
            "player already in game"
        );
        require(msg.value >= entryFee, "Minimum entry fee not sent");
        if (_needsNewGameID) {
            _currentGameID++;
            // Create railcar with game controller as owner, this as operator
            railcarID[_currentGameID] = RAIL_YARD.createRailcar(
                _gameControllerAddress,
                address(this),
                playerLimit
            );
            uint256 rid = railcarID[_currentGameID];
            uint256[] memory storageValues = new uint256[](1);
            storageValues[0] = _currentGameID;
            RAIL_YARD.createRailcar(4, storageValues);
            // Manually enter railcar since not receiving from any other hub
            if (_groupCanEnter(rid)) {
                _groupDidEnter(rid);
            }
            _needsNewGameID = false;
        }
        // add entry to pool and send to winners
        uint256 poolValue = msg.value > adminFee ? msg.value - adminFee : 0;
        if (poolValue > 0) {
            payable(REGISTRY.addressFromName("hivemind.winners")).transfer(
                poolValue
            );
            SCORE_KEEPER.increasePrizePool(poolValue, _currentGameID);
        }
        SCORE_KEEPER.setGameID(
            _currentGameID,
            player,
            railcarID[_currentGameID]
        );
        playerCount[_currentGameID]++;

        if (playerCount[_currentGameID] == 2) {
            joinCountdownStartTime = block.timestamp;
        }

        RAIL_YARD.joinRailcar(railcarID[_currentGameID], player);

        // auto-start game if at limit
        if (playerCount[_currentGameID] == playerLimit) {
            startGame();
        }
    }

    function canStart() public view returns (bool) {
        return _canStartGame();
    }

    function currentGame() public view returns (uint256) {
        return _currentGameID;
    }

    function startGame() public {
        require(_canStartGame(), "unable to start game");

        _sendGroupToHub(railcarID[_currentGameID], gameHub);
        _needsNewGameID = true;
        joinCountdownStartTime = block.timestamp + HUNDRED_YEARS;
    }

    // Admin functions
    function setGameControllerAddress(address gameControllerAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _gameControllerAddress = gameControllerAddress;
    }

    function setTimeLimitToJoin(uint256 timeInSeconds)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        timeLimitToJoin = timeInSeconds;
    }

    function setPlayerLimit(uint256 limit) public onlyRole(DEFAULT_ADMIN_ROLE) {
        playerLimit = limit;
    }

    function setEntryFee(uint256 newEntryFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        entryFee = newEntryFee;
    }

    function setAdminFee(uint256 newAdminFee)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        adminFee = newAdminFee;
    }

    function withdraw(address withdrawAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        payable(withdrawAddress).transfer(address(this).balance);
    }

    // Internal functions
    function _canStartGame() internal view returns (bool canStartGame) {
        canStartGame = false;
        if (
            block.timestamp >= (joinCountdownStartTime + timeLimitToJoin) ||
            playerCount[_currentGameID] >= playerLimit
        ) {
            if (!_needsNewGameID) {
                // if this is false we have an unstarted game
                // if true, _currentGameID will not be an active game
                canStartGame = true;
            }
        }
    }

    function _groupCanExit(uint256) internal pure override returns (bool) {
        return true;
    }
}

// join game
// move with group into round 1 when game is ready
// Max limit 1000

// Any group of players who enter this hub split the prize pool. If nobody wins, pool carries over to next game.
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@luckymachines/railway/contracts/Hub.sol";
import "./ScoreKeeper.sol";
import "./GameController.sol";
import "hardhat/console.sol";

contract Winners is Hub {
    bytes32 public GAME_ROUND_ROLE = keccak256("GAME_ROUND_ROLE");

    ScoreKeeper internal SCORE_KEEPER;
    GameController internal GAME_CONTROLLER;
    // mapping from game ID
    mapping(uint256 => uint256) public prizePoolPaidAmount;
    mapping(uint256 => bool) public gameHasWinnings; // true if game has available prize
    mapping(uint256 => uint256[]) public topScores;
    // mapping from game ID => player address
    mapping(uint256 => mapping(address => bool)) public playerPaid; // if player was paid for a given game
    // mapping from game ID => game score
    mapping(uint256 => mapping(uint256 => address[])) addressFromScore; // all addresses with given score

    constructor(
        string memory thisHub,
        address scoreKeeperAddress,
        address gameControllerAddress,
        address hubRegistryAddress,
        address hubAdmin
    ) Hub(hubRegistryAddress, hubAdmin) {
        uint256 hubID = REGISTRY.idFromAddress(address(this));
        REGISTRY.setName(thisHub, hubID);
        SCORE_KEEPER = ScoreKeeper(scoreKeeperAddress);
        GAME_CONTROLLER = GameController(gameControllerAddress);
    }

    function _groupDidEnter(uint256 railcarID) internal override {
        super._groupDidEnter(railcarID);
        uint256 gameID = SCORE_KEEPER.gameIDFromRailcar(railcarID);
        if (SCORE_KEEPER.prizePool(gameID) > 0) {
            gameHasWinnings[gameID] = true;
        }
        // Saves top scores + removes players from game
        saveTopScores(railcarID, gameID);
        GAME_CONTROLLER.enterWinners(block.timestamp, gameID, railcarID);
    }

    function getFinalRank(uint256 gameID, address playerAddress)
        public
        view
        returns (uint256 rank)
    {
        rank = 1;
        uint256 prevScore = 0;
        bool addressIsMatch = false;
        for (uint256 i = topScores[gameID].length - 1; i >= 0; i--) {
            uint256 score = topScores[gameID][i];
            if (score != prevScore) {
                for (
                    uint256 j = 0;
                    j < addressFromScore[gameID][score].length;
                    j++
                ) {
                    if (playerAddress == addressFromScore[gameID][score][j]) {
                        addressIsMatch = true;
                        break;
                    }
                }
                if (addressIsMatch) {
                    break;
                }
                rank++;
                prevScore = score;
            }
            if (i == 0) {
                break;
            }
        }
    }

    function playerHasScore(
        uint256 score,
        uint256 gameID,
        address playerAddress
    ) internal view returns (bool hasScore) {
        address[] memory scoreAddresses = addressFromScore[gameID][score];
        hasScore = false;
        for (uint256 i = 0; i < scoreAddresses.length; i++) {
            if (playerAddress == scoreAddresses[i]) {
                hasScore = true;
                break;
            }
        }
    }

    // User should call "getFinalRank" before calling this.
    // This function will waste gas if not in top 4 rank.
    function claimWinnings(uint256 gameID, uint256 finalScore) public {
        uint256 prizePool = SCORE_KEEPER.prizePool(gameID);
        require(prizePool > 0, "No prize pool for this game");
        address payable claimant = payable(tx.origin);
        require(
            !playerPaid[gameID][claimant],
            "player already paid for this game"
        );
        require(
            playerHasScore(finalScore, gameID, claimant),
            "incorrect player score submitted"
        );

        uint256 payoutAmount = getPayoutAmount(gameID, finalScore);

        // only payout what hasn't been paid from pool
        uint256 remainingPool = prizePool - prizePoolPaidAmount[gameID];
        if (payoutAmount > remainingPool) {
            payoutAmount = remainingPool;
        }
        claimant.transfer(payoutAmount);
        prizePoolPaidAmount[gameID] += payoutAmount;
        playerPaid[gameID][claimant] = true;
        if (prizePoolPaidAmount[gameID] >= prizePool) {
            gameHasWinnings[gameID] = false;
        }
    }

    function getPayoutAmount(uint256 gameID, uint256 finalScore)
        public
        view
        returns (uint256 payoutAmount)
    {
        payoutAmount = 0;
        uint256 prizePool = SCORE_KEEPER.prizePool(gameID);
        if (prizePool == 0) {
            return payoutAmount;
        }
        uint256 totalPlayers = GAME_CONTROLLER.getPlayerCount(gameID);
        uint256[] memory scores;
        if (totalPlayers == 2) {
            scores = new uint256[](2);
        } else if (totalPlayers == 3) {
            scores = new uint256[](3);
        } else if (totalPlayers > 3) {
            scores = new uint256[](4);
        }

        // create array of top scores [500,400,300,200]
        for (uint256 i = 0; i < scores.length; i++) {
            scores[i] = topScores[gameID][topScores[gameID].length - 1 - i];
        }

        uint256[] memory payoutTiers = new uint256[](scores.length);

        uint256 tier1Payouts = 1;
        uint256 tier2Payouts = 0;
        uint256 tier3Payouts = 0;
        uint256 tier4Payouts = 0;

        payoutTiers[0] = 1;
        for (uint256 i = 1; i < scores.length; i++) {
            if (scores[i] == scores[i - 1]) {
                payoutTiers[i] = payoutTiers[i - 1];
                if (payoutTiers[i] == 1) {
                    tier1Payouts++;
                } else if (payoutTiers[i] == 2) {
                    tier2Payouts++;
                } else if (payoutTiers[i] == 3) {
                    tier3Payouts++;
                }
            } else {
                payoutTiers[i] = payoutTiers[i - 1] + 1;
                if (payoutTiers[i] == 2) {
                    tier2Payouts++;
                } else if (payoutTiers[i] == 3) {
                    tier3Payouts++;
                } else if (payoutTiers[i] == 4) {
                    tier4Payouts++;
                }
            }
        }

        uint256[4] memory payoutAmounts;
        // Assuming 4 payouts...
        if (totalPlayers > 3) {
            if (tier1Payouts == 4) {
                // 1, 1, 1, 1
                payoutAmounts[0] = prizePool / 4;
                payoutAmounts[1] = prizePool / 4;
                payoutAmounts[2] = prizePool / 4;
                // payoutAmounts[3] = 25; // % (convert to actual numbers?)
            } else if (tier1Payouts == 3) {
                // 1, 1, 1, 2
                // 95% 1s, 5% 2
                payoutAmounts[0] = (prizePool * 10) / 32; //~31%
                payoutAmounts[1] = (prizePool * 10) / 32;
                payoutAmounts[2] = (prizePool * 10) / 32;
                // payoutAmounts[3] = 7;
            } else if (tier1Payouts == 2 && tier2Payouts == 2) {
                // 1, 1, 2, 2
                // 85% 1s, 15% 2s
                payoutAmounts[0] = (prizePool * 10) / 24;
                payoutAmounts[1] = (prizePool * 10) / 24;
                payoutAmounts[2] = prizePool / 12; // ~8%
                // payoutAmounts[3] = 8;
            } else if (tier1Payouts == 1 && tier2Payouts == 3) {
                // 1, 2, 2, 2
                // 70% 1s, 15% 2s
                payoutAmounts[0] = (prizePool * 10) / 14; //~70%
                payoutAmounts[1] = prizePool / 10;
                payoutAmounts[2] = prizePool / 10;
                // payoutAmounts[3] = 10;
            } else if (tier2Payouts == 2 && tier3Payouts == 1) {
                // 1, 2, 2, 3
                // 70% 1s, 25% 2s, 5% 3s
                payoutAmounts[0] = (prizePool * 10) / 14; //~70%
                payoutAmounts[1] = prizePool / 8;
                payoutAmounts[2] = prizePool / 8; // ~13%
                // payoutAmounts[3] = 4;
            } else if (tier2Payouts == 1 && tier3Payouts == 2) {
                // 1, 2, 3, 3
                // 70% 1s, 15% 2s, 15% 3s
                payoutAmounts[0] = (prizePool * 10) / 14; //~70%
                payoutAmounts[1] = prizePool / 6; // ~16%
                payoutAmounts[2] = prizePool / 14; // 7%
                // payoutAmounts[3] = 7;
            } else {
                // 1, 2, 3, 4
                // 70% 1s, 15% 2s, 10% 3s, 5% 4s
                payoutAmounts[0] = (prizePool * 10) / 14;
                payoutAmounts[1] = prizePool / 7; // ~14%
                payoutAmounts[2] = prizePool / 10;
                // payoutAmounts[3] = 5;
            }
            payoutAmounts[3] =
                prizePool -
                (payoutAmounts[0] + payoutAmounts[1] + payoutAmounts[2]);
        } else if (totalPlayers == 3) {
            if (tier1Payouts == 3) {
                //111
                payoutAmounts[0] = prizePool / 3;
                payoutAmounts[1] = prizePool / 3;
                // payoutAmounts[2] = 33;
            } else if (tier1Payouts == 2) {
                //112
                payoutAmounts[0] = (prizePool * 10) / 24; //~42%
                payoutAmounts[1] = (prizePool * 10) / 24; //~42%
                // payoutAmounts[2] = 16;
            } else if (tier2Payouts == 2) {
                //122
                payoutAmounts[0] = (prizePool * 10) / 14;
                payoutAmounts[1] = (prizePool * 10) / 67; //~15%
                // payoutAmounts[2] = 15;
            } else {
                //123
                payoutAmounts[0] = (prizePool * 10) / 14;
                payoutAmounts[1] = prizePool / 5;
                // payoutAmounts[2] = 10;
            }
            payoutAmounts[2] =
                prizePool -
                (payoutAmounts[0] + payoutAmounts[1]);
        } else if (totalPlayers == 2) {
            if (tier1Payouts == 2) {
                //1, 1
                payoutAmounts[0] = prizePool / 2;
                // payoutAmounts[1] = 50;
            } else {
                //1, 2
                payoutAmounts[0] = (prizePool * 10) / 14;
                // payoutAmounts[1] = 30;
            }
            payoutAmounts[1] = prizePool - payoutAmounts[0];
        }

        for (uint256 i = 0; i < scores.length; i++) {
            if (finalScore == scores[i]) {
                payoutAmount = payoutAmounts[i];
                break;
            }
        }
    }

    function saveTopScores(uint256 railcarID, uint256 gameID) public {
        // for each player, save mapping of score to their address
        address[] memory players = GAME_CONTROLLER.getRailcarMembers(railcarID);
        uint256[] memory allScores = new uint256[](players.length);
        for (uint256 i = 0; i < players.length; i++) {
            uint256 score = SCORE_KEEPER.playerScore(gameID, players[i]);
            allScores[i] = score;
            addressFromScore[gameID][score].push(players[i]);
            SCORE_KEEPER.removePlayerFromActiveGame(players[i]);
        }
        // sort scores
        quickSort(allScores, int256(0), int256(allScores.length - 1));
        topScores[gameID] = allScores;
    }

    function quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
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