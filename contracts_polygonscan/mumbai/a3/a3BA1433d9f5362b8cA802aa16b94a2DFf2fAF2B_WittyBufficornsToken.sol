/**
 *Submitted for verification at polygonscan.com on 2022-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

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
        address from;      // Address from which the request was posted.
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

    /// Retrieves the whole Request record posted to the Witnet Request Board.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been reported
    /// @dev or deleted.
    /// @param _queryId The unique identifier of a previously posted query.
    function readRequest(uint256 _queryId) external view returns (Witnet.Request memory);

    /// Retrieves the serialized bytecode of a previously posted Witnet Data Request.
    /// @dev Fails if the `_queryId` is not valid, or if the related script bytecode 
    /// @dev got changed after being posted. Returns empty array once it gets reported, 
    /// @dev or deleted.
    /// @param _queryId The unique query identifier.
    function readRequestBytecode(uint256 _queryId) external view returns (bytes memory);

    /// Retrieves the gas price that any assigned reporter will have to pay when reporting 
    /// result to a previously posted Witnet data request.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
    /// @param _queryId The unique query identifie
    function readRequestGasPrice(uint256 _queryId) external view returns (uint256);

    /// Retrieves the reward currently set for the referred query.
    /// @dev Fails if the `_queryId` is not valid or, if it has already been 
    /// @dev reported, or deleted. 
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
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\WitnetRequestBoard.sol
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
// File: witnet-solidity-bridge\contracts\UsingWitnet.sol
/// @title The UsingWitnet contract
/// @dev Witnet-aware contracts can inherit from this contract in order to interact with Witnet.
/// @author The Witnet Foundation.
abstract contract UsingWitnet {

    WitnetRequestBoard public immutable witnet;

    /// Include an address to specify the WitnetRequestBoard entry point address.
    /// @param _wrb The WitnetRequestBoard entry point address.
    constructor(WitnetRequestBoard _wrb)
    {
        require(address(_wrb) != address(0), "UsingWitnet: zero address");
        witnet = _wrb;
    }

    /// Provides a convenient way for client contracts extending this to block the execution of the main logic of the
    /// contract until a particular request has been successfully solved and reported by Witnet.
    modifier witnetRequestSolved(uint256 _id) {
        require(
                _witnetCheckResultAvailability(_id),
                "UsingWitnet: request not solved"
            );
        _;
    }

    /// Check if a data request has been solved and reported by Witnet.
    /// @dev Contracts depending on Witnet should not start their main business logic (e.g. receiving value from third.
    /// parties) before this method returns `true`.
    /// @param _id The unique identifier of a previously posted data request.
    /// @return A boolean telling if the request has been already resolved or not. Returns `false` also, if the result was deleted.
    function _witnetCheckResultAvailability(uint256 _id)
        internal view
        virtual
        returns (bool)
    {
        return witnet.getQueryStatus(_id) == Witnet.QueryStatus.Reported;
    }

    /// Estimate the reward amount.
    /// @param _gasPrice The gas price for which we want to retrieve the estimation.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward(uint256 _gasPrice)
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(_gasPrice);
    }

    /// Estimates the reward amount, considering current transaction gas price.
    /// @return The reward to be included when either posting a new request, or upgrading the reward of a previously posted one.
    function _witnetEstimateReward()
        internal view
        virtual
        returns (uint256)
    {
        return witnet.estimateReward(tx.gasprice);
    }

    /// Send a new request to the Witnet network with transaction value as a reward.
    /// @param _request An instance of `IWitnetRequest` contract.
    /// @return _id Sequential identifier for the request included in the WitnetRequestBoard.
    /// @return _reward Current reward amount escrowed by the WRB until a result gets reported.
    function _witnetPostRequest(IWitnetRequest _request)
        internal
        virtual
        returns (uint256 _id, uint256 _reward)
    {
        _reward = _witnetEstimateReward();
        _id = witnet.postRequest{value: _reward}(_request);
    }

    /// Upgrade the reward for a previously posted request.
    /// @dev Call to `upgradeReward` function in the WitnetRequestBoard contract.
    /// @param _id The unique identifier of a request that has been previously sent to the WitnetRequestBoard.
    /// @return Amount in which the reward has been increased.
    function _witnetUpgradeReward(uint256 _id)
        internal
        virtual
        returns (uint256)
    {
        uint256 _currentReward = witnet.readRequestReward(_id);        
        uint256 _newReward = _witnetEstimateReward();
        uint256 _fundsToAdd = 0;
        if (_newReward > _currentReward) {
            _fundsToAdd = (_newReward - _currentReward);
        }
        witnet.upgradeReward{value: _fundsToAdd}(_id); // Let Request.gasPrice be updated
        return _fundsToAdd;
    }

    /// Read the Witnet-provided result to a previously posted request.
    /// @param _id The unique identifier of a request that was posted to Witnet.
    /// @return The result of the request as an instance of `Witnet.Result`.
    function _witnetReadResult(uint256 _id)
        internal view
        virtual
        returns (Witnet.Result memory)
    {
        return witnet.readResponseResult(_id);
    }

    /// Retrieves copy of all response data related to a previously posted request, removing the whole query from storage.
    /// @param _id The unique identifier of a previously posted request.
    /// @return The Witnet-provided result to the request.
    function _witnetDeleteQuery(uint256 _id)
        internal
        virtual
        returns (Witnet.Response memory)
    {
        return witnet.deleteQuery(_id);
    }

}
// File: witnet-solidity-bridge\contracts\interfaces\IWitnetRandomness.sol
/// @title The Witnet Randomness generator interface.
/// @author Witnet Foundation.
interface IWitnetRandomness {

    /// Thrown every time a new WitnetRandomnessRequest gets succesfully posted to the WitnetRequestBoard.
    /// @param from Address from which the randomize() function was called. 
    /// @param prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @param witnetQueryId Unique query id assigned to this request by the WRB.
    /// @param witnetRequestHash SHA-256 hash of the WitnetRandomnessRequest actual bytecode just posted to the WRB.
    event Randomized(
        address indexed from,
        uint256 indexed prevBlock,
        uint256 witnetQueryId,
        bytes32 witnetRequestHash
    );

    /// Returns amount of wei required to be paid as a fee when requesting randomization with a 
    /// transaction gas price as the one given.
    function estimateRandomizeFee(uint256 _gasPrice) external view returns (uint256);

    /// Retrieves data of a randomization request that got successfully posted to the WRB within a given block.
    /// @dev Returns zero values if no randomness request was actually posted within a given block.
    /// @param _block Block number whose randomness request is being queried for.
    /// @return _from Address from which the latest randomness request was posted.
    /// @return _id Unique request identifier as provided by the WRB.
    /// @return _fee Request's total paid fee.
    /// @return _prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @return _nextBlock Block number in which a randomness request got posted just after this one, 0 if none.
    function getRandomizeData(uint256 _block)
        external view returns (address _from, uint256 _id, uint256 _fee, uint256 _prevBlock, uint256 _nextBlock);

    /// Retrieves the randomness generated upon solving a request that was posted within a given block,
    /// if any, or to the _first_ request posted after that block, otherwise. Should the intended 
    /// request happen to be finalized with errors on the Witnet oracle network side, this function 
    /// will recursively try to return randomness from the next non-faulty randomization request found 
    /// in storage, if any. 
    /// @dev Fails if:
    /// @dev   i.   no `randomize()` was not called in either the given block, or afterwards.
    /// @dev   ii.  a request posted in/after given block does exist, but no result has been provided yet.
    /// @dev   iii. all requests in/after the given block were solved with errors.
    /// @param _block Block number from which the search will start.
    function getRandomnessAfter(uint256 _block) external view returns (bytes32); 

    /// Tells what is the number of the next block in which a randomization request was posted after the given one. 
    /// @param _block Block number from which the search will start.
    /// @return Number of the first block found after the given one, or `0` otherwise.
    function getRandomnessNextBlock(uint256 _block) external view returns (uint256); 

    /// Gets previous block in which a randomness request was posted before the given one.
    /// @param _block Block number from which the search will start.
    /// @return First block found before the given one, or `0` otherwise.
    function getRandomnessPrevBlock(uint256 _block) external view returns (uint256);

    /// Returns `true` only when the randomness request that got posted within given block was already
    /// reported back from the Witnet oracle, either successfully or with an error of any kind.
    function isRandomized(uint256 _block) external view returns (bool);

    /// Returns latest block in which a randomness request got sucessfully posted to the WRB.
    function latestRandomizeBlock() external view returns (uint256);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the randomness returned by `getRandomnessAfter(_block)`. 
    /// @dev Fails under same conditions as `getRandomnessAfter(uint256)` may do.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _block Block number from which the search will start.
    function random(uint32 _range, uint256 _nonce, uint256 _block) external view returns (uint32);

    /// Generates a pseudo-random number uniformly distributed within the range [0 .. _range), by using 
    /// the given `_nonce` value and the given `_seed` as a source of entropy.
    /// @param _range Range within which the uniformly-distributed random number will be generated.
    /// @param _nonce Nonce value enabling multiple random numbers from the same randomness value.
    /// @param _seed Seed value used as entropy source.
    function random(uint32 _range, uint256 _nonce, bytes32 _seed) external pure returns (uint32);

    /// Requests the Witnet oracle to generate an EVM-agnostic and trustless source of randomness. 
    /// Only one randomness request per block will be actually posted to the WRB. Should there 
    /// already be a posted request within current block, it will try to upgrade Witnet fee of current's 
    /// block randomness request according to current gas price. In both cases, all unused funds shall 
    /// be transfered back to the tx sender.
    /// @return _usedFunds Amount of funds actually used from those provided by the tx sender.
    function randomize() external payable returns (uint256 _usedFunds);

    /// Increases Witnet fee related to a pending-to-be-solved randomness request, as much as it
    /// may be required in proportion to how much bigger the current tx gas price is with respect the 
    /// highest gas price that was paid in either previous fee upgrades, or when the given randomness 
    /// request was posted. All unused funds shall be transferred back to the tx sender.
    /// @return _usedFunds Amount of dunds actually used from those provided by the tx sender.
    function upgradeRandomizeFee(uint256 _block) external payable returns (uint256 _usedFunds);
}
// File: ..\..\node_modules\witnet-solidity-bridge\contracts\requests\WitnetRequestBase.sol
abstract contract WitnetRequestBase
    is
        IWitnetRequest
{
    /// Contains a well-formed Witnet Data Request, encoded using Protocol Buffers.
    bytes public override bytecode;

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    bytes32 public override hash;
}
// File: witnet-solidity-bridge\contracts\requests\WitnetRequest.sol
contract WitnetRequest
    is
        WitnetRequestBase
{
    using Witnet for bytes;
    constructor(bytes memory _bytecode) {
        bytecode = _bytecode;
        hash = _bytecode.hash();
    }
}
// File: ..\..\node_modules\@openzeppelin\contracts\utils\introspection\IERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


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
// File: ..\..\node_modules\@openzeppelin\contracts\token\ERC721\IERC721.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// File: ..\..\node_modules\@openzeppelin\contracts\token\ERC721\IERC721Receiver.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)


/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: ..\..\node_modules\@openzeppelin\contracts\token\ERC721\extensions\IERC721Metadata.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)



/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: ..\..\node_modules\@openzeppelin\contracts\utils\Address.sol
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)


/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// File: ..\..\node_modules\@openzeppelin\contracts\utils\Context.sol
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
// File: ..\..\node_modules\@openzeppelin\contracts\utils\introspection\ERC165.sol
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)



/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
// File: @openzeppelin\contracts\token\ERC721\ERC721.sol
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)









/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// File: @openzeppelin\contracts\security\ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)


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
        } else if (self == Awards.BestRanch) {
            return "Best Ranch";
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
// File: contracts\interfaces\IWittyBufficornsAdmin.sol
/// @title  Witty Bufficorns Token's admin interface
/// @dev    Only callable be either the owner, or the signator.
/// @author Otherplane Labs, 2022.
interface IWittyBufficornsAdmin {
    /// Returns decorator contract's address.
    function getDecorator() external view returns (address);

    /// Returns signator's address.
    function getSignator() external view returns (address);

    /// Returns tender's current status
    function getStatus() external view returns (WittyBufficornsLib.Status);

    /// Sets name, ranch and final traits for the given bufficorn.
    function setBufficorn(
        uint256 _id,
        uint256 _ranchId,
        string calldata _name,
        uint256[6] calldata _traits
    ) external;

    /// Sets Opensea-compliant Decorator contract
    /// @param _decorator Decorating logic contract producing a creature's metadata, and picture.
    function setDecorator(address _decorator) external;

    /// Sets a ranch's data, final score and weather station.
    function setRanch(
        uint256 _id,
        uint256 _score
    ) external;
        
    /// Sets externally owned account that is authorized to sign farmer awards.
    function setSignator(address _signator) external;

    /// Stops Breeding phase, which means: (a) ranches and bufficorns' traits cannot be modified any more;
    /// and (b), randomness will be requested to the Witnet's oracle.
    /// @param _totalRanches Total of ranches that must have been previously set.
    /// @param _totalBufficorns Total of bufficorns that must have been previoustly set.
    function stopBreeding(uint256 _totalRanches, uint256 _totalBufficorns) external payable;

    /// Starts the Awarding phase, in which players will be able to mint their tokens.
    function startAwarding() external;    

    /// Ask the Witnet oracle to update current weather for the given ranch.
    function updateRanchWeather(uint256 _ranchId) external payable returns (uint256);
}
// File: contracts\interfaces\IWittyBufficornsEvents.sol
/// @title Witty Bufficorns Token's events.
/// @author Otherplane Labs, 2022.
interface IWittyBufficornsEvents {
    event AwardingBegins(address signator, uint totalRanches, uint totalBufficorns);
    event BufficornSet(uint id, string name, uint score, uint[6] traits);
    event DecoratorSet(address decorator);
    event FarmerAward(uint indexed tokenId, uint indexed farmerId, WittyBufficornsLib.Awards indexed category, uint ranking);
    event RanchSet(uint id, uint score, string name, bytes4 weatherStation);
    event SignatorSet(address signator);
}
// File: contracts\interfaces\IWittyBufficornsSurrogates.sol
/// @title Witty Bufficorns Token's surrogating interface.
/// @author Otherplane Labs, 2022.
interface IWittyBufficornsSurrogates {

    /// @dev Called from front-end.
    function mintFarmerAwards(
        address _tokenOwner,
        uint256 _ranchId,
        uint256 _farmerId,
        uint256 _farmerScore,
        string calldata _farmerName,
        WittyBufficornsLib.Award[] calldata _farmerAwards,
        bytes calldata _signature
    ) external;
}
// File: contracts\interfaces\IWittyBufficornsView.sol
/// @title Witty Bufficorns Token's view interface.
/// @author Otherplane Labs, 2022.
interface IWittyBufficornsView {
    function getBufficorn(uint256 _bufficornId) external view returns (WittyBufficornsLib.Bufficorn memory);
    function getFarmer(uint256 _farmerId) external view returns (WittyBufficornsLib.Farmer memory);
    function getFarmerTokens(uint256 _farmerId) external view returns (uint256[] memory);
    function getRanch(uint256 _ranchId) external view returns (WittyBufficornsLib.Ranch memory);
    function getRanchWeather(uint256 _ranchId) external view returns (uint256, string memory);
    function getTokenInfo(uint256 _tokenId) external view returns (WittyBufficornsLib.TokenInfo memory);

    function previewFarmerAwards(
            uint256 _ranchId,
            uint256 _farmerId,
            uint256 _farmerScore,
            string calldata _farmerName,
            WittyBufficornsLib.Award[] calldata _farmerAwards
        ) external view returns (string[] memory _metadata);

    function stopBreedingBlock() external view returns (uint256);
    function stopBreedingRandomness() external view returns (bytes32);

    function toJSON(uint256 _tokenId) external view returns (string memory);

    function totalBufficorns() external view returns (uint256);
    function totalFarmers() external view returns (uint256);
    function totalRanches() external view returns (uint256);
    function totalSupply() external view returns (uint256);
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
// File: contracts\WittyBufficornsToken.sol
/// @title Witty Bufficorns Awards - ERC721 Token contract
/// @author Otherplane Labs, 2022.
contract WittyBufficornsToken
    is
        ERC721,
        Ownable,
        ReentrancyGuard,
        IWittyBufficornsAdmin,
        IWittyBufficornsEvents,
        IWittyBufficornsSurrogates,
        IWittyBufficornsView
{
    using Strings for uint256;
    using WittyBufficornsLib for WittyBufficornsLib.Storage;

    IWitnetRandomness public immutable randomizer;
    WitnetRequestBoard public immutable witnet;

    modifier inStatus(WittyBufficornsLib.Status status) {
        require(
            __storage.status() == status,
            "WittyBufficornsToken: bad mood"
        );
        _;
    }

    modifier onlySignator {
        require(
            msg.sender == __storage.signator,
            "WittyBufficornsToken: only signator"
        );
        _;
    }

    modifier tokenExists(uint256 _tokenId) {
        require(
            _exists(_tokenId),
            "WittyBufficornsToken: inexistent token"
        );
        _;
    }

    WittyBufficornsLib.Storage internal __storage;

    constructor(
            string memory _name,
            string memory _symbol,
            IWitnetRandomness _randomizer,
            IWittyBufficornsDecorator _decorator
        )
        ERC721(_name, _symbol)
    {
        randomizer = _randomizer;
        witnet = UsingWitnet(address(_randomizer)).witnet();
        setDecorator(address(_decorator));
        __storage.signator = msg.sender;
    }

    receive() external payable {}


    // ========================================================================
    // --- 'ERC721Metadata' overriden functions -------------------------------
    
    function baseURI()
        public view
        virtual
        returns (string memory)
    {
        return IWittyBufficornsDecorator(__storage.decorator).baseURI();
    }
    
    function metadata(uint256 _tokenId)
        external view
        virtual
        tokenExists(_tokenId)
        returns (string memory)
    {
        return toJSON(_tokenId);
    }

    function tokenURI(uint256 _tokenId)
        public view
        virtual override
        tokenExists(_tokenId)
        returns (string memory)
    {
        return string(abi.encodePacked(
            baseURI(),
            _tokenId.toString()
        ));
    }

    // ========================================================================
    // --- Implementation of 'IWittyBufficornsAdmin' --------------------------

    /// Returns decorator contract's address.
    function getDecorator()
        external view
        virtual override
        returns (address)
    {
        return __storage.decorator;
    }

    /// Returns signator's address.
    function getSignator()
        external view
        returns (address)
    {
        return __storage.signator;
    }

    /// Returns tender's current status
    function getStatus()
        external view
        returns (WittyBufficornsLib.Status)
    {
        return __storage.status();
    }

    /// Sets name, ranch and final traits for the given bufficorn.
    /// @dev Must be called from the signators's address.
    /// @dev Fails if not in Breeding status. 
    function setBufficorn(
            uint256 _id,
            uint256 _ranchId,
            string calldata _name,
            uint256[6] calldata _traits
        )
        external
        onlySignator
        inStatus(WittyBufficornsLib.Status.Breeding)
    {
        WittyBufficornsLib.Ranch storage __ranch = __storage.ranches[_ranchId];
        require(
            bytes(_name).length > 0,
            "WittyBufficornsToken: no name"
        );
        WittyBufficornsLib.Bufficorn storage __bufficorn = __storage.bufficorns[_id];
        if (bytes(_name).length > 0) {
            if (bytes(__bufficorn.name).length == 0) {
                __storage.stats.totalBufficorns ++;
            }
        }
        uint _score = _traits[0];
        for (uint _i = 1; _i < 6; _i ++) {
            if (_traits[_i] < _score) {
                // Bufficorn's score correspond to the minimum or its traits
                _score = _traits[_i];
            }
        }
        require( 
            _score >= __ranch.score,
            "WittyBufficornsToken: score below ranch'es"
        );
        __bufficorn.name = _name;
        __bufficorn.ranchId = _ranchId;
        __bufficorn.score = _score;
        __bufficorn.traits = _traits;
        emit BufficornSet(_id, _name, _score, _traits);
    }

    /// Sets Opensea-compliant Decorator contract
    /// @dev Must be called from the owner's address.
    function setDecorator(address _decorator)
        public
        virtual override
        onlyOwner
    {
        require(
            address(_decorator) != address(0),
            "WittyBufficornsToken: no decorator"
        );
        __storage.decorator = _decorator;
        emit DecoratorSet(_decorator);
    }

    /// Sets a ranch's data, final score and weather station.
    /// @dev Must be called from the signators's address.
    /// @dev Fails if not in Breeding status. 
    function setRanch(
            uint256 _id,
            uint256 _score
        )
        external
        onlySignator
        inStatus(WittyBufficornsLib.Status.Breeding)
    {
        WittyBufficornsLib.Ranch storage __ranch = __storage.ranches[_id];        
        if (_score == 0 && __ranch.score > 0) {
            __storage.stats.totalRanches --;
        } else if (_score > 0 && __ranch.score == 0) {
            __storage.stats.totalRanches ++;
        }
        bytes4 _weatherStation = IWittyBufficornsDecorator(__storage.decorator).lookupRanchWeatherStation(_id);
        if (__ranch.weatherStation == bytes4(0)) {
            __ranch.weatherStation = _weatherStation;
            /** Javascript DSL:
             *
             *  import * as Witnet from "witnet-requests"
             *  const weather = new Witnet.Source("https://api.weather.gov/stations/<ascii_code>/observations/latest")
             *    .parseJSONMap()
             *    .getMap("properties")
             *    .getString("textDescription")
             *
             *  const weatherRequest = new WitnetRequest()
             *    .addSource(weather)
             *    .setAggregator(new Witnet.Aggregator({ reducer: Witnet.Types.REDUCERS.mode }))
             *    .setTally(new Witnet.Aggregator({ reducer: Witnet.Types.REDUCERS.mode }))
             *    .setQuorum(10, 51) // set witness count and minimum consensus percentage
             *    .setFees(10 ** 6, 10 ** 6) // set Witnet economic incentives
             *    .setCollateral(5 * 10 ** 9) // set 5 wits as collateral
             */
            __ranch.witnet.request = new WitnetRequest(abi.encodePacked(
                bytes(hex"0a6d12630801123968747470733a2f2f6170692e776561746865722e676f762f73746174696f6e732f"),
                _weatherStation,
                bytes(hex"2f6f62736572766174696f6e732f6c61746573741a248318778218666a70726f706572746965738218676f746578744465736372697074696f6e1a02"),
                bytes(hex"10022202100210c0843d180a20c0843d28333080e497d012")
            ));
        }
        __ranch.score = _score;
        emit RanchSet(
            _id,
            _score,
            IWittyBufficornsDecorator(__storage.decorator).lookupRanchName(_id),
            _weatherStation
        );
    }

    /// Sets externally owned account that is authorized to sign farmer awards.
    /// @dev Must be called from the owner's address.
    /// @dev Fails if not in Breeding status. 
    function setSignator(address _signator)
        public
        virtual override
        onlyOwner
        inStatus(WittyBufficornsLib.Status.Breeding)
    {
        require(
            _signator != address(0),
            "WittyBufficornsToken: no signator"
        );
        __storage.signator = _signator;        
        emit SignatorSet(_signator);
    }

    /// Stops Breeding phase, which means: (a) ranches and bufficorns' traits cannot be modified any more;
    /// and (b), randomness will be requested to the Witnet's oracle. 
    /// @param _totalRanches Total of ranches that must have been previously set.
    /// @param _totalBufficorns Total of bufficorns that must have been previoustly set.
    /// @dev Must be called from the Signator's address. Fails if not in Breeding status. 
    /// @dev If no WitnetRandomness address was provided in construction, contract status will directly change to Awarding.
    function stopBreeding(
            uint256 _totalRanches,
            uint256 _totalBufficorns
        )
        external payable
        virtual override
        onlySignator
        inStatus(WittyBufficornsLib.Status.Breeding)
    {
        require(
            __storage.stats.totalRanches == _totalRanches,
            "WittyBufficornsToken: ranches mismatch"
        );
        require(
            __storage.stats.totalBufficorns == _totalBufficorns,
            "WittyBufficornsToken: bufficorns mismatch"
        );
        __storage.stopBreedingBlock = block.number;
        if (address(randomizer) == address(0)) {
            __storage.stopBreedingRandomness = bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            emit AwardingBegins(
                msg.sender,
                _totalRanches,
                _totalBufficorns
            );
        } else {
            uint _usedFunds = randomizer.randomize{value: msg.value}();
            if (_usedFunds < msg.value) {
                payable(msg.sender).transfer(msg.value - _usedFunds);
            }
        }
    }

    /// Starts the Awarding phase, in which players will be able to mint their tokens.
    /// @dev Must be called from the Signator's address. Fails if not in Randomizing status. 
    function startAwarding()
        external
        virtual override
        onlySignator
        inStatus(WittyBufficornsLib.Status.Randomizing)
    {
        __storage.stopBreedingRandomness = randomizer.getRandomnessAfter(__storage.stopBreedingBlock);
        emit AwardingBegins(
            msg.sender,
            __storage.stats.totalRanches,
            __storage.stats.totalBufficorns
        );
    }

    /// Ask the Witnet oracle to update current weather for the given ranch.
    function updateRanchWeather(uint256 _ranchId)
        external payable
        virtual override
        returns (uint256)
    {
        return __storage.updateRanchWeather(witnet, _ranchId);
    }


    // ========================================================================
    // --- Implementation of 'IWittyBufficornsSurrogates' ---------------------

    function mintFarmerAwards(
            address _tokenOwner,
            uint256 _ranchId,
            uint256 _farmerId,
            uint256 _farmerScore,
            string memory _farmerName,
            WittyBufficornsLib.Award[] calldata _farmerAwards,
            bytes memory _signature
        )
        public
        virtual override
        nonReentrant
        // UNCOMMENT: inStatus(WittyBufficornsLib.Status.Awarding)
    {
        require(_tokenOwner != address(0), "WittyBufficornsToken: no token owner");
        require(_farmerAwards.length > 0, "WittyBufficornsToken: no awards");

        // UNCOMMENT: WittyBufficornsLib.Ranch storage __ranch = __storage.ranches[_ranchId];
        // UNCOMMENT: require(__ranch.score > 0, "WittyBufficornsToken: inexistent ranch");

        WittyBufficornsLib.Farmer storage __farmer = __storage.farmers[_farmerId];
        require(bytes(__farmer.name).length == 0, "WittyBufficornsToken: already minted");
        
        _verifySignatorSignature(
            _tokenOwner,
            _ranchId,
            _farmerId,
            _farmerScore,
            _farmerName,
            _farmerAwards,
            _signature
        );

        // Set farmer's info for the first and only time:
        __farmer.name = _farmerName;
        __farmer.score = _farmerScore;
        __farmer.ranchId = _ranchId;
        __farmer.firstTokenId = __storage.stats.totalSupply + 1;
        __farmer.totalAwards = _farmerAwards.length;

        WittyBufficornsLib.TokenInfo memory _tokenInfo;

        // Set common parameters to all tokens minted within this call:
        _tokenInfo.farmerId = _farmerId;
        // solhint-disable-next-line not-rely-on-time
        _tokenInfo.expeditionTs = block.timestamp;

        // Loop: Mint one token per received award:
        for (uint _ix = 0; _ix < _farmerAwards.length; _ix ++) {
            _tokenInfo.award = _farmerAwards[_ix];
            require(
                uint8(_tokenInfo.award.category) < uint8(WittyBufficornsLib.Awards.BestBufficorn)
                    || _tokenInfo.award.ranking > 3,
                "WittyBufficornsToken: bufficorn bad ranking"
            );
            __doSafeMint(_tokenOwner, _tokenInfo);
        }

        // Increase total number of farmers that minted at least one award:
        __storage.stats.totalFarmers ++;
    }


    // ========================================================================
    // --- Implementation of 'IWittyBufficornsView' ---------------------------

    function getBufficorn(uint256 _bufficornId)
        external view
        override
        returns (WittyBufficornsLib.Bufficorn memory)
    {
        return __storage.bufficorns[_bufficornId];
    }

    function getFarmer(uint256 _farmerId)
        external view
        override
        returns (WittyBufficornsLib.Farmer memory)
    {
        return __storage.farmers[_farmerId];
    }

    function getFarmerTokens(uint256 _farmerId)
        external view
        virtual override
        returns (uint256[] memory _tokenIds)
    {
        WittyBufficornsLib.Farmer storage __farmer = __storage.farmers[_farmerId];
        if (__farmer.totalAwards > 0) {
            uint _tokenId = __farmer.firstTokenId;
            _tokenIds = new uint256[](__farmer.totalAwards);            
            for (uint _i = 0; _i < _tokenIds.length; _i ++) {
                _tokenIds[_i] = _tokenId ++;
            }
        }
    }

    function getRanch(uint256 _ranchId)
        external view
        override
        returns (WittyBufficornsLib.Ranch memory _ranch)
    {
        _ranch = __storage.ranches[_ranchId];
        (_ranch.weatherTimestamp, _ranch.weatherDescription) = getRanchWeather(_ranchId);
    }

    function getRanchWeather(uint256 _ranchId)
        public view
        override
        returns (
            uint256 _lastTimestamp,
            string memory _lastDescription
        )
    {
        return __storage.getRanchWeather(witnet, _ranchId);
    }

    function getTokenInfo(uint256 _tokenId)
        external view 
        override
        tokenExists(_tokenId)
        returns (WittyBufficornsLib.TokenInfo memory)
    {
        return __storage.awards[_tokenId];
    }

    function previewFarmerAwards(
            uint256 _ranchId,
            uint256 _farmerId,
            uint256 _farmerScore,
            string calldata _farmerName,
            WittyBufficornsLib.Award[] calldata _farmerAwards
        )
        external view
        virtual override
        inStatus(WittyBufficornsLib.Status.Awarding)
        returns (string[] memory _metadatas)
    {
        require(_farmerAwards.length > 0, "WittyBufficornsToken: no awards");

        WittyBufficornsLib.TokenMetadata memory _token;
        _token.ranch = __storage.ranches[_ranchId];
        (_token.ranch.weatherTimestamp, _token.ranch.weatherDescription) = getRanchWeather(_ranchId);
        
        _token.farmer.name = _farmerName;
        _token.farmer.score = _farmerScore;
        _token.tokenInfo.farmerId = _farmerId;

        _metadatas = new string[](_farmerAwards.length);
        for (uint _ix = 0; _ix < _farmerAwards.length; _ix ++) {
            _token.tokenInfo.award = _farmerAwards[_ix];
            _token.bufficorn = __storage.bufficorns[
                uint8(_token.tokenInfo.award.category) >= uint8(WittyBufficornsLib.Awards.BestBufficorn)
                    ? _token.tokenInfo.award.bufficornId
                    : 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            ];
            _metadatas[_ix] = IWittyBufficornsDecorator(__storage.decorator).toJSON(
                0,
                __storage.stopBreedingRandomness,
                _token
            );
        }
    }

    function stopBreedingBlock()
        external view
        override
        returns (uint256)
    {
        return __storage.stopBreedingBlock;
    }

    function stopBreedingRandomness()
        external view
        override
        returns (bytes32)
    {
        return __storage.stopBreedingRandomness;
    }

    function toJSON(uint256 _tokenId)
        public view
        override
        tokenExists(_tokenId)
        returns (string memory)
    {
        WittyBufficornsLib.TokenMetadata memory _metadata;
        _metadata.tokenInfo = __storage.awards[_tokenId];
        _metadata.farmer = __storage.farmers[_metadata.tokenInfo.farmerId];
        _metadata.ranch = __storage.ranches[_metadata.farmer.ranchId];
        (_metadata.ranch.weatherTimestamp, _metadata.ranch.weatherDescription) = getRanchWeather(_metadata.farmer.ranchId);
        if (
            uint8(_metadata.tokenInfo.award.category) >= uint8(WittyBufficornsLib.Awards.BestBufficorn)
        ) {
            _metadata.bufficorn = __storage.bufficorns[_metadata.tokenInfo.award.bufficornId];
        }
        return IWittyBufficornsDecorator(__storage.decorator).toJSON(
            _tokenId,
            __storage.stopBreedingRandomness,
            _metadata
        );
    }
    
    function totalBufficorns() public view override returns (uint256) {
        return __storage.stats.totalBufficorns;
    }

    function totalFarmers() public view override returns (uint256) {
        return __storage.stats.totalFarmers;
    }

    function totalRanches() public view override returns (uint256) {
        return __storage.stats.totalRanches;
    }

    function totalSupply() public view override returns (uint256) {
        return __storage.stats.totalSupply;
    }


    // ------------------------------------------------------------------------
    // --- INTERNAL METHODS ---------------------------------------------------
    // ------------------------------------------------------------------------

    function __doSafeMint(
            address _tokenOwner,
            WittyBufficornsLib.TokenInfo memory _tokenInfo
        )
        internal
        returns (uint256 _tokenId)
    {
        _tokenId = ++ __storage.stats.totalSupply;               
        __storage.awards[_tokenId] = _tokenInfo;
        _safeMint(_tokenOwner, _tokenId);
    }

    function _verifySignatorSignature(
            address _tokenOwner,
            uint256 _ranchId,
            uint256 _farmerId,
            uint256 _farmerScore,
            string memory _farmerName,
            WittyBufficornsLib.Award[] memory _farmerAwards,
            bytes memory _signature
        )
        internal view
        virtual
    {
        // Verify signator:
        bytes32 _hash = keccak256(abi.encode(
            _tokenOwner,
            _ranchId,
            _farmerId,
            _farmerScore,
            _farmerName,
            _farmerAwards
        ));
        // UNCOMMENT: require(
        // UNCOMMENT:     WittyBufficornsLib.recoverAddr(_hash, _signature) == __storage.signator,
        // UNCOMMENT:     "WittyBufficornsToken: bad signature"
        // UNCOMMENT: );
    }
}