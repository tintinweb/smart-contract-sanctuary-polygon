// SPDX-License-Identifier: MIT
// Create by 0xChrisx - v.0.8.0

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";


contract Chrisx is Ownable, ERC721A, ReentrancyGuard {

    event Received(address, uint);

    uint256 public publicMintActive = 0 ;

    uint256 public mintPrice = 0.005 ether;
    uint256 public collectionSize_ = 999 ;
    uint256 public maxPerAddress = 3 ;
    uint256 public amountForDev = 100 ;

    uint256 public devMinted ;

    string private baseURI = "url" ;



    constructor() ERC721A("Chirsx", "CX", maxPerAddress , collectionSize_ ) {

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

    function setAmountForDev (uint newAmountForDev) public onlyOwner {
        amountForDev = newAmountForDev ;
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

        require(publicMintActive >= 1, "public sale has not begun yet");
        require(totalSupply() + _mintAmount <= collectionSize_  , "reached max supply"); // must less than collction size
        require(numberMinted(msg.sender) + _mintAmount <= maxPerAddress, "can not mint this many"); // check max mint PerAddress ?
        require(msg.value >= mintPrice * _mintAmount, "ETH amount is not sufficient");

        _safeMint(msg.sender, _mintAmount);
    }

    function numberMinted(address owner) public view returns (uint256) { // check number Minted of that address จำนวนที่มิ้นไปแล้ว ใน address นั้น
        return _numberMinted(owner);
    }
//-------------------- END PublicMint
//-------------------- DevMint
    function devMint(address _to ,uint _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size");
        require(_mintAmount + devMinted <= amountForDev , "You can't mint more than amountForDev");

        _safeMint( _to,_mintAmount);
        devMinted += _mintAmount ;
    }
//-------------------- END DevMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0x75963B63D551Fc3723F3Ca40bc43c45201b35f33; 
        address private wallet2 = 0x899005A4ecddcd5a880744229DA625c1b6124737; 


    function withdrawMoney() external payable onlyOwner nonReentrant { 

        uint256 _paytoW1 = address(this).balance*80/100 ;
        uint256 _paytoW2 = address(this).balance*20/100 ;

        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));
        require(payable(wallet2).send(_paytoW2));


    }
//------------------------- END Withdraw Money

//-------------------- START Fallback Receive Ether Function
    receive() external payable {
            emit Received(msg.sender, msg.value);
    }
//-------------------- END Fallback Receive Ether Function

}