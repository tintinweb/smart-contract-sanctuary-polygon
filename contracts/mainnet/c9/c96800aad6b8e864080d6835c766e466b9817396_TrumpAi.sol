// SPDX-License-Identifier: MIT


import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract TrumpAi is ERC721, Ownable, nonReentrant {

    string public TRUMPAI_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN TRUMPAI ARE ALL SOLD OUT
    
    uint256 public trumpaiPrice = 1000000000000000000; // 1 MATIC for MINT

    uint public constant maxTrumpAiPurchase = 1000;

    uint256 public constant MAX_TRUMPAI = 45000;

    bool public saleIsActive = false;
    
    // mapping(uint => string) public trumpaiNames;
    
    // Reserve TrumpAi for team - Giveaways/Prizes etc
	uint public constant MAX_TRUMPAIRESERVE = 2000;	// total team reserves allowed
    uint public TrumpAiReserve = MAX_TRUMPAIRESERVE;	// counter for team reserves remaining 
    
    constructor() ERC721("TrumpAi", "TRUMPAI") { }
    
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

	
	function setTrumpAiPrice(uint256 _trumpaiPrice) public onlyOwner {
        trumpaiPrice = _trumpaiPrice;
    }
	
	
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        TRUMPAI_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }


    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
    
    
    function reserveTrumpAi(address _to, uint256 _reserveAmount) public onlyOwner {        
        uint reserveMint = MAX_TRUMPAIRESERVE - TrumpAiReserve; // Mint from beginning of tokenIds
        require(_reserveAmount > 0 && _reserveAmount < TrumpAiReserve + 1, "Not enough reserve left to fulfill amount");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        TrumpAiReserve = TrumpAiReserve - _reserveAmount;
    }


    function mintTrumpAi(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint TrumpAi");
        require(numberOfTokens > 0 && numberOfTokens < maxTrumpAiPurchase + 1, "Can only mint 15 tokens at a time");
        require(totalSupply() + numberOfTokens < MAX_TRUMPAI - TrumpAiReserve + 1, "Purchase would exceed max supply of TrumpAi");
        require(msg.value >= trumpaiPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + TrumpAiReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_TRUMPAI) {
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