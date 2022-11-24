// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract Wukong is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    bool public public_mint_status = true;

    uint256 MAX_SUPPLY = 2222;

    string public notRevealedUri;
    
    bool public revealed = true;

    uint256 public publicSaleCost = 55 ether;
    uint256 public max_per_wallet = 2222;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Wukong", "Wukong") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    }

    function mint(uint256 quantity) public payable  {
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(public_mint_status, "public mint is off");
            require(balanceOf(msg.sender) + quantity <= max_per_wallet,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);

    }

    function airdrop(address[] calldata _holders, uint256[] calldata _quantities) public onlyOwner{

        require(_holders.length == _quantities.length, "Data doesn't match");
        for(uint256 x = 0 ; x < _holders.length ; x++){

            _safeMint(_holders[x], _quantities[x]);

        }

    }
   
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if(revealed == false) {
        return notRevealedUri;
        }
      
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }



    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


    //only owner      
    
    function toggleReveal() public onlyOwner {
        
        if(revealed==false){
            revealed = true;
        }else{
            revealed = false;
        }
    }   

        
    function toggle_public_mint_status() public onlyOwner {
        
        if(public_mint_status==false){
            public_mint_status = true;
        }else{
            public_mint_status = false;
        }
    }  

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }
     
    function withdraw() public payable onlyOwner {
  
    (bool main, ) = payable(owner()).call{value: address(this).balance}("");
    require(main);
    }
    
    function setPublicSaleCost(uint256 _publicSaleCost) public onlyOwner {
        publicSaleCost = _publicSaleCost;
    }

    function setMax_per_wallet(uint256 _max_per_wallet) public onlyOwner {
        max_per_wallet = _max_per_wallet;
    }

    function setMAX_SUPPLY(uint256 _MAX_SUPPLY) public onlyOwner {
        MAX_SUPPLY = _MAX_SUPPLY;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
   }
       
}