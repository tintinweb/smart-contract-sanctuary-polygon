// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - TxERC1155 Facet
/// @dev This contract provides functions for user to deposit listed ERC1155 token into the portal.
/******************************************************************************/

import {AppStorage} from "../libraries/AppStorage.sol";
import {LibTokenManagement} from "../libraries/LibTokenManagement.sol";
import {LibSafeCast} from "../libraries/LibSafeCast.sol";
import {LibOperations} from "../libraries/LibOperations.sol";
import {LibStatusControl} from "../libraries/LibStatusControl.sol";
import {IOperations} from "../interfaces/IOperations.sol";
import {IERC1155} from "../interfaces/IERC1155.sol";

contract TxERC1155Facet is IOperations {
    /* ------ TYPE & VARIABLES ------ */

    /// @dev declare AppStorage.
    AppStorage internal s;

    /* ------ EVENTS ------ */

    /// @dev Event emitted when a new deposit is successful.
    event NewDeposit(
        address from,
        uint8 listingId,
        uint88 tokenId,
        uint88 amount,
        uint128 newRequestId,
        uint256 currentBatchId
    );

    /// @dev Event emitted when a new batch deposit is successful.
    event NewDepositBatch(
        address from,
        uint8 listingId,
        uint88[] tokenIds,
        uint88[] amounts,
        uint128 newRequestId,
        uint256 currentBatchId
    );

    /* ------ EXTERNAL FUNTIONS ------ */

    /// @notice Deposit a listed ERC1155 token to the portal.
    /// @dev Deposit-related features must be enabled.
    /// @dev Require the deposit token already listed and not paused.
    /// @param _tokenAddress Token's address
    /// @param _tokenId Id of the token on its contract.
    /// @param _amount Amount to deposit.
    function depositERC1155(IERC1155 _tokenAddress, uint88 _tokenId, uint88 _amount) external {
        LibStatusControl._requireDepositEnabled();

        uint8 listingId_ = LibTokenManagement._validateTokenAddress(address(_tokenAddress));
        LibTokenManagement._requireUnpaused(listingId_);

        _depositAndCheck(_tokenAddress, _tokenId, _amount);

        uint128 currentDepositRequestId = s.currentDepositRequestId;

        Deposit memory deposit = Deposit({
            from: msg.sender,
            listingId: listingId_,
            tokenId: _tokenId,
            amount: _amount,
            requestId: currentDepositRequestId
        });

        bytes32 hashDepositRequest = keccak256(
            abi.encode(s.domainSeparator, LibOperations._hashDepositRequest(deposit))
        );

        LibOperations._addPendingRequest(hashDepositRequest, currentDepositRequestId);

        emit NewDeposit(
            msg.sender,
            deposit.listingId,
            deposit.tokenId,
            deposit.amount,
            currentDepositRequestId,
            s.currentBatchId
        );
    }

    /// @notice Deposit a batch of listed ERC1155 token to portal.
    /// @dev Deposit-related features must be enabled.
    /// @dev Require the deposit token already listed and not paused.
    /// @param _tokenAddress Token's address
    /// @param _tokenIds Array of tokenId.
    /// @param _amounts Array of amount to deposit of each tokenId.
    function depositBatchERC1155(
        IERC1155 _tokenAddress,
        uint88[] calldata _tokenIds,
        uint88[] calldata _amounts
    ) external {
        require(_tokenIds.length == _amounts.length, "TE1155F: tokenIds and amounts length mismatch");
        require(_tokenIds.length > 1 && _tokenIds.length <= 10, "TE1155F: tokenIds and amounts length out of range");
        LibStatusControl._requireDepositEnabled();
        uint8 listingId_ = LibTokenManagement._validateTokenAddress(address(_tokenAddress));
        LibTokenManagement._requireUnpaused(listingId_);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            _depositAndCheck(_tokenAddress, _tokenIds[i], _amounts[i]);
        }

        uint128 currentDepositRequestId = s.currentDepositRequestId;

        DepositBatch memory depositBatch = DepositBatch({
            from: msg.sender,
            listingId: listingId_,
            arrayLength: LibSafeCast.toUint8(_tokenIds.length),
            tokenIds: _tokenIds,
            amounts: _amounts,
            requestId: currentDepositRequestId
        });

        bytes32 hashDepositBatchRequest = keccak256(
            abi.encode(s.domainSeparator, LibOperations._hashDepositBatchRequest(depositBatch))
        );
        LibOperations._addPendingRequest(hashDepositBatchRequest, currentDepositRequestId);

        emit NewDepositBatch(
            msg.sender,
            depositBatch.listingId,
            depositBatch.tokenIds,
            depositBatch.amounts,
            currentDepositRequestId,
            s.currentBatchId
        );
    }

    /* ------ INTERNAL FUNTIONS ------ */

    /// @notice Check before deposit
    /// @param _tokenAddress Token's address
    /// @param _tokenId Id of the token on its contract.
    /// @param _amount Amount to deposit.
    function _depositAndCheck(IERC1155 _tokenAddress, uint256 _tokenId, uint256 _amount) internal returns (uint88) {
        uint256 balanceBefore = _tokenAddress.balanceOf(address(this), _tokenId);
        _tokenAddress.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        uint256 balanceAfter = _tokenAddress.balanceOf(address(this), _tokenId);
        uint88 depositAmount = LibSafeCast.toUint88(balanceAfter - balanceBefore);
        require(depositAmount > 0, "TE1155F: Invalid deposit amount");

        return depositAmount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity 0.8.9;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

    /**
     * @dev This is a virtual function to make the mint feature available.
     *
     * Requirements:
     *
     * The ERC1155 contract should support and apply access control to the caller of this function.
     *
     * Emits a {Transfer} event.
     */
    function mint(address to, uint256 tokenId, uint256 amount) external;

    /**
     * @dev This is a virtual function to make the mint feature available.
     *
     * Requirements:
     *
     * The ERC1155 contract should support and apply access control to the caller of this function.
     *
     * Emits a {Transfer} event.
     */
    function mint(
        uint256 _deadline,
        uint256 _batchID,
        uint256 _amount,
        string calldata _salt,
        bytes calldata signature
    ) external;

    /**
     * @dev This is a virtual function to make the mint batch feature available.
     *
     * Requirements:
     *
     * The ERC1155 contract should support and apply access control to the caller of this function.
     *
     * Emits a {Transfer} event.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external;

    /**
     * @dev This is a virtual function to make the mint batch feature available.
     *
     * Requirements:
     *
     * The ERC1155C contract should support and apply access control to the caller of this function.
     *
     * Emits a {Transfer} event.
     */
    function mintBatch(
        uint256 _deadline,
        uint256[] memory _batchID,
        uint256[] memory _amount,
        string memory _salt,
        bytes memory signature
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Operations
/// @dev This library provides internal functions for facets related to transaction processing.
/******************************************************************************/

import {LibAppStorage, AppStorage} from "./AppStorage.sol";
import {LibBytes} from "./LibBytes.sol";
import {LibSafeCast} from "./LibSafeCast.sol";
import {IOperations} from "../interfaces/IOperations.sol";

library LibOperations {
    /// @dev Expiration delta for onchain request to be satisfied (in seconds)
    uint256 internal constant REQUEST_EXPIRATION_PERIOD = 1; // test exist

    /* ------ EXTERNAL FUNTIONS ------ */

    /// @notice Check if the input data can re-create the Merkle stageRoot.
    /// @param _stateRoot bytes32 stageRoot from the latest commit.
    /// @param _defaultReceiver The default receiver's address
    /// @param _listingId The listingId of the token.
    /// @param _tokenId The tokenId of asset.
    /// @param _amount The amount of asset.
    /// @param proofs The list of proofs to reconstruct the merkle tree.
    /// @return bool <true> the input data is valid, otherwise <false>.
    function _verifyMerkle(
        bytes32 _stateRoot,
        address _defaultReceiver,
        uint8 _listingId,
        uint88 _tokenId,
        uint128 _amount,
        bytes32[] calldata proofs
    ) external pure returns (bool) {
        require(_stateRoot != bytes32(0), "LibOperations: Invalid state root");
        bytes32 computedHash = keccak256(abi.encode(_defaultReceiver, _listingId, _tokenId, _amount));
        for (uint256 i = 0; i < proofs.length; i++) {
            computedHash = _hashPair(computedHash, proofs[i]);
        }
        return computedHash == _stateRoot;
    }

    /* ------ INTERNAL FUNTIONS ------ */

    /// @notice Read bytes input to reconstruct the Deposit request data struct
    /// @param _data Data input in bytes
    function _readDepositRequest(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (IOperations.Deposit memory deposit) {
        // request length must be 60 bytes
        require(_data.length == 60, "Operations: Invalid data length");
        uint256 offset = _offset; //offset start from 1
        (offset, deposit.from) = LibBytes.readAddress(_data, offset);
        (offset, deposit.listingId) = LibBytes.readUInt8(_data, offset);
        (offset, deposit.tokenId) = LibBytes.readUInt88(_data, offset);
        (offset, deposit.amount) = LibBytes.readUInt88(_data, offset);
        (offset, deposit.requestId) = LibBytes.readUInt128(_data, offset);
        //59 bytes
        require(_data.length == offset, "Operations: Invalid data length");
    }

    /// @notice Read bytes input to reconstruct the DepositBatch request data struct
    function _readDepositBatchRequest(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (IOperations.DepositBatch memory depositBatch) {
        uint256 offset = _offset;
        // offset start from 1
        (offset, depositBatch.from) = LibBytes.readAddress(_data, offset);
        (offset, depositBatch.listingId) = LibBytes.readUInt8(_data, offset);
        (offset, depositBatch.arrayLength) = LibBytes.readUInt8(_data, offset);
        require(depositBatch.arrayLength > 1 && depositBatch.arrayLength < 21, "Operations: Invalid batch length");
        (offset, depositBatch.tokenIds) = LibBytes.readUInt88Array(_data, offset, depositBatch.arrayLength);
        (offset, depositBatch.amounts) = LibBytes.readUInt88Array(_data, offset, depositBatch.arrayLength);
        (offset, depositBatch.requestId) = LibBytes.readUInt128(_data, offset);
        // min 82 + (n-2)*22 bytes| n>=2;n<=20
        require(_data.length == offset, "Operations: Invalid data length");
    }

    /// @notice Read bytes input to reconstruct the Withdraw request data struct
    function _readWithdrawRequest(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (IOperations.Withdraw memory withdraw) {
        require(_data.length == 44, "Operations: Invalid data length");
        uint256 offset = _offset; //offset start from 1
        (offset, withdraw.to) = LibBytes.readAddress(_data, offset);
        (offset, withdraw.listingId) = LibBytes.readUInt8(_data, offset);
        (offset, withdraw.tokenId) = LibBytes.readUInt88(_data, offset);
        (offset, withdraw.amount) = LibBytes.readUInt88(_data, offset);
        //43 bytes
    }

    /// @notice Read bytes input to reconstruct the Withdraw1155C request data struct
    function _readWithdraw1155CRequest(
        bytes memory _data,
        uint256 _offset
    ) internal pure returns (IOperations.Withdraw1155C memory withdraw1155C) {
        require(_data.length > 112 && (_data.length - 91) % 11 == 0, "Operations: Invalid data length");
        uint256 offset = _offset; //offset start from 1
        withdraw1155C.executeSig = LibBytes.slice(_data, offset, 65);
        offset = 66;
        (offset, withdraw1155C.to) = LibBytes.readAddress(_data, offset);
        (offset, withdraw1155C.salt) = LibBytes.readUInt24(_data, offset);
        (offset, withdraw1155C.listingId) = LibBytes.readUInt8(_data, offset);
        (offset, withdraw1155C.arrayLength) = LibBytes.readUInt8(_data, offset);
        require(withdraw1155C.arrayLength > 0 && withdraw1155C.arrayLength < 21, "Operations: Invalid batch length");
        (offset, withdraw1155C.tokenIds) = LibBytes.readUInt88Array(_data, offset, withdraw1155C.arrayLength);
        (offset, withdraw1155C.amounts) = LibBytes.readUInt88Array(_data, offset, withdraw1155C.arrayLength);
        //min 112 + (n-2)*16 bytes| n>=2;n<=21
    }

    /// @notice This internal function is used to add a new pending request
    /// @param _hashedRequestData hashed request data
    function _addPendingRequest(bytes32 _hashedRequestData, uint128 _newRequestId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(
            s.numberOfPendingRequest < s.config.maxNumberOfPendingRequests,
            "Operations: too many pending requests"
        );

        require(s.pendingDepositRecord[_newRequestId].hashedRequestData == 0, "Operations: requesionId already exist");
        s.pendingDepositRecord[_newRequestId] = IOperations.PendingDepositRecord({
            hashedRequestData: _hashedRequestData,
            expirationTimestamp: block.timestamp + REQUEST_EXPIRATION_PERIOD
        });

        s.currentDepositRequestId++;
        s.numberOfPendingRequest++;
    }

    /// @notice This internal function is used to create a hash of the Deposit request data struct
    /// @param deposit A deposit data struct
    /// @return r hashed bytes32 of input data
    function _hashDepositRequest(IOperations.Deposit memory deposit) internal pure returns (bytes32 r) {
        r = keccak256(abi.encode(deposit.from, deposit.listingId, deposit.tokenId, deposit.amount));
    }

    /// @notice Hash the DepositBatch data struct
    /// @param depositBatch A batch deposit data struct
    /// @return r hashed bytes32 of input data
    function _hashDepositBatchRequest(IOperations.DepositBatch memory depositBatch) internal pure returns (bytes32 r) {
        r = keccak256(
            abi.encode(
                depositBatch.from,
                depositBatch.listingId,
                keccak256(abi.encode(depositBatch.tokenIds)),
                keccak256(abi.encode(depositBatch.amounts))
            )
        );
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function _concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    /* ------ PRIVATE FUNTIONS ------ */
    /// @notice Private function to process the proofs.
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    /// @notice Private function to process the proofs.
    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Safe Cast
/// @dev This library provides unsigned integer data type conversion functions .

* Implementation of OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
/******************************************************************************/

/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library LibSafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2 ** 128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value < 2 ** 88, "11");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2 ** 64, "08");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2 ** 40, "05");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2 ** 32, "04");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2 ** 16, "02");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2 ** 8, "01");
        return uint8(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Status Control
/// @dev This library provides internal functions to check the portal's operating status conditions.
/******************************************************************************/

import {LibAppStorage, AppStorage} from "./AppStorage.sol";

/// @dev System status
///      status == 0 Contract is in Migrate mode, disable deposit-related features, keeping all withdrawal-related features enabled before the migration time is half over. Prepare for migrating to a new contract version.
///      status == 1 Contract is in Active mode, only disable exit-related features. This is the normal working state of the portal.
///      status == 2 Contract is in Maintenance mode, disable all deposit & withdrawal-related features. Anyone can turn off Maintenance mode after it expires.
///      status == 3 Contract is in MassExit mode, enable exit features, only available when no operations are performed before the expiration time.

library LibStatusControl {
    /// @notice Checks if deposit features are enabled
    function _requireDepositEnabled() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.status == 1, "Status Control: Deposit is not enabled");
    }

    /// @notice Checks if operations features are enabled
    function _requireOperationsEnabled() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.status == 1 || s.status == 2, "Status Control: Operations are not enabled");
    }

    /// @notice Checks if withdraw features are enabled
    function _requireWithdrawEnabled() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.status == 1, "Status Control: Withdrawal is not enabled");
    }

    /// @notice Checks that current state is Maintenance
    function _requireExitEnabled() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.status == 3, "Status Control: Exit is not enabled");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/******************************************************************************\
/// @title Portal - Library Token Management
/// @dev This library provides functions to check & validate listed token.
/******************************************************************************/

import {LibAppStorage, AppStorage} from "./AppStorage.sol";

library LibTokenManagement {
    /// @notice Validate if token address is valid, except for native token which has listingId = 0 by default
    /// @param _tokenAddr Token address
    /// @return listingId Token's listingId
    function _validateTokenAddress(address _tokenAddr) internal view returns (uint8) {
        require(_tokenAddr != address(0), "Token Management: Invalid token address");
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint8 listingId = s.listingIds[_tokenAddr];
        require(listingId != 0, "Token Management: Invalid token address");
        return listingId;
    }

    /// @notice Validate if listingId is valid, except for native token which has listingId = 0 by default
    /// @param _listingId Token's listingId
    /// @return tokenAddr Address of valid listingId
    function _validateListingId(uint8 _listingId) internal view returns (address) {
        require(_listingId != 0, "Token Management: Invalid listing ID");

        AppStorage storage s = LibAppStorage.diamondStorage();

        address tokenAddr = s.tokenAddresses[_listingId];
        require(tokenAddr != address(0), "Token Management: Invalid listing ID");

        return tokenAddr;
    }

    /// @notice Checks that token is not paused
    function _requireUnpaused(uint8 _listingId) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.pausedTokens[_listingId], "Token Management: Token is paused");
    }
}