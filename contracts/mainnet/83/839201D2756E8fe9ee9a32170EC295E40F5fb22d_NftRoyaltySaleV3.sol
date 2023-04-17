// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {CBORChainlink} from "./vendor/CBORChainlink.sol";
import {BufferChainlink} from "./vendor/BufferChainlink.sol";

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
pragma solidity ^0.8.0;

import "./Chainlink.sol";
import "./interfaces/ENSInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./interfaces/ChainlinkRequestInterface.sol";
import "./interfaces/OperatorInterface.sol";
import "./interfaces/PointerInterface.sol";
import {ENSResolver as ENSResolver_Chainlink} from "./vendor/ENSResolver.sol";

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

import "./OracleInterface.sol";
import "./ChainlinkRequestInterface.sol";

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
pragma solidity >=0.4.19;

import {BufferChainlink} from "./BufferChainlink.sol";

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

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/// @title Picardy Protocol Hub Contract
/// @author Blok_hamster  
/// @notice This contract is the hub of the Picardy Protocol. It is the admin access to the protocol the Picardy Protocol.
contract PicardyHub is AccessControlEnumerable {

    event FactoryAdded(string  factoryName, address factoryAddress);
    event FactoryRemoved(address factoryAddress);
    event RoyaltyAddressUpdated(address royaltyAddress);

    bytes32 public constant HUB_ADMIN_ROLE = keccak256("HUB_ADMIN_ROLE");
    mapping (string => address) public factories;
    mapping (address => bool) public isFactory;
    address[] public depricatedFactories;
    address royaltyAddress;
    address royaltyAdapter;
    address royaltyRegistrar;
    address paymaster;
    
    modifier onlyAdmin {
        _isHubAdmain();
        _;
    }
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(HUB_ADMIN_ROLE, _msgSender());
    }
    /// @notice This function is used to add a new factory to the protocol.
    /// @param _factoryName The name of the factory to be added.
    /// @param _factoryAddress The address of the factory to be added.
    function addFactory(string calldata _factoryName, address _factoryAddress) external onlyAdmin {
        factories[_factoryName] = _factoryAddress;
        isFactory[_factoryAddress] = true;
        emit FactoryAdded(_factoryName, _factoryAddress);
    }
    /// @notice This function is used to update the royalty address for the protocol.
    /// @param _royaltyAddress The address for recieving royalty to the protocol.
    function updateRoyaltyAddress(address _royaltyAddress) external onlyAdmin {
        require(_royaltyAddress != address(0), "Royalty address cannot be zero address");
        royaltyAddress = _royaltyAddress;
        emit RoyaltyAddressUpdated(_royaltyAddress);
    }

    function addRoyaltyAdapter(address _royaltyAdapter) external onlyAdmin {
        require(_royaltyAdapter != address(0), "Royalty adapter cannot be zero address");
        royaltyAdapter = _royaltyAdapter;
    }

    function addRoyaltyRegistrar(address _royaltyRegistrar) external onlyAdmin {
        require(_royaltyRegistrar != address(0), "Royalty registrar cannot be zero address");
        royaltyRegistrar = _royaltyRegistrar;
    }

    function addPaymaster(address _paymaster) external onlyAdmin {
        require(_paymaster != address(0), "Paymaster cannot be zero address");
        paymaster = _paymaster;
    }

    function getRoyaltyAdapter() external view returns(address){
        return royaltyAdapter;
    }

    function getRoyaltyRegistrar() external view returns(address){
        return royaltyRegistrar;
    }

    function getPaymaster() external view returns(address){
        return paymaster;
    }

    function getRoyaltyAddress() external view returns(address){
        return royaltyAddress;

    }

    function checkHubAdmin(address addr) external view returns(bool){
        if (hasRole(HUB_ADMIN_ROLE, addr)){
            return true;
        } else {
            return false;
        }
    }

    /// @notice This function is used to add depricated factories to the protocol.
    /// @param _factoryAddress The address of the factory to be depricated.
    function depricateFactory(address _factoryAddress) external onlyAdmin{
        require(isFactory[_factoryAddress], "Factory does not exist");
        depricatedFactories.push(_factoryAddress);
        emit FactoryRemoved(_factoryAddress);
    }

    function getDepricatedFactories() external view returns(address[] memory){
        return depricatedFactories;
    }

    function getHubAddress() external view returns(address) {
        return address(this);
    }

    function _isHubAdmain() internal view {
        require(hasRole(HUB_ADMIN_ROLE, _msgSender()), "Not Admin");
    }
}

interface IPicardyHub {
    function addFactory(string calldata _factoryName, address factoryAddress) external;
    function updateRoyaltyAddress(address _royaltyAddress) external;
    function checkHubAdmin(address addr) external returns(bool);
    function getRoyaltyAddress() external view returns(address);
    function getHubAddress() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CPTokenV3 is ERC20 {

    uint decimal = 10**18;
    address public owner;
    address[] holders;

    modifier onlyOwner {
        require(msg.sender == owner, "not approved");
        _;
    }

    constructor(string memory _name, address _owner, string memory _symbol) ERC20(_name, _symbol){
        owner = _owner;
    }

    function mint(uint _amount, address _to) external onlyOwner {
        uint toMint = _amount * decimal;
        _mint(_to, toMint);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        super.transfer(recipient, amount);
        holders.push(recipient);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  override returns (bool) {
        super.transferFrom(sender, recipient, amount);
        holders.push(recipient);
        return true;
    }

    function getHolders() public view returns (address[] memory) {
        return holders;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract PicardyNftBase is ERC721Enumerable, Pausable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  
  struct Royalty {
  string baseURI;
  string  artisteName;
  uint256 maxSupply;
  uint256 maxMintAmount;
  uint saleCount;
  uint percentage;
  address[] holders;
  address saleAddress;
  }
  Royalty royalty;

  string public baseExtension = ".json";

  modifier onlySaleContract {
    _onlySaleContract();
    _;
  }

  constructor(
    uint _maxSupply,
    uint _maxMintAmount,
    uint _percentage,
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _artisteName,
    address _saleAddress,
    address _creator
  ) ERC721(_name, _symbol) {
    royalty.maxSupply = _maxSupply;
    royalty.maxMintAmount = _maxMintAmount;
    royalty.percentage = _percentage;
    royalty.baseURI = _initBaseURI;
    royalty.artisteName = _artisteName;
    royalty.saleAddress = _saleAddress;
    transferOwnership(_creator);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return royalty.baseURI;
  }

  // public

  // Holders has to approve spend before buying the token
  function buyRoyalty(uint256 _mintAmount, address addr) external onlySaleContract{
    uint256 supply = totalSupply();

    if (_tokenIds.current() == 0) {
      _tokenIds.increment();
    }

    require(_mintAmount > 0);
    require(_mintAmount <= royalty.maxMintAmount);
    require(supply + _mintAmount <= royalty.maxSupply);

    royalty.holders.push(addr);
    royalty.saleCount += _mintAmount;
   
    for (uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(addr, _tokenIds.current());
      _tokenIds.increment();
    }
  }

  function holdersTokenIds(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setMaxMintAmount(uint256 _newmaxMintAmount) external onlyOwner{
    royalty.maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    royalty.baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause() public onlySaleContract {
        _pause();
    }

  function unpause() public onlySaleContract{
        _unpause();
    }
 
  function withdraw(address _addr) public onlyOwner{
    uint balance = address(this).balance;
    (bool os, ) = payable(_addr).call{value: balance}("");
    require(os);
  }

  function withdrawERC20(address _token, address _addr) public onlyOwner{
    IERC20 token = IERC20(_token);
    uint balance = token.balanceOf(address(this));
    (bool success) = token.transfer(_addr, balance);
    require(success, "withdrawal failed");
  }

  //override transferFrom
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    royalty.holders.push(to);
    super.transferFrom(from, to, tokenId); 
  }

  //override safeTransferFrom
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    super.safeTransferFrom(from, to, tokenId);
    royalty.holders.push(to);
  }

  function _burn( uint256 tokenId) internal override {
    require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
    for (uint i = 0; i < royalty.holders.length; i++) {
      if (royalty.holders[i] == ownerOf(tokenId)) {
        royalty.holders[i] = royalty.holders[royalty.holders.length - 1];
        royalty.holders.pop();
        break;
      }
    }
    super._burn(tokenId);
  }


  function getHolders() public view returns (address[] memory){
    return royalty.holders;
  }

  function getSaleCount() public view returns (uint){
    return royalty.saleCount;
  }

  function _onlySaleContract() internal view {
    require(msg.sender == royalty.saleAddress);
  }
}

interface IPicardyNftBase {
   function getHolders() external view returns (address[] memory);
   function getSaleCount() external view returns (uint);
   function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
/// @title Paymaster V2
/// @author Joshua Obigwe

import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol"; 
import {IRoyaltyAutomationRegistrarV3} from "../AutomationV3/RoyaltyAutomationRegV3.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract PayMasterV3 {

    event PaymentPending(address indexed royaltyAddress, string indexed ticker, uint indexed amount);
    event PendingRoyaltyRefunded (address indexed royaltyAddress, string indexed ticker, uint indexed amount);
    event RoyaltyPaymentSent(address indexed royaltyAddress, string indexed ticker, uint indexed amount);

    IPicardyHub public picardyHub;
    address private regAddress;

    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyReserve; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyReserve
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPending; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPending
    mapping (address => mapping (address => mapping ( string => uint256))) public royaltyPaid; // reoyaltyAdapter -> royaltyAddress -> ticker = royaltyPaid
    
    mapping (address => mapping (address => bool)) public isRegistered; // royaltyAdapter -> royaltyAddress = isRegistered
    mapping (address => RoyaltyData) public royaltyData; // royaltyAdapter = RoyaltyData
    mapping (string => address) public tokenAddress;
    mapping (string => bool) tickerExist;

    struct RoyaltyData {
        address adapter;
        address payable royaltyAddress;
        uint royaltyType;
        string ticker;
    }

    IRoyaltyAutomationRegistrarV3 public i_royaltyReg;
    
    // Royalty Type 0 = NFT Royalty
    // Royalty Type 1 = Token Royalty

    constructor(address _picardyHub) {
        picardyHub = IPicardyHub(_picardyHub);
        tickerExist["ETH"] = true;
    }

    /// @notice Add a new token to the PayMaster
    /// @param _ticker The ticker of the token
    /// @param _tokenAddress The address of the token
    /// @dev Only the PicardyHub admin can call this function
    function addToken(string memory _ticker, address _tokenAddress) external {
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        require(tickerExist[_ticker] == false, "addToken: Token already Exist");
        tokenAddress[_ticker] = _tokenAddress;
        tickerExist[_ticker] = true;
    }

    /// @notice adds the picardyRegistrar address to the PayMaster
    /// @param _picardyReg The address of the picardyRegistrar
    /// @dev Only the PicardyHub admin can call this function
    function addRegAddress(address _picardyReg) external {
        require(picardyHub.checkHubAdmin(msg.sender), "addToken: Un-Auth");
        regAddress = _picardyReg;
        i_royaltyReg = IRoyaltyAutomationRegistrarV3(_picardyReg);
    }

    /// @notice Remove a token from the PayMaster
    /// @param _ticker The ticker of the token
    /// @dev Only the PicardyHub admin can call this function
    function removeToken(string memory _ticker) external {
        require(picardyHub.checkHubAdmin(msg.sender), "removeToken: Un-Auth");
        require(tickerExist[_ticker] == true, "addToken: Token does not Exist");
        delete tokenAddress[_ticker];
        delete tickerExist[_ticker];
    }

    /// @notice registers a new royalty to the paymaster
    /// @param _adapter The address for picardy royalty adapter
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param royaltyType The type of royalty (0 = NFT, 1 = Token)
    /// @param ticker The ticker of the token to be paid to the royalty holders from pay master (e.g. ETH, USDC, etc)
    /// @dev Only the picardyRegistrar can call this function on automation registration
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType, string memory ticker) external {
        require(msg.sender == regAddress, "addRoyaltyData: only picardyReg"); 
        require(royaltyType == 0 || royaltyType == 1, "addRoyaltyData: Invalid royaltyType");
        require(_adapter != address(0), "addRoyaltyData: Invalid adapter");
        require(_royaltyAddress != address(0), "addRoyaltyData: Invalid royaltyAddress");
        require(isRegistered[_royaltyAddress][_adapter] == false, "addRoyaltyData: Already registered");
        royaltyData[_royaltyAddress] = RoyaltyData(_adapter, payable(_royaltyAddress), royaltyType, ticker);
        isRegistered[_royaltyAddress][_adapter] = true;
    }

    /// @notice removes a royalty from the paymaster
    /// @param _adapter The address for picardy royalty adapter
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @dev Only the picardyRegistrar can call this function on automation cancellation
    function removeRoyaltyData(address _adapter, address _royaltyAddress) external {
        require(_adapter != address(0), "removeRoyaltyData: Invalid adapter");
        require(_royaltyAddress != address(0), "removeRoyaltyData: Invalid royaltyAddress");
        require(msg.sender == regAddress, "removeRoyaltyData: only picardyReg");
        require(isRegistered[_royaltyAddress][_adapter] == true, "removeRoyaltyData: Not registered");
        delete royaltyData[_royaltyAddress];
        delete isRegistered[_royaltyAddress][_adapter];
    }

    /// @notice updates the ETH reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _amount The amount of ETH to be added to the reserve
    /// @dev This function can be called by anyone as it basically just adds ETH to the royalty reserve
    function addETHReserve(address _royaltyAddress, uint256 _amount) external payable {
        require(_royaltyAddress != address(0), "addETHReserve: Invalid adapter");
        require(_amount != 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "addETHReserve: Not registered");
        require(msg.sender.balance >= _amount, "addETHReserve: Insufficient balance");
        require(msg.value == _amount, "addETHReserve: Insufficient ETH sent");
        royaltyReserve[_royaltyAddress][_adapter]["ETH"] += msg.value;
    }

    /// @notice updates the ERC20 reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be added to the reserve
    /// @param _amount The amount of tokens to be added to the reserve
    /// @dev This function can be called by anyone as it basically just adds tokens to the royalty reserve
    function addERC20Reserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "addETHReserve: Invalid adapter");
        require(_amount > 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "addERC20Reserve: Not registered");
        require(tokenAddress[_ticker] != address(0), "addERC20Reserve: Token not registered");
        require(IERC20(tokenAddress[_ticker]).balanceOf(msg.sender) >= _amount, "addERC20Reserve: Insufficient balance");
        (bool success) = IERC20(tokenAddress[_ticker]).transferFrom(msg.sender, address(this), _amount);
        require(success, "addERC20Reserve: Transfer failed");
        royaltyReserve[_royaltyAddress][_adapter][_ticker] += _amount;
    }

    /// @notice withdraws the ETH reserve for payment of royalty splits to royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _amount The amount of ETH to be withdrawn from the reserve
    /// @dev This function can only be called by the royalty contract admin
    function withdrawReserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "withdrawReserve: Invalid adapter");
        require(_amount > 0, "Amount must be greather than zero");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "withdrawReserve: Not registered");
        require(msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "withdrawReserve: not royalty admin");
        uint balance = royaltyReserve[_royaltyAddress][_adapter][_ticker];
        require(balance >= _amount, "withdrawReserve: Insufficient balance");
        royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
        if(keccak256(abi.encodePacked(_ticker)) == keccak256(abi.encodePacked("ETH"))){
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        require(success, "withdrawReserve: withdraw failed");
        }else{
            (bool success) = IERC20(tokenAddress[_ticker]).transfer(msg.sender, _amount);
            require(success, "withdrawReserve: Transfer failed");
        }
    }

    /// @notice sends the royalty payment to the royalty sale contract to be distributed to the royalty holders
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be sent to the royalty sales contract
    /// @param _amount The amount to be sent to the royalty sales contract
    /// @dev This function can only be called by picardy royalty adapter, With the amount being the return form chainlink node.
    /// @dev The amount is then multiplied by the royalty percentage to get the amount to be sent to the royalty sales contract
    /// @dev if the reserve balance of the token is less than the amount to be sent, the amount is added to the pending payments
    function sendPayment(address _royaltyAddress, string memory _ticker, uint256 _amount) external  returns(bool){
        require(_royaltyAddress != address(0), "sendPayment: Invalid royaltyAddress");
        require(tickerExist[_ticker] == true, "sendPayment: Token not registered");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "sendPayment: Not registered");
        require(msg.sender == _adapter, "sendPayment: Un-Auth");
        
        uint balance = royaltyReserve[_royaltyAddress][_adapter][_ticker];
        uint royaltyType = royaltyData[_royaltyAddress].royaltyType;
        uint percentageToBips = _royaltyPercentage(_royaltyAddress, royaltyType);

        uint send = (_amount * percentageToBips) / 10000;
        uint toSend = send * 10**18;
        
        if(balance < _amount){
            royaltyPending[_royaltyAddress][_adapter][_ticker] += toSend;
            emit PaymentPending(_royaltyAddress, _ticker, toSend);
        
        } else {
            
            if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
            royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
            (bool success, ) = payable(_royaltyAddress).call{value: toSend}("");
            require (success);
            
            } else {
                require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
                require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= toSend, "low reserve balance");
                if(royaltyType == 0){
                    require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                    royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
                    IPicardyNftRoyaltySaleV3(_royaltyAddress).updateRoyalty(toSend, tokenAddress[_ticker]);
                    royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
                } else if(royaltyType == 1){
                    require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                    royaltyReserve[_royaltyAddress][_adapter][_ticker] -= toSend;
                    IPicardyTokenRoyaltySaleV3(_royaltyAddress).updateRoyalty(toSend, tokenAddress[_ticker]);
                    royaltyPaid[_royaltyAddress][_adapter][_ticker] += toSend;
                }

                (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, toSend);
                require (success);    
            }
        }
        emit RoyaltyPaymentSent(_royaltyAddress, _ticker, toSend); 
        return true;
    }

    /// @notice gets the royalty percentage from the royalty sales contract and converts it to bips
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _royaltyType The type of royalty sales contract
    /// @dev This is internal view function and doesnt write to state.
    function _royaltyPercentage(address _royaltyAddress, uint _royaltyType) internal view returns(uint){
        require(_royaltyAddress != address(0), "getRoyaltyPercentage: Invalid royaltyAddress");
        require(_royaltyType == 0 || _royaltyType == 1, "getRoyaltyPercentage: Invalid royaltyType");
        uint percentageToBips;
        if (_royaltyType == 0){
            uint percentage = IPicardyNftRoyaltySaleV3(_royaltyAddress).getRoyaltyPercentage();
            percentageToBips = percentage * 100;
        } else if (_royaltyType == 1){
            uint percentage = IPicardyTokenRoyaltySaleV3(_royaltyAddress).getRoyaltyPercentage();
            percentageToBips = percentage * 100;
        }

        return percentageToBips;
    }

    /// @notice Refunds the pending unpaid royalty to the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token to be sent to the royalty sales contract
    /// @param _amount The amount to be sent to the royalty sales contract
    /// @dev this function should be called by the royalty sale contract admin
    function refundPending(address _royaltyAddress, string memory _ticker, uint256 _amount) external {
        require(_royaltyAddress != address(0), "refundPending: Invalid adapter");
        require(msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "withdrawReserve: not royalty admin");
        require(tickerExist[_ticker] == true, "refundPending: Token not registered");
        address _adapter = royaltyData[_royaltyAddress].adapter;
        require(isRegistered[_royaltyAddress][_adapter] == true, "refundPending: Not registered");
        require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= _amount, "refundPending: low reserve balance");
        require(_amount <= royaltyPending[_royaltyAddress][_adapter][_ticker], "refundPending: amount is greather than pending royalty");
        
        uint royaltyType = royaltyData[_royaltyAddress].royaltyType;
        
        if(keccak256(bytes(_ticker)) == keccak256(bytes("ETH"))){
            
            royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
            royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
            royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
            (bool success, ) = payable(_royaltyAddress).call{value: _amount}("");
            require (success);
        
        } else {
            
            require(tokenAddress[_ticker] != address(0), "sendPayment: Token not registered");
            require(royaltyReserve[_royaltyAddress][_adapter][_ticker] >= _amount, "low reserve balance");
            
            if(royaltyType == 0){
                require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
                IPicardyNftRoyaltySaleV3(_royaltyAddress).updateRoyalty(_amount, tokenAddress[_ticker]);
            } else if(royaltyType == 1){
                require(IRoyaltyAdapterV3(_adapter).checkIsValidSaleAddress(_royaltyAddress) == true, "Royalty address invalid");
                royaltyReserve[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPending[_royaltyAddress][_adapter][_ticker] -= _amount;
                royaltyPaid[_royaltyAddress][_adapter][_ticker] += _amount;
                IPicardyTokenRoyaltySaleV3(_royaltyAddress).updateRoyalty(_amount, tokenAddress[_ticker]);
            }
            
            (bool success) = IERC20(tokenAddress[_ticker]).transfer(_royaltyAddress, _amount);
            require (success);    
        }

        emit PendingRoyaltyRefunded(_royaltyAddress, _ticker, _amount);
    }

    /// @notice Gets the ETH royalty reserve balance of the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @dev This is external view function and doesnt write to state.
    function getETHReserve(address _royaltyAddress) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyReserve[_royaltyAddress][_adapter]["ETH"];
    }

    /// @notice Gets the ERC20 royalty reserve balance for the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getERC20Reserve(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyReserve[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice Gets the royalty pending balance for the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getPendingRoyalty(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyPending[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice returns the amount of royalty that has paid to the royalty sales contract
    /// @param _royaltyAddress The address of the royalty sales contract
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getRoyaltyPaid(address _royaltyAddress, string memory _ticker) external view returns (uint256) {
        address _adapter = royaltyData[_royaltyAddress].adapter;
        return royaltyPaid[_royaltyAddress][_adapter][_ticker];
    }

    /// @notice gets the royalty address of the token by ticker
    /// @param _ticker The ticker of the token
    /// @dev This is external view function and doesnt write to state.
    function getTokenAddress(string memory _ticker) external view returns (address) {
        return tokenAddress[_ticker];
    }

    /// @notice gets the picardy automation registrar address
    /// @dev This is external view function and doesnt write to state.
    function getPicardyReg() external view returns(address){
        return regAddress;
    }

    /// @notice checks that the ticker is registered
    function checkTickerExist(string memory _ticker) external view returns(bool){
        return tickerExist[_ticker];
    }

}

interface IPayMaster {
    function getERC20Reserve(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function getETHReserve(address _royaltyAddress) external view returns (uint256);
    function getRoyaltyPaid(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function getPendingRoyalty(address _royaltyAddress, string memory _ticker) external view returns (uint256);
    function addETHReserve(address _royaltyAddress, uint256 _amount) external payable; 
    function addERC20Reserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external ;
    function sendPayment(address _royaltyAddress, string memory _ticker, uint256 _amount) external  returns(bool);
    function checkTickerExist(string memory _ticker) external view returns(bool);
    function getPicardyReg() external view returns(address);
    function addRoyaltyData(address _adapter, address _royaltyAddress, uint royaltyType, string memory ticker) external; 
    function removeRoyaltyData(address _adapter, address _royaltyAddress) external; 
    function getTokenAddress(string memory _ticker) external view returns (address);
    function refundPending(address _royaltyAddress, string memory _ticker, uint256 _amount) external;
    function withdrawReserve(address _royaltyAddress, string memory _ticker, uint256 _amount) external;
    function removeToken(string memory _ticker) external;
    function addRegAddress(address _picardyReg) external;
    function addToken(string memory _ticker, address _tokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
/// @title Royalty Adapter V2
/// @author joshua Obigwe

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPayMaster} from "../AutomationV3/PayMasterV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import {IRoyaltyAutomationRegistrarV3} from "../AutomationV3/RoyaltyAutomationRegV3.sol";

contract RoyaltyAdapterV3 is ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Strings for uint256;

    event RoyaltyData(bytes32 indexed requestId, uint indexed value, uint indexed royaltyAutomationId);
    event UpkeepPerformed(uint indexed time);
    event UpkeepNotNeeded(uint indexed time);

    uint256 private ORACLE_PAYMENT = 1 * LINK_DIVISIBILITY / 10; // 1.0  * 10**18
    uint256 private KEEPERS_FEE = 1 * LINK_DIVISIBILITY / 10; // 1.0  * 10**18
    address payMaster;
    address public picardyReg;
    address public picardyHub;
    address public linkAddress;

    struct AutomationDetails {
       address royaltyAddress;
       address oracle;
       uint royaltyType;
       uint updateInterval;
       string jobId;
       uint royaltyAutomationId;
    }

    mapping(address => bool) public saleExists;
    mapping(address => uint) public linkBalance;
    mapping (address => AutomationDetails) public automationDetails;
    mapping (uint => AutomationDetails) public idToAutomationDetails;
    mapping (address => uint[]) recievedAmounts;
    address[] registeredAddresses;

    uint royaltyAutomationId = 1;
    LinkTokenInterface immutable LINK;
    IRoyaltyAutomationRegistrarV3 i_royaltyReg;
    constructor(address _linkToken, address _payMaster, address _picardyHub) {
        require(IPicardyHub(_picardyHub).checkHubAdmin(msg.sender) == true, "addAdapterDetails: not hubAdmin");
        payMaster = _payMaster;
        picardyHub = _picardyHub;
        setChainlinkToken(_linkToken);
        LINK = LinkTokenInterface(_linkToken);
        linkAddress = _linkToken;
    }

    // call this after the contract is deployed
    /// @notice This function is called by the Picardy Hub Admin to add the picardyReg address
    /// @param _picardyReg The address of the Picardy Royalty Automation Registrar
    function addPicardyReg(address _picardyReg) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "addAdapterDetails: not hubAdmin");
        picardyReg = _picardyReg;
        i_royaltyReg = IRoyaltyAutomationRegistrarV3(_picardyReg);
    }

    /// @notice this function is called on registration of automation
    /// @param royaltySaleAddress The address of the royalty sale contract
    /// @param royaltyType The type of royalty sale contract
    /// @param updateInterval The interval at which the royalty data should be updated
    /// @param oracle The address of the oracle
    /// @param jobId The jobId of the oracle
    /// @param amount The amount of LINK to be sent to the oracle
    /// @dev this function should only be called by the picardy automation Registrar
    function addValidSaleAddress(address royaltySaleAddress, uint royaltyType, uint updateInterval, address oracle, string  calldata jobId, uint amount) external {
        require(msg.sender == picardyReg, "addValidSaleAddress: not picardyReg");
        require(royaltySaleAddress != address(0), "addValidSaleAddress: royalty sale address cannot be address(0)");
        require(royaltyType == 0 || royaltyType == 1, "addValidSaleAddress: royalty type not valid");
        require(oracle != address(0), "addValidSaleAddress: oracle address cannot be address(0)");
        require(bytes(jobId).length > 0, "addValidSaleAddress: jobId cannot be empty");
        AutomationDetails memory _automationDetails = AutomationDetails({
            royaltyAddress: royaltySaleAddress,
            oracle: oracle,
            royaltyType: royaltyType,
            updateInterval: updateInterval,
            jobId: jobId,
            royaltyAutomationId: royaltyAutomationId});
            linkBalance[royaltySaleAddress] = amount;

        automationDetails[royaltySaleAddress] = _automationDetails;
        idToAutomationDetails[royaltyAutomationId] = _automationDetails;
        royaltyAutomationId++;
        registeredAddresses.push(royaltySaleAddress);
        saleExists[royaltySaleAddress] = true;
    }

    function getAddressById(uint _royaltyAutomationId) external view returns (address) {
        return idToAutomationDetails[_royaltyAutomationId].royaltyAddress;
    }

    function getIdByAddress(address _royaltySaleAddress) external view returns (uint) {
        return automationDetails[_royaltySaleAddress].royaltyAutomationId;
    }

    /// @notice this function is called to check the validity of the royalty sale address
    /// @param _royaltySaleAddress The address of the royalty sale contract
    function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool) {
        return saleExists[_royaltySaleAddress];
    }

    /// @notice this function is called by a valid royalty sale contract to request the royalty amount to be sent to the paymaster
    /// @param _royaltySaleAddress The address of the royalty sale contract
    /// @param _oracle The address of the oracle
    /// @param _royaltyType The type of royalty sale
    /// @param _jobId The job id of the oracle
    /// @dev this function should only be called by a registered royalty sale contract
    function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint _royaltyType, string memory _jobId) internal {
        (, uint link) = contractBalances();
        require (link > ORACLE_PAYMENT, "requestRoyaltyAmount: Adapter balance low");
        require (_royaltySaleAddress != address(0), "requestRoyaltyAmount: royalty sale address cannotbe address(0)");
        require (_oracle != address(0), "requestRoyaltyAmount: oracle address cannot be address(0)");
        require (_royaltyType == 0 || _royaltyType == 1, "requestRoyaltyAmount: royalty type not valid");
        require (saleExists[_royaltySaleAddress] == true, "requestRoyaltyAmount: royalty sale registered");
        require (linkBalance[_royaltySaleAddress] >= ORACLE_PAYMENT, "requestRoyaltyAmount: Link balance low");
        if( _royaltyType == 0){
            require(IPicardyNftRoyaltySaleV3(_royaltySaleAddress).checkAutomation() == true, "royalty adapter: automation not enabled");
             linkBalance[_royaltySaleAddress] -= ORACLE_PAYMENT;
            (,,,,string memory _projectTitle,string memory _creatorName) = IPicardyNftRoyaltySaleV3(_royaltySaleAddress).getTokenDetails();

            Chainlink.Request memory req = buildOperatorRequest( stringToBytes32(_jobId), this.fulfillRequestRoyaltyAmount.selector);
            req.add("creatorName", _creatorName);
            req.add("projectTitle", _projectTitle);
            req.add("royaltyAddress", Strings.toHexString(uint256(uint160(_royaltySaleAddress)), 20));
            sendOperatorRequestTo(_oracle, req, ORACLE_PAYMENT);
        }else if(_royaltyType == 1){
            require(IPicardyTokenRoyaltySaleV3(_royaltySaleAddress).checkAutomation() == true, "royalty adapter: automation not enabled");
             linkBalance[_royaltySaleAddress] -= ORACLE_PAYMENT;
            (string memory _projectTitle,string memory _creatorName) = IPicardyTokenRoyaltySaleV3(_royaltySaleAddress).getTokenDetails();
            
            Chainlink.Request memory req = buildOperatorRequest( stringToBytes32(_jobId), this.fulfillRequestRoyaltyAmount.selector);
            req.add("creatorName", _creatorName);
            req.add("projectTitle", _projectTitle);
            req.add("royaltyAddress", Strings.toHexString(uint256(uint160(_royaltySaleAddress)), 20));
            sendOperatorRequestTo(_oracle, req, ORACLE_PAYMENT);
        }  
    }

    ///@notice this function is called by the oracle to fulfill the request and send the royalty amount to the paymaster
    ///@param _requestId The request id from the node.
    ///@param amount The amount of royalty to be sent to the paymaster
    ///@param _royaltyAutomationId the id to the royalty sale contract
    ///@dev this function should only be called by the oracle 
    function fulfillRequestRoyaltyAmount(bytes32 _requestId, uint256 amount, uint  _royaltyAutomationId) public recordChainlinkFulfillment(_requestId) {
        emit RoyaltyData(_requestId, amount, _royaltyAutomationId);

        address _royaltySaleAddress = idToAutomationDetails[_royaltyAutomationId].royaltyAddress;
        string memory ticker = IRoyaltyAutomationRegistrarV3(picardyReg).getRoyaltyTicker(_royaltySaleAddress);
        IPayMaster(payMaster).sendPayment(_royaltySaleAddress, ticker,  amount);  
        uint[] storage recieved = recievedAmounts[_royaltySaleAddress];
        recieved.push(amount);
    }

    function viewRecievedAmounts(address _royaltySaleAddress) external view returns(uint[] memory){
        return recievedAmounts[_royaltySaleAddress];
    }

    /// @notice this function gets the link token balance of the royalty sale contract
    /// @param _royaltySaleAddress The address of the royalty sale contract
    function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns(uint){
        return linkBalance[_royaltySaleAddress];
    } 

    function fundLinkBalance(address _royaltySaleAddress, uint _amount) external {
        LINK.transferFrom(msg.sender, address(this), _amount);
        linkBalance[_royaltySaleAddress] += _amount;
    }

    /// @notice this function is called to get the picardy automation registrar address
    function getPicardyReg() external view returns(address){
        return picardyReg;
    }

    function contractBalances() public view returns (uint256 eth, uint256 link){
        eth = address(this).balance;

        LinkTokenInterface linkContract = LinkTokenInterface(
            chainlinkTokenAddress()
        );
        link = linkContract.balanceOf(address(this));
    }

    function getPayMaster() external view returns(address){
        return payMaster;
    }

    function getChainlinkToken() external view returns (address) {
        return chainlinkTokenAddress();
    }

    ///@notice this function is called to withdraw LINK from the contract and should be called only by the picardy hub admin
    function withdrawLink() external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer Link"
        );
    }

    ///@notice this function is called by the royalty admin to take out link balance from the contract
    ///@param _royaltyAddress The address of the royalty contract
    ///@dev this function should only be called by the royalty admin
    function adminWithdrawLink(address _royaltyAddress) external {
        require (linkBalance[_royaltyAddress] != 0, "adminWithdrawLink: no link balance");
        require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "adminWithdrawLink: Un-Auth");
        require (LINK.balanceOf(address(this)) >= linkBalance[_royaltyAddress], "adminWithdrawLink: contract balance low");
        (bool success) = LINK.transfer(msg.sender, linkBalance[_royaltyAddress]);
        require(success == true, "adminWithdrawLink: transfer failed");
    }

    ///@notice this function is called to withdraw ETH from the contract and should be called only by the picardy hub admin
    function withdrawBalance() external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        require(success == true, "withdrawBalance: transfer failed");
    }

    /// @notice ths function is called to update the oracle payment and should be called only by the picardy hub admin
    function updateOraclePayment(uint256 _newPayment) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        ORACLE_PAYMENT = _newPayment;
    }

    function updateRoyaltyOracle(address _royaltyAddress, address _newOracle) external {
         require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "updateRoyaltyOracle: Un-Auth");
        automationDetails[_royaltyAddress].oracle = _newOracle;
    }

    function updateRoyaltyJobId(address _royaltyAddress, string memory _newJobId) external {
         require (msg.sender == i_royaltyReg.getAdminAddress(_royaltyAddress), "updateRoyaltyJobId: Un-Auth");
        automationDetails[_royaltyAddress].jobId = _newJobId;
    }

    function cancelRequest( bytes32 _requestId, uint256 _payment, bytes4 _callbackFunctionId, uint256 _expiration) public {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender) == true, "royalty adapter: Un-Auth");
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
    }

    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    /// @notice This function is used by chainlink keepers to perform upkeep if checkUpkeep() returns true
    /// @dev this function can be called by anyone. checkUpkeep() parameters again to avoid unautorized call.
    function royaltyUpdate () external {   
        for (uint i = 0; i < registeredAddresses.length;){
            address _royaltyAddress = registeredAddresses[i];
            AutomationDetails memory _automationDetails = automationDetails[_royaltyAddress];
            if(_automationDetails.royaltyType == 0){
                IPicardyNftRoyaltySaleV3 _nftRoyaltySale = IPicardyNftRoyaltySaleV3(_royaltyAddress);
                bool _check = (_nftRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check != true){
                    emit UpkeepNotNeeded(block.timestamp);
                    continue;
                }
                linkBalance[_royaltyAddress] -= KEEPERS_FEE;
                requestRoyaltyAmount(_royaltyAddress, _automationDetails.oracle, _automationDetails.royaltyType, _automationDetails.jobId);
                emit UpkeepPerformed(block.timestamp);
                 
            } else if(_automationDetails.royaltyType == 1){
                IPicardyTokenRoyaltySaleV3 _tokenRoyaltySale = IPicardyTokenRoyaltySaleV3(_royaltyAddress); 
                bool _check = (_tokenRoyaltySale.getLastRoyaltyUpdate() + _automationDetails.updateInterval) >= block.timestamp;
                if (_check != true){
                    emit UpkeepNotNeeded(block.timestamp);
                    continue;
                } 
                linkBalance[_royaltyAddress] -= KEEPERS_FEE;
                requestRoyaltyAmount(_royaltyAddress, _automationDetails.oracle, _automationDetails.royaltyType, _automationDetails.jobId);
                emit UpkeepPerformed(block.timestamp); 
            }
            unchecked { ++i; }
        }      
    }

    receive() external payable {}
}

interface IRoyaltyAdapterV3{
    function requestRoyaltyAmount(address _royaltySaleAddress, address _oracle, uint _royaltyType, string memory _jobId) external;
    function updateRoyalty(uint _amount) external;
    function checkIsValidSaleAddress(address _royaltySaleAddress) external view returns (bool);	
    function getPicardyReg() external view returns(address);
    function getPayMaster() external view returns(address);
    function addValidSaleAddress(address _royaltySaleAddress, uint _royaltyType, uint _updateIntervals, address _oracle, string calldata _jobId, uint amount) external;
    function getRoyaltyLinkBalance(address _royaltySaleAddress) external view returns(uint);
    function adminWithdrawLink(address _royaltyAddress) external;
    function withdrawBalance() external;
    function updateOraclePayment(uint256 _newPayment) external;
}


//0x7E0ffaca8352CbB93c099C08b9aD7B4bE9f790Ec = operatr
//42b90f5bf8b940029fed6330f7036f01 = jobid
//0xdeba4845DdE1E5AAf0eD88053b8Ab5D73A811f7b = oracle

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/// @title Picardy RoyaltyAutomationRegistrarV2
/// @author Joshua Obigwe

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IPicardyNftRoyaltySaleV3} from "../ProductsV3/NftRoyaltySaleV3.sol";
import {IPicardyTokenRoyaltySaleV3} from "../ProductsV3/TokenRoyaltySaleV3.sol";
import {IPayMaster} from "../AutomationV3/PayMasterV3.sol";
import {IRoyaltyAdapterV3} from "./RoyaltyAdapterV3.sol";
import {IPicardyHub} from "../../PicardyHub.sol";

contract RoyaltyAutomationRegistrarV3 {

    /** @dev Picardy RoyaltyAutomationRegistrarV2 
        manages the royalty automation and inherits 
        chainlink KeeperRegistrarInterface.
     */

    event AutomationRegistered(address indexed royaltyAddress);
    event AutomationFunded(address indexed royaltyAddress, uint96 indexed amount);
    event AutomationCancled(address indexed royaltyAddress);
    event AutomationRestarted(address indexed royaltyAddress);
    event AutomationToggled(address indexed royaltyAddress);
    
    /// @notice details for a registered automation
    /// @param royaltyAddress the address of the royalty contract.
    /// @param adapterAddress the address of the royalty adapter contract.
    /// @param adminAddress the address of the admin of the automation. This can also be the address of the royalty owner
    /// @param upkeepId the upkeep id of the automation.
    /// @param royaltyType the type of royalty contract (0 = NFT, 1 = Token).
    /// @dev The struct is initilized in a mapping with the royalty address as the key.
    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint royaltyType;
    }

    /// @notice details for registering a new automation
    /// @param ticker the ticker of that would be used to pay for the upkeep.
    /// @param jobId the job id of the job that would be used on the chainlink node (See Docs for more info).
    /// @param oracle the address of the Picardy oracle address (See Docs for more info).
    /// @param royaltyAddress the address of the royalty contract.
    /// @param adminAddress the address of the admin of the automation. This can also be the address of the royalty owner
    /// @param royaltyType the type of royalty contract (0 = NFT, 1 = Token).
    /// @param updateInterval the interval at which the automation would be updated.
    /// @param amount the amount of LINK to be sent to the upkeep contract.
    /// @dev The amount of link would be split and sent to chainlink for upkeep and picardy royalty adapter for oracle fees.

    ///note time should be in minute
    struct RegistrationDetails {
        string ticker;
        string jobId;
        address oracle;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint96 amount;
    }
    
    address public link;
    address public adapter;
    address public picardyHub;
    address public payMaster;
    uint time = 1 minutes;

    mapping (address => RegisteredDetails) public registeredDetails;
    mapping (address => bool) hasReg;

    IPayMaster i_payMaster;
    LinkTokenInterface i_link;

    constructor(
        address _link, //get from chainlink docs
        address _adapter,
        address _picardyHub,
        address _payMaster
    ) {
        picardyHub = _picardyHub;
        link = _link;
        payMaster = _payMaster;
        adapter = _adapter;
        i_payMaster = IPayMaster(_payMaster);
        i_link = LinkTokenInterface(_link);
        
    }

    /// @notice adds a new royalty adapter
    /// @param _adapterAddress address of the new royalty adapter
    /// @dev only callable by the PicardyHub admin
    function addRoyaltyAdapter(address _adapterAddress) external {
        require(_adapterAddress != address(0), "invalid adapter address");
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "Only PicardyHub can add royalty adapter");
        adapter = _adapterAddress;
    }

    /// @notice registers a new royalty contract for automation
    /// @param details struct containing all the details for the registration
    /// @dev only callable by the royalty contract owner see (RegistrationDetails struct above for more info).
    function register(RegistrationDetails memory details) external {
        require (details.updateInterval >= 1, "update interval too low");
        require (details.royaltyAddress != address(0), "invalid royalty address");
        require (details.adminAddress != address(0), "invalid admin address");
        require (details.oracle != address(0), "invalid oracle address");
        require(hasReg[details.royaltyAddress] == false, "already registered");
        require(i_link.balanceOf(msg.sender) >= details.amount, "Insufficient LINK for automation registration");
        require(i_payMaster.checkTickerExist(details.ticker), "Ticker not accepted");
        require (details.royaltyType == 0 || details.royaltyType == 1, "invalid Royalty type");
        uint interval = details.updateInterval * time;

        if (details.royaltyType == 0){   
            IPicardyNftRoyaltySaleV3 royalty = IPicardyNftRoyaltySaleV3(details.royaltyAddress);
            require(msg.sender == royalty.getOwner(), "Only owner can register automation");   
            royalty.setupAutomationV2(interval, adapter, details.oracle, details.jobId);
            i_link.transferFrom(msg.sender, adapter, details.amount);
            IRoyaltyAdapterV3(adapter).addValidSaleAddress(details.royaltyAddress, details.royaltyType, interval, details.oracle, details.jobId, details.amount);
            i_payMaster.addRoyaltyData(
                adapter, 
                details.royaltyAddress, 
                details.royaltyType,
                details.ticker
            );
        }
        else if (details.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3 royalty = IPicardyTokenRoyaltySaleV3(details.royaltyAddress);
            require(msg.sender == royalty.getOwner(), "Only owner can register automation");
            royalty.setupAutomationV2(interval, adapter, details.oracle, details.jobId);
            IRoyaltyAdapterV3(adapter).addValidSaleAddress(details.royaltyAddress, details.royaltyType, interval, details.oracle, details.jobId, details.amount);
            i_payMaster.addRoyaltyData(
                adapter, 
                details.royaltyAddress, 
                details.royaltyType,
                details.ticker
            );
        }
        RegisteredDetails memory i_registeredDetails = RegisteredDetails( details.royaltyAddress, adapter, details.adminAddress, details.royaltyType);
        registeredDetails[details.royaltyAddress] = i_registeredDetails;
        hasReg[details.royaltyAddress] = true;
        emit AutomationRegistered(details.royaltyAddress);   
    }

    /// @notice pauses automation can also be on the royalty contract
    /// @param _royaltyAddress address of the royalty contract
    function toggleAutomation(address _royaltyAddress) external {
        require(_royaltyAddress != address(0), "invalid royalty address");
        require(hasReg[_royaltyAddress] == true, "not registered");
        RegisteredDetails memory i_registeredDetails = registeredDetails[_royaltyAddress];
       
        require(i_registeredDetails.adminAddress == msg.sender, "not admin");
        
        if (i_registeredDetails.royaltyType == 0){
            IPicardyNftRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        else if (i_registeredDetails.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        
        emit AutomationToggled(_royaltyAddress);
    }

    /// @notice cancels automation
    /// @param _royaltyAddress address of the royalty contract
    function cancelAutomation(address _royaltyAddress) external {
        require(_royaltyAddress != address(0), "invalid royalty address");
        require(hasReg[_royaltyAddress] == true, "not registered");
        RegisteredDetails memory i_registeredDetails = registeredDetails[_royaltyAddress];
       
        require(i_registeredDetails.adminAddress == msg.sender, "not admin");
        if (i_registeredDetails.royaltyType == 0){
            IPicardyNftRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        else if (i_registeredDetails.royaltyType == 1){
            IPicardyTokenRoyaltySaleV3(_royaltyAddress).toggleAutomation();
        }
        i_payMaster.removeRoyaltyData(i_registeredDetails.adapterAddress, _royaltyAddress);
        hasReg[_royaltyAddress] = false;
        delete registeredDetails[_royaltyAddress];
        emit AutomationCancled(_royaltyAddress);
    }

    /// @notice updates automation configurations(link)
    /// @param _link address of the link token
    /// @dev can only be called by hub admin
    function updateAutomationConfig(address _link) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "not hub admin");
        require(_link != address(0), "link address cannot be address 0");
        //Initilize interface
        i_link = LinkTokenInterface(_link);
        //Initilize addresses
        link = _link;
       
    }

    /// @notice updates the paymaster address
    /// @param _payMaster address of the paymaster
    function updatePayMaster(address _payMaster) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(msg.sender), "not hub admin");
        require(_payMaster != address(0), "payMaster address cannot be address 0");
        i_payMaster = IPayMaster(_payMaster);
        payMaster = _payMaster;
    }

    /// @notice gets royalty admin address
    function getAdminAddress(address _royaltyAddress) external view returns(address){
        return registeredDetails[_royaltyAddress].adminAddress;
    }

    /// @notice gets royalty adapter address
    function getRoyaltyAdapterAddress( address _royaltyAddress) external view returns(address){
        return registeredDetails[_royaltyAddress].adapterAddress;
    }

    /// @notice returns an struct of the registered details
    function getRegisteredDetails(address _royaltyAddress) external view returns(RegisteredDetails memory) {
        return registeredDetails[_royaltyAddress];
    }
}

interface IRoyaltyAutomationRegistrarV3 {
    struct RegistrationDetails {
        string ticker;
        string jobId;
        address oracle;
        address royaltyAddress;
        address adminAddress;
        uint royaltyType;
        uint updateInterval;
        uint96 amount;
    }

    struct RegisteredDetails {
        address royaltyAddress;
        address adapterAddress;
        address adminAddress;
        uint upkeepId;
        uint royaltyType;
        string ticker;
    }
    
    function register(RegistrationDetails memory details) external;

    function fundUpkeep(address royaltyAddress, uint96 amount) external;

    function toggleAutomation(address royaltyAddress) external;

    function addRoyaltyAdapter(address _adapterAddress) external;

    function fundAdapterBalance(uint96 _amount, address _royaltyAddress) external ;

    function cancleAutomation(address _royaltyAddress) external;

    function updateAutomationConfig(address _link) external;

    function updatePayMaster(address _payMaster) external;

    function getRoyaltyAdapterAddress( address _royaltyAddress) external view returns(address);

    function getAdminAddress(address _royaltyAddress) external view returns(address);

    function getRoyaltyTicker(address _royaltyAddress) external view returns(string memory);

    function getRegisteredDetails(address _royaltyAddress) external view returns(RegisteredDetails memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title: NftRoyaltySaleFactoryV2
/// @author: Joshua Obigwe

import "../ProductsV3/NftRoyaltySaleV3.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftRoyaltySaleFactoryV3 is Context , ReentrancyGuard {

    address nftRoyaltySaleImplementation;

    event NftRoyaltySaleCreated (uint indexed royaltySaleId, address indexed creator, address indexed royaltySaleAddress);
    event RoyaltyDetailsUpdated(uint percentage, address royaltyAddress);
    
    /// @notice: Details for creating the NftRoyaltySale contract
    /// @param maxSupply: Maximum number of tokens that can be minted
    /// @param maxMintAmount: Maximum number of NFTs that can be minted in a single transaction
    /// @param cost: Cost of each token
    /// @param percentage: Percentage of split to be paid back to holders
    /// @param name: Name of the project / token
    /// @param symbol: Symbol of the project / token
    /// @param initBaseURI: Base URI for the token
    /// @param creatorName: Name of the creator
    /// @param creator: Address of the creator

    struct Details {
        uint maxSupply; 
        uint maxMintAmount; 
        uint cost; 
        uint percentage;
        string name;
        string symbol; 
        string initBaseURI;
        string creatorName;
        address creator;
    }

    /// @notice: Details of the NftRoyaltySale contract
    /// @param royaltyId: Id of the royalty
    /// @param royaltyPercentage: Percentage of split to be paid back to holders
    /// @param royaltyName: Name of the Project / Token
    /// @param royaltyAddress: Address of the royalty

    struct NftRoyaltyDetails {
        uint royaltyId;
        uint royaltyPercentage;
        string royaltyName;
        address royaltyAddress;
    }

    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(address => NftRoyaltyDetails) public nftRoyaltyDetails;
    mapping(string => mapping (string => address)) public royaltySaleAddress;

    address picardyHub;
    uint nftRoyaltyId = 1;
    address linkToken;
    constructor(address _picardyHub, address _linkToken, address _nftRoyaltySaleImpl) {
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        nftRoyaltySaleImplementation = _nftRoyaltySaleImpl;
    }

    /// @notice Creates a new NftRoyaltySale contract
    /// @param details: Details of the NftRoyaltySale contract. (see struct Details for more info)
    /// @return  Address of the newly created NftRoyaltySale contract
    /// @dev  The NftRoyaltySale contract is created using the Clones library
    function createNftRoyalty(Details memory details) external nonReentrant returns(address){
        require(details.percentage <= 50, "Royalty percentage cannot be more than 50%");
        uint newRId = nftRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newRId, block.number, block.timestamp));
        address payable nftRoyalty = payable(Clones.cloneDeterministic(nftRoyaltySaleImplementation, salt));
        NftRoyaltyDetails memory newNftRoyaltyDetails = NftRoyaltyDetails(newRId, details.percentage, details.name, nftRoyalty);
        royaltySaleAddress[details.creatorName][details.name] = nftRoyalty;
        nftRoyaltyDetails[nftRoyalty] = newNftRoyaltyDetails;
        nftRoyaltyId++;
        NftRoyaltySaleV3(nftRoyalty).initialize(
            details.maxSupply, 
            details.maxMintAmount, 
            details.cost,  
            details.percentage , 
            details.name, 
            details.symbol, 
            details.initBaseURI, 
            details.creatorName, 
            details.creator, 
            address(this));
        emit NftRoyaltySaleCreated(newRId,_msgSender(), nftRoyalty);
        return nftRoyalty;
    }

    /// @notice Updates the royalty details
    /// @param _royaltyPercentage: percentage of transaction fee to be paid to the Picardy royalty address
    /// @dev Only the Picardy Hub Admin can call this function. Do not confuse this with the royalty percentage for the NftRoyaltySale contract 
    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()), "Not Hub Admin");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    function getLinkToken() external view returns(address){
        return linkToken;
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getNftRoyaltySaleAddress(string memory _creatorName, string memory _name) external view returns (address){
        return royaltySaleAddress[_creatorName][_name];
    }
}

interface INftRoyaltySaleFactoryV3 {

    struct Details {
        uint maxSupply; 
        uint maxMintAmount; 
        uint cost; 
        uint percentage;
        string name;
        string symbol; 
        string initBaseURI;
        string creatorName;
        address creator;
    }

    function createNftRoyalty(Details memory details) external returns(address);
    
    function getRoyaltyDetails() external view returns (address, uint);
    
    function updateRoyaltyDetails(uint _royaltyPercentage) external ;
    
    function getLinkToken() external view returns(address);    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title TokenRoyaltySaleFactoryV2
/// @author Joshua Obigwe 

import "../ProductsV3/TokenRoyaltySaleV3.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import {IPicardyHub} from "../../PicardyHub.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

 
contract TokenRoyaltySaleFactoryV3 is Context, ReentrancyGuard {

    address tokenRoyaltySaleImplementation;
    
    event TokenRoyaltyCreated (address indexed creator, address indexed tokenRoyaltyAddress, uint indexed royaltyId);
    event RoyaltyDetailsUpdated(uint indexed percentage, address indexed royaltyAddress);

    struct TokenRoyaltyDetails{ 
        uint tokenRoyaltyId;
        uint askAmount;
        uint returnPercentage;
        address tokenRoyaltyAddress;
    }

    /// @notice struct holds royalty details for the hub
    struct RoyaltyDetails{
        uint royaltyPercentage;
        address royaltyAddress;
    }
    RoyaltyDetails royaltyDetails;

    mapping(address => TokenRoyaltyDetails) public tokenRoyaltyDetailsMap;
    mapping(string => mapping (string => address)) royaltySaleAddress;
    address picardyHub;
    address linkToken;
    uint tokenRoyaltyId = 1;
   constructor (address _picardyHub, address _linkToken, address _tokenRoyaltySaleImpl){
        picardyHub = _picardyHub;
        linkToken = _linkToken;
        tokenRoyaltySaleImplementation = _tokenRoyaltySaleImpl;
    }

    ///@param _askAmount The total askinng amount for royalty
    ///@param _returnPercentage Percentage of royalty to sell
    ///@dev Creats A ERC20 token royalty sale. contract is created using the Clones library
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name, address creator, string calldata symbol) external nonReentrant returns(address){
        uint newTokenRoyaltyId = tokenRoyaltyId;
        bytes32 salt = keccak256(abi.encodePacked(newTokenRoyaltyId, block.number, block.timestamp));
        address payable tokenRoyalty = payable(Clones.cloneDeterministic(tokenRoyaltySaleImplementation, salt));
        TokenRoyaltyDetails memory n_tokenRoyaltyDetails = TokenRoyaltyDetails(newTokenRoyaltyId, _askAmount, _returnPercentage, address(tokenRoyalty));
        royaltySaleAddress[creatorName][name] = tokenRoyalty;
        tokenRoyaltyDetailsMap[tokenRoyalty] = n_tokenRoyaltyDetails;
        tokenRoyaltyId++;
        TokenRoyaltySaleV3(tokenRoyalty).initialize(_askAmount, _returnPercentage, address(this), creator, creatorName, name, symbol);
        emit TokenRoyaltyCreated(_msgSender(), tokenRoyalty, newTokenRoyaltyId);
        return tokenRoyalty;
    }

    /// @notice the function is used to update the royalty percentage.
    /// @param _royaltyPercentage the amount in percentage the hub takes.
    /// @dev only hub admin can call this function 
    function updateRoyaltyDetails(uint _royaltyPercentage) external {
        require(IPicardyHub(picardyHub).checkHubAdmin(_msgSender()) , "Not Hub Admin");
        require(_royaltyPercentage <= 50, "Royalty percentage cannot be more than 50%");
        address royaltyAddress = IPicardyHub(picardyHub).getRoyaltyAddress();
        RoyaltyDetails memory newRoyaltyDetails = RoyaltyDetails(_royaltyPercentage, royaltyAddress);
        royaltyDetails = newRoyaltyDetails;
        emit RoyaltyDetailsUpdated(_royaltyPercentage, royaltyAddress);
    }

    function getRoyaltyDetails() external view returns (address, uint){
        address royaltyAddress = royaltyDetails.royaltyAddress;
        uint royaltyPercentage = royaltyDetails.royaltyPercentage;
        return(royaltyAddress, royaltyPercentage);
    }

    function getTokenRoyaltyAddress(string memory creatorName, string memory name) external view returns(address){
        return royaltySaleAddress[creatorName][name];
    }

    function getRoyaltySaleDetails(address _royaltySaleAddress) external view returns (TokenRoyaltyDetails memory) {
        return tokenRoyaltyDetailsMap[_royaltySaleAddress];
    }

    function getHubAddress() external view returns (address){
        return picardyHub;
    }

    function getLinkToken() external view returns(address){
        return linkToken;
    }
}

interface ITokenRoyaltySaleFactoryV3{
    function createTokenRoyalty(uint _askAmount, uint _returnPercentage, string memory creatorName, string memory name) external returns(address);
    function getRoyaltyDetails() external view returns (address, uint);
    function getHubAddress() external view returns (address);
    function getLinkToken() external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

/// @title NftRoyaltySaleV2
/// @author Joshua Obigwe

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../../Tokens/PicardyNftBase.sol";
import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {INftRoyaltySaleFactoryV3} from "../FactoryV3/NftRoyaltySaleFactoryV3.sol";

contract NftRoyaltySaleV3 is ReentrancyGuard, Pausable {

    event UpkeepPerformed(uint indexed time);
    event Received(address indexed sender, uint indexed amount);
    event AutomationStarted(bool indexed status);
    event RoyaltySold(uint indexed mintAmount, address indexed buyer);
    event RoyaltyUpdated(uint indexed royalty);
    event WithdrawSuccess(uint indexed time);
    event RoyaltyWithdrawn(uint indexed amount, address indexed holder);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    enum NftRoyaltyState {
        OPEN,
        CLOSED
    }

    NftRoyaltyState nftRoyaltyState;

    /// @notice Royalty struct
    /// @param maxMintAmount max amount of tokens that can be minted by an address
    /// @param maxSupply max amount of tokens that can be minted
    /// @param cost cost of each token
    /// @param percentage percentage of split to be paid back to holders
    /// @param creatorName name of the creator
    /// @param name name of the project / token
    /// @param initBaseURI base URI for the token
    /// @param symbol symbol of the project / token
    /// @param creator address of the creator
    /// @param factoryAddress address of the factory

    struct Royalty {
        uint maxMintAmount;
        uint maxSupply;
        uint cost;
        uint percentage;
        string creatorName;
        string name;
        string initBaseURI;
        string symbol;
        address creator;
        address factoryAddress;
    }

    Royalty royalty;

    struct NodeDetails {
        address oracle;
        string jobId;
    }
    NodeDetails nodeDetails;

    
    address owner;
    address public nftRoyaltyAddress;
    address private royaltyAdapter;
    address private picardyReg;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initialized;
    bool ownerWithdrawn;
    bool hasEnded;
    bool started;
    uint royaltyType = 0;

    mapping (address => uint) nftBalance;
    mapping (address => uint) public royaltyBalance;

    //holder => tokenAddress => royaltyAmount
    mapping (address => mapping(address => uint)) public ercRoyaltyBalance;
    mapping (address => uint[]) tokenIdMap;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
    
    function initialize(uint _maxSupply, 
        uint _maxMintAmount, 
        uint _cost, 
        uint _percentage, 
        string memory _name,
        string memory _symbol, 
        string memory _initBaseURI, 
        string memory _creatorName,
        address _creator,
        address _factroyAddress) public {
            require(!initialized, "already initialized");
            Royalty memory newRoyalty = Royalty(_maxMintAmount, _maxSupply, _cost, _percentage, _creatorName, _name, _initBaseURI, _symbol, _creator, _factroyAddress);
            royalty = newRoyalty;
            owner = _creator;
            nftRoyaltyState = NftRoyaltyState.CLOSED;
            initialized = true;
    }

    /// @notice this function is called by the contract owner to start the royalty sale
    /// @dev this function can only be called once and it cretes the NFT contract
    function start() external onlyOwner {
        require(started == false, "start: already started");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED);
        _picardyNft();
        nftRoyaltyState = NftRoyaltyState.OPEN;
        started = true;
    }

    
    /// @notice this function is called by Picardy Royalty Registrar when registering automation and sets up the automation
    /// @param _updateInterval update interval for the automation
    /// @param _royaltyAdapter address of Picardy Royalty Adapter
    /// @param _oracle address of the oracle
    /// @param _jobId job id for the oracle 
    /// @dev //This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work
    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external {
        require(msg.sender == IRoyaltyAdapterV3(_royaltyAdapter).getPicardyReg() , "setupAutomation: only picardy reg");
        require(automationStarted == false, "startAutomation: automation started");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        nodeDetails.oracle = _oracle;
        nodeDetails.jobId = _jobId;
        updateInterval = _updateInterval;
        royaltyAdapter = _royaltyAdapter;
        lastRoyaltyUpdate = block.timestamp;
        automationStarted = true;
        emit AutomationStarted(true);
    }

    /// @notice this function is called by the contract owner to pause automation
    /// @dev this function can only be called by the contract owner and picardy royalty registrar
    function toggleAutomation() external {
        require(msg.sender == IRoyaltyAdapterV3(royaltyAdapter).getPicardyReg() ||msg.sender == owner, "toggleAutomation: Un Auth");
        automationStarted = !automationStarted;
        emit AutomationStarted(false);
    }

    /// @notice This function can be called by anyone and is a payable function to buy royalty token in ETH
    /// @param _mintAmount amount of royalty token to be minted
    /// @param _holder address of the royalty token holder
    function buyRoyalty(uint _mintAmount, address _holder) external payable whenNotPaused nonReentrant{
        require(!hasEnded, "already ended");
        uint cost = royalty.cost;
        require(nftRoyaltyState == NftRoyaltyState.OPEN);
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        nftBalance[_holder] += _mintAmount;
        PicardyNftBase(nftRoyaltyAddress).buyRoyalty(_mintAmount, _holder);
        if(msg.value > cost * _mintAmount) {
        (bool os, ) = payable(msg.sender).call{value: msg.value - cost * _mintAmount}("");
        }

        if (royalty.maxSupply == PicardyNftBase(nftRoyaltyAddress).totalSupply()) {
            hasEnded = true;
            nftRoyaltyState = NftRoyaltyState.CLOSED;
        }
        emit RoyaltySold(_mintAmount, _holder); 
    }

    
    /// @dev This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
    /// @param _amount amount of ERC20 tokens to be paid back to royalty holders
    /// @param tokenAddress address of the ERC20 token
    /// @dev this function can only be called by the contract owner or payMaster contract
    function updateRoyalty(uint256 _amount, address tokenAddress) external {
        require(hasEnded, "already ended");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        require (msg.sender == getUpdateRoyaltyCaller(), "updateRoyalty: Un-auth");
        uint saleCount = PicardyNftBase(nftRoyaltyAddress).getSaleCount();
        uint valuePerNft = _amount / saleCount;
        address[] memory holders = PicardyNftBase(nftRoyaltyAddress).getHolders();
        for(uint i; i < holders.length; i++){
            uint balance = valuePerNft * nftBalance[holders[i]];
            ercRoyaltyBalance[holders[i]][tokenAddress] += balance;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyUpdated(_amount);
    }

    /// @notice helper function that makes sure the caller is the owner or payMaster contract
    function getUpdateRoyaltyCaller() internal view returns (address) {
        if (automationStarted == true){
            return IRoyaltyAdapterV3(royaltyAdapter).getPayMaster();
        } else {
            return owner;
        }   
    }

    /// @notice This function changes the state of the royalty sale and should only be called by the owner
    function toggleRoyaltySale() external onlyOwner {
        require(hasEnded == false, "already ended");
        if(nftRoyaltyState == NftRoyaltyState.OPEN){
            nftRoyaltyState = NftRoyaltyState.CLOSED;
        }else{
            nftRoyaltyState = NftRoyaltyState.OPEN;
        }
    }

    /// @notice This function changes the state of the royalty sale to closed and should only be called by the owner, and can only be called once
    function endRoyaltySale() external onlyOwner {
        require(hasEnded == false, "endRoyaltySale: already ended");
        nftRoyaltyState = NftRoyaltyState.CLOSED;
        hasEnded = true;
    }

    /// @notice his function is used to pause the ERC721 token base contract
    /// @dev this function can only be called by the contract owner
    function pauseTokenBase() external onlyOwner{
        PicardyNftBase(nftRoyaltyAddress).pause();
    }

    /// @notice his function is used to unPause the ERC721 token base contract
    /// @dev this function can only be called by the contract owner
    function unPauseTokenBase() external onlyOwner {
        PicardyNftBase(nftRoyaltyAddress).unpause();
    }

    function getTimeLeft() external view returns (uint256) {
        uint timePassed = block.timestamp - lastRoyaltyUpdate;
        uint nextUpdate = lastRoyaltyUpdate + updateInterval;
        uint timeLeft = nextUpdate - timePassed;
        return timeLeft;
    }

    function checkNftRoyaltyState() external view returns(bool){
        if(nftRoyaltyState == NftRoyaltyState.OPEN){
            return true;
        }else{
            return false;
        }
    }

    /// @notice This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner
    function withdraw() external onlyOwner { 
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(hasEnded == true, "not Ended");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        (address royaltyAddress, uint royaltyPercentage) = INftRoyaltySaleFactoryV3(royalty.factoryAddress).getRoyaltyDetails();
         uint balance = address(this).balance;
         uint royaltyPercentageTobips = royaltyPercentage * 100;
         uint txFee = (balance * royaltyPercentageTobips) / 10000;
         uint toWithdraw = balance - txFee;
         ownerWithdrawn = true;
        (bool os, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool hs, ) = payable(msg.sender).call{value: toWithdraw}("");
        require(hs);
        require(os);
        emit WithdrawSuccess(block.timestamp);
    }

    /// @notice This function is used to withdraw the royalty. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(hasEnded == true, "not ended");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "Insufficient funds");
        require(royaltyBalance[_holder] >= _amount, "Insufficient balance");
        royaltyBalance[_holder] -= _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }

    /// @notice This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external nonReentrant {
        require(hasEnded == true, "not ended");
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open"); 
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(ercRoyaltyBalance[_holder][_tokenAddress] >= _amount, "Insufficient royalty balance");
        ercRoyaltyBalance[_holder][_tokenAddress] -= _amount;
        (bool os) = IERC20(_tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);
    }

    /// @notice This function is used to pause the royalty sale contract and should only be called by the owner
    function pause() public onlyOwner {
        _pause();
    }

    /// @notice This function is used to unpause the royalty sale contract and should only be called by the owner
    function unpause() public onlyOwner {
        _unpause();
    }

    /// @notice this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    /// @notice This function is used to change the oracle address and jobId of the chainlink node for custom job id
    /// @param _oracle new oracle address
    /// @param _jobId new jobId
    /// @dev this function can only be called by the contract owner. (See docs for custom automation)
    function updateNodeDetails(address _oracle, string calldata _jobId) external onlyOwner{
        nodeDetails.oracle = _oracle;
        nodeDetails.jobId = _jobId;
    }

    //Getter FUNCTIONS//

    function getTokensId(address _addr) external returns (uint[] memory){
        uint[] memory tokenIds = _getTokenIds(_addr);
        
        return tokenIds;
    }

    function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns(uint){
        return ercRoyaltyBalance[_holder][_tokenAddress];
    }

    function getTokenDetails() external view returns(uint, uint, uint, string memory, string memory, string memory){  
        uint price = royalty.cost;
        uint maxSupply= royalty.maxSupply;
        uint percentage=royalty.percentage;
        string memory symbol =royalty.symbol;
        string memory name = royalty.name;
        string memory creatorName = royalty.creatorName;

        return (price, maxSupply, percentage, symbol, name, creatorName);
    }

    function getCreator() external view returns(address){
        return royalty.creator;
    }

    function getRoyaltyTokenAddress() external view returns(address){
        return nftRoyaltyAddress;
    }

    function getOwner() external view returns(address){
        return owner;
    }

   function getRoyaltyPercentage() external view returns(uint){
        return royalty.percentage;
    }

    function getLastRoyaltyUpdate() external view returns(uint){
        return lastRoyaltyUpdate;
    }

    // INTERNAL FUNCTIONS//

 
    function _getTokenIds(address addr) internal returns(uint[] memory){
        uint[] storage tokenIds = tokenIdMap[addr];
        uint balance = IERC721Enumerable(nftRoyaltyAddress).balanceOf(addr);
        for (uint i; i< balance; i++){
            uint tokenId = IERC721Enumerable(nftRoyaltyAddress).tokenOfOwnerByIndex(msg.sender, i);
            tokenIds.push(tokenId);
        }
        return tokenIds;
    }

    function checkAutomation() external view returns(bool){
        return automationStarted;
    }

     function _picardyNft() internal {
        PicardyNftBase  newPicardyNft = new PicardyNftBase (royalty.maxSupply, royalty.maxMintAmount, royalty.percentage, royalty.name, royalty.symbol, royalty.initBaseURI, royalty.creatorName, address(this), royalty.creator);
        nftRoyaltyAddress = address(newPicardyNft);
    }

    function _update(uint _amount) internal {
        require(nftRoyaltyState == NftRoyaltyState.CLOSED, "royalty sale still open");
        uint saleCount = PicardyNftBase(nftRoyaltyAddress).getSaleCount();
        uint valuePerNft = _amount / saleCount;
        address[] memory holders = PicardyNftBase(nftRoyaltyAddress).getHolders();
        for(uint i; i < holders.length; i++){
            uint balance = valuePerNft * nftBalance[holders[i]];
            royaltyBalance[holders[i]] += balance;
        }

        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyUpdated(_amount);
    }

    receive() external payable {
        _update(msg.value);
    }

}

interface IPicardyNftRoyaltySaleV3 {

    /// starts royalty sale
    function start() external;
    
    /// @dev gets token ids of a specific address
    function getTokenIds(address _addr) external returns(uint[] memory);

    /// @dev gets token details of the caller
    function getTokenDetails() external returns(uint, uint, uint, string memory, string memory, string memory);

    function getCreator() external returns(address);
   
   /// @dev withdraws royalty balance of the caller
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external;

    function getRoyaltyTokenAddress() external view returns(address);

    /// @dev updates royalty balance of token holders
    function updateRoyalty(uint256 _amount, address tokenAddress) external ;

    function getTokensId(address _addr) external returns (uint[] memory);
    /// @dev buys royalty tokens
    function buyRoyalty(uint _mintAmount, address _holder) external payable;

    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external;

    function toggleAutomation() external;

    function toggleRoyaltySale() external;

    function changeUpdateInterval(uint _updateInterval) external;

    function checkRoyaltyState() external view returns(bool);

    function getLastRoyaltyUpdate() external view returns(uint);

    function getERC20RoyaltyBalance(address _holder, address _tokenAddress) external view returns(uint);

    function getRoyaltyPercentage() external view returns(uint);

    function checkAutomation() external view returns (bool);

    function updateNodeDetails(address _oracle, string calldata _jobId) external;

    function getOwner() external view returns(address);
    /// @dev pause the royalty sale contract
    function pause() external ;
    
    /// @dev unpauses the royalty sale contract
    function unpause() external ;
    
    /// @dev withdraws all eth sent to the royalty sale contract
    function withdraw() external ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../Tokens/CPTokenV3.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {IRoyaltyAdapterV3} from "../AutomationV3/RoyaltyAdapterV3.sol";
import {ITokenRoyaltySaleFactoryV3} from "../FactoryV3/TokenRoyaltySaleFactoryV3.sol";

contract TokenRoyaltySaleV3 is ReentrancyGuard, Pausable {

    event RoyaltyBalanceUpdated(uint indexed time, uint indexed amount);
    event Received(address indexed depositor, uint indexed amount);
    event UpkeepPerformed(uint indexed time);
    event AutomationStarted(bool indexed status);
    event RoyaltyWithdrawn(uint indexed amount, address indexed holder);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    enum TokenRoyaltyState{
        OPEN,
        CLOSED
    }

    TokenRoyaltyState tokenRoyaltyState;

    struct Royalty {
    uint royaltyPoolSize;
    uint percentage;
    uint royaltyPoolBalance;
    address royaltyCPToken;
    address tokenRoyaltyFactory;
    address creator;
    address[] royaltyPoolMembers;
    string creatorsName;
    string name;
    string symbol;
    }
    Royalty royalty;
  
    struct NodeDetails {
        address oracle;
        string jobId;
    }
    NodeDetails nodeDetails;

    address public owner;
    address private royaltyAdapter;
    uint256 lastRoyaltyUpdate;
    uint256 updateInterval;
    bool automationStarted;
    bool initilized;
    bool started;
    bool ownerWithdrawn;
    bool hasEnded;
    uint royaltyType = 1;

  
    mapping (address => uint) royaltyBalance;

    //holder => tokenAddress => royaltyBalance
    mapping (address => mapping(address => uint)) public ercRoyaltyBalance;
    mapping (address => bool) isPoolMember;
    mapping (address => uint) memberSize;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function initialize(uint _royaltyPoolSize, uint _percentage, address _tokenRoyaltyFactory, address _creator, string memory _creatorsName, string memory _name, string calldata symbol) external {
        require(!initilized, "token Royalty: already initilized ");
        royalty.royaltyPoolSize = _royaltyPoolSize;
        royalty.percentage = _percentage;
        royalty.tokenRoyaltyFactory = _tokenRoyaltyFactory;
        royalty.creator = _creator;
        royalty.creatorsName = _creatorsName;
        royalty.name = _name;
        royalty.symbol = symbol;
        owner = _creator;
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        initilized = true;
    }

    function start() external onlyOwner {
        require(!started, "already started");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED);
        _start();
        started = true;
    }
    
    /// @notice this function is called by Picardy Royalty Registrar when registering automation and sets up the automation
    /// @param _updateInterval update interval for the automation
    /// @param _royaltyAdapter address of Picardy Royalty Adapter
    /// @param _oracle address of the oracle
    /// @param _jobId job id for the oracle
    /// @dev This function is called by picardy royalty registrar, PS: royalty adapter contract needs LINK for automation to work
    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external { 
        require(msg.sender == IRoyaltyAdapterV3(_royaltyAdapter).getPicardyReg(), "setupAutomation: only picardy reg");
        require (automationStarted == false, "startAutomation: automation started");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty still open");
        nodeDetails.oracle = _oracle;
        nodeDetails.jobId = _jobId;
        updateInterval = _updateInterval;
        royaltyAdapter = _royaltyAdapter;
        lastRoyaltyUpdate = block.timestamp;
        automationStarted = true;
        emit AutomationStarted(true);
    }

    /// @notice this function is called by the contract owner to pause automation
    /// @dev this function can only be called by the contract owner and picardy royalty registrar
    function toggleAutomation() external {
        require(msg.sender == IRoyaltyAdapterV3(royaltyAdapter).getPicardyReg() || msg.sender == owner, "toggleAutomation: Un Auth");
        automationStarted = !automationStarted;
        emit AutomationStarted(false);
    }
   
    /// @notice This function can be called by anyone and is a payable function to buy royalty token in ETH
    /// @param _holder address of the royalty token holder
    function buyRoyalty(address _holder) external payable whenNotPaused nonReentrant {
        require(hasEnded == false, "Sale Ended");
        require(tokenRoyaltyState == TokenRoyaltyState.OPEN, "Sale closed");
        require(msg.value <=  royalty.royaltyPoolSize);
        royalty.royaltyPoolBalance += msg.value;
        _buyRoyalty(msg.value, _holder);
    }
    function _buyRoyalty(uint _amount, address _holder) internal {
        if (isPoolMember[_holder] == false){
            royalty.royaltyPoolMembers.push(_holder);
            isPoolMember[_holder] = true;
        }
        (bool os) = IERC20(royalty.royaltyCPToken).transfer( _holder, _amount);
        require(os, "transfer failed");
        if(royalty.royaltyPoolSize == royalty.royaltyPoolBalance){
            tokenRoyaltyState = TokenRoyaltyState.CLOSED;
            hasEnded = true;
        }
    }

    /// @dev This function can only be called by the royaltySale owner or payMaster contract to pay royalty in ERC20.    
    /// @param amount amount of ERC20 tokens to be paid back to royalty holders
    /// @param tokenAddress address of the ERC20 token
    /// @dev this function can only be called by the contract owner or payMaster contract
    function updateRoyalty(uint amount, address tokenAddress) external {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require (msg.sender == getUpdateRoyaltyCaller(), "updateRoyalty: Un-auth");
        address[] memory holders = CPTokenV3(royalty.royaltyCPToken).getHolders();
        for(uint i = 0; i < holders.length; i++){
            address poolMember = holders[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 10000;
            ercRoyaltyBalance[poolMember][tokenAddress] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;
        emit RoyaltyBalanceUpdated(block.timestamp, amount);
    }

    function getUpdateRoyaltyCaller() private view returns (address) {
        if (automationStarted == true){
            return IRoyaltyAdapterV3(royaltyAdapter).getPayMaster();
        } else {
            return owner;
        }   
    }

    /// @notice This function is used to withdraw the funds from the royalty sale contract and should only be called by the owner
    function withdraw() external onlyOwner {
        require(hasEnded == true, "sale not ended");
        require(ownerWithdrawn == false, "funds already withdrawn");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(royalty.royaltyPoolBalance > 0, "Pool balance empty");
        (address royaltyAddress, uint royaltyPercentage) = ITokenRoyaltySaleFactoryV3(royalty.tokenRoyaltyFactory).getRoyaltyDetails();
        uint balance = royalty.royaltyPoolBalance;
        uint royaltyPercentageToBips = royaltyPercentage * 100;
        uint txFee = (balance * royaltyPercentageToBips) / 10000;
        uint toWithdraw = balance - txFee;
        ownerWithdrawn = true;
        address _owner = payable(owner);
        (bool hs, ) = payable(royaltyAddress).call{value: txFee}("");
        (bool os, ) = _owner.call{value: toWithdraw}("");
        require(hs);
        require(os);
    }

    /// @notice This function is used to withdraw the royalty. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawRoyalty(uint _amount, address _holder) external nonReentrant {
        require(hasEnded == true, "sale not ended");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        require(address(this).balance >= _amount, "low balance");
        require(royaltyBalance[_holder] >= _amount, "Insufficient royalty balance");
        royaltyBalance[_holder] - _amount;
        (bool os, ) = payable(_holder).call{value: _amount}("");
        emit RoyaltyWithdrawn(_amount, _holder);
        require(os);
    }

    /// @notice This function is used to withdraw the royalty in ERC20. It can only be called by the royalty token holder
    /// @param _amount amount of royalty token to be withdrawn
    /// @param _holder address of the royalty token holder
    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external nonReentrant {
        require(hasEnded == true, "sale not ended");
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty still open");
        require(IERC20(_tokenAddress).balanceOf(address(this)) >= _amount, "low balance");
        require(ercRoyaltyBalance[_holder][_tokenAddress] >= _amount, "Insufficient royalty balance");
        ercRoyaltyBalance[_holder][_tokenAddress] -= _amount;
        (bool os) = IERC20(_tokenAddress).transfer(_holder, _amount);
        require(os);
        emit RoyaltyWithdrawn(_amount, _holder);  
    }

    /// @notice This function changes the state of the royalty sale and should only be called by the owner
    function changeRoyaltyState() external onlyOwner{
        require(hasEnded == false, "already ended");
        if(tokenRoyaltyState == TokenRoyaltyState.OPEN){
            tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        } else {
            tokenRoyaltyState = TokenRoyaltyState.OPEN;
        }
    }

    /// @notice This function changes the state of the royalty sale to closed and should only be called by the owner, and can only be called once
    function endRoyaltySale() external onlyOwner {
        require(hasEnded == false, "endRoyaltySale: already ended");
        tokenRoyaltyState = TokenRoyaltyState.CLOSED;
        hasEnded = true;
    }
    
    /// @notice this function is used to transfer ownership of the sale contract to a new owner and should only be called by the owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    ///GETTERS
    function getPoolMembers() external view returns (address[] memory){
        return royalty.royaltyPoolMembers;
    }

    function getPoolMemberCount() external view returns (uint){
        return royalty.royaltyPoolMembers.length;
    }

    function getPoolSize() external view returns(uint){
        return royalty.royaltyPoolSize;
    }

    function getPoolBalance() external view returns(uint){
        return royalty.royaltyPoolBalance;
    }

    function getMemberPoolSize(address addr) external view returns(uint){
        uint balance = IERC20(royalty.royaltyCPToken).balanceOf(addr);
        uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
        return poolSize;
    }

    function getRoyatyTokenAddress() external view returns(address){
        return royalty.royaltyCPToken;
    }

    function getRoyaltyBalance(address addr) external view returns(uint){
        return royaltyBalance[addr];
    }

    function getERC20RoyaltyBalance(address addr, address tokenAddress) external view returns(uint){
        return ercRoyaltyBalance[addr][tokenAddress];
    }

    function getCreator() external view returns (address){
        return royalty.creator;
    }

    function checkRoyaltyState() external view returns(bool){
        if(tokenRoyaltyState == TokenRoyaltyState.OPEN){
            return true;
        } else {
            return false;
        }
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getRoyaltyPercentage() external view returns(uint){
        return royalty.percentage;
    }

    function getRoyaltyState() external view returns (uint){
        return uint(tokenRoyaltyState);
    }

    function getTokenDetails() external view returns(string memory, string memory) {
        return ( royalty.name, royalty.creatorsName);
    }

    function getTimeLeft() external view returns (uint256) {
        uint timePassed = block.timestamp - lastRoyaltyUpdate;
        uint nextUpdate = lastRoyaltyUpdate + updateInterval;
        uint timeLeft = nextUpdate - timePassed;
        return timeLeft;
    } 

    function checkAutomation() external view returns (bool) {
        return automationStarted;
    }

    function getLastRoyaltyUpdate() external view returns (uint) {
        return lastRoyaltyUpdate;
    }

    function _start() internal {
        tokenRoyaltyState = TokenRoyaltyState.OPEN;
         _CPToken(royalty.name, royalty.symbol);
    }

    function _CPToken(string memory name, string memory symbol) internal {
        CPTokenV3 newCpToken = new CPTokenV3(name, address(this), symbol);
        royalty.royaltyCPToken = address(newCpToken);
        newCpToken.mint(royalty.royaltyPoolSize, address(this));
    }

    /// @notice This function is used to update the royalty balance of royalty token holders
    /// @param amount amount of royalty to be distributed
    /// @dev this function is called in the receive fallback function.
    function _update(uint amount) internal {
        require(tokenRoyaltyState == TokenRoyaltyState.CLOSED, "royalty sale still open");
        address[] memory holders = CPTokenV3(royalty.royaltyCPToken).getHolders();
        for(uint i = 0; i < holders.length; i++){
            address poolMember = holders[i];
            uint balance = IERC20(royalty.royaltyCPToken).balanceOf(poolMember);
            require(balance != 0, "balance is zero");
            uint poolSize = (balance * 10000) / royalty.royaltyPoolBalance;
            uint _amount = (poolSize * amount) / 10000;
            royaltyBalance[poolMember] += _amount;
        }
        lastRoyaltyUpdate = block.timestamp;   
        emit RoyaltyBalanceUpdated(block.timestamp, msg.value);
    }

    receive() external payable {
        _update(msg.value);
    }
}

interface IPicardyTokenRoyaltySaleV3 {
    
    /// @notice starts the token royalty sale
    function start() external ;

    /// @notice buys royalty
    function buyRoyalty(uint _amount, address _holder) external payable;

    /// @notice gets the pool members
    function getPoolMembers() external view returns (address[] memory);

    /// @notice gets the pool member count
    function getPoolMemberCount() external view returns (uint);

    /// @notice gets the pool size
    function getPoolSize() external view returns(uint);

    /// @notice gets the pool balance
    function getPoolBalance() external view returns(uint);

    /// @notice gets the member pool size
    function getMemberPoolSize(address addr) external view returns(uint);

    /// @notice gets the royalty balance
    function getRoyaltyBalance(address addr) external view returns(uint);

    function checkAutomation() external view returns (bool);

    /// @notice gets the royalty percentage
    function getRoyaltyPercentage() external view returns(uint);

    function getTokenDetails() external view returns(string memory, string memory);

    function checkRoyaltyState() external view returns(bool);

    function getLastRoyaltyUpdate() external view returns (uint);

    /// @notice updates the royalty balance
    function updateRoyalty(uint amount, address tokenAddress) external;

    function getCreator() external view returns (address);

    function getOwner() external view returns(address);

    /// @notice withdraws the royalty contract balance
    function withdraw() external;

    /// @notice withdraws the royalty balance
    function withdrawRoyalty(uint _amount, address _holder) external;

    function withdrawERC20Royalty(uint _amount, address _holder, address _tokenAddress) external;

    function setupAutomationV2(uint256 _updateInterval, address _royaltyAdapter, address _oracle, string memory _jobId) external;

    function toggleAutomation() external ;

}