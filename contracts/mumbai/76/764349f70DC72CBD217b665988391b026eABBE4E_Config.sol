/*
Config

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IConfig.sol";

contract Config is IConfig, Ownable {
    // events
    event ConfigUpdated(bytes32 indexed key, uint256 previous, uint256 updated);

    // data
    mapping(bytes32 => uint256) private _config;

    /**
     * @inheritdoc IConfig
     */
    function setUint256(bytes32 key, uint256 value) external onlyOwner {
        emit ConfigUpdated(key, _config[key], value);
        _config[key] = value;
    }

    /**
     * @inheritdoc IConfig
     */
    function setAddress(bytes32 key, address value) external onlyOwner {
        uint256 val = uint256(uint160(value));
        emit ConfigUpdated(key, _config[key], val);
        _config[key] = val;
    }

    /**
     * @inheritdoc IConfig
     */
    function getUint256(bytes32 key) external view returns (uint256) {
        return _config[key];
    }

    /**
     * @inheritdoc IConfig
     */
    function getAddress(bytes32 key) external view returns (address) {
        return address(uint160(_config[key]));
    }
}

/*
IConfig

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

/**
 * @title Config interface
 *
 * @notice this defines the interface for the global config contract
 */
interface IConfig {
    /**
     * @notice set uint256 parameter
     * @param key parameter key
     * @param value parameter value
     */
    function setUint256(bytes32 key, uint256 value) external;

    /**
     * @notice set address parameter
     * @param key parameter key
     * @param value parameter value
     */
    function setAddress(bytes32 key, address value) external;

    /**
     * @notice get uint256 parameter
     * @param key parameter key
     * @return value parameter value
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice get address parameter
     * @param key parameter key
     * @return value parameter value
     */
    function getAddress(bytes32 key) external view returns (address);
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}