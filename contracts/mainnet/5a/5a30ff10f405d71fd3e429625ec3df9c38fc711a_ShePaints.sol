// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";


contract ShePaints is ERC721A, Ownable {
    using Strings for uint256;


    string private baseURI;

    uint256 public MAX_SUPPLY = 10000;  
    uint256 public Avl_Supply = 3333;
    uint256 public cost = 48 ether;

    bool public paused = false;

    constructor(string memory _initBaseURI) ERC721A("She Paints ", "SP") {
    
    setBaseURI(_initBaseURI);
  
    }

    function mint(uint256 quantity) public payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(Avl_Supply <= MAX_SUPPLY);
        require(!paused, "the contract is paused");
        require(totalSupply() + quantity <= Avl_Supply, "Not enough tokens left");
        uint256 supply = totalSupply();

        if (msg.sender != owner()) {

            if(supply == Avl_Supply){
            revert("All tokens in the session have been sold!");

            } else {
            require(msg.value >= (cost * quantity), "Not enough ether sent");  
            
            }
                       
            
        }
        _safeMint(msg.sender, quantity);

    }

     function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
    
    //only owner

    function setAvl_supply(uint256 _avlSupply) public onlyOwner {
        Avl_Supply = _avlSupply;
    }

    function withdraw() public payable onlyOwner {

    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    
    function setMintRate(uint256 _cost) public onlyOwner {
        cost = _cost;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }
 
   
}