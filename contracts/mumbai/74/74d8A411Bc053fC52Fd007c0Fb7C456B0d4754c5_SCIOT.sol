/**
 *Submitted for verification at polygonscan.com on 2023-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Developed by: [email protected]

contract SCIOT {

    // SCIOT -> Smart Contract-based IOT system 
    
    event Connect(Connection connection, bytes key);
    // An event that the server is continuously listening to

    address public owner;
    // The owner of the contract

    uint256 public failedConnectionLimit = 3;
    // Number of times a device can fail before getting blacklisted

    bytes32 public constant CONNECTION_TYPEHASH = 
        keccak256(
            "Connection(address sender,address recipient,uint256 deadline,string action)"
        );

    bytes32 public constant EIP712_TYPEHASH = 
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    bytes32 public constant NAME_TYPEHASH = 
        keccak256(
            bytes("Smart Home")
        );

    bytes32 public constant VERSION_TYPEHASH = 
        keccak256(
            bytes("1")
        );

    struct Connection {
        address sender;
        address recipient;
        uint256 deadline;
        string action;
    }

    mapping(address => mapping(uint256 => Connection)) public _connections;
    mapping(address => mapping(uint256 => bytes)) public keys;
    mapping(address => uint256) public _numberOfConnections;
    // A tree-like structure connection, whereby the sender is the tree, the receivers are the branch and connection data is stored along side the receiver

    mapping(address => uint256) public _failedConnections; 
    // Number of times a device has failed to connect

    
    constructor() {
        owner = msg.sender;
        // The constructor is ran when the contract is created, so the creator of the contract becomes the owner of the contract
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
        // Checks whether the caller of the function is in fact the owner or not
    }

    function createConnection(
        Connection memory connection,
        bytes memory key
    ) 
        public returns (uint256 receiverId) 
    {
        address sender = connection.sender;

        address signer = recoverAddress(connection, key);
        // Use the hash of the 'connection' and the signature to verify that the signature belongs to the owner

        require(signer == owner, "signer and owner do not match");
        // Will revert if signature doesn't belong to owner

        receiverId = _numberOfConnections[sender];
        // Declares a new receiver Id to create a 'branch' for the recipient

        _connections[sender][receiverId] = connection;
        // Adds connection information to the 'branch' (the sender)

        keys[sender][receiverId] = key;
        // Storing the key in the same branch

        _numberOfConnections[sender] = receiverId + 1;
        // Increases number of connections by one for later usage

        // Returns receiver Id to owner for future reference
    }

    function changeConnection(
        Connection memory connection,
        uint256 receiverId,
        bytes memory newKey
    ) 
        public onlyOwner
    {
        _connections[connection.sender][receiverId] = connection;
        keys[connection.sender][receiverId] = newKey;
        // Changes the recipient, deadline and signature of the 'branch' using receiver Id

    }

    function connect(address receiver) public returns (bool canConnect) {

        uint256 receiverId;
        address sender = msg.sender;
        // Setting variables for simpler reference

        require(
            _failedConnections[sender] < failedConnectionLimit, 
            "Caller has been blacklisted"
        );
        // Ensures the caller of the function is not blacklisted

        (canConnect, receiverId) = isConnected(sender, receiver);
        // Using the sender and receiver we locate the 'branch'. If the branch exists, then the variable canConnect becomes true otherwise false. 

        Connection memory connection = _connections[sender][receiverId];
        bytes memory key = keys[sender][receiverId];
        // We restore the data of the 'branch'

        address signer = recoverAddress(connection, key);
        // We hash the data to verify the signature that exists in the branch
        
        if (
            canConnect && 
            connection.deadline >= block.timestamp && 
            signer == owner
        ) { 
            emit Connect(connection, key);
            // If canConnect is true AND deadline has not passed yet AND signature belongs to owner then emit an event called Connect for the server to be triggered
        } else {
            _failedConnections[sender]++;
            // Otherwise increase the number of failed connections of the caller
        }

    }

    function isConnected(
        address sender, 
        address recipient
    ) 
        internal view returns (bool, uint256) 
    {
        uint256 receiverId;
        bool canConnect;
        for (uint256 i = 0; i < _numberOfConnections[sender]; i++) {
            if (_connections[sender][i].recipient == recipient) {
                receiverId = i;
                canConnect = true;
            }
        }
        return (canConnect, receiverId);
        // A function used to return the receiver Id or 'branch' using the sender and recipient
        // If a branch exists, it will turn success into true, otherwise false
    }

    function recoverAddress(
        Connection memory connection,
        bytes memory key
    )
        public view returns (address)
    {
        bytes32 _hash = getHash(
            keccak256(abi.encode(
                CONNECTION_TYPEHASH,
                connection.sender,
                connection.recipient,
                connection.deadline,
                keccak256(bytes(connection.action))
            ))
        );

        return recover(_hash, key);
    }

    function getHash(
        bytes32 hashStruct
    )
        internal view returns (bytes32) 
    {
        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                EIP712_TYPEHASH,
                NAME_TYPEHASH,
                VERSION_TYPEHASH,
                block.chainid,
                address(this)
            )
        );

        return keccak256(
            abi.encodePacked(
                "\x19\x01", 
                eip712DomainHash, 
                hashStruct
            )
        );
    }

    function recover(
        bytes32 _hash, 
        bytes memory _signature
    )
        internal pure returns (address)
    {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        return ecrecover(_hash, v, r, s);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setNewFailedLimit(uint256 newLimit) public onlyOwner {
        failedConnectionLimit = newLimit;
    }

    function whitelist(address blacklistedDevice) public onlyOwner {
        _failedConnections[blacklistedDevice] = 0;
    }
}