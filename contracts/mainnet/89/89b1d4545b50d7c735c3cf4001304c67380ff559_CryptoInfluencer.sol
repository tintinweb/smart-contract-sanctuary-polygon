// SPDX-License-Identifier: NONE

pragma solidity >=0.8.10 <=0.8.10;

import "./OpenzeppelinERC721Ownable.sol";

contract CryptoInfluencer is  ERC721URIStorage , ERC721Enumerable , Ownable{

    uint256 public nftid = 1;

    event Mint();
    event SetTokenURI( uint256 , string );

    function tennnoMint(string memory _uri) public {
        require( _msgSender() == owner() );
        _safeMint( owner() , nftid);
        _setTokenURI( nftid , _uri );
        emit Mint();
        emit SetTokenURI( nftid , _uri );
        nftid++;
    }

    function renounceOwnership() public pure override{
        revert("renounce disabled.");
    }

    function setTokenURI( uint targetnftid ,string memory _uri ) public {
        require( _msgSender() == owner() );
        //ipfs://Qm....... or https://arweave.net/......  etc.
        _setTokenURI( targetnftid , _uri );
        emit SetTokenURI( targetnftid , _uri );
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function burn(uint256 _id) public {
        require( _msgSender() == ownerOf(_id));
        _burn(_id);
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



    constructor() ERC721("Crypto Influencer" , "JAPAN" ) {
    } 


}