pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./Strings.sol";
import "./ERC721.sol";

contract FDJ is ERC721,Ownable {
    
    address public dropperAddress;

    string private baseURI = "ipfs://QmbgNiWTLEYihDFwLu3YoAc2eBQC9ydGcpQb3KQH79Hx1d/";

    uint256 public totalSupply;

    constructor()
    ERC721("TESTJDGEZGATEST2","TESTFDJ2")
        {
        }

    /**
        Mint ouvert à owner et dropperAddress (air drop).
        Token id est compris entre 1 et 1500 (bornes incluses).
     */
    function mint(address targetAddress, uint256 tokenId) external {
        require(msg.sender == owner() || msg.sender == dropperAddress, "Not allowed");       
        require(tokenId >= 1 && tokenId <= 1500, "token Id out of bounds");
        _safeMint(targetAddress, tokenId);
        totalSupply++;
    }

    /**
    */
    function setDropperAddress(address targetAddress) external onlyOwner {
        dropperAddress = targetAddress;
    }

    /**
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory)   {
        string memory uri = string(abi.encodePacked(baseURI,Strings.toString(tokenId)));
        uri = string(abi.encodePacked(uri,".json"));
        return uri;
    }

    /**
       Le transfert de token est desactive.
     */
    function _beforeTokenTransfer(address from, address to,  uint256 tokenId) internal virtual override(ERC721) {
        require(address(0) == from || address(0) == to, "Token transfer is not allowed");      
    }
    
    /**
        Le burn est autorise pour le proprietaire du contrat et celui du jeton.
     */
    function burn(uint256 tokenId) internal virtual {
        address ownesr = ERC721.ownerOf(tokenId);
        require(msg.sender == owner() || msg.sender == ownesr, "Only token owner and contract owner can burn");
        _burn(tokenId);
    }



}