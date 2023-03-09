// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
}

contract TokenLock {
    mapping(address => mapping(address => uint256)) private balances;
    mapping(address => mapping(address => uint256)) private unlockTimes;
    mapping(address => mapping(address => bool)) private approved;

    function deposit(
        address token,
        uint256 amount,
        uint256 unlockTime
    ) external {
        require(amount > 0, "Amount must be greater than 0");
        require(
            unlockTime > block.timestamp,
            "Unlock time must be in the future"
        );

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[msg.sender][token] += amount;
        unlockTimes[msg.sender][token] = unlockTime;
        approved[msg.sender][token] = true;

        emit Deposit(msg.sender, token, amount, unlockTime);
    }

    function withdraw(address token) external {
        require(
            block.timestamp >= unlockTimes[msg.sender][token],
            "Tokens are still locked"
        );
        require(balances[msg.sender][token] > 0, "No tokens to withdraw");
        require(
            approved[msg.sender][token],
            "User is not authorized to withdraw"
        );

        uint256 amount = balances[msg.sender][token];
        balances[msg.sender][token] = 0;

        address tokenAddress = address(token);
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
        require(success, "Token transfer failed");

        emit Withdraw(msg.sender, token, amount);
    }

    function getBalance(address token, address account)
        external
        view
        returns (uint256)
    {
        return balances[account][token];
    }

    function authorizeWithdrawal(address token, address user) external {
        require(
            msg.sender == user || msg.sender == owner(),
            "Only owner or user can authorize withdrawal"
        );
        require(balances[user][token] > 0, "No tokens to withdraw");

        approved[user][token] = true;

        emit AuthorizeWithdrawal(user, token);
    }

    function revokeAuthorization(address token, address user) external {
        require(
            msg.sender == user || msg.sender == owner(),
            "Only owner or user can revoke authorization"
        );
        require(balances[user][token] > 0, "No tokens to withdraw");

        approved[user][token] = false;

        emit RevokeAuthorization(user, token);
    }

    function owner() public view returns (address) {
        return address(uint160(bytes20(msg.sender)));
    }

    event Deposit(
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 unlockTime
    );
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event AuthorizeWithdrawal(address indexed user, address indexed token);
    event RevokeAuthorization(address indexed user, address indexed token);
}