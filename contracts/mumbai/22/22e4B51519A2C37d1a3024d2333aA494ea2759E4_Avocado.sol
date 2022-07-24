// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Avocado {

	/******************************************************************
	| Constants
	/******************************************************************/
	
	uint256 immutable MAX_GUESS = 100;
	uint256 immutable ROUND_LENGTH = 5 minutes;
	uint256 immutable MINIMAL_BET_AMOUNT = 0.0001 ether;
	uint256 immutable CONTRACT_PERCENTAGE = 3;
	uint256 immutable TEAM_PERCENTAGE = 7;

	/******************************************************************
	| Variables
	/******************************************************************/

	struct Round {
		address[] players;
		mapping(address => bytes32) guesses;
		uint256 balance;
		address winner;
	}

	address public owner;
	address public keeper;
	uint256 public deployDate;
	uint256 public currentRoundId = 1;
	mapping(uint256 => Round) public rounds;

	/******************************************************************
	| Events
	/******************************************************************/
	event RoundStarted(uint256 id);
	event BetPlaced(uint256 indexed id, address player, bytes32 guess);
	event RoundEnded(uint256 indexed id, address winner, uint256 balance);
	event KeeperAddressUpdated(address newAddress);

	/******************************************************************
	| Custom errors
	/******************************************************************/
	error Unauthorized(address callerAddress, address expectedAddress);
	error PlayerAlreadyBetInThisRound(bytes32 guess);
	error NotEnoughMoneyBet(uint256 bet, uint256 minimalBet);
	error NoWinnerYet();
	error RoundIsNotOverYet();

	/******************************************************************
	| Core methods
	/******************************************************************/

	/**
	 * @dev Avocado constructor
	 * @param _keeper the address of the Chainlink keeper that will draw a winner at the end of each round
	 */
	constructor(address _keeper) {
		owner = msg.sender;
		keeper = _keeper;
		deployDate = block.timestamp;

		// Start the first round
		emit RoundStarted(currentRoundId);
	}

	/**
	 * @notice Place a bet on a number (integer and positive)
	 * @dev Make sure that the bet is a number between 1 and 100
	 * @param _guess the hash of the bet of the player
	 */
	function bet(bytes32 _guess) external payable {
		// Check that the player has bet enough
		if(msg.value < MINIMAL_BET_AMOUNT) {
			revert NotEnoughMoneyBet(msg.value, MINIMAL_BET_AMOUNT);
		}

		// Check that the player has never played in this round
		Round storage round = rounds[currentRoundId];
		bytes32 guess = round.guesses[msg.sender];
		if(guess != bytes32(0)) {
			revert PlayerAlreadyBetInThisRound(guess);
		}

		// Store the guess
		rounds[currentRoundId].guesses[msg.sender] = _guess;
		rounds[currentRoundId].players.push(msg.sender);
		rounds[currentRoundId].balance += msg.value;
		emit BetPlaced(currentRoundId, msg.sender, _guess);
	}

	/**
	 * @notice Draw a winner
	 */
	function draw() external {
		// Only the keeper can call this function
		if(msg.sender != keeper) {
			revert Unauthorized(msg.sender, keeper);
		}

		// The draw function can only be called at the end of the round
		if (block.timestamp < deployDate + ROUND_LENGTH * currentRoundId) {
			revert RoundIsNotOverYet();
		}

		address winnerAddress;
		uint256 winnerCount;

		Round storage round = rounds[currentRoundId];
		uint256 numberOfPlayers = round.players.length;
		for(uint256 i = 0; i < numberOfPlayers; i++) {
			address playerAddress = round.players[i];
			bytes32 playerGuess = round.guesses[playerAddress];

			//string memorychailinkVRFNumber = "3"; // TODO: Implement the Chainlink VRF part
			if (playerGuess == keccak256("3")) {
				winnerAddress = playerAddress;
				winnerCount++;
			}
		}

		// Store the winner
		// If multiple people guessed the number, then nobody wins.
		if (winnerCount == 1) {
			rounds[currentRoundId].winner = winnerAddress;
			emit RoundEnded(currentRoundId, winnerAddress, round.balance);

			// Send the rest of the money to the team.
			(bool sent,) = address(owner).call{value: round.balance / 4}("");
			require(sent, "Failed to send Ether");

			// Send the money to the winner.
			(sent,) = address(winnerAddress).call{value: round.balance / 2}("");
			require(sent, "Failed to send Ether");
		} else {
			emit RoundEnded(currentRoundId, address(0x0), round.balance);
		}

		// Start a new round
		currentRoundId++;
		emit RoundStarted(currentRoundId);
	}

	/******************************************************************
	| Getters
	/******************************************************************/

	/**
	 * @notice Get the winner of a specific round
	 * @param _id the id of the round
	 * @return address the address of the winner
	 * @return uint256 the balance of the round
	 */
	function getWinner(uint256 _id) external view returns(address, uint256) {
		if (currentRoundId == 1 || currentRoundId == _id) {
			revert NoWinnerYet();
		}

		Round storage round = rounds[_id];
		return (round.winner, round.balance);
	}

	/**
	 * @notice Get the guess of the player in a specific round
	 * @param _player the address of the player
	 * @param _id the id of the round
	 * @return bytes32 the hash of the guess of the player
	 */
	function getPlayerGuess(address _player, uint256 _id) external view returns (bytes32) {
		return rounds[_id].guesses[_player];
	}

	/**
	 * @notice Get the number of players in the last roud
	 * @return uint256 the number of players
	 */
	function getNumberOfPlayers() external view returns (uint256) {
		return rounds[currentRoundId].players.length;
	}

	/******************************************************************
	| Setters
	/******************************************************************/
	
	/**
	 * @notice Update the keeper's address
	 * @param _keeper the new address of the keeper
	 */
	function setKeeper(address _keeper) external {
		// Only the owner can call this function
		if(msg.sender != owner) {
			revert Unauthorized(msg.sender, owner);
		}

		keeper = _keeper;
		emit KeeperAddressUpdated(_keeper);
	}
}