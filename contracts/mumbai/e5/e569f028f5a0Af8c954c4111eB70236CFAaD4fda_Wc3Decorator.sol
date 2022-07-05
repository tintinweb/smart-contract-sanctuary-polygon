/**
 *Submitted for verification at polygonscan.com on 2022-07-04
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
// File: node_modules\witnet-solidity-bridge\contracts\interfaces\IWitnetRequest.sol
/// @title The Witnet Data Request basic interface.
/// @author The Witnet Foundation.
interface IWitnetRequest {
    /// A `IWitnetRequest` is constructed around a `bytes` value containing 
    /// a well-formed Witnet Data Request using Protocol Buffers.
    function bytecode() external view returns (bytes memory);

    /// Returns SHA256 hash of Witnet Data Request as CBOR-encoded bytes.
    function hash() external view returns (bytes32);
}
// File: node_modules\witnet-solidity-bridge\contracts\libs\Witnet.sol
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
    /// @return _prevBlock Block number in which a randomness request got posted just before this one. 0 if none.
    /// @return _nextBlock Block number in which a randomness request got posted just after this one, 0 if none.
    function getRandomizeData(uint256 _block)
        external view returns (address _from, uint256 _id, uint256 _prevBlock, uint256 _nextBlock);

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
// File: contracts\libs\Wc3Lib.sol
/// @title Wc3Lib Library: data model and helper functions
/// @author Otherplane Labs, 2022.
library Wc3Lib {

    struct Storage {
        address decorator;
        address signator;
        Settings settings;

        uint256 mintGasLimit;
        uint256 hatchingBlock;
        uint256 totalSupply;

        mapping (/* tokenId => WittyCreature */ uint256 => WittyCreature) intrinsics;
    }

    struct Settings {        
        uint256 expirationBlocks;
        uint256 totalEggs;
        uint8[] percentileMarks;
    }

    enum Status {
        Batching,
        Randomizing,
        Hatching,
        Frozen
    }

    struct WittyCreature {
        string  name;
        uint256 birthTimestamp;
        uint256 globalRanking;
        uint256 guildRanking; /// @dev same as tokenId
        uint256 index;
        uint256 mintUsdCost6;
        WittyCreatureRarity rarity;
        uint256 score;
    }

    enum WittyCreatureRarity {
        Legendary,  // 0
        Rare,       // 1
        Common      // 2
    }

    enum WittyCreatureStatus {
        Inexistent,  // 0
        Incubating,  // 1
        Randomizing, // 2
        Hatching,    // 3
        Minted,      // 4
        Frozen       // 5
    }

    // Calculate length of string-equivalent to given bytes32.
    function length(bytes32 _bytes32)
        internal pure
        returns (uint _length)
    {
        for (; _length < 32; _length ++) {
            if (_bytes32[_length] == 0) {
                break;
            }
        }
    }

    /// Generates pseudo-random number uniformly distributed in range [0 .. _range).
    function randomUint8(bytes32 _seed, uint256 _index, uint _range)
        internal pure
        returns (uint8)
    {
        assert(_range > 0 && _range <= 256);
        uint8 _flagBits = uint8(255 - _msbDeBruijn32(uint32(_range)));
        uint256 _number = uint256(keccak256(abi.encode(_seed, _index))) & uint256(2 ** _flagBits - 1);
        return uint8((_number * _range) >> _flagBits); 
    }

    /// Calculate rarity index based on a creature's ranking percentile.
    function rarity(
            Storage storage self,
            uint _percentile100
        )
        internal view
        returns (WittyCreatureRarity)
    {
        uint8 _i; uint8 _cumuled;
        if (_percentile100 > 100) {
            _percentile100 = 100;
        }
        for (; _i < self.settings.percentileMarks.length; _i ++) {
            _cumuled += self.settings.percentileMarks[_i];
            if (_percentile100 <= _cumuled) {
                break;
            }
        }
        return WittyCreatureRarity(_i);
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

    /// Gets tender's current status.
    function status(Storage storage self, IWitnetRandomness _randomizer)
        internal view
        returns (Status)
    {
        uint _hatchingBlock = self.hatchingBlock;
        uint _expirationBlocks = self.settings.expirationBlocks;
        if (_hatchingBlock > 0) {
            if (_randomizer.isRandomized(_hatchingBlock)) {
                if (_expirationBlocks > 0 && block.number > _hatchingBlock + _expirationBlocks) {
                    return Status.Frozen;
                } else {
                    return Status.Hatching;
                }
            } else {
                return Status.Randomizing;
            }
        } else {
            return Status.Batching;
        }
    }

    /// @dev Produces revert message when tender is not in expected status.
    function statusRevertMessage(Status _status)
        internal pure
        returns (string memory)
    {
        if (_status == Status.Frozen) {
            return "Wc3Lib: not in Frozen status";
        } else if (_status == Status.Batching) {
            return "Wc3Lib: not in Batching status";
        } else if (_status == Status.Randomizing) {
            return "Wc3Lib: not in Randomizing status";
        } else if (_status == Status.Hatching) {
            return "Wc3Lib: not in Hatching status";
        } else {
            return "Wc3Lib: bad mood";
        }
    }

    /// Gets tokens's current status.
    function tokenStatus(Storage storage self, IWitnetRandomness _randomizer, uint256 _tokenId)
        internal view
        returns (WittyCreatureStatus)
    {
        WittyCreature memory _wc3 = self.intrinsics[_tokenId];
        if (
            _tokenId == 0
                || _tokenId > self.settings.totalEggs
        ) {
            return WittyCreatureStatus.Inexistent;
        }
        else if (_wc3.birthTimestamp > 0) {
            return WittyCreatureStatus.Minted;
        }
        else {
            uint _hatchingBlock = self.hatchingBlock;
            if (_hatchingBlock > 0) {
                if (_randomizer.isRandomized(_hatchingBlock)) {
                    uint _expirationBlocks = self.settings.expirationBlocks;
                    if (
                        _expirationBlocks > 0
                            && block.number > _hatchingBlock + _expirationBlocks
                    ) {
                        return WittyCreatureStatus.Frozen;
                    } else {
                        return WittyCreatureStatus.Hatching;
                    }
                } else {
                    return WittyCreatureStatus.Randomizing;
                }
            } else {
                return WittyCreatureStatus.Incubating;
            }
        }
    }

    /// Reduces string into bytes32.
    function toBytes32(string memory _string)
        internal pure
        returns (bytes32 _result)
    {
        if (bytes(_string).length == 0) {
            return 0x0;
        } else {
            assembly {
                _result := mload(add(_string, 32))
            }
        }
    }

    /// Converts bytes32 into string.
    function toString(bytes32 _bytes32)
        internal pure
        returns (string memory)
    {
        bytes memory _bytes = new bytes(length(_bytes32));
        for (uint _i = 0; _i < _bytes.length; _i ++) {
            _bytes[_i] = _bytes32[_i];
        }
        return string(_bytes);
    }

    /// Translate rarity index into a literal string.
    function toString(WittyCreatureRarity _rarity)
        internal pure
        returns (string memory)
    {
        if (_rarity == WittyCreatureRarity.Legendary) {
            return "Legendary";
        } else if (_rarity == WittyCreatureRarity.Rare) {
            return "Rare";
        } else {
            return "Common";
        }
    }

    /// Returns index of Most Significant Bit of given number, applying De Bruijn O(1) algorithm.
    function _msbDeBruijn32(uint32 _v)
        private pure
        returns (uint8)
    {
        uint8[32] memory _bitPosition = [
                0, 9, 1, 10, 13, 21, 2, 29, 11, 14, 16, 18, 22, 25, 3, 30,
                8, 12, 20, 28, 15, 17, 24, 7, 19, 27, 23, 6, 26, 5, 4, 31
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
// File: contracts\interfaces\IWc3Decorator.sol
/// @title Witty Creatures 3.0 Decorating interface.
/// @author Otherplane Labs, 2022.
interface IWc3Decorator {
    function baseURI() external view returns (string memory);
    function forged() external view returns (bool);
    function toJSON(bytes32, Wc3Lib.WittyCreature memory) external view returns (string memory);
    function version() external view returns (string memory);
}
// File: contracts\Wc3Decorator.sol
/// @title Decorator contract providing metadata content for Witty Creatures v3
/// @author Otherplane Labs, 2022.
contract Wc3Decorator is IWc3Decorator, Ownable {

    using Strings for uint256;
    using Wc3Lib for bytes32;
    using Wc3Lib for string;
    using Wc3Lib for Wc3Lib.WittyCreatureRarity;

    uint256 internal constant _TRAITS_RANDOM_SPREAD_RANK = 32;

    string internal constant _TRAITS_DEFAULT_BACKGROUND = "Plain";
    string internal constant _TRAITS_DEFAULT_EYES = "Default";
    string internal constant _TRAITS_DEFAULT_HEAD = "Default";
    string internal constant _TRAITS_DEFAULT_MOUTH = "Default";
    string internal constant _TRAITS_DEFAULT_OBJECT = "None";
    string internal constant _TRAITS_DEFAULT_OUTFIT = "Default";    

    bytes32 internal immutable __version;

    string public override baseURI;
    bool public override forged;
    TraitRanges public ranges;

    mapping (uint256 => string) public backgrounds;
    mapping (uint256 => string) public colors;
    mapping (uint256 => string) public eyes;
    mapping (uint256 => string) public guilds;
    mapping (uint256 => string) public heads;
    mapping (uint256 => string) public mouths;
    mapping (uint256 => string) public objects;
    mapping (uint256 => string) public outfits;     

    struct TraitIndexes {
        uint8 backgroundIndex;
        uint8 eyesIndex;
        uint8 headIndex;
        uint8 mouthIndex;
        uint8 objectIndex;
        uint8 outfitIndex;        
    }

    struct TraitRanges {
        uint16 totalBackgrounds;
        uint16 totalColors;
        uint16 totalEyes;
        uint16 totalHeads;
        uint16 totalMouths;
        uint16 totalObjects;
        uint16 totalOutfits;        
    }

    modifier checkRange(string[] memory _tags) {
        require(
            _tags.length <= _TRAITS_RANDOM_SPREAD_RANK,
            "Wc3Decorator: out of range"
        );
        _;
    }

    modifier isForged {
        require(forged, "Wc3Decorator: not forged");
        _;
    }

    modifier notForged {
        require(!forged, "Wc3Decorator: already forged");
        _;
    }

    constructor(
        string memory _version,
        string memory _baseURI,
        string memory _chainName
    ) {
        __version = _version.toBytes32();
        setBaseURI(_baseURI);
        setGuildTag(block.chainid, _chainName);
    }

    function version()
        external view
        override
        returns (string memory)
    {
        return __version.toString();
    }

    function forge()
        external virtual
        notForged
        onlyOwner
    {
        require(ranges.totalBackgrounds > 0, "Wc3Decorator: no backgrounds");
        require(ranges.totalColors > 0, "Wc3Decorator: no colors");
        require(ranges.totalEyes > 0, "Wc3Decorator: no eyes");
        require(ranges.totalHeads > 0, "Wc3Decorator: no heads");
        require(ranges.totalMouths > 0, "Wc3Decorator: no mouths");
        require(ranges.totalObjects > 0, "Wc3Decorator: no objects");
        require(ranges.totalOutfits > 0, "Wc3Decorator: no outfits");
        require(
            bytes(guilds[block.chainid]).length > 0,
            "Wc3Decorator: guild name not set"
        );
        forged = true;
    }

    function getBackgrounds()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalBackgrounds);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = backgrounds[_i];
        }
    }

    function getColors()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalColors);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = colors[_i];
        }
    }

    function getEyes()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalEyes);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = eyes[_i];
        }
    }

    function getGuildName()
        public view
        virtual
        returns (string memory)
    {
        return guilds[block.chainid];
    }

    function getHeads()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalHeads);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = heads[_i];
        }
    }

    function getMouths()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalMouths);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = mouths[_i];
        }
    }
    
    function getObjects()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalObjects);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = objects[_i];
        }
    }

    function getOutfits()
        public view
        virtual
        returns (string[] memory _tags)
    {
        _tags = new string[](ranges.totalOutfits);
        for (uint _i = 0; _i < _tags.length; _i ++) {
            _tags[_i] = outfits[_i];
        }
    }

    function setBaseURI(string memory _baseURI)
        public virtual
        onlyOwner
    {
        bytes memory _rawURI = bytes(_baseURI);
        require(
            _rawURI.length > 0,
            "Wc3Decorator: empty URI"
        );
        require(
            _rawURI[_rawURI.length - 1] == "/",
            "Wc3Decorator: no trailing slash"
        );
        baseURI = _baseURI;  
    }

    // backgrounds
    function setBackgrounds(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                backgrounds[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalBackgrounds = _total;
    }

    // colors
    function setColors(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                colors[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalColors = _total;
    }

    // eyes
    function setEyes(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                eyes[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalEyes = _total;
    }

    // guild
    function setGuildTag(uint _index, string memory _tag)
        public virtual
        notForged
        onlyOwner
    {
        guilds[_index] = _tag;
    }

    // heads
    function setHeads(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                heads[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalHeads = _total;
    }

    // mouths
    function setMouths(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                mouths[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalMouths = _total;
    }

    // objects
    function setObjects(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                objects[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalObjects = _total;
    }

    // outfits
    function setOutfits(string[] memory _tags)
        public virtual
        notForged
        onlyOwner
        checkRange(_tags)
    {
        uint16 _total;
        for (uint _i = 0; _i < _tags.length; _i ++) {
            if (bytes(_tags[_i]).length > 0) {
                outfits[_i] = _tags[_i];
                _total ++;
            }
        }
        ranges.totalOutfits = _total;
    }

    function toJSON(
            bytes32 _randomness,
            Wc3Lib.WittyCreature memory _intrinsics
        )
        external view
        virtual override
        returns (string memory _json)
    {
        TraitIndexes memory _traits = _splitPhenotype(
            keccak256(abi.encodePacked(
                _randomness,
                _intrinsics.index
            ))
        );
        
        string memory _tokenIdStr = _intrinsics.guildRanking.toString();
        string memory _baseURI = baseURI;

        string memory _name = string(abi.encodePacked(
            "\"name\": \"", _intrinsics.name, "\","
        ));
        string memory _description = string(abi.encodePacked(
            "\"description\": \"Witty Creature #",
                _intrinsics.index.toString(),
            " at EthCC'5 (Paris), July 2022.\","
        ));
        string memory _externalUrl = string(abi.encodePacked(
            "\"external_url\": \"", _baseURI, "metadata/", _tokenIdStr, "\","
        ));
        string memory _image = string(abi.encodePacked(
            "\"image\": \"", _baseURI, "image/", _tokenIdStr, "\","
        ));
        string memory _attributes = string(abi.encodePacked(
            "\"attributes\": [",
                _loadAttributes(
                    _intrinsics,
                    _traits
                ),
            "]"
        ));
        return string(abi.encodePacked(
            "{", _name, _description, _externalUrl, _image, _attributes, "}"
        ));
    }

    function _loadAttributes(
            Wc3Lib.WittyCreature memory _intrinsics,
            TraitIndexes memory _traits
        )
        internal view
        returns (string memory)
    {
        return string(abi.encodePacked(
            _loadAttributesIntrinsics(_intrinsics),
            _loadAttributesRandomized(
                _intrinsics.rarity,
                _traits
            )
        ));        
    }

    function _loadAttributesIntrinsics(Wc3Lib.WittyCreature memory _intrinsics)
        internal view
        returns (string memory)
    {
        string memory _birthDate = string(abi.encodePacked(
            "{",
                "\"display_type\": \"date\",",
                "\"trait_type\": \"Birth date\",",
                "\"value\": ", _intrinsics.birthTimestamp.toString(),
            "},"
        ));
        string memory _eggColor = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Egg color\",",
                "\"value\": \"", (
                    colors[_intrinsics.index % ranges.totalColors]
                ), "\""
            "},"
        ));
        string memory _globalRanking = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Global ranking\",",
                "\"value\": ", _intrinsics.globalRanking.toString(),
            "},"
        ));
        string memory _guild = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Guild\",",
                "\"value\": \"", (
                    guilds[block.chainid]
                ), "\""
            "},"
        ));
        string memory _guildRanking = string(abi.encodePacked(
            "{",
                "\"display_type\": \"number\",",
                "\"trait_type\": \"Guild ranking\",",
                "\"value\": ", _intrinsics.guildRanking.toString(),
            "},"
        ));
        string memory _mintCost = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Mint cost (USD)\",",
                "\"value\": ", _toStringDecimals2(_intrinsics.mintUsdCost6),
            "},"
        ));
        string memory _rarity = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Rarity\",",
                "\"value\": \"", (
                    _intrinsics.rarity.toString()
                ), "\""
            "},"
        ));
        string memory _score = string(abi.encodePacked(
            "{", 
                "\"trait_type\": \"Score\",",
                "\"value\": ", _intrinsics.score.toString(),
            "},"
        ));
        return string(abi.encodePacked(
            _birthDate,
            _eggColor,
            _globalRanking,
            _guild,
            _guildRanking,
            _mintCost,
            _rarity,
            _score
        ));
    }

    function _loadAttributesRandomized(
            Wc3Lib.WittyCreatureRarity _rarity,
            TraitIndexes memory _traits
        )
        internal view
        returns (string memory)
    {
        string memory _background = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Background\",",
                "\"value\": \"", (
                    _rarity != Wc3Lib.WittyCreatureRarity.Legendary
                        || bytes(backgrounds[_traits.backgroundIndex]).length == 0
                    ? _TRAITS_DEFAULT_BACKGROUND
                    : backgrounds[_traits.backgroundIndex]
                ), "\""
            "},"
        ));
        string memory _eyes = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Eyes\",",
                "\"value\": \"", (
                    bytes(eyes[_traits.eyesIndex]).length == 0
                        ? _TRAITS_DEFAULT_EYES
                        : eyes[_traits.eyesIndex]
                ), "\""
            "},"
        ));
        string memory _head = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Head\",",
                "\"value\": \"", (
                    bytes(heads[_traits.headIndex]).length == 0
                        ? _TRAITS_DEFAULT_HEAD
                        : heads[_traits.headIndex]
                ), "\""
            "},"
        ));
        string memory _mouth = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Mouth\",",
                "\"value\": \"", (
                    bytes(mouths[_traits.mouthIndex]).length == 0
                        ? _TRAITS_DEFAULT_MOUTH
                        : mouths[_traits.mouthIndex]
                ), "\""
            "},"
        ));
        string memory _object = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Object\",",
                "\"value\": \"", (
                    _rarity == Wc3Lib.WittyCreatureRarity.Common 
                        || bytes(objects[_traits.objectIndex]).length == 0
                    ? _TRAITS_DEFAULT_OBJECT
                    : objects[_traits.objectIndex]
                ), "\""
            "},"
        ));
        string memory _outfit = string(abi.encodePacked(
            "{",
                "\"trait_type\": \"Outfit\",",
                "\"value\": \"", (
                    bytes(outfits[_traits.outfitIndex]).length == 0
                        ? _TRAITS_DEFAULT_OUTFIT
                        : objects[_traits.outfitIndex]
                ), "\""
            "}"
        ));
        return string(abi.encodePacked(
            _background,
            _eyes,
            _head,
            _mouth,
            _object,
            _outfit
        ));
    }

    function _splitPhenotype(bytes32 _phenotype)
        internal view
        returns (TraitIndexes memory _traits)
    {
        uint _nonce;
        _traits.backgroundIndex = _phenotype.randomUint8(_nonce ++, ranges.totalBackgrounds);
        _traits.eyesIndex = _phenotype.randomUint8(_nonce ++, _TRAITS_RANDOM_SPREAD_RANK);
        _traits.headIndex = _phenotype.randomUint8(_nonce ++, _TRAITS_RANDOM_SPREAD_RANK);
        _traits.objectIndex = _phenotype.randomUint8(_nonce ++, ranges.totalObjects);
        _traits.outfitIndex = _phenotype.randomUint8(_nonce ++, _TRAITS_RANDOM_SPREAD_RANK);
        _traits.mouthIndex = _phenotype.randomUint8(_nonce ++, _TRAITS_RANDOM_SPREAD_RANK);
    }

    function _toStringDecimals2(uint256 _decimals6)
        internal pure
        returns (string memory _str)
    {
        uint256 _integer = _decimals6 / 10 ** 6;
        uint256 _fraction2 = (_decimals6 - _integer * 10 ** 6) / 10 ** 4;
        return string(abi.encodePacked(
            _integer.toString(),
            ".",
            _fraction2.toString()
        ));
    }

}