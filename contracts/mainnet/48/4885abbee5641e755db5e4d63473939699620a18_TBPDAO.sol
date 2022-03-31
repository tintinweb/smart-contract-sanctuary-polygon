// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Snapshot.sol";
import "Ownable.sol";

contract TBPDAO is ERC20, ERC20Snapshot, Ownable {
    constructor() ERC20("TBP DAO", "TBP") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}