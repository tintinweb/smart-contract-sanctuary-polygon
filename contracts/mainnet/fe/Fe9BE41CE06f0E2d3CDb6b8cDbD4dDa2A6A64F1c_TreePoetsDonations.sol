// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract TreePoetsDonations is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI;

    bool public public_mint_status = true;

    uint256 MAX_SUPPLY = 8784;

    string public notRevealedUri;
    
    bool public revealed = true;

    uint256 public publicSaleCost = 0 ether;
    uint256 public max_per_wallet = 20;
    uint256 public mintedCount = 0;
    uint256 public timeGap = 86400;

    mapping(address => uint256) public lastMintedNFTID;
    mapping(address => mapping(uint256 => uint256)) public myMintedNFTs;
    mapping(address => uint256) public myMintedCount;
    mapping(uint256 => uint256) public mintedTime;

    
    constructor(string memory _initBaseURI, string memory _initNotRevealedUri) ERC721A("Tree Poets Donations", "TPD") {
    
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    }

    function mint(uint256 ID) public payable  {
        require(totalSupply() + 1 <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(block.timestamp - mintedTime[ID] >= timeGap,"Too many request per day");
            require(public_mint_status, "public mint is off");
            require(balanceOf(msg.sender) + 1 <= max_per_wallet,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * 1), "Not enough ether sent");          
           
        }

        _safeMint(owner(), 1);

        lastMintedNFTID[msg.sender] = mintedCount;
        myMintedNFTs[msg.sender][myMintedCount[msg.sender]] = mintedCount;
        mintedCount++;
        myMintedCount[msg.sender]++;
        mintedTime[ID] = block.timestamp;

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

    function setTimeGap(uint256 _timeGap) public onlyOwner {
        timeGap = _timeGap;
   }

       
}