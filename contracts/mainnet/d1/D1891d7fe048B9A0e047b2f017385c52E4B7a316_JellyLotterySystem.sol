// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract JellyLotterySystem {
    address public owner;
    uint256 public ticketPrice;
    uint256 public jackpot;
    uint256 public numTicketsSold;
    address[] public tickets;
    uint256 public constant CONTRACT_FEE_PERCENTAGE = 5;
    address public tokenAddress;
    uint256 public tokenAmount;
    address[3] public pastWinners;

    bool public paused;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused, "Function temporarily paused");
        _;
    }
    
    constructor(uint256 _ticketPrice, address _tokenAddress) {
        owner = msg.sender;
        ticketPrice = _ticketPrice;
        jackpot = 0;
        numTicketsSold = 0;
        tokenAddress = _tokenAddress;
        paused = false;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = _tokenAddress;
    }

    function buyTicket(uint256 _tokenAmount) public whenNotPaused {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), _tokenAmount), "Token transfer failed");
        require(_tokenAmount == ticketPrice, "Invalid token amount");
        require(numTicketsSold < 20, "Maximum number of tickets sold");
        tickets.push(msg.sender);
        jackpot += _tokenAmount;
        numTicketsSold++;
        
        // automatically select winner if 20 tickets have been sold
        if (numTicketsSold == 20) {
            paused = true;
        }
    }

    function selectWinner() public onlyOwner {
        require(paused, "Lottery not yet closed");
        require(numTicketsSold == 20, "Not all tickets have been sold");

        uint256 index = uint256(blockhash(block.number - 1)) % 20;
        address winner = tickets[index];
        uint256 winnerPrize = (jackpot * 95) / 100; // 95% of jackpot goes to winner
        uint256 contractFee = (jackpot * CONTRACT_FEE_PERCENTAGE) / 100; // 5% of jackpot goes to contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(winner, winnerPrize), "Token transfer failed");
        
        // reset the lottery variables
        jackpot = 0;
        numTicketsSold = 0;
        delete tickets;
        paused = false;
        
        // transfer contract fee to owner
        require(token.transfer(owner, contractFee), "Token transfer failed");
        
        // update past winners
        if (pastWinners[2] != address(0)) {
            pastWinners[0] = pastWinners[1];
            pastWinners[1] = pastWinners[2];
        }
        pastWinners[2] = winner;
    }

    function getTickets() public view returns (address[] memory) {
        return tickets;
    }

    function withdraw() public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, token.balanceOf(address(this))), "Token transfer failed");
    }
    
}