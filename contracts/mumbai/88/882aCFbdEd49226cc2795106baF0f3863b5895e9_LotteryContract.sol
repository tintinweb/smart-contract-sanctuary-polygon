// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract LotteryContract {
    address public admin;
    address payable[] public players; //Array of players who bought tickets
    bool public lotteryStatus; //True if the lottery is running
    uint256 public ticketCost;

    event NewTicketBought(address player); //Event when someone buys a ticket
    event LotteryStarted();
    event LotteryEnded();
    event Winner(address winner); //Event when someone wins the lottery
    event TicketCostChanged(uint256 newCost); //Event when the ticket cost is updated

    constructor(uint256 _ticketCost) {
        admin = msg.sender; //The admin is the one who deploys the contract
        lotteryStatus = false; //Lottery is not running
        ticketCost = _ticketCost; //Initial ticket cost
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function"); //Sets the admin as the only one who can call functions
        _;
    }

    function buyTicket() public payable {
        require(lotteryStatus == true, "Lottery is not running"); //Lottery must be running
        require(msg.value == ticketCost, "Ticket cost is not correct"); //Ticket cost must match the ticketCost variable

        players.push(payable(msg.sender)); //Add the player to the players array
        emit NewTicketBought(msg.sender); //Emit the event that a new ticket was bought
    }

    function startLottery() public onlyAdmin {
        require(!lotteryStatus, "Lottery is already running"); //Lottery must not be running

        lotteryStatus = true; //Set the lottery status to true
        emit LotteryStarted(); //Emit the event that the lottery has started
    }

    function endLottery() public onlyAdmin {
        require(lotteryStatus, "Lottery is not running"); //Lottery must be running

        lotteryStatus = false; //Set the lottery status to false
        emit LotteryEnded(); //Emit the event that the lottery has ended
    }

    //Function returns a random number between 0 and the length of the players array
    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.prevrandao,
                        block.timestamp,
                        players.length
                    )
                )
            );
    }

    function pickWinner() public onlyAdmin {
        require(!lotteryStatus, "Lottery is still running"); //Lottery must not be running
        require(players.length > 0, "No players in the lottery"); //There must be at least one player

        uint256 index = random() % players.length; //Get a random index
        address payable winner = players[index]; //Get the winner address

        winner.transfer(address(this).balance); //Transfer the balance to the winner

        players = new address payable[](0); //Reset the players array

        emit Winner(winner); //Emit the event that a winner was picked
    }

    function changeTicketCost(uint256 _newCost) public onlyAdmin {
        require(!lotteryStatus, "Lottery is still running"); //Lottery must not be running

        ticketCost = _newCost; //Set the new ticket cost
        emit TicketCostChanged(_newCost); //Emit the event that the ticket cost was updated
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players; //Return the players array
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance; //Return the contract balance
    }
}