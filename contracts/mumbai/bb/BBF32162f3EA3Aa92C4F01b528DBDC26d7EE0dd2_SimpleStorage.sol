// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 private totalBalance;

    mapping(address => uint256) private usersMovesRegister;

    constructor() {
        totalBalance = 0;
    }

    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }

    function getAmountFunded(address _user) public view returns (uint256) {
        require(_user != address(0));
        require(msg.sender != address(0));

        return usersMovesRegister[_user];
    }

    function addAmount(address _user, uint256 _amount) public {
        require(_user != address(0));
        require(_amount > 0);

        uint256 prevAmount = usersMovesRegister[_user];

        uint256 totalAmount = prevAmount + _amount;

        usersMovesRegister[_user] = totalAmount;
    }
}