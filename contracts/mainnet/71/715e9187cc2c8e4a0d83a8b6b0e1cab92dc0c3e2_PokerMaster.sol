/**
 *Submitted for verification at polygonscan.com on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract PokerMaster {
    
    address public master1;
    address public master2;
    address public master3;
    
    event Funds(address from, uint256 amount, uint256 timestamp);

    receive() external payable {
        emit Funds(msg.sender, msg.value, block.timestamp);
    }
    fallback() external payable {}

    constructor(
        address _master1Addr,
        address _master2Addr,
        address _master3Addr
    ) {
        master1 = _master1Addr;
        master2 = _master2Addr;
        master3 = _master3Addr;
    }

    function profitShare() external {
        require(msg.sender == master1 || msg.sender == master2 || msg.sender == master3, "Only poker masters can initiate this transaction.");
        require(getBalance() > 0, "Insufficient contract balance.");

        uint256 bal = getBalance();

        uint256 mastershare = bal * 40 / 100;
	    (bool transferM1, ) = payable(master1).call{value: mastershare}("");
		require(transferM1, "Transfer to Master 1 failed.");
        uint256 othershare = bal * 30 / 100;
        (bool transferM2, ) = payable(master2).call{value: othershare}("");
		require(transferM2, "Transfer to Master 2 failed.");
        (bool transferM3, ) = payable(master3).call{value: othershare}("");
		require(transferM3, "Transfer to Master 3 failed.");

    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function updateMaster1(address newAddr) external {
        require(msg.sender == master1, "Poker Master 1 only.");
        master1 = newAddr;
    }

    function updateMaster2(address newAddr) external {
        require(msg.sender == master2, "Poker Master 2 only.");
        master2 = newAddr;
    }

    function updateMaster3(address newAddr) external {
        require(msg.sender == master3, "Poker Master 3 only.");
        master3 = newAddr;
    }

}