// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20BasicApproveExtension.sol";
import "./ERC20BaseToken.sol";

contract DollarDogBaseToken is ERC20BaseToken, ERC20BasicApproveExtension {
    constructor(
        address ddAdmin,
        address executionAdmin,
        address beneficiary,
        uint256 amount
    ) ERC20BaseToken("Dollar Dog Token", "DDT", ddAdmin, executionAdmin) {
        _admin = ddAdmin;
        if (beneficiary != address(0)) {
            uint256 initialSupply = amount * (1 ether);
            _mint(beneficiary, initialSupply);
        }
    }
}