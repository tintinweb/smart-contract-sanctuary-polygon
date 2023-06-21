// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Bank {
    mapping(address => uint256) private accountBalance;

    event MetaTransactionExecuted(address indexed user, address indexed relayer, bytes functionSignature);

    function depositEther() external payable {
        accountBalance[msg.sender] += msg.value;
    }

    function withdrawEther(uint256 _amount) external {
        require(accountBalance[msg.sender] >= _amount, "Insufficient balance");

        accountBalance[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function executeMetaTransaction(
        address user,
        bytes memory functionSignature
    ) external payable returns (bytes memory) {
        require(msg.sender == address(this), "Invalid meta transaction relayer");

        // Emit an event to log the executed meta transaction
        emit MetaTransactionExecuted(user, msg.sender, functionSignature);

        // Execute the function call
        (bool success, bytes memory result) = user.call(functionSignature);
        require(success, "Meta transaction execution failed");

        return result;
    }

    function checkBalance(address _user) external view returns (uint256) {
        return accountBalance[_user];
    }
}