// SPDX-License-Identifier: MIT
// Create by 0xChrisx

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./ERC721AQueryable.sol";

import "./IERC721ACXCraft.sol";
import "./ERC721ABurnable.sol";

contract NFT is Ownable,
    ERC721A,
    ERC721ABurnable,
    ERC721AQueryable,
    IERC721ACXCraft,
    ReentrancyGuard {

    event Received(address, uint);

    uint256 public collectionSize_ = 40000 ;

    string private baseURI ;

    address[] public L2Contract ;

    IERC721ACXCraft public L0Contract ;
    IERC721ACXCraft private L2;

    struct AddressDetail {
        uint256 InternalBurned ; 
        uint256 ClaimedThis ;
    }
    
    mapping(address => AddressDetail) public _addressDetail ;

    constructor() ERC721A("SilverPass", "SVP") {
    }


    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

//------------- Check NFT Contract that Burned
    // ----------->>>> START 1. BurnUsed
    // Description : BurnUsed ไว้นับจาก Contract Layer 2 ว่าเอาไปใช้เท่าไหร่แล้ว
        
    function setLayer2(address[] memory newAddresses) public onlyOwner {
        // L2Contract = IERC721ACXCraft(_addresses);
        
        // reset to nothing
        for (uint i = 0; i < L2Contract.length; i++) {
            delete L2Contract[i] ;
        }

        // add new data to Layer2 Contract
        for(uint i = 0; i < newAddresses.length; i++) {
            L2Contract[i] = newAddresses[i];
        }
    }
//--------------------------------------
    // BurnedUsed => Read BurnUsed
    function myClaimed(address _sender) external view returns(uint256) {
        // ส่งออกไปว่า ของเราถูกเคลมไปเท่าไหร่
        // myClaim กับ BurnUsed คือ อันเดียวกัน

        return _addressDetail[_sender].ClaimedThis ;
    }
//--------------------------------------
    function ExternalBurnUsed(address _sender) internal view returns (uint) {
        // รวมผลจากทุก External ว่าเขามี myClaimed เท่าไหร่ ส่งให้ MaxCanUse ประมวลผลต่อ เตรียมให้ Layer 2 Contract ไปใช้
        // myClaim กับ BurnUsed คือ อันเดียวกัน

        uint256 sumMyClaimed = 0 ; 
        for(uint i = 0; i < L2Contract.length; i++) {
            
            address _L2Contract = L2Contract[i] ;

            IERC721ACXCraft _L2 = IERC721ACXCraft(_L2Contract);

            sumMyClaimed += _L2.myClaimed(_sender) ;

        }

        return sumMyClaimed ;
    }


    // ----------->>>> END 1. BurnUsed
//---------------------------------------
    // ----------->>>> START 3. Max Can Use
    // Description : เอา ( InternalBurned - BurnUsed ) = MaxCanUse

    function MaxCanUse(address _sender) external view returns(uint) {
        // ส่งออกไปว่า จำนวน Burned จาก Contract นี้ สามารถใช้ได้อีกเท่าไหร่
        return _addressDetail[_sender].InternalBurned - ExternalBurnUsed(_sender) ;
    }

    // ----------->>>> END 3. Max Can Use

    function setLayer0 (address _address) public onlyOwner {
        L0Contract = IERC721ACXCraft(_address) ;
    }
//---------------------------------------
//------------------ BaseURI 
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI (string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

//--------------------- END BaseURI
//--------------------- Set & Change anythings
    
    function setCollectionSize (uint256 newCollectionSize) public onlyOwner {
        collectionSize_ = newCollectionSize ;
    }

//--------------------- END Set & Change anythings
//------------------ Burn FUNCTION
    function burnNFT(uint256 _number) public {
        burn(_number) ;
        _addressDetail[msg.sender].InternalBurned += 1 ;
    }

    function burnNFTs(uint256[] memory _number) public {
        
        for(uint256 i = 0; i < _number.length; i++) {
            uint256 nftNumber = _number[i] ;
            burn(nftNumber) ;
            _addressDetail[msg.sender].InternalBurned += 1 ;

        }

    }
//--------------------- END Burn FUNCTION
//--------------------------------------- Mint
//-------------------- DevMint
    function mintDev(address _to ,uint256 _mintAmount) external onlyOwner {

        require(totalSupply() + _mintAmount <= collectionSize_ , "You can't mint more than collection size");

        _safeMint( _to,_mintAmount);
    }

    // Airdrop same amount (devAirdrop2)
    function devAirdrop(address[] memory _to ,uint256 _mintAmount) external onlyOwner {

        // loop to count total amount to mint to Check in require
        uint256 countTotalAmount = _to.length * _mintAmount;

        // use countTotalAmount to check in require
        require(totalSupply() + countTotalAmount <= collectionSize_ , "You can't mint more than collection size");

        // Loop to mint all of it
        for(uint256 i ; i < _to.length ; i++) {
            _safeMint(_to[i],_mintAmount);
        }
    }
//-------------------- END DevMint
//--------------------------------------------- END Mint
//------------------------- Withdraw Money

        address private wallet1 = 0x009ED1DFB92a970eC3476b4Ca887011EDf1BCF4F;

    function withdrawMoney() external payable nonReentrant { 

        uint256 _paytoW1 = address(this).balance ;
    
        require(address(this).balance > 0, "No ETH left");

        require(payable(wallet1).send(_paytoW1));

    }

//------------------------- END Withdraw Money

//-------------------- START Fallback Receive Ether Function
    receive() external payable {
            emit Received(msg.sender, msg.value);
    }
//-------------------- END Fallback Receive Ether Function
}