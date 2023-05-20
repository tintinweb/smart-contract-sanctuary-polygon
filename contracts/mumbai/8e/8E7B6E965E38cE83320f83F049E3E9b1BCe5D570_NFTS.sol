// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./ERC1155.sol";
import "./Owner.sol";
import "./Counters.sol";

contract NFTS is ERC1155, Owner {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;

    mapping (uint256 => string) private _uris;

    mapping (uint256 => address) private artists;

    event Set_TokenUri(
        uint256 tokenId,
        string uri
    );

    event Create_Token(
        uint256 tokenId,
        address owner,
        uint256 amount,
        string uri
    );

    constructor() ERC1155("https://gateway.pinata.cloud/ipfs/QmYtET2YHMkVN4BbnBZHaf5qkjv9DLasyfQ6e8x3RcDcKA/") { }

    function createToken(uint256 _amount, string memory _uri) external {
        tokenIds.increment();
        uint256 newTokenId = tokenIds.current();
        _mint(msg.sender, newTokenId, _amount, "");
        setTokenUri(newTokenId, _uri);
        artists[newTokenId] = msg.sender;
        emit Create_Token(newTokenId, msg.sender, _amount, _uri);
    }
    
    function setTokenUri(uint256 _tokenId, string memory _uri) private {
        _uris[_tokenId] = _uri;
        emit Set_TokenUri(_tokenId, _uri);
    }

    function uri(uint256 _tokenId) override public view returns (string memory) {
        return(_uris[_tokenId]);
    }

    function artistOf(uint256 _tokenId) external view returns(address) {
        return artists[_tokenId];
    }


}