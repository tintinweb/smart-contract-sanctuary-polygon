// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLock {
    struct Lock {
        uint256 releaseTime;
        address payable recipient;
        uint256 amount;
        bool released;
    }

    mapping(uint256 => Lock) public locks;
    uint256 public lockCount;

    event LockCreated(uint256 indexed lockId, address indexed recipient, uint256 amount, uint256 releaseTime);
    event LockReleased(uint256 indexed lockId, address indexed recipient, uint256 amount);

    function createLock(address payable _recipient, uint256 _amount, uint256 _releaseTimeOffset) public payable returns (uint256 lockId) {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Amount must be greater than zero");
        require(_releaseTimeOffset > 0, "Time must be at least 1 second.");

        lockId = ++lockCount;

        // Calculate the total amount including gas fees
        uint256 totalAmount = _amount + msg.value;

        locks[lockId] = Lock(block.timestamp + _releaseTimeOffset, _recipient, totalAmount, false);

        emit LockCreated(lockId, _recipient, totalAmount, block.timestamp + _releaseTimeOffset);
    }

    function release(uint256 lockId) public {
        Lock storage _lock = locks[lockId];
        require(!_lock.released, "Lock already released");
        require(block.timestamp >= _lock.releaseTime, "Release time has not arrived yet");
        require(address(this).balance >= _lock.amount, "Insufficient balance");

        // Transfer the entire lock amount, including gas fees
        _lock.recipient.transfer(_lock.amount);

        _lock.released = true;

        emit LockReleased(lockId, _lock.recipient, _lock.amount);
    }
}