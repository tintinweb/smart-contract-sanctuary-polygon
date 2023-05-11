// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract TokenDistributor {
    function distribute(
        address tokenAddress,
        uint256 amount,
        address[] memory recipients
    ) external {
        require(amount > 0, "Amount must be greater than zero");
        require(recipients.length > 0, "No recipients provided");
        ERC20 token = ERC20(tokenAddress);
        uint256 totalAmount = amount * recipients.length;
        require(
            token.balanceOf(msg.sender) >= totalAmount,
            "Insufficient balance"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            require(
                token.transfer(recipients[i], amount),
                "Token transfer failed"
            );
        }
    }
}