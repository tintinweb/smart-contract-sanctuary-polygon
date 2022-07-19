/**
 *Submitted for verification at polygonscan.com on 2022-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20{
    constructor(){}
    function transferFrom(address from,address to,uint256 amount) public{}
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
    
    //Events
    event TransactionDone(address indexed shop, address sender,address token,uint value,string data);

    //Managers list
    mapping(address => bool) Managers;

    constructor(){
        Managers[msg.sender] = true;
    }

    //Function for managers
    modifier onlyManager {
      require(Managers[msg.sender] == true);
      _;
    }

    function setManager(address manager, bool state) public onlyManager{
        Managers[manager] = state;
    }

    function setRewards(address tokenAddress, bool state) public onlyManager{
        rewardsEnabled = state;
        rewardsTokenAddress = tokenAddress;
    }

    function setBan(address wallet, bool state) public onlyManager{
        bannedAddress[wallet] = state;
    }

    //Clear a shop's transactions history
    function clearShopTransactions() public{
        transactionsCount[msg.sender] = 0;
    }

    function Pay(address shop,string memory data) public payable{
        Transaction memory transaction = Transaction(msg.sender,0x0000000000000000000000000000000000000000,msg.value,data);
        //FAIRE LE SPLIT
        //ENREGISTRER DANS L'HISTOIRY
        emit TransactionDone(shop,msg.sender,0x0000000000000000000000000000000000000000,msg.value,data);
    }

    function PayWithToken(address shop,string memory data,address tokenAddress,uint value) public{
        ERC20 Token = ERC20(tokenAddress);
        Transaction memory transaction = Transaction(msg.sender,tokenAddress,value,data);
        Token.transferFrom(msg.sender,address(this),value);
        //FAIRE LE SPLIT
        //ENREGISTRER DANS L'HISTOIRY
        emit TransactionDone(shop,msg.sender,tokenAddress,value,data);
    }
}