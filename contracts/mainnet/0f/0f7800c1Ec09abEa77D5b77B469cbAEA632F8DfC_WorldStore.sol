// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../access/AccessControl.sol";

contract WorldStore is AccessControl {
    // key: definition name
    string[] public definitionKeys;

    // key: worldId, value: (key: key, value: contract address)
    mapping(uint256 => mapping(string => address)) private _definitions;

    // key: data contract name
    string[] public dataContractKeys;

    // key: worldId, value: (key: key, value: contract address)
    mapping(uint256 => mapping(string => address)) private _dataContract;


    constructor(address game)
    AccessControl(game) {
    }

    function getDefinition(uint256 worldId, string memory key) public view returns(address) {
        return _definitions[worldId][key];
    }

    function setDefinition(uint256 worldId, string memory key, address definition) public onlyGameOwner {
        require(_validDefinitionKey(key), "wrong key");

        _definitions[worldId][key] = definition;
    }

    function setDefinitionKeys(string[] memory keys) public onlyGameOwner {
        definitionKeys = keys;
    }

    function _validDefinitionKey(string memory key) private view returns(bool) {
        for (uint256 i; i < definitionKeys.length; i++) {
            if (keccak256(abi.encodePacked(definitionKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }

    function getDataContract(uint256 worldId, string memory key) public view returns(address) {
        return _dataContract[worldId][key];
    }

    function setDataContract(uint256 worldId, string memory key, address definition) public onlyGameOwner {
        require(_validDataContractKey(key), "wrong key");

        _dataContract[worldId][key] = definition;
    }

    function setDataContractKeys(string[] memory keys) public onlyGameOwner {
        dataContractKeys = keys;
    }

    function _validDataContractKey(string memory key) private view returns(bool) {
        for (uint256 i; i < dataContractKeys.length; i++) {
            if (keccak256(abi.encodePacked(dataContractKeys[i])) == keccak256(abi.encodePacked(key))) {
                return true;
            }
        }

        return false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IGameAccess.sol";

contract AccessControl is Ownable {
    IGameAccess internal _gameAccess;

    constructor(address gameAddress) {
        _gameAccess = IGameAccess(gameAddress);
    }

    modifier onlyGameOwner() {
        bool isGameAdmin = checkAccess(msg.sender, _gameAccess.getGameAdminAddresses());
        bool isInternal = checkAccess(msg.sender, _gameAccess.getInterfaceAddresses());
        bool isOwner = msg.sender == owner();
        bool isGame = msg.sender == address(_gameAccess);

        require(isGameAdmin || isInternal || isOwner || isGame, "WorldAccess: caller is not GameOwner");
        _;
    }

    function setGameAddress(address gameAddress) public virtual onlyGameOwner {
        _gameAccess = IGameAccess(gameAddress);
    }

    function checkAccess(address sender, address[] memory addresses) internal view returns(bool) {
        bool result = false;
        for (uint256 i; i < addresses.length; i++) {
            if (addresses[i] == sender) {
                result = true;
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGameAccess {
    function getInterfaceAddresses() external view returns(address[] memory);
    function getWorldOwnerAddresses(uint256 worldId) external view returns(address[] memory);
    function getWorldAdminAddresses(uint256 worldId) external view returns(address[] memory);
    function getGameAdminAddresses() external view returns(address[] memory);
    function getTokenOwnerAddress(uint256 worldId, uint256 tokenId) external view returns(address);
    function getItemPackNFTAddresses(uint256 worldId) external view returns(address[] memory);
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