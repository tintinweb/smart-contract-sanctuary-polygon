// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "strings.sol";

import "Strings.sol";
import "ChainlinkClient.sol";
import "Oracle.sol";

contract RainOracle is 
    Oracle, ChainlinkClient 
{
    using strings for bytes32;
    using Chainlink for Chainlink.Request;

    string public constant API_URL = "https://rainsurance.org/api/weather";

    mapping(bytes32 /* Chainlink request ID */ => uint256 /* GIF request ID */) public gifRequests;
    bytes32 private jobId;
    uint256 private payment;

    event LogRainRequest(uint256 requestId, bytes32 chainlinkRequestId, string requestUrl);
    
    event LogRainFulfill(
        uint256 requestId, 
        bytes32 chainlinkRequestId, 
        uint256 aaay
    );

    constructor(
        bytes32 _name,
        address _registry,
        address _chainLinkToken,
        address _chainLinkOperator,
        bytes32 _jobId,
        uint256 _payment
    )
        Oracle(_name, _registry)
    {
        updateRequestDetails(
            _chainLinkToken, 
            _chainLinkOperator, 
            _jobId, 
            _payment);
    }

    function updateRequestDetails(
        address _chainLinkToken,
        address _chainLinkOperator,
        bytes32 _jobId,
        uint256 _payment
    ) 
        public 
        onlyOwner 
    {
        if (_chainLinkToken != address(0)) { setChainlinkToken(_chainLinkToken); }
        if (_chainLinkOperator != address(0)) { setChainlinkOracle(_chainLinkOperator); }
        
        jobId = _jobId;
        payment = _payment;
    }

    function request(uint256 gifRequestId, bytes calldata input)
        external override
        onlyQuery
    {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );

        (
            uint256 startDate, 
            uint256 endDate, 
            int256 lat,
            int256 long
        ) = abi.decode(input, (uint256, uint256, int256, int256));

        string memory requestUrl = prepareRequestUrl(lat, long, startDate, endDate);
        req.add(
            "get",
            requestUrl
        );
        req.add("path", "result");
        req.addInt("times", 1); // Multiply by times value to remove decimals. Parameter required so pass '1' if the number returned doesn't have decimals

        bytes32 chainlinkRequestId = sendChainlinkRequest(req, payment);

        gifRequests[chainlinkRequestId] = gifRequestId;
        emit LogRainRequest(gifRequestId, chainlinkRequestId, requestUrl);
    }

    function prepareRequestUrl(
        int256 lat,
        int256 long,
        uint256 startDate,
        uint256 endDate
    ) public pure returns (string memory requestUrl) {
        string memory latString = string(abi.encodePacked(lat >= 0 ? "" : "-", Strings.toString(abs(lat)))); 
        string memory longString = string(abi.encodePacked(long >= 0 ? "" : "-", Strings.toString(abs(long)))); 
        requestUrl = string(abi.encodePacked(
            API_URL,
            "?startdate=",
            Strings.toString(startDate),
            "&enddate=",
            Strings.toString(endDate),
            "&lat=",
            latString,
            "&long=",
            longString
        ));
    }

    function fulfill(
        bytes32 chainlinkRequestId, 
        uint256 aaay
    )
        public recordChainlinkFulfillment(chainlinkRequestId) 
    {
        uint256 gifRequest = gifRequests[chainlinkRequestId];
        
        bytes memory data =  abi.encode(aaay);
        _respond(gifRequest, data);

        delete gifRequests[chainlinkRequestId];
        emit LogRainFulfill(gifRequest, chainlinkRequestId, aaay);
    }

    function cancel(uint256 requestId)
        external override
        onlyOwner
    {
        // TODO mid/low priority
        // cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    // only used for testing of chainlink operator
    function encodeFulfillParameters(
        bytes32 chainlinkRequestId, 
        bytes32 placeId, 
        uint256 startDate, 
        uint256 endDate, 
        uint256 aaay
    ) 
        external
        pure
        returns(bytes memory parameterData)
    {
        //TODO: for now I'm just ignoring the extra parameters so as not to break the tests. If they are not really needed, then it is better to remove them.
        return abi.encode(
            chainlinkRequestId, 
            aaay
        );
    }


    function abs(int256 x) private pure returns (uint256) {
        return x >= 0 ? uint256(x) : uint256(-x);
    }

    function getChainlinkJobId() external view returns(bytes32 chainlinkJobId) {
        return jobId;
    }

    function getChainlinkPayment() external view returns(uint256 paymentAmount) {
        return payment;
    }

    function getChainlinkToken() external view returns(address linkTokenAddress) {
        return chainlinkTokenAddress();
    }

    function getChainlinkOperator() external view returns(address operator) {
        return chainlinkOracleAddress();
    }
}

// SPDX-License-Identifier: Apache2

// source: https://github.com/Arachnid/solidity-stringutils
/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */
pragma solidity 0.8.2;

library strings {

    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len_) private pure {
        // Copy word-length chunks while possible
        for(; len_ >= 32; len_ -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = type(uint).max;
        if (len_ > 0) {
            mask = 256 ** (32 - len_) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint) {
        uint ret;
        if (self == 0)
            return 0;
        if (uint(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint(self) / 0x100000000000000000000000000000000);
        }
        if (uint(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint(self) / 0x10000000000000000);
        }
        if (uint(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint(self) / 0x100000000);
        }
        if (uint(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint(self) / 0x10000);
        }
        if (uint(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    // merge of toSliceB32 and toString of strings library
    function toB32String(bytes32 self) internal pure returns (string memory) {
        slice memory slc;
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(slc, 0x20), ptr)
        }
        slc._len = len(self);

        string memory ret = new string(slc._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }
        memcpy(retptr, slc._ptr, slc._len);
        return ret;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Chainlink.sol";
import "ENSInterface.sol";
import "LinkTokenInterface.sol";
import "ChainlinkRequestInterface.sol";
import "OperatorInterface.sol";
import "PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "ENSResolver.sol";

/**
 * @title The ChainlinkClient contract
 * @notice Contract writers can inherit this contract in order to create requests for the
 * Chainlink network
 */
abstract contract ChainlinkClient {
  using Chainlink for Chainlink.Request;

  uint256 internal constant LINK_DIVISIBILITY = 10**18;
  uint256 private constant AMOUNT_OVERRIDE = 0;
  address private constant SENDER_OVERRIDE = address(0);
  uint256 private constant ORACLE_ARGS_VERSION = 1;
  uint256 private constant OPERATOR_ARGS_VERSION = 2;
  bytes32 private constant ENS_TOKEN_SUBNAME = keccak256("link");
  bytes32 private constant ENS_ORACLE_SUBNAME = keccak256("oracle");
  address private constant LINK_TOKEN_POINTER = 0xC89bD4E1632D3A43CB03AAAd5262cbe4038Bc571;

  ENSInterface private s_ens;
  bytes32 private s_ensNode;
  LinkTokenInterface private s_link;
  OperatorInterface private s_oracle;
  uint256 private s_requestCount = 1;
  mapping(bytes32 => address) private s_pendingRequests;

  event ChainlinkRequested(bytes32 indexed id);
  event ChainlinkFulfilled(bytes32 indexed id);
  event ChainlinkCancelled(bytes32 indexed id);

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackAddr address to operate the callback on
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildChainlinkRequest(
    bytes32 specId,
    address callbackAddr,
    bytes4 callbackFunctionSignature
  ) internal pure returns (Chainlink.Request memory) {
    Chainlink.Request memory req;
    return req.initialize(specId, callbackAddr, callbackFunctionSignature);
  }

  /**
   * @notice Creates a request that can hold additional parameters
   * @param specId The Job Specification ID that the request will be created for
   * @param callbackFunctionSignature function signature to use for the callback
   * @return A Chainlink Request struct in memory
   */
  function buildOperatorRequest(bytes32 specId, bytes4 callbackFunctionSignature)
    internal
    view
    returns (Chainlink.Request memory)
  {
    Chainlink.Request memory req;
    return req.initialize(specId, address(this), callbackFunctionSignature);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev Calls `chainlinkRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendChainlinkRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendChainlinkRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      ChainlinkRequestInterface.oracleRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      address(this),
      req.callbackFunctionId,
      nonce,
      ORACLE_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Creates a Chainlink request to the stored oracle address
   * @dev This function supports multi-word response
   * @dev Calls `sendOperatorRequestTo` with the stored oracle address
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequest(Chainlink.Request memory req, uint256 payment) internal returns (bytes32) {
    return sendOperatorRequestTo(address(s_oracle), req, payment);
  }

  /**
   * @notice Creates a Chainlink request to the specified oracle address
   * @dev This function supports multi-word response
   * @dev Generates and stores a request ID, increments the local nonce, and uses `transferAndCall` to
   * send LINK which creates a request on the target oracle contract.
   * Emits ChainlinkRequested event.
   * @param oracleAddress The address of the oracle for the request
   * @param req The initialized Chainlink Request
   * @param payment The amount of LINK to send for the request
   * @return requestId The request ID
   */
  function sendOperatorRequestTo(
    address oracleAddress,
    Chainlink.Request memory req,
    uint256 payment
  ) internal returns (bytes32 requestId) {
    uint256 nonce = s_requestCount;
    s_requestCount = nonce + 1;
    bytes memory encodedRequest = abi.encodeWithSelector(
      OperatorInterface.operatorRequest.selector,
      SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
      AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
      req.id,
      req.callbackFunctionId,
      nonce,
      OPERATOR_ARGS_VERSION,
      req.buf.buf
    );
    return _rawRequest(oracleAddress, nonce, payment, encodedRequest);
  }

  /**
   * @notice Make a request to an oracle
   * @param oracleAddress The address of the oracle for the request
   * @param nonce used to generate the request ID
   * @param payment The amount of LINK to send for the request
   * @param encodedRequest data encoded for request type specific format
   * @return requestId The request ID
   */
  function _rawRequest(
    address oracleAddress,
    uint256 nonce,
    uint256 payment,
    bytes memory encodedRequest
  ) private returns (bytes32 requestId) {
    requestId = keccak256(abi.encodePacked(this, nonce));
    s_pendingRequests[requestId] = oracleAddress;
    emit ChainlinkRequested(requestId);
    require(s_link.transferAndCall(oracleAddress, payment, encodedRequest), "unable to transferAndCall to oracle");
  }

  /**
   * @notice Allows a request to be cancelled if it has not been fulfilled
   * @dev Requires keeping track of the expiration value emitted from the oracle contract.
   * Deletes the request from the `pendingRequests` mapping.
   * Emits ChainlinkCancelled event.
   * @param requestId The request ID
   * @param payment The amount of LINK sent for the request
   * @param callbackFunc The callback function specified for the request
   * @param expiration The time of the expiration for the request
   */
  function cancelChainlinkRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunc,
    uint256 expiration
  ) internal {
    OperatorInterface requested = OperatorInterface(s_pendingRequests[requestId]);
    delete s_pendingRequests[requestId];
    emit ChainlinkCancelled(requestId);
    requested.cancelOracleRequest(requestId, payment, callbackFunc, expiration);
  }

  /**
   * @notice the next request count to be used in generating a nonce
   * @dev starts at 1 in order to ensure consistent gas cost
   * @return returns the next request count to be used in a nonce
   */
  function getNextRequestCount() internal view returns (uint256) {
    return s_requestCount;
  }

  /**
   * @notice Sets the stored oracle address
   * @param oracleAddress The address of the oracle contract
   */
  function setChainlinkOracle(address oracleAddress) internal {
    s_oracle = OperatorInterface(oracleAddress);
  }

  /**
   * @notice Sets the LINK token address
   * @param linkAddress The address of the LINK token contract
   */
  function setChainlinkToken(address linkAddress) internal {
    s_link = LinkTokenInterface(linkAddress);
  }

  /**
   * @notice Sets the Chainlink token address for the public
   * network as given by the Pointer contract
   */
  function setPublicChainlinkToken() internal {
    setChainlinkToken(PointerInterface(LINK_TOKEN_POINTER).getAddress());
  }

  /**
   * @notice Retrieves the stored address of the LINK token
   * @return The address of the LINK token
   */
  function chainlinkTokenAddress() internal view returns (address) {
    return address(s_link);
  }

  /**
   * @notice Retrieves the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function chainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addChainlinkExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @notice Sets the stored oracle and LINK token contracts with the addresses resolved by ENS
   * @dev Accounts for subnodes having different resolvers
   * @param ensAddress The address of the ENS contract
   * @param node The ENS node hash
   */
  function useChainlinkWithENS(address ensAddress, bytes32 node) internal {
    s_ens = ENSInterface(ensAddress);
    s_ensNode = node;
    bytes32 linkSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_TOKEN_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(linkSubnode));
    setChainlinkToken(resolver.addr(linkSubnode));
    updateChainlinkOracleWithENS();
  }

  /**
   * @notice Sets the stored oracle contract with the address resolved by ENS
   * @dev This may be called on its own as long as `useChainlinkWithENS` has been called previously
   */
  function updateChainlinkOracleWithENS() internal {
    bytes32 oracleSubnode = keccak256(abi.encodePacked(s_ensNode, ENS_ORACLE_SUBNAME));
    ENSResolver_Chainlink resolver = ENSResolver_Chainlink(s_ens.resolver(oracleSubnode));
    setChainlinkOracle(resolver.addr(oracleSubnode));
  }

  /**
   * @notice Ensures that the fulfillment is valid for this contract
   * @dev Use if the contract developer prefers methods instead of modifiers for validation
   * @param requestId The request ID for fulfillment
   */
  function validateChainlinkCallback(bytes32 requestId)
    internal
    recordChainlinkFulfillment(requestId)
  // solhint-disable-next-line no-empty-blocks
  {

  }

  /**
   * @dev Reverts if the sender is not the oracle of the request.
   * Emits ChainlinkFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    require(msg.sender == s_pendingRequests[requestId], "Source must be the oracle of the request");
    delete s_pendingRequests[requestId];
    emit ChainlinkFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    require(s_pendingRequests[requestId] == address(0), "Request is already pending");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "CBORChainlink.sol";
import {BufferChainlink} from "BufferChainlink.sol";

/**
 * @title Library for common Chainlink functions
 * @dev Uses imported CBOR library for encoding to buffer
 */
library Chainlink {
  uint256 internal constant defaultBufferSize = 256; // solhint-disable-line const-name-snakecase

  using CBORChainlink for BufferChainlink.buffer;

  struct Request {
    bytes32 id;
    address callbackAddress;
    bytes4 callbackFunctionId;
    uint256 nonce;
    BufferChainlink.buffer buf;
  }

  /**
   * @notice Initializes a Chainlink request
   * @dev Sets the ID, callback address, and callback function signature on the request
   * @param self The uninitialized request
   * @param jobId The Job Specification ID
   * @param callbackAddr The callback address
   * @param callbackFunc The callback function signature
   * @return The initialized request
   */
  function initialize(
    Request memory self,
    bytes32 jobId,
    address callbackAddr,
    bytes4 callbackFunc
  ) internal pure returns (Chainlink.Request memory) {
    BufferChainlink.init(self.buf, defaultBufferSize);
    self.id = jobId;
    self.callbackAddress = callbackAddr;
    self.callbackFunctionId = callbackFunc;
    return self;
  }

  /**
   * @notice Sets the data for the buffer without encoding CBOR on-chain
   * @dev CBOR can be closed with curly-brackets {} or they can be left off
   * @param self The initialized request
   * @param data The CBOR data
   */
  function setBuffer(Request memory self, bytes memory data) internal pure {
    BufferChainlink.init(self.buf, data.length);
    BufferChainlink.append(self.buf, data);
  }

  /**
   * @notice Adds a string value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The string value to add
   */
  function add(
    Request memory self,
    string memory key,
    string memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeString(value);
  }

  /**
   * @notice Adds a bytes value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The bytes value to add
   */
  function addBytes(
    Request memory self,
    string memory key,
    bytes memory value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeBytes(value);
  }

  /**
   * @notice Adds a int256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The int256 value to add
   */
  function addInt(
    Request memory self,
    string memory key,
    int256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeInt(value);
  }

  /**
   * @notice Adds a uint256 value to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param value The uint256 value to add
   */
  function addUint(
    Request memory self,
    string memory key,
    uint256 value
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.encodeUInt(value);
  }

  /**
   * @notice Adds an array of strings to the request with a given key name
   * @param self The initialized request
   * @param key The name of the key
   * @param values The array of string values to add
   */
  function addStringArray(
    Request memory self,
    string memory key,
    string[] memory values
  ) internal pure {
    self.buf.encodeString(key);
    self.buf.startArray();
    for (uint256 i = 0; i < values.length; i++) {
      self.buf.encodeString(values[i]);
    }
    self.buf.endSequence();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.19;

import {BufferChainlink} from "BufferChainlink.sol";

library CBORChainlink {
  using BufferChainlink for BufferChainlink.buffer;

  uint8 private constant MAJOR_TYPE_INT = 0;
  uint8 private constant MAJOR_TYPE_NEGATIVE_INT = 1;
  uint8 private constant MAJOR_TYPE_BYTES = 2;
  uint8 private constant MAJOR_TYPE_STRING = 3;
  uint8 private constant MAJOR_TYPE_ARRAY = 4;
  uint8 private constant MAJOR_TYPE_MAP = 5;
  uint8 private constant MAJOR_TYPE_TAG = 6;
  uint8 private constant MAJOR_TYPE_CONTENT_FREE = 7;

  uint8 private constant TAG_TYPE_BIGNUM = 2;
  uint8 private constant TAG_TYPE_NEGATIVE_BIGNUM = 3;

  function encodeFixedNumeric(BufferChainlink.buffer memory buf, uint8 major, uint64 value) private pure {
    if(value <= 23) {
      buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.appendUint8(uint8((major << 5) | 24));
      buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.appendUint8(uint8((major << 5) | 25));
      buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.appendUint8(uint8((major << 5) | 26));
      buf.appendInt(value, 4);
    } else {
      buf.appendUint8(uint8((major << 5) | 27));
      buf.appendInt(value, 8);
    }
  }

  function encodeIndefiniteLengthType(BufferChainlink.buffer memory buf, uint8 major) private pure {
    buf.appendUint8(uint8((major << 5) | 31));
  }

  function encodeUInt(BufferChainlink.buffer memory buf, uint value) internal pure {
    if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, value);
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    }
  }

  function encodeInt(BufferChainlink.buffer memory buf, int value) internal pure {
    if(value < -0x10000000000000000) {
      encodeSignedBigNum(buf, value);
    } else if(value > 0xFFFFFFFFFFFFFFFF) {
      encodeBigNum(buf, uint(value));
    } else if(value >= 0) {
      encodeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(uint256(value)));
    } else {
      encodeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(uint256(-1 - value)));
    }
  }

  function encodeBytes(BufferChainlink.buffer memory buf, bytes memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.append(value);
  }

  function encodeBigNum(BufferChainlink.buffer memory buf, uint value) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    encodeBytes(buf, abi.encode(value));
  }

  function encodeSignedBigNum(BufferChainlink.buffer memory buf, int input) internal pure {
    buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
    encodeBytes(buf, abi.encode(uint256(-1 - input)));
  }

  function encodeString(BufferChainlink.buffer memory buf, string memory value) internal pure {
    encodeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.append(bytes(value));
  }

  function startArray(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
  }

  function startMap(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
  }

  function endSequence(BufferChainlink.buffer memory buf) internal pure {
    encodeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for writing to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library BufferChainlink {
  /**
   * @dev Represents a mutable buffer. Buffers have a current value (buf) and
   *      a capacity. The capacity may be longer than the current value, in
   *      which case it can be extended without the need to allocate more memory.
   */
  struct buffer {
    bytes buf;
    uint256 capacity;
  }

  /**
   * @dev Initializes a buffer with an initial capacity.
   * @param buf The buffer to initialize.
   * @param capacity The number of bytes of space to allocate the buffer.
   * @return The buffer, for chaining.
   */
  function init(buffer memory buf, uint256 capacity) internal pure returns (buffer memory) {
    if (capacity % 32 != 0) {
      capacity += 32 - (capacity % 32);
    }
    // Allocate space for the buffer data
    buf.capacity = capacity;
    assembly {
      let ptr := mload(0x40)
      mstore(buf, ptr)
      mstore(ptr, 0)
      mstore(0x40, add(32, add(ptr, capacity)))
    }
    return buf;
  }

  /**
   * @dev Initializes a new buffer from an existing bytes object.
   *      Changes to the buffer may mutate the original value.
   * @param b The bytes object to initialize the buffer with.
   * @return A new buffer.
   */
  function fromBytes(bytes memory b) internal pure returns (buffer memory) {
    buffer memory buf;
    buf.buf = b;
    buf.capacity = b.length;
    return buf;
  }

  function resize(buffer memory buf, uint256 capacity) private pure {
    bytes memory oldbuf = buf.buf;
    init(buf, capacity);
    append(buf, oldbuf);
  }

  function max(uint256 a, uint256 b) private pure returns (uint256) {
    if (a > b) {
      return a;
    }
    return b;
  }

  /**
   * @dev Sets buffer length to 0.
   * @param buf The buffer to truncate.
   * @return The original buffer, for chaining..
   */
  function truncate(buffer memory buf) internal pure returns (buffer memory) {
    assembly {
      let bufptr := mload(buf)
      mstore(bufptr, 0)
    }
    return buf;
  }

  /**
   * @dev Writes a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The start offset to write to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    require(len <= data.length);

    if (off + len > buf.capacity) {
      resize(buf, max(buf.capacity, len + off) * 2);
    }

    uint256 dest;
    uint256 src;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Start address = buffer address + offset + sizeof(buffer length)
      dest := add(add(bufptr, 32), off)
      // Update buffer length if we're extending it
      if gt(add(len, off), buflen) {
        mstore(bufptr, add(len, off))
      }
      src := add(data, 32)
    }

    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    unchecked {
      uint256 mask = (256**(32 - len)) - 1;
      assembly {
        let srcpart := and(mload(src), not(mask))
        let destpart := and(mload(dest), mask)
        mstore(dest, or(destpart, srcpart))
      }
    }

    return buf;
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(
    buffer memory buf,
    bytes memory data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, len);
  }

  /**
   * @dev Appends a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, data.length);
  }

  /**
   * @dev Writes a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write the byte at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeUint8(
    buffer memory buf,
    uint256 off,
    uint8 data
  ) internal pure returns (buffer memory) {
    if (off >= buf.capacity) {
      resize(buf, buf.capacity * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Length of existing buffer data
      let buflen := mload(bufptr)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if eq(off, buflen) {
        mstore(bufptr, add(buflen, 1))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    return writeUint8(buf, buf.buf.length, data);
  }

  /**
   * @dev Writes up to 32 bytes to the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function write(
    buffer memory buf,
    uint256 off,
    bytes32 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    unchecked {
      uint256 mask = (256**len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + off + len
        let dest := add(add(bufptr, off), len)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(add(off, len), mload(bufptr)) {
          mstore(bufptr, add(off, len))
        }
      }
    }
    return buf;
  }

  /**
   * @dev Writes a bytes20 to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function writeBytes20(
    buffer memory buf,
    uint256 off,
    bytes20 data
  ) internal pure returns (buffer memory) {
    return write(buf, off, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return write(buf, buf.buf.length, data, 32);
  }

  /**
   * @dev Writes an integer to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param off The offset to write at.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer, for chaining.
   */
  function writeInt(
    buffer memory buf,
    uint256 off,
    uint256 data,
    uint256 len
  ) private pure returns (buffer memory) {
    if (len + off > buf.capacity) {
      resize(buf, (len + off) * 2);
    }

    uint256 mask = (256**len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + off + sizeof(buffer length) + len
      let dest := add(add(bufptr, off), len)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(add(off, len), mload(bufptr)) {
        mstore(bufptr, add(off, len))
      }
    }
    return buf;
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   * exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer.
   */
  function appendInt(
    buffer memory buf,
    uint256 data,
    uint256 len
  ) internal pure returns (buffer memory) {
    return writeInt(buf, buf.buf.length, data, len);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ENSInterface {
  // Logged when the owner of a node assigns a new owner to a subnode.
  event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

  // Logged when the owner of a node transfers ownership to a new account.
  event Transfer(bytes32 indexed node, address owner);

  // Logged when the resolver for a node changes.
  event NewResolver(bytes32 indexed node, address resolver);

  // Logged when the TTL of a node changes
  event NewTTL(bytes32 indexed node, uint64 ttl);

  function setSubnodeOwner(
    bytes32 node,
    bytes32 label,
    address owner
  ) external;

  function setResolver(bytes32 node, address resolver) external;

  function setOwner(bytes32 node, address owner) external;

  function setTTL(bytes32 node, uint64 ttl) external;

  function owner(bytes32 node) external view returns (address);

  function resolver(bytes32 node) external view returns (address);

  function ttl(bytes32 node) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ChainlinkRequestInterface {
  function oracleRequest(
    address sender,
    uint256 requestPrice,
    bytes32 serviceAgreementID,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function cancelOracleRequest(
    bytes32 requestId,
    uint256 payment,
    bytes4 callbackFunctionId,
    uint256 expiration
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "OracleInterface.sol";
import "ChainlinkRequestInterface.sol";

interface OperatorInterface is OracleInterface, ChainlinkRequestInterface {
  function operatorRequest(
    address sender,
    uint256 payment,
    bytes32 specId,
    bytes4 callbackFunctionId,
    uint256 nonce,
    uint256 dataVersion,
    bytes calldata data
  ) external;

  function fulfillOracleRequest2(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes calldata data
  ) external returns (bool);

  function ownerTransferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function distributeFunds(address payable[] calldata receivers, uint256[] calldata amounts) external payable;

  function getAuthorizedSenders() external returns (address[] memory);

  function setAuthorizedSenders(address[] calldata senders) external;

  function getForwarder() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OracleInterface {
  function fulfillOracleRequest(
    bytes32 requestId,
    uint256 payment,
    address callbackAddress,
    bytes4 callbackFunctionId,
    uint256 expiration,
    bytes32 data
  ) external returns (bool);

  function isAuthorizedSender(address node) external view returns (bool);

  function withdraw(address recipient, uint256 amount) external;

  function withdrawable() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PointerInterface {
  function getAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IOracle.sol";
import "Component.sol";
import "IComponent.sol";
import "IOracleService.sol";

abstract contract Oracle is
    IOracle, 
    Component 
{   
    IOracleService private _oracleService;

    modifier onlyQuery {
        require(
             _msgSender() == _getContractAddress("Query"),
            "ERROR:ORA-001:ACCESS_DENIED"
        );
        _;
    }

    constructor(
        bytes32 name,
        address registry
    )
        Component(name, ComponentType.Oracle, registry)
    {
        _oracleService = IOracleService(_getContractAddress("OracleService"));
        emit LogOracleCreated(address(this));
    }

    // default callback function implementations
    function _afterApprove() internal override { 
        emit LogOracleApproved(getId()); 
    }

    function _afterPropose() internal override { emit LogOracleProposed(getId()); }
    function _afterDecline() internal override { emit LogOracleDeclined(getId()); }

    function _respond(uint256 requestId, bytes memory data) internal {
        _oracleService.respond(requestId, data);
    }    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IOracle is IComponent {
    
    event LogOracleCreated (address oracleAddress);
    event LogOracleProposed (uint256 componentId);
    event LogOracleApproved (uint256 componentId);
    event LogOracleDeclined (uint256 componentId);
    
    function request(uint256 requestId, bytes calldata input) external;
    function cancel(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IRegistry.sol";

interface IComponent {

    enum ComponentType {
        Oracle,
        Product,
        Riskpool
    }

    enum ComponentState {
        Created,
        Proposed,
        Declined,
        Active,
        Paused,
        Suspended,
        Archived
    }

    event LogComponentCreated (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        address registryAddress);

    function setId(uint256 id) external;

    function getName() external view returns(bytes32);
    function getId() external view returns(uint256);
    function getType() external view returns(ComponentType);
    function getState() external view returns(ComponentState);
    function getOwner() external view returns(address);

    function isProduct() external view returns(bool);
    function isOracle() external view returns(bool);
    function isRiskpool() external view returns(bool);

    function getRegistry() external view returns(IRegistry);

    function proposalCallback() external;
    function approvalCallback() external; 
    function declineCallback() external;
    function suspendCallback() external;
    function resumeCallback() external;
    function pauseCallback() external;
    function unpauseCallback() external;
    function archiveCallback() external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRegistry {

    event LogContractRegistered(
        bytes32 release,
        bytes32 contractName,
        address contractAddress,
        bool isNew
    );

    event LogContractDeregistered(bytes32 release, bytes32 contractName);

    event LogReleasePrepared(bytes32 release);

    function registerInRelease(
        bytes32 _release,
        bytes32 _contractName,
        address _contractAddress
    ) external;

    function register(bytes32 _contractName, address _contractAddress) external;

    function deregisterInRelease(bytes32 _release, bytes32 _contractName)
        external;

    function deregister(bytes32 _contractName) external;

    function prepareRelease(bytes32 _newRelease) external;

    function getContractInRelease(bytes32 _release, bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getContract(bytes32 _contractName)
        external
        view
        returns (address _contractAddress);

    function getRelease() external view returns (bytes32 _release);

    function ensureSender(address sender, bytes32 _contractName) external view returns(bool _senderMatches);

    function contracts() external view returns (uint256 _numberOfContracts);

    function contractName(uint256 idx) external view returns (bytes32 _contractName);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IAccess.sol";
import "IComponentEvents.sol";
import "IRegistry.sol";
import "IComponentOwnerService.sol";
import "IInstanceService.sol";
import "Ownable.sol";


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/GUIDELINES.md#style-guidelines
abstract contract Component is 
    IComponent,
    IComponentEvents,
    Ownable 
{
    bytes32 private _componentName;
    uint256 private _componentId;
    IComponent.ComponentType private _componentType;

    IRegistry private _registry;
    IAccess private _access;
    IComponentOwnerService private _componentOwnerService;
    IInstanceService private _instanceService;

    modifier onlyInstanceOperatorService() {
        require(
             _msgSender() == _getContractAddress("InstanceOperatorService"),
            "ERROR:CMP-001:NOT_INSTANCE_OPERATOR_SERVICE");
        _;
    }

    modifier onlyComponent() {
        require(
             _msgSender() == _getContractAddress("Component"),
            "ERROR:CMP-002:NOT_COMPONENT");
        _;
    }

    modifier onlyComponentOwnerService() {
        require(
             _msgSender() == address(_componentOwnerService),
            "ERROR:CMP-003:NOT_COMPONENT_OWNER_SERVICE");
        _;
    }

    constructor(
        bytes32 name,
        IComponent.ComponentType componentType,
        address registry
    )
        Ownable()
    {
        require(registry != address(0), "ERROR:CMP-004:REGISTRY_ADDRESS_ZERO");

        _registry = IRegistry(registry);
        _access = _getAccess();
        _componentOwnerService = _getComponentOwnerService();
        _instanceService = _getInstanceService();

        _componentName = name;
        _componentType = componentType;

        emit LogComponentCreated(
            _componentName, 
            _componentType, 
            address(this), 
            address(_registry));
    }

    function setId(uint256 id) external override onlyComponent { _componentId = id; }

    function getName() public override view returns(bytes32) { return _componentName; }
    function getId() public override view returns(uint256) { return _componentId; }
    function getType() public override view returns(IComponent.ComponentType) { return _componentType; }
    function getState() public override view returns(IComponent.ComponentState) { return _instanceService.getComponentState(_componentId); }
    function getOwner() public override view returns(address) { return owner(); }

    function isProduct() public override view returns(bool) { return _componentType == IComponent.ComponentType.Product; }
    function isOracle() public override view returns(bool) { return _componentType == IComponent.ComponentType.Oracle; }
    function isRiskpool() public override view returns(bool) { return _componentType == IComponent.ComponentType.Riskpool; }

    function getRegistry() external override view returns(IRegistry) { return _registry; }

    function proposalCallback() public override onlyComponent { _afterPropose(); }
    function approvalCallback() public override onlyComponent { _afterApprove(); }
    function declineCallback() public override onlyComponent { _afterDecline(); }
    function suspendCallback() public override onlyComponent { _afterSuspend(); }
    function resumeCallback() public override onlyComponent { _afterResume(); }
    function pauseCallback() public override onlyComponent { _afterPause(); }
    function unpauseCallback() public override onlyComponent { _afterUnpause(); }
    function archiveCallback() public override onlyComponent { _afterArchive(); }
    
    // these functions are intended to be overwritten to implement
    // component specific notification handling
    function _afterPropose() internal virtual {}
    function _afterApprove() internal virtual {}
    function _afterDecline() internal virtual {}
    function _afterSuspend() internal virtual {}
    function _afterResume() internal virtual {}
    function _afterPause() internal virtual {}
    function _afterUnpause() internal virtual {}
    function _afterArchive() internal virtual {}

    function _getAccess() internal view returns (IAccess) {
        return IAccess(_getContractAddress("Access"));        
    }

    function _getInstanceService() internal view returns (IInstanceService) {
        return IInstanceService(_getContractAddress("InstanceService"));        
    }

    function _getComponentOwnerService() internal view returns (IComponentOwnerService) {
        return IComponentOwnerService(_getContractAddress("ComponentOwnerService"));        
    }

    function _getContractAddress(bytes32 contractName) internal view returns (address) { 
        return _registry.getContract(contractName);
    }

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IAccess {
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns(bool);

    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;
    function renounceRole(bytes32 role, address principal) external;
    
    function addRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IComponentEvents {

    event LogComponentProposed (
        bytes32 componentName,
        IComponent.ComponentType componentType,
        address componentAddress,
        uint256 id);
    
    event LogComponentApproved (uint256 id);
    event LogComponentDeclined (uint256 id);

    event LogComponentSuspended (uint256 id);
    event LogComponentResumed (uint256 id);

    event LogComponentPaused (uint256 id);
    event LogComponentUnpaused (uint256 id);

    event LogComponentArchived (uint256 id);

    event LogComponentStateChanged (
        uint256 id, 
        IComponent.ComponentState stateOld, 
        IComponent.ComponentState stateNew);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";

interface IComponentOwnerService {

    function propose(IComponent component) external;

    function stake(uint256 id) external;
    function withdraw(uint256 id) external;

    function pause(uint256 id) external; 
    function unpause(uint256 id) external;

    function archive(uint256 id) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IComponent.sol";
import "IBundle.sol";
import "IPolicy.sol";
import "IPool.sol";
import "IBundleToken.sol";
import "IComponentOwnerService.sol";
import "IInstanceOperatorService.sol";
import "IOracleService.sol";
import "IProductService.sol";
import "IRiskpoolService.sol";

import "IERC20.sol";
import "IERC721.sol";

interface IInstanceService {

    // instance
    function getChainId() external view returns(uint256 chainId);
    function getChainName() external view returns(string memory chainName);
    function getInstanceId() external view returns(bytes32 instanceId);
    function getInstanceOperator() external view returns(address instanceOperator);

    // registry
    function getComponentOwnerService() external view returns(IComponentOwnerService service);
    function getInstanceOperatorService() external view returns(IInstanceOperatorService service);
    function getOracleService() external view returns(IOracleService service);
    function getProductService() external view returns(IProductService service);
    function getRiskpoolService() external view returns(IRiskpoolService service);
    function contracts() external view returns (uint256 numberOfContracts);
    function contractName(uint256 idx) external view returns (bytes32 name);

    // access
    function getDefaultAdminRole() external view returns(bytes32 role);
    function getProductOwnerRole() external view returns(bytes32 role);
    function getOracleProviderRole() external view returns(bytes32 role);
    function getRiskpoolKeeperRole() external view returns(bytes32 role);
    function hasRole(bytes32 role, address principal) external view returns (bool roleIsAssigned);    

    // component
    function products() external view returns(uint256 numberOfProducts);
    function oracles() external view returns(uint256 numberOfOracles);
    function riskpools() external view returns(uint256 numberOfRiskpools);

    function getComponentId(address componentAddress) external view returns(uint256 componentId);
    function getComponent(uint256 componentId) external view returns(IComponent component);
    function getComponentType(uint256 componentId) external view returns(IComponent.ComponentType componentType);
    function getComponentState(uint256 componentId) external view returns(IComponent.ComponentState componentState);

    // service staking
    function getStakingRequirements(uint256 componentId) external view returns(bytes memory data);
    function getStakedAssets(uint256 componentId) external view returns(bytes memory data);

    // riskpool
    function getRiskpool(uint256 riskpoolId) external view returns(IPool.Pool memory riskPool);
    function getFullCollateralizationLevel() external view returns (uint256);
    function getCapital(uint256 riskpoolId) external view returns(uint256 capitalAmount);
    function getTotalValueLocked(uint256 riskpoolId) external view returns(uint256 totalValueLockedAmount);
    function getCapacity(uint256 riskpoolId) external view returns(uint256 capacityAmount);
    function getBalance(uint256 riskpoolId) external view returns(uint256 balanceAmount);

    function activeBundles(uint256 riskpoolId) external view returns(uint256 numberOfActiveBundles);
    function getActiveBundleId(uint256 riskpoolId, uint256 bundleIdx) external view returns(uint256 bundleId);
    function getMaximumNumberOfActiveBundles(uint256 riskpoolId) external view returns(uint256 maximumNumberOfActiveBundles);

    // bundles
    function getBundleToken() external view returns(IBundleToken token);
    function bundles() external view returns(uint256 numberOfBundles);
    function getBundle(uint256 bundleId) external view returns(IBundle.Bundle memory bundle);
    function unburntBundles(uint256 riskpoolId) external view returns(uint256 numberOfUnburntBundles);

    // policy
    function processIds() external view returns(uint256 numberOfProcessIds);
    function getMetadata(bytes32 processId) external view returns(IPolicy.Metadata memory metadata);
    function getApplication(bytes32 processId) external view returns(IPolicy.Application memory application);
    function getPolicy(bytes32 processId) external view returns(IPolicy.Policy memory policy);
    function claims(bytes32 processId) external view returns(uint256 numberOfClaims);
    function payouts(bytes32 processId) external view returns(uint256 numberOfPayouts);

    function getClaim(bytes32 processId, uint256 claimId) external view returns (IPolicy.Claim memory claim);
    function getPayout(bytes32 processId, uint256 payoutId) external view returns (IPolicy.Payout memory payout);

    // treasury
    function getTreasuryAddress() external view returns(address treasuryAddress);
 
    function getInstanceWallet() external view returns(address walletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address walletAddress);
 
    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeFractionFullUnit() external view returns(uint256 fullUnit);

}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IBundle {

    event LogBundleCreated(
        uint256 bundleId, 
        uint256 riskpoolId, 
        address owner,
        BundleState state,
        uint256 amount
    );

    event LogBundleStateChanged(uint256 bundleId, BundleState oldState, BundleState newState);

    event LogBundleCapitalProvided(uint256 bundleId, address sender, uint256 amount, uint256 capacity);
    event LogBundleCapitalWithdrawn(uint256 bundleId, address recipient, uint256 amount, uint256 capacity);

    event LogBundlePolicyCollateralized(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);
    event LogBundlePayoutProcessed(uint256 bundleId, bytes32 processId, uint256 amount);
    event LogBundlePolicyReleased(uint256 bundleId, bytes32 processId, uint256 amount, uint256 capacity);

    enum BundleState {
        Active,
        Locked,
        Closed,
        Burned
    }

    struct Bundle {
        uint256 id;
        uint256 riskpoolId;
        uint256 tokenId;
        BundleState state;
        bytes filter; // required conditions for applications to be considered for collateralization by this bundle
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function create(address owner_, uint256 riskpoolId_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fund(uint256 bundleId, uint256 amount) external;
    function defund(uint256 bundleId, uint256 amount) external;

    function lock(uint256 bundleId) external;
    function unlock(uint256 bundleId) external;
    function close(uint256 bundleId) external;
    function burn(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPolicy {

    // Events
    event LogMetadataCreated(
        address owner,
        bytes32 processId,
        uint256 productId, 
        PolicyFlowState state
    );

    event LogMetadataStateChanged(
        bytes32 processId, 
        PolicyFlowState state
    );

    event LogApplicationCreated(
        bytes32 processId, 
        uint256 premiumAmount, 
        uint256 sumInsuredAmount
    );

    event LogApplicationRevoked(bytes32 processId);
    event LogApplicationUnderwritten(bytes32 processId);
    event LogApplicationDeclined(bytes32 processId);

    event LogPolicyCreated(bytes32 processId);
    event LogPolicyExpired(bytes32 processId);
    event LogPolicyClosed(bytes32 processId);

    event LogPremiumCollected(bytes32 processId, uint256 amount);
    
    event LogApplicationSumInsuredAdjusted(bytes32 processId, uint256 sumInsuredAmountOld, uint256 sumInsuredAmount);
    event LogApplicationPremiumAdjusted(bytes32 processId, uint256 premiumAmountOld, uint256 premiumAmount);
    event LogPolicyPremiumAdjusted(bytes32 processId, uint256 premiumExpectedAmountOld, uint256 premiumExpectedAmount);

    event LogClaimCreated(bytes32 processId, uint256 claimId, uint256 claimAmount);
    event LogClaimConfirmed(bytes32 processId, uint256 claimId, uint256 confirmedAmount);
    event LogClaimDeclined(bytes32 processId, uint256 claimId);
    event LogClaimClosed(bytes32 processId, uint256 claimId);

    event LogPayoutCreated(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutId,
        uint256 amount
    );

    event LogPayoutProcessed(
        bytes32 processId, 
        uint256 payoutId
    );

    // States
    enum PolicyFlowState {Started, Active, Finished}
    enum ApplicationState {Applied, Revoked, Underwritten, Declined}
    enum PolicyState {Active, Expired, Closed}
    enum ClaimState {Applied, Confirmed, Declined, Closed}
    enum PayoutState {Expected, PaidOut}

    // Objects
    struct Metadata {
        address owner;
        uint256 productId;
        PolicyFlowState state;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Application {
        ApplicationState state;
        uint256 premiumAmount;
        uint256 sumInsuredAmount;
        bytes data; 
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Policy {
        PolicyState state;
        uint256 premiumExpectedAmount;
        uint256 premiumPaidAmount;
        uint256 claimsCount;
        uint256 openClaimsCount;
        uint256 payoutMaxAmount;
        uint256 payoutAmount;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Claim {
        ClaimState state;
        uint256 claimAmount;
        uint256 paidAmount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Payout {
        uint256 claimId;
        PayoutState state;
        uint256 amount;
        bytes data;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function createPolicyFlow(
        address owner,
        uint256 productId, 
        bytes calldata data
    ) external returns(bytes32 processId);

    function createApplication(
        bytes32 processId, 
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata data
    ) external;

    function revokeApplication(bytes32 processId) external;
    function underwriteApplication(bytes32 processId) external;
    function declineApplication(bytes32 processId) external;

    function collectPremium(bytes32 processId, uint256 amount) external;

    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function createPolicy(bytes32 processId) external;
    function expirePolicy(bytes32 processId) external;
    function closePolicy(bytes32 processId) external;

    function createClaim(
        bytes32 processId, 
        uint256 claimAmount, 
        bytes calldata data
    ) external returns (uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function createPayout(
        bytes32 processId,
        uint256 claimId,
        uint256 payoutAmount,
        bytes calldata data
    ) external returns (uint256 payoutId);

    function processPayout(
        bytes32 processId,
        uint256 payoutId
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IPool {

    event LogRiskpoolRegistered(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token, 
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    );
    
    event LogRiskpoolRequiredCollateral(bytes32 processId, uint256 sumInsured, uint256 collateral);
    event LogRiskpoolCollateralizationFailed(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralizationSucceeded(uint256 riskpoolId, bytes32 processId, uint256 amount);
    event LogRiskpoolCollateralReleased(uint256 riskpoolId, bytes32 processId, uint256 amount);

    struct Pool {
        uint256 id; // matches component id of riskpool
        address wallet; // riskpool wallet
        address erc20Token; // the value token of the riskpool
        uint256 collateralizationLevel; // required collateralization level to cover new policies 
        uint256 sumOfSumInsuredCap; // max sum of sum insured the pool is allowed to secure
        uint256 sumOfSumInsuredAtRisk; // current sum of sum insured at risk in this pool
        uint256 capital; // net investment capital amount (<= balance)
        uint256 lockedCapital; // capital amount linked to collateralizaion of non-closed policies (<= capital)
        uint256 balance; // total amount of funds: net investment capital + net premiums - payouts
        uint256 createdAt;
        uint256 updatedAt;
    }

    function registerRiskpool(
        uint256 riskpoolId, 
        address wallet,
        address erc20Token,
        uint256 collateralizationLevel, 
        uint256 sumOfSumInsuredCap
    ) external;

    function setRiskpoolForProduct(uint256 productId, uint256 riskpoolId) external;

    function underwrite(bytes32 processId) external returns(bool success);
    function processPremium(bytes32 processId, uint256 amount) external;
    function processPayout(bytes32 processId, uint256 amount) external;
    function release(bytes32 processId) external; 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "IERC721.sol";

interface IBundleToken is
    IERC721
{
    event LogBundleTokenMinted(uint256 bundleId, uint256 tokenId, address tokenOwner);
    event LogBundleTokenBurned(uint256 bundleId, uint256 tokenId);   

    function burned(uint tokenId) external view returns(bool isBurned);
    function exists(uint256 tokenId) external view returns(bool doesExist);
    function getBundleId(uint256 tokenId) external view returns(uint256 bundleId);
    function totalSupply() external view returns(uint256 tokenCount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

import "ITreasury.sol";

interface IInstanceOperatorService {

    // registry
    function prepareRelease(bytes32 newRelease) external;
    function register(bytes32 contractName, address contractAddress) external;
    function deregister(bytes32 contractName) external;
    function registerInRelease(bytes32 release, bytes32 contractName, address contractAddress) external;
    function deregisterInRelease(bytes32 release, bytes32 contractName) external;

    // access
    function createRole(bytes32 role) external;
    function invalidateRole(bytes32 role) external;
    function grantRole(bytes32 role, address principal) external;
    function revokeRole(bytes32 role, address principal) external;

    // component
    function approve(uint256 id) external;
    function decline(uint256 id) external;
    function suspend(uint256 id) external;
    function resume(uint256 id) external;
    function archive(uint256 id) external;
    
    // service staking
    function setDefaultStaking(uint16 componentType, bytes calldata data) external;
    function adjustStakingRequirements(uint256 id, bytes calldata data) external;

    // treasury
    function suspendTreasury() external;
    function resumeTreasury() external;
    
    function setInstanceWallet(address walletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address walletAddress) external;  
    function setProductToken(uint256 productId, address erc20Address) external; 

    function setPremiumFees(ITreasury.FeeSpecification calldata feeSpec) external;
    function setCapitalFees(ITreasury.FeeSpecification calldata feeSpec) external;
    
    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    ) external view returns(ITreasury.FeeSpecification memory);


}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;
import "IERC20.sol";

interface ITreasury {

    event LogTreasurySuspended();
    event LogTreasuryResumed();

    event LogTreasuryProductTokenSet(uint256 productId, uint256 riskpoolId, address erc20Address);
    event LogTreasuryInstanceWalletSet(address walletAddress);
    event LogTreasuryRiskpoolWalletSet(uint256 riskpoolId, address walletAddress);

    event LogTreasuryPremiumFeesSet(uint256 productId, uint256 fixedFee, uint256 fractionalFee);
    event LogTreasuryCapitalFeesSet(uint256 riskpoolId, uint256 fixedFee, uint256 fractionalFee);

    event LogTreasuryPremiumTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryPayoutTransferred(address riskpoolWalletAddress, address to, uint256 amount);
    event LogTreasuryCapitalTransferred(address from, address riskpoolWalletAddress, uint256 amount);
    event LogTreasuryFeesTransferred(address from, address instanceWalletAddress, uint256 amount);
    event LogTreasuryWithdrawalTransferred(address riskpoolWalletAddress, address to, uint256 amount);

    event LogTreasuryPremiumProcessed(bytes32 processId, uint256 amount);
    event LogTreasuryPayoutProcessed(uint256 riskpoolId, address to, uint256 amount);
    event LogTreasuryCapitalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);
    event LogTreasuryWithdrawalProcessed(uint256 riskpoolId, uint256 bundleId, uint256 amount);

    struct FeeSpecification {
        uint256 componentId;
        uint256 fixedFee;
        uint256 fractionalFee;
        bytes feeCalculationData;
        uint256 createdAt;
        uint256 updatedAt;
    }

    function setProductToken(uint256 productId, address erc20Address) external;

    function setInstanceWallet(address instanceWalletAddress) external;
    function setRiskpoolWallet(uint256 riskpoolId, address riskpoolWalletAddress) external;

    function createFeeSpecification(
        uint256 componentId,
        uint256 fixedFee,
        uint256 fractionalFee,
        bytes calldata feeCalculationData
    )
        external view returns(FeeSpecification memory feeSpec);
    
    function setPremiumFees(FeeSpecification calldata feeSpec) external;
    function setCapitalFees(FeeSpecification calldata feeSpec) external;
    
    function processPremium(bytes32 processId) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPremium(bytes32 processId, uint256 amount) external 
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function processPayout(bytes32 processId, uint256 payoutId) external 
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );
    
    function processCapital(uint256 bundleId, uint256 capitalAmount) external 
        returns(
            uint256 feeAmount,
            uint256 netCapitalAmount
        );

    function processWithdrawal(uint256 bundleId, uint256 amount) external
        returns(
            uint256 feeAmount,
            uint256 netAmount
        );

    function getComponentToken(uint256 componentId) external view returns(IERC20 token);
    function getFeeSpecification(uint256 componentId) external view returns(FeeSpecification memory feeSpecification);

    function getFractionFullUnit() external view returns(uint256);
    function getInstanceWallet() external view returns(address instanceWalletAddress);
    function getRiskpoolWallet(uint256 riskpoolId) external view returns(address riskpoolWalletAddress);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IOracleService {

    function respond(uint256 requestId, bytes calldata data) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IProductService {

    function newApplication(
        address owner,
        uint256 premiumAmount,
        uint256 sumInsuredAmount,
        bytes calldata metaData, 
        bytes calldata applicationData 
    ) external returns(bytes32 processId);

    function collectPremium(bytes32 processId, uint256 amount) external
        returns(
            bool success,
            uint256 feeAmount,
            uint256 netPremiumAmount
        );
    
    function adjustPremiumSumInsured(
        bytes32 processId, 
        uint256 expectedPremiumAmount,
        uint256 sumInsuredAmount
    ) external;

    function revoke(bytes32 processId) external;
    function underwrite(bytes32 processId) external returns(bool success);
    function decline(bytes32 processId) external;
    function expire(bytes32 processId) external;
    function close(bytes32 processId) external;

    function newClaim(
        bytes32 processId, 
        uint256 claimAmount,
        bytes calldata data
    ) external returns(uint256 claimId);

    function confirmClaim(
        bytes32 processId, 
        uint256 claimId, 
        uint256 confirmedAmount
    ) external;

    function declineClaim(bytes32 processId, uint256 claimId) external;
    function closeClaim(bytes32 processId, uint256 claimId) external;

    function newPayout(
        bytes32 processId, 
        uint256 claimId, 
        uint256 amount,
        bytes calldata data
    ) external returns(uint256 payoutId);

    function processPayout(bytes32 processId, uint256 payoutId) external
        returns(
            uint256 feeAmount,
            uint256 netPayoutAmount
        );

    function request(
        bytes32 processId,
        bytes calldata data,
        string calldata callbackMethodName,
        address callbackContractAddress,
        uint256 responsibleOracleId
    ) external returns(uint256 requestId);

    function cancelRequest(uint256 requestId) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.2;

interface IRiskpoolService {

    function registerRiskpool(
        address wallet,
        address erc20Token,
        uint256 collateralization, 
        uint256 sumOfSumInsuredCap
    ) external;

    function createBundle(address owner_, bytes calldata filter_, uint256 amount_) external returns(uint256 bundleId);
    function fundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);
    function defundBundle(uint256 bundleId, uint256 amount) external returns(uint256 netAmount);

    function lockBundle(uint256 bundleId) external;
    function unlockBundle(uint256 bundleId) external;
    function closeBundle(uint256 bundleId) external;
    function burnBundle(uint256 bundleId) external;

    function collateralizePolicy(uint256 bundleId, bytes32 processId, uint256 collateralAmount) external;
    function processPremium(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function processPayout(uint256 bundleId, bytes32 processId, uint256 amount) external;
    function releasePolicy(uint256 bundleId, bytes32 processId) external returns(uint256 collateralAmount);

    function setMaximumNumberOfActiveBundles(uint256 riskpoolId, uint256 maxNumberOfActiveBundles) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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