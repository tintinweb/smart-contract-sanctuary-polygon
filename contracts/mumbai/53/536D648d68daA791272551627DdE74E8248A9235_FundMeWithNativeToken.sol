// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error FundMe_NotOwner();
error FundMe_WithdrawCallFailed();

contract FundMeWithNativeToken {
    address private immutable i_owner;
    mapping (address => uint256) private s_not_withdrawn_addressToAmountFunded;
    mapping (address => uint256) private s_addresToAmountFunded;
    address[] private s_all_funders;
    address[] private s_current_funders;

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert FundMe_NotOwner();
        _;
    }

    constructor() {
        i_owner = msg.sender;
    }

    function fund() public payable {
        s_not_withdrawn_addressToAmountFunded[msg.sender] += msg.value;
        if (s_not_withdrawn_addressToAmountFunded[msg.sender] == 0) {
            s_current_funders.push(msg.sender);
        }
        s_addresToAmountFunded[msg.sender] += msg.value;
        if (s_addresToAmountFunded[msg.sender] == 0) {
            s_all_funders.push(msg.sender);
        }
    }

    function withdraw() public payable onlyOwner {
        address[] memory funders = s_current_funders;

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_not_withdrawn_addressToAmountFunded[funder] = 0;
        }
        s_current_funders = new address[](0);

        (bool callSuccess, ) = i_owner.call{
            value: address(this).balance
        }("");
        if (!callSuccess) revert FundMe_WithdrawCallFailed();
    }

    // receive () external payable {
    //     s_not_withdrawn_addressToAmountFunded[msg.sender] += msg.value;
    //     if (s_not_withdrawn_addressToAmountFunded[msg.sender] == 0) {
    //         s_current_funders.push(msg.sender);
    //     }
    //     s_addresToAmountFunded[msg.sender] += msg.value;
    //     if (s_addresToAmountFunded[msg.sender] == 0) {
    //         s_all_funders.push(msg.sender);
    //     }
    // }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getAllFunders() public view returns (address[] memory) {
        return s_all_funders;
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addresToAmountFunded[funder];
    }

    function getStoredBalance() public view returns (uint256) {
        return address(this).balance;
    }
}