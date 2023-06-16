pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

import {AppStorage} from "../libraries/AppStorage.sol";
import {IOperations} from "../interfaces/IOperations.sol";

/******************************************************************************\
/// @title Portal - View Facet
/// @dev This contract provides the functions of checking and monitoring the operation of the portal. 
/******************************************************************************/

contract ViewFacet is IOperations {
    /* ------ TYPE & VARIABLES ------ */

    /// @notice declare AppStorage
    AppStorage internal s;

    /* ------ EXTERNAL FUNTIONS ------ */

    /// @notice Get the current status of the portal .
    /// @return uint8 Current status of the portal in form of a code. 0 - Migration; 1 - Active; 2 - Maintenance; 3 - MassExit.
    function getStatus() external view returns (uint8) {
        return s.status;
    }

    /// @notice Get data of the latest successful commit.
    /// @return CommittedBatchInfo Latest commit data.
    function getCurrentCommittedData() external view returns (CommittedBatchInfo memory) {
        return s.latestCommittedBatch;
    }

    /// @notice Check if a batchId has been executed or not.
    /// @return bool `true` if the batchId has been executed, otherwise `false`.
    function getIsExecuted(uint256 _batchId) external view returns (bool) {
        return s.isExecuted[_batchId];
    }

    /// @notice Check if a balance record has been exited or not.
    /// @return bool `true` if the balance record has been executed, otherwise `false`.
    function getIsExited(
        address _defaultReceiver,
        uint8 _listingId,
        uint88[] calldata _tokenIds,
        uint128[] calldata _amounts
    ) external view returns (bool) {
        bytes32 exitAssetKey = keccak256(
            abi.encode(_defaultReceiver, _listingId, s.currentBatchId, _tokenIds, _amounts)
        );
        return s.isExited[exitAssetKey];
    }

    /// @notice Get balance of the user's withdrawal key.
    /// @param _recipient Recipient's address.
    /// @param _tokenId Id of the token on its contract.
    /// @param _listingId Token's listingId.
    /// @return balance Witdrawable balance.
    function getWithdrawableBalance(
        address _recipient,
        uint88 _tokenId,
        uint8 _listingId
    ) external view returns (uint128 balance) {
        return s.pendingWithdrawBalance[bytes32(abi.encodePacked(_recipient, _listingId, _tokenId))];
    }

    /// @notice Get the Id of the current pending deposit request.
    /// @return uint128 Id of the current pending deposit request.
    function getcurrentDepositRequestId() public view returns (uint128) {
        return s.currentDepositRequestId;
    }

    /// @notice Get the total number of pending deposit requests.
    /// @return uint256 Current number of pending deposit requests.
    function getNumberOfPendingRequest() public view returns (uint256) {
        return s.numberOfPendingRequest;
    }

    /// @notice Get the maximum number of pending deposit requests allowed.
    /// @return uint256 The maximum number of pending deposit requests allowed.
    function getMaxNumberOfPendingRequests() public view returns (uint256) {
        return s.config.maxNumberOfPendingRequests;
    }

    /// @notice Get the current batchId.
    /// @return uint256 Current batchId.
    function getCurrentBatchId() public view returns (uint256) {
        return s.currentBatchId;
    }

    /// @notice Get data of the pending deposit request by its Id.
    /// @param _requestId The pending deposit request Id.
    /// @return PendingDepositRecord Data of the pending deposit request.
    function getPendingDepositRecordData(uint128 _requestId) external view returns (PendingDepositRecord memory) {
        return s.pendingDepositRecord[_requestId];
    }

    /// @notice Check if a pending deposit request has expired or not.
    /// @param _requestId The pending deposit request Id.
    /// @return bool `true` if pending deposit request expired, otherwise `false`.
    function getValidExpiredDepositRequest(uint128 _requestId) external view returns (bool) {
        return
            s.pendingDepositRecord[_requestId].expirationTimestamp < block.timestamp &&
            s.pendingDepositRecord[_requestId].expirationTimestamp != 0;
    }

    /// @notice Get the number of un-executed deposit requests in the range from start to current.
    /// @param _start The start of the range.
    /// @return count The number of un-executed deposit requests.
    function getNumberOfUnexecutedDepositRequest(uint128 _start) external view returns (uint256 count) {
        require(_start < s.currentDepositRequestId, "ViewFacet: invalid start");
        for (uint128 i = _start; i < s.currentDepositRequestId; i++) {
            if (
                s.pendingDepositRecord[i].hashedRequestData != 0 && s.pendingDepositRecord[i].expirationTimestamp != 0
            ) {
                count++;
            }
        }
        return count;
    }

    /* ------ PUBLIC FUNTIONS ------ */

    /// @notice Get the expiration time of the current Migration stage (if active).
    /// @return uint256 The expiration timestamp.
    function getMigrationExpirationTime() public view returns (uint256) {
        return s.migrationExpirationTime;
    }

    /// @notice Get the default expiration time of the Migration mode.
    /// @return uint256 Default expiration time in seconds
    function getDefaultMigrationTime() public view returns (uint256) {
        return s.config.defaultMigrationTime;
    }

    /// @notice Get the expiration time of the current Maintenance stage (if active).
    /// @return uint256 The expiration timestamp.
    function getMaintenanceExpirationTime() public view returns (uint256) {
        return s.maintenanceExpirationTime;
    }

    /// @notice Get the default expiration time of the Maintenance mode.
    /// @return uint256 Default expiration time in seconds
    function getDefaultMaintenanceTime() public view returns (uint256) {
        return s.config.defaultMaintenanceTime;
    }

    /// @notice Get the default withdrawal gas limit.
    /// @return uint256 The default withdrawal gas limit in MWei
    function getWithdrawGasLimit() public view returns (uint256) {
        return s.config.withdrawGasLimit;
    }

    /// @notice Get the default interval time between a commit and its execute.
    /// @return uint256 Default interval time in seconds
    function getExecuteTimeInterval() public view returns (uint256) {
        return s.config.executeTimeInterval;
    }

    /// @notice Get the blacklist status info.
    /// @param _address User's address.
    /// @return status <true> if blacklisted, otherwise <false>.
    /// @return deadline Deadline timestamp before the account's assets could be quarantined.
    function getBlacklistInfo(address _address) public view returns (bool status, uint256 deadline) {
        return (s.isBlacklisted[_address].status, s.isBlacklisted[_address].deadline);
    }

    /// @notice Get the listingId of token by its address.
    /// @param _tokenAddress Token's address.
    /// @return uint8 listing Id of the token address
    function getListingIdByAddress(address _tokenAddress) public view returns (uint8) {
        require(_tokenAddress != address(0), "VF: Invalid address");
        return s.listingIds[_tokenAddress];
    }

    /// @notice Get the token address of a listingId.
    /// @param _listingId Listing Id.
    /// @return address token address of the listingId
    function getAddressByListingId(uint8 _listingId) public view returns (address) {
        require(s.tokenAddresses[_listingId] != address(0), "VF: Token not listed");
        return s.tokenAddresses[_listingId];
    }

    /// @notice Get the minimum liquidity limit of a listingId.
    /// @param _listingId Listing Id.
    /// @return uint256 Minimum liquidity limit.
    function getMinLiquidityByListingId(uint8 _listingId) public view returns (uint256) {
        return s.config.minLiquidity[_listingId];
    }

    /// @notice Get the minimum deposit amount of a listingId.
    /// @param _listingId Listing Id.
    /// @return uint256 The minimum amount of tokens required in a single deposit Tx. Only applies to Native & ERC20 tokens.
    function getMinDepositByListingId(uint8 _listingId) public view returns (uint256) {
        return s.config.minDeposit[_listingId];
    }

    /// @notice Check if the listingId is paused or not.
    /// @param _listingId Listing Id.
    /// @return bool `true` If the listing Id is paused, otherwise `false`.
    function getIsPausedByListingId(uint8 _listingId) public view returns (bool) {
        return s.pausedTokens[_listingId];
    }

    /// @notice Get the domain separator of the portal.
    /// @return bytes32 Domain separator in form of a bytes32.
    function getDomainSeparator() public view returns (bytes32) {
        return s.domainSeparator;
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