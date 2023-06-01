// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./DefaultOperatorFilterer.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ReferralStorage.sol";


contract NetlyFans is ERC721, Ownable, DefaultOperatorFilterer, ReferralStorage {
    using Strings for uint256;

    uint public constant MAX_TOKENS = 5000;
    uint public price = 350000000000000000000; // 350
    uint256 public constant MAX_MINT_PER_TX = 100;
    uint public constant MAX_PER_WALLET = 100;

    address private feeW1 = 0xA3a21Ab1624559b0F5faAa1E9fdf1602112D812d;
    address private feeW2 = 0x5759A50dcAd2F6cE0C2D4c5A562C05fe1f5Bce25;
    address private feeW3 = 0x77d4321478234c729bDA5011722C85465BEd0917;

    bool public isSaleActive;
    uint256 public totalSupply;
    mapping(address => uint256) private mintedPerWallet;

    string public baseUri;
    string public baseExtension = ".json";

    constructor() ERC721("Netlyfans", "NF") {
        baseUri = "ipfs://bafybeiab2vjsz252unl7uk3tu4zufoyhzmldxkozylyqrebcfhrynlo744/";
    }

    // Public Functions
    function mintwithRef(address _referral, uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(_numTokens <= MAX_MINT_PER_TX, "You cannot mint that many in one transaction.");
        require(mintedPerWallet[msg.sender] + _numTokens <= MAX_PER_WALLET, "You cannot mint that many total.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS, "Exceeds total supply.");
        require(_numTokens * price <= msg.value, "Insufficient funds.");
        uint256 fee = 0;
        if(_isAffiliate[_referral]){
           fee = _withReferralSale(msg.value, msg.sender, _referral, block.timestamp);
        }

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }

        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;

        if (fee > 0) {
             withdrawFees(_referral, fee);
        }
        
        
        
    }

    function mint(uint256 _numTokens) external payable {
        require(isSaleActive, "The sale is paused.");
        require(_numTokens <= MAX_MINT_PER_TX, "You cannot mint that many in one transaction.");
        require(mintedPerWallet[msg.sender] + _numTokens <= MAX_MINT_PER_TX, "You cannot mint that many total.");
        uint256 curTotalSupply = totalSupply;
        require(curTotalSupply + _numTokens <= MAX_TOKENS, "Exceeds total supply.");
        require(_numTokens * price <= msg.value, "Insufficient funds.");

        for(uint256 i = 1; i <= _numTokens; ++i) {
            _safeMint(msg.sender, curTotalSupply + i);
        }
        mintedPerWallet[msg.sender] += _numTokens;
        totalSupply += _numTokens;
    }

    // Owner-only functions
    function flipSaleState() external onlyOwner {
        isSaleActive = !isSaleActive;
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }
	
	function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function withdrawAll() external payable onlyOwner {
        uint256 balance = address(this).balance;
        uint256 balanceOne = balance * 35 / 100;
        uint256 balanceTwo = balance * 35 / 100;
        uint256 balanceThree = balance * 30 / 100;
        ( bool transferOne, ) = payable(feeW1).call{value: balanceOne}("");
        ( bool transferTwo, ) = payable(feeW2).call{value: balanceTwo}("");
        ( bool transferThree, ) = payable(feeW3).call{value: balanceThree}("");
        require(transferOne && transferTwo && transferThree, "Transfer failed.");
    }

    function withdrawFees (address _receiver, uint256 _amount) internal {
        ( bool transferOne, ) = payable(_receiver).call{value: _amount}("");
       require(transferOne, "Transfer failed.");
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
 
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }
 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }
}