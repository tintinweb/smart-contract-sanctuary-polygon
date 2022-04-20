// SPDX-License-Identifier: MIT

// Adapted from UpsidePunks on ETH
// Modified and updated to 0.8.0 by Gerardo Gomez
// Tiny Dinos Ai Art by FATBOIGOMEZ
// <3 The Gomez Family
// Special thanks to my #NFTFAM and everyone who follows me and owns my NFT's


import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract TINYDINOSAI is ERC721, Ownable, nonReentrant {

    string public TINYDINOSAI_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TINY DINOS AI ARE ALL SOLD OUT
    
    uint256 public TINYDINOSAIPrice = 10000000000000000000; // 10 MATIC

    uint public constant maxTINYDINOSAIPurchase = 40;

    uint256 public constant MAX_TINYDINOSAI = 15000;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public TINYDINOSAINames;
    
    // Reserve TINYDINOSAI for team - Giveaways/Prizes etc
	uint public constant MAX_TINYDINOSAIRESERVE = 1000;	// total team reserves allowed
    uint public TINYDINOSAIReserve = MAX_TINYDINOSAIRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("Tiny Dinos Ai", "TDAi") { }
    
    // withraw to project wallet
    function withdraw(uint256 _amount, address payable _owner) public onlyOwner {
        require(_owner == owner());
        require(_amount < address(this).balance + 1);
        _owner.transfer(_amount);
    }
    
    // withdraw to team
	function teamWithdraw(address payable _team1, address payable _team2) public onlyOwner {
        uint balance1 = address(this).balance / 2;
		uint balance2 = address(this).balance - balance1;
		_team1.transfer(balance1);
		_team2.transfer(balance2);
    }

	
	function setTINYDINOSAIPrice(uint256 _TINYDINOSAIPrice) public onlyOwner {
        TINYDINOSAIPrice = _TINYDINOSAIPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        TINYDINOSAI_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveTINYDINOSAI(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_TINYDINOSAIRESERVE - TINYDINOSAIReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < TINYDINOSAIReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        TINYDINOSAIReserve = TINYDINOSAIReserve - _reserveAmount;
    }


    function mintTINYDINOSAI(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint TINYDINOSAI");
        require(numberOfTokens > 0 && numberOfTokens < maxTINYDINOSAIPurchase + 1, "Can only mint 40 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_TINYDINOSAI - TINYDINOSAIReserve + 1, "Purchase would exceed max supply of TINYDINOSAI");
        require(msg.value >= TINYDINOSAIPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + TINYDINOSAIReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_TINYDINOSAI) {
                _safeMint(msg.sender, mintIndex);
            }
        }

    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
	
    
}