// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./BRC721Enumerable.sol";
import "./Pausable.sol";
import "./Strings.sol";

contract EXIST721 is BRC721Enumerable, Pausable {
    using Strings for uint256;

    string private baseURI;

    constructor(
        address admin_,
        string memory baseURI_,
        string memory name_,
        string memory symbol_
    ) BRC721(admin_, name_, symbol_) {
        baseURI = string(abi.encodePacked(baseURI_, symbol_, "/"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function mint(address to, uint tokenId) external {
        _mint(to, tokenId);
    }

    /**
     * override tokenURI(uint256), remove restrict for tokenId exist.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function setPause() external onlyAdmin {
        _pause();
    }

    function unsetPause() external onlyAdmin {
        _unpause();
    }

    function changeBaseURI(string memory newBaseURI) external onlyAdmin {
        string memory symbol_ = symbol();
        baseURI = string(abi.encodePacked(newBaseURI, symbol_, "/"));
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "BRC721Pausable: token transfer while paused");
    }
}