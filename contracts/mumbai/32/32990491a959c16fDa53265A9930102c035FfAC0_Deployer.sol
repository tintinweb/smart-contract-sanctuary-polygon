// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "./Artist.sol";
import "./utils/OwnableSimple.sol";

contract Deployer is OwnableSimple {
    mapping(address => ArtistCollection) internal artistOwnerMap;

    constructor () OwnableSimple(msg.sender) {}

    modifier isNotDeployed(address _artistAddr) {
        require(address(artistOwnerMap[_artistAddr])==address(0) || msg.sender == owner, "Artist Collection already deployed");
        _;
    }

    function deploy(string memory _collectionName, string memory _baseURI, address _artistAddr, uint256 _royaltyBasisPoints, address _currency) external isNotDeployed(_artistAddr){
        ArtistCollection _a = new ArtistCollection(_collectionName, _baseURI, _artistAddr, _royaltyBasisPoints, _currency);
        artistOwnerMap[_artistAddr] = _a;
    }

    function getCollection(address _artistAddr) external view returns(address) {
        return address(artistOwnerMap[_artistAddr]);
    }

    // function setBaseURIBatch(address[] memory _artistAddrs, string[] calldata _baseURIs) external onlyOwner {
    //     require(_artistAddrs.length == _baseURIs.length, "Array lengths must match");
    //     for (uint i = 0; i < _artistAddrs.length; i++) {
    //         artistOwnerMap[_artistAddrs[i]].setBaseURI(_baseURIs[i]);
    //     }
    // }

    function setCurrencyBatch(address[] memory _artistAddrs, address[] memory _currencies) external onlyOwner {
        require(_artistAddrs.length == _currencies.length, "Array lengths must match");
        for (uint i = 0; i < _artistAddrs.length; i++) {
            artistOwnerMap[_artistAddrs[i]].setCurrency(_currencies[i]);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;



contract OwnableSimple {
  address internal owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor (address _firstOwner) {
    owner = _firstOwner;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  function getOwner() public view returns (address) {
    return owner;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;



contract Ownable {
  address internal owner;
  address internal creator;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor (address _creator, address _firstOwner) {
    owner = _firstOwner;
    creator = _creator;
    emit OwnershipTransferred(address(0), _firstOwner);
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Ownable#onlyOwner: SENDER_IS_NOT_OWNER");
    _;
  }

  modifier onlyCreator() {
    require(msg.sender == creator, "Ownable#onlyCreator: SENDER_IS_NOT_CREATOR");
    _;
  }

  modifier onlyOwnerOrCreator() {
    require(msg.sender == owner || msg.sender == creator, "Ownable#onlyOwnerOrCreator: SENDER_IS_NOT_OWNER_OR_CREATOR");
    _;
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0), "Ownable#transferOwnership: INVALID_ADDRESS");
    owner = _newOwner;
    emit OwnershipTransferred(owner, _newOwner);
  }

  function getOwner() public view returns (address) {
    return owner;
  }

  function getCreator() public view returns (address) {
    return creator;
  }  

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.4;

import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155MintBurn.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC1155/ERC1155Metadata.sol";
import "@0xsequence/erc-1155/contracts/tokens/ERC2981/ERC2981Global.sol";
import "@0xsequence/erc-1155/contracts/utils/SafeMath.sol";
import "./utils/Ownable.sol";
import "./utils/IERC20.sol";

contract ArtistCollection is ERC1155MintBurn, ERC1155Metadata, ERC2981Global, Ownable{
    using SafeMath for uint256;

    /***********************************|
    |             Variables             |
    |__________________________________*/
    IERC20 internal currency;
    mapping(uint256 => uint256) internal tokenPrices; // Stores the Price
    uint256 internal currTokenID;
    /***********************************|
    |             Constuctor            |
    |__________________________________*/
    constructor(string memory _name, string memory _baseURI, address _artistAddr, uint256 _royaltyBasisPoints, address _currency) 
                ERC1155Metadata(_name, _baseURI)
                Ownable(msg.sender, _artistAddr) 
                {
                    _setGlobalRoyaltyInfo(_artistAddr, _royaltyBasisPoints);
                    currency = IERC20(_currency);
                    currTokenID = 0;
                }

    /***********************************|
    |      Receiver Method Handler      |
    |__________________________________*/
    /**
    * @notice Prevents receiving Ether or calls to unsuported methods
    */
    fallback () external {
        revert("UNSUPPORTED_METHOD");
    }

    // sets token id base uri... 
    function setBaseURI(string calldata _newuri) public onlyCreator {
        _setBaseMetadataURI(_newuri);
    }

    function setContractName(string calldata _newName) public onlyCreator {
        _setContractName(_newName);
    }

    function transferOwnership(address _newOwner, uint256 _royaltyBasisPoints) public onlyOwner {
        _transferOwnership(_newOwner);
        _setGlobalRoyaltyInfo(_newOwner, _royaltyBasisPoints);
    }

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    function getTokenPrice(uint256 _id) external view returns(uint256) {
        return tokenPrices[_id];
    }

    function getCurrency() external view returns(address) {
        return address(currency);
    }

    function setCurrency(address _currency) external onlyOwnerOrCreator {
        currency = IERC20(_currency);
    }
    
    function currencyBalance() external view returns(uint256){
        return currency.balanceOf(msg.sender);
    }

    // sets price if it was not set... while minting it can be reset
    function setPrice(uint256 _id, uint256 _price) external onlyOwner {
        tokenPrices[_id] = _price;
    }

    function setPriceBatch(uint256[] memory _ids, uint256[] memory _prices) external onlyOwner {
        require(_ids.length == _prices.length, "Lengths of arrays must match");
        for(uint256 i = 0; i < _ids.length; i++) {
            tokenPrices[_ids[i]] = _prices[i];
        }
    }

    /***********************************|
    |         Market Functions          |
    |__________________________________*/
    modifier tokenAvailable(uint256 _id) {
        require(balanceOf(owner, _id)>0);
        _;
    }

    function buy(uint256 _id, uint256 _amount, bytes memory _data) external 
        tokenAvailable(_id)
    {
        uint256 totalPrice = tokenPrices[_id] * _amount;
        bool _success = currency.transferFrom(msg.sender,owner,totalPrice);
        require(_success, "Buyer Couldn't Transfer Currency");
        _safeTransferFrom(owner, msg.sender, _id, _amount);
        _callonERC1155Received(owner, msg.sender, _id, _amount, gasleft(), _data);
    }


    /***********************************|
    |    Royalty Management Methods     |
    |__________________________________*/
    /**
    * @notice Will set the basis point and royalty recipient that is applied to all Skyweaver assets
    * @param _royaltyBasisPoints Basis points with 3 decimals representing the fee %
    *        e.g. a fee of 2% would be 20 (i.e. 20 / 1000 == 0.02, or 2%)
    */
    function setGlobalRoyaltyInfo(uint256 _royaltyBasisPoints) external onlyOwner() {
        _setGlobalRoyaltyInfo(owner, _royaltyBasisPoints);
    }

    /***********************************|
    |         Minting Methods           |
    |__________________________________*/
    function mint(uint256 id, uint256 amount, uint256 price, bytes memory data)
        public
        onlyOwner
    {
        _mint(owner, id, amount, data);
        tokenPrices[id] = price;
        if (currTokenID<id){
            currTokenID = id;
        }
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts, uint256[] memory prices, bytes memory data)
        public
        onlyOwner
    {
        _batchMint(owner, ids, amounts, data);
        uint i=0;
        for (i = 0; i < ids.length; i++) {
            if (currTokenID<ids[i]){
                currTokenID=ids[i];
            }
            tokenPrices[ids[i]] = prices[i];
        }
    }   

    function getNextTokenID() external view returns(uint256) {
        return currTokenID+1;
    }

    /***********************************|
    |          Burning Functions        |
    |__________________________________*/

    /**
    * @notice Burn _amount of tokens of a given id from msg.sender
    * @dev This will not change the current issuance tracked in _supplyManagerAddr.
    * @param _id     Asset id to burn
    * @param _amount The amount to be burn
    */
    function burn(
        uint256 _id,
        uint256 _amount)
        external
    {
        _burn(msg.sender, _id, _amount);
    }

    /**
    * @notice Burn _amounts of tokens of given ids from msg.sender
    * @dev This will not change the current issuance tracked in _supplyManagerAddr.
    * @param _ids     Asset id to burn
    * @param _amounts The amount to be burn
    */
    function batchBurn(
        uint256[] calldata _ids,
        uint256[] calldata _amounts)
        external
    {
        _batchBurn(msg.sender, _ids, _amounts);
    }

    /***********************************|
    |          ERC165 Functions         |
    |__________________________________*/
    /**
    * @notice Query if a contract implements an interface
    * @param _interfaceID  The interface identifier, as specified in ERC-165
    * @return `true` if the contract implements `_interfaceID`
    */
    function supportsInterface(bytes4 _interfaceID) public override(ERC1155, ERC1155Metadata, ERC2981Global) virtual pure returns (bool) {
        return super.supportsInterface(_interfaceID);
    }
}

pragma solidity 0.7.4;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }
}

pragma solidity 0.7.4;
import "../interfaces/IERC165.sol";

abstract contract ERC165 is IERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual override public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

pragma solidity 0.7.4;


/**
 * Utility library of inline functions on addresses
 */
library Address {

  // Default hash for EOA accounts returned by extcodehash
  bytes32 constant internal ACCOUNT_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract.
   * @param _address address of the account to check
   * @return Whether the target address is a contract
   */
  function isContract(address _address) internal view returns (bool) {
    bytes32 codehash;

    // Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address or if it has a non-zero code hash or account hash
    assembly { codehash := extcodehash(_address) }
    return (codehash != 0x0 && codehash != ACCOUNT_HASH);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "../../utils/ERC165.sol";
import "../../utils/SafeMath.sol";
import "../../interfaces/IERC2981.sol";

/**
 * @notice Contract return royalty information for tokens of this contract
 * @dev This contract sets a global fee information for all token ids.
 */
contract ERC2981Global is IERC2981, ERC165 {
  using SafeMath for uint256;

  struct FeeInfo {
    address receiver;
    uint256 feeBasisPoints;
  }

  // Royalty Fee information struct
  FeeInfo public globalRoyaltyInfo;

  /**
   * @notice Will set the basis point and royalty recipient that is applied to all assets
   * @param _receiver Fee recipient that will receive the royalty payments
   * @param _royaltyBasisPoints Basis points with 3 decimals representing the fee %
   *        e.g. a fee of 2% would be 20 (i.e. 20 / 1000 == 0.02, or 2%)
   */
  function _setGlobalRoyaltyInfo(address _receiver, uint256 _royaltyBasisPoints) internal {
    require(_receiver != address(0x0), "ERC2981Global#_setGlobalRoyalty: RECIPIENT_IS_0x0");
    require(_royaltyBasisPoints <= 1000, "ERC2981Global#_setGlobalRoyalty: FEE_IS_ABOVE_100_PERCENT");
    globalRoyaltyInfo.receiver = _receiver;
    globalRoyaltyInfo.feeBasisPoints = _royaltyBasisPoints;
  }


  /***********************************|
  |         ERC-2981 Functions        |
  |__________________________________*/

    /**  
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * @param _saleCost - the sale cost of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */
  function royaltyInfo(
    uint256, 
    uint256 _saleCost
  ) external view override returns (address receiver, uint256 royaltyAmount) 
  {
    FeeInfo memory info = globalRoyaltyInfo;
    return (info.receiver, _saleCost.mul(info.feeBasisPoints).div(1000));
  }


  /***********************************|
  |         ERC-165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC2981).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "./ERC1155.sol";


/**
 * @dev Multi-Fungible Tokens with minting and burning methods. These methods assume
 *      a parent contract to be executed as they are `internal` functions
 */
contract ERC1155MintBurn is ERC1155 {
  using SafeMath for uint256;

  /****************************************|
  |            Minting Functions           |
  |_______________________________________*/

  /**
   * @notice Mint _amount of tokens of a given id
   * @param _to      The address to mint tokens to
   * @param _id      Token id to mint
   * @param _amount  The amount to be minted
   * @param _data    Data to pass if receiver is contract
   */
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
    // Add _amount
    balances[_to][_id] = balances[_to][_id].add(_amount);

    // Emit event
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

    // Calling onReceive method if recipient is contract
    _callonERC1155Received(address(0x0), _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Mint tokens for each ids in _ids
   * @param _to       The address to mint tokens to
   * @param _ids      Array of ids to mint
   * @param _amounts  Array of amount of tokens to mint per id
   * @param _data    Data to pass if receiver is contract
   */
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

    // Number of mints to execute
    uint256 nMint = _ids.length;

     // Executing all minting
    for (uint256 i = 0; i < nMint; i++) {
      // Update storage balance
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

    // Calling onReceive method if recipient is contract
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, gasleft(), _data);
  }


  /****************************************|
  |            Burning Functions           |
  |_______________________________________*/

  /**
   * @notice Burn _amount of tokens of a given token id
   * @param _from    The address to burn tokens from
   * @param _id      Token id to burn
   * @param _amount  The amount to be burned
   */
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
    //Substract _amount
    balances[_from][_id] = balances[_from][_id].sub(_amount);

    // Emit event
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

  /**
   * @notice Burn tokens of given token id for each (_ids[i], _amounts[i]) pair
   * @param _from     The address to burn tokens from
   * @param _ids      Array of token ids to burn
   * @param _amounts  Array of the amount to be burned
   */
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    // Number of mints to execute
    uint256 nBurn = _ids.length;
    require(nBurn == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

    // Executing all minting
    for (uint256 i = 0; i < nBurn; i++) {
      // Update storage balance
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

    // Emit batch mint event
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import "../../interfaces/IERC1155Metadata.sol";
import "../../utils/ERC165.sol";


/**
 * @notice Contract that handles metadata related methods.
 * @dev Methods assume a deterministic generation of URI based on token IDs.
 *      Methods also assume that URI uses hex representation of token IDs.
 */
contract ERC1155Metadata is IERC1155Metadata, ERC165 {
  // URI's default URI prefix
  string public baseURI;
  string public name;

  // set the initial name and base URI
  constructor(string memory _name, string memory _baseURI) {
    name = _name;
    baseURI = _baseURI;
  }

  /***********************************|
  |     Metadata Public Functions     |
  |__________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   * @return URI string
   */
  function uri(uint256 _id) public override view returns (string memory) {
    return string(abi.encodePacked(baseURI, _uint2str(_id), ".json"));
  }


  /***********************************|
  |    Metadata Internal Functions    |
  |__________________________________*/

  /**
   * @notice Will emit default URI log event for corresponding token _id
   * @param _tokenIDs Array of IDs of tokens to log default URI
   */
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

  /**
   * @notice Will update the base URL of token's URI
   * @param _newBaseMetadataURI New base URL of token's URI
   */
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseURI = _newBaseMetadataURI;
  }

  /**
   * @notice Will update the name of the contract
   * @param _newName New contract name
   */
  function _setContractName(string memory _newName) internal {
    name = _newName;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155Metadata).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }


  /***********************************|
  |    Utility Internal Functions     |
  |__________________________________*/

  /**
   * @notice Convert uint256 to string
   * @param _i Unsigned integer to convert to string
   */
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

    // Get number of bytes
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

    // Get each individual ASCII
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

    // Convert to string
    return string(bstr);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

import "../../utils/SafeMath.sol";
import "../../interfaces/IERC1155TokenReceiver.sol";
import "../../interfaces/IERC1155.sol";
import "../../utils/Address.sol";
import "../../utils/ERC165.sol";


/**
 * @dev Implementation of Multi-Token Standard contract
 */
contract ERC1155 is IERC1155, ERC165 {
  using SafeMath for uint256;
  using Address for address;

  /***********************************|
  |        Variables and Events       |
  |__________________________________*/

  // onReceive function signatures
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

  // Objects balances
  mapping (address => mapping(uint256 => uint256)) internal balances;

  // Operator Functions
  mapping (address => mapping(address => bool)) internal operators;


  /***********************************|
  |     Public Transfer Functions     |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   * @param _data    Additional data with no specified format, sent in call to `_to`
   */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public override
  {
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
    // require(_amount <= balances[_from][_id]) is not necessary since checked with safemath operations

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, gasleft(), _data);
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   * @param _data     Additional data with no specified format, sent in call to `_to`
   */
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public override
  {
    // Requirements
    require((msg.sender == _from) || isApprovedForAll(_from, msg.sender), "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, gasleft(), _data);
  }


  /***********************************|
  |    Internal Transfer Functions    |
  |__________________________________*/

  /**
   * @notice Transfers amount amount of an _id from the _from address to the _to address specified
   * @param _from    Source address
   * @param _to      Target address
   * @param _id      ID of the token type
   * @param _amount  Transfered amount
   */
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
    // Update balances
    balances[_from][_id] = balances[_from][_id].sub(_amount); // Subtract amount
    balances[_to][_id] = balances[_to][_id].add(_amount);     // Add amount

    // Emit event
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155Received(...)
   */
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Check if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received{gas: _gasLimit}(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

  /**
   * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
   * @param _from     Source addresses
   * @param _to       Target addresses
   * @param _ids      IDs of each token type
   * @param _amounts  Transfer amounts per token type
   */
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

    // Number of transfer to execute
    uint256 nTransfer = _ids.length;

    // Executing all transfers
    for (uint256 i = 0; i < nTransfer; i++) {
      // Update storage balance of previous bin
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

    // Emit event
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

  /**
   * @notice Verifies if receiver is contract and if so, calls (_to).onERC1155BatchReceived(...)
   */
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, uint256 _gasLimit, bytes memory _data)
    internal
  {
    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived{gas: _gasLimit}(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


  /***********************************|
  |         Operator Functions        |
  |__________________________________*/

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved)
    external override
  {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator)
    public override view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


  /***********************************|
  |         Balance Functions         |
  |__________________________________*/

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id)
    public override view returns (uint256)
  {
    return balances[_owner][_id];
  }

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public override view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

    // Variables
    uint256[] memory batchBalances = new uint256[](_owners.length);

    // Iterate over each owner and token ID
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


  /***********************************|
  |          ERC165 Functions         |
  |__________________________________*/

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID  The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID` and
   */
  function supportsInterface(bytes4 _interfaceID) public override(ERC165, IERC165) virtual pure returns (bool) {
    if (_interfaceID == type(IERC1155).interfaceId) {
      return true;
    }
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';

interface IERC2981 is IERC165 {
  /**  
    * @notice Called with the sale price to determine how much royalty is owed and to whom.
    * @param _tokenId - the NFT asset queried for royalty information
    * @param _saleCost - the sale cost of the NFT asset specified by _tokenId
    * @return receiver - address of who should be sent the royalty payment
    * @return royaltyAmount - the royalty payment amount for _salePrice
    */
  function royaltyInfo(uint256 _tokenId, uint256 _saleCost) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

  /**
   * @notice Handle the receipt of a single ERC1155 token type
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value MUST result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _id        The id of the token being transferred
   * @param _amount    The amount of tokens being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

  /**
   * @notice Handle the receipt of multiple ERC1155 token types
   * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
   * This function MAY throw to revert and reject the transfer
   * Return of other amount than the magic value WILL result in the transaction being reverted
   * Note: The token contract address is always the message sender
   * @param _operator  The address which called the `safeBatchTransferFrom` function
   * @param _from      The address which previously owned the token
   * @param _ids       An array containing ids of each token being transferred
   * @param _amounts   An array containing amounts of each token being transferred
   * @param _data      Additional data with no specified format
   * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;


interface IERC1155Metadata {

  event URI(string _uri, uint256 indexed _id);

  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
   * @notice A distinct Uniform Resource Identifier (URI) for a given token.
   * @dev URIs are defined in RFC 3986.
   *      URIs are assumed to be deterministically generated based on token ID
   *      Token IDs are assumed to be represented in their hex format in URIs
   * @return URI string
   */
  function uri(uint256 _id) external view returns (string memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.4;
import './IERC165.sol';


interface IERC1155 is IERC165 {

  /****************************************|
  |                 Events                 |
  |_______________________________________*/

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

  /**
   * @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero amount transfers as well as minting or burning
   *   Operator MUST be msg.sender
   *   When minting/creating tokens, the `_from` field MUST be set to `0x0`
   *   When burning/destroying tokens, the `_to` field MUST be set to `0x0`
   *   The total amount transferred from address 0x0 minus the total amount transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID
   *   To broadcast the existence of multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`, and a `_amount` of 0
   */
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

  /**
   * @dev MUST emit when an approval is updated
   */
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


  /****************************************|
  |                Functions               |
  |_______________________________________*/

  /**
    * @notice Transfers amount of an _id from the _from address to the _to address specified
    * @dev MUST emit TransferSingle event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if balance of sender for token `_id` is lower than the `_amount` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    * @param _from    Source address
    * @param _to      Target address
    * @param _id      ID of the token type
    * @param _amount  Transfered amount
    * @param _data    Additional data with no specified format, sent in call to `_to`
    */
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

  /**
    * @notice Send multiple types of Tokens from the _from address to the _to address (with safety call)
    * @dev MUST emit TransferBatch event on success
    * Caller must be approved to manage the _from account's tokens (see isApprovedForAll)
    * MUST throw if `_to` is the zero address
    * MUST throw if length of `_ids` is not the same as length of `_amounts`
    * MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_amounts` sent
    * MUST throw on any other error
    * When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` and revert if the return amount is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    * Transfers and events MUST occur in the array order they were submitted (_ids[0] before _ids[1], etc)
    * @param _from     Source addresses
    * @param _to       Target addresses
    * @param _ids      IDs of each token type
    * @param _amounts  Transfer amounts per token type
    * @param _data     Additional data with no specified format, sent in call to `_to`
  */
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;

  /**
   * @notice Get the balance of an account's Tokens
   * @param _owner  The address of the token holder
   * @param _id     ID of the Token
   * @return        The _owner's balance of the Token type requested
   */
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

  /**
   * @notice Get the balance of multiple account/token pairs
   * @param _owners The addresses of the token holders
   * @param _ids    ID of the Tokens
   * @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
   */
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

  /**
   * @notice Enable or disable approval for a third party ("operator") to manage all of caller's tokens
   * @dev MUST emit the ApprovalForAll event on success
   * @param _operator  Address to add to the set of authorized operators
   * @param _approved  True if the operator is approved, false to revoke approval
   */
  function setApprovalForAll(address _operator, bool _approved) external;

  /**
   * @notice Queries the approval status of an operator for a given owner
   * @param _owner     The owner of the Tokens
   * @param _operator  Address of authorized operator
   * @return isOperator True if the operator is approved, false if not
   */
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);
}