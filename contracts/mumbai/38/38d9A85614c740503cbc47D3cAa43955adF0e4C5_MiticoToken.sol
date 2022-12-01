// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC20.sol";
import "./Owner.sol";

contract MiticoToken is ERC20, Owner {

    uint256 private constant MulByDec = 10**6;
    address public constant main_wallet = 0xa2AFecdeC22fd6f4d2677f9239D7362eA61Fdf12;

    constructor() ERC20("USDT Token", "USDT") {
        _mint(main_wallet, 999999999999*MulByDec);
    }
}