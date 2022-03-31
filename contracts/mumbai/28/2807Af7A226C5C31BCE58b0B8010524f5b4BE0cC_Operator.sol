// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.11;

interface IBaseNFT1155 {

    function setRoyaltyFee(address receiver, uint96 _royalty) external;

    function mint(address creator, string memory uri, uint256 supplys) external returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

}

contract Operator {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event MinterAdded(address indexed minter);

    event MinterRemoved(address indexed minter);

    event CelebrityAdminAdded(address indexed admin);

    event CelebrityAdminRemoved(address indexed admin);

    address public owner;
    mapping(address => bool) private celebrityAdmin;
    mapping(address => bool) private minters;

    constructor () {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMinters() {
        require(minters[msg.sender], "Minter: caller doesn't have minter Role");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        return true;
    }

    function addCelebrityAdmin(address _celebrityAdmin) public onlyOwner returns(bool) {
        require(!celebrityAdmin[_celebrityAdmin], "Celebrity Admin already exist");
        celebrityAdmin[_celebrityAdmin] = true;
        emit CelebrityAdminAdded(_celebrityAdmin);
        return true;
    }

    function removeCelebrityAdmin(address _celebrityAdmin) public onlyOwner returns(bool) {
        require(celebrityAdmin[_celebrityAdmin], "Celebrity Admin does not exist");
        celebrityAdmin[_celebrityAdmin] = false;
        emit CelebrityAdminRemoved(_celebrityAdmin);
        return true;
    }
    
    function isCelebrityAdmin(address _celebrityAdmin) view public returns(bool) {
        return celebrityAdmin[_celebrityAdmin];
    }
    
    function addMinter(address _minter) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can add minter");
        require(!minters[_minter], "Minter already exist");
        minters[_minter] = true;
        emit MinterAdded(_minter);
        return true;
    }
    
    function removeMinter(address _minter) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Only celebrity admin can remove minter");
        require(minters[_minter], "Minter does not exist");
        minters[_minter] = false;
        emit MinterRemoved(_minter);
        return true;
    }


    function mint1155(address nftAddress, address creator, string memory tokenURI, uint256 supply) public onlyMinters returns(bool) {
        IBaseNFT1155(nftAddress).mint(creator, tokenURI, supply);
        return true;
    }

    function safeTransfer1155(address nftAddress, address from, uint256 tokenId, address receiver, uint256 amount) public onlyMinters returns(bool) {
        IBaseNFT1155(nftAddress).safeTransferFrom(from, receiver, tokenId, amount, "");
        return true;
    }

    function setRoyaltyFee(address nftAddress, address receiver, uint96 royaltyFee) public returns(bool) {
        require(celebrityAdmin[msg.sender], "Operator: caller doesn't have role");       
        IBaseNFT1155(nftAddress).setRoyaltyFee(receiver, royaltyFee);
        return true;
    }

    function isMinter(address _minter) public view returns(bool) {
        return minters[_minter];
    }
    
}