/**
 *Submitted for verification at polygonscan.com on 2023-04-08
*/

pragma solidity ^0.8.0;

contract Pazaak {
    uint8 constant STAND = 0;
    uint8 constant HIT = 1;
    uint8 constant MAX_SCORE = 20;
    uint8 constant MAX_DECK_SIZE = 10;

    uint8[MAX_DECK_SIZE] private deck;
    uint8 private deckSize;
    uint8[MAX_DECK_SIZE] private playerHand;
    uint8 private playerScore;
    uint8[MAX_DECK_SIZE] private dealerHand;
    uint8 private dealerScore;
    bool private isPlayerTurn;

    event GameStarted(bool playerTurn);
    event CardDealt(uint8 card, bool isPlayer);
    event TurnEnded(bool isPlayer);
    event GameEnded(bool playerWins);

    constructor() {
        deckSize = 0;
        playerScore = 0;
        dealerScore = 0;
        isPlayerTurn = true;
    }

    function startGame() public {
        require(deckSize == 0, "Game has already started");
        for (uint8 i = 1; i <= 10; i++) {
            for (uint8 j = 1; j <= 4; j++) {
                deck[deckSize++] = i;
            }
        }
        shuffleDeck();
        dealCard(true);
        dealCard(false);
        emit GameStarted(isPlayerTurn);
    }

    function shuffleDeck() private {
        for (uint8 i = 0; i < deckSize; i++) {
            uint256 rand = uint256(
                keccak256(abi.encodePacked(block.timestamp, i, deck[i]))
            );
            uint8 randIndex = uint8(rand % deckSize);
            uint8 temp = deck[randIndex];
            deck[randIndex] = deck[i];
            deck[i] = temp;
        }
    }

    function dealCard(bool toPlayer) private {
        uint8 card = deck[--deckSize];
        if (toPlayer) {
            playerHand[playerScore++] = card;
            emit CardDealt(card, true);
        } else {
            dealerHand[dealerScore++] = card;
            emit CardDealt(card, false);
        }
    }

    function getPlayerHand() public view returns (uint8[MAX_DECK_SIZE] memory) {
        return playerHand;
    }

    function getPlayerScore() public view returns (uint8) {
        return playerScore;
    }

    function getDealerHand() public view returns (uint8[MAX_DECK_SIZE] memory) {
        return dealerHand;
    }

    function getDealerScore() public view returns (uint8) {
        return dealerScore;
    }

    function getPlayerTurn() public view returns (bool) {
        return isPlayerTurn;
    }

    function playerAction(uint8 action) public {
        require(isPlayerTurn, "It is not the player's turn");
        require(playerScore < MAX_DECK_SIZE, "Player's hand is full");
        if (action == HIT) {
            dealCard(true);
            if (playerScore == MAX_SCORE) {
                endGame();
            }
        } else if (action == STAND) {
            isPlayerTurn = false;
            dealerAction();
        }
        emit TurnEnded(isPlayerTurn);
    }

    function dealerAction() private {
        while (dealerScore < MAX_SCORE && dealerScore < playerScore) {
            dealCard(false);
        }
        endGame();
    }

    function endGame() private {
        isPlayerTurn = false;
        bool playerWins = (playerScore <= MAX_SCORE &&
            (playerScore > dealerScore || dealerScore > MAX_SCORE));
        emit GameEnded(playerWins);
        resetGame();
    }

    function resetGame() private {
        deckSize = 0;
        playerScore = 0;
        dealerScore = 0;
        isPlayerTurn = true;
    }
}