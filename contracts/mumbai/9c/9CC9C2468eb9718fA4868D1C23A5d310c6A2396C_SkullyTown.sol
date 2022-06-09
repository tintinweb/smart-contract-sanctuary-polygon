// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import 'Ownable.sol';
import 'Strings.sol';
import 'ERC721AQueryable.sol';


pragma solidity ^0.8.0;


contract SkullyTown is ERC721A, Ownable{
    using Strings for uint256;

    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant OFFER_SUPPLY = 2500;
    uint256 public constant GENERAL_SUPPLY = 7500;
    uint256 public constant OFFER_PRICE = .05 ether;
    uint256 public constant GENERAL_PRICE = .01 ether;

    string private  baseTokenUri;  // No Reveal Uri
    string public   placeholderTokenUri; // Reveal Uri

    //deploy smart contract, toggle publicSale 
    //14days later toggle reveal
    bool public isRevealed;
    bool public publicSale;
    bool public pause;
    bool public teamMinted;

    mapping(address => uint256) public totalPublicMint;

    constructor() ERC721A("SkullyTown", "ST"){

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Cannot be called by a contract");
        _;
    }
    
    function OfferMint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, "Not Yet Active.");
        require((totalSupply() + _quantity) <=  OFFER_SUPPLY, "The discounted mint has ended");
        require(msg.value >= (OFFER_PRICE * _quantity), "Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }


    function GeneralMint(uint256 _quantity) external payable callerIsUser{
        require(publicSale, " Not Yet Active.");
        require((totalSupply() + _quantity) >=  GENERAL_SUPPLY, "Not active yet, you can mint with a discount");
        require((totalSupply() + _quantity) <= MAX_SUPPLY, "Beyond Max Supply");
        require(msg.value >= (GENERAL_PRICE * _quantity), "Below ");

        totalPublicMint[msg.sender] += _quantity;
        _safeMint(msg.sender, _quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }

    //return uri for certain token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 trueId = tokenId + 1;

        if(!isRevealed){
            return placeholderTokenUri;
        } 
        //string memory baseURI = _baseURI();
        return bytes(baseTokenUri).length > 0 ? string(abi.encodePacked(baseTokenUri, trueId.toString(), ".json")) : "";
    }


    function setTokenUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function setPlaceHolderUri(string memory _placeholderTokenUri) external onlyOwner{
        placeholderTokenUri = _placeholderTokenUri;
    }

  
    function togglePause() external onlyOwner{
        pause = !pause;
    }

    function togglePublicSale() external onlyOwner{
        publicSale = !publicSale;
    }

    function toggleReveal() external onlyOwner{
        isRevealed = !isRevealed;
    }

    function withdraw() external onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}