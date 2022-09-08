/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

contract BatchAirdroper {
    constructor() {}

    function transferBatch(
        address[] calldata receivers,
        uint256[] calldata amounts,
        address contractAddress
    ) external {
        IERC20 erc20Contract = IERC20(contractAddress);

        for (uint256 index = 0; index < receivers.length; index++) {
            erc20Contract.transferFrom(
                msg.sender,
                receivers[index],
                amounts[index]
            );
        }
    }
}