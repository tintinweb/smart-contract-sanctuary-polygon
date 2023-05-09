/**
 *Submitted for verification at polygonscan.com on 2023-05-09
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract NewExcuse{
     receive() external payable{}
        function DelayOneDay() public pure returns(string memory){
            return "Exchange is still processing transfer, refunds will start in 24 hours PST";
        }
        function DelayTwoDays() public pure returns(string memory){
            return "Mixer got stuck, it was communicated to me that funds will arrive in exactly 48 hours PST";
        }
        function DelayThreeDays() public pure returns(string memory){
            return "Too many threats, have to relocate to a new island to protect my family. Refunds will start in 3 days PST";
        }
        function DelayFourDays() public pure returns(string memory){
            return "Laptop blew up, will take exactly 4 days to get situated on a new laptop. 4 Days PST have patients.";
        }
        function DelayTwoWeeks() public pure returns(string memory){
            return "Threats have only gotten worse. Thankfully my friend who works at NASA can book me a one way flight to the moon. Expected arrival time is set for 2 weeks PST, refunds will start PST once I am situated, have patients.";
        }
}