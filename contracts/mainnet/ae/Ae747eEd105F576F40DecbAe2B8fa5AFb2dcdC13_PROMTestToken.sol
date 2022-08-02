// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC20.sol";

contract PROMTestToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 supply
    ) ERC20(name, symbol) {
        _mint(msg.sender, supply * 10**18);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}