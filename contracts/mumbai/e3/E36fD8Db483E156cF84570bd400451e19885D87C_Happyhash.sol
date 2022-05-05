/**
 *Submitted for verification at polygonscan.com on 2022-05-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Happyhash {
    address public owner;
    mapping (address => uint) public balances;
    event Sent(address from, address to, uint amount);

    uint public gameCount = 0;
    mapping (uint => Game) public games;
    struct Game {
        uint id;
        address playerAddress;
        string ruleType;
        uint betAmount;
        uint winAmount;
        string betStatus;
        uint betOdds;
        string dai;
    }

    constructor() {
        owner = msg.sender;
    }

    function mint(address reciever, uint amount) public {
        require(owner == msg.sender, "Minting can be done only by the smart contract owner");
        require(amount < 1e60);
        balances[reciever] += amount;
    }

    function send(address reciever, uint amount) public {
        require(amount < balances[msg.sender], "Ooooops you do not have enough balance");
        balances[msg.sender] -= amount;
        balances[reciever] += amount;
        emit Sent(msg.sender, reciever, amount);
    }

    function getAllgames() public view returns(Game[] memory) {
        Game[] memory id = new Game[](gameCount);
        for (uint i = 0; i < gameCount; i++) {
            Game storage game = games[i];
            id[i] = game;
        }
        return id;
    }

    function blockValue() view public returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }
    
    function oddVsEven(uint amount, uint hashDigit) public returns (string memory rst) {
        uint i = 1;
        string memory _dai = "2 - 2000";
        string memory rule = "old vs even";
        uint odds = 2;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            for(i; i < 4; i++){
                if(amount / 1000 == 3){
                    status = "win";
                }else if(amount / 100 == 2){
                    status = "win";
                }else if(amount / 10 == hashDigit){
                    status = "win";
                }else{
                    status = "loss";
                }
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function numberOrLetter(uint amount, uint hashDigit) public returns (string memory rst) {
        string memory _dai = "2 - 2000";
        string memory rule = "Number or a Letter";
        uint odds = 2;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            if(hashDigit >= 0){
                status = "win";
            }else{
                status = "loss";
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function bigVsSmall(uint amount, uint hashDigit) public returns (string memory rst) {
        string memory _dai = "2 - 2000";
        string memory rule = "big vs small";
        uint odds = 2;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            if(amount / 1000 <= 4 || amount / 100 <= 4 || amount / 10 <= 4){
                if(amount / 1000 == hashDigit){
                    status = "win";
                }else if(amount / 100 == hashDigit){
                    status = "win";
                }else if(amount / 10 == hashDigit){
                    status = "win";
                }else{
                    status = "loss";
                }
            }else if(amount / 1000 <= 9 || amount / 100 <= 9 || amount / 10 <= 9){
                if(amount / 1000 == hashDigit){
                    status = "win";
                }else if(amount / 100 == 2){
                    status = "win";
                }else if(amount / 10 == 1){
                    status = "win";
                }else{
                    status = "loss";
                }
            }else{
                status = "loss";
            }
            

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function guessNumber(uint amount, uint hashDigit) public returns (string memory rst) {
        uint i = 1;
        string memory _dai = "2 - 2000";
        string memory rule = "Guess the Number";
        uint odds = 10;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            for(i; i < 4; i++){
                if(amount / 1000 == hashDigit){
                    status = "win";
                }else if(amount / 100 == hashDigit){
                    status = "win";
                }else if(amount / 10 == hashDigit){
                    status = "win";
                }else{
                    status = "loss";
                }
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function threeKinds(uint amount, uint digitOne, uint digitTwo, uint digitThree) public returns (string memory rst) {
        string memory _dai = "2 - 2000";
        string memory rule = "three of a kind";
        uint odds = 88;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            if(digitOne == digitTwo && digitTwo == digitThree){
                status = "win";
            }else{
                status = "loss";
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function pairs(uint amount, uint digitOne, uint digitTwo, uint digitThree) public returns (string memory rst) {
        string memory _dai = "2 - 2000";
        string memory rule = "Pairs";
        uint odds = 20;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            if(digitOne == digitTwo || digitTwo == digitThree || digitOne == digitThree){
                status = "win";
            }else{
                status = "loss";
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

    function straightOrder(uint amount, uint digitOne, uint digitTwo, uint digitThree) public returns (string memory rst) {
        string memory _dai = "2 - 2000";
        string memory rule = "Straight Order";
        uint odds = 18;
        string memory status = "";
        uint winAmount = 0;
        if( amount > 2 && amount < 2000 ){
            if(digitOne > digitTwo || digitTwo > digitThree){
                status = "win";
            }else if(digitOne < digitTwo || digitTwo < digitThree){
                status = "win";
            }else{
                status = "loss";
            }

            if(keccak256(bytes(status)) == keccak256(bytes("win"))){
                winAmount = amount * odds;
                require(winAmount < balances[owner], "Ooooops you do not have enough balance");
                balances[owner] -= winAmount;
                balances[msg.sender] += winAmount;
                emit Sent(owner, msg.sender, winAmount);
            }

            games[gameCount] = Game(gameCount, msg.sender, rule, amount, winAmount, status, odds, _dai);
            gameCount += 1;
            
        }else{
            rst = "Bet amount must be between 2 - 2000";
        }
    }

}