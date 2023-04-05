// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title A contract that pays out prize to winner
/// @author Team 2
/// @notice you can use this contract for games with a pooled winnings/ high score format
/// @dev This contract collects payments for pay to play game that pays out proceeds to player with highest score
contract Prize {
    /// The current high score for the current game
    // TODO: Check if we can optimise.
    uint256 public highestScore;

    /// Fee paid for playing
    uint256 public fee;

    /// Collected pool of payments for playing the game and submitting high scores
    uint256 public prizePool;

    /// Timestamp of the game starting time and date
    // TODO: Check if we can optimise.
    uint256 public startTime;

    /// Address of owner to recieve winnings from prize pool
    address public winnerAddress;

    /// Duration of the game
    uint16 public duration;

    /// Game unique identificator.
    uint16 public gameId = 1;

    /// Flag indicating whether the lottery is open for bets or not
    bool public isOpen;

    /// Identifies recorded high score for specified address
    // TODO: Check if we can optimise.
    mapping(address => uint256) public highScores;

    /// Event that will be fired when an user succesfully claim winnings.
    event Claim(
        uint16 indexed gameId,
        address indexed player,
        uint256 indexed winnings
    );

    /// Event that will be fired when an user plays.
    event Play(uint16 indexed gameId, address player);

    /// Event that will be fired when an has a personal high score.
    event PersonalHighScore(
        uint16 indexed gameId,
        address indexed player,
        uint256 indexed score
    );

    /// Event that will be fired when somebody breaks current game high score.
    event GameHighScore(
        uint16 indexed gameId,
        address indexed player,
        uint256 indexed score
    );

    /// Event that will be fired when a game is started.
    event Start(
        uint16 indexed gameId,
        address indexed starter,
        uint256 indexed timestamp
    );

    /// Event that will be fired when a game is ended.
    event End(
        uint16 indexed gameId,
        address indexed ender,
        uint256 indexed timestamp
    );

    constructor(uint16 _duration, uint256 _fee) {
        duration = _duration;
        fee = _fee;
    }

    /// Modifier that will check that a game is open.
    modifier mustBeOpen() {
        require(startTime != 0 && isOpen, "Game must be open.");
        require(block.timestamp < startTime + duration, "Game must be open.");
        _;
    }

    /// Modifier that will check that a game is closed.
    modifier mustBeClosed() {
        require(block.timestamp > startTime + duration, "Game must be closed.");
        _;
    }

    /// Modifier that will give a grace period for the winner to withdraw funds of 2 * duration.
    modifier gracePeriod() {
        require(
            msg.sender == winnerAddress ||
                block.timestamp > startTime + 2 * duration,
            "Grace period for the winner still running."
        );
        _;
    }

    /// Player pays a fee in order to play. The fee goes to the prize pool.
    function play() public payable {
        // If there's no current game, start one.
        if (startTime == 0 && !isOpen) {
            // Set game as open, mark starting timestamp, emit event and increment game id for next game.
            isOpen = true;
            startTime = block.timestamp;
            emit Start(gameId, msg.sender, block.timestamp);
            gameId++;
        }

        // To play, game must be open.
        require(
            isOpen && block.timestamp < startTime + duration,
            "Game must be open."
        );

        // Revert if the value is not equal to the fee.
        require(msg.value == fee, "Only the fee should be payed.");
        // Add fee to the prize pool.
        prizePool += msg.value;
        emit Play(gameId, msg.sender);
    }

    /// Player can submit his score after playing the game.
    function submitScore(uint256 score) public mustBeOpen {
        // Check if it's a personal high score to update it.
        if (score > highScores[msg.sender]) {
            highScores[msg.sender] = score;
            emit PersonalHighScore(gameId, msg.sender, score);
        }

        // Check if it's a game highest score.
        if (score > highestScore) {
            winnerAddress = msg.sender;
            highestScore = score;
            emit GameHighScore(gameId, msg.sender, score);
        }
    }

    function claim() public mustBeClosed gracePeriod {
        // Set prize pool to zero before transferring.
        uint256 bal = prizePool;
        prizePool = 0;

        // Send ether
        (bool sent, ) = msg.sender.call{value: bal}("");
        require(sent, "Failed to send Ether");
        emit Claim(gameId, msg.sender, prizePool);

        // End game
        startTime = 0;
        isOpen = false;
        highestScore = 0;
        winnerAddress = address(0);

        emit End(gameId, msg.sender, block.timestamp);
    }
}