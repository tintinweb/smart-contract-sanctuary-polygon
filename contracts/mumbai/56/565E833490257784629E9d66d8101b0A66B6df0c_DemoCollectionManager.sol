// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IDemoCollectionManager.sol";
import "./access/Ownable.sol";

contract DemoCollectionManager is IDemoCollectionManager, Ownable {
    mapping(address => bool) public _operators;
    mapping(string => address) public _demoCollectionTracking;

    modifier onlyOperator() {
        require(_operators[msg.sender] || _operators[tx.origin], "Forbidden");
        _;
    }

    constructor() {
        _operators[msg.sender] = true;
    }

    function setCollectionTracking(
        string calldata id,
        address collectionAddress
    ) external override onlyOperator {
        bytes calldata strBytes = bytes(id);
        require(strBytes.length > 0, "Invalid id");
        require(collectionAddress != address(0), "zero address");
        require(_demoCollectionTracking[id] == address(0), "exist");
        _demoCollectionTracking[id] = collectionAddress;
        emit CollectionCreated(id, collectionAddress);
    }

    function checkCollectionAddress(string calldata id)
        external
        view
        override
        returns (address)
    {
        return _demoCollectionTracking[id];
    }

    function setOperator(address operatorAddress, bool value)
        external
        onlyOwner
    {
        require(
            operatorAddress != address(0),
            "operatorAddress is zero address"
        );
        _operators[operatorAddress] = value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDemoCollectionManager {
    event CollectionCreated(
        string indexed id,
        address indexed collectionAddress
    );

    function setCollectionTracking(
        string calldata id,
        address collectionAddress
    ) external;

    function checkCollectionAddress(string calldata id)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}