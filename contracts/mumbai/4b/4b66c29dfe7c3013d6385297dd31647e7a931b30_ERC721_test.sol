// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "../ERC721.sol";
import "../ERC721URIStorage.sol";
import "../Counters.sol";
import "../Ownable.sol";

contract ERC721_test is ERC721URIStorage, Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event Print_Requested(uint256 tokenId, address token_owner);
    event NFT_Status_Changed(uint256 tokenId, uint256 status);
    string private contract_uri = 'https://gateway.pinata.cloud/ipfs/QmXgsTjqii6qGh9Z95bobwm2ck1YTdJy5Fju8SfKbh9TEn';

    //set a certain status of a specific nft.
    //In the initial setup these would be the status data and thier interpretation:
    //xxxxxxx0 - print disabled
    //xxxxxxx1 - print enabled
    //xxxxxx1x - request pending
    //xxxxx0xx - not printed
    //xxxxx1xx - already printed 
    mapping(uint => uint256) private nft_status;
    string private baseTokenURI = '';

    constructor() ERC721("NFT_name", "NFT_symbol") {}

    function set_nft_status (uint256 tokenId, uint256 status) public onlyOwner() {
        require(_exists(tokenId), "ERC721Metadata: nft_status input for nonexistent token");
        nft_status[tokenId] = status;
        emit NFT_Status_Changed(tokenId, status);
    }

    function get_nft_status (uint256 tokenId) public view returns(uint256) {
        require(_exists(tokenId), "ERC721Metadata: nft_status query for nonexistent token");
        return nft_status[tokenId];
    }

    function request_print (uint256 tokenId) public {
        require(_exists(tokenId), "ERC721Metadata: print query for nonexistent token");
        require( nft_status[tokenId] % 10 == 1, "ERC721Metadata: Any print is not available for this NFT");
        require( nft_status[tokenId] % 100 / 10 != 1, "ERC721Metadata: Print request for this NFT is already pending");
        require( nft_status[tokenId] % 1000 /100 == 0, "ERC721Metadata: This NFT has been already printed");
        require(ownerOf(tokenId) == msg.sender, "ERC721Metadata: Only the owner of the NFT can request a print");
        nft_status[tokenId] = 11;
    }
 
    function contractURI() public view returns (string memory) {
        return contract_uri;
    }

    function set_contractURI(string memory _contract_uri) public onlyOwner(){
        contract_uri = _contract_uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseTokenURI(string memory _baseTokenURI) public {
        baseTokenURI = _baseTokenURI;
    }

}