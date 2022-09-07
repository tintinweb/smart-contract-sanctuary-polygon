// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PublicResolver.sol";

contract ENSRegistry is ENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32 => Record) records;
    mapping(address => mapping(address => bool)) operators;
    mapping(address => bytes32) public nodeAddress;

    // Permits modifications only by the owner of the specified node.
    modifier authorised(bytes32 node) {
        address _owner = records[node].owner;
        require(_owner == msg.sender || operators[_owner][msg.sender]);
        _;
    }

    modifier isexist(bytes32 node) {
        address _owner = records[node].owner;
        require(_owner == address(0), "already exist");
        _;
    }

    /**
     * @dev Constructs a new ENS registrar.
     */
    constructor() {
        records[0x0].owner = msg.sender;
    }

    /***
     * @dev Sets the record for a node.
     * @param node The node to update.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setRecord(
        bytes32 node,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) internal {
        _setResolverAndTTL(node, _resolver, _ttl);
        _setOwner(node, _owner);
    }

    /***
     * @dev Sets the record for a subnode.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     * @param resolver The address of the resolver.
     * @param ttl The TTL in seconds.
     */
    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address _owner,
        address _resolver,
        uint64 _ttl
    ) external {
        bytes32 subnode = setSubnodeOwner(node, label, _owner);
        _setResolverAndTTL(subnode, _resolver, _ttl);
    }

    /***
     * @dev Transfers ownership of a node to a new address. May only be called by the current owner of the node.
     * @param node The node to transfer ownership of.
     * @param owner The address of the new owner.
     */
    function setOwner(bytes32 node, address _owner)
        public
        override
        authorised(node)
    {
        _setOwner(node, _owner);
        nodeAddress[_owner] = node;
        emit Transfer(node, _owner);
    }

    /***
     * @dev Transfers ownership of a subnode keccak256(node, label) to a new address. May only be called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param owner The address of the new owner.
     */
    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address _owner
    ) public override authorised(node) returns (bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        _setOwner(subnode, _owner);
        emit NewOwner(node, label, _owner);
        return subnode;
    }

    function Factory(
        bytes32 node,
        address _owner,
        uint64 _ttl
    ) external isexist(node) {
        PublicResolver _resolver = new PublicResolver(ENS(address(this)));
        setRecord(node, _owner, address(_resolver), _ttl);
    }

    /***
     * @dev Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address _resolver)
        public
        override
        authorised(node)
    {
        emit NewResolver(node, address(_resolver));
        records[node].resolver = address(_resolver);
    }

    /***
     * @dev Sets the TTL for the specified node.
     * @param node The node to update.
     * @param ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 _ttl)
        public
        override
        authorised(node)
    {
        emit NewTTL(node, _ttl);
        records[node].ttl = _ttl;
    }

    /**
     * @dev Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`'s ENS records. Emits the ApprovalForAll event.
     * @param operator Address to add to the set of authorized operators.
     * @param approved True if the operator is approved, false to revoke approval.
     */
    function setApprovalForAll(address operator, bool approved) external {
        operators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param node The specified node.
     * @return address of the owner.
     */
    function owner(bytes32 node)
        public
        view
        virtual
        override
        returns (address)
    {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the address of the resolver for the specified node.
     * @param node The specified node.
     * @return address of the resolver.
     */
    function resolver(bytes32 node)
        public
        view
        virtual
        override
        returns (address)
    {
        return records[node].resolver;
    }

    /**
     * @dev Returns the TTL of a node, and any records associated with it.
     * @param node The specified node.
     * @return ttl of the node.
     */
    function ttl(bytes32 node) public view virtual override returns (uint64) {
        return records[node].ttl;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param node The specified node.
     * @return Bool if record exists
     */
    function recordExists(bytes32 node) public view returns (bool) {
        return records[node].owner != address(0x0);
    }

    /***
     * @dev Query if an address is an authorized operator for another address.
     * @param owner The address that owns the records.
     * @param operator The address that acts on behalf of the owner.
     * @return True if `operator` is an approved operator for `owner`, false otherwise.
     */
    function isApprovedForAll(address _owner, address operator)
        external
        view
        override
        returns (bool)
    {
        return operators[_owner][operator];
    }

    function _setOwner(bytes32 node, address _owner) internal virtual {
        records[node].owner = _owner;
    }

    function _setResolverAndTTL(
        bytes32 node,
        address _resolver,
        uint64 _ttl
    ) internal {
        if (_resolver != records[node].resolver) {
            records[node].resolver = _resolver;
            emit NewResolver(node, _resolver);
        }

        if (_ttl != records[node].ttl) {
            records[node].ttl = _ttl;
            emit NewTTL(node, _ttl);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// File: contracts/ENS.sol

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// File: contracts/PublicResolver.sol

/**
 * A simple resolver anyone can use; only allows the owner of a node to set its
 * address.
 */
contract PublicResolver {
    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexedKey, string key);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string => string) text;
        mapping(uint256 => bytes) abis;
    }

    ENS ens;

    mapping(bytes32 => Record) records;

    modifier only_owner(bytes32 node) {
        require(ens.owner(node) == msg.sender);
        _;
    }

    /**
     * Constructor.
     * @param ensAddr The ENS registrar contract.
     */
    constructor(ENS ensAddr) {
        ens = ensAddr;
    }

    /***
     * Sets the address associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param addr The address to set.
     */
    function setAddr(bytes32 node, address _addr) public only_owner(node) {
        records[node].addr = _addr;
        emit AddrChanged(node, _addr);
    }

    /**
     * Sets the content hash associated with an ENS node.
     * May only be called by the owner of that node in the ENS registry.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The node to update.
     * @param hash The content hash to set
     */
    function setContent(bytes32 node, bytes32 hash) public only_owner(node) {
        records[node].content = hash;
        emit ContentChanged(node, hash);
    }

    /***
     * Sets the name associated with an ENS node, for reverse records.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param name The name to set.
     */
    function setName(bytes32 node, string memory _name)
        public
        only_owner(node)
    {
        records[node].name = _name;
        emit NameChanged(node, _name);
    }

    /**
     * Sets the ABI associated with an ENS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(
        bytes32 node,
        uint256 contentType,
        bytes memory data
    ) public only_owner(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        records[node].abis[contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Sets the text data associated with an ENS node and key.
     * May only be called by the owner of that node in the ENS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(
        bytes32 node,
        string memory key,
        string memory value
    ) public only_owner(node) {
        records[node].text[key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string memory key)
        public
        view
        returns (string memory)
    {
        return records[node].text[key];
    }

    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes)
        public
        view
        returns (uint256 contentType, bytes memory data)
    {
        Record storage record = records[node];
        for (contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if (
                (contentType & contentTypes) != 0 &&
                record.abis[contentType].length > 0
            ) {
                data = record.abis[contentType];
            }
        }
        contentType = 0;
    }

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) public view returns (string memory) {
        return records[node].name;
    }

    /**
     * Returns the content hash associated with an ENS node.
     * Note that this resource type is not standardized, and will likely change
     * in future to a resource type based on multihash.
     * @param node The ENS node to query.
     * @return The associated content hash.
     */
    function content(bytes32 node) public view returns (bytes32) {
        return records[node].content;
    }

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address) {
        return records[node].addr;
    }

    /**
     * Returns true if the resolver implements the interface specified by the provided hash.
     * @param interfaceID The ID of the interface to check for.
     * @return True if the contract implements the requested interface.
     */
    function supportsInterface(bytes4 interfaceID) public pure returns (bool) {
        return
            interfaceID == ADDR_INTERFACE_ID ||
            interfaceID == CONTENT_INTERFACE_ID ||
            interfaceID == NAME_INTERFACE_ID ||
            interfaceID == ABI_INTERFACE_ID ||
            interfaceID == PUBKEY_INTERFACE_ID ||
            interfaceID == TEXT_INTERFACE_ID ||
            interfaceID == INTERFACE_META_ID;
    }
}