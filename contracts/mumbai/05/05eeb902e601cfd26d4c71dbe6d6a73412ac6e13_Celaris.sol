// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./Ownable.sol";
import "./ERC721Royalty.sol";
import "./ERC2981.sol";
import "./Address.sol";
import "./ReentrancyGuard.sol";
import "./UpdatableOperatorFilterer.sol";


contract Celaris is ERC721, ERC2981, Ownable, ReentrancyGuard, UpdatableOperatorFilterer {

    address public minter;

    uint256 public totalSupply = 0;

    uint256 public maxSupply = 50;

    string public baseURI;

    string public collectionURI;

    address public treasure;

    address constant MYDEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    
    address constant MYOPERATOR_FILTER_REGISTRY = address(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address _treasure)
    ERC721("721 cel","CEL")
    UpdatableOperatorFilterer(MYOPERATOR_FILTER_REGISTRY, MYDEFAULT_SUBSCRIPTION, true)
    {
      _setDefaultRoyalty(_treasure, 1000); // 10% fees
      treasure = _treasure;
    }


   function mint(address to,uint256 tokenId) external {
        require(msg.sender == minter || msg.sender == owner(), "not allowed");
        require(totalSupply +1 < maxSupply , "not allowed");        
        _safeMint(to,tokenId);
        totalSupply = totalSupply + 1;        
   }

   function mints(address to,uint256[] memory tokenId) external {
        require(msg.sender == minter || msg.sender == owner(), "not allowed");
        require(totalSupply + tokenId.length <= maxSupply , "not allowed");
        for(uint256 i = 0 ; i < tokenId.length; i++){
            _safeMint(to, tokenId[i]);
            totalSupply = totalSupply + 1;
        }
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _burn(tokenId);
    }
    
    //METADATA URI BUILDER

    function tokenURI(uint256 tokenId) public view override
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        // Concatenate the baseURI and the tokenId as the tokenId should
        // just be appended at the end to access the token metadata
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId), ".json"));
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setContractURI(string memory uri) external onlyOwner {
        collectionURI = uri;
    }

    
    function contractURI() public view returns (string memory) {
      return string(abi.encodePacked(_baseURI(), "contract.json"));
    }
  

    function setMinter(address  _minter) external onlyOwner {
        minter = _minter;
    }

    function setMaxSupply(uint256  _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

     function setOperatorFilter(address  defaultSubsription,address filterRegistry) external onlyOwner {
     //  UpdatableOperatorFilterer(filterRegistry, defaultSubsription, true);
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
    return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
  }

  function owner() public view virtual override(Ownable, UpdatableOperatorFilterer) returns (address) {
    return Ownable.owner();
  }

  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
      super.approve(operator, tokenId);
  }

  function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      override
      onlyAllowedOperator(from)
  {
      super.safeTransferFrom(from, to, tokenId, data);
  }
   

}