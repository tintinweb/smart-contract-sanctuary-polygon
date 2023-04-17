// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/**
 * @title ISwooshNFTAbridged
 * @author Syndicate Protocol
 * @custom:license Copyright (c) 2021-present Syndicate Inc. All rights
 * reserved.
 *
 * Interface for only functions defined in SwooshNFT (excludes inherited
 * and overridden functions)
 */
interface ISwooshNFTAbridged {
    function balanceOf(address account) external view returns (uint256);

    function mintTo(address account, uint256 tokenId) external returns (bool);

    function setNFTType(uint256 tokenId, uint8 nftType) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {AdminChecker} from "src/contracts/utils/Administrable/AdminChecker.sol";
import {ISwooshNFTAbridged} from "src/contracts/custom/swoosh/nft/ISwooshNFTAbridged.sol";

/**
 * @title PosterMintModule
 * @author Syndicate Protocol
 * @custom:license Copyright (c) 2021-present Syndicate Inc. All rights
 * reserved.
 *
 * Module that allows admins to mint a SwooshNFT Poster for addresses.
 */
contract PosterMintModule is ReentrancyGuard, AdminChecker {
    address public immutable posterAddress;
    // This will be used to track the last minted tokenId. We use this instead
    // of totalSupply so that mints and burns can be run concurrently. Without
    // this, a burnt NFT could be re-minted since it would have been removed
    // from the total supply
    // This value is initialized to 0. It is incremented prior to minting, so
    // the starting ID is 1.
    uint256 public lastMintedId;

    // check for number of NFT an address can have upon miting
    uint256 public maxAmountOfNFTPerAddress;

    constructor(address posterAddress_) {
        posterAddress = posterAddress_;

        // initial max amount of NFT per address is 1
        maxAmountOfNFTPerAddress = 1;
    }

    modifier onlyWithinMaxAmountOfNFTPerAddressAllowed(address account) {
        require(
            ISwooshNFTAbridged(posterAddress).balanceOf(account) <
                maxAmountOfNFTPerAddress,
            "PosterMintModule: Address has reached the maximum amount of NFT allowed"
        );
        _;
    }

    /// @dev Allows an admin to set the last minted id.
    /// @param lastMintedId_ The last minted id.
    function setLastMintedId(
        uint256 lastMintedId_
    ) external onlyAdminOf(posterAddress) {
        lastMintedId = lastMintedId_;
    }

    /// @dev Allows an admin to set the max amount of NFT per address.
    /// @param maxAmountOfNFTPerAddress_ The max amount of NFT per address.
    function setMaxAmountOfNFTPerAddress(
        uint256 maxAmountOfNFTPerAddress_
    ) external onlyAdminOf(posterAddress) {
        maxAmountOfNFTPerAddress = maxAmountOfNFTPerAddress_;
    }

    /**
     * Allows an admin of the poster to mint SwooshNFT Poster for an address.
     *
     * Requirements:
     * - The caller must be an admin of the poster.
     * - The recipient of the poster must not already have a poster. (From
     *   SwooshNFT)
     * - The address cannot be an zero address.
     * @param account Address that will receive the minted poster.
     */
    function mint(
        address account
    ) external onlyAdminOf(posterAddress) nonReentrant {
        _mint(account);
    }

    /**
     * Allows an admin of the poster to mint an arbitrary tokenId to the holder
     * of a Swoosh ID, if that swooshId has not already been used to mint.
     *
     * Requirements:
     * - The caller must be an admin of the poster.
     * - The recipient of the poster must not already have a poster. (From
     *   SwooshNFT)
     * - The address cannot be an zero address.
     * @param accounts Addresses that own a Swoosh ID token. The address will each
     * receive the minted poster for a Swoosh ID token they own.
     */
    function mintBatch(
        address[] memory accounts
    ) external onlyAdminOf(posterAddress) nonReentrant {
        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; ) {
            _mint(accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Internal helper function to mint an arbitrary tokenId to the holder
     * of a Swoosh ID, if that swooshId has not already been used to mint.
     *
     * - The caller must be an admin of the poster.
     * - The recipient of the poster must not already have a poster. (From
     *   SwooshNFT)
     * - The address cannot be an zero address.
     * @param account Address that will receive the minted poster.
     */
    function _mint(
        address account
    ) internal onlyWithinMaxAmountOfNFTPerAddressAllowed(account) {
        // Increment the last minted id prior to minting. This rotates it easily
        // and ensure that we start at 1
        ++lastMintedId;

        ISwooshNFTAbridged(posterAddress).mintTo(account, lastMintedId);
    }

    /// This function is called for all messages sent to this contract (there
    /// are no other functions). Sending Ether to this contract will cause an
    /// exception, because the fallback function does not have the `payable`
    /// modifier.
    /// Source: https://docs.soliditylang.org/en/v0.8.9/contracts.html?highlight=fallback#fallback-function
    fallback() external {
        revert("PosterMintModule: non-existent function");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IAdministrable} from "src/contracts/utils/Administrable/IAdministrable.sol";

/**
 * @title TokenAdminChecker
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Utility for use by any Module or Guard that needs to check if an address is
 * an admin of any (other) contract implementing the `Administrable` utility.
 */

abstract contract AdminChecker {
    /**
     * Only proceed if msg.sender is an admin of the specified contract
     * @param token Contract whose owner to check
     */
    modifier onlyAdminOf(address token) {
        _checkAdmin(token);
        _;
    }

    function _checkAdmin(address token) internal view {
        require(
            IAdministrable(token).isAdmin(msg.sender),
            "AdminChecker: Caller is not admin"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * @title IAdministrable
 * @author Syndicate Inc.
 * @custom:license MIT license. Copyright (c) 2021-present Syndicate Inc.
 *
 * Interface for an access control utility allowing any number of addresses to
 * be granted "admin" status and permission to execute functions with the
 * `onlyAdmin` modifier.
 */
interface IAdministrable {
    event AdminGranted(address indexed account, address indexed operator);
    event AdminRevoked(address indexed account, address indexed operator);

    /**
     * @return True iff `account` is an admin.
     * @param account The address that may be an admin.
     */
    function isAdmin(address account) external view returns (bool);

    /**
     * Grants admin status to each address in `accounts`.
     *
     * Emits an `AdminGranted` event for each address in `accounts` that was
     * not already an admin.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param accounts The addresses to grant admin status
     */
    function grantAdmin(address[] calldata accounts) external;

    /**
     * Revokes admin status from each address in `accounts`.
     *
     * Emits an `AdminRevoked` event for each address in `accounts` that was an
     * admin until this call.
     *
     * Requirements:
     * - The caller must be an admin.
     * @param accounts The addresses from which admin status should be revoked
     */
    function revokeAdmin(address[] calldata accounts) external;

    /**
     * Allows the caller to renounce admin status.
     *
     * Emits an `AdminRevoked` event iff the caller was an admin until this
     * call.
     */
    function renounceAdmin() external;
}