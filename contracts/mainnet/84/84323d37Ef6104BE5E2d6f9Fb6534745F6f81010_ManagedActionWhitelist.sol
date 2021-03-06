// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IActionWhitelist } from "./IActionWhitelist.sol";

contract ManagedActionWhitelist is Ownable, IActionWhitelist
{
	mapping(address => bool) private modules_;
	mapping(address => mapping(bytes4 => bool)) private actions_;

	function checkAction(address _module, bytes4 _selector) external view override returns (bool _whitelisted)
	{
		return modules_[_module] || actions_[_module][_selector];
	}

	function updateModule(address _module, bool _whitelisted) external onlyOwner
	{
		modules_[_module] = _whitelisted;
	}

	function updateModules(address[] calldata _modules, bool _whitelisted) external onlyOwner
	{
		for (uint256 _i = 0; _i < _modules.length; _i++) {
			modules_[_modules[_i]] = _whitelisted;
		}
	}

	function updateAction(address _module, bytes4 _selector, bool _whitelisted) external onlyOwner
	{
		actions_[_module][_selector] = _whitelisted;
	}

	function updateActions(address _module, bytes4[] calldata _selectors, bool _whitelisted) external onlyOwner
	{
		for (uint256 _i = 0; _i < _selectors.length; _i++) {
			actions_[_module][_selectors[_i]] = _whitelisted;
		}
	}

	function updateActions(address[] calldata _modules, bytes4[] calldata _selectors, bool _whitelisted) external onlyOwner
	{
		require(_modules.length == _selectors.length, "length mismatch");
		for (uint256 _i = 0; _i < _selectors.length; _i++) {
			actions_[_modules[_i]][_selectors[_i]] = _whitelisted;
		}
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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

interface IActionWhitelist
{
	function checkAction(address _module, bytes4 _selector) external view returns (bool _whitelisted);
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