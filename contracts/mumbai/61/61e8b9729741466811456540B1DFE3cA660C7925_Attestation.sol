/**
 *Submitted for verification at polygonscan.com on 2023-03-05
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/SchemaRegistry.sol

pragma solidity >=0.8.12 <0.9.0;


contract SchemaRegistry is Ownable {
  /* 
    * TODO open access to everyone or to a trusted few ?
    * everyone -> remove `is Ownable` and `onlyOwner`
    * trusted few -> 
    * * 1. inherit AccessControl 
    * * 2. implement registrarApprovals and REGISTRAR_ROLE
    * * // bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    * * // mapping(address => bool)) private _registrarApprovals;
  */
  /*
    * TODO gas optimizations if we decide to open up Schema Registry to everyone
    * 2. consider using enum (uint8) instead of string for schemaType
    * 3. remove key from Schema struct because it is redundant 
    * 4. rearrange struct fields for better packing
  */
  uint256 private _schemaIdCounter;

  //TODO should this be enums
  mapping(string => uint8) public schemaTypes;
  enum SchemaType { CUSTOM, JSON, YAML }

  struct Schema {
    uint256 schemaId; 
    address creator;
    string key; 
    SchemaType schemaType;
    string definition;
  }

  mapping(bytes32 => Schema) public schemas; 
  mapping(uint => bytes32) public schemaIds; 

  event SchemaRegistered(
    uint256 schemaId,
    address indexed creator,
    string key,
    SchemaType schemaType,
    string definition
  );

  function registerSchema(
    string memory _key, 
    SchemaType _schemaType, 
    string memory _definition
  ) external onlyOwner {

    bytes32 hashed = keccak256(abi.encode(msg.sender, _key));
    require(schemas[hashed].schemaId == 0, "Schema already exists");

    _schemaIdCounter++;

    schemas[hashed] = Schema(_schemaIdCounter, msg.sender, _key, _schemaType, _definition);
    schemaIds[_schemaIdCounter] = hashed;

    emit SchemaRegistered(_schemaIdCounter, msg.sender, _key, _schemaType, _definition);
  } 

  function getSchemaById(uint256 _schemaId) external view 
  returns (Schema memory)
  {
    bytes32 hashed = schemaIds[_schemaId];
    require(hashed != 0x00, "Invalid Schema Id");

    Schema storage _schema = schemas[hashed];
    return (_schema);
  }
}


// File contracts/Attestation.sol

pragma solidity >=0.8.12 <0.9.0;

/** 
 * @title Attestations
 * @notice Contract used to publish attestations.
 * @custom:beta
 */
 contract Attestation is SchemaRegistry {
  string public constant SEMVER = "0.1.0";

  struct AttestationRecord {
    uint256 schemaId;
    address publisher;
    address from;
    address recipient;
    string data;
  }

  event AttestationPublished(
    address indexed publisher,
    address indexed from,
    address indexed recipient,
    uint256 schemaId,
    string data
  );

  AttestationRecord[] public attestations;
  uint256 attestationCount = 0; 
  mapping(uint256 => uint256[]) public attestationIdxBySchemaId;
  mapping(address => uint256[]) public attestationIdxByPublisher;

  /**
    * Emits a {AttestationPublished} event.
    * @dev Currently msg.sender, _from, and _recipient can all be the same address, even another contract address.
    * @notice Publish an attestation or update if an attestaion is already published. 
    * @param _from Address that is providing the attestation.
    * @param _recipient Address that the attestation is about.
    * @param _schemaId Valid schema defined in the Schema registry.
    * @param _data Attestation data that conforms to the schema.
    */
  function attest(
    address _from,
    address _recipient,
    uint256 _schemaId,
    string memory _data
  ) public {
    require(
      _from != address(0) && _from != address(0),
      "Zero addresses not allowed" //26 bytes < 1 slot
    ); 
    require(schemaIds[_schemaId] != 0x00, "Invalid _schemaId");
    
    attestations.push(AttestationRecord({
      schemaId: _schemaId,
      publisher: msg.sender,
      from: _from,
      recipient: _recipient,
      data: _data
    }));

    attestationIdxByPublisher[msg.sender].push(attestationCount);
    attestationIdxBySchemaId[_schemaId].push(attestationCount);
    attestationCount++;

    emit AttestationPublished(msg.sender, _from, _recipient, _schemaId, _data);
  }

  // TODO: Remove schemaId
  function attestBatch(uint256 _schemaId, AttestationRecord[] calldata _attestations) external {
    uint256 length = _attestations.length;
    for (uint256 i = 0; i < length;) {
      AttestationRecord memory attestation = _attestations[i];
      attest(attestation.from, attestation.recipient, _schemaId, attestation.data);
      unchecked {
        ++i;
      }
    }
  }

  /**
    * @notice Get all attestations published by a publisher.
    * @param _schemaId Valid schema defined in the Schema registry. 
    * @return AttestationRecord[] Array of attestation records.
    */
  function getAttestationsBySchemaId(uint256 _schemaId) external view returns (AttestationRecord[] memory) {
    uint256[] memory attestationIdxs = attestationIdxBySchemaId[_schemaId];
    uint256 length = attestationIdxs.length;
    AttestationRecord[] memory _attestations = new AttestationRecord[](length);

    for (uint256 i = 0; i < length;) {
      _attestations[i] = attestations[attestationIdxs[i]];
      unchecked {
        ++i;
      }
    }
    return _attestations;
  }

  /**
   * @notice Get all attestations published by a publisher.
   * @param _publisher Address of the publisher.
   * @return AttestationRecord[] Array of attestation records.
   */
  function getAttestationsByPublisher(address _publisher) external view returns (AttestationRecord[] memory) {
    uint256[] memory attestationIdxs = attestationIdxByPublisher[_publisher];
    uint256 length = attestationIdxs.length;
    AttestationRecord[] memory _attestations = new AttestationRecord[](length);

    for (uint256 i = 0; i < length;) {
      _attestations[i] = attestations[attestationIdxs[i]];
      unchecked {
        ++i;
      }
    }
    return _attestations;
  }
}