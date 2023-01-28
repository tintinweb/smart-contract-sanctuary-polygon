/**
 *Submitted for verification at polygonscan.com on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CyberMaster {
    
    address public master1;
    address public master2;
    address public dev;

    uint256 public transactionCounter = 1;
    mapping(uint256 => uint256) public transactionAmount;
    mapping(uint256 => address) public transactionReceiver;
    mapping(uint256 => bool[2]) public transactionApproval;
    mapping(uint256 => bool) public transactionStatus;

    bool[2] public profitShareApproval = [false, false];
    
    event Funds(address from, uint256 amount, uint256 timestamp);
    event CreateTransaction(uint256 transactionID, uint256 amount, address to, address initiate, uint256 timestamp);
    event TransactionComplete(uint256 transactionID, bool status, uint256 amount, address to, uint256 timestamp);
    event ProfitShare(uint256 balance, uint256 masterProfit, uint256 devProfit, uint256 timestamp);

    receive() external payable {
        emit Funds(msg.sender, msg.value, block.timestamp);
    }
    fallback() external payable {}

    constructor(
        address _master1Addr,
        address _master2Addr,
        address _devAddr
    ) {
        master1 = _master1Addr;
        master2 = _master2Addr;
        dev = _devAddr;
    }

    function createTransaction(uint256 amount, address to) external {
        require(msg.sender == master1 || msg.sender == master2, "Only cyber masters can initiate this transaction.");
        require(getBalance() >= amount, "Insufficient contract balance.");
        transactionAmount[transactionCounter] = amount;
        transactionReceiver[transactionCounter] = to;
        if (msg.sender == master1) {
            transactionApproval[transactionCounter] = [true, false];
        } else if (msg.sender == master2) {
            transactionApproval[transactionCounter] = [false, true];
        }
        emit CreateTransaction(transactionCounter, amount, to, msg.sender, block.timestamp);
        transactionCounter++;
    }

    function approveTransactionID(uint256 id, bool state) external {
        require(msg.sender == master1 || msg.sender == master2, "Only cyber masters can initiate this transaction.");
        require(id <= transactionCounter, "Invalid transaction ID.");
        require(transactionStatus[id] == false, "This transaction already completed.");
        if (msg.sender == master1) {
            transactionApproval[id][0] = state;
        } else if (msg.sender == master2) {
            transactionApproval[id][1] = state;
        }
        if (transactionApproval[id][0] == true && transactionApproval[id][1] == true) {
            (bool transfer, ) = payable(transactionReceiver[id]).call{value: transactionAmount[id]}("");
		    require(transfer, "Transfer failed.");
            transactionStatus[id] = true;
            emit TransactionComplete(id, transactionStatus[id], transactionAmount[id], transactionReceiver[id], block.timestamp);
        }
    }

    function profitShare() external {
        require(msg.sender == master1 || msg.sender == master2, "Only cyber masters can initiate this transaction.");
        require(getBalance() > 0, "Insufficient contract balance.");
        require(profitShareApproval[0] == true, "Master 1 not approved.");
        require(profitShareApproval[1] == true, "Master 2 not approved.");

        uint256 bal = getBalance();

        uint256 masterProfit = bal * 9 / 20;
	    (bool transferM1, ) = payable(master1).call{value: masterProfit}("");
		require(transferM1, "Transfer to Master 1 failed.");
        (bool transferM2, ) = payable(master2).call{value: masterProfit}("");
		require(transferM2, "Transfer to Master 2 failed.");

        uint256 devProfit = bal * 2 / 20;
        (bool transferDev, ) = payable(dev).call{value: devProfit}("");
		require(transferDev, "Transfer to Dev failed.");

        profitShareApproval[0] = false;
        profitShareApproval[1] = false;

        emit ProfitShare(bal, masterProfit, devProfit, block.timestamp);
    }

    function setProfitShareApproval(bool state) external {
        require(msg.sender == master1 || msg.sender == master2, "Only cyber masters can initiate this transaction.");
        if (msg.sender == master1) {
            profitShareApproval[0] = state;
        } else if (msg.sender == master2) {
            profitShareApproval[1] = state;
        }
    }

    function getTransactionCount() public view returns(uint256) {
        return transactionCounter;
    }

    function getTransactionDetails(uint256 id) public view returns(address, uint256, bool, bool, bool) {
        return (transactionReceiver[id], transactionAmount[id], transactionApproval[id][0], transactionApproval[id][1], transactionStatus[id]);
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function updateMaster1(address newAddr) external {
        require(msg.sender == master1, "Cyber Master 1 only.");
        master1 = newAddr;
    }

    function updateMaster2(address newAddr) external {
        require(msg.sender == master2, "Cyber Master 2 only.");
        master2 = newAddr;
    }

    function updateDev(address newAddr) external {
        require(msg.sender == dev, "Dev only.");
        dev = newAddr;
    }

}