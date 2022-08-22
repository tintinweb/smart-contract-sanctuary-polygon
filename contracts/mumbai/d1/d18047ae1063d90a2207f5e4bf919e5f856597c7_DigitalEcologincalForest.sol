// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Ownable.sol";
import './ERC721A.sol';

contract DigitalEcologincalForest is ERC721A, Ownable {

    uint public sameAddressMaxMint;
    uint public maxMint;
    uint public porfit;
    uint public maxTotal;
    uint public price;
    uint public mintTime;
    bool public publicMintOpen;
    address public withdrawAddress;
    string public baseTokenURI;
    mapping(address => uint) public mintCount;
    
    constructor() ERC721A("Digital Ecological Forest", "DEF")  {
        sameAddressMaxMint = 5;
        maxMint = 5;
        maxTotal = 10262;
        price = 100 ether;
        mintTime = 1661961600;
        baseTokenURI = "http://nft-forest.net/export/outjson/";
        withdrawAddress = msg.sender;
    }

    function publicMint(uint256 num) public payable {
        uint256 supply = totalSupply();
        require(publicMintOpen, "no mint time");
        require(num <= maxMint, "You can mint a maximum of 5 NFT");
        require(supply + num <= maxTotal, "Exceeds maximum DEF supply");
        require(mintCount[msg.sender] + num <= sameAddressMaxMint, "Exceeds maximum DEF supply");
        require(block.timestamp >= mintTime, "no mint time");
        require(msg.value >= price * num, "Ether sent is not correct");    

        mintCount[msg.sender] += num;
        _safeMint(msg.sender, num);
    }

    function getAirDrop(uint16 _num, address recipient) public onlyOwner {
        _safeMint(recipient, _num);
    }

    function setWithdrawAddress(address _withdrawAddress) public onlyOwner {
        withdrawAddress = _withdrawAddress;
    }

    function setPublicMintOpen() public onlyOwner {
        publicMintOpen = !publicMintOpen;
    }

    function setMintTime(uint _mintTime) public onlyOwner {
        mintTime = _mintTime;
    }

    function setMintPrice(uint _price) public onlyOwner {
        price = _price;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function withdrawAll() public onlyOwner {
        (bool success, ) = withdrawAddress.call{value: address(this).balance}("");
        require(success, "not success");
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }
}