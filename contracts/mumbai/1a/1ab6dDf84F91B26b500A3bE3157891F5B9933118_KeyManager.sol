// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract KeyManager is ERC2771Context {
    address public trustedForwarder;

    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {
        trustedForwarder = _trustedForwarder;
    }

    struct Key {
        uint id;
        string ipfsHash;
        bool isDeleted;
    }

    event KeyAdded(uint id, string ipfsHash, address indexed owner);
    event KeyUpdated(uint id, string ipfsHash, address indexed owner);
    event KeyDeleted(uint id, address indexed owner);

    mapping(address => Key[]) keys;
    mapping(string => bool) isIpfsHashExists;

    modifier onlyUniqueIpfsHash(string calldata _ipfsHash) {
        require(
            bytes(_ipfsHash).length == 46,
            "KeyManger: Actual IPFS hash is required!"
        );
        require(
            !isIpfsHashExists[_ipfsHash],
            "KeyManger: IPFS hash already exists!"
        );
        _;
    }

    modifier onlyExistingKey(uint _id) {
        require(
            _id < keys[_msgSender()].length,
            "KeyManager: Key does not exist!"
        );
        _;
    }

    function addKey(
        string calldata _ipfsHash
    ) public onlyUniqueIpfsHash(_ipfsHash) {
        keys[_msgSender()].push(
            Key(keys[_msgSender()].length, _ipfsHash, false)
        );
        isIpfsHashExists[_ipfsHash] = true;
        emit KeyAdded(keys[_msgSender()].length - 1, _ipfsHash, _msgSender());
    }

    function updateKey(
        uint _id,
        string calldata _ipfsHash
    ) public onlyUniqueIpfsHash(_ipfsHash) onlyExistingKey(_id) {
        keys[_msgSender()][_id].ipfsHash = _ipfsHash;
        isIpfsHashExists[_ipfsHash] = true;
        emit KeyUpdated(_id, _ipfsHash, _msgSender());
    }

    function softDeleteKey(uint _id) public onlyExistingKey(_id) {
        keys[_msgSender()][_id].isDeleted = true;
        emit KeyDeleted(_id, _msgSender());
    }

    function getMyKeys() public view returns (Key[] memory) {
        return keys[_msgSender()];
    }
}