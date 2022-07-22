// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract Web3TalentFairXWagmi is Ownable, ERC1155Supply {
    using Strings for uint256;

    string public name = "Web3TalentFair x Wagmi 2022";

    string public symbol = "WEB3T-WAGMI";

    uint256 public MAX_SUPPLY = 100;

    address public dropperAddress;

    constructor()
    ERC1155("ipfs://QmNUixuS1AaLjGdZ8XRQLh4J1qZd5FnjmJhvBynxkxC7cG/")
        {
        }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    function drop(address targetAddress) external {
        require(targetAddress!=address(0));
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        require(totalSupply(1)<MAX_SUPPLY);
        _mint(targetAddress, 1, 1, "");
    }


    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        require(from == address(0)||to == address(0));
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(account == _msgSender(),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

}