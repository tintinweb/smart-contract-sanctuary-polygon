pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Airdrop {
    function drop(address tokenAddress, address[] memory recipients, uint256 amount) external {
        for (uint256 i = 0; i < recipients.length; i++) {
            require(IERC20(tokenAddress).transfer(recipients[i], amount), "Transfer failed");
        }
    }
}