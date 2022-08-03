// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Survey.sol";

contract SurveyFactory {
    mapping(string => address) public surveys;
    constructor(){

    }

    function deploySurvey(string memory ipfsAddress, address _currency, uint256 _bounty) external returns (address surveyAddress) {
         require(surveys[ipfsAddress] == address(0x0), "Survey already exists");
         address surveyAddress = address(new Survey(ipfsAddress, _currency, _bounty, msg.sender));
         surveys[ipfsAddress] = surveyAddress;
         emit SurveyCreation(msg.sender, ipfsAddress, block.timestamp, _currency, _bounty, surveyAddress);
         return surveyAddress;
    }

    event SurveyCreation(address indexed owner, string surveyAddress, uint256 creationDate, address currency, uint256 bounty, address surveyContract);
}