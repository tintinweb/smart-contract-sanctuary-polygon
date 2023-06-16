// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - ManagementFacet
/// @dev This facet provides functions to manage contract's configuration
/******************************************************************************/

import {AppStorage} from "../libraries/AppStorage.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {LibBytes} from "../libraries/LibBytes.sol";
import {LibMeta} from "../libraries/LibMeta.sol";

contract ManagementFacet {
    /* ------ TYPE & VARIABLES ------ */

    /// @dev declare AppStorage
    AppStorage internal s;

    /* ------ EVENTS------ */

    /// @dev Event emitted when the maximum number of pending deposit requests allowed is changed.
    event MaxNumberOfPendingRequestsUpdated(uint256 maxNumberOfPendingRequests);

    /// @dev Event emitted when the token minimum liquidity limit is updated.
    event TokenMinLiquidityUpdated(uint8 listingId, uint256 minLiquidity);

    /// @dev Event emitted when the token deposit limit is updated.
    event TokenMinDepositUpdated(uint8 listingId, uint256 minDeposit);

    /// @dev Event emitted when the default migration time is changed
    event WithdrawGasLimitUpdated(uint256 withdrawGasLimit);

    /// @dev Event emitted when the default time between a commit and its execute is changed
    event ExecuteTimeIntervalUpdated(uint256 executeTimeInterval);

    /// @dev Event emitted when the default maintenance time is changed.
    event DefaultMaintenanceTimeUpdated(uint256 defautMaintenanceTime);

    /// @dev Event emitted when the default migration time is changed
    event DefaultMigrationTimeUpdated(uint256 defautMigrationTime);

    /// @dev Event emitted when an address's blacklist status is updated;
    event BlacklistStatusUpdated(address userAddress, bool status, uint256 deadline);

    /// @dev Event emitted when Domain Separator's version is updated;
    event DomainSeparatorVersionUpdated(string version);

    /* ------ MODIFIERS ------ */

    modifier onlyGov() {
        LibAccessControl._requireGov();
        _;
    }

    modifier onlyGovOrOperator() {
        LibAccessControl._requireGovOrOperator();
        _;
    }

    /* ------ EXTERNAL FUNTIONS ------ */

    /// @notice Set the maximum number of pending deposit requests allowed.
    /// @dev Governor or Operator can call this function.
    /// @param _maxNumberOfPendingRequests The number of pending deposit requests allowed.
    function setMaxNumberOfPendingRequests(uint256 _maxNumberOfPendingRequests) external onlyGovOrOperator {
        s.config.maxNumberOfPendingRequests = _maxNumberOfPendingRequests;

        emit MaxNumberOfPendingRequestsUpdated(_maxNumberOfPendingRequests);
    }

    /// @notice Set token min liquidity.
    /// @dev Only Governor can call this function.
    /// @param _listingId Token's listingId.
    /// @param _minLiquidity Minimum balance limit of the token on this contract.
    function setTokenMinLiquidity(uint8 _listingId, uint256 _minLiquidity) external onlyGov {
        s.config.minLiquidity[_listingId] = _minLiquidity;

        emit TokenMinLiquidityUpdated(_listingId, _minLiquidity);
    }

    /// @notice Set token's deposit limit.
    /// @dev Only Governor can call this function.
    /// @param _listingId Token's listingId.
    /// @param _minDeposit The minimum amount of tokens required in a single deposit Tx. Only applies to Native & ERC20 tokens
    function setTokenMinDeposit(uint8 _listingId, uint256 _minDeposit) external onlyGov {
        s.config.minDeposit[_listingId] = _minDeposit;

        emit TokenMinDepositUpdated(_listingId, _minDeposit);
    }

    /// @notice Set new version to Domain Separator
    /// @dev Only Governor can call this function.
    /// @param _version New version ex: V1.0.1
    function setVersionDomainSeparator(string calldata _version) external onlyGov {
        s.domainSeparator = LibMeta._domainSeparator(_version);

        emit DomainSeparatorVersionUpdated(_version);
    }

    /// @notice Set new value for the withdrawal gas limit.
    /// @dev Governor or Operator can call this function.
    /// @param _gasLimit New default value for withdrawal gas limit. Example value for 100Gwei is 100000.
    function setWithdrawGasLimit(uint256 _gasLimit) external onlyGovOrOperator {
        s.config.withdrawGasLimit = _gasLimit;

        emit WithdrawGasLimitUpdated(_gasLimit);
    }

    /// @notice Set new value for the default migration time.
    /// @dev Governor or Operator can call this function.
    /// @param _intervalTime New default time between a commit and its execute.
    function setExecuteTimeInterval(uint256 _intervalTime) external onlyGovOrOperator {
        s.config.executeTimeInterval = _intervalTime;

        emit ExecuteTimeIntervalUpdated(_intervalTime);
    }

    /// @notice Set new value for the default maintenance time.
    /// @dev Governor or Operator can call this function.
    /// @param _time New default time in seconds.
    function setDefaultMaintenanceTime(uint256 _time) external onlyGovOrOperator {
        s.config.defaultMaintenanceTime = _time;

        emit DefaultMaintenanceTimeUpdated(_time);
    }

    /// @notice Set new value for the default migration time.
    /// @dev Governor or Operator can call this function.
    /// @param _time New default time in seconds.
    function setDefaultMigrationTime(uint256 _time) external onlyGovOrOperator {
        s.config.defaultMigrationTime = _time;

        emit DefaultMigrationTimeUpdated(_time);
    }

    /// @notice Update addresses's blacklist status.
    /// @dev Governor or Operator can call this function.
    /// @dev Do not use this function to update blacklist status for a single address. Use updateBlacklistSingle() instead.
    /// @param _blacklistData Bytes array data of all addresses to be updated.
    /// @param _action <true> to blacklist, otherwise <false>.
    function updateBlacklistBatch(bytes memory _blacklistData, bool _action) external onlyGovOrOperator {
        require(_blacklistData.length % 20 == 0, "Management: Invalid data length");
        uint256 numberOfCases = _blacklistData.length / 20;
        uint256 offset;
        address blacklistAddress;
        for (uint256 i; i < numberOfCases; i++) {
            (offset, blacklistAddress) = LibBytes.readAddress(_blacklistData, offset);

            s.isBlacklisted[blacklistAddress].status = _action;
            if (_action) {
                s.isBlacklisted[blacklistAddress].deadline = block.timestamp + 15 days;
            }

            emit BlacklistStatusUpdated(
                blacklistAddress,
                s.isBlacklisted[blacklistAddress].status,
                s.isBlacklisted[blacklistAddress].deadline
            );
        }
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Bytes
/// @dev This library provides internal functions for converting and processing bytes data.
/******************************************************************************/

// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library LibBytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    // function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
    //     bts = toBytesFromUIntTruncated(uint256(self), 20);
    // }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x1)
    function bytesToUInt8(bytes memory _bytes, uint256 _start) internal pure returns (uint8 r) {
        uint256 offset = _start + 0x1;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x5)
    function bytesToUInt40(bytes memory _bytes, uint256 _start) internal pure returns (uint40 r) {
        uint256 offset = _start + 0x5;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x5)
    function bytesToUInt40Array(
        bytes memory _bytes,
        uint256 _start,
        uint8 _arrayLength
    ) internal pure returns (uint40[] memory) {
        uint256 offset = _start + 0x5;
        require(_bytes.length >= offset, "V");
        uint40[] memory r = new uint40[](_arrayLength);
        uint40 n;
        for (uint8 i = 0; i < _arrayLength; i++) {
            assembly {
                n := mload(add(_bytes, offset))
            }
            offset = offset + 0x5;
            r[i] = n;
        }
        return r;
    }

    // NOTE: theoretically possible overflow of (_start + 0x8)
    function bytesToUInt64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 r) {
        uint256 offset = _start + 0x8;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 10)
    function bytesToUInt80(bytes memory _bytes, uint256 _start) internal pure returns (uint80 r) {
        uint256 offset = _start + 0xa;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0xa)
    function bytesToUInt80Array(
        bytes memory _bytes,
        uint256 _start,
        uint8 _arrayLength
    ) internal pure returns (uint80[] memory) {
        uint256 offset = _start + 0xa;
        require(_bytes.length >= offset, "V");
        uint80[] memory r = new uint80[](_arrayLength);
        uint80 n;
        for (uint8 i = 0; i < _arrayLength; i++) {
            assembly {
                n := mload(add(_bytes, offset))
            }
            offset = offset + 0xa;
            r[i] = n;
        }
        return r;
    }

    // NOTE: theoretically possible overflow of (_start + 0xb)
    function bytesToUInt88(bytes memory _bytes, uint256 _start) internal pure returns (uint88 r) {
        uint256 offset = _start + 0xb;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0xb)
    function bytesToUInt88Array(
        bytes memory _bytes,
        uint256 _start,
        uint8 _arrayLength
    ) internal pure returns (uint88[] memory) {
        uint256 offset = _start + 0xb;
        require(_bytes.length >= offset, "V");
        uint88[] memory r = new uint88[](_arrayLength);
        uint88 n;
        for (uint8 i = 0; i < _arrayLength; i++) {
            assembly {
                n := mload(add(_bytes, offset))
            }
            offset = offset + 0xb;
            r[i] = n;
        }
        return r;
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128Array(
        bytes memory _bytes,
        uint256 _start,
        uint8 _arrayLength
    ) internal pure returns (uint128[] memory) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "V");
        uint128[] memory r = new uint128[](_arrayLength);
        uint128 n;
        for (uint8 i = 0; i < _arrayLength; i++) {
            assembly {
                n := mload(add(_bytes, offset))
            }
            offset = offset + 0x10;
            r[i] = n;
        }
        return r;
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUInt8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = bytesToUInt8(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 5)
    function readUInt40(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint40 r) {
        newOffset = _offset + 5;
        r = bytesToUInt40(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 5*arrayLength)
    function readUInt40Array(
        bytes memory _data,
        uint256 _offset,
        uint8 _arrayLength
    ) internal pure returns (uint256 newOffset, uint40[] memory r) {
        newOffset = _offset + 5 * _arrayLength;
        r = bytesToUInt40Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 8)
    function readUInt64(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint64 r) {
        newOffset = _offset + 8;
        r = bytesToUInt64(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 10)
    function readUInt80(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint80 r) {
        newOffset = _offset + 10;
        r = bytesToUInt80(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 10*arrayLength)
    function readUInt80Array(
        bytes memory _data,
        uint256 _offset,
        uint8 _arrayLength
    ) internal pure returns (uint256 newOffset, uint80[] memory r) {
        newOffset = _offset + 10 * _arrayLength;
        r = bytesToUInt80Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 11)
    function readUInt88(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint88 r) {
        newOffset = _offset + 11;
        r = bytesToUInt88(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 11*arrayLength)
    function readUInt88Array(
        bytes memory _data,
        uint256 _offset,
        uint8 _arrayLength
    ) internal pure returns (uint256 newOffset, uint88[] memory r) {
        newOffset = _offset + 11 * _arrayLength;
        r = bytesToUInt88Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16*_arrayLength)
    function readUInt128Array(
        bytes memory _data,
        uint256 _offset,
        uint8 _arrayLength
    ) internal pure returns (uint256 newOffset, uint128[] memory r) {
        newOffset = _offset + 16 * _arrayLength;
        r = bytesToUInt128Array(_data, _offset, _arrayLength);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
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
/// @title Portal - Library Meta
/// @dev This library provides the portal's meta information.
/******************************************************************************/

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string version,uint256 chainId,address verifyingContract)"));

    function _domainSeparator(string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(version)), _getChainID(), address(this))
        );
    }

    function _getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
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