// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Contract is ReentrancyGuard{

    address public owner;
    
    struct accountData {
        uint balance;
        uint releaseTime;
    }

    constructor () {
        owner = msg.sender;
    }

    mapping (address => accountData) accounts;

    event depositMade(uint value, address player);
    event withdrawMade(uint value, address player);

    function deposit() external payable returns (uint) {
        require(msg.value == 0.1 ether);
        accounts[msg.sender].balance += msg.value;
        accounts[msg.sender].releaseTime = block.timestamp + 100 days;
        emit depositMade(msg.value, msg.sender);
        return accounts[msg.sender].balance;

    }

    function withdraw() external {
        require(accounts[msg.sender].releaseTime < block.timestamp, "The challenge isn't over!");
        require(accounts[msg.sender].balance > 0, "You don't have balance");
        accounts[msg.sender].releaseTime = 0;
        accounts[msg.sender].balance = 0;
        emit withdrawMade(accounts[msg.sender].balance, msg.sender);
        (bool success, ) = msg.sender.call{value: accounts[msg.sender].balance}("");
        require(success, "MATIC not sent");

        
    }

    function balance(address yourAddress) public view returns (uint) {
        return (accounts[yourAddress].balance);
    }

    function releaseTime(address yourAddress) public view returns (uint) {
	    return (accounts[yourAddress].releaseTime - block.timestamp)/86400;
    }
}

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