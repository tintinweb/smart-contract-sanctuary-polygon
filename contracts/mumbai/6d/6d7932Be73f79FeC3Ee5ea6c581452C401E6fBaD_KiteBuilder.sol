// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IKiteFighter {
    function mintGenOne(address, string memory) external payable;
}

interface IKiteComponent {
    function dappMint(address, uint256, uint256) external payable;
    function burnBatch(address, uint256[] memory, uint256[] memory) external;
}

contract KiteBuilder is Ownable {
    address public admin;

    address public kiteComponentContractAddress;
    address public kiteFighterContractAddress;

    // constructor
    constructor (
        address _admin,
        address _kiteFighterContractAddress,
        address _kiteComponentContractAddress
    ) public {
        admin = _admin;
        kiteComponentContractAddress = _kiteComponentContractAddress;
        kiteFighterContractAddress = _kiteFighterContractAddress;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function setContractAddresses(address _kiteFighterContractAddress, address _kiteComponentContractAddress) public onlyOwner {
        kiteComponentContractAddress = _kiteComponentContractAddress;
        kiteFighterContractAddress = _kiteFighterContractAddress;
    }

    // Assumes the components are validated
    function buildKite(uint256[] memory componentIds, uint256[] memory componentValues, address to, string memory url) public {
        require(msg.sender == admin, "Only admin can build a kite, nice try!");
        require(kiteComponentContractAddress != address(0), "Kite component contract address not set");
        require(kiteFighterContractAddress != address(0), "Kite component contract address not set");

        IKiteComponent(kiteComponentContractAddress).burnBatch(to, componentIds, componentValues);
        IKiteFighter(kiteFighterContractAddress).mintGenOne(to, url);
    }

    function mintComponent(address to, uint256 componentId, uint256 amount) public {
        require(msg.sender == admin, "Only admin can build a kite, nice try!");
        require(kiteComponentContractAddress != address(0), "Kite component contract address not set");
        IKiteComponent(kiteComponentContractAddress).dappMint(to, componentId, amount);
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