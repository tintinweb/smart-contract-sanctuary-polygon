/**
 *Submitted for verification at polygonscan.com on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// File: node_modules\@openzeppelin\contracts\utils\Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)


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
// File: @openzeppelin\contracts\access\Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: @openzeppelin\contracts\utils\Strings.sol
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)


/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequestBoardEvents.sol
/// @title Witnet Request Board emitting events interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardEvents {
    /// Emitted when a Witnet Data Request is posted to the WRB.
    event PostedRequest(uint256 queryId, address from);

    /// Emitted when a Witnet-solved result is reported to the WRB.
    event PostedResult(uint256 queryId, address from);

    /// Emitted when all data related to given query is deleted from the WRB.
    event DeletedQuery(uint256 queryId, address from);
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequestBoardReporter.sol
/// @title The Witnet Request Board Reporter interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardReporter {
    /// Reports the Witnet-provided result to a previously posted request. 
    /// @dev Will assume `block.timestamp` as the timestamp at which the request was solved.
    /// @dev Fails if:
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique identifier of the data request.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(uint256 _queryId, bytes32 _drTxHash, bytes calldata _result) external;

    /// Reports the Witnet-provided result to a previously posted request.
    /// @dev Fails if:
    /// @dev - called from unauthorized address;
    /// @dev - the `_queryId` is not in 'Posted' status.
    /// @dev - provided `_drTxHash` is zero;
    /// @dev - length of provided `_result` is zero.
    /// @param _queryId The unique query identifier
    /// @param _timestamp The timestamp of the solving tally transaction in Witnet.
    /// @param _drTxHash The hash of the solving tally transaction in Witnet.
    /// @param _result The result itself as bytes.
    function reportResult(uint256 _queryId, uint256 _timestamp, bytes32 _drTxHash, bytes calldata _result) external;
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequest.sol
/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\libs\Witnet.sol
library Witnet {

    /// @notice Witnet function that computes the hash of a CBOR-encoded Data Request.
    /// @param _bytecode CBOR-encoded RADON.
    function hash(bytes memory _bytecode) internal pure returns (bytes32) {
        return sha256(_bytecode);
    }

    /// Struct containing both request and response data related to every query posted to the Witnet Request Board
    struct Query {
        Request request;
        Response response;
    }

    /// Possible status of a Witnet query.
    enum QueryStatus {
        Unknown,
        Posted,
        Reported,
        Deleted
    }

    /// Data kept in EVM-storage for every Request posted to the Witnet Request Board.
    struct Request {
        IWitnetRequest addr;    // The contract containing the Data Request which execution has been requested.
        address requester;      // Address from which the request was posted.
        bytes32 hash;           // Hash of the Data Request whose execution has been requested.
        uint256 gasprice;       // Minimum gas price the DR resolver should pay on the solving tx.
        uint256 reward;         // Escrowed reward to be paid to the DR resolver.
    }

    /// Data kept in EVM-storage containing Witnet-provided response metadata and result.
    struct Response {
        address reporter;       // Address from which the result was reported.
        uint256 timestamp;      // Timestamp of the Witnet-provided result.
        bytes32 drTxHash;       // Hash of the Witnet transaction that solved the queried Data Request.
        bytes   cborBytes;      // Witnet-provided result CBOR-bytes to the queried Data Request.
    }

    /// Data struct containing the Witnet-provided result to a Data Request.
    struct Result {
        bool success;           // Flag stating whether the request could get solved successfully, or not.
        CBOR value;             // Resulting value, in CBOR-serialized bytes.
    }

    /// Data struct following the RFC-7049 standard: Concise Binary Object Representation.
    struct CBOR {
        Buffer buffer;
        uint8 initialByte;
        uint8 majorType;
        uint8 additionalInformation;
        uint64 len;
        uint64 tag;
    }

    /// Iterable bytes buffer.
    struct Buffer {
        bytes data;
        uint32 cursor;
    }

    /// Witnet error codes table.
    enum ErrorCodes {
        // 0x00: Unknown error. Something went really bad!
        Unknown,
        // Script format errors
        /// 0x01: At least one of the source scripts is not a valid CBOR-encoded value.
        SourceScriptNotCBOR,
        /// 0x02: The CBOR value decoded from a source script is not an Array.
        SourceScriptNotArray,
        /// 0x03: The Array value decoded form a source script is not a valid Data Request.
        SourceScriptNotRADON,
        /// Unallocated
        ScriptFormat0x04,
        ScriptFormat0x05,
        ScriptFormat0x06,
        ScriptFormat0x07,
        ScriptFormat0x08,
        ScriptFormat0x09,
        ScriptFormat0x0A,
        ScriptFormat0x0B,
        ScriptFormat0x0C,
        ScriptFormat0x0D,
        ScriptFormat0x0E,
        ScriptFormat0x0F,
        // Complexity errors
        /// 0x10: The request contains too many sources.
        RequestTooManySources,
        /// 0x11: The script contains too many calls.
        ScriptTooManyCalls,
        /// Unallocated
        Complexity0x12,
        Complexity0x13,
        Complexity0x14,
        Complexity0x15,
        Complexity0x16,
        Complexity0x17,
        Complexity0x18,
        Complexity0x19,
        Complexity0x1A,
        Complexity0x1B,
        Complexity0x1C,
        Complexity0x1D,
        Complexity0x1E,
        Complexity0x1F,
        // Operator errors
        /// 0x20: The operator does not exist.
        UnsupportedOperator,
        /// Unallocated
        Operator0x21,
        Operator0x22,
        Operator0x23,
        Operator0x24,
        Operator0x25,
        Operator0x26,
        Operator0x27,
        Operator0x28,
        Operator0x29,
        Operator0x2A,
        Operator0x2B,
        Operator0x2C,
        Operator0x2D,
        Operator0x2E,
        Operator0x2F,
        // Retrieval-specific errors
        /// 0x30: At least one of the sources could not be retrieved, but returned HTTP error.
        HTTP,
        /// 0x31: Retrieval of at least one of the sources timed out.
        RetrievalTimeout,
        /// Unallocated
        Retrieval0x32,
        Retrieval0x33,
        Retrieval0x34,
        Retrieval0x35,
        Retrieval0x36,
        Retrieval0x37,
        Retrieval0x38,
        Retrieval0x39,
        Retrieval0x3A,
        Retrieval0x3B,
        Retrieval0x3C,
        Retrieval0x3D,
        Retrieval0x3E,
        Retrieval0x3F,
        // Math errors
        /// 0x40: Math operator caused an underflow.
        Underflow,
        /// 0x41: Math operator caused an overflow.
        Overflow,
        /// 0x42: Tried to divide by zero.
        DivisionByZero,
        /// Unallocated
        Math0x43,
        Math0x44,
        Math0x45,
        Math0x46,
        Math0x47,
        Math0x48,
        Math0x49,
        Math0x4A,
        Math0x4B,
        Math0x4C,
        Math0x4D,
        Math0x4E,
        Math0x4F,
        // Other errors
        /// 0x50: Received zero reveals
        NoReveals,
        /// 0x51: Insufficient consensus in tally precondition clause
        InsufficientConsensus,
        /// 0x52: Received zero commits
        InsufficientCommits,
        /// 0x53: Generic error during tally execution
        TallyExecution,
        /// Unallocated
        OtherError0x54,
        OtherError0x55,
        OtherError0x56,
        OtherError0x57,
        OtherError0x58,
        OtherError0x59,
        OtherError0x5A,
        OtherError0x5B,
        OtherError0x5C,
        OtherError0x5D,
        OtherError0x5E,
        OtherError0x5F,
        /// 0x60: Invalid reveal serialization (malformed reveals are converted to this value)
        MalformedReveal,
        /// Unallocated
        OtherError0x61,
        OtherError0x62,
        OtherError0x63,
        OtherError0x64,
        OtherError0x65,
        OtherError0x66,
        OtherError0x67,
        OtherError0x68,
        OtherError0x69,
        OtherError0x6A,
        OtherError0x6B,
        OtherError0x6C,
        OtherError0x6D,
        OtherError0x6E,
        OtherError0x6F,
        // Access errors
        /// 0x70: Tried to access a value from an index using an index that is out of bounds
        ArrayIndexOutOfBounds,
        /// 0x71: Tried to access a value from a map using a key that does not exist
        MapKeyNotFound,
        /// Unallocated
        OtherError0x72,
        OtherError0x73,
        OtherError0x74,
        OtherError0x75,
        OtherError0x76,
        OtherError0x77,
        OtherError0x78,
        OtherError0x79,
        OtherError0x7A,
        OtherError0x7B,
        OtherError0x7C,
        OtherError0x7D,
        OtherError0x7E,
        OtherError0x7F,
        OtherError0x80,
        OtherError0x81,
        OtherError0x82,
        OtherError0x83,
        OtherError0x84,
        OtherError0x85,
        OtherError0x86,
        OtherError0x87,
        OtherError0x88,
        OtherError0x89,
        OtherError0x8A,
        OtherError0x8B,
        OtherError0x8C,
        OtherError0x8D,
        OtherError0x8E,
        OtherError0x8F,
        OtherError0x90,
        OtherError0x91,
        OtherError0x92,
        OtherError0x93,
        OtherError0x94,
        OtherError0x95,
        OtherError0x96,
        OtherError0x97,
        OtherError0x98,
        OtherError0x99,
        OtherError0x9A,
        OtherError0x9B,
        OtherError0x9C,
        OtherError0x9D,
        OtherError0x9E,
        OtherError0x9F,
        OtherError0xA0,
        OtherError0xA1,
        OtherError0xA2,
        OtherError0xA3,
        OtherError0xA4,
        OtherError0xA5,
        OtherError0xA6,
        OtherError0xA7,
        OtherError0xA8,
        OtherError0xA9,
        OtherError0xAA,
        OtherError0xAB,
        OtherError0xAC,
        OtherError0xAD,
        OtherError0xAE,
        OtherError0xAF,
        OtherError0xB0,
        OtherError0xB1,
        OtherError0xB2,
        OtherError0xB3,
        OtherError0xB4,
        OtherError0xB5,
        OtherError0xB6,
        OtherError0xB7,
        OtherError0xB8,
        OtherError0xB9,
        OtherError0xBA,
        OtherError0xBB,
        OtherError0xBC,
        OtherError0xBD,
        OtherError0xBE,
        OtherError0xBF,
        OtherError0xC0,
        OtherError0xC1,
        OtherError0xC2,
        OtherError0xC3,
        OtherError0xC4,
        OtherError0xC5,
        OtherError0xC6,
        OtherError0xC7,
        OtherError0xC8,
        OtherError0xC9,
        OtherError0xCA,
        OtherError0xCB,
        OtherError0xCC,
        OtherError0xCD,
        OtherError0xCE,
        OtherError0xCF,
        OtherError0xD0,
        OtherError0xD1,
        OtherError0xD2,
        OtherError0xD3,
        OtherError0xD4,
        OtherError0xD5,
        OtherError0xD6,
        OtherError0xD7,
        OtherError0xD8,
        OtherError0xD9,
        OtherError0xDA,
        OtherError0xDB,
        OtherError0xDC,
        OtherError0xDD,
        OtherError0xDE,
        OtherError0xDF,
        // Bridge errors: errors that only belong in inter-client communication
        /// 0xE0: Requests that cannot be parsed must always get this error as their result.
        /// However, this is not a valid result in a Tally transaction, because invalid requests
        /// are never included into blocks and therefore never get a Tally in response.
        BridgeMalformedRequest,
        /// 0xE1: Witnesses exceeds 100
        BridgePoorIncentives,
        /// 0xE2: The request is rejected on the grounds that it may cause the submitter to spend or stake an
        /// amount of value that is unjustifiably high when compared with the reward they will be getting
        BridgeOversizedResult,
        /// Unallocated
        OtherError0xE3,
        OtherError0xE4,
        OtherError0xE5,
        OtherError0xE6,
        OtherError0xE7,
        OtherError0xE8,
        OtherError0xE9,
        OtherError0xEA,
        OtherError0xEB,
        OtherError0xEC,
        OtherError0xED,
        OtherError0xEE,
        OtherError0xEF,
        OtherError0xF0,
        OtherError0xF1,
        OtherError0xF2,
        OtherError0xF3,
        OtherError0xF4,
        OtherError0xF5,
        OtherError0xF6,
        OtherError0xF7,
        OtherError0xF8,
        OtherError0xF9,
        OtherError0xFA,
        OtherError0xFB,
        OtherError0xFC,
        OtherError0xFD,
        OtherError0xFE,
        // This should not exist:
        /// 0xFF: Some tally error is not intercepted but should
        UnhandledIntercept
    }
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequestBoardRequestor.sol
/// @title Witnet Requestor Interface
/// @notice It defines how to interact with the Witnet Request Board in order to:
///   - request the execution of Witnet Radon scripts (data request);
///   - upgrade the resolution reward of any previously posted request, in case gas price raises in mainnet;
///   - read the result of any previously posted request, eventually reported by the Witnet DON.
///   - remove from storage all data related to past and solved data requests, and results.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardRequestor {
    /// Retrieves a copy of all Witnet-provided data related to a previously posted request, removing the whole query from the WRB storage.
    /// @dev Fails if the `_queryId` is not in 'Reported' status, or called from an address different to
    /// @dev the one that actually posted the given request.
    /// @param _queryId The unique query identifier.
    function deleteQuery(uint256 _queryId) external returns (Witnet.Response memory);

    /// Requests the execution of the given Witnet Data Request in expectation that it will be relayed and solved by the Witnet DON.
    /// A reward amount is escrowed by the Witnet Request Board that will be transferred to the reporter who relays back the Witnet-provided 
    /// result to this request.
    /// @dev Fails if:
    /// @dev - provided reward is too low.
    /// @dev - provided script is zero address.
    /// @dev - provided script bytecode is empty.
    /// @param _addr The address of the IWitnetRequest contract that can provide the actual Data Request bytecode.
    /// @return _queryId An unique query identifier.
    function postRequest(IWitnetRequest _addr) external payable returns (uint256 _queryId);

    /// Increments the reward of a previously posted request by adding the transaction value to it.
    /// @dev Updates request `gasPrice` in case this method is called with a higher 
    /// @dev gas price value than the one used in previous calls to `postRequest` or
    /// @dev `upgradeReward`. 
    /// @dev Fails if the `_queryId` is not in 'Posted' status.
    /// @dev Fails also in case the request `gasPrice` is increased, and the new 
    /// @dev reward value gets below new recalculated threshold. 
    /// @param _queryId The unique query identifier.
    function upgradeReward(uint256 _queryId) external payable;
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequestBoardView.sol
/// @title Witnet Request Board info interface.
/// @author The Witnet Foundation.
interface IWitnetRequestBoardView {
    /// Estimates the amount of reward we need to insert for a given gas price.
    /// @param _gasPrice The gas price for which we need to calculate the rewards.
    function estimateReward(uint256 _gasPrice) external view returns (uint256);

    /// Returns next query id to be generated by the Witnet Request Board.
    function getNextQueryId() external view returns (uint256);

    /// Gets the whole Query data contents, if any, no matter its current status.
    function getQueryData(uint256 _queryId) external view returns (Witnet.Query memory);

    /// Gets current status of given query.
    function getQueryStatus(uint256 _queryId) external view returns (Witnet.QueryStatus);

    /// Retrieves the whole `Witnet.Request` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting result 
    /// to the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has been deleted,
    /// @dev or if the related script bytecode got changed after being posted.
    /// @param _queryId The unique query identifier.
    function readRequestReward(uint256 _queryId) external view returns (uint256);

    /// Retrieves the whole `Witnet.Response` record referred to a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponse(uint256 _queryId) external view returns (Witnet.Response memory);

    /// Retrieves the hash of the Witnet transaction hash that actually solved the referred query.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseDrTxHash(uint256 _queryId) external view returns (bytes32);    

    /// Retrieves the address that reported the result to a previously-posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseReporter(uint256 _queryId) external view returns (address);

    /// Retrieves the Witnet-provided CBOR-bytes result of a previously posted request.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseResult(uint256 _queryId) external view returns (Witnet.Result memory);

    /// Retrieves the timestamp in which the result to the referred query was solved by the Witnet DON.
    /// @dev Fails if the `_queryId` is not in 'Reported' status.
    /// @param _queryId The unique query identifier.
    function readResponseTimestamp(uint256 _queryId) external view returns (uint256);
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequestParser.sol
/// @title The Witnet interface for decoding Witnet-provided request to Data Requests.
/// This interface exposes functions to check for the success/failure of
/// a Witnet-provided result, as well as to parse and convert result into
/// Solidity types suitable to the application level. 
/// @author The Witnet Foundation.
interface IWitnetRequestParser {

    /// Decode raw CBOR bytes into a Witnet.Result instance.
    /// @param _cborBytes Raw bytes representing a CBOR-encoded value.
    /// @return A `Witnet.Result` instance.
    function resultFromCborBytes(bytes memory _cborBytes) external pure returns (Witnet.Result memory);

    /// Decode a CBOR value into a Witnet.Result instance.
    /// @param _cborValue An instance of `Witnet.CBOR`.
    /// @return A `Witnet.Result` instance.
    function resultFromCborValue(Witnet.CBOR memory _cborValue) external pure returns (Witnet.Result memory);

    /// Tell if a Witnet.Result is successful.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if successful, `false` if errored.
    function isOk(Witnet.Result memory _result) external pure returns (bool);

    /// Tell if a Witnet.Result is errored.
    /// @param _result An instance of Witnet.Result.
    /// @return `true` if errored, `false` if successful.
    function isError(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a bytes value from a Witnet.Result as a `bytes` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes` decoded from the Witnet.Result.
    function asBytes(Witnet.Result memory _result) external pure returns (bytes memory);

    /// Decode a bytes value from a Witnet.Result as a `bytes32` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bytes32` decoded from the Witnet.Result.
    function asBytes32(Witnet.Result memory _result) external pure returns (bytes32);

    /// Decode an error code from a Witnet.Result as a member of `Witnet.ErrorCodes`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `CBORValue.Error memory` decoded from the Witnet.Result.
    function asErrorCode(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes);


    /// Generate a suitable error message for a member of `Witnet.ErrorCodes` and its corresponding arguments.
    /// @dev WARN: Note that client contracts should wrap this function into a try-catch foreseing potential errors generated in this function
    /// @param _result An instance of `Witnet.Result`.
    /// @return A tuple containing the `CBORValue.Error memory` decoded from the `Witnet.Result`, plus a loggable error message.
    function asErrorMessage(Witnet.Result memory _result) external pure returns (Witnet.ErrorCodes, string memory);

    /// Decode a raw error from a `Witnet.Result` as a `uint64[]`.
    /// @param _result An instance of `Witnet.Result`.
    /// @return The `uint64[]` raw error as decoded from the `Witnet.Result`.
    function asRawError(Witnet.Result memory _result) external pure returns(uint64[] memory);

    /// Decode a boolean value from a Witnet.Result as an `bool` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `bool` decoded from the Witnet.Result.
    function asBool(Witnet.Result memory _result) external pure returns (bool);

    /// Decode a fixed16 (half-precision) numeric value from a Witnet.Result as an `int32` value.
    /// @dev Due to the lack of support for floating or fixed point arithmetic in the EVM, this method offsets all values.
    /// by 5 decimal orders so as to get a fixed precision of 5 decimal positions, which should be OK for most `fixed16`.
    /// use cases. In other words, the output of this method is 10,000 times the actual value, encoded into an `int32`.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asFixed16(Witnet.Result memory _result) external pure returns (int32);

    /// Decode an array of fixed16 values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asFixed16Array(Witnet.Result memory _result) external pure returns (int32[] memory);

    /// Decode a integer numeric value from a Witnet.Result as an `int128` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128` decoded from the Witnet.Result.
    function asInt128(Witnet.Result memory _result) external pure returns (int128);

    /// Decode an array of integer numeric values from a Witnet.Result as an `int128[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `int128[]` decoded from the Witnet.Result.
    function asInt128Array(Witnet.Result memory _result) external pure returns (int128[] memory);

    /// Decode a string value from a Witnet.Result as a `string` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string` decoded from the Witnet.Result.
    function asString(Witnet.Result memory _result) external pure returns (string memory);

    /// Decode an array of string values from a Witnet.Result as a `string[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `string[]` decoded from the Witnet.Result.
    function asStringArray(Witnet.Result memory _result) external pure returns (string[] memory);

    /// Decode a natural numeric value from a Witnet.Result as a `uint64` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64` decoded from the Witnet.Result.
    function asUint64(Witnet.Result memory _result) external pure returns(uint64);

    /// Decode an array of natural numeric values from a Witnet.Result as a `uint64[]` value.
    /// @param _result An instance of Witnet.Result.
    /// @return The `uint64[]` decoded from the Witnet.Result.
    function asUint64Array(Witnet.Result memory _result) external pure returns (uint64[] memory);

}
// File: witnet-solidity-bridge\contracts\WitnetRequestBoard.sol
/// @title Witnet Request Board functionality base contract.
/// @author The Witnet Foundation.
abstract contract WitnetRequestBoard is
    IWitnetRequestBoardEvents,
    IWitnetRequestBoardReporter,
    IWitnetRequestBoardRequestor,
    IWitnetRequestBoardView,
    IWitnetRequestParser
{
    receive() external payable {
        revert("WitnetRequestBoard: no transfers accepted");
    }
}
// File: contracts\libs\WittyBufficornsLib.sol
/// @title WittyBufficornsLib Library: data model and helper functions
/// @author Otherplane Labs, 2022.
library WittyBufficornsLib {

    // ========================================================================
    // --- Storage layout -----------------------------------------------------

    struct Storage {
        address decorator;
        address signator;

        Stats   stats;

        uint256 stopBreedingBlock;
        bytes32 stopBreedingRandomness;
        
        mapping (/* tokenId => FarmerAward */ uint256 => TokenInfo) awards;
        mapping (/* bufficornId => Bufficorn */ uint256 => Bufficorn) bufficorns;
        mapping (/* farmerId => Farmer */ uint256 => Farmer) farmers;
        mapping (/* ranchId => Ranch */ uint256 => Ranch) ranches;
    }


    // ========================================================================
    // --- Enums --------------------------------------------------------------

    enum Awards {
        /* 0 => */ BestBreeder,
        /* 1 => */ BestRanch,

        /* 2 => */ BestBufficorn,

        /* 3 => */ WarmestBufficorn,
        /* 4 => */ CoolestBufficorn,
        /* 5 => */ SmartestBufficorn,      
        /* 6 => */ FastestBufficorn,
        /* 7 => */ MostEnduringBufficorn,
        /* 8 => */ MostVigorousBufficorn
    }

    enum Status {
        /* 0 => */ Breeding,
        /* 1 => */ Randomizing,
        /* 2 => */ Awarding
    }

    enum Traits {
        /* 0 => */ Coat, 
        /* 1 => */ Coolness,
        /* 2 => */ Intelligence,
        /* 3 => */ Speed,
        /* 4 => */ Stamina,
        /* 5 => */ Strength
    }
    

    // ========================================================================
    // --- Structs ------------------------------------------------------------

    struct Award {
        Awards  category;
        uint256 ranking;
        uint256 bufficornId;
    }

    struct Bufficorn {
        string name;
        uint256 score;
        uint256 ranchId;
        uint256[6] traits;
    }

    struct Farmer {
        string  name;
        uint256 score;
        uint256 ranchId;
        uint256 firstTokenId;
        uint256 totalAwards;
    }

    struct Ranch {
        uint256 score;
        string  weatherDescription;
        bytes4  weatherStation;
        uint256 weatherTimestamp;
        WitnetInfo witnet;
    }

    struct Stats {
        uint256 totalBufficorns;
        uint256 totalFarmers;
        uint256 totalRanches;
        uint256 totalSupply;
    }
    
    struct TokenInfo {
        Award   award;
        uint256 farmerId;  
        uint256 expeditionTs;
    }

    struct WitnetInfo {
        uint256 lastValidQueryId;
        uint256 latestQueryId;
        IWitnetRequest request;
    }

    struct TokenMetadata {
        TokenInfo tokenInfo;
        Farmer farmer;
        Ranch ranch;
        Bufficorn bufficorn;
    }


    // ========================================================================
    // --- Public: 'Storage' selectors ----------------------------------------

    function status(Storage storage self)
        public view
        returns (Status)
    {
        if (self.stopBreedingRandomness != bytes32(0)) {
            return Status.Awarding;
        } else if (self.stopBreedingBlock > 0) {
            return Status.Randomizing;
        } else {
            return Status.Breeding;
        }
    }

    function getRanchWeather(
            Storage storage self,
            WitnetRequestBoard _wrb,
            uint256 _ranchId
        )
        public view
        returns (
            uint256 _lastTimestamp,
            string memory _lastDescription
        )
    {
        Ranch storage __ranch = self.ranches[_ranchId];
        uint _lastValidQueryId = __ranch.witnet.lastValidQueryId;
        uint _latestQueryId = __ranch.witnet.latestQueryId;
        Witnet.QueryStatus _latestQueryStatus = _wrb.getQueryStatus(_latestQueryId);
        Witnet.Response memory _response;
        Witnet.Result memory _result;
        // First try to read weather from latest request, in case it was succesfully solved:
        if (_latestQueryId > 0 && _latestQueryStatus == Witnet.QueryStatus.Reported) {
            _response = _wrb.readResponse(_latestQueryId);
            _result = _wrb.resultFromCborBytes(_response.cborBytes);
            if (_result.success) {
                return (
                    _response.timestamp,
                    _wrb.asString(_result)
                );
            }
        }
        if (_lastValidQueryId > 0) {
            // If not solved, or solved with errors, read weather from last valid request, if any:
            _response = _wrb.readResponse(_lastValidQueryId);
            _result = _wrb.resultFromCborBytes(_response.cborBytes);
            _lastTimestamp = _response.timestamp;
            _lastDescription = _wrb.asString(_result);
        }
    }

    function updateRanchWeather(
            Storage storage self,
            WitnetRequestBoard _wrb,
            uint256 _ranchId
        )
        public 
        returns (uint256 _usedFunds)
    {
        Ranch storage __ranch = self.ranches[_ranchId];
        if (address(__ranch.witnet.request) != address(0)) {
            uint _lastValidQueryId = __ranch.witnet.lastValidQueryId;
            uint _latestQueryId = __ranch.witnet.latestQueryId;            
            // Check whether there's no previous request pending to be solved:
            Witnet.QueryStatus _latestQueryStatus = _wrb.getQueryStatus(_latestQueryId);
            if (_latestQueryId == 0 || _latestQueryStatus != Witnet.QueryStatus.Posted) {
                if (_latestQueryId > 0 && _latestQueryStatus == Witnet.QueryStatus.Reported) {
                    Witnet.Result memory _latestResult  = _wrb.readResponseResult(_latestQueryId);
                    if (_latestResult.success) {
                        // If latest request was solved with no errors...
                        if (_lastValidQueryId > 0) {
                            // ... delete last valid response, if any
                            _wrb.deleteQuery(_lastValidQueryId);
                        }
                        // ... and set latest request id as last valid request id.
                        __ranch.witnet.lastValidQueryId = _latestQueryId;
                    }
                }
                // Estimate request fee, in native currency:
                _usedFunds = _wrb.estimateReward(tx.gasprice);
                
                // Post weather update request to the WitnetRequestBoard contract:
                __ranch.witnet.latestQueryId = _wrb.postRequest{value: _usedFunds}(__ranch.witnet.request);
                
                if (_usedFunds < msg.value) {
                    // Transfer back unused funds, if any:
                    payable(msg.sender).transfer(msg.value - _usedFunds);
                }
            }
        }
    }


    // ========================================================================
    // --- Public: 'Awards' selectors ------------------------------------------

    function toString(Awards self)
        public pure
        returns (string memory)
    {
        if (self == Awards.BestBufficorn) {
            return "Best Overall Bufficorn";
        } else if (self == Awards.WarmestBufficorn) {
            return "Warmest Bufficorn";
        } else if (self == Awards.CoolestBufficorn) {
            return "Coolest Bufficorn";
        } else if (self == Awards.SmartestBufficorn) {
            return "Smartest Bufficorn";
        } else if (self == Awards.FastestBufficorn) {
            return "Fastest Bufficorn";
        } else if (self == Awards.MostEnduringBufficorn) {
            return "Most Enduring Bufficorn";
        } else if (self == Awards.MostVigorousBufficorn) {
            return "Most Vigorous Bufficorn";
        } else {
            return "Best Breeder";
        }
    }


    // ========================================================================
    // --- Public: 'Traits' selectors -----------------------------------------

    function toString(Traits self)
        public pure
        returns (string memory)
    {
        if (self == Traits.Coat) {
            return "Coat";
        } else if (self == Traits.Coolness) {
            return "Coolness";
        } else if (self == Traits.Intelligence) {
            return "Intelligence";
        } else if (self == Traits.Speed) {
            return "Speed";
        } else if (self == Traits.Stamina) {
            return "Stamina";
        } else {
            return "Strength";
        }
    }
    

    // ========================================================================
    // --- Internal/public helper functions -----------------------------------

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the given `_seed` as a source of entropy.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _seed Seed value used as entropy source.
    function random(uint32 _range, uint256 _nonce, bytes32 _seed)
        public pure
        returns (uint32)
    {
        uint8 _flagBits = uint8(255 - _msbDeBruijn32(_range));
        uint256 _number = uint256(
                keccak256(
                    abi.encode(_seed, _nonce)
                )
            ) & uint256(2 ** _flagBits - 1);
        return uint32((_number * _range) >> _flagBits);
    }

    /// Recovers address from hash and signature.
    function recoverAddr(bytes32 _hash, bytes memory _signature)
        internal pure
        returns (address)
    {
        if (_signature.length != 65) {
            return (address(0));
        }
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return address(0);
        }
        if (v != 27 && v != 28) {
            return address(0);
        }
        return ecrecover(_hash, v, r, s);
    }


    // ========================================================================
    // --- PRIVATE FUNCTIONS --------------------------------------------------

    /// @dev Returns index of the Most Significant Bit of the given number, applying De Bruijn O(1) algorithm.
    function _msbDeBruijn32(uint32 _v)
        private pure
        returns (uint8)
    {
        uint8[32] memory _bitPosition = [
                0, 9, 1, 10, 13, 21, 2, 29,
                11, 14, 16, 18, 22, 25, 3, 30,
                8, 12, 20, 28, 15, 17, 24, 7,
                19, 27, 23, 6, 26, 5, 4, 31
            ];
        _v |= _v >> 1;
        _v |= _v >> 2;
        _v |= _v >> 4;
        _v |= _v >> 8;
        _v |= _v >> 16;
        return _bitPosition[
            uint32(_v * uint256(0x07c4acdd)) >> 27
        ];
    }
}
// File: contracts\interfaces\IWittyBufficornsDecorator.sol
/// @title Witty Bufficorns Token's decorator interface.
/// @author Otherplane Labs, 2022.
interface IWittyBufficornsDecorator {
    function baseURI() external view returns (string memory);
    function lookupMedalCaption(uint256 _ranking) external pure returns (string memory);
    function lookupRanchName(uint256 _ranchId) external pure returns (string memory);
    function lookupRanchResource(uint256 _ranchId) external pure returns (string memory);
    function lookupRanchWeatherStation(uint256 _ranchId) external pure returns (bytes4);
    function toJSON(
            uint256 _tokenId,
            bytes32 _randomness,
            WittyBufficornsLib.TokenMetadata memory _metadata
        ) external view returns (string memory);
}
// File: contracts\WittyBufficornsDecorator.sol
/// @title Decorator contract providing specific art content for Liscon 2021.
/// @author Otherplane Labs, 2021.
contract WittyBufficornsDecorator
    is
        IWittyBufficornsDecorator,
        Ownable
{
    using Strings for uint256;
    using WittyBufficornsLib for WittyBufficornsLib.Awards;
    using WittyBufficornsLib for WittyBufficornsLib.Traits;

    struct Boosters {
        uint[] odds;
        uint[] values;
        uint32 range;
    }

    Boosters public boosters;
    bool public forged;    

    modifier isForged {
        require(forged, "WittyBufficornsDecorator: not forged");
        _;
    }

    modifier notForged {
        require(!forged, "WittyBufficornsDecorator: already forged");
        _;
    }

    constructor(string memory _baseURI) {
        bytes memory _rawURI = bytes(_baseURI);
        require(
            _rawURI.length > 0,
            "WittyBufficornsDecorator: empty URI"
        );
        require(
            _rawURI[_rawURI.length - 1] == "/",
            "WittyBufficornsDecorator: no trailing slash"
        );
        baseURI = _baseURI;
        boosters.odds = [ 225, 16, 8, 4, 2, 1 ];
        boosters.values = [ 0, 10, 20, 30, 40, 50 ];
        boosters.range = 256;
    }    

    function forge()
        external virtual
        notForged
        onlyOwner
    {
        forged = true;
    }

    function setBoosters(uint[] calldata _odds, uint[] calldata _values)
        external virtual
        notForged
        onlyOwner
    {
        require(_values.length == _odds.length, "WittyBufficornsDecorator: range mismatch");
        boosters.odds = _odds;
        boosters.values = _values;
        uint _range;
        for (uint _index = 0; _index < _odds.length; _index ++) {
            _range += _odds[_index];
        }
    }


    // ========================================================================
    // --- Implementation of IWittyBufficornsDecorator ------------------------

    string public override baseURI;

    function lookupMedalCaption(uint256 _ranking)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranking == 1) {
            return "Gold";
        } else if (_ranking == 2) {
            return "Silver";
        } else if (_ranking == 3) {
            return "Bronze";
        } else {
            return "Diploma";
        }
    }

    function lookupRanchName(uint256 _ranchId)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranchId == 0) {
            return "Gold Reef Co.";
        } else if (_ranchId == 1) {
            return "Infinite Harmony Farm";
        } else if (_ranchId == 2) {
            return "Balancer Peak State";
        } else if (_ranchId == 3) {
            return "The Ol' Algoranch";
        } else if (_ranchId == 4) {
            return "Vega Slopes Range";
        } else if (_ranchId == 5) {
            return "Opolis Reservation";
        } else {
            return "Mystery Ranch";
        }
    }

    function lookupRanchResource(uint256 _ranchId)
        public pure
        virtual override
        returns (string memory)
    {
        if (_ranchId == 0) {
            return "Warm Hay";
        } else if (_ranchId == 1) {
            return "Fresh Grass";
        } else if (_ranchId == 2) {
            return "Smart Sedge";
        } else if (_ranchId == 3) {
            return "Mighty Acorn";
        } else if (_ranchId == 4) {
            return "Tireless Water";
        } else if (_ranchId == 5) {
            return "Hearty Berry";
        } else {
            return "Mystery Resource";
        }
    }

    function lookupRanchWeatherStation(uint256 _ranchId)
        public pure 
        virtual override
        returns (bytes4)
    {
        if (_ranchId == 0) {
            // Gold Reef Co. => Trinidad => KVTP
            return bytes4("KVTP");
        } else if (_ranchId == 2) {
            // Balancer Peak State => Silverton => KCPW
            return bytes4("KCPW");
        } else if (_ranchId == 3) {
            // The Ol' Algoranch => Colorado Springs => KMNH
            return bytes4("KMNH");
        } else if (_ranchId == 4) {
            // Vega Slopes Range => Breckenridge => KBJC
            return bytes4("KBJC");
        } else if (_ranchId == 5) {
            // Opolis Reservation => Pueblo => KLHX
            return bytes4("KLHX");
        } else {
            // Otherwise => Denver => KDEN
            return bytes4("KDEN");
        }
    }

    function toJSON(
            uint256 _tokenId,
            bytes32 _randomness,
            WittyBufficornsLib.TokenMetadata calldata _metadata
        )
        external view
        virtual override
        isForged
        returns (string memory)
    {
        if (_randomness != bytes32(0)) {
            // convolute game global randomness and unique farmer name
            _randomness = keccak256(abi.encode(_randomness, _metadata.farmer.name));
        }
        string memory _tokenIdStr = _tokenId.toString();
        string memory _rankingStr = _metadata.tokenInfo.award.ranking.toString();
        string memory _categoryStr = _metadata.tokenInfo.award.category.toString();
        string memory _farmerName = _metadata.farmer.name;
        string memory _baseURI = baseURI;

        string memory _name = string(abi.encodePacked(
            "\"name\": \"", _farmerName, " #", _tokenIdStr, "\","
        ));
        string memory _description = string(abi.encodePacked(
            "\"description\": \"EthDenver 2022: Ranked as #", _rankingStr, " ", _categoryStr, "\","
        ));        
        string memory _externalUrl = string(abi.encodePacked(
            "\"external_url\": \"", _baseURI, "metadata/", _tokenIdStr, "\","
        ));
        string memory _image = string(abi.encodePacked(
            "\"image\": \"", _baseURI, "image/", _tokenIdStr, "\","  
        ));
        string memory _attributes = string(abi.encodePacked(
            "\"attributes\": [",
            _loadAttributes(_randomness, _metadata),
            "]"
        ));
        return string(abi.encodePacked(
            "{", _name, _description, _externalUrl, _image, _attributes, "}"
        ));
    }


    // ========================================================================
    // --- INTERNAL METHODS ---------------------------------------------------

    function _getRandomTraitBoost(uint32 _range, uint8 _traitIndex, bytes32 _randomness)
        internal view
        returns (uint _value)
    {
        uint8 _random = uint8(WittyBufficornsLib.random(_range, uint(_traitIndex), _randomness));
        uint _index; uint _maxIndex = boosters.odds.length; uint _odds;
        for (_index = 0; _index < _maxIndex; _index ++) {
            _odds += boosters.odds[_index];
            if (_random < _odds) break;
        }
        if (_index < _maxIndex) {
            _value = boosters.values[_index];
        }
    }

    function _loadAttributes(
           bytes32 _randomness,
           WittyBufficornsLib.TokenMetadata memory _metadata
        )
        public view
        returns (string memory _json)
    {
        _json = _loadAttributesCommon(_metadata);
        WittyBufficornsLib.Awards _category = _metadata.tokenInfo.award.category;
        if (_category == WittyBufficornsLib.Awards.BestBreeder) {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesFarmer(
                    _randomness,
                    _metadata.tokenInfo.award.ranking,
                    _metadata.farmer
                )
            ));
        } else if (_category == WittyBufficornsLib.Awards.BestRanch) {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesRanch(
                    _metadata.tokenInfo.award.ranking,
                    _metadata.farmer.ranchId,
                    _metadata.ranch
                )
            ));
        } else {
            _json = string(abi.encodePacked(
                _json,
                _loadAttributesBufficorn(
                    _metadata.tokenInfo.award.ranking,
                    _metadata.bufficorn
                )
            ));
        }
    }

    function _loadAttributesCommon(WittyBufficornsLib.TokenMetadata memory _metadata)
        internal pure
        returns (string memory)
    {
        string memory _awardCategoryTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Award Category\",",
                "\"value\": \"", _metadata.tokenInfo.award.category.toString(), "\"",
            "},"
        ));
        string memory _expeditionDateTrait = string(abi.encodePacked(
             "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Expedition Date\",",
                "\"value\": ", _metadata.tokenInfo.expeditionTs.toString(),
            "},"
        ));
        string memory _medalTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Medal\",",
                "\"value\": \"", lookupMedalCaption(_metadata.tokenInfo.award.ranking), "\"",
            "},"
        ));
        string memory _farmerNameTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Farmer Name\",",
                "\"value\": \"", _metadata.farmer.name, "\""
            "},"
        ));
        return string(abi.encodePacked(
            _awardCategoryTrait,
            _expeditionDateTrait,
            _medalTrait,
            _farmerNameTrait
        ));
    }

    function _loadAttributesFarmer(
            bytes32 _randomness,
            uint256 _ranking,
            WittyBufficornsLib.Farmer memory _farmer
        )
        internal view
        returns (string memory _json)
    {
        _json = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Farmer Ranking\",",
                "\"value\": ", _ranking.toString(),
            "},"
            "{", 
                "\"trait_type\": \"Farmer Score\",",
                "\"value\": ", _farmer.score.toString(),
            "}"
        ));
        uint8 _ranchId = uint8(_farmer.ranchId);
        uint32 _randomRange = boosters.range;
        for (
            uint8 _traitIndex = 0;
            _traitIndex < uint8(type(WittyBufficornsLib.Traits).max) + 1;
            _traitIndex ++
        ) {
            uint _traitBoost = 0;
            if (_traitIndex == _ranchId) {
                _traitBoost = (
                    _ranking < 100
                        ? 100 - (25 * (_ranking / 25))
                        : 10
                );
            } else if (_randomness != bytes32(0) && _randomRange > 0) {
                _traitBoost = _getRandomTraitBoost(
                    _randomRange,
                    _traitIndex,
                    _randomness
                );
            }          
            if (_traitBoost > 0) {
                _json = string(abi.encodePacked(
                    _json,
                    ",{",
                        "\"display_type\": \"boost_percentage\",",
                        "\"trait_type\": \"", lookupRanchResource(_traitIndex), " Increase\",",
                        "\"value\": ", _traitBoost.toString(),
                    "}"
                ));
            }
        }
    }

    function _loadAttributesRanch(
            uint256 _ranking,
            uint256 _ranchId,
            WittyBufficornsLib.Ranch memory _ranch
        )
        internal pure
        returns (string memory)
    {
        string memory _ranchDateTrait = string(abi.encodePacked(
            "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Ranch Date\",",
                "\"value\": ", _ranch.weatherTimestamp.toString(),
            "},"
        ));
        string memory _ranchNameTrait = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Ranch Name\",",
                "\"value\": \"", lookupRanchName(_ranchId), "\""
            "},"
        ));
        string memory _ranchRanking =string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Ranch Ranking\",",
                "\"value\": ", _ranking.toString(),
            "},"
        ));
        string memory _ranchScore = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Ranch Score\",",
                "\"value\": ", _ranch.score.toString(),
            "},"
        ));
        string memory _ranchWeatherTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Ranch Weather\",",
                "\"value\": \"", _ranch.weatherDescription, "\""
            "}"
        ));
        return string(abi.encodePacked(
            _ranchDateTrait,
            _ranchNameTrait,
            _ranchRanking,
            _ranchScore,
            _ranchWeatherTrait
        ));
    }

    function _loadAttributesBufficorn(
            uint256 _ranking,
            WittyBufficornsLib.Bufficorn memory _bufficorn
        )
        internal pure
        returns (string memory)
    {
        string memory _bufficornNameTrait = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Bufficorn Name\",",
                "\"value\": \"", _bufficorn.name, "\""
            "},"
        ));
        string memory _bufficornRankingTrait = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Bufficorn Ranking\",",
                "\"value\": \"", _ranking.toString(), "\""
            "},"
        ));
        string memory _bufficornScoreTrait = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Bufficorn Score\",",
                "\"value\": ", _bufficorn.score.toString(),
            "}"
        ));
        string memory _bufficornTraits;
        for (uint8 _traitIndex = 0; _traitIndex < 6; _traitIndex ++) {
            string memory _traitName = WittyBufficornsLib.Traits(_traitIndex).toString();
            string memory _traitValue = _bufficorn.traits[_traitIndex].toString();
            _bufficornTraits = string(abi.encodePacked(
                _bufficornTraits,
                ",{",
                    "\"trait_type\": \"Bufficorn ", _traitName, "\",",
                    "\"value\": ", _traitValue,
                "}"
            ));
        }
        return string(abi.encodePacked(
            _bufficornNameTrait,
            _bufficornRankingTrait,
            _bufficornScoreTrait,
            _bufficornTraits
        ));
    }
}