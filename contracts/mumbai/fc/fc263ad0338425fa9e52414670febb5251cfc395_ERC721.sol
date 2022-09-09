/**
 *Submitted for verification at polygonscan.com on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC721 {

    event Transfer(address indexed from, address indexed to, uint indexed id);
    event Approval(address indexed owner, address indexed spender, uint indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    mapping(uint => address) internal ownerOfNft;
    mapping(address => uint) internal nftCountOf;
    mapping(uint => address) internal approvals;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    modifier checkAlreadyMinted(uint _nftId){
        require(ownerOfNft[_nftId] == address(0), "this NFT is already minted");
        _;
    }

    modifier checkAlreadyMintedCollection(uint fromNftNumber, uint toNftNumber){
        for(uint i = fromNftNumber; i <= toNftNumber; i++){
            require(ownerOfNft[i] == address(0), "some of these Nfts are already minted");
        }
        _;
    }

    modifier requestSenderIsOwner(uint _nftId){
        require(ownerOfNft[_nftId] == msg.sender, "You are not Owner ( can't burn ) ");
        _;
    }

    modifier ValidateTransfer(address _from, address _to, uint _nftId){
        require(ownerOfNft[_nftId] == _from ,"no Ownership");
        require(_to != address(0),"not correct address");
        require(msg.sender == _from || isApprovedForAll[_from][msg.sender] || msg.sender == approvals[_nftId], " not have authority ");
        _;
    }    

    function mintNFT(uint _nftId) external checkAlreadyMinted(_nftId) {
        address owner = msg.sender;
        nftCountOf[owner]++;
        ownerOfNft[_nftId] = owner;
        emit Transfer(address(0), owner, _nftId);
    }

    function mintNFTsInBulk(uint fromNftNumber, uint toNftNumber) external checkAlreadyMintedCollection(fromNftNumber, toNftNumber) {
        address collectionOwnwer = msg.sender;
        uint totalCollectionNFTs = toNftNumber - fromNftNumber + 1;
        nftCountOf[collectionOwnwer] += totalCollectionNFTs;
        for(uint i = fromNftNumber; i <= toNftNumber; i++){
            ownerOfNft[i] = collectionOwnwer;
        }
        emit Transfer(address(0), collectionOwnwer, totalCollectionNFTs);
    }

    function burnNFT(uint _nftId) requestSenderIsOwner(_nftId) external   {
        address owner = ownerOfNft[_nftId];
        nftCountOf[owner] -= 1;
        delete ownerOfNft[_nftId];
        delete approvals[_nftId];
        emit Transfer(owner, address(0), _nftId);
    }

    function ownerOfNftToken(uint _id) external view returns (address owner) {
        owner = ownerOfNft[_id];
        require(owner != address(0), "no such nft exists");
    }

    function nftCountOfOwner(address _owner) external view returns (uint) {
        require(_owner != address(0), "no such owner exists");
        return nftCountOf[_owner];
    }

    function approve(address _approveAddress, uint256 _nftId) external {
        address owner = ownerOfNft[_nftId];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "not have authority");
        approvals[_nftId] = _approveAddress;
        emit Approval(owner, _approveAddress, _nftId);
    }

    function setApprovalForAll(address _operator, bool _approved) external{
        isApprovedForAll[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint _nftId) external view returns (address operator){
        require(ownerOfNft[_nftId] != address(0), "no such token exists");
        return approvals[_nftId];
    }

     function checkApprovedOrOwner(address _owner, address _operator) external view returns (bool){
        return (_operator == _owner || isApprovedForAll[_owner][_operator]);
    }

    function transferFrom(address _from, address _to, uint _nftId) external ValidateTransfer(_from, _to, _nftId) {
        nftCountOf[_from]--;
        nftCountOf[_to]++;
        ownerOfNft[_nftId] = _to;
        delete approvals[_nftId];
        emit Transfer(_from, _to, _nftId);
    }

}