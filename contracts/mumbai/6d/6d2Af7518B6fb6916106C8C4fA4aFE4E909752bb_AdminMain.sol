/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/18_aa.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";


contract AdminMain is Ownable {
  //identify owner
  address contractOwnerAddress;

  //to identify the contract id of the orginazation
  mapping(string => Organization) public organizationContract;

  //constructor
  address OrganizationImplementationAddress; //done //make private later
  address EventImplementationAddress; //done //make private later

  // constructor(address _OrganizationImplementationAddress, address _EventImplementationAddress) {
  //     OrganizationImplementationAddress = _OrganizationImplementationAddress;
  //     EventImplementationAddress = _EventImplementationAddress;
  //     contractOwnerAddress = msg.sender;
  // }
  //implement  this later <--------------------------------------------------
  constructor() {
    OrganizationImplementationAddress = address(new Organization());
    EventImplementationAddress = address(new Event());
    contractOwnerAddress = msg.sender; //msg.sender could also be written as owner
  }

  function addOrganization(string memory organizationName)
    public
    onlyOwner
    returns (address)
  {
    //also think of returning orginization insterd of address (i think its the same thing)
    //add a check for minimum orginization size (ask krishna)

    // require(organizationContract[organizationName] == Organization(address(0))); //prevent contract to be overriden
    //Creating a new Organization object
    Organization OrganizationAddress = Organization(
      Clones.clone(OrganizationImplementationAddress)
    );

    // since the clone create a proxy, the constructor is redundant and you have to use the initialize function
    OrganizationAddress.initialize(
      EventImplementationAddress,
      contractOwnerAddress
    ); //done //pass in the parameters of their address later (also pass in the implementation address) <-----------------------------------------

    //mapping organizationContract to organization name
    organizationContract[organizationName] = OrganizationAddress;
    return address(OrganizationAddress);
  }
}

//generates events
contract Organization {
  //to identify the contract id of the orginazation
  mapping(string => Event) public eventContract;

  address public EventImplementationAddress; //make private later
  address public contractOwnerAddress; //make private later

  function initialize(
    address _EventImplementationAddress,
    address _contractOwnerAddress
  ) public {
    //change this to contract only and only owners
    require(contractOwnerAddress == address(0), "already initialized");
    require(EventImplementationAddress == address(0), "already initialized");
    EventImplementationAddress = _EventImplementationAddress;
    contractOwnerAddress = _contractOwnerAddress;
  }

  function addEvent(string memory eventName) public returns (address) {
    // require(eventContract[eventName] == Event(address(0))); //prevent contract to be overriden
    require(msg.sender == contractOwnerAddress, "Permission Denied");
    //Creating a new crew Event
    Event EventAddress = Event(Clones.clone(EventImplementationAddress));

    // since the clone create a proxy, the constructor is redundant and you have to use the initialize function
    EventAddress.initialize(contractOwnerAddress); // done //pass in the parameters of their address later (also pass in the implementation address so child can add stuff) <-----------------------------------------

    //mapping eventContract to event name
    eventContract[eventName] = EventAddress;
    return address(EventAddress);
  }
}

//event tracker

contract Event {
  // is Ownable, AccessControl
 uint256 certCreate = 100;
  struct Certificate {
    string name;
    string organization;
    string url;
    address assignedTo;
    bool approved;
  }
  mapping(address => Certificate[]) public holdersCertificate;
  mapping(address => uint16) public holdersCertificateCount;

  address contractOwnerAddress; //make private later

  function initialize(address _contractOwnerAddress) public {
    require(contractOwnerAddress == address(0), "already initialized");
    contractOwnerAddress = _contractOwnerAddress;
    certCreate = 100;

  }

  

  function addMoreCertificates(uint256 number) public {
    require(contractOwnerAddress != address(0));
    // require(msg.sender != address(0)); //ask y abhay put this
    require(contractOwnerAddress == msg.sender);
    certCreate = certCreate + number;
  }

  //in future make child contract capable of adding its entry in parent contract
  function assignCertificate(
    string memory name,
    string memory organization,
    string memory url,
    address assignTo
  ) public {
    require(contractOwnerAddress != address(0));
    // require(msg.sender != address(0)); //ask abhay y he put this
    require(contractOwnerAddress == msg.sender);
    require(certCreate > 0); //just in case 2 prevent underflow attacks (not a problem in this vertion of solidity)
    //let us leave the checks off chain🔗
    // require(bytes(_name).length > 0);
    // require(bytes(_url).length > 0);
    //require(checkURL(_url));
    certCreate--;
    holdersCertificateCount[assignTo] = holdersCertificateCount[assignTo] + 1;

    holdersCertificate[assignTo].push(
      Certificate(name, organization, url, assignTo, true)
    );
    // holderCertificateCount[msg.sender] = holderCertificateCount[msg.sender] + 1;
  }

  function approveCertificate(
    uint256 id,
    address owner,
    bool status
  ) public {
    require(contractOwnerAddress != address(0));
    require(contractOwnerAddress == msg.sender);

    holdersCertificate[owner][id].approved = status;
  }
}