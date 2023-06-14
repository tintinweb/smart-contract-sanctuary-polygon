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

interface IEmissionLogic {
    function determineTokenByLogic(uint16 logic) external view returns (uint256 tokenid);
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

interface IMaterialObject {
    struct Size {
        uint8 x;
        uint8 y;
        uint8 z;
    }

    function getSize(uint256 tokenId) external view returns (Size memory);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;

    function getObject(address to, uint256 tokenid, uint256 amount) external;

    function burnObject(address from, uint256 tokenid, uint256 amount) external;

    function burnBatchObject(address from, uint256[] memory ids, uint256[] memory amounts) external;
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

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import { IMaterialObject } from "./interfaces/IMaterialObject.sol";
import { IEmissionLogic } from "./interfaces/IEmissionLogic.sol";
import { ERC2771Context } from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import { MultiOwner } from "./utils/MultiOwner.sol";

/// @title Users claim Material Objects
/// @dev This contract handles the claims of material objects by users.
/// The contract utilizes ECDSA for secure, non-repudiable claims.
/// It also includes an emission logic contract to determine the ID of the token to be emitted.
/// The emission logic can be set by the contract owner.
/// This contract has been upgraded to include OpenZeppelin's access control for role-based permissions.
contract PhiDaily is ERC2771Context, MultiOwner, ReentrancyGuard {
    /* -------------------------------------------------------------------------- */
    /*                                   CONFIG                                   */
    /* -------------------------------------------------------------------------- */
    // The address that signs the claims (admin).
    address public adminSigner;
    // The MaterialObject contract address.
    address public materialObject;
    // The EmissionLogic contract address.
    address public emissionLogic;
    // The phiGelatoRelay contract address.
    address public phiGelatoRelay;

    //@notice Status:the coupon is used by msg sender
    // uint256 private constant _NOT_CLAIMED = 0;
    uint256 private constant _CLAIMED = 1;
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    //@notice the coupon sent was signed by the admin signer
    struct Coupon {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    // Mapping to track how many claims a sender has made.
    mapping(address => uint256) public claimedCount;
    // Mapping to track how many of each token a sender has claimed.
    mapping(address => mapping(uint256 => uint256)) public claimedEachCount;
    // Mapping to track the claim status of a sender for a specific event and logic ID.
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public dailyClaimedStatus;
    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    // Event emitted when the admin signer is set.
    event SetAdminSigner(address indexed verifierAddress);
    // Event emitted when the MaterialObject contract is set.
    event SetMaterialObject(address indexed materialContract);
    // Event emitted when the EmissionLogic contract is set.
    event SetEmissionLogic(address indexed emissionlogic);
    // Event emitted when a user claims a material object.
    event LogClaimMaterialObject(address indexed sender, uint256 eventid, uint256 logicid, uint256 tokenid);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    // Error to throw if the user has already claimed.
    error AllreadyClaimed(address sender, uint256 eventid, uint256 logicid);
    // Error to throw if the function call is not made by an admin.
    error NotAdminCall(address sender);
    // Error to throw if the ECDSA signature is invalid.
    error ECDSAInvalidSignature(address sender, address signer, bytes32 digest, Coupon coupon);
    // Error to throw if the coupon is invalid.
    error InvalidCoupon();
    // Error to throw if the lengths of the input arrays do not match.
    error ArrayLengthMismatch();
    // Error to throw if an invalid address is input.
    error InvalidAddress(string reason);
    // Error to throw if the function call is not made by an GelatoRelay.
    error OnlyGelatoRelay();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    constructor(
        address _adminSigner,
        address _materialObject,
        address _emissionLogic,
        address trustedForwarder
    ) ERC2771Context(trustedForwarder) {
        if (_adminSigner == address(0)) revert InvalidAddress("adminSigner can't be 0");
        if (_materialObject == address(0)) revert InvalidAddress("materialObject address can't be 0");
        if (_emissionLogic == address(0)) revert InvalidAddress("emissionLogic address can't be 0");

        adminSigner = _adminSigner;
        materialObject = _materialObject;
        emissionLogic = _emissionLogic;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    // Modifier to ensure the user has not already claimed.
    modifier onlyIfAllreadyClaimed(uint256 eventid, uint256 logicid) {
        if (dailyClaimedStatus[_msgSender()][eventid][logicid] > 0) {
            revert AllreadyClaimed({ sender: _msgSender(), eventid: eventid, logicid: logicid });
        }
        _;
    }

    // Modifier to ensure none of the IDs in the arrays have already been claimed.
    modifier onlyIfAllreadyClaimedMultiple(uint32[] memory eventids, uint16[] memory logicids) {
        uint256 length = eventids.length;
        if (length != logicids.length) {
            revert ArrayLengthMismatch();
        }
        for (uint i = 0; i < length; ) {
            if (dailyClaimedStatus[_msgSender()][eventids[i]][logicids[i]] == _CLAIMED) {
                revert AllreadyClaimed({ sender: _msgSender(), eventid: eventids[i], logicid: logicids[i] });
            }
            unchecked {
                ++i;
            }
        }
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   Coupon                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev set adminsigner
    function setAdminSigner(address _adminSigner) external onlyOwner {
        if (_adminSigner == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        adminSigner = _adminSigner;
        emit SetAdminSigner(adminSigner);
    }

    /// @dev check that the coupon sent was signed by the admin signer
    function isVerifiedCoupon(bytes32 digest, Coupon memory coupon) public view returns (bool) {
        address signer = ecrecover(digest, coupon.v, coupon.r, coupon.s);
        if (signer == address(0)) {
            revert ECDSAInvalidSignature({ sender: _msgSender(), signer: signer, digest: digest, coupon: coupon });
        }
        return signer == adminSigner;
    }

    /* --------------------------------- ****** --------------------------------- */
    /* -------------------------------------------------------------------------- */
    /*                                   MUTATORS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev set MaterialContract
    function setEmissionLogic(address _emissionLogic) external onlyOwner {
        if (_emissionLogic == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        emissionLogic = _emissionLogic;
        emit SetEmissionLogic(emissionLogic);
    }

    /// @dev set DailyContract
    function setMaterialObject(address _materialObject) external onlyOwner {
        if (_materialObject == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        materialObject = _materialObject;
        emit SetMaterialObject(materialObject);
    }

    function setPhiGelatoRelay(address _phiGelatoRelay) external onlyOwner {
        if (_phiGelatoRelay == address(0)) {
            revert InvalidAddress({ reason: "cant set address(0)" });
        }
        phiGelatoRelay = _phiGelatoRelay;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                 History                                    */
    /* -------------------------------------------------------------------------- */

    // Internal function to update claim status
    function _updateClaimStatus(address user, uint256 eventid, uint256 tokenid, uint256 logicid) internal {
        ++claimedCount[user];
        ++claimedEachCount[user][tokenid];
        dailyClaimedStatus[user][eventid][logicid] = _CLAIMED;
    }

    // Function to check the total number of claims made by a user.
    function checkClaimCount(address sender) external view returns (uint256 count) {
        return claimedCount[sender];
    }

    // Function to check the total number of claims made by a user for a specific token.
    function checkClaimEachCount(address sender, uint256 tokenid) external view returns (uint256 count) {
        return claimedEachCount[sender][tokenid];
    }

    // Function to check the claim status for a user for a specific event and logic ID.
    function checkClaimStatus(address sender, uint256 eventid, uint256 logicid) external view returns (uint256 status) {
        return dailyClaimedStatus[sender][eventid][logicid];
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   Claim                                    */
    /* -------------------------------------------------------------------------- */
    // Function to process claim for material object
    function _processClaim(uint32 eventid, uint16 logicid, Coupon memory coupon) private {
        // Check that the coupon sent was signed by the admin signer
        bytes32 digest = keccak256(abi.encode(eventid, logicid, _msgSender()));
        if (!isVerifiedCoupon(digest, coupon)) {
            revert InvalidCoupon();
        }

        uint256 tokenid = IEmissionLogic(emissionLogic).determineTokenByLogic(logicid);

        _updateClaimStatus(_msgSender(), eventid, tokenid, logicid);
        emit LogClaimMaterialObject(_msgSender(), eventid, logicid, tokenid);
        IMaterialObject(materialObject).getObject(_msgSender(), tokenid, 1);
    }

    // Function to claim a material object.
    function claimMaterialObject(
        uint32 eventid,
        uint16 logicid,
        Coupon memory coupon
    ) external onlyIfAllreadyClaimed(eventid, logicid) nonReentrant {
        _processClaim(eventid, logicid, coupon);
    }

    // Function to claim multiple material objects.
    function batchClaimMaterialObject(
        uint32[] memory eventids,
        uint16[] memory logicids,
        Coupon[] memory coupons
    ) external onlyIfAllreadyClaimedMultiple(eventids, logicids) nonReentrant {
        uint256 length = eventids.length;
        // Ensure input arrays have the same length
        if (length != logicids.length || logicids.length != coupons.length) {
            revert ArrayLengthMismatch();
        }
        for (uint i = 0; i < length; ) {
            _processClaim(eventids[i], logicids[i], coupons[i]);
            {
                ++i;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               RelayClaim                                   */
    /* -------------------------------------------------------------------------- */

    address constant GELATO_RELAY = 0xd8253782c45a12053594b9deB72d8e8aB2Fca54c;
    modifier onlyGelatoRelay() {
        if (!_isGelatoRelay(msg.sender)) revert OnlyGelatoRelay();
        _;
    }

    function _isGelatoRelay(address _forwarder) internal pure returns (bool) {
        return _forwarder == GELATO_RELAY;
    }

    // Function to claim a material object by relayer.
    function claimMaterialObjectByRelayer(
        uint32 eventid,
        uint16 logicid,
        Coupon memory coupon
    ) external onlyGelatoRelay onlyIfAllreadyClaimed(eventid, logicid) nonReentrant {
        _processClaim(eventid, logicid, coupon);
    }

    // Function to claim multiple material objects by relayer.
    function batchClaimMaterialObjectByRelayer(
        uint32[] memory eventids,
        uint16[] memory logicids,
        Coupon[] memory coupons
    ) external onlyGelatoRelay onlyIfAllreadyClaimedMultiple(eventids, logicids) nonReentrant {
        uint256 length = eventids.length;
        // Ensure input arrays have the same length
        if (length != logicids.length || logicids.length != coupons.length) {
            revert ArrayLengthMismatch();
        }
        for (uint i = 0; i < length; ) {
            _processClaim(eventids[i], logicids[i], coupons[i]);
            unchecked {
                ++i;
            }
        }
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

/**
 * @dev Contracts to manage multiple owners.
 */
abstract contract MultiOwner {
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    mapping(address => bool) private _owners;
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */
    event OwnershipGranted(address indexed operator, address indexed target);
    event OwnershipRemoved(address indexed operator, address indexed target);
    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   ERRORS                                   */
    /* -------------------------------------------------------------------------- */
    error InvalidOwner();

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                               INITIALIZATION                               */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owners[msg.sender] = true;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        if (!_owners[msg.sender]) revert InvalidOwner();
        _;
    }

    /* --------------------------------- ****** --------------------------------- */

    /* -------------------------------------------------------------------------- */
    /*                                   PUBLIC                                   */
    /* -------------------------------------------------------------------------- */
    /**
     * @dev Returns the address of the current owner.
     */
    function ownerCheck(address targetAddress) external view virtual returns (bool) {
        return _owners[targetAddress];
    }

    /**
     * @dev Set the address of the owner.
     */
    function setOwner(address newOwner) external virtual onlyOwner {
        _owners[newOwner] = true;
        emit OwnershipGranted(msg.sender, newOwner);
    }

    /**
     * @dev Remove the address of the owner list.
     */
    function removeOwner(address oldOwner) external virtual onlyOwner {
        _owners[oldOwner] = false;
        emit OwnershipRemoved(msg.sender, oldOwner);
    }
}