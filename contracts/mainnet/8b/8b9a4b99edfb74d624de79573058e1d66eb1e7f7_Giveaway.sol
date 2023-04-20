/**
 *Submitted for verification at polygonscan.com on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Giveaway {
    
    address public owner1;
    address public owner2;
    uint256 public giveawayAmount = 1 ether;
    uint256 public totalPaidOut = 0;
    mapping(address => bool) public claimed;
    
    event Funds(address from, uint256 amount, uint256 timestamp);

    receive() external payable {
        emit Funds(msg.sender, msg.value, block.timestamp);
    }
    fallback() external payable {}

    constructor(
        address _owner1Addr,
        address _owner2Addr
    ) {
        owner1 = _owner1Addr;
        owner2 = _owner2Addr;
    }

    function giveaway(address[] memory winnerList) external {
        require(msg.sender == owner1 || msg.sender == owner2, "Only owners can initiate this transaction.");
        require(getBalance() > 0, "Insufficient contract balance.");

        for (uint256 i = 0; i < winnerList.length; i++) {
            if (claimed[winnerList[i]] == false) {
                (bool transfer, ) = payable(winnerList[i]).call{value: giveawayAmount}("");
                require(transfer, "Transfer MATIC failed.");
                claimed[winnerList[i]] = true;
                totalPaidOut++;
            }
        }
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function checkClaimed(address wallet) public view returns(bool) {
        return claimed[wallet];
    }

    function updateGiveawayAmount(uint256 newAmount) external {
        require(msg.sender == owner1 || msg.sender == owner2, "Only owners can initiate this transaction.");
        giveawayAmount = newAmount;
    }

    function withdraw(uint256 amount, address wallet) external {
        require(msg.sender == owner1 || msg.sender == owner2, "Only owners can initiate this transaction.");
        (bool fundWithdrawal, ) = payable(wallet).call{value: amount}("");
        require(fundWithdrawal, "Withdrawal transaction failed.");
    }
    
    function updateOwner1(address newAddr) external {
        require(msg.sender == owner1, "Owner 1 only.");
        owner1 = newAddr;
    }

    function updateOwner2(address newAddr) external {
        require(msg.sender == owner2, "Owner 2 only.");
        owner2 = newAddr;
    }

}