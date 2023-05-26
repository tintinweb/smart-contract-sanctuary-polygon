/**
 *Submitted for verification at polygonscan.com on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CXXXSystem {
    
    address public owner1;
    address public owner2;
    
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

    function profitShare() external {
        require(msg.sender == owner1 || msg.sender == owner2, "Only owners can initiate this transaction.");
        require(getBalance() > 0, "Insufficient contract balance.");

        uint256 bal = getBalance();

        uint256 owner1Profit = bal * 75 / 100;
	    (bool transferM1, ) = payable(owner1).call{value: owner1Profit}("");
		require(transferM1, "Transfer to Owner 1 failed.");

        uint256 owner2Profit = bal * 25 / 100;
        (bool transferM2, ) = payable(owner2).call{value: owner2Profit}("");
		require(transferM2, "Transfer to Owner 2 failed.");
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
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