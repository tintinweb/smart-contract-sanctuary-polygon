// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./OwnableWithAdmin.sol";
import "./ERC721Enumerable.sol";

contract CampSocialNFT is ERC721Enumerable, OwnableWithAdmin {
    uint256 public              MAX_SUPPLY              = 10000;
    string  public              baseURI;

    struct Camp {
        uint256 id;
        string  name;
        string  description;
    }

    struct Token {
        uint256 id;
        uint256 campId;
        uint256 spirit;
    }

    uint256[] public _campListByTokenIndex;
    uint256 public _campCount = 0;
    mapping(uint256 => Camp) public Camps;
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

    function addCamp(string memory _name, string memory _description) public onlyOwner {
        Camps[_campCount] = Camp(_campCount, _name, _description);
        _campCount++;
    }

    function editCamp(uint256 _campId, string memory _name, string memory _description) public onlyOwner {
        require(_exists(_campId), "Camp does not exist.");
        Camps[_campId].name = _name;
        Camps[_campId].description = _description;
    }

    function mint(uint256 _count, address _to, uint256 _campId) public onlyOwnerOrAdmin {
        require(totalSupply() + _count <= MAX_SUPPLY, "Exceeds max supply.");
        require(_campId <= _campCount, "Camp does not exist.");
        for(uint i; i < _count; i++) { 
            uint256 _thisTokenId = totalSupply();
            _mint(_to, _thisTokenId);
            Tokens[_thisTokenId] = Token(
                {
                id: _thisTokenId,
                campId: _campId,
                spirit: 0
                }
            );
            _campListByTokenIndex.push(_campId);
        }
    }

    function addSpirit(uint256[] calldata _tokenId, uint256[] calldata _spirit) public onlyOwnerOrAdmin {
        for (uint i; i < _tokenId.length; i++) {
            require(_exists(_tokenId[i]), "Token does not exist.");
            Tokens[_tokenId[i]].spirit += _spirit[i];
        }
    }

    function subSpirit(uint256[] calldata _tokenId, uint256[] calldata _spirit) public onlyOwnerOrAdmin {
        for (uint i; i < _tokenId.length; i++) {
            require(_exists(_tokenId[i]), "Token does not exist.");
            Tokens[_tokenId[i]].spirit -= _spirit[i];
        }
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

    // for a campId, returns mapping
    // of tokenIds belonging to _campId
    function tokensOfCamp(uint256 _campId) public view returns (uint256[] memory) {
        uint256 tokenCount = tokensOfCampByIndex(_campId);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);

        for(uint i; i < totalSupply(); i++){
            uint256 this_camp = _campListByTokenIndex[i];
            if (_campId == this_camp){
                tokensId[i] = this_camp;
            }
        }
        return tokensId;
    }

    // how many tokens for any campId
    function tokensOfCampByIndex(uint256 _campId) public view returns (uint256) {
        require(_campId <= _campCount, "Camp does not exist.");

        uint count;
        for(uint i; i < _campListByTokenIndex.length; i++){
            if(_campId == _campListByTokenIndex[i]){
                count++;
            }
        }

        return count;

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