// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Context.sol";
import "./Ownable.sol";

contract MAFACES is Context, Ownable, ERC1155Burnable {
    string private _contractURI;

    string private _name;
    string private _symbol;

    bool public tokenURIFrozen = false;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory uri
    ) ERC1155(uri) {
        _name = name_;
        _symbol = symbol_;
    }

    function ownerMint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyOwner {
        _mint(to, id, amount, data);
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory uri) public onlyOwner {
        _contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyOwner {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _setURI(uri);
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
}