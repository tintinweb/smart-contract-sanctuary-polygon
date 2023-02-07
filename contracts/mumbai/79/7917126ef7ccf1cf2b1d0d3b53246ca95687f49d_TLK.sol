// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";

contract TLK is ERC20, Ownable {
    address private constant _to = 0x538935d9bd028bF29D4c3B6BDd5AA02D885D59e2;
    uint256 private _amount = 100000000 * (10 ** uint256(decimals()));

    constructor() ERC20("The Lion King", "TLK") {
        _mint(_to, _amount);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}