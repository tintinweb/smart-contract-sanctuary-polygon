/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20{
    constructor(){}
    function transferFrom(address from,address to,uint256 amount) public{}
    function transfer(address to,uint256 amount) public{}
}

contract PayBlobTunnel {

    /* Our Transaction structure
     * encryptedData is data related to the transaction sent by the user
     * like real name, delivery address ...
     * This data is encrypted with the shop's public key so only him can reveal it
     */
    struct Transaction {
        address sender;
        address token;
        uint value;
        string encryptedData;
    }   

    //Keep track of the transactions per shop address
    mapping(address => mapping(int => Transaction)) public transactionsHistory;
    mapping(address => int) public transactionsCount;

    //Just in case ...
    mapping(address => bool) public bannedAddress;

    // Data related to rewards for buyers & sellers
    bool public rewardsEnabled;
    address public rewardsTokenAddress;
    address public swapingContract;
    bool public burningEnabled;
    //Events
    event TransactionDone(address indexed shop, address sender,address token,uint value,string data);

    //Managers list
    mapping(address => bool) Managers;

    //Fees & Rewards rate
    uint public Fees = 2;
    uint public Rewards;
    address payable public feesAddress;
    constructor(){
        Managers[msg.sender] = true;
        feesAddress = payable(0x0Ca2d160bF83079456BA175435f06354cdb6beBe);
    }

    //Function for managers
    modifier onlyManager {
      require(Managers[msg.sender] == true);
      _;
    }

    function setManager(address manager, bool state) public onlyManager{
        Managers[manager] = state;
    }

    function setFees(uint value) public onlyManager{
        Fees = value;
    }

    function setRewardsRate(uint value) public onlyManager{
        Rewards = value;
    }

    function setRewards(address tokenAddress, bool state) public onlyManager{
        rewardsEnabled = state;
        rewardsTokenAddress = tokenAddress;
    }

    function setBurning(address tokenAddress, bool state) public onlyManager{
        burningEnabled = state;
        swapingContract = tokenAddress;
    }

    function setBan(address wallet, bool state) public onlyManager{
        bannedAddress[wallet] = state;
    }

    //Clear a shop's transactions history
    function clearShopTransactions() public{
        transactionsCount[msg.sender] = 0;
    }

    function Pay(address payable shop,string memory data) public payable{
        require(!bannedAddress[shop],"This shop is banned");
        require(!bannedAddress[msg.sender],"You are banned from this service ");
        Transaction memory transaction = Transaction(msg.sender,0x0000000000000000000000000000000000000000,msg.value,data);
        
        shop.transfer(msg.value*(100-Fees)/100);
        feesAddress.transfer(msg.value*(Fees)/100);
        //Rwards
        transactionsCount[shop] += 1;
        transactionsHistory[shop][transactionsCount[shop]] = transaction;
        emit TransactionDone(shop,msg.sender,0x0000000000000000000000000000000000000000,msg.value,data);
    }

    function PayWithToken(address shop,string memory data,address tokenAddress,uint value) public{
        require(!bannedAddress[shop],"This shop is banned");
        require(!bannedAddress[msg.sender],"You are banned from this service ");
        ERC20 Token = ERC20(tokenAddress);
        Transaction memory transaction = Transaction(msg.sender,tokenAddress,value,data);
        Token.transferFrom(msg.sender,address(this),value);
        
        Token.transfer(shop, value*(100-Fees)/100);
        Token.transfer(feesAddress, value*(Fees)/100);
        //rewards
        transactionsCount[shop] += 1;
        transactionsHistory[shop][transactionsCount[shop]] = transaction;
        emit TransactionDone(shop,msg.sender,tokenAddress,value,data);
    }
}