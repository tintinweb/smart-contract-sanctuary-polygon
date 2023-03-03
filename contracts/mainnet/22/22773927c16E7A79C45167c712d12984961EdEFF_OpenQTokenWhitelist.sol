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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

/// @title Errors
/// @author FlacoJones
/// @notice Revert message constants
library Errors {
    string constant BOUNTY_ALREADY_EXISTS = 'BOUNTY_ALREADY_EXISTS';
    string constant CALLER_NOT_ISSUER = 'CALLER_NOT_ISSUER';
    string constant CALLER_NOT_ISSUER_OR_ORACLE = 'CALLER_NOT_ISSUER_OR_ORACLE';
    string constant CONTRACT_NOT_CLOSED = 'CONTRACT_NOT_CLOSED';
    string constant CONTRACT_ALREADY_CLOSED = 'CONTRACT_ALREADY_CLOSED';
    string constant TOKEN_NOT_ACCEPTED = 'TOKEN_NOT_ACCEPTED';
    string constant NOT_A_COMPETITION_CONTRACT = 'NOT_A_COMPETITION_CONTRACT';
    string constant NOT_A_TIERED_FIXED_BOUNTY = 'NOT_A_TIERED_FIXED_BOUNTY';
    string constant TOKEN_TRANSFER_IN_OVERFLOW = 'TOKEN_TRANSFER_IN_OVERFLOW';
    string constant NOT_AN_ONGOING_CONTRACT = 'NOT_AN_ONGOING_CONTRACT';
    string constant NO_EMPTY_BOUNTY_ID = 'NO_EMPTY_BOUNTY_ID';
    string constant NO_EMPTY_ORGANIZATION = 'NO_EMPTY_ORGANIZATION';
    string constant ZERO_VOLUME_SENT = 'ZERO_VOLUME_SENT';
    string constant CONTRACT_IS_CLOSED = 'CONTRACT_IS_CLOSED';
    string constant TIER_ALREADY_CLAIMED = 'TIER_ALREADY_CLAIMED';
    string constant DEPOSIT_ALREADY_REFUNDED = 'DEPOSIT_ALREADY_REFUNDED';
    string constant CALLER_NOT_FUNDER = 'CALLER_NOT_FUNDER';
    string constant NOT_A_TIERED_BOUNTY = 'NOT_A_TIERED_BOUNTY';
    string constant NOT_A_FIXED_TIERED_BOUNTY = 'NOT_A_FIXED_TIERED_BOUNTY';
    string constant PREMATURE_REFUND_REQUEST = 'PREMATURE_REFUND_REQUEST';
    string constant NO_ZERO_ADDRESS = 'NO_ZERO_ADDRESS';
    string constant CONTRACT_IS_NOT_CLAIMABLE = 'CONTRACT_IS_NOT_CLAIMABLE';
    string constant TOO_MANY_TOKEN_ADDRESSES = 'TOO_MANY_TOKEN_ADDRESSES';
    string constant NO_ASSOCIATED_ADDRESS = 'NO_ASSOCIATED_ADDRESS';
    string constant ADDRESS_LACKS_KYC = 'ADDRESS_LACKS_KYC';
    string constant TOKEN_NOT_ALREADY_WHITELISTED =
        'TOKEN_NOT_ALREADY_WHITELISTED';
    string constant ETHER_SENT = 'ETHER_SENT';
    string constant INVALID_STRING = 'INVALID_STRING';
    string constant TOKEN_ALREADY_WHITELISTED = 'TOKEN_ALREADY_WHITELISTED';
    string constant CLAIMANT_NOT_TIER_WINNER = 'CLAIMANT_NOT_TIER_WINNER';
    string constant INVOICE_NOT_COMPLETE = 'INVOICE_NOT_COMPLETE';
    string constant UNKNOWN_BOUNTY_TYPE = 'UNKNOWN_BOUNTY_TYPE';
    string constant SUPPORTING_DOCS_NOT_COMPLETE =
        'SUPPORTING_DOCS_NOT_COMPLETE';
    string constant EXPIRATION_NOT_GREATER_THAN_ZERO =
        'EXPIRATION_NOT_GREATER_THAN_ZERO';
    string constant PAYOUT_SCHEDULE_MUST_ADD_TO_100 =
        'PAYOUT_SCHEDULE_MUST_ADD_TO_100';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import './TokenWhitelist.sol';

/// @title OpenQTokenWhitelist
/// @author FlacoJones
/// @notice OpenQTokenWhitelist provides the list of verified token addresses
/// @dev Whitelisting and token address limit is implemented primarily as a means of preventing out-of-gas exceptions when looping over funded addresses for payouts
contract OpenQTokenWhitelist is TokenWhitelist {
    /// @notice Initializes OpenQTokenWhitelist with maximum token address limit to prevent out-of-gas errors
    constructor() TokenWhitelist() {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../Library/Errors.sol';

/// @title TokenWhitelist
/// @author FlacoJones
/// @notice Base contract for token whitelists
/// @dev Whitelisting and token address limit is implemented primarily as a means of preventing out-of-gas exceptions when looping over funded addresses for payouts
abstract contract TokenWhitelist is Ownable {
    uint256 public tokenCount;
    mapping(address => bool) public whitelist;

    /// @notice Determines if a tokenAddress is whitelisted
    /// @param _tokenAddress The token address on which to check whitelisting status
    /// @return bool Whether or not tokenAddress is whitelisted
    function isWhitelisted(address _tokenAddress) external view returns (bool) {
        return whitelist[_tokenAddress];
    }

    /// @notice Adds tokenAddress to the whitelist
    /// @param _tokenAddress The token address to add to the whitelist
    function addToken(address _tokenAddress) external onlyOwner {
        require(
            !this.isWhitelisted(_tokenAddress),
            Errors.TOKEN_ALREADY_WHITELISTED
        );
        whitelist[_tokenAddress] = true;
        tokenCount++;
    }

    /// @notice Removes tokenAddress to the whitelist
    /// @param _tokenAddress The token address to remove from the whitelist
    function removeToken(address _tokenAddress) external onlyOwner {
        require(
            this.isWhitelisted(_tokenAddress),
            Errors.TOKEN_NOT_ALREADY_WHITELISTED
        );
        whitelist[_tokenAddress] = false;
        tokenCount--;
    }
}