/**
 *Submitted for verification at polygonscan.com on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC721 {
  function ownerOf(uint256 tokenid) external view returns (address);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
      return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    constructor() {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require( _owner == _msgSender());
      _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
      emit OwnershipTransferred(_owner, account);
      _owner = account;
    }
}

contract RedeemNFT is Context, Ownable {

    struct User {
      uint256[] hold;
    }

    struct Redeem {
      address sender;
      uint256 tokenid;
      uint256 state;
      uint256 blockstamp;
      string data;
    }

    uint256 public totalRedeem;

    mapping(address => User) user;
    mapping(uint256 => Redeem) public redeem;
    
    address public nftContract = 0x49C6E466E9551b42617f58DadDE1d95cc42c7281;

    mapping(uint256 => uint256) public nftCurrentState;

    mapping(address => bool) public permission;
    modifier onlyPermission() {
        require(permission[msg.sender], "!PERMISSION");
        _;
    }

    constructor() {}

    function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
        permission[_account] = _flag;
        return true;
    }

    function getUserHoldTx(address addr) public view returns (uint256[] memory) {
      return user[addr].hold;
    }

    function changeNFTContract(address addr) public onlyOwner returns (bool) {
      nftContract = addr;
      return true;
    }

    function requestRedeemFromUser(uint256 tokenid,string memory data) public returns (bool) {
      require(IERC721(nftContract).ownerOf(tokenid)==msg.sender,"Have Not Owner Of TokenId");
      require(nftCurrentState[tokenid]==0,"Nft State Request Error");
      totalRedeem += 1;
      nftCurrentState[tokenid] = 1;
      updateRedeemData(totalRedeem,msg.sender,tokenid,1,block.timestamp,data);
      user[msg.sender].hold.push(totalRedeem);
      return true;
    }

    function updateRedeemDataWithPermit(uint256 id,address sender,uint256 tokenid,uint256 state,uint256 blockstamp,string memory data) public onlyPermission returns (bool) {
      updateRedeemData(id,sender,tokenid,state,blockstamp,data);
      return true;
    }

    function updateRedeemData(uint256 id,address sender,uint256 tokenid,uint256 state,uint256 blockstamp,string memory data) internal {
      redeem[id].sender = sender;
      redeem[id].tokenid = tokenid;
      redeem[id].state = state;
      redeem[id].blockstamp = blockstamp;
      redeem[id].data = data;
    }
}