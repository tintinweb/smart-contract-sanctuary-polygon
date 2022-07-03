// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20.sol";

contract Disney {

    //----------------------------------------Initial Declarations----------------------------------------

    //Instance for the token contract (the msg.sender in this contract is the contract direction)
    ERC20Basic private token;
    //Owner address
    address payable public owner; 

    constructor() public {
        token = new ERC20Basic(10000);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You don't have permisions");
        _;
    }

    //Data struct for save the disney clients
    struct client {
        uint buyed_tokens;
        string [] attractions; 
    }

    //Mapping for the clients registration
    mapping (address => client) public Clients;

    //----------------------------------------Token Management--------------------------------------------

    //Function to see the price of a token respect the Ether
    function tokenPrice(uint _numTokens) internal pure returns(uint) {
        return _numTokens*(1 wei);
    }

    //Function to buy tokens
    function buyTokens(uint _numTokens) public payable {
        //Stablish the token price
        uint cost = tokenPrice(_numTokens);
        //Evaluates the money pay for the tokens
        require(msg.value >= cost, "Buy less tokens or pay with more ethers.");
        //Diference that the client pays.
        uint returnValue = msg.value - cost;
        //Disney returns the quantity of ethers to the client
        msg.sender.transfer(returnValue);
        //Obtain the available tokens
        uint Balance = balanceOf();
        require(_numTokens <= Balance, "Buy less tokens");
        //Transfers the tokens to the client
        token.transfer(msg.sender, _numTokens);
        //To see all the tokens buyed by a client
        Clients[msg.sender].buyed_tokens += _numTokens;
    }

    //Function to see the available tokens in the Disney contract
    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    //Function to see the client tokens
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    //Function to create more tokens
    function createTokens(uint _numTokens) public onlyOwner {
        token.increaseTotalSuply(_numTokens);
    }

    //----------------------------------------Disney Management--------------------------------------------

    //Events
    event enjoy_attraction(string);
    event new_attraction(string, uint);
    event leave_attraction(string);

    //Data attraction struct
    struct attraction {
        string attraction_name;
        uint  attraction_price;
        bool attraction_condition;
    }

    //Mapping for link a name of an attraction with a data structure of the attraction
    mapping (string => attraction) public AttractionMapping;

    //Array for save the name of the attractions
    string [] Attractions;

    //Mapping for link a client with their history
    mapping (address => string []) AttractionHistory;

    //Function to create a new attractions
    function NewAttraction(string memory _attractionName, uint _price) public onlyOwner {
        AttractionMapping[_attractionName] = attraction(_attractionName, _price, true);
        Attractions.push(_attractionName);
        emit new_attraction(_attractionName, _price);
    }

    //Function to leave an attraction
    function LeaveAttraction(string memory _attractionName) public onlyOwner {
        AttractionMapping[_attractionName].attraction_condition = false;
        emit leave_attraction(_attractionName);
    }

    //Function to see all the attractions in disney
    function seeAttractions() public view returns(string [] memory ) {
        return Attractions;
    }

    //Function to get on in an attraction and pay tokens
    function goAttraction(string memory _attractionName) public {
        //Attraction price in tokens
        uint attraction_tokens = AttractionMapping[_attractionName].attraction_price;
        //Verifies the attraction condition
        require(AttractionMapping[_attractionName].attraction_condition == true, "The attraction is not available");
        //Vereifies if the client has enpugh tokens
        require(myTokens() >= attraction_tokens, "You dont have enough tokens");

        /*The client pays for the attraction with tokens:
        -It is necessary to create a new function in ERC20.sol with the name of disneyTransfer. This is necessary because
        if we use transfer the direcctions are wrong because the msg.sender that the transfer function gets 
        was the contract direction.
        */
        token.disneyTransfer(msg.sender, address(this), attraction_tokens);
        //Saving the history of the client
        AttractionHistory[msg.sender].push(_attractionName);
        emit enjoy_attraction(_attractionName);    
    }

    //Function to see the attractions that the client enjoyed
    function History() public view returns(string [] memory) {
        return AttractionHistory[msg.sender];
    }

    //Function to returns the tokens to disney
    function returnTokens(uint _numTokens) public payable {
        require(_numTokens > 0, "You need to put a positive number of tokens");
        require(_numTokens <= myTokens(), "You don't have this quantity of tokens");
        //The client returns the tokens to disney
        token.disneyTransfer(msg.sender, address(this), _numTokens);
        //The dinsey returns the ethers to the client
        msg.sender.transfer(tokenPrice(_numTokens));
    }

//----------------------------------------Disney Food--------------------------------------------

    //Events
    event enjoy_food(string);
    event new_food(string, uint);
    event leave_food(string);

    //Data food struct
    struct food {
        string food_name;
        string [] ingredients;
        uint  food_price;
        bool food_condition;
    }

    //Mapping for link a name of a food with a data structure of the food
    mapping (string => food) public FoodMapping;

    //Array for save the name of the attractions
    string [] Foods;

    //Mapping for link a client with their history
    mapping (address => string []) FoodHistory;

    //Function to create a new attractions
    function NewFood(string memory _foodName, uint _price, string [] memory _ingrtedients) public onlyOwner {
        FoodMapping[_foodName] = food(_foodName, _ingrtedients, _price, true);
        Foods.push(_foodName);
        emit new_food(_foodName, _price);
    }

    //Function to leave a food
    function LeaveFood(string memory _foodName) public onlyOwner {
        FoodMapping[_foodName].food_condition = false;
        emit leave_attraction(_foodName);
    }

    //Function to see all the food in disney
    function seeFood() public view returns(string [] memory ) {
        return Foods;
    }

    //Function to buy food and pay tokens
    function buyFood(string memory _foodName) public {
        //Attraction price in tokens
        uint food_tokens = FoodMapping[_foodName].food_price;
        //Verifies the attraction condition
        require(FoodMapping[_foodName].food_condition == true, "The food is not available");
        //Vereifies if the client has enpugh tokens
        require(myTokens() >= food_tokens, "You dont have enough tokens");
        //Send the tokens to disney
        token.disneyTransfer(msg.sender, address(this), food_tokens);
        //Saving the history of the client
        FoodHistory[msg.sender].push(_foodName);
        emit enjoy_food(_foodName);    
    }

    //Function to see the ingredients of the food
    function getIngredients(string memory _foodName) public view returns(string [] memory) {
        return FoodMapping[_foodName].ingredients;
    }

    //Function to see the attractions that the client enjoyed
    function foodHistory() public view returns(string [] memory) {
        return FoodHistory[msg.sender];
    }


}