/**
 *Submitted for verification at polygonscan.com on 2023-04-17
*/

// SPDX-License-Identifier: MIT
// The line above is recommended and let you define the license of your contract
// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

//import "hardhat/console.sol"; // fix for conflict with forge-std/Test.sol in tests.

// This is the main building block for smart contracts.
contract MyToken {
    bool      public  gameOngoing;

    // admin side.
    address   public  admin;
    uint32    public  ticketPrice;
    uint8     public  prizePercentage; // ranging from 1~90.
    uint32    public  gameRound;
    uint8[6]  public  winningNums;     // The 6 winning numbers in a game. Each should be between 1~49, inclusive.

    // player side.
    uint32    public  playerNum;       // The number of players. This is to loop through mapping 'ticketOrders'.
    address[] public  playerList;
    address[] public  winnerList;
    mapping(address => LotteryTicket) public ticketOrders;
    //mapping(uint32 => uint8[6]) public winningNumbers; // winning numbers records. The key is the round number, while the value (uint8[6]) is the corresponding winning number.

    struct LotteryTicket {
        //TODO: bring back. uint32 ticketCnt; // the number of tickets a player buys in a game. This is to loop through all the tickets one buys.
        //TODO: bring back. uint8[][6] playerLotteryNums;  // a player can buy multiple tickets in a game.
        bool   isValid;              // true: player's ticket is valid. Otherwise, invalid.
        bool   isClaimed;
        uint32 playerGameRound;      // the latest game round that a player is in.
        uint8[6] playerLotteryNums;  // a player can buy multiple tickets in a game.
    }

    constructor() {
        admin = msg.sender;
        gameRound = 1;            // increase by 1 every time when a game is finished.
        ticketPrice = 500000 wei; // about one US dollar.
        prizePercentage = 70;     // 70% of the balance in pool is used for the Prize.
        gameOngoing = false;      // true: the game is ongoing. false: game is paused/cancelled.
        for (uint8 i = 0; i < 6; i++) {
            winningNums[i] = 0;   // set the initial winning number as 0.
        }
    }

    mapping(address => uint256) balances;

    modifier onlyAdmin () { // only admin can enable/pause/cancel a game and change the ticket price and prize percentage.
        require(msg.sender == admin, "Only the contract admin can call this function.");
        _;
    }

    modifier gameIsOngoing () { // only admin can enable/pause/cancel a game and change the ticket price and prize percentage.
        require(gameOngoing == true, "Game is not ongoing.");
        _;
    }

    modifier onlyValidTicket () { // a player needs a valid ticket to claim a prize or cancel a ticket.
        require(ticketOrders[msg.sender].isValid == true, "The ticket is invalid and thus cannot proceed.");
        _;
    }

    modifier onlyOneTicket () { // a player is allowed to buy at msot one ticket in a game. This limit may be removed later. // test_08 fix.
        require((ticketOrders[msg.sender].isValid == false) || (ticketOrders[msg.sender].playerGameRound != gameRound), "Only one ticket at most in a game round.");
        _;
    }

    modifier hasPlayers () { // a player is allowed to buy at msot one ticket in a game. This limit may be removed later. // test_08 fix.
        require(playerNum > 0, "There should be at least one player in a game.");
        _;
    }

    event getTicketPriceEvent();
    function setTicketPrice(uint32 newPrice) onlyAdmin external {
        require(newPrice > 0, "The new ticket price should be larger than 0.");
        ticketPrice = newPrice;
    }

    function setPrizePercentage(uint8 newPercent) onlyAdmin external {
        require((newPercent > 0) && (newPercent <= 90), "The new percentage should be > 0 and <= 90.");
        prizePercentage = newPercent;
    }

    function enableGame() onlyAdmin external {
        gameOngoing = true;
    }
    function pauseGame() onlyAdmin external {
        gameOngoing = false;
    }

    // A game can only be cancelled (to prevent any new player from buying tickets) when it has been paused to avoid any synchronization issue.
    function adminCancelGame() external {
        require(gameOngoing == false, "Please pause the game before cancelling it.");
        // return ticket fees back to players if a game is cancelled.
        for (uint32 i = 0; i < playerNum; i++) {
            if (ticketOrders[playerList[i]].playerGameRound == gameRound) { // make sure that a player has joined the latest game before refunding.
                payable(playerList[i]).transfer(ticketPrice);
            }
        }
    }

    // Player side.
    function buyTicket(uint8[6] memory newNums) gameIsOngoing onlyOneTicket external payable { // test_04 fix.
        require(msg.value == ticketPrice, "Incorrect paid Ethers, check the price by function getTicketPrice and try again.");
        bool hasDuplicate = false;
        for (uint8 i = 0; i < 5; i++) {
            for (uint8 j = (i + 1); j < 6; j++) {
                if (newNums[i] == newNums[j]) {
                    hasDuplicate = true;
                }
            }
        }
        require(hasDuplicate == false, "No duplicate numbers are allowed.");

        // numbers should be between 1~49. // issue_1 fix.
        bool validNums = true;
        for (uint8 i = 0; i < 6; i++) {
            if (newNums[i] < 1 || newNums[i] > 49) {
                validNums = false;
            }
        }
        require(validNums == true, "All selected numbers should be between 1~49, inclusive.");

        ticketOrders[msg.sender].playerGameRound = gameRound;
        ticketOrders[msg.sender].isValid = true;
        ticketOrders[msg.sender].isClaimed = false;
        for (uint8 i = 0; i < newNums.length; i++) {
            ticketOrders[msg.sender].playerLotteryNums[i] = newNums[i];
        }

        playerList.push(msg.sender);
        //playerList[playerNum] = msg.sender;
        playerNum += 1;  
    }

    function playerCancelTicket() onlyValidTicket external {
        ticketOrders[msg.sender].isValid = false;
        payable(msg.sender).transfer(ticketPrice);
    }

    function draw() onlyAdmin hasPlayers external {
        gameOngoing = false; // disable game to prevent any player from buying a ticket after the winning numbers are generated.
        winningNums = generateNumbers();

        //address[] memory winnerList;
        // check winners and get the total number of winners.
        for (uint32 i = 0; i < playerNum; i++) {
            if ((ticketOrders[playerList[i]].playerGameRound == gameRound) && (ticketOrders[playerList[i]].isValid == true)) { // make sure that a player has joined the latest game and has not cancelled. // issue_3 fix.
                bool isWinner = checkWinner(ticketOrders[playerList[i]].playerLotteryNums, winningNums);
                if (isWinner) {
                    winnerList.push(playerList[i]);
                }
                //payable(playerList[i]).transfer(ticketPrice); // issue_4 fix by removing this line.
            }
        }

        // divide the prize and transfer.
        if (winnerList.length > 0) {
            uint256 winnerPrize =  (address(this).balance * prizePercentage / (100 *winnerList.length)); // issue_2 fix.
            for (uint32 i = 0; i < winnerList.length; i++) {
                require(ticketOrders[winnerList[i]].isClaimed == false, "Winner has already claimed the prize.");
                ticketOrders[winnerList[i]].isClaimed = true;
                payable(winnerList[i]).transfer(winnerPrize);
            }
        }

        // prepare for the next game.
        gameRound += 1;
        playerNum = 0;
        delete playerList;
    }

    function getWinningNumber() external view returns (uint32, uint8[6] memory) {
        return  (gameRound - 1, winningNums); // gameRound needs to minus 1 because it is increased every time a round of winning nubmers is generated.
    }

    // for players to check their own number and corresponding game round in case they forgot them.
    function getPlayerNumber() external view returns (uint32, uint8[6] memory) {
        return (ticketOrders[msg.sender].playerGameRound, ticketOrders[msg.sender].playerLotteryNums);
    }

    // for players to check the ticket price before buying a ticket.
    function getTicketPrice() external view returns (uint32) {
        return ticketPrice;
    }

    // for players to check the total money in the pool before buying a ticket.
    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // for players to check the expected prize before buying a ticket.
    function getExpectedPrize() external view returns (uint256) {
        return (address(this).balance * prizePercentage / 100); // default 70%.
    }

    // Newly Added
    function getPrizePercentage() external view returns (uint256) {
        return (prizePercentage / 100); // default 70%.
    }

    // Newly Added
    function getGameRound() external view returns (uint32) {
        return gameRound;
    }

    // Newly Added
    function getGameStatus() external view returns (string memory) {
        string memory gameStatus = gameOngoing ? "Ongoing" : "Paused/Cancelled";
        return gameStatus;
    }

    // for admin to donate money to charitable organization.
    // This is the main purpose of this lottery game.
    function doCharityDonation() onlyAdmin external view returns (uint256) {
        return address(this).balance;
    }

    function generateNumbers() private view returns(uint8[6] memory) {
        uint8[6] memory numbers;
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender)));
        
        for(uint8 i=0; i<6; i++) {
            uint8 number = uint8(randomNumber % 49) + 1;
            while(numberExists(numbers, number)) {
                randomNumber = uint(keccak256(abi.encodePacked(randomNumber)));
                number = uint8(randomNumber % 49) + 1;
            }
            numbers[i] = number;
            randomNumber = uint(keccak256(abi.encodePacked(randomNumber)));
        }
        
        return numbers;
    }
    
    function numberExists(uint8[6] memory array, uint8 number) private pure returns(bool) {
        for(uint8 i=0; i<array.length; i++) {
            if(array[i] == number) {
                return true;
            }
        }
        return false;
    }

    function checkWinner(uint8[6] memory playerNums, uint8[6] memory winnerNums) private pure returns(bool) {
        require(playerNums.length == winnerNums.length, "Player number length should be equal to winner number length.");
        bool isWinner = true;
        for(uint8 i =0; i < winnerNums.length; i++) {
            if (playerNums[i] != winnerNums[i]) {
                isWinner = false;
                break;
            }
        }
        return isWinner;
    }

}