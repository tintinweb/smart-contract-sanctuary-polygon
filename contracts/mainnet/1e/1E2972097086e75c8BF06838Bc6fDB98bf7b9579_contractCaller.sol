/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface buyInterface {
    event Buy(address indexed buyer, uint indexed value);
}

contract calledToken {
     function approve(address spender, uint amount) external returns (bool) {}
     function transfer(address recipient, uint amount) external returns (bool) {}
     function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {}
    function allowance(address owner, address spender) external view returns (uint){}
}

contract contractCaller is buyInterface {
    calledToken c;
    bool public pause = true;
    address public contractOwner;
    uint public amountDisponible = 0;
    uint public amountSold = 0;
    uint public claimedTokens = 0;
    bool _claimActive = false;
    mapping(address => uint) public buyedTokens;

    constructor () {
        contractOwner  = msg.sender;
        c = calledToken(0x6E328eba6CB1ABd175F6622262DB1a3a2AfE6Da8);
    }


    modifier Pause(){
        if(msg.sender != contractOwner) require(pause == false,"Contract Paused");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not owner");
        _;
    }

    modifier claimActive(){
        require(_claimActive == true);
        _;
    }

    function setCalledToken(address _address) public onlyOwner{
        c = calledToken(_address);
    }

    function disponible(uint _amount) public onlyOwner{
        amountDisponible += _amount;
    }

    function changeClaimActive() public onlyOwner{
        _claimActive = !_claimActive;
    }

    function changePause() public onlyOwner{
        pause = !pause;
    }

    function approve(address spender, uint amount) external onlyOwner Pause returns (bool) {
        return c.approve(spender,amount);
    }

    function transfer(address recipient, uint amount) external onlyOwner Pause returns (bool) {
        return c.transfer(recipient,amount);
    }

    function transferFrom( address sender, address recipient, uint amount ) external onlyOwner Pause returns (bool) {
        return c.transferFrom(sender,recipient,amount);
    }

    function allowance(address owner, address spender) external view Pause returns (uint){
        return c.allowance(owner,spender);
    }

    function buy() public payable Pause {
        require(msg.value >= 1 ether,"Incorrect value > 0");
        require(msg.value <= 100 ether,"Incorrect value > 0");
        require(amountDisponible >= msg.value,"Insufficient amount disponible");

        uint amount = msg.value;
        uint sendTokens = amount*100;
        buyedTokens[msg.sender] += sendTokens;
        amountSold += sendTokens;
        amountDisponible -= sendTokens;
        emit Buy(msg.sender,amount);

    }

    function claim() public claimActive Pause returns (bool){
        uint amount = buyedTokens[msg.sender];
        require(amount > 0 , "You dont have tokens");
        c.transfer(msg.sender,amount);
        buyedTokens[msg.sender] = 0;
        claimedTokens += amount;
        return true;
    }

    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function makeContract() public onlyOwner{
        uint amount = address(this).balance;
        (bool success,) = contractOwner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

}