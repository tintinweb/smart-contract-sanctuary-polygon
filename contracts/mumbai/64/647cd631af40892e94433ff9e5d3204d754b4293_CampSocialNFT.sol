// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableWithAdmin.sol";
import "./ERC721Enumerable.sol";

contract CampSocialNFT is ERC721Enumerable, OwnableWithAdmin {
    uint256 public              MAX_SUPPLY              = 10000;
    string  public              baseURI;

    struct Token {
        uint256 id;
        string  CampName;
        uint256 spirit;
    }
    mapping(uint256 => Token) public Tokens;

    constructor()  
        ERC721("CampSocial NFT", "CAMPSOCIAL")
        {}    

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function mint(uint256 _count, address _to) public onlyOwnerOrAdmin {
        require(totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply.");
        for(uint i; i < _count; i++) { 
            _mint(_to, totalSupply() + i);
            Tokens[totalSupply()+i] = Token(
                {
                id: totalSupply()+i,
                CampName: "",
                spirit: 0
                }
            );
        }
    }

    function addSpirit(uint256 _tokenId, uint256 _spirit) public onlyOwnerOrAdmin {
        require(_exists(_tokenId), "Token does not exist.");
        Tokens[_tokenId].spirit += _spirit;
    }

    function subtractSpirit(uint256 _tokenId, uint256 _spirit) public onlyOwnerOrAdmin {
        require(_exists(_tokenId), "Token does not exist.");
        require(Tokens[_tokenId].spirit >= _spirit, "Subtracting this amount of spirit would result in negative value.");
        Tokens[_tokenId].spirit -= _spirit;
    }
        
    function updateCampName(uint256 _tokenId, string memory _campName) public onlyOwnerOrAdmin {
        require(_exists(_tokenId), "Token does not exist.");
        Tokens[_tokenId].CampName = _campName;
    }

    function burn(uint256 tokenId) public onlyOwnerOrAdmin { 
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyOwnerOrAdmin {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override onlyOwnerOrAdmin {
        _safeTransfer(from, to, tokenId, "");
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}