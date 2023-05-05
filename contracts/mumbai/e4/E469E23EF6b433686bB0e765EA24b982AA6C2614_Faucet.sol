// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
    address public owner;
    mapping(address => uint256) public lastWithdrawal;
    uint256 public withdrawalLimit = 5 minutes;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    function withdraw(uint256 _amount) public {
        require(
            _amount <= 100000000000000000,
            "Amount exceeds the maximum limit"
        );

        uint256 lastWithdraw = lastWithdrawal[msg.sender];
        require(
            lastWithdraw == 0 ||
                block.timestamp - lastWithdraw >= withdrawalLimit,
            "Withdrawal not allowed yet"
        );

        lastWithdrawal[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(_amount);
    }

    function withdrawFixedAmount() public {
        uint256 fixedAmount = 100000000000000000;

        uint256 lastWithdraw = lastWithdrawal[msg.sender];
        require(
            lastWithdraw == 0 ||
                block.timestamp - lastWithdraw >= withdrawalLimit,
            "Withdrawal not allowed yet"
        );

        lastWithdrawal[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(fixedAmount);
    }

    function fundFaucet() public payable {
        // Funds the faucet with the amount sent by the user.
    }

    function ownerWithdraw() public onlyOwner {
        // Transfer the full contract balance to the owner
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable {}
}