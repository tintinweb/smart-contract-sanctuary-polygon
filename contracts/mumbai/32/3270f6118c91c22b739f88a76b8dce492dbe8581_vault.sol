/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

interface IERC20Token {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract vault {
    struct VaultInfo {
        address owner;
        uint256 lockedAmount;
        uint256 lockTime;
    }

    IERC20Token private vaultToken;
    address public owner;
    uint256 public lockPeriod = 2592000; //in seconds
    uint256 public totalValueLocked;

    mapping(address => VaultInfo) public lockOf;

    event Deposit(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );
    event Withdraw(
        address indexed user,
        uint256 amount,
        uint256 timestamp,
        uint256 totalValueLocked
    );

    constructor(address vt) {
        vaultToken = IERC20Token(vt);
        owner = msg.sender;
    }

    function lock(uint256 _amount) public {
        require(
            lockOf[msg.sender].lockedAmount == 0,
            "You have already staked"
        );
        require(_amount >= 1e18, "You cannot stake nothing");
        lockOf[msg.sender] = VaultInfo(
            msg.sender,
            _amount,
            block.timestamp
        );
        vaultToken.transferFrom(msg.sender, address(this), _amount);
        totalValueLocked = totalValueLocked + _amount;
        emit Deposit(msg.sender, _amount, block.timestamp, totalValueLocked);
    }
    
    function withdraw() public {
        require(
            lockOf[msg.sender].lockedAmount > 0,
            "You are not staking anything"
        );
        require(
            block.timestamp >= lockOf[msg.sender].lockTime + lockPeriod,
            "Assets are still locked"
        );
        vaultToken.transfer(msg.sender, lockOf[msg.sender].lockedAmount);
        totalValueLocked = totalValueLocked - lockOf[msg.sender].lockedAmount;
        emit Withdraw(
            msg.sender,
            lockOf[msg.sender].lockedAmount,
            block.timestamp,
            totalValueLocked
        );
        lockOf[msg.sender].lockedAmount = 0;
    }
}