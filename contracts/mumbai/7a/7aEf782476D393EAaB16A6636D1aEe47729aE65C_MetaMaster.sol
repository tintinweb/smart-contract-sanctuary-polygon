/**
 *Submitted for verification at polygonscan.com on 2023-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract MetaMaster{
    address public  creator;
    mapping(address => uint) public balances;
    mapping (address => uint) public depositCount1;
    //mapping (address => mapping(address => bool)) public firstDepositWithReferrer;///
    constructor(address _creator) {
        creator = _creator;
    }
    uint minTimeBetweenWithdrawals = 1 minutes;//
    uint lastWithdrawl;//
    function deposit(uint amount, address _referrer) public payable{
        require(amount >=50 ,"low aamount");
        uint refferBonus = amount*5/100;
        uint creatorpay=amount*2/100;
        //require(depositCount[refferer] >=1 || msg.sender == creator, "Your referrer has not deposited money");
        if((depositCount1[msg.sender] ==0) && (depositCount1[_referrer]>=1)) {
           payable(_referrer).transfer(refferBonus);
            balances[_referrer] += refferBonus;
            balances[msg.sender] += amount - creatorpay - refferBonus;
            depositCount1[msg.sender] ++;
        }
        else {
            balances[msg.sender] += amount - creatorpay;
            depositCount1[msg.sender] ++;
        }
        balances[creator] += creatorpay;
        payable(creator).transfer(creatorpay);
    }
    function withdrawMoney(address _userAddress,uint _amount) public returns(uint256) {
        require(block.timestamp >= lastWithdrawl + minTimeBetweenWithdrawals, "you can only withdraw once in 15 days" );//
        lastWithdrawl = block.timestamp;//
        payable(_userAddress).transfer(_amount);
        uint amount1  = (_amount/100)*5 ;//
        payable(creator).transfer(_amount - amount1);//
        balances[creator] += amount1;
        balances[msg.sender] -= _amount;
        return amount1;
    }
 }