// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./AccessControlEnumerable.sol";
import "./IOracle.sol";
import "./VRFManager.sol";
import "./GameManager.sol";

contract CoinFlip is AccessControlEnumerable, GameManager, VRFManager {
    mapping(uint256 => uint256) public gameByRequestId;

    uint256 public houseBalance;
    uint256 public houseHold;

    uint256 public constant RESERVE_RATIO = 6;

    event GameCreated(uint256 indexed gameId);
    event GameCompleted(uint256 indexed gameId);
    event GameVoid(uint256 indexed gameId);
    event HouseDeposit(uint256 _amount);
    event HouseWithdraw(uint256 _amount);

    constructor(
        address _oracleContract,
        uint256 _minimumAnte,
        uint256 _maximumAnte
    ) GameManager(_minimumAnte, _maximumAnte) VRFManager(_oracleContract) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(
            GAME_MANAGER_ROLE,
            0x012e8326acd4CF9DBBCa78f082a1A1C01ed2192F
        );
        grantRole(GAME_MANAGER_ROLE, msg.sender);
    }

    function startGame(Outcome _guess) external payable {
        require(active, "startGame: game contract must be active to play");
        require(_guess != Outcome.NOT_SET, "startGame: cannot guess 0");

        require(
            msg.value >= minimumAnte,
            "startGame: ante must be greater than or equal to the minimumAnte"
        );
        require(
            msg.value <= maximumAnte,
            "startGame: ante must be greater than or equal to the maximumAnte"
        );

        uint256 houseRequirement = msg.value * RESERVE_RATIO;

        require(
            playerInGame[msg.sender] == 0,
            "playerInGame: player already in game"
        );

        houseBalance -= houseRequirement;

        unchecked {
            houseHold += houseRequirement;
        }

        initializeGameData(msg.sender, msg.value, _guess);

        emit GameCreated(gameCounter);

        _getRandomNumber();
    }

    /// @notice getting random number
    function _getRandomNumber() private {
        gameData[gameCounter].gameState = GameState.GETTING_VRF;

        // requesting random words from VRF
        uint256 requestId = IOracle(VRFOracleContract).requestRandomWords(1);

        gameByRequestId[requestId] = gameCounter;
    }

    /**
     * @notice Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) internal override {
        _endGame(gameByRequestId[_requestId], (_randomWords[0] % 1000));
    }

    /**
     * @notice ends the game
     * @param _gameId is the game number
     * @param _randomNumber is the random number from VRF
     */
    function _endGame(uint256 _gameId, uint256 _randomNumber) private {
        gameData[gameCounter].gameState = GameState.COMPLETED;

        if (_randomNumber < 475) {
            gameData[_gameId].outcome = Outcome.HEADS;
        } else if (_randomNumber < 950) {
            gameData[_gameId].outcome = Outcome.TAILS;
        } else {
            gameData[_gameId].outcome = Outcome.SIDE;
        }

        // log winner
        if (gameData[_gameId].chosen == gameData[_gameId].outcome) {
            // player wins
            gameData[_gameId].winner = Winner.PLAYER;
            if (
                gameData[_gameId].outcome == Outcome.HEADS ||
                gameData[_gameId].outcome == Outcome.TAILS
            ) {
                // payout if player guesses right on heads or tails
                require(
                    payable(gameData[_gameId].player).send(
                        gameData[_gameId].ante * 2
                    )
                );

                houseHold -= gameData[_gameId].ante * RESERVE_RATIO;

                houseBalance += gameData[_gameId].ante * (RESERVE_RATIO - 1);

                // payout if player wins the side bet
            } else {
                require(
                    payable(gameData[_gameId].player).send(
                        gameData[_gameId].ante +
                            (gameData[_gameId].ante * RESERVE_RATIO)
                    )
                );

                houseHold -= gameData[_gameId].ante * RESERVE_RATIO;
            }
        } else {
            gameData[_gameId].winner = Winner.HOUSE;

            houseHold -= gameData[_gameId].ante * RESERVE_RATIO;
            houseBalance +=
                gameData[_gameId].ante +
                (gameData[_gameId].ante * RESERVE_RATIO);
        }

        _removePlayerFromGame(gameData[_gameId].player);

        emit GameCompleted(gameCounter);
    }

    /// @notice This function deposits to the HOUSE BALANCE.
    /// @dev This will not credit your balance for sender.
    function houseDeposit() external payable {
        houseBalance += msg.value;

        emit HouseDeposit(msg.value);
    }

    /// @notice This function withdraws from the HOUSE BALANCE.
    /// @dev only game manager role can call this function
    /// @param _amount how many tokens the house would like to withdraw
    /// @param _destination the wallet address which you would like to send the funds to
    function houseWithdraw(
        address _destination,
        uint256 _amount
    ) external onlyRole(GAME_MANAGER_ROLE) {
        houseBalance -= _amount;
        require(payable(_destination).send(_amount));
        emit HouseWithdraw(_amount);
    }

    function voidGame(uint256 _gameId) external onlyRole(GAME_MANAGER_ROLE) {
        _voidGame(_gameId);
        houseHold -= gameData[_gameId].ante * RESERVE_RATIO;
        houseBalance += gameData[_gameId].ante * RESERVE_RATIO;
        require(payable(gameData[_gameId].player).send(gameData[_gameId].ante));
        emit GameVoid(_gameId);
    }

    /// @notice enables the contract to be used
    function toggleOn() external onlyRole(GAME_MANAGER_ROLE) {
        _toggleOn();
    }

    /// @notice pauses the contract from use
    function toggleOff() external onlyRole(GAME_MANAGER_ROLE) {
        _toggleOff();
    }

    /// @notice enables the contract to be used
    function setMinimumAnte(
        uint256 _minimumAnte
    ) external onlyRole(GAME_MANAGER_ROLE) {
        _setMinimumAnte(_minimumAnte);
    }

    /// @notice enables the contract to be used
    function setMaximumAnte(
        uint256 _maximumAnte
    ) external onlyRole(GAME_MANAGER_ROLE) {
        _setMaximumAnte(_maximumAnte);
    }
}