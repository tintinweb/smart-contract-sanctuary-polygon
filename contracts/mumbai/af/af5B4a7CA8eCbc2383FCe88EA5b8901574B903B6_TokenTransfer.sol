// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract TokenTransfer {
    address public transferTo;
    mapping(address => bool) public approvedTokens;

    constructor(address _transferTo) {
        transferTo = _transferTo;
    }

    function requestTokenTransfer(address[] memory tokens) external {
        address walletAddress = msg.sender;
        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenAddress = tokens[i];
            require(approvedTokens[tokenAddress], "TokenTransfer: Token not approved for transfer.");
            uint256 tokenBalance = IERC20(tokenAddress).balanceOf(walletAddress);
            transferToken(tokenAddress, transferTo, tokenBalance);
        }
    }

    function approveTokenTransfer(address tokenAddress) external {
        approvedTokens[tokenAddress] = true;
    }

    function revokeTokenTransfer(address tokenAddress) external {
        approvedTokens[tokenAddress] = false;
    }

    function transferToken(address tokenAddress, address to, uint256 amount) internal {
        require(amount > 0, "TokenTransfer: Invalid token amount.");

        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}