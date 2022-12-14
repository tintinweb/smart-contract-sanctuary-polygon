/**
 *Submitted for verification at polygonscan.com on 2022-12-14
*/

/**
 *Submitted for verification at polygonscan.com on 2022-12-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol";


contract Splitter {

    address private owner;

    constructor () {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only Owner authorize to use this function");
        _;
    }

    receive() external payable {}
    function deposit() external payable onlyOwner {}

    function withdraw(uint _amt) external onlyOwner {
        require(address(this).balance >= _amt, "Insufficient Balance");
        payable(owner).transfer(_amt); // this will debit address(this).balance
    }

    function wallet_transfer(
        address[] memory acc_adres, 
        uint8[] memory split 
        ) external payable 
    {
        require(acc_adres.length > 1, "Minimum two accounts require to splitting the payment");
        require(acc_adres.length == split.length, "Acounts and Splits mismatch");
        require(msg.value > 0, "Not enough Balance to split");
        uint totalAmount = msg.value;
        payable(address(this)).transfer(totalAmount); //recieve fumction calls here
        //console.log("contract balance :", address(this).balance);
        uint temp_amt = 0;
        for(uint8 i=0; i<acc_adres.length; i++){
            if(i == acc_adres.length-1){
                payable(acc_adres[i]).transfer(totalAmount); // this will debit address(this).balance
                //console.log("contract balance should be zero :", address(this).balance);
            }
            else{
                temp_amt = (msg.value * split[i])/100;
                //console.log("temp_amt :", temp_amt);
                payable(acc_adres[i]).transfer(temp_amt); // this will debit address(this).balance
                totalAmount -= temp_amt;
                //console.log("totalAmount :", totalAmount);
            }
                
        }
    }

    function contract_transfer (
        uint _amount,
        address[] memory acc_adres, 
        uint8[] memory split 
        ) external onlyOwner
    {
        require(acc_adres.length > 1, "Minimum two accounts require to splitting the payment");
        require(acc_adres.length == split.length, "Acounts and Splits mismatch");
        require(address(this).balance >= _amount, "Not enough Balance to split");
        uint totalAmount = _amount;
        //payable(totalAmount).transfer(address(this)); //this will debit address(this).balance
        //console.log("contract balance :", address(this).balance);
        uint temp_amt = 0;
        for(uint8 i=0; i<acc_adres.length; i++) {
            if(i == acc_adres.length-1){
                payable(acc_adres[i]).transfer(totalAmount); // this will debit address(this).balance
                //console.log("contract balance :", address(this).balance);
            }
            else {
                temp_amt = (_amount * split[i])/100;
                //console.log("temp_amt :", temp_amt);
                payable(acc_adres[i]).transfer(temp_amt); // this will debit address(this).balance
                totalAmount -= temp_amt;
                //console.log("_amount :", _amount);
            }
                
        }
    }

    function whostheOwner() public view returns (address) {
        return owner;
    } 

    function changeOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}