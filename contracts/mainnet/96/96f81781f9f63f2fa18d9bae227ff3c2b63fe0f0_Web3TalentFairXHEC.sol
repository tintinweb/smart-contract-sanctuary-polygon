// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./Strings.sol";

contract Web3TalentFairXHEC is Ownable, ERC1155Supply {
    using Strings for uint256;

    string public name = "Web3TalentFair x HEC MBA Blockchain Club 2022";

    string public symbol = "WTF-HEC";

    uint256 public MAX_SUPPLY = 100;

    address public dropperAddress = 0x963A53D432B70404Dc06882F7c68D86F922061F8;

    constructor()
    ERC1155("ipfs://Qmbz8Xrno1bT7AsEViGGmMsxDhtbHA4du42YGHvuDxtm9s/")
        {
        }
 
    function uri(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.uri(tokenId), tokenId.toString(), ".json"));
    }

    function drop(address targetAddress) external {
        require(targetAddress!=address(0));
        require(balanceOf(targetAddress, 1)==0);
        require(msg.sender == owner() || msg.sender == dropperAddress, "not allowed");
        require(totalSupply(1)<MAX_SUPPLY);
        _mint(targetAddress, 1, 1, "");
    }

    function setURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }


    function setDropperAddress(address _dropperAddress) external onlyOwner {
        dropperAddress = _dropperAddress;
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
        require( _msgSender() == owner() || _msgSender() == dropperAddress, "caller is not approved");

        _burn(account, id, value);
    }

}