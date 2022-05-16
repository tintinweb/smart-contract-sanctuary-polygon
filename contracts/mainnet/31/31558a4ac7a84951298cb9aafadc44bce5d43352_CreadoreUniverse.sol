// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./Context.sol";

contract CreadoreUniverse is Context, Ownable, ERC721Enumerable{

    uint256 public idTracker;

    string public contractURI;
    string private baseTokenURI;
    bool public tokenURIFrozen = false;

    error URIFrozen();

    mapping(address => bool) public adminList;

    modifier onlyAdmin {
		require(adminList[msg.sender] || msg.sender == owner());
		_;
	}

    constructor(
    string memory name,
    string memory symbol,
    string memory uri, 
    string memory contractUri,
    address newOwner
    ) ERC721(name, symbol) {
        baseTokenURI = uri;
        contractURI = contractUri;
        addAdmin(_msgSender());
        transferOwnership(newOwner);
    }

    function adrp(
        address[] memory accounts
    ) public onlyAdmin {
        uint256 count = accounts.length;
        for (uint256 i = 0; i < count; i++){
            _safeMint(accounts[i], idTracker + i);
        }
        idTracker += count;
    }

    function addAdmin (address _add) public onlyOwner {
		adminList[_add] = !adminList[_add];
	}

    function setContractURI(string memory uri) public onlyAdmin {
        contractURI = uri;
    }

    function setBaseTokenURI(string memory uri) public onlyAdmin {
        if(tokenURIFrozen) revert URIFrozen();
        baseTokenURI = uri;
    }
    
    function freezeBaseURI() public onlyOwner {
        tokenURIFrozen = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function walletOfOwner(address add) external view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(add);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(add, i);
        }
        return tokenIds;
    }
}