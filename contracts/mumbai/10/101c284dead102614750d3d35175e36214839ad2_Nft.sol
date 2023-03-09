// SPDX-License-Identifier: MIT;

pragma solidity ^0.8.0;


import "./ERC721.sol";
import "./IERC721Receiver.sol";

contract Nft is ERC721 {


    //constructor() ERC721("myFirstNFT","HNT") {}
    constructor (string memory name_, string memory symbol_) ERC721(name_,symbol_) {
        
    }
    
    function onERC721Received(address, address, uint256, bytes memory) public pure  returns (bytes4) {
         return this.onERC721Received.selector;
     }


    function mint_batch(address to, uint256[] memory tokenIds) public {
        require(tokenIds.length > 0,"The tokenIds must be have");
        //if (msg.sender != _admin) return;
        //_safeMint(to, tokenId, "");
        //uint[] memory returnTokenUrls = new uint[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++){
            //  _tokenId.increment();
            //  newTokenId = _tokenId.current();
            //  _tokenURIs[newTokenId] = _tokenUrls[i];
            // returnTokenUrls[i] = tokenIds[i];
             mint(to,tokenIds[i]);
         }
        
    }

    /**
     * 返回tokenId是否存在
     *
     * Tokens 被mint时开始存在，直到被燃烧掉,
     */
    function exists(uint256 tokenId) public view returns(bool r) {
        return _exists(tokenId);
    }

       /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */


}