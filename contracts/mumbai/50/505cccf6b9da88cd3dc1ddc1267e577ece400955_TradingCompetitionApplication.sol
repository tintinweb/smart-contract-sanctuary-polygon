/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TradingCompetitionApplication {

    mapping(address => bool) public applicant;

    /**
     * @dev applyToTrade set application for address true     
     */
    function applyToTrade() external {
        applicant[msg.sender] = true; 
    }
}