//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAddressRegistry.sol";


contract AddressRegistry is IAddressRegistry, Ownable {

    mapping(string => address) _fromTag;
    mapping(address => bool) authorized;

    event Authorized(address _target);
    event AuthorizedRemoved(address _target);
    event Tagged(string _tag, address _target);
    event TagRemoved(string _tag, address _target);


    modifier notZeroAddress (address _target)
    {
        require(_target != address(0), "REGISTRY: ADDRESS 0");
        _;
    }

    function isAuthorized(address _target)
        public
        view
        returns(bool)
    {
        return authorized[_target];
    }

    function removeAuthorized(address _target)
        public
        onlyOwner
        notZeroAddress(_target)
    {
        require(authorized[_target] == true, "REGISTRY: NOT_EXISTANT");
        authorized[_target] = false;

        emit AuthorizedRemoved(_target);
    }

    function addAuthorized(address _target)
        public
        onlyOwner
        notZeroAddress(_target)
    {
        require(!authorized[_target], "REGISTRY: ALREADY_ADDED");
        authorized[_target] = true;

        emit Authorized(_target);
    }

    function removeTag(string calldata _tag)
        public
        onlyOwner
    {
        address auth = _fromTag[_tag];

        emit TagRemoved(_tag, auth);
    }

    function addTag(string calldata _tag, address _target)
        public
        onlyOwner
    {
        require(isAuthorized(_target), "REGISTRY: TARGET_NOT_AUTH");
        _fromTag[_tag] = _target;

        emit Tagged(_tag, _target);
    }

    function getFromTag(string calldata _tag)
        public
        view
        returns(address tagged)
    {
        tagged = _fromTag[_tag];
        require(tagged != address(0), "REGISTRY: TAGGED_NON_EXISTANT");
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >= 0.8.9;

interface IAddressRegistry {

    function isAuthorized(address _target) external returns (bool);
    function getFromTag(string memory _title) external view returns (address);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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