//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import { StringUtils } from "./stringUtils.sol";


contract Fundme {
    string public name;
    string public description;
    string public externalSite;
    uint256 public deadline;
    uint256 public fundingGoal;
    address payable public owner;
    

    mapping(address => uint256) public contributors;

    event donated(string successMessage, uint256 amount, address participant, uint256 currentBalance);
    event withdrawn(string successMessage, uint256 amount, address owner, uint256 delta);

    function initialize(string memory _name, 
                string memory _description, 
                string memory _externalSite, 
                uint256 _deadline, 
                uint256 _fundingGoal, 
                address _owner) public {

        require (StringUtils.strlen(_name) > 0);
        require (StringUtils.strlen(_description) > 0);
        require(_deadline > (1 days + block.timestamp));
        require(_fundingGoal > 0);
        name = _name;
        description = _description;
        externalSite = _externalSite;
        deadline = _deadline;
        fundingGoal = _fundingGoal;
        owner = payable(_owner);
    }

    function donate() external payable returns (string memory _contributed) {
        require(msg.value >= .001 ether, 'Your contribution must be greater than 0.001 ETH');
        require(block.timestamp <= deadline, 'The time to contribute to this cause has passed.');
        contributors[msg.sender] += msg.value;
        emit donated('You have successfully donated to this cause.', msg.value, msg.sender, address(this).balance);
        _contributed = 'Your donation was successful';
    }

    function viewOverview() public view returns (string memory _name, 
                                                 string memory _description, 
                                                 string memory _externalSite,
                                                 uint256 _goal, 
                                                 uint256 _bal, 
                                                 uint256 _timeRemaining){
        _name = name;
        _description = description;
        _externalSite = externalSite;
        _goal = fundingGoal;
        _bal = address(this).balance;
        _timeRemaining = deadline - block.timestamp;
    }

    function withDraw() public onlyOwner {
        require(address(this).balance > 0);
        require(block.timestamp > deadline);
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Failed to withdraw donations.");   
    }
     

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}