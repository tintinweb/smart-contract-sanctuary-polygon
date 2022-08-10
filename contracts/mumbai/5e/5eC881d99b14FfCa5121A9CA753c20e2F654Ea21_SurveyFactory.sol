// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Survey.sol";

contract SurveyFactory {
    mapping(string => address) public surveys;

    function deploySurvey(string memory ipfsAddress, address _currency, uint256 _reward, uint256 _bountyTotal, bool _whitelistExist, address[] memory _whitelist, bytes32 _merkleRoot, address _trustedForwarder) external returns (address surveyAddress) {
         require(surveys[ipfsAddress] == address(0x0), "Survey already exists");
        require(IERC20(_currency).balanceOf(msg.sender) >= _bountyTotal, "Not enough funds");

         address _surveyAddress = address(new Survey(ipfsAddress, _currency, _reward, _bountyTotal,msg.sender, _whitelistExist, _whitelist, _merkleRoot, _trustedForwarder));
        IERC20(_currency).transferFrom(msg.sender, _surveyAddress, _bountyTotal);
         surveys[ipfsAddress] = _surveyAddress;

         emit SurveyCreation(msg.sender, ipfsAddress, block.timestamp, _currency, _reward, _bountyTotal, _surveyAddress, _whitelistExist);
        return _surveyAddress;
    }
    event SurveyCreation(address indexed owner, string surveyAddress, uint256 creationDate, address currency, uint256 reward, uint256 bountyTotal, address surveyContract, bool whitelistExist);
}