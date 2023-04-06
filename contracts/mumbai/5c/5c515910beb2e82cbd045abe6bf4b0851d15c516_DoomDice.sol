/**
 *Submitted for verification at polygonscan.com on 2023-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DoomDice 
{
    // Constants
    uint256 constant MIN_BET = 0.00001 ether;
    uint256 constant TARGET_POT_SIZE = 0.0001 ether;
    uint256 constant HOUSE_CUT = 5;
    uint constant MAX_SESSION_HISTORY = 200;

    uint8 constant MIN_ROLL = 1;
    uint8 constant MAX_ROLL = 10;

    int256 private nonce = 0;

    enum SessionStatus { Initial, InProgress, Finished }

    address[] private participatingPlayers;
    mapping(address => mapping(uint8 => bool)) private playerWonWithNumber;

    mapping(address => bool) private isParticipating;
    mapping(address => uint8[]) private playerUsedNumbers;

    struct GameSession 
    {
        SessionStatus status;
        uint256 createdAt;
        uint256 totalPot;
        uint256 totalCorrectBets;
        uint256 totalIncorrectBets;
        DiceGame[] diceGames;

        uint8 mainPot_DiceNumber;
        uint256 mainPot_Participants;
        uint256 mainPot_NumberOfWinners;
    }

    struct DiceGame
    {
        uint256 timestamp;

        uint8 dice_One;
        uint8 dice_Two;

        bool didWin;
        PlayerBet playerBet;
    }

    struct PlayerBet 
    {
        address player;
        uint256 amount;
        uint8 playerGuess;
    }

    struct PlayerWinningNumber {
        address player;
        uint8 number;
    }

    //Events
    event DiceRoll(DiceGame);
    event MainPotWinners(address[] players, uint8 DiceNumber, uint256 rewardPerPlayer, uint256 totalPot, uint256 numberOfParticipants);
    event MainPotNoWinners(uint8 Dice_Number, uint256 amountReturned, uint256 numberOfParticipants);

    GameSession private currentSession;
    GameSession[] private sessionHistory;

    constructor() {
        //randomize nonce
        nonce = int256(uint256(keccak256(abi.encodePacked(address(this), block.timestamp))));
        
        //start first session ever
        startNewSession();
    }
    
    function getAllPlayersWithWinningNumbers() public view returns (PlayerWinningNumber[] memory) {
        PlayerWinningNumber[] memory winners = new PlayerWinningNumber[](participatingPlayers.length * MAX_ROLL);
        uint256 winnerIndex = 0;

        for (uint256 i = 0; i < participatingPlayers.length; i++) {
            address player = participatingPlayers[i];
            for (uint8 number = MIN_ROLL; number <= MAX_ROLL; number++) {
                if (playerWonWithNumber[player][number]) {
                    winners[winnerIndex] = PlayerWinningNumber({player: player, number: number});
                    winnerIndex++;
                }
            }
        }

        // Resize the winners array to the correct length
        assembly {
            mstore(winners, winnerIndex)
        }

        return winners;
    }

    function getPlayersWonWithNumber(uint8 number) private view returns (address[] memory) {
        address[] memory players = new address[](participatingPlayers.length);
        uint256 playerIndex = 0;

        for (uint256 i = 0; i < participatingPlayers.length; i++) {
            address player = participatingPlayers[i];
            if (playerWonWithNumber[player][number]) {
                players[playerIndex] = player;
                playerIndex++;
            }
        }

        // Resize the players array to the correct length
        assembly {
            mstore(players, playerIndex)
        }

        return players;
    }

    function getCurrentSession() public view returns (GameSession memory) {
        require(currentSession.status == SessionStatus.InProgress, "No game session in progress");
        return currentSession;
    }

    function getHistory() public view returns (GameSession[] memory) {
        return sessionHistory;
    }

    function getPlayerWonWithNumberCurrentSession(address player, uint8 number) private view returns (bool) {
        return playerWonWithNumber[player][number];
    }

    function placeBet(uint8 playerGuess) public payable returns (bool, uint8, uint8) {
        require(!playerWonWithNumber[msg.sender][playerGuess], "Player already won with this number");
        require(currentSession.status == SessionStatus.InProgress, "No game session in progress");
        require(msg.value == MIN_BET, "Incorrect bet amount");
        require(playerGuess >= MIN_ROLL && playerGuess <= MAX_ROLL, "Invalid guess number. Must be between 1 and 10.");

        (bool result, uint8 dice_One, uint8 dice_Two) = newDiceRoll(playerGuess, msg.sender, msg.value);

        if(currentSession.totalPot >= TARGET_POT_SIZE)
        {
            finishSession();
        }

        return (result, dice_One, dice_Two);
    } 

    function mainPotRoll() private 
    {
        uint8 Dice_Number = getRandomNumber();

        address[] memory winningPlayers = getPlayersWonWithNumber(Dice_Number);
        uint256 numberOfWinners = winningPlayers.length;
        
        currentSession.mainPot_DiceNumber = Dice_Number;
        currentSession.mainPot_NumberOfWinners = numberOfWinners;

        if(numberOfWinners == 0)
        {
            uint256 participatingNumberOfPlayers = participatingPlayers.length;

            for(uint256 i = 0; i < participatingPlayers.length; i++)
            {
                uint256 numberOfNumbersInPot = playerUsedNumbers[participatingPlayers[i]].length;
                payable(participatingPlayers[i]).transfer(MIN_BET * numberOfNumbersInPot);
            }

            emit MainPotNoWinners(Dice_Number, participatingNumberOfPlayers * MIN_BET, participatingNumberOfPlayers);
            return;
        }

        uint256 houseCut = (currentSession.totalPot * HOUSE_CUT) / 100;
        uint256 remainingPot = currentSession.totalPot - houseCut;
        uint256 winnerShare = remainingPot / numberOfWinners;

        emit MainPotWinners(winningPlayers, Dice_Number, winnerShare, currentSession.totalPot, numberOfWinners);

        for(uint256 i = 0; i < winningPlayers.length; i++)
        {
            payable(winningPlayers[i]).transfer(winnerShare);
        }
    }

    function newDiceRoll(uint8 playerGuess, address playerAddress, uint256 value) private returns(bool, uint8, uint8) 
    {
        //add to pot
        currentSession.totalPot += value;

        uint8 dice_One = getRandomNumber();
        uint8 dice_Two = getRandomNumber();

        bool didWin = (dice_One == playerGuess) || (dice_Two == playerGuess);
        
        PlayerBet memory playerBet = createPlayerBet(playerAddress, value, playerGuess);

        DiceGame storage newDiceGame = currentSession.diceGames.push();
        newDiceGame.timestamp = block.timestamp;
        newDiceGame.dice_One = dice_One;
        newDiceGame.dice_Two = dice_Two;

        newDiceGame.playerBet = playerBet;  
        newDiceGame.didWin = didWin;

        if(didWin)
        {
            addParticipant(playerAddress);
            playerWonWithNumber[playerAddress][playerGuess] = true;
            currentSession.totalCorrectBets++;
        }
        else
        {
            currentSession.totalIncorrectBets++;
        }

        emit DiceRoll(newDiceGame);

        return (didWin, dice_One, dice_Two);
    }

    function startNewSession() private {
        require(currentSession.status != SessionStatus.InProgress, "A game session is already in progress");

        currentSession.status = SessionStatus.InProgress;
        currentSession.createdAt = block.timestamp;
        currentSession.totalPot = 0;
        currentSession.totalCorrectBets = 0;
        currentSession.totalIncorrectBets = 0;
        
        currentSession.mainPot_DiceNumber = 0;
        currentSession.mainPot_Participants = 0;
        currentSession.mainPot_NumberOfWinners = 0;

        // Clear the diceGames array
        while(currentSession.diceGames.length > 0) {
            currentSession.diceGames.pop();
        }
    }

    function resetPlayers() private {
        for (uint256 i = 0; i < participatingPlayers.length; i++) {
            for (uint8 j = MIN_ROLL; j <= MAX_ROLL; j++) {
                delete playerWonWithNumber[participatingPlayers[i]][j];
            }
        }

        for (uint256 i = 0; i < participatingPlayers.length; i++) {
            isParticipating[participatingPlayers[i]] = false;
        }

        delete participatingPlayers;
    }
    
    function addParticipant(address player) private {
        if (!isParticipating[player]) {
            participatingPlayers.push(player);
            isParticipating[player] = true;

            currentSession.mainPot_Participants++;
        }
    }

    function finishSession() private {
        require(currentSession.status == SessionStatus.InProgress, "No game session in progress");
        currentSession.status = SessionStatus.Finished;

        //roll main pot
        mainPotRoll();


        sessionHistory.push(currentSession);
        if (sessionHistory.length > MAX_SESSION_HISTORY) {
            for (uint256 i = 0; i < sessionHistory.length - 1; i++) {
                sessionHistory[i] = sessionHistory[i + 1];
            }
            sessionHistory.pop();
        }

        resetPlayers();
        startNewSession();
    }

    function getRandomNumber() private returns (uint8) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(nonce, block.timestamp, block.difficulty)
            )
        );
        nonce++;

        return uint8((randomNumber % MAX_ROLL) + 1);
    }   

    // Helper function to create a PlayerBet struct
    function createPlayerBet(address player, uint256 betAmount, uint8 selectedNumber) private pure returns (PlayerBet memory) {
        return PlayerBet({
            player: player,
            amount: betAmount,
            playerGuess: selectedNumber
        });
    }
}