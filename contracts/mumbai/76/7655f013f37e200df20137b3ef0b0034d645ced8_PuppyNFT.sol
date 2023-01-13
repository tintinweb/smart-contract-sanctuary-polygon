/**
 *Submitted for verification at polygonscan.com on 2023-01-12
*/

// File: puppiesfinal.sol


pragma solidity ^0.8.0;

contract PuppyNFT {
    // ERC721 Token Metadata
    string public name = "Puppy NFT";
    string public symbol = "PUP";
    uint8 public decimals = 0;

    // ERC721 Token Properties
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    // Initial Minting Value
    uint256 public initialMintingValue = 0.1 ether;

    // Overriding Function
    function mint(address _to, uint256 _tokenId, string memory _tokenURI) public {
        require(msg.sender == msg.sender, "Only owner can mint new tokens.");
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        tokenURI[_tokenId] = _tokenURI;
        emit Transfer(address(0), _to, _tokenId);
    }

    // ERC721 Token Functions
    function transfer(address _to, uint256 _tokenId) public {
        require(balanceOf[msg.sender] >= 1 && ownerOf[_tokenId] == msg.sender, "You do not have permission to transfer this token.");
        balanceOf[msg.sender]--;
        balanceOf[_to]++;
        ownerOf[_tokenId] = _to;
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public {
        require(ownerOf[_tokenId] == msg.sender, "You do not have permission to approve this transfer.");
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getBalance(address _owner) public view returns (uint256) {
        return balanceOf[_owner];
    }

    function getOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf[_tokenId];
    }

    function getTokenURI(uint256 _tokenId) public view returns (string memory) {
        return tokenURI[_tokenId];
    }
}