// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC1155Burnable.sol";

contract FactoryNFT is ERC1155, Ownable, Pausable, ERC1155Burnable {
    uint256[] nftIds;
    mapping(uint256 => uint256) totalMintedCount;

    constructor() ERC1155("") {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(account, id, amount, data);
        if (findNFTId(id) == true) {
            totalMintedCount[id] += amount;
        } else {
            nftIds.push(id);
            totalMintedCount[id] += amount;
        }
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function findNFTId(uint256 _id) internal view returns (bool) {
        for (uint256 index = 0; index < nftIds.length; index++) {
            if (nftIds[index] == _id) {
                return true;
            }
        }
        return false;
    }

    function getTotalMintedCount(uint256 _id) public view returns (uint256) {
        return totalMintedCount[_id];
    }

    function getNFTIds() public view returns (uint256[] memory) {
        return nftIds;
    }
}