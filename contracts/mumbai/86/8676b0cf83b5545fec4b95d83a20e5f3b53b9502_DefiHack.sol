/**
 *Submitted for verification at polygonscan.com on 2022-08-22
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >0.8.0 ;

contract DefiHack{

    mapping(address => mapping(address => bool)) internal contract_hack_dispute;
    mapping(address => bool) internal contract_dispute_pending;
    mapping(address => bool) internal contract_hacked;
    mapping(address => uint256) internal stakes;
    address payable owner;

    constructor(){
        owner = payable(msg.sender);
    }

    function isContractHacked(address contract_address) public view returns(bool hack_status) {
        return contract_hacked[contract_address];
    }

    function isDisputePending(address contract_address) public view returns(bool dispute_pending) {
        return contract_dispute_pending[contract_address];
    }

    function getUserStake(address contract_address) public view returns(uint256 user_stake){
        return stakes[contract_address];
    }

    function hackDispute(address contract_address) external payable {
        require(contract_dispute_pending[contract_address] == false);
        require(msg.value >= 0.001 ether);
        (bool sent, bytes memory data) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        contract_dispute_pending[contract_address] = true;
        contract_hack_dispute[contract_address][msg.sender] = true;
        stakes[msg.sender] = msg.value;
    }

    function approveHackDispute(address contract_address, address payable disputer_address ) external payable {
        require(owner == msg.sender);
        require(stakes[owner] > 0);
        (bool sent, bytes memory data) = disputer_address.call{value: stakes[owner]+stakes[disputer_address]}("");
        require(sent, "Failed to send Ether");
        //disputer_address.transfer(stakes[owner]+stakes[disputer_address]);
        
        contract_dispute_pending[contract_address] = false;
        contract_hacked[contract_address] = true;
        contract_hack_dispute[contract_address][disputer_address] = false;
        stakes[owner] = 0;
        stakes[disputer_address] = 0;

    }

    function rejectHackDispute(address contract_address,address disputer_address) external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = owner.call{value: stakes[disputer_address]}("");
        require(sent, "Failed to send Ether");
        contract_dispute_pending[contract_address] = false;
        contract_hack_dispute[contract_address][disputer_address] = false;
        stakes[disputer_address] = 0;
    }

    function refundUserStake(address contract_address,address payable disputer_address) external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = disputer_address.call{value: stakes[disputer_address]}("");
        require(sent, "Failed to send Ether");
        contract_dispute_pending[contract_address] = false;
        contract_hack_dispute[contract_address][disputer_address] = false;
        stakes[disputer_address] = 0;
    }

    function addRewards() external payable {
        require(owner == msg.sender);
        (bool sent, bytes memory data) = address(this).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        stakes[owner] = stakes[owner] + msg.value;
    }

    function updateContractStatus(address contract_address, bool is_hacked) external {
        require(owner == msg.sender);
        require(contract_dispute_pending[contract_address]==false);
        contract_hacked[contract_address] = is_hacked;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}