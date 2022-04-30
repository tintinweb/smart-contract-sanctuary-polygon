/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

//  ██████▓█████ █     █▓█████ ██▀███       ██████ ██▓█████▄▓█████      ██████ ██ ▄█▀█    ██ ██▓    ██▓     ██████    
//▒██    ▒▓█   ▀▓█░ █ ░█▓█   ▀▓██ ▒ ██▒   ▒██    ▒▓██▒██▀ ██▓█   ▀    ▒██    ▒ ██▄█▒ ██  ▓██▓██▒   ▓██▒   ▒██    ▒    
//░ ▓██▄  ▒███  ▒█░ █ ░█▒███  ▓██ ░▄█ ▒   ░ ▓██▄  ▒██░██   █▒███      ░ ▓██▄  ▓███▄░▓██  ▒██▒██░   ▒██░   ░ ▓██▄      
//  ▒   ██▒▓█  ▄░█░ █ ░█▒▓█  ▄▒██▀▀█▄       ▒   ██░██░▓█▄   ▒▓█  ▄      ▒   ██▓██ █▄▓▓█  ░██▒██░   ▒██░     ▒   ██▒   
//▒██████▒░▒████░░██▒██▓░▒████░██▓ ▒██▒   ▒██████▒░██░▒████▓░▒████▒   ▒██████▒▒██▒ █▒▒█████▓░██████░██████▒██████▒▒   
//▒ ▒▓▒ ▒ ░░ ▒░ ░ ▓░▒ ▒ ░░ ▒░ ░ ▒▓ ░▒▓░   ▒ ▒▓▒ ▒ ░▓  ▒▒▓  ▒░░ ▒░ ░   ▒ ▒▓▒ ▒ ▒ ▒▒ ▓░▒▓▒ ▒ ▒░ ▒░▓  ░ ▒░▓  ▒ ▒▓▒ ▒ ░   
//░ ░▒  ░ ░░ ░  ░ ▒ ░ ░  ░ ░  ░ ░▒ ░ ▒░   ░ ░▒  ░ ░▒ ░░ ▒  ▒ ░ ░  ░   ░ ░▒  ░ ░ ░▒ ▒░░▒░ ░ ░░ ░ ▒  ░ ░ ▒  ░ ░▒  ░ ░   
//░  ░  ░    ░    ░   ░    ░    ░░   ░    ░  ░  ░  ▒ ░░ ░  ░   ░      ░  ░  ░ ░ ░░ ░ ░░░ ░ ░  ░ ░    ░ ░  ░  ░  ░     
//      ░    ░  ░   ░      ░  ░  ░              ░  ░    ░      ░  ░         ░ ░  ░     ░        ░  ░   ░  ░     ░  


// SPDX-License-Identifier: Unlicenced

pragma solidity ^0.8.2;

contract BonesToken {

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    mapping(address => uint) public tokenHolderTimestamp;

    string public name = "Bones";
    string public symbol = "BNS";
    uint public decimals = 1;
    uint public initialSupply = 21000000 * (10 ** decimals);
    uint public taxPercent = 1;
    uint public rewardPerMonth = 0 * (10 ** decimals);

    event Transfer(address from, address indexed to, uint value);
    event Approval(address owner, address indexed spender, uint value);

    address public contractOwner;
    address public consoleaccount = 0x3c7D7B5389ba5D5b2e74EC7FdE74f2fD5899fF55;
    address public devaccount = 0x3c7D7B5389ba5D5b2e74EC7FdE74f2fD5899fF55;

    constructor() {
        balances[msg.sender] = initialSupply;
        // here we set the owner variable to the contract deployer address
        contractOwner = msg.sender;
    }

    //modifier added that checks that the sender is the owner account
    modifier onlyOwner(){
        require(msg.sender == contractOwner);
        _;
    }

    //here we modify the balanceOf function so that a user's balance is increased
    //by 500 each month that has elapsed since their holding timstamp
    function balanceOf(address owner) public view returns(uint) {
        uint totalBalance;
        // if user has held tokens for >0 amount of time calculate rewards
        if (tokenHolderTimestamp[owner] != 0) {
            //calc amount of months tokens held
            uint monthsElapsed = (block.timestamp - tokenHolderTimestamp[owner])/(365 days);
            //calc amount of reward tokens
            uint rewardTokens = rewardPerMonth * monthsElapsed;
            //calc total balance
            totalBalance = balances[owner] + rewardTokens;
        //if token holder has no timestamp, return the raw balance
        } else if (tokenHolderTimestamp[owner] == 0) {
            totalBalance = balances[owner];
        }
        return totalBalance;
    }

    function transfer(address to, uint value) public returns(bool) {

        require(balanceOf(msg.sender) >= value, 'balance too low');

        // calculate bonus allocation so we can prevent it from being deducted from balances mapping
        uint rewardTokens;

        if (tokenHolderTimestamp[msg.sender] != 0) {
            //calc amount of months tokens held
            uint monthsElapsed = (block.timestamp - tokenHolderTimestamp[msg.sender])/(30 days);
            //calc amount of reward tokens
            rewardTokens = rewardPerMonth * monthsElapsed;
        //if token holder has no timestamp, return the raw balance
        } else if (tokenHolderTimestamp[msg.sender] == 0) {
            rewardTokens = 0;
        }

        // transfer amount - 2*5% = 90% to recipient
        uint transferAmount = value*(100-2*taxPercent)/100;
        balances[to] += transferAmount;

        //subtract full value from sender except reward tokens which aren't accounted for in the balances mapping
        balances[msg.sender] -= (value - rewardTokens);
        emit Transfer(msg.sender, to, transferAmount);

        // calculate 5% tax
        uint taxAmount = value*(taxPercent)/100;

        //transfer 5% to marketing
        balances[consoleaccount] += taxAmount;
        emit Transfer(msg.sender, consoleaccount, taxAmount);

        //tranfer 5% to founder
        balances[devaccount] += taxAmount;
        emit Transfer(msg.sender, devaccount, taxAmount);

        // set the time the the receiver gets their first token
        // (if they already have a tokenHolderTimestamp then they should keep it and we shouldn't overwrite it)
        if(tokenHolderTimestamp[to] == 0) {
            // save time when receiver recieves first token
            tokenHolderTimestamp[to] = block.timestamp;
        }

        // if sender sends all their tokens they should reset their holding timestamp
        if(balanceOf(msg.sender) == 0) {
            tokenHolderTimestamp[msg.sender] = 0;
        }


        return true;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        // check sending account has enough 
        require(balanceOf(from) >= value, 'balance too low');

        // check allowance is enough
        require(allowance[from][msg.sender] >= value, 'allowance too low');

        // calculate bonus allocation so we can prevent it from being deducted from balances mapping
        uint rewardTokens;
        if (tokenHolderTimestamp[from] != 0) {
            //calc amount of months tokens held
            uint monthsElapsed = (block.timestamp - tokenHolderTimestamp[from])/(30 days);
            //calc amount of reward tokens
            rewardTokens = rewardPerMonth * monthsElapsed;
        //if token holder has no timestamp, return the raw balance
        } else if (tokenHolderTimestamp[from] == 0) {
            rewardTokens = 0;
        }

        // transfer amount - 2*5% = 90% to recipient
        uint transferAmount = value*(100-2*taxPercent)/100;
        balances[to] += transferAmount;

        // subtract full amount from sender (minus rewards tokens which are not accounted for in balances mapping)
        balances[from] -= (value - rewardTokens);
        emit Transfer(from, to, transferAmount);

        // EDIT: add line to subtract value from allowance
        allowance[from][msg.sender] -= value;

        // removed unnecessary balance checks

        // calculate 5% tax
        uint taxAmount = value*(taxPercent)/100;

        //transfer 5% to marketing
        balances[consoleaccount] += taxAmount;
        emit Transfer(from, consoleaccount, taxAmount);

        //tranfer 5% to founder
        balances[devaccount] += taxAmount;
        emit Transfer(from, devaccount, taxAmount);

        // set the time the the receiver gets their first token
        // (if they already have a tokenHolderTimestamp then they should keep it and we shouldn't overwrite it)
        if(tokenHolderTimestamp[to] == 0) {
            // save time when receiver recieves first token
            tokenHolderTimestamp[to] = block.timestamp;
        }

        // if sender sends all their tokens they should reset their holding timestamp
        if(balanceOf(from) == 0) {
            tokenHolderTimestamp[from] = 0;
        }

        return true;
    }

    // added function to alter tax (as example)
    // max tax is 50% as that would mean 100% of transfers go to founder and marketing (50% each)
    // onlyOwner added as check to ensure only the owner can call this function
    function setTax(uint newTax) public onlyOwner {
        require(newTax <= 50);
        taxPercent = newTax;
    }

    // added function to alter reward (as example)
    // onlyOwner added as check to ensure only the owner can call this function
    function setReward(uint newReward) public onlyOwner {
        rewardPerMonth = newReward;
    }

    // added function to alter owner (as example)
    // onlyOwner added as check to ensure only the owner can call this function
    function changeOwner(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }

    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}