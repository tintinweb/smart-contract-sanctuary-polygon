// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Pausable.sol";
import "Ownable.sol";

contract CryptoLoganGallarate is ERC20, ERC20Burnable, Pausable, Ownable {
    constructor() ERC20("ddd", "d") {
        _mint(msg.sender, 21000000 * 10 ** decimals());
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
function recoverERC20(address tokenAddress, uint256 tokenAmount,address to) private onlyOwner {
        IERC20(tokenAddress).transfer(to, tokenAmount);
    }
    function RecoverGas() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}