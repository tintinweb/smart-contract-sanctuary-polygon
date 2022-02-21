/**
 *Submitted for verification at polygonscan.com on 2022-02-21
*/

// File: @0xcert/ethereum-utils-contracts/src/contracts/permission/ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev The contract has an owner address, and provides basic authorization control which
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable
{

  /**
   * @dev Error constants.
   */
  string constant NOT_OWNER = "018001";
  string constant ZERO_ADDRESS_NOT_ALLOWED = "018002";

  /**
   * @dev Address of the owner.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner()
  {
    require(msg.sender == owner, NOT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    public
    virtual
    onlyOwner
  {
    require(_newOwner != address(0), ZERO_ADDRESS_NOT_ALLOWED);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

// File: contracts/ArianeeIdentity/ArianeeIdentity.sol

pragma solidity 0.8.0;

contract ArianeeIdentity is
Ownable
{

  /**
   * @dev A descriptive name.
   */
  string internal name;

  /**
   * @dev An abbreviated name.
   */
  string internal symbol;

  /**
   * @dev Mapping from address to approvedList boolean
   */
  mapping(address => bool) internal approvedList;

  /**
   * @dev Mapping from address to URI.
   */
  mapping(address => string) internal addressToUri;

  /**
   * @dev Mapping from address to imprint.
   */
  mapping(address => bytes32) internal addressToImprint;

  /**
   * @dev Mapping from address to URI.
   */
  mapping(address => string) internal addressToWaitingUri;

  /**
   * @dev Mapping from address to imprint.
   */
  mapping(address => bytes32) internal addressToWaitingImprint;

  /**
   * @dev Mapping from address to compromise date.
   */
  mapping(address => uint256) internal compromiseDate;

  /**
   * @dev Mapping from addressId to address.
   */
  mapping(bytes3=>address) internal addressListing;
  
  address public bouncerAddress;
  address public validatorAddress;
   
  /**
   * @dev This emits when a new address is approved.
   */
  event AddressApprovedAdded(address _newIdentity, bytes3 _addressId);
   
  /**
   * @dev This emits when an address is removed from approvedList.
   */
  event AddressApprovedRemoved(address _newIdentity);
   
  /**
   * @dev This emits when a new address is approved.
   */
  event URIUpdated(address _identity, string _uri, bytes32 _imprint);

  /**
   * @dev This emits when an identity change its URI and Imprint.
   */
  event URIValidate(address _identity, string _uri, bytes32 _imprint);

  /**
   * @dev This emits when an identity change is validated by the contract owner.
   */
  event IdentityCompromised(address _identity, uint256 _compromiseDate);
  
  /**
   * @dev This emits when a new address is set.
   */
  event SetAddress(string _addressType, address _newAddress);
   
  /**
    * @dev Initialize this contract. Acts as a constructor
    * @param _newBouncerAddress Address of the bouncer.
    * @param _newValidatorAddress Address of the validator.
    */
  constructor(address _newBouncerAddress, address _newValidatorAddress) {
    name = "Arianee Identity";
    symbol = "AriaID";
    updateBouncerAddress(_newBouncerAddress);
    updateValidatorAddress(_newValidatorAddress);
  }
  
  /**
   * @dev Add a new address to approvedList
   * @notice allow an address to create/update his URI and Imprint.
   * @notice Can only be called by the bouncer.
   * @param _newIdentity Address to authorize.
   * @return Id for address in bytes3.
   */
  function addAddressToApprovedList(address _newIdentity) external returns (bytes3) {
    require(msg.sender == bouncerAddress);
    approvedList[_newIdentity] = true;
    
    bytes memory _bytesAddress = abi.encodePacked(_newIdentity);
    bytes3 _addressId = _convertBytesToBytes3(_bytesAddress);
    
    addressListing[_addressId] = _newIdentity;
    
    emit AddressApprovedAdded(_newIdentity, _addressId);
    
    return _addressId;
  }
  
  /**
   * @dev Remove an address from approvedList.
   * @notice Can only be called by the bouncer.
   * @param _identity to delete from the approvedList.
   */
  function removeAddressFromApprovedList(address _identity) external {
    require(msg.sender == bouncerAddress);
    approvedList[_identity] = false;
    emit AddressApprovedRemoved(_identity);
  }

  /**
   * @dev Update URI and Imprint of an address.
   * @param _uri URI to update.
   * @param _imprint Imprint to update
   */
  function updateInformations(string calldata _uri, bytes32 _imprint) external isApproved(msg.sender) {
    addressToWaitingUri[msg.sender] = _uri;
    addressToWaitingImprint[msg.sender] = _imprint;
    
    emit URIUpdated(msg.sender, _uri, _imprint);
  }
  
  
  /**
   * @dev Validate waiting informations provided by the identity.
   * @notice Can only be called by the validator.
   * @param _uriToValidate uri to be validated.
   * @param _identity address to be validated.
   */
  function validateInformation(address _identity, string calldata _uriToValidate, bytes32 _imprintToValidate) external {
    require(msg.sender == validatorAddress);
    require(addressToWaitingImprint[_identity] == _imprintToValidate);
    require(keccak256(abi.encodePacked(addressToWaitingUri[_identity])) == keccak256(abi.encodePacked(_uriToValidate)));
    
    addressToUri[_identity] = addressToWaitingUri[_identity];
    addressToImprint[_identity] =  addressToWaitingImprint[_identity];

    emit URIValidate(_identity, addressToWaitingUri[_identity], addressToWaitingImprint[_identity]);

    delete addressToWaitingUri[_identity];
    delete addressToWaitingImprint[_identity];
  }

  /**
   * @notice Add a compromise date to an identity.
   * @dev Can only be called by the bouncer.
   * @param _identity address compromise
   * @param _compromiseDate compromise date
   */
  function updateCompromiseDate(address _identity, uint256 _compromiseDate) external {
    require(msg.sender == bouncerAddress);
    compromiseDate[_identity] = _compromiseDate;
    emit IdentityCompromised(_identity, _compromiseDate);
  }
  
  /**
   * @notice Check if an address is approved.
   * @param _identity address of the identity.
   * @return _isApproved true if approved.
   */
  function addressIsApproved(address _identity) external view returns (bool _isApproved) {
      _isApproved = approvedList[_identity];
  }
  
  /**
   * @notice The uri of a given identity.
   * @param _identity address of the identity.
   * @return _uri the uri.
   */
  function addressURI(address _identity) external view returns (string memory _uri) {
      _uri = addressToUri[_identity];
  }
  
  /**
   * @notice The imprint for a given identity.
   * @param _identity address of the identity.
   * @return _imprint true if approved.
   */
  function addressImprint(address _identity) external view returns (bytes32 _imprint) {
      _imprint = addressToImprint[_identity];
  }

  /**
   * @notice The waiting uri for a given identity.
   * @param _identity address of the identity.
   * @return _waitingUri the waiting Uri.
   */
  function waitingURI(address _identity) external view returns(string memory _waitingUri) {
      _waitingUri = addressToWaitingUri[_identity];
  }
  
  /**
   * @notice The waiting imprint for a given identity.
   * @param _identity address of the identity.
   * @return _waitingImprint the waiting imprint.
   */
  function waitingImprint(address _identity) external view returns(bytes32 _waitingImprint) {
      _waitingImprint = addressToWaitingImprint[_identity];
  }
  
  /**
   * @notice The compromise date for a given identity.
   * @param _identity address of the identity.
   * @return _compromiseDate the waiting Uri.
   */
  function compromiseIdentityDate(address _identity) external view returns(uint256 _compromiseDate) {
      _compromiseDate = compromiseDate[_identity];
  }

  /**
   * @notice The address for a given short id.
   * @param _id short id of the identity
   * @return _identity the address of the identity.
   */
  function addressFromId(bytes3 _id) external view returns(address _identity) {
      _identity = addressListing[_id];
  }
  
  /**
   * @dev Change address of the bouncer.
   * @param _newBouncerAddress new address of the bouncer.
   */
  function updateBouncerAddress(address _newBouncerAddress) public onlyOwner() {
    bouncerAddress = _newBouncerAddress;
    emit SetAddress("bouncerAddress", _newBouncerAddress);
  }
  
  /**
   * @dev Change address of the validator.
   * @param _newValidatorAddress new address of the validator.
   */
  function updateValidatorAddress(address _newValidatorAddress) public onlyOwner() {
    validatorAddress = _newValidatorAddress;
    emit SetAddress("validatorAddress", _newValidatorAddress);
  }
  
  /**
   * @dev Check if an address is approved.
   * @param _identity The address to check.
   */
  modifier isApproved(address _identity) {
    require(approvedList[_identity]);
    _;
  }

   /**
    * @dev Convert a bytes in bytes3.
    * @param _inBytes input bytes.
    * @return outBytes3 output bytes3.
    */
  function _convertBytesToBytes3(bytes memory _inBytes) internal pure returns (bytes3 outBytes3) {
    if (_inBytes.length == 0) {
        return 0x0;
    }

    assembly {
        outBytes3 := mload(add(_inBytes, 32))
    }
  }

}