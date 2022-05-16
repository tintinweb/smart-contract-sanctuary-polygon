// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./ERC1155Burnable.sol";
import "./Context.sol";
import "./Ownable.sol";

contract CreadoreUniverse is Context, Ownable, ERC1155Burnable{

    string private _name;
    string private _symbol;

    string public contractURI;
    bool public tokenURIFrozen = false;

    mapping(address => bool) public adminList;

    modifier onlyAdmin {
		require(adminList[msg.sender] || msg.sender == owner());
		_;
	}

    constructor(
    string memory name_,
    string memory symbol_,
    string memory uri, 
    string memory contractUri,
    address newOwner
    ) ERC1155(uri) {
        _name = name_;
        _symbol = symbol_;
        contractURI = contractUri;
        addAdmin(_msgSender());
        transferOwnership(newOwner);
    }

    function airdrop(
        address[] memory accounts,
        uint256 id,
        bytes memory data
    ) public onlyAdmin {
        uint256 count = accounts.length;
        for (uint256 i = 0; i < count; i++){
            _mint(accounts[i], id, 1, data);
        }
    }

    function setContractURI(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyAdmin {
        require(tokenURIFrozen == false, "Token URIs are frozen");
        _setURI(uri);
    }

    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function addAdmin (address _add) public onlyOwner {
		adminList[_add] = !adminList[_add];
	}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}