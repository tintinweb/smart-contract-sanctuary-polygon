/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0 ;

contract DefiHack{

    struct ContractData {
        bool has_been_added;
        bool contract_dispute_pending;
        bool contract_hacked;
    }

    struct DisputerData {
        bool has_been_added;
        uint256 stake;
        bool is_disputing;
    }

    struct RewardData {
        uint256 stake;
    }

    uint256 public contract_count;
    uint256 public disputer_count;
    mapping(address => mapping(address => bool)) public contract_hack_dispute;
    mapping(address => DisputerData) public disputer_data;
    mapping(address => ContractData) public contract_data;
    RewardData public reward_data;
    mapping(uint256 => address) public disputer_list;
    mapping(uint256 => address) public contract_list;

    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }

    function isContractDisputedByUser(address contract_address, address disputer) public view returns(bool is_disputing){
        return contract_hack_dispute[contract_address][disputer];
    }

    function hackDispute(address contract_address) external payable {
        require(contract_data[contract_address].contract_dispute_pending == false);
        require(msg.value >= 0.001 ether);
        (bool sent, bytes memory data) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        contract_data[contract_address].contract_dispute_pending = true;
        contract_hack_dispute[contract_address][msg.sender] = true;

        disputer_data[msg.sender].stake = msg.value;
        disputer_data[msg.sender].is_disputing = true;

        if (!disputer_data[msg.sender].has_been_added) {
            disputer_count+=1;
            disputer_data[msg.sender].has_been_added = true;
        }
        if (!contract_data[contract_address].has_been_added) {
            contract_count+=1;
            contract_data[contract_address].has_been_added = true;
        }
    }

    function approveHackDispute(address contract_address, address payable disputer_address ) external payable {
        require(owner == msg.sender);
        require(reward_data.stake > 0);
        (bool sent, bytes memory data) = disputer_address.call{value: reward_data.stake+disputer_data[disputer_address].stake}("");
        require(sent, "Failed to send Ether");
        
        contract_data[contract_address].contract_dispute_pending = false;
        contract_data[contract_address].contract_hacked = true;
        contract_hack_dispute[contract_address][disputer_address] = false;
        reward_data.stake = 0;
        disputer_data[disputer_address].stake = 0;
    }

    function rejectHackDispute(address contract_address,address disputer_address) external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = owner.call{value: disputer_data[disputer_address].stake}("");
        require(sent, "Failed to send Ether");
        contract_data[contract_address].contract_dispute_pending = false;
        contract_hack_dispute[contract_address][disputer_address] = false;
        disputer_data[disputer_address].stake = 0;
    }

    function refundUserStake(address contract_address,address payable disputer_address) external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = disputer_address.call{value: disputer_data[disputer_address].stake}("");
        require(sent, "Failed to send Ether");
        contract_data[contract_address].contract_dispute_pending = false;
        contract_hack_dispute[contract_address][disputer_address] = false;
        disputer_data[disputer_address].stake = 0;
    }

    function addRewards() external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");

        reward_data.stake += msg.value;
    }

    function updateContractStatus(address contract_address, bool is_hacked) external {
        require(owner == msg.sender);
        require(contract_data[contract_address].contract_dispute_pending==false);
        contract_data[contract_address].contract_hacked = is_hacked;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}