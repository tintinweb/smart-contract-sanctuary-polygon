pragma solidity ^0.7.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ManagerStore is Ownable {
    struct Manager {
        address managerAddress;
        string ipfsHash;
        bool isAuthorized;
    }

    mapping(address => Manager) public managersMap;
    address[] public authorizedManagers;
    address[] public allManagers;

    event ManagerRegistered(address indexed managerAddress, string ipfsHash);
    event ManagerAuthorized(address indexed managerAddress);
    event ManagerRemoved(address indexed managerAddress);

    function registerManager(string memory ipfsHash) public {
        if (managersMap[msg.sender].managerAddress != msg.sender) {
            allManagers.push(msg.sender);
        } else if (managersMap[msg.sender].isAuthorized == true) {
            // remove manager from authorizedManagers list if it is already authorized
            _deauthorizeManager(msg.sender);
        }
        managersMap[msg.sender] = Manager(msg.sender, ipfsHash, false);

        emit ManagerRegistered(msg.sender, ipfsHash);
    }

    function authorizeManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "Invalid manager address");
        require(!managersMap[managerAddress].isAuthorized, "Manager already authorized");

        managersMap[managerAddress].isAuthorized = true;
        authorizedManagers.push(managerAddress);

        emit ManagerAuthorized(managerAddress);
    }

    function deauthorizeManager(address managerAddress) public onlyOwner {
        require(managerAddress != address(0), "Invalid manager address");
        require(managersMap[managerAddress].isAuthorized, "Manager not authorized");
        _deauthorizeManager(managerAddress);
    }

    function _deauthorizeManager(address managerAddress) private {
        managersMap[managerAddress].isAuthorized = false;

        for (uint256 i = 0; i < authorizedManagers.length; i++) {
            if (authorizedManagers[i] == managerAddress) {
                authorizedManagers[i] = authorizedManagers[authorizedManagers.length - 1];
                authorizedManagers.pop();
                break;
            }
        }

        emit ManagerRemoved(managerAddress);
    }

    function getAllAuthorizedManagersWithHashes() public view returns (Manager[] memory) {
        uint256 authorizedCount = authorizedManagers.length;
        Manager[] memory result = new Manager[](authorizedCount);

        for (uint256 i = 0; i < authorizedCount; i++) {
            result[i] = managersMap[authorizedManagers[i]];
        }

        return result;
    }

    function getAllManagersWithHashes() public view returns (Manager[] memory) {
        uint256 allCount = allManagers.length;
        Manager[] memory result = new Manager[](allCount);

        for (uint256 i = 0; i < allCount; i++) {
            result[i] = managersMap[allManagers[i]];
        }

        return result;
    }

    function getAllManagers() public view returns (address[] memory) {
        return allManagers;
    }

    function getAllAuthorizedManagers() public view returns (address[] memory) {
        return authorizedManagers;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}