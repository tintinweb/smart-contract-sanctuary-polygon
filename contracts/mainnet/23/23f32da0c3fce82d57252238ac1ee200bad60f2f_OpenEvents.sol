/**
 *Submitted for verification at polygonscan.com on 2022-02-20
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File openzeppelin-solidity/contracts/introspection/[email protected]
// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]



/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256('balanceOf(address)')) ^
   *   bytes4(keccak256('ownerOf(uint256)')) ^
   *   bytes4(keccak256('approve(address,uint256)')) ^
   *   bytes4(keccak256('getApproved(uint256)')) ^
   *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
   *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
   *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
   *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
   */

  bytes4 internal constant InterfaceId_ERC721Exists = 0x4f558e79;
  /*
   * 0x4f558e79 ===
   *   bytes4(keccak256('exists(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256('totalSupply()')) ^
   *   bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) ^
   *   bytes4(keccak256('tokenByIndex(uint256)'))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256('name()')) ^
   *   bytes4(keccak256('symbol()')) ^
   *   bytes4(keccak256('tokenURI(uint256)'))
   */

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]



/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]




/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
   * @param _data Additional data with no specified format
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4);
}


// File openzeppelin-solidity/contracts/math/[email protected]




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


// File openzeppelin-solidity/contracts/[email protected]




/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address _addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_addr) }
    return size > 0;
  }

}


// File openzeppelin-solidity/contracts/introspection/[email protected]



/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256('supportsInterface(bytes4)'))
   */

  /**
   * @dev a mapping of interface id to whether or not it's supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]







/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

  /**
   * @dev Gets the owner of the specified token ID
   * @param _tokenId uint256 ID of the token to query the owner of
   * @return owner address currently marked as the owner of the given token ID
   */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

  /**
   * @dev Sets or unsets the approval of a given operator
   * An operator is allowed to transfer all tokens of the sender on their behalf
   * @param _to operator address to set the approval
   * @param _approved representing the status of the approval to be set
   */
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

  /**
   * @dev Transfers the ownership of a given token ID to another address
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
  */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
   * @param _from current owner of the token
   * @param _to address to receive the ownership of the given token ID
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes data to send along with a safe transfer check
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
    // Disable solium check because of
    // https://github.com/duaraghav8/Solium/issues/175
    // solium-disable-next-line operator-whitespace
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0), "bad address");
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}


// File openzeppelin-solidity/contracts/token/ERC721/[email protected]





/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  // Token name
  string internal name_;

  // Token symbol
  string internal symbol_;

  // Mapping from owner to list of owned token IDs
  mapping(address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    // To prevent a gap in the array, we store the last token in the index of the token to delete, and
    // then delete the last slot.
    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    // This also deletes the contents at the last position of the array
    ownedTokens[_from].length--;

    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

  /**
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
   * @param _to address the beneficiary that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

    // Reorg all tokens array
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}


// File contracts/OpenTicket.sol




/**
 * @title OpenTicket
 * @dev It is an implementation of ERC721Token that provides ability to view information about tickets.
 */
contract OpenTicket is
    ERC721Token("Jet Gang Benefit Concert Series NFTicket", "JGBT")
{
    struct Ticket {
        uint256 event_id;
        uint256 vip;
        uint256 seat;
        string image;
    }

    mapping(address => mapping(uint256 => uint256)) public ownedEventTickets;

    mapping(uint256 => bool) internal ticketValidity;

    Ticket[] internal tickets;

    /**
     * @dev Throws if ticket is not valid.
     * @param _ticketId - ID of event.
     */
    modifier validTicket(uint256 _ticketId) {
        require(ticketValidity[_ticketId], "Ticket is not valid");
        _;
    }

    /**
     * @dev Function to show all tickets of the specified address.
     * @param _owner - The address to query the tickets of.
     * @return uint[] - Array of tickets ID.
     */
    function ticketsOf(address _owner) public view returns (uint256[] memory) {
        return ownedTokens[_owner];
    }

    /**
     * @dev Function to show balance of all tickets for specified event and address.
     * @param _owner - The address to query the event ticket balance of.
     * @param event_id - The event ID to query for owner ticket balance.
     * @return uint - Owner event ticket balance.
     */
    function eventTicketBalanceOf(address _owner, uint256 event_id)
        public
        view
        returns (uint256)
    {
        return ownedEventTickets[_owner][event_id];
    }

    /**
     * @dev Function to show ticket information.
     * @param _id - Ticket ID.
     * @return uint - Event ID.
     * @return uint - Ticket seat.
     * @return bool - Ticket validity.
     * @return string - Ticket image IPFS URL.
     */
    function getTicket(uint256 _id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool,
            string memory
        )
    {
        require(_id < tickets.length);
        Ticket memory _ticket = tickets[_id];
        return (
            _ticket.event_id,
            _ticket.seat,
            _ticket.vip,
            ticketValidity[_id],
            _ticket.image
        );
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to - representing the new owner of the given token ID
     * @param _tokenId - ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 _eventId = tickets[_tokenId].event_id;
        ownedEventTickets[_to][_eventId] += 1;
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from - representing the previous owner of the given token ID
     * @param _tokenId - ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);
        uint256 _eventId = tickets[_tokenId].event_id;
        ownedEventTickets[_from][_eventId] -= 1;
    }
}


// File openzeppelin-solidity/contracts/token/ERC20/[email protected]




/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


// File openzeppelin-solidity/contracts/token/ERC20/[email protected]



/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


// File openzeppelin-solidity/contracts/ownership/[email protected]




/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


// File openzeppelin-solidity/contracts/lifecycle/[email protected]



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused, "Paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}


// File contracts/OpenEvents.sol








/**
 * @title OpenEvents
 * @dev It is a main contract that provides ability to create events, view information about events and buy tickets.
 */
contract OpenEvents is Ownable, OpenTicket, Pausable {
    using SafeMath for uint256;

    struct OpenEvent {
        address owner;
        string name;
        uint256 time;
        bool token;
        bool limited;
        uint256 price;
        uint256 seats;
        uint256 sold;
        bool vipAvailable;
        string ipfs;
    }

    struct VIPSettings {
        uint256 price;
        uint256 seats;
        uint256 sold;
        bool bottleService;
        bool exclusive;
    }

    OpenEvent[] private openEvents;

    // Mapping from owner to list of owned events IDs.
    mapping(address => uint256[]) private ownedEvents;

    mapping(uint256 => VIPSettings[]) private eventVIPSettings;

    // mapping(uint256 => mapping(uint256 => uint256))
    // private eventIdToVIPIdToEventVIPSettingsIndex;

    mapping(address => uint256) internal adminEvents;

    mapping(address => mapping(uint256 => uint256)) internal promoterEventComps;

    mapping(uint256 => uint256) public vipTickets;

    uint256 public latestEvent;
    event CreatedEvent(address indexed owner, uint256 eventId);
    event CreatedVIPPackage(uint256 eventId, uint256 vipId);
    event SoldTicket(
        address indexed buyer,
        uint256 indexed eventId,
        uint256 ticketId,
        uint256 vip
    );
    event RedeemedTicket(
        uint256 indexed eventId,
        uint256 ticketId,
        uint256 vip
    );

    // event MintedTicket(address indexed buyer, uint indexed eventId, uint ticketId, bool vip);

    /**
     *	General TODOs
     *	- Add uint guestListSupply to OpenEvent struct.
     *	- Update createEvent params.
     *	* Add promoterEventTickets mapping(address => mapping(uint => uint)). Respresenting # of guest tix a promoter can give out.
     * 	* Add eventPromoterHasNComps modifier.
     *	- Add batchRedeem and ability to read user event ticket balance before initiating variable quantity redeem in second step.
     *	  with intuitive interface and resposnive design.
     *	- Add purchase modals w/ ticket options (art work, vip settings, contact info, email opt-in).
     *	- CRM.
     *	- Email list.
     *	/ Rename SoldTicket event.
     *	- Rename OpenEvent.seats field.
     *	X Move ticket supply related require statements, using OpenEvent.seats field, to modifier seatsAvailable.
     *	- Design functionality to support assigned seating.
     *	- Design open-access customer ticketing platform and revenue model.
     *	- Resale royalties for vendor bulk orders.
     **/

    /**
     *	URGENT/IMPORTANT TODOs
     *	- Replace existing admin frontend with dapp hosted at https://admin.jetgangbenefit.com/
     *	* Add uint vipPrice and vipSold to OpenEvent struct.
     *	* Add uint vipAvailable, vipTicketSupply, to OpenEvent struct.
     *	X Add vipAvailable modifier.
     *	* Update createEvent params.
     *	* Add bool vip to OpenTicket struct.
     *	* Update buyTicket and grantTicket with param bool _vip and related control flow for utilizing vipPrice from
     *	  openEvents[_eventId].
     *	* Update redeemTicket to return true if vip, false if not.
     *	* Update getEvent and getTicket accordingly.
     *	- Accept additional donation.
     *	- Add setters for OpenEvent struct.
     *	- Update admin frontend w/ ability to read redeemTicket ret value beyond the existing alert/toast indicating success.
     **/

    constructor() public {}

    /**
     * @dev Throws is address is not event owner.
     * @param _eventId - ID of event.
     **/
    modifier onlyEventOwner(uint256 _eventId) {
        require(msg.sender == openEvents[_eventId].owner);
        _;
    }

    /**
     * @dev Throws if address is not event admin.
     * @param _admin - Address of admin.
     * @param _eventId - ID of event.
     */
    modifier onlyEventAdmin(address _admin, uint256 _eventId) {
        require(adminEvents[_admin] == _eventId);
        // "You must be event an admin."
        _;
    }

    /**
     * @dev Throws if address is not event admin.
     * @param _promoter - Address of admin.
     * @param _eventId - ID of event.
     * @param _qty - Number of comps required.
     */
    modifier eventPromoterHasNComps(
        address _promoter,
        uint256 _eventId,
        uint256 _qty
    ) {
        require(promoterEventComps[_promoter][_eventId] > _qty);
        // "You must be an event promoter and have sufficient comps available."
        _;
    }

    /**
     * @dev Throws if events time is in the past.
     * @param _time - Time of event.
     */
    modifier goodTime(uint256 _time) {
        require(_time > now, "Bad time");
        _;
    }

    /**
     * @dev Throws if event does not exist.
     * @param _eventId - Event ID.
     */
    modifier eventExist(uint256 _eventId) {
        require(_eventId < openEvents.length, "Event doesn't exist");
        _;
    }

    modifier eventVIPExists(uint256 _eventId, uint256 _vipId) {
        require(
            eventVIPSettings[_eventId].length.sub(1) >= _vipId,
            "VIP does not exist."
        );
        _;
    }

    // uint256 _qty
    //  * @param _qty - Quantity of VIP tickets to confirm availability of.

    /**
     * @dev Throws if there are not enough VIP tickets remaining in vipTicketSupply for a given event.
     * @param _eventId - ID of the event to validate VIP ticket supply for.
     * @return uint - Number of remaining VIP tickets.
     **/
    function vipRemaining(uint256 _eventId, uint256 _vipId)
        public
        view
        returns (uint256)
    {
        VIPSettings memory _vipSettings = eventVIPSettings[_eventId][_vipId];
        return _vipSettings.seats.sub(_vipSettings.sold);
    }

    /**
     * @dev Function creates the event.
     * @param _name - The name of the event.
     * @param _time - The time of the event. Should be in the future.
     * @param _token - If true the price will be in tokens, else the price will be in ethereum.
     * @param _limited - If true event has limited seats.
     * @param _price - The ticket price.
     * @param _seats - If event has limited seats, says how much tickets can be sold.
     * @param _vipAvailable - If true event has vip available.
     * @param _ipfs - The IPFS hash containing additional information about the event.
     * @notice Requires that the events time is in the future.
     * @notice Requires that the contract is not paused.
     */
    function createEvent(
        string _name,
        uint256 _time,
        bool _token,
        bool _limited,
        uint256 _price,
        uint256 _seats,
        bool _vipAvailable,
        string _ipfs
    ) public goodTime(_time) whenNotPaused onlyOwner {
        OpenEvent memory _event = OpenEvent({
            owner: msg.sender,
            name: _name,
            time: _time,
            token: _token,
            limited: _limited,
            price: _price,
            seats: _seats,
            sold: 0,
            vipAvailable: _vipAvailable,
            ipfs: _ipfs
        });
        uint256 _eventId = openEvents.push(_event).sub(1);
        ownedEvents[msg.sender].push(_eventId);
        latestEvent = _eventId;
        emit CreatedEvent(msg.sender, _eventId);
    }

    /**
     * @dev Function to set VIP package settings for event.
     * @param _eventId - ID of event.
     * @param _price - Price of VIP ticket in ETH.
     * @param _seats - Number of seats/tickets available.
     * @param _sold - Number of seats/tickets sold.
     * @param _bottleService - Boolean indicating package includes bottle service.
     * @param _exclusive - Boolean indicating that a ticket holder is eligible to receive package exclusive.
     */
    function addVIPPackage(
        uint256 _eventId,
        uint256 _price,
        uint256 _seats,
        uint256 _sold,
        bool _bottleService,
        bool _exclusive
    ) public onlyEventOwner(_eventId) {
        VIPSettings memory _vipPackage = VIPSettings({
            price: _price,
            seats: _seats,
            sold: _sold,
            bottleService: _bottleService,
            exclusive: _exclusive
        });
        eventVIPSettings[_eventId].push(_vipPackage);
        uint256 _vipId = eventVIPSettings[_eventId].length.sub(1);
        vipTickets[_eventId] = _vipId;
        // eventVIPPackages[_eventId][
        // _vipId
        // ] = _vipPackage;
        emit CreatedVIPPackage(_eventId, _vipId);
    }

    /**
     * @dev Function to show all events of the specified address.
     * @param _owner - The address to query the events of.
     * @return uint[] - Array of events IDs.
     */
    function eventsOf(address _owner) public view returns (uint256[] memory) {
        return ownedEvents[_owner];
    }

    /**
     * @dev Function to set event admins.
     * @param _admin - The address to set as admin.
     * @param _eventId - The event ID admin priveledges will be granted for.
     */
    function setEventAdmin(address _admin, uint256 _eventId)
        public
        onlyEventOwner(_eventId)
    {
        adminEvents[_admin] = _eventId;
    }

    /**
     * @dev Function to set event admins.
     * @param _promoter - The address to set as admin.
     * @param _eventId - The event ID admin priveledges will be granted for.
     * @param _comps - The number of comp tickets to grant promoter permission to mint.
     */
    function setEventPromoterComps(
        address _promoter,
        uint256 _eventId,
        uint256 _comps
    ) public onlyEventOwner(_eventId) {
        promoterEventComps[_promoter][_eventId] = _comps;
    }

    /**
     * @dev Function to set event admins.
     * @param _admin - The address to set as admin.
     */
    function getAdminEvent(address _admin) public view returns (uint256) {
        return adminEvents[_admin];
    }

    /**
     * @dev Function to set event admins.
     * @param _promoter - The address to set as admin.
     * @param _eventId - The event ID admin priveledges will be granted for.
     * @return comps uint - The number of comp tickets to grant promoter permission to mint.
     */
    function getEventPromoterComps(address _promoter, uint256 _eventId)
        public
        view
        returns (uint256 comps)
    {
        return promoterEventComps[_promoter][_eventId];
    }

    /**
     * @dev Function to show general adminssions information for the event.
     * @param _eventId - Event ID.
     * @notice Requires that the events exist.
     * @return name string - The name of the event.
     * @return time uint - The time of the event. Should be in the future.
     * @return token bool - If true the price will be in tokens, else the price will be in ethereum.
     * @return limited bool - If true event has limited seats.
     * @return price uint - The ticket price.
     * @return seats uint - If event has limited seats, says how much tickets can be sold.
     * @return sold uint - If event has limited seats, says how much tickets can be sold.
     * @return ipfs string - The IPFS hash containing additional information about the event.
     * @return owner address - The owner of the event.
     */
    function getEvent(uint256 _eventId)
        public
        view
        eventExist(_eventId)
        returns (
            string memory name,
            uint256 time,
            bool token,
            bool limited,
            uint256 price,
            uint256 seats,
            uint256 sold,
            string memory ipfs,
            address owner
        )
    {
        OpenEvent memory _event = openEvents[_eventId];
        return (
            _event.name,
            _event.time,
            _event.token,
            _event.limited,
            _event.price,
            _event.seats,
            _event.sold,
            _event.ipfs,
            _event.owner
        );
    }

    /**
     * @dev Function to show VIP information for the event.
     * @param _eventId - Event ID.
     * @param _eventId - Event ID.
     * @notice Requires that the events exist.
     * @return price uint256 - If true event has vip available.
     * @return seats uint256 - The VIP ticket price.
     * @return sold uint256 - Says how much tickets can be sold.
     * @return bottleService bool - If event has limited seats, says how much tickets can be sold.
     * @return exclusive bool - If event has limited seats, says how much tickets can be sold.
     * @return ipfs string - The IPFS hash containing additional information about the event.
     **/
    function getEventVIP(uint256 _eventId, uint256 _vipId)
        public
        view
        eventExist(_eventId)
        returns (
            uint256 price,
            uint256 seats,
            uint256 sold,
            bool bottleService,
            bool exclusive
        )
    {
        VIPSettings memory _vipPackage = eventVIPSettings[_eventId][_vipId];
        return (
            _vipPackage.price,
            _vipPackage.seats,
            _vipPackage.sold,
            _vipPackage.bottleService,
            _vipPackage.exclusive
        );
    }

    /**
     * @dev Function returns number of all events.
     * @return uint - Number of events.
     */
    function getEventsCount() public view returns (uint256) {
        return openEvents.length;
    }

    // uint256 _qty
    //  * @param _qty - Ticket quantity to mint.

    /**
     * @dev Function to grant ticket to address on guest list.
     * @param _guest - The address of guest list member.
     * @param _eventId - The ID of event.
     * @notice Requires that the events exist.
     * @notice Requires that the events time is in the future.
     * @notice Requires that the contract is not paused.
     * @notice Reverts if event has limited seats and an amount of sold tickets bigger then the number of seats.
     */
    function grantTicket(address _guest, uint256 _eventId)
        public
        payable
        eventExist(_eventId)
        goodTime(openEvents[_eventId].time)
        whenNotPaused
        onlyEventAdmin(msg.sender, _eventId)
    {
        OpenEvent memory _event = openEvents[_eventId];

        if (_event.limited) {
            require(_event.seats > _event.sold);
        }

        uint256 seat = _event.sold.add(1);
        openEvents[_eventId].sold = seat;

        Ticket memory _ticket = Ticket({
            event_id: _eventId,
            vip: 0,
            seat: seat,
            image: _event.ipfs
        });

        uint256 _ticketId = tickets.push(_ticket).sub(1);
        ticketValidity[_ticketId] = true;
        _mint(_guest, _ticketId);
        emit SoldTicket(_guest, _eventId, _ticketId, 0);
    }

    // , uint256 _qty
    // * @param _qty - Ticket quantity to mint.

    /**
     * @dev Function to buy ticket to specific event.

     * @notice Requires that the events exist.
     * @notice Requires that the events time is in the future.
     * @notice Requires that the contract is not paused.
     * @notice Reverts if event has limited seats and an amount of sold tickets bigger then the number of seats.
     * @notice Reverts if ticket price is in ethereum and msg.value smaller then the ticket price.
     * @notice Reverts if ticket price is in tokens and token.transferFrom() does not return true.
     */
    function buyTicket()
        public
        payable
        eventExist(latestEvent)
        goodTime(openEvents[latestEvent].time)
        whenNotPaused
    {
        OpenEvent memory _event = openEvents[latestEvent];
        openEvents[latestEvent].sold = seat;
        uint256 _qty = msg.value / _event.price;
        uint256 _ticketId = _event.sold;
        if (_event.limited)
            require(_event.seats > _event.sold.add(_qty), "Sold Out");
        _event.sold = _event.sold.add(_qty);

        require(msg.value >= _event.price.mul(_qty), "Not enough sent");

        _event.owner.transfer(_qty.mul(_event.price));

        for (uint256 i; i < _qty; i++) {
            uint256 seat = _ticketId.add(i);
            Ticket memory _ticket = Ticket({
                event_id: latestEvent,
                vip: 0,
                seat: seat,
                image: _event.ipfs
            });

            uint256 newId = tickets.push(_ticket).sub(1);
            ticketValidity[newId] = true;
            _mint(msg.sender, newId);
            emit SoldTicket(msg.sender, latestEvent, newId, 0);
        }
    }

    /**
     * @dev Function to purchase a VIP ticket.

     **/
    function buyVIPTicket()
        public
        payable
        eventExist(latestEvent)
        eventVIPExists(latestEvent, _vipId)
        goodTime(openEvents[latestEvent].time)
        whenNotPaused
    {
        uint256 _vipId = vipTickets[latestEvent];
        VIPSettings memory _vipPackage = eventVIPSettings[latestEvent][_vipId];
        uint256 _qty = 8;

        OpenEvent memory _event = openEvents[latestEvent];
        require(_qty < _vipPackage.seats.sub(_vipPackage.sold), "Sold out.");
        // "Not enough VIP tickets remaining for this event."

        require(msg.value >= _vipPackage.price, "Not enough sent.");
        _event.owner.transfer(_vipPackage.price);

        for (uint256 i; i < _qty; i++) {
            uint256 seat = _vipPackage.sold.add(1);
            eventVIPSettings[latestEvent][_vipId].sold = seat;

            Ticket memory _vipTicket = Ticket({
                event_id: latestEvent,
                vip: _vipId,
                seat: seat,
                image: _event.ipfs
            });
            uint256 _ticketId = tickets.push(_vipTicket).sub(1);
            _mint(msg.sender, _ticketId);
            emit SoldTicket(msg.sender, latestEvent, _ticketId, 0);
        }
    }

    /**
     * @dev Function to redeem ticket to specific event.
     * @param _ticketId - The ID of ticket.
     * @param _eventId - The ID of event.
     * @notice Requires that the events exist.
     * @notice Requires that the contract is not paused.
     * @notice Requires that the caller is an event admin.
     * @notice Requires that the ticket is present.
     * @return vip uint256 - ID of the VIP package of redeemed ticket. 0 represents GA.
     */
    function redeemTicket(uint256 _ticketId, uint256 _eventId)
        public
        eventExist(_eventId)
        whenNotPaused
        onlyEventAdmin(msg.sender, _eventId)
        validTicket(_ticketId)
        returns (uint256)
    {
        ticketValidity[_ticketId] = false;
        uint256 vip = tickets[_ticketId].vip;
        emit RedeemedTicket(_eventId, _ticketId, vip);
        return vip;
    }

    /**
     * @dev Function to redeem VIP exclusive.
     * @param _eventId - ID of event.
     * @param _vipId - ID of event.
     * @return bool exclusive - Boolean representing status of VIP exclusive redemption.
     */
    function redeemVIPExclusive(uint256 _eventId, uint256 _vipId)
        public
        eventExist(_eventId)
        eventVIPExists(_eventId, _vipId)
        returns (bool)
    {
        bool exclusive = eventVIPSettings[_eventId][_vipId].exclusive;
        eventVIPSettings[_eventId][_vipId].exclusive = false;
        return exclusive;
    }
}