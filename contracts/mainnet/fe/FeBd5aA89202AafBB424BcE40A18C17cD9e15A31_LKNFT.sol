// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.10;
import "./Ownable.sol";

import "./Counters.sol";
import "./ERC721URIStorage.sol";
import "./ERC721.sol";
import "./IERC20.sol";

contract LKNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress = address(0);
    address LK_ERC20_address;
    address public TLK_receiver_account;
    address public NFT_Holder_account;
    uint public TLK_fee = 1;
    uint public max_token_mint=10;
    //mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    constructor() ERC721("Legacy Kollective NFT", "LKNFT") {
       /*
            contractAddress = marketplaceAddress;
    */
    }

    function createToken(string memory tokenURI) public onlyOwner returns (uint) {
        IERC20(LK_ERC20_address).approve(TLK_receiver_account, TLK_fee); //Approving TLK token from the minter account

        _tokenIds.increment();        
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        //setApprovalForAll(contractAddress, true);
        return newItemId;
    }

    function transferToken(address from, address to, uint256 tokenId) public onlyOwner {
        require(ownerOf(tokenId) == from, "From address must be token owner");
        //_transfer(from, to, tokenId);
        safeTransferFrom(from, to, tokenId);
    }
        
    function mintNft_counter_self(address receiver, string memory stokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        receiver = msg.sender;
        uint256 newNftTokenId = _tokenIds.current();
        //_mint(receiver, newNftTokenId);
        _safeMint(receiver, newNftTokenId,""); 
        _setTokenURI(newNftTokenId, stokenURI);
        //setApprovalForAll(contractAddress, true);
        return newNftTokenId;
    }

    function mintNft_counter(string memory stokenURI) external onlyOwner returns (uint256) {
        _tokenIds.increment();
        require(NFT_Holder_account != address(0),"Address should be valid. NFT Holder.");
        uint256 newNftTokenId = _tokenIds.current();        
        _safeMint(NFT_Holder_account, newNftTokenId,""); 
        _setTokenURI(newNftTokenId, stokenURI);
        // uint256 length = ERC721.balanceOf(NFT_Holder_account);
        //_ownedTokens[NFT_Holder_account][length] = newNftTokenId;
        //setApprovalForAll(contractAddress, true);
        return newNftTokenId;
    }

    function mintNft_counter_bulk(uint no_of_tokens, string memory stokenURI) external onlyOwner returns (uint256) {
        
        require(NFT_Holder_account != address(0),"Address should be valid. NFT Holder.");
        require(no_of_tokens <= max_token_mint, "Maximum NFT token limit has been reached." );
        uint256 newNftTokenId;
        for(uint i = 0; i<no_of_tokens; i++){
    
        _tokenIds.increment();
         newNftTokenId = _tokenIds.current();        
        _safeMint(NFT_Holder_account, newNftTokenId,""); 
        _setTokenURI(newNftTokenId, stokenURI);
        //setApprovalForAll(contractAddress, true);
        }
        return newNftTokenId;
    }

     function burn_token(uint256 tokenId) public onlyOwner {
         _burn(tokenId);

     }




    /*function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }*/


    function set_LK_ERC20(address addr) public onlyOwner{
        LK_ERC20_address = addr;
    }

    function set_Marketaddress(address market) public onlyOwner{
        contractAddress = market;

    }
    function set_TLK_Receiver_account(address addr) public onlyOwner{
        TLK_receiver_account = addr;

    }
    function set_NFT_Holder(address addr) public onlyOwner{
        NFT_Holder_account = addr;

    }
     function set_Max_NFT_token(uint t) public onlyOwner{
        max_token_mint = t;

    }
}