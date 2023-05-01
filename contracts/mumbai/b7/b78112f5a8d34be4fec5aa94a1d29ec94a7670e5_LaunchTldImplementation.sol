/**
 *Submitted for verification at polygonscan.com on 2023-04-30
*/

/**
 *Submitted for verification at polygonscan.com on 2023-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringToBytes32 {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        // Ensure that the source string is not longer than 32 bytes
        require(tempEmptyStringTest.length <= 32, "Source string is too long.");

        assembly {
            result := mload(add(source, 32))
        }
    }
}

library StringUtils {
    /**
     * @dev Returns the length of a given string
     *
     * @param s The string to measure the length of
     * @return The length of the input string
     */
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        uint bytelength = bytes(s).length;
        for(len = 0; i < bytelength; len++) {
            bytes1 b = bytes(s)[i];
            if(b < 0x80) {
                i += 1;
            } else if (b < 0xE0) {
                i += 2;
            } else if (b < 0xF0) {
                i += 3;
            } else if (b < 0xF8) {
                i += 4;
            } else if (b < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }
}

interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) virtual public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) virtual public view returns (address owner);

    function approve(address to, uint256 tokenId) virtual public;
    function getApproved(uint256 tokenId) virtual public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) virtual public;
    function isApprovedForAll(address owner, address operator) virtual public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) virtual public;
    function safeTransferFrom(address from, address to, uint256 tokenId) virtual public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) virtual public;
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface Reflect {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    event SetPermanent(bytes32 indexed node, bool permanent);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl, bool permanent) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl, bool permanent) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

abstract contract BaseRegistrar is IERC721, Ownable {
    event ControllerAdded(address indexed controller);
    event ControllerRemoved(address indexed controller);
    event NameMigrated(uint256 indexed id, bytes32 baseNode, address indexed owner, uint expires);
    event NameRegistered(uint256 indexed id, bytes32 baseNode, address indexed owner, uint expires, bool permanent);
    event NameRenewed(uint256 indexed id, bytes32 baseNode, uint expires);

    // The Reflect registry
    Reflect public reflect;

    // A map of addresses that are authorised to register and renew names.
    mapping(address=>bool) public controllers;

    // Authorises a controller, who can register and renew domains.
    function addController(address controller) virtual external;

    // Revoke controller permission for an address.
    function removeController(address controller) virtual external;

    // Returns the expiration timestamp of the specified label hash.
    function nameExpires(uint256 id) external view virtual returns(uint, bool);

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) public view virtual returns(bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, bytes32 baseNode, address owner, uint duration, bool permanent) virtual external returns(uint, bool);

    function renew(uint256 id, bytes32 baseNode, uint duration) virtual external returns(uint);

    /**
     * @dev Reclaim ownership of a name in Reflect, if you own it in the registrar.
     */
    function reclaim(uint256 id, bytes32 baseNode, address owner) virtual external;
}

interface LaunchTld {
    /**
     * @dev Returns the price to register.
     * @param condition keccak256 multiple conditions, like payment token address, duration, length, etc.
     * @return The price of this registration.
     */
    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint);

    /**
     * @dev Returns the payment token addresses according to a specific tld.
     * @param tld keccak256 tld.
     * @return The payment token addresses.
     */
    function getSupportedPayment(bytes32 tld) external view returns(address[] memory);

    /**
     * @dev Returns the permanent ownership status of subnode belonged to a tld.
     * @param tld keccak256 tld.
     * @return The permanent ownership status of subnode belonged to a tld
     */
    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool);

    function receivingAddress(bytes32 tld) external view returns(address);
}

contract LaunchTldImplementation {
    using StringUtils for string;

    Reflect public reflectRegistry;
    BaseRegistrar public baseRegistrar ;
    address public registryController;
    mapping(address=>bool) public whitelist;
    bool whitelistEnabled;

    struct TldOwner {
        address owner;
        address receivingAddress;
        bool permanent;
        address[] supportedPayment;
    }
    mapping(bytes32=>TldOwner) public tldToOwner;
    mapping(address=>bytes32) public ownerToTld;

    // A map of conditions that correspond to prices.
    mapping(bytes32=>mapping(bytes32=>uint)) public prices;

    event SetRegistry(address indexed registry);
    event SetBaseRegistrar(address indexed baseRegistrar);
    event UpdateWhitelist(address indexed member, bool indexed enabled);
    event SetReceivingAddress(bytes32 indexed tld, address indexed receivingAddress);
    event SetTld(bytes32 indexed tld, address indexed receivingAddress, bool indexed permanent, bytes32[] condition, uint[] price, address[] payment);

    modifier onlyController {
        require(registryController == msg.sender);
        _;
    }

    constructor(address _registryController) public {
        registryController = _registryController;
        whitelistEnabled = true;
    }

    function setReflectRegistry(Reflect _registry) onlyController public {
        reflectRegistry = _registry;
        emit SetRegistry(address(_registry));
    }

    function setBaseRegistrar(BaseRegistrar _baseRegistrar) onlyController public {
        baseRegistrar = _baseRegistrar;
        emit SetBaseRegistrar(address(_baseRegistrar));
    }

    function updateWhitelist(address member, bool enabled) onlyController public {
        whitelist[member] = enabled;
        emit UpdateWhitelist(member, enabled);
    }

    function setWhitelistEnabled(bool enabled) onlyController public {
        whitelistEnabled = enabled;
    }

    function setTld(string memory tld, address receiveWallet, bytes32[] memory condition, uint[] memory price, address[] memory payment, bool permanent) public {
        require(tld.strlen() == 3);
        if(whitelistEnabled && !whitelist[msg.sender]) {
            revert('Not authorized');
        }
        bytes32 tldHash = keccak256(abi.encodePacked(bytes32(0), keccak256(bytes(tld))));
        if(tldToOwner[tldHash].owner != address(0)) {
            require(tldToOwner[tldHash].owner == msg.sender, 'Not tld owner');
        }
        tldToOwner[tldHash] = TldOwner({owner : msg.sender, receivingAddress : receiveWallet, permanent : permanent, supportedPayment: payment});
        ownerToTld[msg.sender] = tldHash;
        require(condition.length == price.length);
        for(uint i = 0; i < condition.length; i++) {
            prices[tldHash][condition[i]] = price[i];
        }
        require(address(reflectRegistry) != address(0) && address(baseRegistrar) != address(0), 'precondition not set');
        reflectRegistry.setSubnodeRecord(bytes32(0), keccak256(bytes(tld)), address(baseRegistrar), address(0), 0, true);
        emit SetTld(StringToBytes32.stringToBytes32(tld), receiveWallet, permanent, condition, price, payment);
    }

    function setReceiveAddress(address receiveWallet) public {
        require(ownerToTld[msg.sender] != bytes32(0));
        tldToOwner[ownerToTld[msg.sender]].receivingAddress = receiveWallet;
        emit SetReceivingAddress(ownerToTld[msg.sender], receiveWallet);
    }

    function getPrice(bytes32 tld, bytes32 condition) external view returns(uint) {
        return prices[tld][condition];
    }

    function permanentOwnershipOfSubnode(bytes32 tld) external view returns(bool) {
        return tldToOwner[tld].permanent;
    }

    function getSupportedPayment(bytes32 tld) public view returns (address[] memory){
        return tldToOwner[tld].supportedPayment;
    }

    function receivingAddress(bytes32 tld) external view returns(address) {
        return tldToOwner[tld].receivingAddress;
    }

    function getTldToOwner(bytes32 tld) external view returns(TldOwner memory) {
        return tldToOwner[tld];
    }

   


}