// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PoolReceiver {
    address public multisig;
    uint256 public totalFeesReceived;
    uint256 public poolBalance;

    mapping(address => bool) public isBorrower;
    mapping(address => uint256) public allocation; // allocation ( maxAmount to borrow ) per borrower

    constructor() public {
        multisig = 0x839B878873998F02cE2f5c6D78d1B0842e58F192;
    }

    function withdraw(uint _amount) public payable {
        // require(msg.sender == multisig, "Only multisig can withdraw");
        require(address(this).balance >= _amount, "Insufficient balance");
        payable(multisig).transfer(_amount);
    }

    /**
     * @dev set allocation for a borrower
     */
    function setAllocation(address _employee, uint256 _maxAmount) public {
        // require(msg.sender == multisig, "Only multisig can set allocation");
        allocation[_employee] = _maxAmount;
        isBorrower[_employee] = true;
    }

    /**
     * @dev borrow money from the pool
     */
    function _borrow(address _employee, uint256 amount) public {
        //Get the pool Balance
        poolBalance = address(this).balance;
        require(poolBalance > 0, "Pool : No funds available");
        // require(
        //     amount < allocation[_employee],
        //     "Credit line, max amount exceeded"
        // );

        // Transfer prize to the borrower
        // allocation[_employee] -= amount;
        payable(_employee).transfer(amount);
        // require(success, "Pool : Failed on transferring to winner");
    }

    receive() external payable {}
}