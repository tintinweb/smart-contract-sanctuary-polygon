// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "ReentrancyGuard.sol";

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
}

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract Bank is ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => uint256) private _userBalances;
    mapping(address => uint256) private _userDepositTimestamps;
    mapping(address => uint256[]) private _transactions;
    mapping(address => bool) private _blacklistedAddresses;
    mapping(address => bool) private _whitelistedAddresses;

    address private _owner;
    uint256 private _depositExpiryTime;

    event DepositReceived(address indexed user, uint256 amount);
    event ERC20Withdrawn(address indexed token, address indexed recipient, uint256 amount);
    event DepositExpired(address indexed user);
    event AddressBlacklisted(address indexed user);
    event AddressUnblocked(address indexed user);
    event AddressWhitelisted(address indexed user);
    event AddressRemovedFromWhitelist(address indexed user);

    constructor() {
        _owner = msg.sender;
        _depositExpiryTime = 300; // 5 minutes
    }

    receive() external payable {
        require(!_blacklistedAddresses[msg.sender], "Address is blacklisted");
        _userBalances[msg.sender] = _userBalances[msg.sender].add(msg.value);
        _userDepositTimestamps[msg.sender] = block.timestamp;
        _transactions[msg.sender].push(block.timestamp);
        emit DepositReceived(msg.sender, msg.value);
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBalance(address userAddress) public view returns (uint256) {
        return _userBalances[userAddress];
    }

    function transferOwnership(address newOwner) public {
        require(msg.sender == _owner, "Only the contract owner can transfer ownership");
        require(newOwner != address(0), "Invalid address provided for new owner");

        _owner = newOwner;
    }

    function isDepositExpired(address userAddress, uint256 amount) public view returns (bool) {
        if (_userBalances[userAddress] < amount) {
            return true;
        }
        return (block.timestamp - _userDepositTimestamps[userAddress]) >= _depositExpiryTime;
    }

    function setDepositExpiryTime(uint256 expiryTime) public {
        require(msg.sender == _owner, "Only the owner can set the deposit expiry time");
        _depositExpiryTime = expiryTime;
    }

    function withdrawERC20(address tokenAddress, uint256 amount, address recipient) public nonReentrant {
    require(msg.sender == _owner, "Only the owner can withdraw ERC20 tokens");
    require(recipient != address(0), "Invalid recipient address");

    ERC20 token = ERC20(tokenAddress);
    uint256 balance = token.balanceOf(address(this));
    require(balance >= amount, "Contract does not have enough ERC20 tokens");

    require(token.transfer(recipient, amount), "ERC20 token transfer failed");

    emit ERC20Withdrawn(tokenAddress, recipient, amount);
}

function withdrawETH(address payable recipient, uint256 amount) public nonReentrant {
    require(_whitelistedAddresses[msg.sender], "Address is not whitelisted to withdraw ETH");
    require(recipient != address(0), "Invalid recipient address");

    uint256 contractBalance = address(this).balance;
    require(amount > 0 && amount <= contractBalance, "Invalid withdrawal amount");

    // Update the user's balance before transferring Ether to prevent reentrancy attacks
    _userBalances[msg.sender] = _userBalances[msg.sender].sub(amount);

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Failed to send Ether");

    assert(address(this).balance == contractBalance.sub(amount));
}
 function getLastTransactionTimestamp(address userAddress) public view returns (uint256) {
    uint256[] memory transactions = _transactions[userAddress];
    if (transactions.length > 0) {
        return transactions[transactions.length - 1];
    } else {
        return 0;
    }
}

function isAddressBlacklisted(address userAddress) public view returns (bool) {
    return _blacklistedAddresses[userAddress];
}

function blacklistAddress(address userAddress) public {
    require(msg.sender == _owner, "Only the contract owner can blacklist an address");
    _blacklistedAddresses[userAddress] = true;
    emit AddressBlacklisted(userAddress);
}

function unblockAddress(address userAddress) public {
    require(msg.sender == _owner, "Only the contract owner can unblock an address");
    _blacklistedAddresses[userAddress] = false;
    emit AddressUnblocked(userAddress);
}

function isAddressWhitelisted(address userAddress) public view returns (bool) {
    return _whitelistedAddresses[userAddress];
}

function whitelistAddress(address userAddress) public {
    require(msg.sender == _owner, "Only the contract owner can whitelist an address");
    _whitelistedAddresses[userAddress] = true;
    emit AddressWhitelisted(userAddress);
}

function removeFromWhitelist(address userAddress) public {
    require(msg.sender == _owner, "Only the contract owner can remove an address from the whitelist");
    _whitelistedAddresses[userAddress] = false;
    emit AddressRemovedFromWhitelist(userAddress);
}

}