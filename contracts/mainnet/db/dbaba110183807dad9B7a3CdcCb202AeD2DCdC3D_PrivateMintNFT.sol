/**
 *Submitted for verification at polygonscan.com on 2023-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC721 {
  function mintWithPermit(address account) external returns (bool);
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

contract PrivateMintNFT is Context, Ownable {

    struct Offer {
      address admin;
      address offerfor;
      uint256 price;
      uint256 start;
      uint256 ended;
      bool active;
      bool minted;
    }

    uint256 public totalOffer;

    mapping(uint256 => Offer) public offer;

    address public nftContract;

    mapping(address => bool) public permission;
    modifier onlyPermission() {
        require(permission[msg.sender], "!PERMISSION");
        _;
    }

    constructor(address _nftContract) {
      nftContract = _nftContract;
    }

    function flagePermission(address _account,bool _flag) public onlyOwner returns (bool) {
        permission[_account] = _flag;
        return true;
    }

    function changeNFTContract(address addr) public onlyOwner returns (bool) {
      nftContract = addr;
      return true;
    }

    function newOffer(address forAddress,uint256 offerPrice,uint256[] memory period) public onlyPermission returns (bool) {
        totalOffer += 1;
        offer[totalOffer].admin = msg.sender;
        offer[totalOffer].offerfor = forAddress;
        offer[totalOffer].price = offerPrice;
        offer[totalOffer].active = true;
        if(period.length==1){
            offer[totalOffer].start = block.timestamp;
            offer[totalOffer].ended = block.timestamp + period[0];
        }else{
            offer[totalOffer].start = period[0];
            offer[totalOffer].ended = period[1];
        }
        return true;
    }

    function revokeOffer(uint256 offerid) public onlyPermission returns (bool) {
        offer[offerid].active = false;
        return true;
    }

    function offerMint(uint256 offerid) public payable returns (bool) {
        require(msg.sender==offer[offerid].offerfor,"Not Allow With Permit");
        require(msg.value>=offer[offerid].price,"Insufficient ETH For Mint");
        require(block.timestamp>offer[offerid].start,"This Private Mint Was Out Of Date");
        require(block.timestamp<offer[offerid].ended,"This Private Mint Was Out Of Date");
        require(offer[offerid].active,"This Offer Id Was Not Actived");
        require(!offer[offerid].minted,"This Offer Id Was Minted");
        offer[offerid].minted = true;
        (bool success,) = owner().call{ value: msg.value }("");
        require(success, "!fail to send eth");
        IERC721(nftContract).mintWithPermit(msg.sender);
        return true;
    }
}