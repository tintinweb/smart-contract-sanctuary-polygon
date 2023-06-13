// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.1;

/**
 * @dev Context variant with ERC2771 support.
 */
// based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
abstract contract ERC2771Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

interface IPhiDaily {
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function isVerifiedCoupon(bytes32 digest, Coupon memory coupon) external view returns (bool);

    function claimMaterialObjectByRelayer(
        uint32 eventid,
        uint16 logicid,
        Coupon memory coupon,
        address userAddress
    ) external;

    function batchClaimMaterialObjectByRelayer(
        uint32[] memory eventids,
        uint16[] memory logicids,
        Coupon[] memory coupons,
        address userAddress
    ) external;
}

// SPDX-License-Identifier: MIT

//                 ____    ____
//                /\___\  /\___\
//       ________/ /   /_ \/___/
//      /\_______\/   /__\___\
//     / /       /       /   /
//    / /   /   /   /   /   /
//   / /   /___/___/___/___/
//  / /   /
//  \/___/

pragma solidity 0.8.18;

import { IPhiDaily } from "./interfaces/IPhiDaily.sol";

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";

/// @title Users claim PhiDaily by relayer
contract PhiDailyRelay is ReentrancyGuard, ERC2771Context {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    // We hold a reference to the PhiDaily contract address.
    address public immutable phiDaily;

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event emitted whenever a user claims a material object.
    event LogClaimMaterialObject(uint32 indexed eventid, uint16 indexed logicid, address indexed user);

    // Event emitted whenever a user batch claims material objects.
    event LogBatchClaimMaterialObjects(uint32[] indexed eventids, uint16[] indexed logicids, address indexed user);
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // We define error types as per Solidity 0.8.x custom errors feature.
    error PhiDailyNotSet();

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /// @dev Gelato implements the ERC2771Context interface, which allows us to relat funcs
    /// we initialize the trusted forwarder for meta transactions and set the PhiDaily contract.
    constructor(address trustedForwarder, address _phidaily) ERC2771Context(trustedForwarder) {
        if (_phidaily == address(0)) {
            revert PhiDailyNotSet();
        }
        phiDaily = _phidaily;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Claim                                    */
    /* -------------------------------------------------------------------------- */

    /// @dev Allows user to claim a material object via a relayer.
    function claimMaterialObjectByRelayer(
        uint32 eventid,
        uint16 logicid,
        IPhiDaily.Coupon memory coupon,
        address userAddress
    ) external nonReentrant {
        require(_msgSender() == userAddress);
        IPhiDaily(phiDaily).claimMaterialObjectByRelayer(eventid, logicid, coupon, userAddress);
        emit LogClaimMaterialObject(eventid, logicid, _msgSender());
    }

    /// @dev Allows user to batch claim material objects via a relayer.
    function batchClaimMaterialObjectByRelayer(
        uint32[] memory eventids,
        uint16[] memory logicids,
        IPhiDaily.Coupon[] memory coupons,
        address userAddress
    ) external nonReentrant {
        require(_msgSender() == userAddress);
        IPhiDaily(phiDaily).batchClaimMaterialObjectByRelayer(eventids, logicids, coupons, userAddress);
        emit LogBatchClaimMaterialObjects(eventids, logicids, _msgSender());
    }
}