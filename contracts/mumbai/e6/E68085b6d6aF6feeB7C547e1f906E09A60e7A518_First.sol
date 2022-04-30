/**
 *Submitted for verification at polygonscan.com on 2022-04-29
*/

//SPDX-License-Identifier: Muaz
pragma solidity 0.8.0;
contract First{

    struct Task1{
        uint amount;
        uint timecreated;
        uint Total_no_of_Payments;
        uint _reward;
        uint _treward;
        }

    mapping(address => Task1) public users;
    
    function Deposit() public payable {
        require(users[msg.sender].amount==0,"Kindly Take Your Reward First");
        users[msg.sender].amount += msg.value;
        users[msg.sender].timecreated = block.timestamp;
        users[msg.sender].Total_no_of_Payments++;
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function withdraw(address payable _to) public{
        _to.transfer(users[msg.sender].amount);
    }
    function reward() public payable{
        require(users[msg.sender].amount!=0,"You Have already taken the Reward");
        require(block.timestamp>users[msg.sender].timecreated+10 seconds,"PLEASE WAIT");
        users[msg.sender]._reward=(users[msg.sender].amount)*2;
        require(address(this).balance>=users[msg.sender]._reward, "Insufficient Balance in Contract");
        payable(msg.sender).transfer(users[msg.sender]._reward);
        users[msg.sender].amount = 0;
    }

}