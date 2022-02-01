// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC20.sol';
import './IERC721.sol';
contract JeroCoin is ERC20 {
    address private _contractOwner;
    bool private _isOwnershipTransfered = false;
    //Reit Lion
    IERC721 private _reitLion ;
    mapping(uint256 => bool) private _isClaimedRL;
    //Reit Lioness
    IERC721 private _reitLioness ;
    mapping(uint256 => bool) private _isClaimedRLS;
    //Reit Angel
    IERC721 private _reitAngel ;
    mapping(uint256 => bool) private _isClaimedRA;
    //Constructor
    constructor() ERC20("JeroCoin","JERO") {
        _contractOwner = msg.sender;
        _mint(address(this),21109e20 );
        _mint(msg.sender,75409108e18);
    }
    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == _contractOwner, "Ownable: caller is not the owner");
        _;
    }
    //Claim function for ReitLion Buyers
    function claimJeroCoin(uint256 tokenId,uint8 nftParam)external{
        //ReitLion
        if(nftParam == 0){
            require(msg.sender == _reitLion.ownerOf(tokenId),"You are not the RELI owner");
            require(! _isClaimedRL[tokenId],"Already claimed for RELI token");
            _transfer(address(this),msg.sender, 1e20);//100Ether
            _isClaimedRL[tokenId] = true;
        }
        //ReitLioness
        else if(nftParam == 1){
            require(msg.sender == _reitLioness.ownerOf(tokenId),"You are not the RELS owner");
            require(! _isClaimedRLS[tokenId],"Already claimed for RELS token");
            _transfer(address(this),msg.sender, 1e20);//100Ether
            _isClaimedRLS[tokenId] = true;
        }
        //ReitAngel
        else if(nftParam == 2){
            require(msg.sender == _reitAngel.ownerOf(tokenId),"You are not the RELA owner");
            require(! _isClaimedRA[tokenId],"Already claimed for RELA token");
            _transfer(address(this),msg.sender, 1e20);//100Ether
            _isClaimedRA[tokenId] = true;
        }
    }
    //Set NFT contract addresses
    function setNFTAdrs(uint8 nftParam,address adrs)external onlyOwner{
        require(adrs != address(0),"Address zero");
        //ReitLion
        if(nftParam == 0){
            _reitLion = IERC721(adrs);
        }//ReitLioness
        else if(nftParam == 1){
            _reitLioness = IERC721(adrs);
        }//ReitAngel
        else if(nftParam == 1){
            _reitAngel = IERC721(adrs);
        }

    }
    //transfer ownership
    function transferOwnership(address newOwner)external onlyOwner{
        require(newOwner != address(0),"Address zero");
        require(!_isOwnershipTransfered,"Already transfered" );
        _contractOwner = newOwner;
        _isOwnershipTransfered = true;
    }
}