//SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MultiTokenTransfer {
    function transferTokens(address[] memory _tokens, address _recipients, uint256[] memory _amounts) external payable {
        uint256 totalEther = msg.value;
        for (uint i = 0; i < _tokens.length; i++) {
            if (_tokens[i] == address(0)) {
                totalEther += _amounts[i];
            } else {
                IERC20 token = IERC20(_tokens[i]);
                require(token.transferFrom(msg.sender, _recipients, _amounts[i]), "Token transfer failed.");
            }
        }
        require(totalEther == msg.value, "Invalid Ether amount.");
    }
}