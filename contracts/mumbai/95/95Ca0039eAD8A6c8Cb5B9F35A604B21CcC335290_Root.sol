// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface MID {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner_);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner_);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver_);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl_);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner_, address resolver_, uint64 ttl_) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner_, address resolver_, uint64 ttl_) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner_) external returns(bytes32);
    function setResolver(bytes32 node, address resolver_) external;
    function setOwner(bytes32 node, address owner_) external;
    function setTTL(bytes32 node, uint64 ttl_) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner_, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";

contract Controllable is Ownable {
    mapping(address=>bool) public controllers;

    event ControllerChanged(address indexed controller, bool enabled);

    modifier onlyController {
        require(controllers[msg.sender], "only ctrl");
        _;
    }

    function setController(address controller, bool enabled) public onlyOwner {
        controllers[controller] = enabled;
        emit ControllerChanged(controller, enabled);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner {
        require(isOwner(msg.sender), "not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function isOwner(address addr) public view returns (bool) {
        return owner == addr;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../registry/MID.sol";
import "./Ownable.sol";
import "./Controllable.sol";

contract Root is Ownable, Controllable {
    bytes32 constant private ROOT_NODE = bytes32(0);

    bytes4 constant private INTERFACE_META_ID = bytes4(keccak256("supportsInterface(bytes4)"));

    event TLDLocked(bytes32 indexed label);

    MID public mid;
    mapping(bytes32=>bool) public locked;

    constructor(MID _mid) {
        mid = _mid;
    }

    function setSubnodeOwner(bytes32 label, address owner) external onlyController {
        require(!locked[label], "locked");
        mid.setSubnodeOwner(ROOT_NODE, label, owner);
    }

    function setResolver(address resolver) external onlyOwner {
        mid.setResolver(ROOT_NODE, resolver);
    }

    function lock(bytes32 label) external onlyOwner {
        emit TLDLocked(label);
        locked[label] = true;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == INTERFACE_META_ID;
    }
}