/**
 *Submitted for verification at polygonscan.com on 2022-04-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

contract JackpotGame {

    address private _owner;
    address private devWallet = 0xa99875ae659BA47456757609bD23dF69CA8f5547;

    bool private ended = false;

    uint256 private contractBalance;
    uint256 private lockedBalance;
    uint256 private perWinner;
    uint256 private winners = 10;

    mapping (address => uint) private tickets;
    mapping (address => bool) private playerExists;

    address payable[] private players;

    address payable[] private ticketedPlayers;

    event Received(address, uint);
    event playerAdded(address, uint);
    event playerWon(address, uint);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function endGame() public onlyOwner { //ends the game, no more deposits, waiting to pick winners
        ended = true;
        lockedBalance = contractBalance;
        perWinner = lockedBalance / winners;
    }

    function checkDevWallet() public view returns(address){ //returns dev wallet address
        return devWallet;
    }

    function updateContractBalance() public onlyOwner { //updates contract balance IMPORTANT: CALL BEFORE END GAME
        contractBalance = address(this).balance;
    }

    function setWinners(uint howMany) public onlyOwner { //sets number of winners(prize pool will be split by this number)
        winners = howMany; //default winners: 10
    }

    function checkOwnTickets() public view returns(uint256) { //checks your own tickets
        return tickets[msg.sender];
    }

    function checkTickets(address who) public view returns(uint256) { //check how many tickets address has
        return tickets[who];
    }

    function howManyPlayers() public view returns(uint256) { //check how many players are playing
        return players.length;
    }

    function isPlaying(address who) public view returns(bool) { //checks if address is in-game
        return playerExists[who];
    }

    function checkContractBalance() public view returns(uint256) { //Test function
        return contractBalance;
    }

    function checkLockedBalance() public view returns(uint256) { //Test function
        return lockedBalance;
    }

    function getRandomNumber() public view onlyOwner returns (uint) { //Used to pick random ticket
        return uint(keccak256(abi.encodePacked(_owner, block.timestamp)));
    }

    function checkPushWorking() public view onlyOwner returns (uint) { //Test function
        return ticketedPlayers.length;
    }

    function pickWinners() public onlyOwner { //Picks winner and transfers their winnings (owner has to manually roll each winner)
        require(ended == true);
        uint index = getRandomNumber() % ticketedPlayers.length;
        ticketedPlayers[index].transfer(perWinner);
    }

    function pickWinnersTest() public onlyOwner returns(address) { //Test for picking the winner
        require(ended == true);
        uint index = getRandomNumber() % ticketedPlayers.length;
        emit playerWon(ticketedPlayers[index], tickets[ticketedPlayers[index]]);
        return ticketedPlayers[index];
    }

    receive() external payable { //Deposit
        require(ended == false);
        if(msg.value >= 10 ether) {
            if(playerExists[msg.sender] == false) { //Adds player to the list of players
                playerExists[msg.sender] = true;
                players.push(payable(msg.sender));
                emit playerAdded(msg.sender, msg.value);
            }
        }
        if(msg.value >= 10 ether && msg.value < 20 ether) { //buys 1 ticket for 10 MATIC
            tickets[msg.sender]++;
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 20 ether && msg.value < 30 ether) { //buys 2 tickets for 20 MATIC
            tickets[msg.sender]+=2;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 30 ether && msg.value < 40 ether) { //buys 3 tickets for 30 MATIC
            tickets[msg.sender]+=3;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 40 ether && msg.value < 50 ether) { //buys 4 tickets for 40 MATIC
            tickets[msg.sender]+=4;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 50 ether && msg.value < 60 ether) { //buys 5 tickets for 50 MATIC
            tickets[msg.sender]+=5;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 60 ether && msg.value < 70 ether) { //buys 6 tickets for 60 MATIC
            tickets[msg.sender]+=6;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 70 ether && msg.value < 80 ether) { //buys 7 tickets for 70 MATIC
            tickets[msg.sender]+=7;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 80 ether && msg.value < 90 ether) { //buys 8 tickets for 80 MATIC
            tickets[msg.sender]+=8;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 90 ether && msg.value < 100 ether) { //buys 9 tickets for 90 MATIC
            tickets[msg.sender]+=9;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        if(msg.value >= 100 ether) { //buys 10 tickets for 100 MATIC
            tickets[msg.sender]+=10;
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
            ticketedPlayers.push(payable(msg.sender));
        }
        payable(devWallet).transfer(msg.value / 10); // transfers 10% of the deposit to devWallet (fee for the dev)
        emit Received(msg.sender, msg.value);
    }
}