// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

/// @title <Lottery.sol>
/// @author <IvanFitro>
/// @notice <Creation of a system of lottery>

contract Lottery {
    
    //Instance of the token contract
    ERC20Basic private token;

    //Directions
    address public owner;
    address public Contract;

    //Events
    event bought_Tokens(address, uint);

    //Tokens to create
    uint created_tokens = 10000;

    constructor () public {
        token = new ERC20Basic(created_tokens);
        owner = msg.sender;
        Contract = address(this);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You don't have permsissions.");
        _;
    }

    //--------------------------------------------Token--------------------------------------------

    //Function to fix the price of the tokens
    function TokenPrice(uint _numTokens) internal pure returns(uint) {
        return _numTokens * (1 finney);
    }

    //Function to generate more tokens
    function generateTokens(uint _numTokens) public onlyOwner {
        token.increaseTotalSuply(_numTokens);
    }

    //Function to buy tokens
    function buyTokens(uint _numTokens) public payable {
        //Calculate the value of the tokens
        uint cost = TokenPrice(_numTokens);
        require (msg.value >= cost, "You don't have enough funds");
        //If the client pays more the contract needs to return de difference
        uint returnValue = msg.value - cost;
        msg.sender.transfer(returnValue);
        //Obatain the balance of tokens of the contract
        uint Balance = availableTokens();
        //Filter to check the available tokens
        require(Balance >= _numTokens, "Buy less tokens");
        //Send the tokens to the client
        token.transfer(msg.sender, _numTokens);
        emit bought_Tokens(msg.sender, _numTokens);
    }

    //Function to see the balance of the contract
    function availableTokens() public view returns(uint) {
        return token.balanceOf(Contract);
    }

    //Function to obtain the balance of tokens in the jackpot
    function Jackpot() public view returns(uint) {
        return token.balanceOf(owner);
    }

    //Function to see the balance of tokens of a client
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //--------------------------------------------Lottery--------------------------------------------

    //Price of the ticket
    uint public TicketPrice = 5;
    
    //Relation of the client that buys the tickets and the number of the tickets
    mapping (address => uint []) idPerson_tickets;
    //Relation for identify the winner
    mapping (uint => address) ADN_Ticket;
    
    //Random number
    uint randNonce = 0;

    //Generated Tickets
    uint [] boughtTickets;

    //Events
    event bought_Ticket(uint, address);
    event winning_Ticket(uint);
    event returned_Tokens(uint, address);

    //Function to buy tickets
    function buyTickets(uint _tickets) public {
        //Total price of the tickets
        uint total_price = _tickets * TicketPrice;
        require(total_price <= myTokens(), "You don't have enough tokens");

        //Transfer of tokens to the owner (reward)
        /*The client pays for the attraction with tokens:
        -It is necessary to create a new function in ERC20.sol with the name of disneyTransfer. This is necessary because
        if we use transfer the direcctions are wrong because the msg.sender that the transfer function gets 
        was the contract direction.
        */
        token.lotteryTransfer(msg.sender, owner, total_price);

        /*For create a random number we take the actual time, the msg.sender and a nonce and with the keccack256 create
        a random hash, next the hash in converted to a uint and fot finish we use a % 1000 to take the four last numbers.
        Giving a value between 0-9999.
        */
        for (uint i=0; i < _tickets; i++ ) {
            uint random = uint(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10000;
            randNonce++;
            //Save the data of the tickets
            idPerson_tickets[msg.sender].push(random);
            //Number of the bought ticket
            boughtTickets.push(random);
            //Assignament of the ticket ADN to obtain a winner
            ADN_Ticket[random] = msg.sender;
            emit bought_Ticket(random, msg.sender);
        }
    }

    //Function to see the tickets of a client
    function myTickets() public view returns(uint [] memory) {
        return idPerson_tickets[msg.sender];
    }

    //Function to choose the winner and send the tokens
    function selectWinner() public onlyOwner {
        require(boughtTickets.length > 0, "No tickets purchased");
        uint length = boughtTickets.length;
        //Choose a random position of the array
        uint array_position = uint(uint(keccak256(abi.encodePacked(now))) % length);
        //Choose a ticket using the random number created in array_position
        uint election = boughtTickets[array_position];
        emit winning_Ticket(election);
        //Select the address of the winner
        address winner = ADN_Ticket[election];
        //Send the tokens of the jackpot to the winner
        token.lotteryTransfer(msg.sender, winner, Jackpot());
    }

    //Function to return the tokens
    function returnTokens(uint _numTokens) public payable {
        require(_numTokens > 0, "You need to return a positive number of tokens");
        require(_numTokens <= myTokens(), "You don't have this number of tokens");
        //The client returns the tokens
        token.lotteryTransfer(msg.sender, address(this), _numTokens);
        //The lottery returns to the client the ethers for each token
        msg.sender.transfer(TokenPrice(_numTokens));
        emit returned_Tokens(_numTokens, msg.sender);
    }

}