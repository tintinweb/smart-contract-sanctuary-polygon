// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract POETTREE is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("POETTREE ", "POETTREE ") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function airdrop(address[] calldata _list, uint256[] calldata _amount) public onlyOwner {
        require(_list.length == _amount.length);
        for(uint256 i = 0; i < _list.length; i++){

        transfer(_list[i], _amount[i]);

        }

    }

}