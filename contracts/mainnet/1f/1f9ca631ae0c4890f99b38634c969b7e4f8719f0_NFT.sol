// SPDX-License-Identifier: MIT
// by 0xChrisx

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract NFT is Ownable, ERC721A, ReentrancyGuard {

    event Received(address, uint);

    uint256 public publicMintActive = 0 ;

    uint256 public mintPrice = 0 ether;
    uint256 public collectionSize_ = 999 ;
    uint256 public maxPerAddress = 1 ;

    string private baseURI = "url" ;

    constructor() ERC721A("Rainbowlist", "RL", maxPerAddress , collectionSize_ ) {

    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
    _;
    }

//------------------ BaseURI 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI (string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }
//--------------------- END BaseURI
//--------------------- Set & Change anythings

    function setMintPrice (uint256 newPrice) public onlyOwner {
        mintPrice = newPrice ;
    }
    
    function setCollectionSize (uint256 newCollectionSize) public onlyOwner {
        collectionSize_ = newCollectionSize ;
    }

    function setMaxPerAddress (uint newMaxPerAddress) public onlyOwner {
        maxPerAddress = newMaxPerAddress ;
    }

//--------------------- END Set & Change anythings
//--------------------- MintStatusActive


    function togglePublicMintActive() public onlyOwner {
        
        if(publicMintActive == 0) {
            publicMintActive = 1;
        } else {
            publicMintActive = 0;
        }
    }

    function pauseAllMint() public onlyOwner {
        // pause everything
        publicMintActive = 0;
    }

//--------------------- END MintStatusActive
//--------------------------------------- Mint
//-------------------- PublicMint
    function publicMint(uint _mintAmount) external payable callerIsUser {

        require(publicMintActive >= 1, "Public sale is close.");
        require(totalSupply() + _mintAmount <= collectionSize_  , "This collection is Sold out."); // must less than collction size
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, "You reached max per address, pls do less."); // check max mint PerAddress ? คุณไม่สามารถมิ้นมากกว่า Max per address ได้ โปรดลองจำนวนที่ต่ำกว่า
        require(msg.value >= mintPrice * _mintAmount, "ETH amount is not sufficient.");

        _safeMint(msg.sender, _mintAmount);
    }

    function numberMinted(address owner) public view returns (uint256) { // check number Minted of that address จำนวนที่มิ้นไปแล้ว ใน address นั้น
        return _numberMinted(owner);
    }
//-------------------- END PublicMint
//-------------------- DevMint
    function devMint(address _to ,uint _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size.");
        _safeMint( _to,_mintAmount);
    }
//-------------------- END DevMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0x00778e7EBE6Ca9D082335Fc027d1A4aB3233036c; // CHRIS
        address private wallet2 = 0x4B0A54D5529D34352048022a6e67BB6a26d91A7A; // KAY
        address private wallet3 = 0xc724C3cB9770eCfBb1Dd09751b15842043bc15a5; // YOK
        address private wallet4 = 0x7884A13d537D281568Ad7e9b9821b745eB8f1EDa; // BASS
        address private wallet5 = 0x41B480d81e6E2Af62B42919Db89bd31e9FF60be7; // GEMS
        address private wallet6 = 0x5350303b367FeA34bFb85Fd0da683eA9D8Ebd550; // Sub wallet 1 by KAY
        address private wallet7 = 0x98f70F25d84c1bD0cCC3b45f2Dc5FC7f71b4fa61; // Sub wallet 2 by BASS

    function withdrawMoney() external payable nonReentrant { 

        uint256 _paytoW1 = address(this).balance*14/100 ;
        uint256 _paytoW2 = address(this).balance*14/100 ;
        uint256 _paytoW3 = address(this).balance*14/100 ;
        uint256 _paytoW4 = address(this).balance*14/100 ;
        uint256 _paytoW5 = address(this).balance*14/100 ;
        uint256 _paytoW6 = address(this).balance*15/100 ;
        uint256 _paytoW7 = address(this).balance*15/100 ;

        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));
        require(payable(wallet2).send(_paytoW2));
        require(payable(wallet3).send(_paytoW3));
        require(payable(wallet4).send(_paytoW4));
        require(payable(wallet5).send(_paytoW5));
        require(payable(wallet6).send(_paytoW6));
        require(payable(wallet7).send(_paytoW7));

    }
//------------------------- END Withdraw Money

//-------------------- START Fallback Receive Ether Function
    receive() external payable {
            emit Received(msg.sender, msg.value);
    }
//-------------------- END Fallback Receive Ether Function

}