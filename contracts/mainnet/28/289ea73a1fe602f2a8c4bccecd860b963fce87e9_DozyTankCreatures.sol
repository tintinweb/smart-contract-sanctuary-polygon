// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";
import "IERC20.sol";
import "ERC2981.sol";
import "DefaultOperatorFilterer.sol";


contract DozyTankCreatures is ERC721A, Ownable, ERC2981, DefaultOperatorFilterer {
    using Strings for uint256;

    IERC20 public token;

    string public baseURI;

    bool public public_mint_status = true;

    uint256 MAX_SUPPLY = 10000;

    string public notRevealedUri;
    
    bool public revealed = false;

    uint256 public publicSaleCost = 10 ether;
    uint256 public max_per_wallet = 20;
    uint256 public refRewardAmount = 5;
    uint256 public decimalNumber = 9;
    string public contractURI;

    address _token_Contract = 0x5A4888E6755d488455FA60bea50631a8B30cdEdb;

    constructor(string memory _initBaseURI, string memory _initNotRevealedUri, string memory _contractURI) ERC721A("Dozy Tank Creatures", "DTC") {
    
    token = IERC20(_token_Contract);
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);    
    setRoyaltyInfo(owner(),500);
    contractURI = _contractURI;  
    mint(1, msg.sender);
    }

    function mint(uint256 quantity, address ref) public payable  {

        if(ref != msg.sender){
        token.transfer(ref, quantity * refRewardAmount * 10 ** decimalNumber);
        }

        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough tokens left");

        if (msg.sender != owner()) {
            require(public_mint_status, "public mint is off");
            require(balanceOf(msg.sender) + quantity <= max_per_wallet,"Per wallet limit reached");
            require(msg.value >= (publicSaleCost * quantity), "Not enough ether sent");          
           
        }
        _safeMint(msg.sender, quantity);

    }
   
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

    if(revealed == false) {
        return notRevealedUri;
        }
      
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString(),".json")) : '';
    }


    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, ERC2981)
        returns (bool)
    {
        // Supports the following `interfaceId`s:
        // - IERC165: 0x01ffc9a7
        // - IERC721: 0x80ac58cd
        // - IERC721Metadata: 0x5b5e139f
        // - IERC2981: 0x2a55205a
        return
            ERC721A.supportsInterface(interfaceId) ||
            ERC2981.supportsInterface(interfaceId);
    }


    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
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
    
    function tokenWithdrawal() public onlyOwner{
    token.transfer(msg.sender,token.balanceOf(address(this)));
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

    function setRefRewardAmount(uint256 _refRewardAmount) public onlyOwner {
        refRewardAmount = _refRewardAmount;
    }

    function setDecimalNumber(uint256 _decimalNumber) public onlyOwner {
        decimalNumber = _decimalNumber;
    }

    function setTokenContract(address _tokenContract) public onlyOwner{
    token = IERC20(_tokenContract);
    }

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeesInBips) public onlyOwner {
        _setDefaultRoyalty(_receiver, _royaltyFeesInBips);
    }

    function setContractURI(string calldata _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }
}