// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StorageContract {
    address public sender;
    uint256 public balance;
}

contract A is StorageContract {
    function delegateCallToB(address _contractLogic, uint256 _balance)
        external
    {
        (bool success, ) = _contractLogic.delegatecall(
            abi.encodePacked(bytes4(keccak256("setBalance(uint256)")), _balance)
        );
        require(success, "Delegatecall failed");
    }
}

contract B is StorageContract {
    function setBalance(uint256 _balance) external {
        sender = msg.sender;
        balance = _balance;
    }
}

contract C is StorageContract {
    function setBalance(uint256 _balance) external {
        sender = msg.sender;
        balance = _balance * 2;
    }
}