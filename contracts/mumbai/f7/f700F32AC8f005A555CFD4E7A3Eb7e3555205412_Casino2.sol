// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Casino2 {
    address public owner;
    uint256 public houseBalance;
    uint256 public coinTossGameIdCounter;
    uint256 public diceRollGameIdCounter;

    enum GameResult { Pending, Win, Lose}

    event CoinTossGameResultEvent(uint256 indexed gameId, string result);
    event DiceRollGameResultEvent(uint256 indexed gameId, string result);

    mapping(uint256 => string) private coinTossGameResults;
    mapping(uint256 => string) private diceRollGameResults;

    constructor() {
        owner = msg.sender;
        coinTossGameIdCounter = 1;
        diceRollGameIdCounter = 1;
    }

    function depositHouseBalance() external payable {
        require(msg.sender == owner, "Only owner can deposit to house balance");
        houseBalance += msg.value;
    }

    function startCoinTossGame(uint8 chosenSide) external payable {
        require(msg.value > 0, "Bet amount must be greater than zero");
        require(chosenSide == 1 || chosenSide == 2, "Invalid choice");

        uint256 gameId = coinTossGameIdCounter;
        coinTossGameIdCounter++;

        GameResult result;
        bool trueResult = getRandomCoinTossResult();

         if (chosenSide == 1 && trueResult) {
            result = GameResult.Win;
            coinTossGameResults[gameId] = "You Win! Result: Heads";
        } else if (chosenSide == 2 && !trueResult) {
            result = GameResult.Win;
            coinTossGameResults[gameId] = "You Win! Result: Tails";
        } else if (chosenSide == 1 && !trueResult) {
            result = GameResult.Lose;
            coinTossGameResults[gameId] = "You Lost! Result: Tails";
        } else  (chosenSide == 2 && trueResult) ;{
            result = GameResult.Lose;
            coinTossGameResults[gameId] = "You Lost! Result: Heads";
        } 

        emit CoinTossGameResultEvent(gameId, coinTossGameResults[gameId]);

        if (result == GameResult.Win) {
            uint256 winnings = msg.value * 2;
            payable(msg.sender).transfer(winnings);
        } else if (result == GameResult.Lose) {
            houseBalance += msg.value;
        }
    }

    function startDiceRollGame(uint8 chosenNumber) external payable {
    require(msg.value > 0, "Bet amount must be greater than zero");
    require(chosenNumber >= 1 && chosenNumber <= 6, "Invalid number choice");

    uint256 gameId = diceRollGameIdCounter;
    diceRollGameIdCounter++;

    GameResult result;
    bool trueResult = getRandomDiceRollResult(chosenNumber);

    if (trueResult) {
        result = GameResult.Win;
        diceRollGameResults[gameId] = string(abi.encodePacked("You Win! The dice rolled ", uintToString(chosenNumber)));
    } else {
        result = GameResult.Lose;
        diceRollGameResults[gameId] = string(abi.encodePacked("You Lost! The dice rolled ", uintToString(chosenNumber)));
    }

    emit DiceRollGameResultEvent(gameId, diceRollGameResults[gameId]);

    if (result == GameResult.Win) {
        uint256 winnings = msg.value * 6;
        payable(msg.sender).transfer(winnings);
    } else if (result == GameResult.Lose) {
        houseBalance += msg.value;
    }
}


    function withdrawFunds(uint256 amount) external {
        require(msg.sender == owner, "Only owner can withdraw funds");
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(msg.sender).transfer(amount);
    }

    function withdrawHouseBalance() external {
        require(msg.sender == owner, "Only owner can withdraw house balance");
        require(houseBalance > 0, "House balance is zero");
        payable(msg.sender).transfer(houseBalance);
        houseBalance = 0;
    }

    function getRandomCoinTossResult() private view returns (bool) {
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 randomNumber = uint256(blockHash);
        return (randomNumber % 2 == 0);
    }

    function getRandomDiceRollResult(uint8 chosenNumber) private view returns (bool) {
        bytes32 blockHash = blockhash(block.number - 1);
        uint256 randomNumber = uint256(blockHash);
        uint8 rolledNumber = uint8((randomNumber % 6) + 1);
        return (rolledNumber == chosenNumber);
    }

    function uintToString(uint256 value) private pure returns (string memory) {
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
        uint256 index = digits - 1;
        temp = value;

        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }

        return string(buffer);
    }

    function getCoinTossGameResult(uint256 gameId) external view returns (string memory) {
        require(gameId >= 1 && gameId < coinTossGameIdCounter, "Invalid game ID");
        return coinTossGameResults[gameId];
    }

    function getDiceRollGameResult(uint256 gameId) external view returns (string memory) {
        require(gameId >= 1 && gameId < diceRollGameIdCounter, "Invalid game ID");
        return diceRollGameResults[gameId];
    }
}