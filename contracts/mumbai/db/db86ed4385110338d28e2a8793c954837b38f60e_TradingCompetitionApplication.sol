/**
 *Submitted for verification at polygonscan.com on 2022-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TradingCompetitionApplication {

    address public admin;
    mapping(address => bool) public applicants; 

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    /**
     * @dev applyToTrade set application for address true     
     */
    function applyToTrade() external {
        applicants[msg.sender] = true; 
    }
    
    /**
     * @dev applyToTrade set applications for address true     
     * @dev manualApplicants list of applicants to manually add
     */
    function applyToTradeMulti(address[] memory manualApplicants) external onlyAdmin {
        for (uint i=0; i< manualApplicants.length; i++) {
            applicants[manualApplicants[i]] = true; 
        }
    }
    
    /**
     * @dev set admin set application for address true     
     * @dev newAdmin 
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        admin = newAdmin;
    }
}