/**
 *Submitted for verification at polygonscan.com on 2023-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface RealNFT  {
    
    function mintNftByContract(address receiver, string memory tokenURI)  external  returns (uint256);
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
 constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract RealEstate is Ownable {

     struct Property {
        uint256 id;
        address owner;
        string name; // name of the property
        string addr; // address of the property
        bool rented; // rent status of the property
        uint rentInterval; // interval in days for the rent amount
        uint rentAmount; // property rent value
        uint tenantWarning; // tracks the count for warning given to tenant
        uint warningLimit; // threshold limit for warning. Once exceeded tenant can be dismissed.
        uint dueDate; // unix timestamp for the dueDate.
        address tenant; // tenant wallet address
    }

    
    struct LandOwner {
        address owner;
        uint256[] propertyIds;
        mapping (uint256 => Property) properties;
    }

    RealNFT public realNft;

    mapping (address => LandOwner) public landOwners;
    mapping (uint256 => Property) public properties;

    uint256 private propertyCount = 0;
    uint256 public mintFee = 0; // Fee should be in wei
    address payable platformFeeReciever;

    constructor (address _realNft, address payable _platformFeeReciever)  {
        realNft = RealNFT(_realNft);
        platformFeeReciever = _platformFeeReciever;
        mintFee = 10000000000000000 ;// 0.01 ETH
    }

    function addProperty(string memory _uri, string memory _name, string memory _addr, uint256 _rentAmount) public payable returns (uint256) {
        require(msg.value == mintFee, "FEE: You have insufficient balance to pay property listing fee." );
       
        address _owner = msg.sender;

        uint256 propertyId = realNft.mintNftByContract(_owner, _uri);

        Property storage property = landOwners[_owner].properties[propertyId];
        property.id = propertyId;
        property.owner = _owner;
        property.name = _name;       
        property.addr = _addr;
        property.rentAmount = _rentAmount;
        landOwners[_owner].propertyIds.push(propertyId);

        platformFeeReciever.transfer(msg.value);
        return propertyId;
        
    }


    function setFee(uint _fee) public onlyOwner {
        mintFee = _fee;
    }

    function updateNftAddress(address _realNft) public onlyOwner {
       realNft = RealNFT(_realNft);
    }

    function updateFeeAddress(address payable _feeAddress) public onlyOwner {
       platformFeeReciever = _feeAddress;
    }
    
    function getPropertyByIdOfOwner(address _landOwner, uint256 _propertyId) public view returns (Property memory) {
        return landOwners[_landOwner].properties[_propertyId];
    }

     function getPropertyIdsOfOwner(address _landOwner) public view returns (uint256[] memory) {
        return landOwners[_landOwner].propertyIds;
    }
    
}