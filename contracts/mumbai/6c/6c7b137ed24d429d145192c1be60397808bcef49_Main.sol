pragma solidity ^0.5.0;

import "./ERC721.sol";

contract Main is ERC721Full {
    using SafeMath for uint256;


    address payable public admin;
    uint256 public tokenCount=0;

    mapping(address => mapping(uint256 => bool)) public valid;
    mapping(uint256 => address) private nfts;

    event NftMinted(address creator,uint256 tokenId,string tokenURI,uint256 price);
    event NftPurchased(address buyer,uint256 tokenId,uint256 price);

    constructor(address _admin) public ERC721Full("Zub Token", "ZT") {
        require(_admin != address(0), "Zero admin address");
        admin = address(uint160(_admin));
    }

    // function nftListOfUser(address user) external view returns (address[] memory) {
    //     return (nfts[user]);
    // }

    // function allNftList(address user) external view returns (address[] memory) {
    //     return (nfts);
    // }

    function changeAdmin(address _admin) external returns (bool) {
        require(msg.sender == admin, "Only admin");
        require(_admin != address(0), "Zero address");
        admin = address(uint160(_admin));
        return true;
    }

    function mintNft(string memory _tokenURI) public payable returns (bool){
        require(bytes(_tokenURI).length > 0, "Invalid URI");
        require(msg.value > 0, "Invalid fee");
        tokenCount++;
        _mint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        nfts[tokenCount] = msg.sender;
        admin.transfer(msg.value);
        emit NftMinted(msg.sender,tokenCount,_tokenURI,msg.value);
        return true;
    }

    function buyNft(uint256 tokenId) public payable returns (bool){
        require(_exists(tokenId), "Invalid tokenId");
        require(msg.value > 0, "Invalid fee");
        require(ownerOf(tokenId) != msg.sender, "Can't buy own nft");
        require(!valid[msg.sender][tokenId], "Already bought this nft");
        valid[msg.sender][tokenId] = true;
        address payable owner = address(uint160(ownerOf(tokenId)));
        uint256 ownerFee = msg.value.mul(90).div(100);
        owner.transfer(ownerFee);
        admin.transfer(msg.value.sub(ownerFee));
        _transferFrom(ownerOf(tokenId), msg.sender, tokenId);
        nfts[tokenId] = msg.sender;
        emit NftPurchased(msg.sender, tokenId, msg.value);
        return true;
    }

    function burn(uint256 tokenId) external returns (bool) {
        _burn(msg.sender, tokenId);
        return true;
    }
}