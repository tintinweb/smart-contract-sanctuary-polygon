//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./ERC2981.sol";
import "./Ownable.sol";
import "./AccessControl.sol";
contract UserContent is ERC721Enumerable, ERC721URIStorage, ERC2981, Ownable, AccessControl {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(uint96 _royaltyFeesInBips) ERC721("User Content", "UC") {
        setRoyaltyInfo(owner(), _royaltyFeesInBips);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function bulkMint(address _user, uint256[] calldata _tokenIds, string[] calldata _uri)
    external
    {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        for(uint i = 0; i < _tokenIds.length; i++){
            _safeMint(_user, _tokenIds[i]);
            _setTokenURI(_tokenIds[i], _uri[i]);
        }
    }

    function updateURI(uint256 _tokenId, string calldata _uri) external {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _setTokenURI(_tokenId, _uri);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function getTokenIds(address _owner) public view returns (uint[] memory) {
        uint[] memory _tokensOfOwner = new uint[](ERC721.balanceOf(_owner));
        uint i;

        for (i=0;i < ERC721.balanceOf(_owner);i++){
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }
}