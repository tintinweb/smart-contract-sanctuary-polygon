/**
 *Submitted for verification at polygonscan.com on 2023-01-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TradingCompetitionApplication {

    address public admin;
    // string here being the referrer 
    mapping(address => string) public applicants; 

    modifier onlyAdmin() {
        require(msg.sender == admin, "not admin");
        _;
    }

    constructor(){
        admin = msg.sender;
    }

    /**
     * @dev applyToTrade set application for address to referrer     
     * @dev referrer - the referrer that brought the candidate to the games     
     */
    function applyToTrade(string calldata referrer) external {
        applicants[msg.sender] = referrer; 
    }
    
    /**
     * @dev applyToTradeMultiForRefferer set applications for address true     
     * @dev manualApplicants list of applicants to manually add 
     * @dev referrer - single referrer to platform
     */
    function applyToTradeMultiForRefferer(address[] calldata manualApplicants, string calldata referrer) external onlyAdmin {
        for (uint i=0; i< manualApplicants.length; i++) {
            applicants[manualApplicants[i]] = referrer; 
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