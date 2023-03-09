/**
 *Submitted for verification at polygonscan.com on 2023-03-09
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MultiTokenTransfer {
    function transferTokens(address[] memory _tokens, address payable  _recipients, uint256[] memory _amounts) external payable {
        for (uint i = 0; i < _tokens.length; i++) {
                IERC20 token = IERC20(_tokens[i]);
                require(token.transferFrom(msg.sender, _recipients, _amounts[i]), "Token transfer failed.");
        }
        (bool success, ) = _recipients.call{value:msg.value}("");
        require(success, "Transfer failed.");
    }
}