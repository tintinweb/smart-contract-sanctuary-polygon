// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.1;

import "ERC1155.sol";
import "SafeMath.sol";
import "Ownable.sol";
contract NFT is ERC1155, Ownable {
    using SafeMath for uint256;

    constructor() ERC1155("ipfs://QmcYzBbtvLxigmQNScdEuGCKediJ9LoR78opGHD5sYpThj/metadata/{id}.json") {
    }
    

    function mintphase1() public onlyOwner {
        for (uint256 i = 0; i <= 319; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint321to500() public onlyOwner {
        for (uint256 i = 320; i <= 499; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint501to800() public onlyOwner {
        for (uint256 i = 500; i <= 799; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint801to1000() public onlyOwner {
        for (uint256 i = 800; i <= 999; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint1001to1500() public onlyOwner {
        for (uint256 i = 1000; i <= 1499; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint1501to2000() public onlyOwner {
        for (uint256 i = 1500; i <= 1999; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint2001to2500() public onlyOwner {
        for (uint256 i = 2000; i <= 2499; i++) {
            mint(msg.sender, i, 1);
        }
    }

    function mint(address account, uint256 id, uint256 amount) public onlyOwner {
    _mint (account, id, amount, "");
}

function burn(address account, uint256 id, uint256 amount) public {
    require(msg.sender == account);
    _burn(account, id, amount);
}




}