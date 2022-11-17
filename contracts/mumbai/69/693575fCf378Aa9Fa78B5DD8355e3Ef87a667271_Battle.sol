// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./libraries/Trigonometry.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./interfaces/IMetadata.sol";
import "./VRFManager.sol";
import "./GameManager.sol";
import "./interfaces/ITerrain.sol";
import "./interfaces/ITanks.sol";
import "./interfaces/IAmmo.sol";
import "./interfaces/IScrap.sol";
import "./interfaces/IMedals.sol";
import "./Tag.sol";

/// @title Battle
/// @author Atlas C.O.R.P.

contract Battle is VRFManager, GameManager, AccessControlEnumerable {
    using SignedMath for int256;

    uint32 public constant NUMBER_OF_INITIAL_RANDOM_WORDS = 4;
    uint32 public constant NUMBER_OF_RANDOM_WORDS_FOR_FIRE = 5;
    uint256 public constant LEFT_WINDOW_OFFSET = 6;
    uint256 public constant RIGHT_WINDOW_OFFSET = 517;
    uint256 public constant WINDOW_WIDTH = 500;
    int256 public constant MAP_SCALE = 1000000; //1M
    int256 public constant MAX_POWER = 1000000; //1M
    uint256 public constant WINNER_SCRAP = 70 ether;
    uint256 public constant LOSER_SCRAP = 30 ether;
    uint256 public constant MEDAL_FOR_WINNER = 1;
    int256 public constant TRIG_COEFFICIENT = 32767;
    uint256 public constant MAX_TIME_STEPS = 4096;
    int256 public constant TANK_HEIGHT = 10000000; //10M
    int256 public constant ACCURACY_VARIANCE = 200;
    uint256 public constant MAX_MOVEMENT = 20;
    uint256 public constant GAS_PER_SPACE_MOVED = 1;
    uint256 public constant TIMEOUT = 3600;

    address public terrainContract;
    address public tankContract;
    address public ammoContract;
    address public scrapContract;
    address public medalsContract;
    address public metadataContract;

    bytes32 public constant GAME_MANAGER = keccak256("GAME_MANAGER");

    mapping(uint256 => uint256) public gameByRequestId;

    event GameSet(uint256 indexed gameId);
    event FireRequested(uint256 indexed gameId);
    event FireFulfilled(uint256 indexed gameId);
    event Move(uint256 indexed gameId);
    event GameOver(uint256 indexed gameId);
    event GameAbandoned(uint256 indexed gameId);

    constructor(
        address _terrainContract,
        address _tankContract,
        address _ammoContract,
        address _scrapContarct,
        address _medalsContarct,
        address _metadataContract,
        VRFManagerConstructorArgs memory _VRFManagerConstructorArgs
    ) VRFManager(_VRFManagerConstructorArgs) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        terrainContract = _terrainContract;
        tankContract = _tankContract;
        ammoContract = _ammoContract;
        scrapContract = _scrapContarct;
        medalsContract = _medalsContarct;
        metadataContract = _metadataContract;
    }

    /// @param _gameId is the number of the game
    /// @param _ammoType is the collection id
    /// @param _angle is the number of the angle
    /// @param _power is the number of the power
    function fire(
        uint256 _gameId,
        uint256 _ammoType,
        uint16 _angle,
        int256 _power
    ) public {
        if (gameData[_gameId].gameState == GameState.HOME) {
            if (gameData[_gameId].home.id == msg.sender) {
                gameData[_gameId].gameState = GameState.GETTING_HOME_VRF;
            } else if (
                (block.timestamp >=
                    gameData[_gameId].timeOfLastAction + TIMEOUT) &&
                gameData[_gameId].away.id == msg.sender
            ) {
                gameData[_gameId].gameState = GameState.GETTING_AWAY_VRF;
            } else {
                revert();
            }
        } else if (gameData[_gameId].gameState == GameState.AWAY) {
            if (gameData[_gameId].away.id == msg.sender) {
                gameData[_gameId].gameState = GameState.GETTING_AWAY_VRF;
            } else if (
                (block.timestamp >=
                    gameData[_gameId].timeOfLastAction + TIMEOUT) &&
                gameData[_gameId].home.id == msg.sender
            ) {
                gameData[_gameId].gameState = GameState.GETTING_HOME_VRF;
            } else {
                revert();
            }
        }

        require(
            _angle >= 0 && _angle < Trigonometry.ANGLES_IN_CYCLE,
            "fire: angle out of bounds"
        );
        require(
            _power > 0 && _power <= MAX_POWER,
            "fire: power must be greater than zero and no greater than max power"
        );

        IAmmo(ammoContract).shoot(msg.sender, _ammoType, 1);

        // request random words
        uint256 requestId = requestRandomWords(NUMBER_OF_RANDOM_WORDS_FOR_FIRE);
        gameByRequestId[requestId] = _gameId;

        gameData[_gameId].shot.power = _power;
        gameData[_gameId].shot.angle = _angle;
        gameData[_gameId].shot.ammoType = _ammoType;
        gameData[_gameId].shot.accuracy = 0;
        gameData[_gameId].timeOfLastAction = block.timestamp;

        emit FireRequested(_gameId);
    }

    function moveTank(uint256 gameId, int256 _numberOfSpaces) external {
        uint256 tankNumber;
        int256 tankPosition;
        int256 newTankPosition;

        if (gameData[gameId].gameState == GameState.HOME) {
            if (msg.sender == gameData[gameId].home.id) {
                tankNumber = gameData[gameId].home.tankNumber;
                tankPosition = gameData[gameId].home.location;
                newTankPosition = tankPosition + _numberOfSpaces;

                require(
                    newTankPosition >= 0 &&
                        newTankPosition <= ITerrain(terrainContract).width() - 1
                );

                gameData[gameId].home.location = newTankPosition;
                gameData[gameId].gameState == GameState.AWAY;
            } else if (
                (block.timestamp >=
                    gameData[gameId].timeOfLastAction + TIMEOUT) &&
                gameData[gameId].away.id == msg.sender
            ) {
                tankNumber = gameData[gameId].away.tankNumber;
                tankPosition = gameData[gameId].away.location;
                newTankPosition = tankPosition + _numberOfSpaces;

                require(
                    newTankPosition >= 0 &&
                        newTankPosition <= ITerrain(terrainContract).width() - 1
                );

                gameData[gameId].away.location = newTankPosition;
            } else {
                revert();
            }
        } else if (gameData[gameId].gameState == GameState.AWAY) {
            if (msg.sender == gameData[gameId].away.id) {
                tankNumber = gameData[gameId].away.tankNumber;
                tankPosition = gameData[gameId].away.location;
                newTankPosition = tankPosition + _numberOfSpaces;

                require(
                    newTankPosition >= 0 &&
                        newTankPosition <= ITerrain(terrainContract).width() - 1
                );

                gameData[gameId].away.location = newTankPosition;
                gameData[gameId].gameState == GameState.HOME;
            } else if (
                (block.timestamp >=
                    gameData[gameId].timeOfLastAction + TIMEOUT) &&
                gameData[gameId].home.id == msg.sender
            ) {
                tankNumber = gameData[gameId].home.tankNumber;
                tankPosition = gameData[gameId].home.location;
                newTankPosition = tankPosition + _numberOfSpaces;

                require(
                    newTankPosition >= 0 &&
                        newTankPosition <= ITerrain(terrainContract).width() - 1
                );

                gameData[gameId].home.location = newTankPosition;
            } else {
                revert();
            }
        } else {
            revert();
        }

        require(
            _numberOfSpaces.abs() <= MAX_MOVEMENT,
            "moveTank: cannot move more than max movement"
        );

        uint256 gasInTank = IMetadata(metadataContract).metadata(
            tankContract,
            tankNumber,
            "gas"
        );
        uint256 gasSpent = _numberOfSpaces.abs() * GAS_PER_SPACE_MOVED;

        require(
            gasInTank >= gasSpent,
            "moveTank: caller's tank does not have sufficient gas"
        );

        IMetadata(metadataContract).updateMetadataField(
            tankContract,
            tankNumber,
            "gas",
            gasInTank - gasSpent
        );

        gameData[gameId].timeOfLastAction = block.timestamp;
    }

    function playerCanSubmit(uint256 _gameId, address _player)
        public
        view
        returns (bool)
    {
        return
            (gameData[_gameId].gameState == GameState.HOME &&
                (gameData[_gameId].home.id == _player ||
                    ((block.timestamp >=
                        gameData[_gameId].timeOfLastAction + TIMEOUT) &&
                        gameData[_gameId].away.id == _player))) ||
            (gameData[_gameId].gameState == GameState.AWAY &&
                (gameData[_gameId].away.id == _player ||
                    ((block.timestamp >=
                        gameData[_gameId].timeOfLastAction + TIMEOUT) &&
                        gameData[_gameId].home.id == _player)));
    }

    function numSpacesPlayersCanMove(uint256 _gameId)
        public
        view
        returns (
            int256 homeLeft,
            int256 homeRight,
            int256 awayLeft,
            int256 awayRight
        )
    {
        uint256 homeGasInTank = IMetadata(metadataContract).metadata(
            tankContract,
            gameData[_gameId].home.tankNumber,
            "gas"
        );

        uint256 awayGasInTank = IMetadata(metadataContract).metadata(
            tankContract,
            gameData[_gameId].away.tankNumber,
            "gas"
        );

        int256 homeMaxMovementByGas = homeGasInTank >=
            MAX_MOVEMENT * GAS_PER_SPACE_MOVED
            ? int256(MAX_MOVEMENT)
            : int256(homeGasInTank / GAS_PER_SPACE_MOVED);

        int256 awayMaxMovementByGas = awayGasInTank >=
            MAX_MOVEMENT * GAS_PER_SPACE_MOVED
            ? int256(MAX_MOVEMENT)
            : int256(awayGasInTank / GAS_PER_SPACE_MOVED);

        homeLeft = gameData[_gameId].home.location - homeMaxMovementByGas < 0
            ? gameData[_gameId].home.location
            : homeMaxMovementByGas;

        homeRight = gameData[_gameId].home.location + homeMaxMovementByGas >
            ITerrain(terrainContract).width() - 1
            ? ITerrain(terrainContract).width() -
                1 -
                gameData[_gameId].home.location
            : homeMaxMovementByGas;
        awayLeft = gameData[_gameId].away.location - awayMaxMovementByGas < 0
            ? gameData[_gameId].away.location
            : awayMaxMovementByGas;
        awayRight = gameData[_gameId].away.location + awayMaxMovementByGas >
            ITerrain(terrainContract).width() - 1
            ? ITerrain(terrainContract).width() -
                1 -
                gameData[_gameId].away.location
            : awayMaxMovementByGas;
    }

    /// @param _tankNumber is the tank id
    function createGame(uint256 _tankNumber) public override {
        ITanks(tankContract).transferFrom(
            msg.sender,
            address(this),
            _tankNumber
        );
        super.createGame(_tankNumber);
    }

    /// @param _gameId is the game number
    /// @param _tankNumber is the tank id
    function joinGame(uint256 _gameId, uint256 _tankNumber) public override {
        ITanks(tankContract).transferFrom(
            msg.sender,
            address(this),
            _tankNumber
        );
        super.joinGame(_gameId, _tankNumber);
        initializeGame(_gameId);
    }

    function withdrawFromGame(uint256 _gameId) external {
        require(
            gameData[_gameId].gameState == GameState.CREATED,
            "withdrawFromGame: caller cannot withdraw in current state"
        );
        require(
            gameData[_gameId].home.id == msg.sender,
            "withdrawFromGame: caller must be home player to initiate withdraw"
        );
        ITanks(tankContract).safeTransferFrom(
            address(this),
            msg.sender,
            gameData[_gameId].home.tankNumber
        );
        gameData[_gameId].gameState = GameState.ABANDONED;
        emit GameAbandoned(_gameId);
    }

    function initializeGame(uint256 _gameId) private {
        gameData[_gameId].gameState = GameState.GETTING_INITIAL_VRF;
        gameData[_gameId].timeOfLastAction = block.timestamp;
        uint256 requestId = requestRandomWords(NUMBER_OF_INITIAL_RANDOM_WORDS);
        gameByRequestId[requestId] = _gameId;
    }

    function requestRandomWords(uint32 _numWords) private returns (uint256) {
        return
            COORDINATOR.requestRandomWords(
                keyHash,
                subscriptionId,
                requestConfirmations,
                callbackGasLimit,
                _numWords
            );
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 gameId = gameByRequestId[requestId];

        if (gameData[gameId].gameState == GameState.GETTING_INITIAL_VRF) {
            uint256 homeAssignment = randomWords[0] % 2;
            uint256 whoGoesFirst = randomWords[3] % 2;
            // left window 6-505
            // right window 517-1016
            if (homeAssignment == 0) {
                gameData[gameId].home.location = int256(
                    (randomWords[1] % WINDOW_WIDTH) + LEFT_WINDOW_OFFSET
                );
                gameData[gameId].away.location = int256(
                    (randomWords[2] % WINDOW_WIDTH) + RIGHT_WINDOW_OFFSET
                );
            } else {
                gameData[gameId].away.location = int256(
                    (randomWords[1] % WINDOW_WIDTH) + LEFT_WINDOW_OFFSET
                );
                gameData[gameId].home.location = int256(
                    (randomWords[2] % WINDOW_WIDTH) + RIGHT_WINDOW_OFFSET
                );
            }

            if (whoGoesFirst == 0) {
                gameData[gameId].gameState = GameState.HOME;
            } else {
                gameData[gameId].gameState = GameState.AWAY;
            }

            emit GameSet(gameId);
        } else if (gameData[gameId].gameState == GameState.GETTING_AWAY_VRF) {
            emit FireFulfilled(gameId);

            (uint16 adjustedAngle, int256 accuracy) = getAdjustedAngle(
                randomWords,
                gameData[gameId].shot.angle
            );

            gameData[gameId].shot.accuracy = accuracy;
            if (
                detectCollision(
                    Position({
                        x: gameData[gameId].away.location * MAP_SCALE,
                        y: ITerrain(terrainContract).terrain(
                            gameData[gameId].away.location
                        )
                    }),
                    Position({
                        x: gameData[gameId].home.location * MAP_SCALE,
                        y: ITerrain(terrainContract).terrain(
                            gameData[gameId].home.location
                        )
                    }),
                    adjustedAngle,
                    gameData[gameId].shot.power,
                    ITerrain(terrainContract).gravity()
                )
            ) {
                (, , uint256 damage, , ) = IAmmo(ammoContract).ammoTypes(
                    gameData[gameId].shot.ammoType
                );

                uint256 health = IMetadata(metadataContract).metadata(
                    tankContract,
                    gameData[gameId].home.tankNumber,
                    "health"
                );

                if (health > damage) {
                    IMetadata(metadataContract).updateMetadataField(
                        tankContract,
                        gameData[gameId].home.tankNumber,
                        "health",
                        health - damage
                    );
                    gameData[gameId].gameState = GameState.HOME;
                } else {
                    IMetadata(metadataContract).updateMetadataField(
                        tankContract,
                        gameData[gameId].home.tankNumber,
                        "health",
                        0
                    );
                    gameData[gameId].gameState = GameState.GAME_OVER;

                    emit GameOver(gameId);

                    ITanks(tankContract).destroyTank(
                        gameData[gameId].home.tankNumber
                    );

                    ITanks(tankContract).safeTransferFrom(
                        address(this),
                        gameData[gameId].away.id,
                        gameData[gameId].away.tankNumber
                    );

                    IScrap(scrapContract).collect(
                        gameData[gameId].away.id,
                        WINNER_SCRAP
                    );

                    IScrap(scrapContract).collect(
                        gameData[gameId].home.id,
                        LOSER_SCRAP
                    );

                    IMedals(medalsContract).awardMedal(
                        gameData[gameId].away.id,
                        MEDAL_FOR_WINNER
                    );
                }
            } else {
                gameData[gameId].gameState = GameState.HOME;
            }
        } else if (gameData[gameId].gameState == GameState.GETTING_HOME_VRF) {
            emit FireFulfilled(gameId);

            (uint16 adjustedAngle, int256 accuracy) = getAdjustedAngle(
                randomWords,
                gameData[gameId].shot.angle
            );

            gameData[gameId].shot.accuracy = accuracy;

            if (
                detectCollision(
                    Position({
                        x: gameData[gameId].home.location * MAP_SCALE,
                        y: ITerrain(terrainContract).terrain(
                            gameData[gameId].home.location
                        )
                    }),
                    Position({
                        x: gameData[gameId].away.location * MAP_SCALE,
                        y: ITerrain(terrainContract).terrain(
                            gameData[gameId].away.location
                        )
                    }),
                    adjustedAngle,
                    gameData[gameId].shot.power,
                    ITerrain(terrainContract).gravity()
                )
            ) {
                (, , uint256 damage, , ) = IAmmo(ammoContract).ammoTypes(
                    gameData[gameId].shot.ammoType
                );

                uint256 health = IMetadata(metadataContract).metadata(
                    tankContract,
                    gameData[gameId].away.tankNumber,
                    "health"
                );

                if (health > damage) {
                    IMetadata(metadataContract).updateMetadataField(
                        tankContract,
                        gameData[gameId].away.tankNumber,
                        "health",
                        health - damage
                    );
                    gameData[gameId].gameState = GameState.AWAY;
                } else {
                    IMetadata(metadataContract).updateMetadataField(
                        tankContract,
                        gameData[gameId].away.tankNumber,
                        "health",
                        0
                    );
                    gameData[gameId].gameState = GameState.GAME_OVER;

                    emit GameOver(gameId);

                    ITanks(tankContract).destroyTank(
                        gameData[gameId].away.tankNumber
                    );

                    ITanks(tankContract).safeTransferFrom(
                        address(this),
                        gameData[gameId].home.id,
                        gameData[gameId].home.tankNumber
                    );

                    IScrap(scrapContract).collect(
                        gameData[gameId].home.id,
                        WINNER_SCRAP
                    );

                    IScrap(scrapContract).collect(
                        gameData[gameId].away.id,
                        LOSER_SCRAP
                    );

                    IMedals(medalsContract).awardMedal(
                        gameData[gameId].home.id,
                        MEDAL_FOR_WINNER
                    );
                }
            } else {
                gameData[gameId].gameState = GameState.AWAY;
            }
        }
    }

    function getAdjustedAngle(uint256[] memory _randomWords, uint16 angle)
        public
        pure
        returns (uint16, int256)
    {
        int256 accuracy;
        for (uint256 i; i < 5; i++) {
            unchecked {
                accuracy += int256(_randomWords[i] % 3) - 1;
            }
        }
        accuracy = (accuracy * 16384) / ACCURACY_VARIANCE;
        unchecked {
            if (accuracy >= 0) {
                return (
                    uint16(
                        Trigonometry.bits(
                            angle + uint16(uint256(accuracy)),
                            14,
                            0
                        )
                    ),
                    accuracy
                );
            } else {
                return (
                    uint16(
                        Trigonometry.bits(
                            angle - uint16(uint256(accuracy * -1)),
                            14,
                            0
                        )
                    ),
                    accuracy
                );
            }
        }
    }

    /// @dev x position values must be scaled
    function detectCollision(
        Position memory _positionFire,
        Position memory _positionTarget,
        uint16 _angle,
        int256 _power,
        int256 _gravity
    ) public view returns (bool) {
        int256 x = _positionFire.x;
        int256 y = _positionFire.y;

        int256 Vx = _power * (Trigonometry.cos(_angle) / TRIG_COEFFICIENT);
        int256 Vy = _power * (Trigonometry.sin(_angle) / TRIG_COEFFICIENT);

        int256 tempX;
        int256 tempY;

        int256 maxX = ITerrain(terrainContract).width() * MAP_SCALE;

        for (uint256 i = 0; i < MAX_TIME_STEPS; i++) {
            tempX = x;
            tempY = y;

            x += Vx;
            y += Vy;
            Vy -= _gravity;
            if (x < 0 || x >= maxX) return false;
            else if ((x >= tempX && x <= x) || (x <= tempX && x >= x)) {
                if ((y >= tempY && y <= y) || (y <= tempY && y >= y)) {
                    return true;
                }
                return false;
            } else if (y <= int256(ITerrain(terrainContract).terrain(x))) {
                return false;
            }
        }
        return false;
    }

    /// @dev x position values must be scaled
    function drawPathX(
        Position memory _positionFire,
        Position memory _positionTarget,
        Shot calldata _shot,
        int256 _gravity
    ) public view returns (int256[] memory, uint256) {
        int256 Vx = (_shot.power * Trigonometry.cos(_shot.angle)) /
            TRIG_COEFFICIENT;
        int256 Vy = (_shot.power * Trigonometry.sin(_shot.angle)) /
            TRIG_COEFFICIENT;

        int256 tempX;
        int256 tempY;

        int256 maxX = ITerrain(terrainContract).width() * MAP_SCALE;

        int256[] memory pathX = new int256[](MAX_TIME_STEPS);

        uint256 i;
        for (; i < MAX_TIME_STEPS; ) {
            unchecked {
                tempX = _positionFire.x;
                tempY = _positionFire.y;

                pathX[i] = _positionFire.x;
                _positionFire.x += Vx;
                _positionFire.y += Vy;
                Vy -= _gravity;

                if (_positionFire.x < 0 || _positionFire.x >= maxX) break;
                else if (
                    (_positionTarget.x >= tempX &&
                        _positionTarget.x <= _positionFire.x) ||
                    (_positionTarget.x <= tempX &&
                        _positionTarget.x >= _positionFire.x)
                ) {
                    if (_positionTarget.y + TANK_HEIGHT >= tempY) {
                        i++;
                        break;
                    }
                }
                if (
                    _positionFire.y <=
                    ITerrain(terrainContract).terrain(
                        _positionFire.x / MAP_SCALE
                    )
                ) {
                    i++;
                    break;
                }
                i++;
            }
        }
        return (pathX, i);
    }

    function drawPathY(
        Position memory _positionFire,
        Position memory _positionTarget,
        Shot calldata _shot,
        int256 _gravity
    ) public view returns (int256[] memory, uint256) {
        int256 Vx = (_shot.power * Trigonometry.cos(_shot.angle)) /
            TRIG_COEFFICIENT;
        int256 Vy = (_shot.power * Trigonometry.sin(_shot.angle)) /
            TRIG_COEFFICIENT;

        int256 tempX;
        int256 tempY;

        int256 maxX = ITerrain(terrainContract).width() * MAP_SCALE;

        int256[] memory pathY = new int256[](MAX_TIME_STEPS);

        uint256 i;
        for (; i < MAX_TIME_STEPS; ) {
            unchecked {
                tempX = _positionFire.x;
                tempY = _positionFire.y;

                pathY[i] = _positionFire.y;
                _positionFire.x += Vx;
                _positionFire.y += Vy;
                Vy -= _gravity;

                if (_positionFire.x < 0 || _positionFire.x >= maxX) break;
                else if (
                    (_positionTarget.x >= tempX &&
                        _positionTarget.x <= _positionFire.x) ||
                    (_positionTarget.x <= tempX &&
                        _positionTarget.x >= _positionFire.x)
                ) {
                    if (_positionTarget.y + TANK_HEIGHT >= tempY) {
                        i++;
                        break;
                    }
                }
                if (
                    _positionFire.y <=
                    ITerrain(terrainContract).terrain(
                        _positionFire.x / MAP_SCALE
                    )
                ) {
                    break;
                }
                i++;
            }
        }
        return (pathY, i);
    }

    function cos(uint16 _angle) public pure returns (int256) {
        return Trigonometry.cos(_angle);
    }

    function sin(uint16 _angle) public pure returns (int256) {
        return Trigonometry.sin(_angle);
    }

    function setActive(bool _active) public override onlyRole(GAME_MANAGER) {
        super.setActive(_active);
    }

    /// @param _terrainContract is the address of the terrain contract
    function updateTerrainContract(address _terrainContract)
        external
        onlyRole(GAME_MANAGER)
    {
        terrainContract = _terrainContract;
    }

    /// @param _tankContract is the address of the tank contract
    function updateTankContract(address _tankContract)
        external
        onlyRole(GAME_MANAGER)
    {
        tankContract = _tankContract;
    }

    /// @param _ammoContract is the address of the ammo contract
    function updateAmmoContract(address _ammoContract)
        external
        onlyRole(GAME_MANAGER)
    {
        ammoContract = _ammoContract;
    }

    /// @param _scrapContract is the address of the scrap contract
    function updateScrapContract(address _scrapContract)
        external
        onlyRole(GAME_MANAGER)
    {
        scrapContract = _scrapContract;
    }

    /// @param _medalsContract is the address of the medals contract
    function updateMedalsContract(address _medalsContract)
        external
        onlyRole(GAME_MANAGER)
    {
        medalsContract = _medalsContract;
    }

    /// @param _metadataContract is the address of the metadata contract
    function updateMetadataContract(address _metadataContract)
        external
        onlyRole(GAME_MANAGER)
    {
        ammoContract = _metadataContract;
    }

    /// @param _subscriptionId is the Id from the Chainlink subscription manager
    function updateSubscriptionId(uint64 _subscriptionId)
        public
        override
        onlyRole(GAME_MANAGER)
    {
        super.updateSubscriptionId(_subscriptionId);
    }

    /// @param _keyHash is the keyhash from the Chainlink subscription manager
    function updateKeyHash(bytes32 _keyHash)
        public
        override
        onlyRole(GAME_MANAGER)
    {
        super.updateKeyHash(_keyHash);
    }

    function updateCallbackGasLimit(uint32 _callbackGasLimit)
        public
        override
        onlyRole(GAME_MANAGER)
    {
        super.updateCallbackGasLimit(_callbackGasLimit);
    }

    /// @param _requestConfirmations the confirmation number from the request
    function updateRequestConfirmations(uint16 _requestConfirmations)
        public
        override
        onlyRole(GAME_MANAGER)
    {
        super.updateRequestConfirmations(_requestConfirmations);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.17;

/**
 * Basic trigonometry functions
 *
 * Solidity library offering the functionality of basic trigonometry functions
 * with both input and output being integer approximated.
 *
 * This is useful since:
 * - At the moment no floating/fixed point math can happen in solidity
 * - Should be (?) cheaper than the actual operations using floating point
 *   if and when they are implemented.
 *
 * The implementation is based off Dave Dribin's trigint C library
 * http://www.dribin.org/dave/trigint/
 * Which in turn is based from a now deleted article which can be found in
 * the internet wayback machine:
 * http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 *
 * @author Lefteris Karapetsas
 *
 */
library Trigonometry {
    // Table index into the trigonometric table
    uint256 constant INDEX_WIDTH = 4;
    // Interpolation between successive entries in the tables
    uint256 constant INTERP_WIDTH = 8;
    uint256 constant INDEX_OFFSET = 12 - INDEX_WIDTH;
    uint256 constant INTERP_OFFSET = INDEX_OFFSET - INTERP_WIDTH;
    uint16 constant ANGLES_IN_CYCLE = 16384;
    uint16 constant QUADRANT_HIGH_MASK = 8192;
    uint16 constant QUADRANT_LOW_MASK = 4096;
    uint256 constant SINE_TABLE_SIZE = 16;

    // constant sine lookup table generated by gen_tables.py
    // We have no other choice but this since constant arrays don't yet exist
    uint8 constant entry_bytes = 2;
    bytes constant sin_table =
        "\x00\x00\x0c\x8c\x18\xf9\x25\x28\x30\xfb\x3c\x56\x47\x1c\x51\x33\x5a\x82\x62\xf1\x6a\x6d\x70\xe2\x76\x41\x7a\x7c\x7d\x89\x7f\x61\x7f\xff";

    /**
     * Convenience function to apply a mask on an integer to extract a certain
     * number of bits. Using exponents since solidity still does not support
     * shifting.
     *
     * @param _value The integer whose bits we want to get
     * @param _width The width of the bits (in bits) we want to extract
     * @param _offset The offset of the bits (in bits) we want to extract
     * @return An integer containing _width bits of _value starting at the
     *         _offset bit
     */
    function bits(
        uint256 _value,
        uint256 _width,
        uint256 _offset
    ) internal pure returns (uint256) {
        return (_value / (2**_offset)) & (((2**_width)) - 1);
    }

    function sin_table_lookup(uint256 index) internal pure returns (uint16) {
        bytes memory table = sin_table;
        uint256 offset = (index + 1) * entry_bytes;
        uint16 trigint_value;
        assembly {
            trigint_value := mload(add(table, offset))
        }

        return trigint_value;
    }

    /**
     * Return the sine of an integer approximated angle as a signed 16-bit
     * integer.
     *
     * @param _angle A 14-bit angle. This divides the circle into 16384
     *               angle units, instead of the standard 360 degrees.
     * @return The sine result as a number in the range -32767 to 32767.
     */
    function sin(uint16 _angle) public pure returns (int256) {
        uint256 interp = bits(_angle, INTERP_WIDTH, INTERP_OFFSET);
        uint256 index = bits(_angle, INDEX_WIDTH, INDEX_OFFSET);

        bool is_odd_quadrant = (_angle & QUADRANT_LOW_MASK) == 0;
        bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

        if (!is_odd_quadrant) {
            index = SINE_TABLE_SIZE - 1 - index;
        }

        uint256 x1 = sin_table_lookup(index);
        uint256 x2 = sin_table_lookup(index + 1);
        uint256 approximation = ((x2 - x1) * interp) / (2**INTERP_WIDTH);

        int256 sine;
        if (is_odd_quadrant) {
            sine = int256(x1) + int256(approximation);
        } else {
            sine = int256(x2) - int256(approximation);
        }

        if (is_negative_quadrant) {
            sine *= -1;
        }

        return sine;
    }

    /**
     * Return the cos of an integer approximated angle.
     * It functions just like the sin() method but uses the trigonometric
     * identity sin(x + pi/2) = cos(x) to quickly calculate the cos.
     */
    function cos(uint16 _angle) public pure returns (int256) {
        if (_angle > ANGLES_IN_CYCLE - QUADRANT_LOW_MASK) {
            _angle = QUADRANT_LOW_MASK + ANGLES_IN_CYCLE - _angle;
        } else {
            _angle += QUADRANT_LOW_MASK;
        }
        return sin(_angle);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract ITerrain {
    mapping(int256 => int256) public terrain;
    int256 public width;
    int256 public gravity;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

struct TankType {
    string name;
    string description;
    uint256 maxHealth;
    uint256 maxGas;
    uint256 accuracy;
    bool developed;
}

abstract contract ITanks is IAccessControlEnumerable, IERC721Enumerable {
    mapping(uint256 => TankType) public tankTypes;
    mapping(uint256 => uint256) public tankTypePerTokenId;
    uint256 public tankTypeCounter;

    function mint(address _destination, uint256 _tankType) external virtual;

    function destroyTank(uint256 _tankId) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IScrap is IERC20 {
    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function collect(address _destination, uint256 _amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract IMetadata {
    mapping(address => mapping(uint256 => mapping(string => uint256)))
        public metadata;
    mapping(address => string[]) public metadataFieldsByContract;
    mapping(address => mapping(string => bool))
        public metadataFieldsApprovedByContract;

    function updateMetadataField(
        address _contract,
        uint256 _tokenId,
        string calldata _field,
        uint256 _value
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IMedals is IERC1155, IAccessControlEnumerable {
    function awardMedal(address _destination, uint256 _tokenId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

struct AmmoType {
    bool developed;
    string name;
    uint256 damage;
    uint256 spread;
    uint256 weight;
}

abstract contract IAmmo is IERC1155, IAccessControlEnumerable {
    mapping(uint256 => AmmoType) public ammoTypes;
    uint256 public ammoTypeCounter;

    function mint(
        address _to,
        uint256 _id,
        uint256 _amount
    ) external virtual;

    function mintBatch(
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts
    ) external virtual;

    function shoot(
        address _from,
        uint256 _id,
        uint256 _amount
    ) external virtual;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

struct VRFManagerConstructorArgs {
    uint64 subscriptionId;
    address vrfCoordinator;
    bytes32 keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
}

contract VRFManager is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public COORDINATOR;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;

    constructor(VRFManagerConstructorArgs memory _VRFManagerConstructorArgs)
        VRFConsumerBaseV2(_VRFManagerConstructorArgs.vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(
            _VRFManagerConstructorArgs.vrfCoordinator
        );
        subscriptionId = _VRFManagerConstructorArgs.subscriptionId;
        keyHash = _VRFManagerConstructorArgs.keyHash;
        callbackGasLimit = _VRFManagerConstructorArgs.callbackGasLimit;
        requestConfirmations = _VRFManagerConstructorArgs.requestConfirmations;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        virtual
        override
    {}

    function updateSubscriptionId(uint64 _subscriptionId) public virtual {
        subscriptionId = _subscriptionId;
    }

    function updateKeyHash(bytes32 _keyHash) public virtual {
        keyHash = _keyHash;
    }

    function updateCallbackGasLimit(uint32 _callbackGasLimit) public virtual {
        callbackGasLimit = _callbackGasLimit;
    }

    function updateRequestConfirmations(uint16 _requestConfirmations)
        public
        virtual
    {
        require(
            _requestConfirmations >= 3,
            "updateRequestConfirmations: request confirmations must be at least 3"
        );
        requestConfirmations = _requestConfirmations;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//                      ---------------[ ]---------------
//                      -------[ ]-------------[ ]-------
//                      ---------------------------------
//                      ----[ ]--------[ ]--------[ ]----
//                      ---------------------------------
//                      -------[ ]-------------[ ]-------
//                      ---------------[ ]---------------

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct GameData {
    Player home;
    Player away;
    GameState gameState;
    Shot shot;
    uint256 timeOfLastAction;
}

struct Shot {
    int256 power;
    uint16 angle;
    uint256 ammoType;
    int256 accuracy;
}

struct Player {
    address id;
    uint256 tankNumber;
    int256 location;
    uint256 joinTime;
}

struct Position {
    int256 x;
    int256 y;
}

enum GameState {
    OFF,
    CREATED,
    GETTING_INITIAL_VRF,
    HOME,
    AWAY,
    GETTING_HOME_VRF,
    GETTING_AWAY_VRF,
    GAME_OVER,
    ABANDONED
}

contract GameManager {
    event GameCreated(uint256 indexed gameId);
    event GameJoined(uint256 indexed gameId);

    mapping(uint256 => GameData) public gameData;

    uint256 public gameCounter;
    bool public active;

    constructor() {
        active = true;
    }

    function createGame(uint256 _tankNumber) public virtual {
        gameCounter++;

        gameData[gameCounter].home.id = msg.sender;
        gameData[gameCounter].home.tankNumber = _tankNumber;
        gameData[gameCounter].home.joinTime = block.timestamp;
        gameData[gameCounter].gameState = GameState.CREATED;
        emit GameCreated(gameCounter);
    }

    function joinGame(uint256 _gameId, uint256 _tankNumber) public virtual {
        require(
            gameData[_gameId].home.id != msg.sender,
            "joinGame: caller cannot be the same as the home player"
        );
        require(
            gameData[_gameId].gameState == GameState.CREATED,
            "joinGame: game must be in created state"
        );

        gameData[gameCounter].away.id = msg.sender;
        gameData[gameCounter].away.tankNumber = _tankNumber;
        gameData[gameCounter].away.joinTime = block.timestamp;

        emit GameJoined(_gameId);
    }

    function setActive(bool _active) public virtual {
        active = _active;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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