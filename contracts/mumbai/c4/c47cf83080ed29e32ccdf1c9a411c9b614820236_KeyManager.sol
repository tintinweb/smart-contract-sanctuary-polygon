// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract KeyManager {
    struct Key {
        uint id;
        string ipfsHash;
        bool isDeleted;
    }

    event KeyAdded(uint id, string ipfsHash, address indexed owner);
    event KeyUpdated(uint id, string ipfsHash, address indexed owner);
    event KeyDeleted(uint id, address indexed owner);

    mapping(address => Key[]) keys;
    mapping(address => mapping(string => bool)) isIpfsHashExists;

    modifier onlyUniqueIpfsHash(string calldata _ipfsHash) {
        require(
            bytes(_ipfsHash).length == 46,
            "KeyManger: Actual IPFS hash is required!"
        );
        require(
            !isIpfsHashExists[msg.sender][_ipfsHash],
            "KeyManger: IPFS hash already exists!"
        );
        _;
    }

    modifier onlyExistingKey(uint _id) {
        require(
            _id < keys[msg.sender].length,
            "KeyManager: Key does not exist!"
        );
        _;
    }

    function addKey(string calldata _ipfsHash)
        public
        onlyUniqueIpfsHash(_ipfsHash)
    {
        keys[msg.sender].push(Key(keys[msg.sender].length, _ipfsHash, false));
        isIpfsHashExists[msg.sender][_ipfsHash] = true;
        emit KeyAdded(keys[msg.sender].length - 1, _ipfsHash, msg.sender);
    }

    function updateKey(uint _id, string calldata _ipfsHash)
        public
        onlyUniqueIpfsHash(_ipfsHash)
        onlyExistingKey(_id)
    {
        keys[msg.sender][_id].ipfsHash = _ipfsHash;
        isIpfsHashExists[msg.sender][_ipfsHash] = true;
        emit KeyUpdated(_id, _ipfsHash, msg.sender);
    }

    function softDeleteKey(uint _id) public onlyExistingKey(_id) {
        keys[msg.sender][_id].isDeleted = true;
        emit KeyDeleted(_id, msg.sender);
    }

    function getMyKeys() public view returns (Key[] memory) {
        return keys[msg.sender];
    }
}