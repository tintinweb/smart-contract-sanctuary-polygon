// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AirdropETH {
    function drop(address payable[] memory recipients, uint256 amount)
        external
    {
        require(
            address(this).balance >= amount * recipients.length,
            "Insufficient balance"
        );

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i].send(amount), "Transfer failed");
        }
    }

    receive() external payable {}

    fallback() external payable {}
}