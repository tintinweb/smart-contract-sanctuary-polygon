// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from './erc20.sol';

contract TestERC20 is ERC20('BetaWLD', 'BWLD', 9) {
    address constant OWNER = 0x80dc00811e7C4A03c1f1599D3dc8fEbaAd87Bf87;

    function issue(address receiver, uint256 amount) public {
        require(msg.sender == OWNER, "needs to be called by owner");
        _mint(receiver, amount);
    }
}