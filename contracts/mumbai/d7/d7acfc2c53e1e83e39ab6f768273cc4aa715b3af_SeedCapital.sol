// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib.sol";

contract SeedCapital is ERC20, Ownable {
    mapping(address => uint256) private _lockup;

    event Locked(address indexed addr, uint256 value);

    constructor() ERC20("SeedCapital", "SCFT") {
        // Token supply is 1.1 billion
        uint256 initialSupply = 1100000000 * 10**decimals();
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 4; // why 4?
    }

    // set address lockup time in weeks
    function setLockup(uint256 _weeks, address addr) external virtual onlyPolicy() {
        uint256 lockup = block.timestamp + _weeks * 1 weeks;
        _lockup[addr] = lockup;
        emit Locked(addr, lockup);
    }

    function isLocked(address addr) public virtual returns(bool) {
        return _lockup[addr] > block.timestamp;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        // Sender can't be in a lockup period
        require(!isLocked(from));
    }
}