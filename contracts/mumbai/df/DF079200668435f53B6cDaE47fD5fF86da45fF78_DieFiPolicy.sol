// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ISubscriptionManager.sol";

/**
 * FortKnoxster DieFiPolicy using meta transaction via DieFiForwarder.
 */
contract DieFiPolicy is ERC2771Context, ReentrancyGuard {

    constructor(address _trustedForwarder, address _subscriptionManager) ERC2771Context(_trustedForwarder) {
        _setSubscriptionManager(_subscriptionManager);
    }

    event SubscriptionManagerUpdated(address oldSubscriptionManager, address newSubscriptionManager);

    event DieFiPolicyCreated(
        bytes16 indexed policyId,
        address indexed owner,
        uint16 size,
        uint32 startTimestamp,
        uint32 endTimestamp,
        uint256 cost
    );

    address public subscriptionManager;

    function _setSubscriptionManager(address newSubscriptionManager) internal {
        address oldSubscriptionManager = subscriptionManager;
        subscriptionManager = newSubscriptionManager;
        emit SubscriptionManagerUpdated(oldSubscriptionManager, newSubscriptionManager);
    }

    function _msgSender() internal view override (ERC2771Context) returns (address sender) {
        return super._msgSender();
    }

    function _msgData() internal view override (ERC2771Context) returns (bytes calldata) {
        return super._msgData();
    }

    function createPolicy(
        bytes16 _policyId,
        address _policyOwner,
        uint16 _size,
        uint32 _startTimestamp,
        uint32 _endTimestamp
    )
        external 
        payable
        nonReentrant
    {
        require(
            _startTimestamp < _endTimestamp && 
            block.timestamp < _endTimestamp && 
            _startTimestamp > block.timestamp,
            "Invalid timestamps"
        );
        
        // Policy cost is validated in remote SubscriptionManager
        ISubscriptionManager(subscriptionManager).createPolicy{value: msg.value }(
            _policyId,
            _policyOwner,
            _size,
            _startTimestamp,
            _endTimestamp
        );

        emit DieFiPolicyCreated(
            _policyId,
            _policyOwner,
            _size,
            _startTimestamp,
            _endTimestamp,
            msg.value
        );
    }

    function getPolicyCost(
        uint16 _size,
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) public view returns (uint256) {
        return ISubscriptionManager(subscriptionManager).getPolicyCost(_size, _startTimestamp, _endTimestamp);
    }

    function isPolicyActive(bytes16 _policyId) public view returns(bool) {
        return ISubscriptionManager(subscriptionManager).isPolicyActive(_policyId);
    }

    function getPolicy(bytes16 _policyId) public view returns(ISubscriptionManager.Policy memory){
        return ISubscriptionManager(subscriptionManager).getPolicy(_policyId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface ISubscriptionManager {

    struct Policy {
        address payable sponsor;
        uint32 startTimestamp;
        uint32 endTimestamp;
        uint16 size;
        address owner;
    }

    function getPolicyCost(
        uint16 _size,
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) external view returns (uint256);

    function createPolicy(
        bytes16 _policyId,
        address _policyOwner,
        uint16 _size,
        uint32 _startTimestamp,
        uint32 _endTimestamp
    ) external payable;

    function isPolicyActive(bytes16 _policyId) external view returns(bool);

    function getPolicy(bytes16 _policyID) external view returns(Policy memory);

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
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}