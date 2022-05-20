/**
 *Submitted for verification at polygonscan.com on 2022-05-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IArtFluenceNFT721{
     function createCollection721(string memory _name ,string memory _symbol,string memory _uri,uint expiry,address owner,address payable _royaltyAddress,uint _royalFee)external returns(address);
}

interface IArtFluenceNFT1155{
     function createCollection1155(string memory _uri,uint expiry,address owner,address payable _royaltyAddress,uint _royalFee)external returns(address);
}

contract ArtFluenceNFTFactory {


    address public signer;
    address public owner;
    uint public currentID = 1;

    struct collectionDetails{
        uint id;
        address user;
        address art721;
        address art1155;
        address royaltyAddress;
        uint royaltyFee;
        string name;
        string symbol;
        string uri;

    }

    IArtFluenceNFT721 public artFluenceNFT721;
    IArtFluenceNFT1155 public artFluenceNFT1155;

    mapping(uint => mapping(address => collectionDetails)) public collections;
    mapping(address => uint[])public userids;

    event create(uint indexed _id, address _owner , address indexed _nft721Address,address indexed _nft1155address);

    constructor(address _signer,IArtFluenceNFT721 _artFluenceNFT721,IArtFluenceNFT1155 _artFluenceNFT1155){
        signer = _signer;
        owner = msg.sender;
        artFluenceNFT721 = _artFluenceNFT721;
        artFluenceNFT1155 = _artFluenceNFT1155;
    }

    modifier _onlyOwner() {
        require(owner == msg.sender, "ArtFluenceNFTFactory: caller is not the owner");
        _;
    } 

    function updateSigner(address _signer)public _onlyOwner{
        require(_signer != address(0),"ArtFluenceNFTFactory:Invalid Address");
        signer = _signer;
    }

    function transferOwnerShip(address _owner)public _onlyOwner{
        require(_owner != address(0),"ArtFluenceNFTFactory:Invalid Address");
        owner = _owner;
    }

    struct Sig {
        /* v parameter */
        uint8 v;
        /* r parameter */
        bytes32 r;
        /* s parameter */
        bytes32 s;
    }


    function createCollection(string memory _name ,string memory _symbol,string memory _uri,uint expiry,address payable _royaltyAddress,uint _royalFee,Sig memory sig)public{
        require(bytes(_name).length > 0, "ArtFluenceNFTFactory : name must not be empty");
        require(bytes(_symbol).length > 0, "ArtFluenceNFTFactory : symbol must not be empty");
        require(expiry > block.timestamp,"Expired");
        validateSignature(msg.sender,_name,_symbol,expiry,_royaltyAddress,_royalFee,sig);

        address _art721 = artFluenceNFT721.createCollection721(_name,_symbol,_uri,expiry,msg.sender,_royaltyAddress,_royalFee);
        address _art1155 = artFluenceNFT1155.createCollection1155(_uri,expiry,msg.sender,_royaltyAddress,_royalFee);

        collectionDetails storage collection = collections[currentID][msg.sender];
        collection.id = currentID;
        collection.user = msg.sender;
        collection.art721 = _art721;
        collection.art1155 = _art1155;
        collection.royaltyAddress = _royaltyAddress;
        collection.royaltyFee = _royalFee;
        collection.name = _name;
        collection.symbol = _symbol;
        collection.uri = _uri;

        userids[msg.sender].push(currentID);

        emit create(currentID,msg.sender,address(_art721),_art1155);
        currentID++;

    }

    function validateSignature(address _to,string memory _name,string memory _symbol,uint expiry,address _royaltyAddress,uint _royalFee,Sig memory sig) private {
         bytes32 hash = prepareHash(_to,address(this),_name,_symbol,expiry,_royaltyAddress,_royalFee);
         require(ecrecover(hash, sig.v, sig.r, sig.s) == signer , "Invalid Signature");
    }

    function prepareHash(address _to,address _contract,string memory _name,string memory _symbol,uint expiry,address _royaltyAddress,uint _royalFee)public  pure returns(bytes32){
        bytes32 hash = keccak256(abi.encodePacked(_to,_contract,_name,_symbol,expiry,_royaltyAddress,_royalFee));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}