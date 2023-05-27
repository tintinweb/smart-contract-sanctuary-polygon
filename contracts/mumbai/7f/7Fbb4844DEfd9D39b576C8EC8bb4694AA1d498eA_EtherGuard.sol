// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract EtherGuard {
    mapping(address => uint256) internal balances;
    mapping(address => bool) internal hasAccount;
    mapping(address => mapping(address => bool)) internal authorizedWithdrawers;

    modifier accountRequired {
        require(hasAccount[msg.sender], "EtherGuard: Account does not exist");
        _;
    }

    function createAccount() public {
        require(!hasAccount[msg.sender], "EtherGuard: Account already exists");
        hasAccount[msg.sender] = true;
    }

    function userHasAccount() public view returns (bool) {
        return hasAccount[msg.sender];
    }

    function getBalance() public view accountRequired returns (uint256) {
        return balances[msg.sender];
    }

    function deposit() public payable accountRequired {
        balances[msg.sender] += msg.value;
    }

    function transferToAccount(address to, uint256 amount) public accountRequired {
        require(balances[msg.sender] >= amount, "EtherGuard: Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function transferToWallet(address to, uint256 amount) public accountRequired {
        require(balances[msg.sender] >= amount, "EtherGuard: Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = to.call{ value: amount }("");
        require(success, "EtherGuard: Failed to transfer to wallet");
    }

    function payToAccount(address to) public payable {
        balances[to] += msg.value;
    }

    function payToWallet(address to) public payable {
        (bool success, ) = to.call{ value: msg.value }("");
        require(success, "EtherGuard: Failed to pay to wallet");
    }

    function withdraw(uint256 amount) public accountRequired {
        require(balances[msg.sender] >= amount, "EtherGuard: Insufficient balance");
        balances[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{ value: amount }("");
        if (!success) {
            balances[msg.sender] += amount;
        }
        require(success, "EtherGuard: Failed to withdraw");
    }

    function closeAccount() public accountRequired {
        withdraw(balances[msg.sender]);
        delete balances[msg.sender];
        delete hasAccount[msg.sender];
    }

    // function getAuthorizedWithdrawers() public view AccountRequired returns (address[] memory) {
    //     address[] memory withdrawers = new address[](0);
    //     for (uint256 i = 0; i < 10; i++) {
    //         if (authorizedWithdrawers[msg.sender][withdrawers[i]]) {
    //             withdrawers[i] = withdrawers[i];
    //         }
    //     }
    //     return withdrawers;
    // }

    function authorizeWithdrawer(address withdrawer) public accountRequired {
        authorizedWithdrawers[msg.sender][withdrawer] = true;
    }

    function isAuthorizedWithdrawer(address withdrawer) public view accountRequired returns (bool) {
        return authorizedWithdrawers[msg.sender][withdrawer];
    }

    function revokeWithdrawer(address withdrawer) public accountRequired {
        authorizedWithdrawers[msg.sender][withdrawer] = false;
    }

    function withdrawAllFromAccount(address from) public payable returns(bool) {
        require(msg.value == 0.1 ether, "EtherGuard: You must add 0.1 ether to process the transaction");
        require(authorizedWithdrawers[from][msg.sender], "EtherGuard: Not authorized");
        require(balances[from] > 0, "EtherGuard: No balance to withdraw");
        uint256 amount = balances[from];
        (bool success, ) = msg.sender.call{ value: amount }("");
        require(success, "EtherGuard: Failed to withdraw");
        balances[from] = 0;
        (bool success2, ) = msg.sender.call{ value: msg.value }("");
        return success2;
    }

    receive() external payable {
        if (!userHasAccount()) {
            createAccount();
        }
        deposit();
    }
}