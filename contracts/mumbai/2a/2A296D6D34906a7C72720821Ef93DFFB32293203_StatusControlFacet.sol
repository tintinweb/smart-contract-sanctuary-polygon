// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Status Facet
/// @dev This facet provides functions to control the operating status of the portal.
/******************************************************************************/

import {AppStorage} from "../libraries/AppStorage.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";

/// @dev System status
///      status == 0 Contract is in Migrate mode, disable deposit-related features, keeping all withdrawal-related features enabled before the migration time is half over. Prepare for migrating to a new contract version.
///      status == 1 Contract is in Active mode, only disable exit-related features. This is the normal working state of the portal.
///      status == 2 Contract is in Maintenance mode, disable all deposit & withdrawal-related features. Anyone can turn off Maintenance mode after it expires.
///      status == 3 Contract is in MassExit mode, enable exit features, only available when no operations are performed before the expiration time.

contract StatusControlFacet {
    /* ------ TYPE & VARIABLES ------ */

    /// @dev declare AppStorage
    AppStorage internal s;

    /* ------ EVENTS------ */

    /// @dev Event emitted when a request to activate MassExit mode is submitted.
    event RequestToMassExitSubmitted(uint128 requestId);

    /// @dev Event emitted when a request to activate MassExit mode is canceled.
    event RequestToMassExitCanceled();

    /// @dev Event emitted when MassExit mode is activated.
    event MassExit();

    /// @dev Event emitted when a request to activate Migration mode is submitted.
    event RequestToMigrateSubmitted();

    /// @dev Event emitted when Migrate mode is activated.
    event Migrate();

    /// @dev Event emitted when Maintenance mode is activated.
    event Maintenance();

    /// @dev Event emitted when Active mode is activated.
    event Active();

    /* ------ EXTERNAL FUNTIONS ------ */

    /// @notice Request to activate Migration mode.
    /// @dev Only Governor can call this function.
    /// @dev Only able to be called when the current status of the portal is Active.
    function requestMigration() external {
        LibAccessControl._requireGov();
        require(s.status == 1, "SCF: Contract is not active");
        require(!s.migrationRequestEnabled, "SCF: Request to Migrate already submitted");

        s.migrationExpirationTime = block.timestamp + s.config.defaultMigrationTime;
        s.migrationRequestEnabled = true;

        emit RequestToMigrateSubmitted();
    }

    /// @notice Enable Migration mode.
    /// @dev Only Governor can call this function.
    /// @dev Contract is not activted Migration.
    /// @dev All pending requests must be cleared.
    /// @dev Only able to be called when the process to activate Migration is completed .
    function enableMigrate() external {
        LibAccessControl._requireGov();
        require(s.status != 0, "SCF: Contract has already activated Migration");
        require(s.numberOfPendingRequest == 0, "SCF: All pending requests must be cleared");
        require(
            s.migrationRequestEnabled && s.migrationExpirationTime < block.timestamp,
            "SCF: The process to activate Migration has not been completed yet"
        );

        s.status = 0;
        s.migrationRequestEnabled = false;
        s.migrationExpirationTime = block.timestamp + 7 days;

        emit Migrate();
    }

    /// @notice Request to activate MassExit mode.
    /// @dev Only able to be called when the current status of the portal is Active.
    /// @dev Anyone can call this function to request for MassExit mode when at least 1 pending deposit request has expired or last commit was more than 60 days ago.
    /// @param _requestId The Id of the deposit request that expired, this param is <any> if last commit was more than 60 days ago
    function requestMassExit(uint128 _requestId) external {
        require(s.status == 1, "SCF: Contract is not active");
        require(!s.massExitRequestEnabled, "SCF: Another request to MassExit already submitted");
        require(s.numberOfPendingRequest != 0, "SCF: All pending request has been cleared");
        require(s.reportedRequestIdForMassExit == 0, "SCF: Another request to MassExit already submitted");
        require(
            _validateExpiredDepositRequest(_requestId) ||
                (s.latestCommittedBatch.timestamp + 60 days < block.timestamp),
            "SCF: Pending deposit request must be expired or last commit was more than 60 days ago"
        );

        s.massExitRequestExpirationTime = block.timestamp + 3 days;
        s.massExitRequestEnabled = true;
        if (_validateExpiredDepositRequest(_requestId)) {
            s.reportedRequestIdForMassExit = _requestId;
        }

        emit RequestToMassExitSubmitted(s.reportedRequestIdForMassExit);
    }

    /// @notice Cancel the request to activate MassExit mode.
    /// @dev Anyone can call this function to cancel a request to MassExit.
    /// @dev Require the reported request Id is executed and the last commit was less than 60 days ago
    function cancelMassExitRequest() external {
        require(s.massExitRequestEnabled, "SCF: There is no request to MassExit");
        require(
            !_validateExpiredDepositRequest(s.reportedRequestIdForMassExit) &&
                (s.latestCommittedBatch.timestamp + 60 days >= block.timestamp),
            "SCF: The request must be resolved and the last commit must be less than 60 days ago"
        );

        s.massExitRequestEnabled = false;
        s.reportedRequestIdForMassExit = 0;

        emit RequestToMassExitCanceled();
    }

    /// @notice Enable MassExit mode.
    /// @dev Contract is not activted MassExit.
    /// @dev There must be at least 1 pending request.
    /// @dev Anyone can call this function to trigger MassExit mode when the process to activate MassExit is completed.
    /// @param _requestId The Id of the deposit request that expired, this param is <any> if last commit was more than 60 days ago.
    function enableMassExit(uint128 _requestId) external {
        require(s.status != 3, "SCF: Contract is already activated MassExit");
        require(s.numberOfPendingRequest != 0, "SCF: All pending request has been cleared");
        require(
            s.massExitRequestEnabled && s.massExitRequestExpirationTime < block.timestamp,
            "SCF: The process to activate MassExit has not been completed yet"
        );
        require(
            _validateExpiredDepositRequest(_requestId) ||
                (s.latestCommittedBatch.timestamp + 60 days < block.timestamp),
            "SCF: Pending deposit request must be expired or last commit was more than 60 days ago"
        );

        s.status = 3;
        s.massExitRequestEnabled = false;
        s.minMassExitTimeLimit = block.timestamp + 1 days;

        emit MassExit();
    }

    /// @notice Enable Maintenance mode or switch from Maintenance to Active.
    /// @dev Anyone can switch from Maintenance to Active when the maintenance time has expired.
    /// @dev Anyone can switch from Migration to Maintenance when the migration time has expired.
    /// @dev Governor has no restrict to switch states but in case of MassExit, Governor must wait for the minimum time limit is over.
    function switchMaintenance() external {
        if (s.status == 2) {
            // When current status is Maintenance.
            require(
                s.maintenanceExpirationTime < block.timestamp ||
                    LibAccessControl._hasRole(LibAccessControl.OPERATOR_ROLE, LibAccessControl._msgSender()),
                "SCF: Maintenance is not expired"
            );
            // New status will be Active.
            s.status = 1;
            emit Active();
            return;
        }

        // When current status is not Maintenance.
        if (s.status == 0) {
            // When current status is Migration.
            require(
                s.migrationExpirationTime < block.timestamp ||
                    LibAccessControl._hasRole(LibAccessControl.OPERATOR_ROLE, LibAccessControl._msgSender()),
                "SCF: Migration is not expired"
            );
        } else if (s.status == 3) {
            // When current status is MassExit.
            require(
                s.minMassExitTimeLimit < block.timestamp &&
                    LibAccessControl._hasRole(LibAccessControl.GOV_ROLE, LibAccessControl._msgSender()),
                "SCF: MassExit is not expired"
            );
        } else {
            // When current status is Active.
            require(
                LibAccessControl._hasRole(LibAccessControl.OPERATOR_ROLE, LibAccessControl._msgSender()),
                "SCF: Unauthorized"
            );
        }
        // New status will be Maintenance.
        s.status = 2;
        s.maintenanceExpirationTime = block.timestamp + s.config.defaultMaintenanceTime;
        emit Maintenance();
    }

    /* ------ INTERNAL FUNTIONS ------ */

    /// @notice Check if the requestId has expired
    /// @param _requestId The Id of the deposit request.
    /// @return bool <true> if expired, otherwise <false>
    function _validateExpiredDepositRequest(uint256 _requestId) internal view returns (bool) {
        return
            _requestId <= s.currentDepositRequestId &&
            s.pendingDepositRecord[_requestId].expirationTimestamp != 0 &&
            s.pendingDepositRecord[_requestId].expirationTimestamp < block.timestamp &&
            s.pendingDepositRecord[_requestId].hashedRequestData != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Interface Operations
/// @dev This interface provides structs for facets related to transaction processing.
/******************************************************************************/

interface IOperations {
    /// @notice Struct data for Deposit request, support: Native, ERC20, ERC721
    struct Deposit {
        address from; //L1 address
        uint8 listingId;
        uint88 tokenId;
        uint88 amount;
        uint128 requestId;
    }

    /// @notice Struct data for Deposit Batch request, support: ERC1155 only
    struct DepositBatch {
        address from; //L1 address
        uint8 listingId;
        uint8 arrayLength;
        uint88[] tokenIds;
        uint88[] amounts;
        uint128 requestId;
    }

    ///@notice Struct data for Withdraw request, support: Native, ERC20, ERC721
    struct Withdraw {
        address to; //L1 address
        uint8 listingId;
        uint88 tokenId;
        uint88 amount;
    }

    /// @notice Struct data for FullBatchExit request
    struct Withdraw1155C {
        bytes executeSig;
        address to; //L1 address
        uint24 salt;
        uint8 listingId;
        uint8 arrayLength;
        uint88[] tokenIds;
        uint88[] amounts;
    }

    /// @notice
    struct PendingDepositRecord {
        bytes32 hashedRequestData;
        uint256 expirationTimestamp;
    }

    /// @notice
    struct CommittedBatchInfo {
        bytes32 stateRoot;
        bytes32 pendingOperationsHash;
        uint256 batchId;
        uint256 timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library AppStorage
/// @dev This Library provides application specific state variables that are shared among facets.
/******************************************************************************/

import {IOperations} from "../interfaces/IOperations.sol";

/// @dev Struct to interact with the role data of access control facet.
struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

/// @dev Struct info of a blacklisted address
struct BlacklistedAddress {
    bool status;
    uint256 deadline;
}

struct PortalConfig {
    /// @dev The default expiration time of the Maintenance mode
    uint256 defaultMaintenanceTime;
    //
    /// @dev The default expiration time of the Migration mode
    uint256 defaultMigrationTime;
    //
    /// @dev Default time between a successful commit and an execution in second.
    uint256 executeTimeInterval;
    //
    /// @dev Default withdrawals gas limit, used only for complete withdrawals
    uint256 withdrawGasLimit;
    //
    /// @dev The maximum number of pending deposit requests allowed.
    uint256 maxNumberOfPendingRequests;
    //
    /// @dev List of minimum liquidity limit by listingId.
    mapping(uint8 => uint256) minLiquidity;
    //
    /// @dev List of minimum amount of tokens required in a single deposit Tx by listingId. Only applies to Native & ERC20 tokens
    mapping(uint8 => uint256) minDeposit;
}

/// @dev Core state variables struct that are shared among facets.
struct AppStorage {
    /// @dev Reentrancy indicator.
    uint256 _reentrancy;
    //
    /// @dev The expiration time of the current Maintenance stage (if active)
    uint256 maintenanceExpirationTime;
    //
    /// @dev The expiration time of the current Migration stage (if active)
    uint256 migrationExpirationTime;
    //
    /// @dev The expiration time of the current MassExit stage (if active)
    uint256 massExitRequestExpirationTime;
    //
    /// @dev The current Id of pending deposit request queue.
    uint128 currentDepositRequestId;
    //
    /// @dev The requestId that has been submitted successfully.
    uint128 reportedRequestIdForMassExit;
    //
    /// @dev The minimum time limit of the MassExit before the operator can switch to Maintenance Mode.
    uint256 minMassExitTimeLimit;
    //
    /// @dev The current batchId of the latest successful execution.
    uint256 currentBatchId;
    //
    /// @dev The current total number of pending deposit requests.
    uint256 numberOfPendingRequest;
    //
    /// @dev The portal current status
    ///      status == 0 Contract is in Migrate mode, disable deposit-related features, keeping all withdrawal-related features enabled before the migration time is half over. Prepare for migrating to a new contract version.
    ///      status == 1 Contract is in Active mode, only disable exit-related features. This is the normal working state of the portal.
    ///      status == 2 Contract is in Maintenance mode, disable all deposit & withdrawal-related features. Anyone can turn off Maintenance mode after it expires.
    ///      status == 3 Contract is in MassExit mode, enable exit features, only available when no operations are performed before the expiration time.
    uint8 status;
    //
    /// @dev An indicator if there is a massExit request has been enabled.
    bool massExitRequestEnabled;
    //
    /// @dev An indicator if there is a massExit request has been enabled.
    bool migrationRequestEnabled;
    //
    /// @dev Domain separator of the portal.
    bytes32 domainSeparator;
    //
    /// @dev Latest successful commit data struct.
    IOperations.CommittedBatchInfo latestCommittedBatch;
    //
    /// @dev List of roles by the role's hash.
    mapping(bytes32 => RoleData) _roles;
    //
    /// @dev List of pending deposit records by Id.
    mapping(uint256 => IOperations.PendingDepositRecord) pendingDepositRecord;
    //
    /// @dev List of blacklisted address by address.
    mapping(address => BlacklistedAddress) isBlacklisted;
    //
    /// @dev List of execution status by batchId.
    mapping(uint256 => bool) isExecuted;
    //
    /// @dev List of exit status by user's withdrawal key.
    mapping(bytes32 => bool) isExited;
    //
    /// @dev List of pending withdraw balance amount by user's withdrawal key.
    mapping(bytes32 => uint128) pendingWithdrawBalance;
    //
    /// @dev List of token's address by listingId.
    mapping(uint8 => address) tokenAddresses;
    //
    /// @dev List of asset types by listingId.
    mapping(uint8 => uint8) tokenTypes;
    //
    /// @dev List of pause status by token's listingId
    mapping(uint8 => bool) pausedTokens;
    //
    /// @dev List of listing Id by token's address.
    mapping(address => uint8) listingIds;
    //
    /// @dev Portal configuration
    PortalConfig config;
    //
    /// @dev test
    uint256 testUpgrade;
}

library LibAppStorage {
    /// @notice Declare appStorage inside the library's internal functions.
    /// @return ds Core state variables struct that are shared among facets.
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Access Control
/// @dev This library provide internal functions to verify and check for administrative & operational roles. 

* Implementation of OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)
/******************************************************************************/

import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import {LibStrings} from "./LibStrings.sol";

library LibAccessControl {
    /// @dev bytes32 identifier of COMMITTER_ROLE
    bytes32 public constant COMMITTER_ROLE = keccak256("COMMITTER_ROLE");

    /// @dev bytes32 identifier of EXECUTOR_ROLE
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    /// @dev bytes32 identifier of GOV_ROLE
    bytes32 public constant GOV_ROLE = keccak256("GOV_ROLE");

    /// @dev bytes32 identifier of MINTER_ROLE
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev bytes32 identifier of OPERATOR_ROLE
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev bytes32 identifier of DEFAULT_ADMIN_ROLE
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function _requireGov() internal view {
        require(_hasRole(GOV_ROLE, _msgSender()), "Access Control: Not governor");
    }

    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function _requireCommitter() internal view {
        require(_hasRole(COMMITTER_ROLE, _msgSender()), "Access Control: Not committer");
    }

    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function _requireExecutor() internal view {
        require(_hasRole(EXECUTOR_ROLE, _msgSender()), "Access Control: Not executor");
    }

    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function _requireMinter() internal view {
        require(_hasRole(MINTER_ROLE, _msgSender()), "Access Control: Not minter");
    }

    /**
     * @dev Returns `true` if `account` has `role`.
     */
    function _requireGovOrOperator() internal view {
        require(
            _hasRole(GOV_ROLE, _msgSender()) || _hasRole(OPERATOR_ROLE, _msgSender()),
            "Access Control: Not governor or operator"
        );
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function _getRoleAdmin(bytes32 role) external view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s._roles[role].adminRole;
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        LibStrings.toHexString(account),
                        " is missing role ",
                        LibStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Provides information about the current execution context, including the
     * sender of the transaction. While these are generally available
     * via msg.sender, they should not be accessed in such a direct
     * manner, since when dealing with meta-transactions the account sending and
     * paying for execution may not be the actual sender (as far as an application
     * is concerned).
     */
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Math
/// @dev This library provides mathematical operations functions.

* Implementation of OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)
/******************************************************************************/

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library LibMath {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Strings
/// @dev This library provides funtions to support string operation.

* Implementation of OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)
/******************************************************************************/

import "./LibMath.sol";

/**
 * @dev String operations.
 */
library LibStrings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = LibMath.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, LibMath.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}