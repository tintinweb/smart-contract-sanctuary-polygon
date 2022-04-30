// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @dev Custom imports
 */
import './TokenWhitelist.sol';

/**
 * @title OpenQTokenWhitelist
 * @dev OpenQTokenWhitelist provides the list of verified token addresses
 */
contract OpenQTokenWhitelist is TokenWhitelist {
    /**
     * INITIALIZATION
     */

    /**
     * @dev Initializes OpenQTokenWhitelist with maximum token address limit to prevent out-of-gas errors
     * @param _tokenAddressLimit Maximum number of token addresses allowed
     */
    constructor(uint256 _tokenAddressLimit) TokenWhitelist() {
        TOKEN_ADDRESS_LIMIT = _tokenAddressLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/**
 * @dev Third party
 */
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @title OpenQTokenWhitelist
 * @dev OpenQTokenWhitelist provides the list of verified token addresses
 */
abstract contract TokenWhitelist is Ownable {
    /**
     * INITIALIZATION
     */

    uint256 public TOKEN_ADDRESS_LIMIT;
    uint256 public tokenCount;
    mapping(address => bool) public whitelist;

    /**
     * UTILITY
     */

    /**
     * @dev Determines if a tokenAddress is whitelisted
     * @param tokenAddress The token address in question
     * @return bool Whether or not tokenAddress is whitelisted
     */
    function isWhitelisted(address tokenAddress) external view returns (bool) {
        return whitelist[tokenAddress];
    }

    /**
     * @dev Adds tokenAddress to the whitelist
     * @param tokenAddress The token address to add
     */
    function addToken(address tokenAddress) external onlyOwner {
        require(tokenCount <= TOKEN_ADDRESS_LIMIT, 'TOO_MANY_TOKEN_ADDRESSES');
        require(!this.isWhitelisted(tokenAddress), 'TOKEN_ALREADY_WHITELISTED');
        whitelist[tokenAddress] = true;
        tokenCount++;
    }

    /**
     * @dev Removes tokenAddress to the whitelist
     * @param tokenAddress The token address to remove
     */
    function removeToken(address tokenAddress) external onlyOwner {
        require(
            this.isWhitelisted(tokenAddress),
            'TOKEN_NOT_ALREADY_WHITELISTED'
        );
        whitelist[tokenAddress] = false;
        tokenCount--;
    }

    /**
     * @dev Updates the tokenAddressLimit
     * @param newTokenAddressLimit The new value for TOKEN_ADDRESS_LIMIT
     */
    function setTokenAddressLimit(uint256 newTokenAddressLimit)
        external
        onlyOwner
    {
        TOKEN_ADDRESS_LIMIT = newTokenAddressLimit;
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