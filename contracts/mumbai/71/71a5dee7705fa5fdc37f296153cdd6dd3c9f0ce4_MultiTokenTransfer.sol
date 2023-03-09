/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface ERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract MultiTokenTransfer {
    function transferTokens(address[] memory _tokens, address payable  _recipients, uint256[] memory _amounts) external payable {
        for (uint i = 0; i < _tokens.length; i++) {
            ERC20 token = ERC20(_tokens[i]);
            require(token.allowance(msg.sender, address(this)) >= _amounts[i], "Insufficient allowance");
            require(token.transferFrom(msg.sender, _recipients, _amounts[i]), "Token transfer failed.");
        }
        (bool success, ) = _recipients.call{value:msg.value}("");
        require(success, "Transfer failed.");
    }
}