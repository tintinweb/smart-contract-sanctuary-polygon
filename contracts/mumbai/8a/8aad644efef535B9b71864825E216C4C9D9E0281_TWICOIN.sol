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

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
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

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.10;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC20Metadata.sol";
import "./utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
    uint256 private _depositer;

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
    constructor() {}

    function setNameAndSymbol(string memory name_,string memory symbol_) internal {
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
        require(currentAllowance >= subtractedValue, "101");
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
        require(from != address(0), "102");
        require(to != address(0), "103");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "104");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        require(account != address(0), "105");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        require(account != address(0), "106");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "107");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    //transfer to depositer
    function _transferToDepositer(address account, uint256 amount) internal virtual {
        require(account != address(0), "111");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "112");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _depositer  += amount;
    }

    //transfer from depositer
    function _transferFromDepositer(address account, uint256 amount) internal virtual {
        require(account != address(0), "113");
        require(_depositer >= amount, "114");

        _balances[account] += amount;
        _depositer  -= amount;

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
        require(owner != address(0), "108");
        require(spender != address(0), "109");

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
            require(currentAllowance >= amount, "110");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";

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
pragma solidity ^0.8.10;


/**
 * @dev Interface for the twiCoin account.
 *
 */
interface ITWICOIN {

    event Unbind(address indexed unbinder, bytes indexed twiUserName);
    
    event Bind(address indexed binder, bytes indexed twiUserName);

    event TransferToTwi(address indexed from, bytes indexed twiUserName, uint256 amount);

    /**
     * @dev unbind
     */
    function unbind() external;

    /**
     * @dev bind
     */
    function bind(string memory twi_string_) external;

    
    /**
     * @dev payBind
     */
    function payBind(string memory twi_string_) external;

    /**
     * @dev getTwiByAddr
     */
    function getTwiByAddr(address address_) external view returns (string memory);

    /**
     * @dev getAddrByTwi
     */
    function getAddrByTwi(string memory twi_string_) external view returns (address);

    /**
     * @dev transferToTwi
     */
    function transferToTwi(string memory twi_string_, uint256 amount) external returns (bool);

    /**
     * @dev getBalanceByTwi
     */
    function getBalanceByTwi(string memory twi_string_) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;


import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./utils/SafeMath.sol";
import "./utils/ContractTools.sol";
import "./utils/Context.sol";
import "./ERC20.sol";

abstract contract TIP is ContractTools, ERC20 {

  using SafeMath for uint256;
  
  // Tip coin
  struct TipInfo{
    address creatorAddress;//creator address
    uint256 tipAmount;//total tip amount
    uint256 recipientNum;//number of people received who have received tips
    uint256 maxRecipientNum;//max number of people who can receive tips
    uint256 remainingAmount;//remaining amount
    bool isOnlyWLRecipient;//whitelist recipient or not
    bool isRandomDistribution;//random distribution or not
    bool isOnlyVerifiedRecipient;//verified users or not
    uint256 startTime;//start time
    uint256 endTime;//end time
  }

  // Tip code > tip
  mapping(bytes => TipInfo) private tipRecord;
  // Tip code > address > receivingTime
  mapping(bytes => mapping(address => uint256)) private tipReceivingRecord;
  // Address > tree root
  mapping(address => bytes32) private whiteListMerkleRoot;

  uint256 private constant TIP_MIN_LENGTH = 8;
  uint256 private constant TIP_MAX_LENGTH = 30;
  bool internal constant NOT_ALL_NUM = true;
  bool internal constant ALLOW_ALL_NUM = false;
  uint256 internal constant MAX_TIME_INTERVAL = 7776000;
  uint256 private constant MIN_SING_RECEIVE_VALUE = 1000000000000;
  uint256 internal constant MIN_RECEIVER_NUM = 1;
  uint256 internal constant MAX_RECEIVER_NUM = 1000;
  uint256 internal constant MIN_TIP_AMOUNT = 1000000000000;
  uint256 internal constant MAX_TIP_AMOUNT = 1000000000000000000000000;//1M


    // Event: create a tip
    event SetTip(address indexed creatorAddress, uint256 tipAmount, uint256 maxRecipientNum, bool isOnlyWLRecipient_,
                    bool isRandomDistribution, bool isOnlyVerifiedRecipient, uint256 startTime, uint256 endTime);

    // Event: get a tip
    event GetTip(address indexed receiver, uint256 amount, uint256 receivedTime);

    // Event: end a tip
    event endTip(bytes indexed tipCode, uint256 indexed howEnd,uint256 timestamp);

    // Verify a tweet
    function checkVerifiedReceiver(address callerAddress) virtual internal returns(bool);
    
    // Check whether the tip recipient has already bound their Twitter account.
    modifier _balaceCheckForTip(uint256 amount) {
        require(amount >= MIN_TIP_AMOUNT && amount<= MAX_TIP_AMOUNT ,"401");
        require(balanceOf(_msgSender()) >= amount,"402");

        _;
    }

   /**
   * @dev Set caller's whitelist merkle tree root
   * @param merkleRoot_  whitelist merkle root
   */
    function setWhiteListMerkleRoot(bytes32 merkleRoot_) public {
        whiteListMerkleRoot[_msgSender()] = merkleRoot_;       
    }

    /**
   * @dev Check whether an address is in the whitelist
   * @param whiteListOwnerAddress whitelist owner address
   * @param proof proof array
   * @return result
   */
    function _checkAddressInWhiteList(address whiteListOwnerAddress, bytes32[] memory proof, address leafAddress) view private returns(bool){
        if(whiteListMerkleRoot[whiteListOwnerAddress] == 0x0000000000000000000000000000000000000000000000000000000000000000){
            return false;
        }

        bytes memory twiUserName = getTwiByCaller();
        bool isTwiInWhiteList = (twiUserName.length > 0? MerkleProof.verify(proof,whiteListMerkleRoot[whiteListOwnerAddress],
                keccak256(abi.encodePacked(string(twiUserName)))) : false);
        
        bytes32 leafAddressHash = keccak256(abi.encodePacked(leafAddress));
        return MerkleProof.verify(proof,whiteListMerkleRoot[whiteListOwnerAddress],leafAddressHash) || isTwiInWhiteList;
    }
    
    function getTwiByCaller() virtual internal view returns (bytes memory);


   /**
   * @dev Set tip
   * @param tipCode_  tip code
   * @param tipAmount_ total tip amount
   * @param maxRecipientNum_ max number of people who can receive this tip
   * @param isRandomDistribution_ random distribution or not
   * @param isOnlyVerifiedRecipient_ verified users or not
   * @param startTime_ start time
   * @param endTime_ end time
   */
    function setTip(string memory tipCode_,
        uint256 tipAmount_,
        uint256 maxRecipientNum_,
        bool isOnlyWLRecipient_,
        bool isRandomDistribution_,
        bool isOnlyVerifiedRecipient_,
        uint256 startTime_,
        uint256 endTime_)
        _isStrValid(tipCode_, TIP_MIN_LENGTH, TIP_MAX_LENGTH, ALLOW_ALL_NUM) 
        _balaceCheckForTip(tipAmount_) public {

        bytes memory tipCode = bytes(tipCode_);

        // The same tip code cannot be repeated in the same time period
        require(block.timestamp > tipRecord[tipCode].endTime,"403");

        // 1\The end time must be later than the start time; 
        // 2\The start time must be later than the current time; 
        // 3\The end time must be earlier than 3 months later
        require(endTime_ > startTime_ && startTime_ > block.timestamp,"404");
        require(endTime_ > block.timestamp && endTime_ < block.timestamp.add(MAX_TIME_INTERVAL),"404");

        // The number of recipients must be between 1 and 1000
        require(maxRecipientNum_ >= MIN_RECEIVER_NUM && maxRecipientNum_ <= MAX_RECEIVER_NUM,"405");

        // The total amount must be greater than or equal to one times the total number of recipients
        require(tipAmount_ >= maxRecipientNum_.mul(MIN_SING_RECEIVE_VALUE),"406");

        // Return the remaining amount to the owner of the tip(if any)
        _endTip(tipCode, 2);

        _buildTip(tipCode, tipAmount_, maxRecipientNum_, isOnlyWLRecipient_, isRandomDistribution_, isOnlyVerifiedRecipient_, startTime_, endTime_);
       
    }

    // buildTip
    function _buildTip(bytes memory tipCode, 
        uint256 tipAmount_, 
        uint256 maxRecipientNum_, 
        bool isOnlyWLRecipient_,
        bool isRandomDistribution_, 
        bool isOnlyVerifiedRecipient_, 
        uint256 startTime_, 
        uint256 endTime_) private{

        uint256 tipAmount ;

        // If average distribution is selected, the remainder after average distribution must be returned to the caller
        tipAmount = isRandomDistribution_?tipAmount_:tipAmount_.sub(tipAmount_.mod(maxRecipientNum_));

        _transferToDepositer(_msgSender(),tipAmount);

        TipInfo memory tipInfo = TipInfo ({
            creatorAddress: _msgSender(),
            tipAmount: tipAmount,
            recipientNum: 0,
            maxRecipientNum: maxRecipientNum_,
            remainingAmount: tipAmount,
            isOnlyWLRecipient: isOnlyWLRecipient_,
            isRandomDistribution: isRandomDistribution_,
            isOnlyVerifiedRecipient: isOnlyVerifiedRecipient_,
            startTime: startTime_,
            endTime: endTime_
        });

        tipRecord[tipCode] = tipInfo;

        emit SetTip(_msgSender(), tipAmount, maxRecipientNum_, isOnlyWLRecipient_, isRandomDistribution_, isOnlyVerifiedRecipient_, startTime_, endTime_);
    }

    
    /**
    * @dev Get tips by whitelist
    * @param tipCode_  tip code
    * @param wlProof_  whitelist proof array
    * @return receivedAmount  Amount of tip received
    */
    function getTipByWhiteList(string calldata tipCode_, bytes32[] calldata wlProof_) 
             _isStrValid(tipCode_, TIP_MIN_LENGTH, TIP_MAX_LENGTH, ALLOW_ALL_NUM) public returns(uint256){

        bytes memory tipCode = bytes(tipCode_);
        TipInfo memory tipInfo = tipRecord[tipCode];

        // Check whether the recipient is in the whitelist
        if(tipInfo.isOnlyWLRecipient){
            require(_checkAddressInWhiteList(tipInfo.creatorAddress, wlProof_, _msgSender()),"412");
        }

        return _checkTip(tipCode,tipInfo);

    }


    /**
    * @dev Get a tip
    * @param tipCode_  tip code
    * @return receivedAmount  Amount of tip received
    */
    function getTip(string calldata tipCode_)  
             _isStrValid(tipCode_, TIP_MIN_LENGTH, TIP_MAX_LENGTH, ALLOW_ALL_NUM) public returns(uint256){

        bytes memory tipCode = bytes(tipCode_);
        TipInfo memory tipInfo = tipRecord[tipCode];

        require(!tipInfo.isOnlyWLRecipient,"413");
        
        return _checkTip(tipCode,tipInfo);
    }

    /**
    * @dev Check whether tip is valid
    * @param tipCode  tip code
    * @param tipInfo  tip info
    * @return receivedAmount Amount of tip received
    */
    function _checkTip(bytes memory tipCode,TipInfo memory tipInfo) private returns(uint256){

        // Tip code must exist
        require(tipInfo.remainingAmount > 0 && tipInfo.maxRecipientNum > tipInfo.recipientNum ,"407");

        // Cannot be claimed past the expiration date
        require(tipInfo.endTime > block.timestamp,"408");

        // The current time must be within the claim time period
        require(block.timestamp >= tipInfo.startTime && block.timestamp < tipInfo.endTime ,"409");
 
        // Cannot be claimed more than once
        require(tipReceivingRecord[tipCode][_msgSender()] < tipInfo.startTime ,"410");
        
        // Check if the recipient has bound their twitter account
        if(tipInfo.isOnlyVerifiedRecipient){
            require(checkVerifiedReceiver(_msgSender()),"411");
        }
        
        return _getTip(tipCode,tipInfo);
    }

    
    /**
    * @dev Get a tip
    * @param tipCode tip code
    * @param tipInfo Tip info
    * @return receivedAmount Amount of tip received
    */
    function _getTip(bytes memory tipCode,TipInfo memory tipInfo) private returns(uint256){

        // Define a received amount
        uint256 receivedAmount;
        uint256 remainingRecipientsNum = tipInfo.maxRecipientNum.sub(tipInfo.recipientNum);

        receivedAmount = remainingRecipientsNum == 1 ? tipInfo.remainingAmount : (
            tipInfo.isRandomDistribution ? (MIN_SING_RECEIVE_VALUE + random(tipInfo.remainingAmount.div(remainingRecipientsNum).mul(2)))
            : tipInfo.tipAmount.div(tipInfo.maxRecipientNum));

        tipReceivingRecord[tipCode][_msgSender()] = block.timestamp;
        tipRecord[tipCode].recipientNum ++;
        tipRecord[tipCode].remainingAmount = tipInfo.remainingAmount.sub(receivedAmount);
        
        _transferFromDepositer(_msgSender(), receivedAmount);
        emit GetTip(_msgSender(), receivedAmount, block.timestamp);

        if(remainingRecipientsNum == 1){
            delete tipRecord[tipCode];
            emit endTip(tipCode, 1, block.timestamp);
        }

        return receivedAmount;
    }

    

    // Terminate Tip
    function terminateTip(string calldata tipCode_) 
        _isStrValid(tipCode_, 
        TIP_MIN_LENGTH, 
        TIP_MAX_LENGTH, 
        ALLOW_ALL_NUM) public returns(uint256){

        bytes memory tipCode = bytes(tipCode_);
        require(_msgSender() == tipRecord[tipCode].creatorAddress,"414");

        return _endTip(bytes(tipCode), 3);

    }

    // Return the remaining tip amount to ex-creator address
    function _endTip(bytes memory tipCode, uint256 howEnd) private returns(uint256){
        uint256 returnAmount = tipRecord[tipCode].remainingAmount;
        address creatorAddress = tipRecord[tipCode].creatorAddress;
        if(returnAmount > 0){

          _transferFromDepositer(creatorAddress, returnAmount);
        }

        delete tipRecord[tipCode];
        emit endTip(tipCode, howEnd, block.timestamp);

        return returnAmount;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/SafeMath.sol";
import "./interfaces/ITWICOIN.sol";
import "./VERIFY.sol";
import "./TIP.sol";

contract TWICOIN is ITWICOIN, VERIFY, TIP{

  using SafeMath for uint256;

  // Configuration parameters
  uint256 public verifyCoolDays = 0;
  uint256 public verifyBalanceLimit = 0;
  bool public verifyAccessible = true;
  // Twitter username length limit
  uint256 private twiUserNameMinLength = 4;
  uint256 private twiUserNameMaxLength = 15;
  // The verification code for binding twitter
  string bindTagName;
  
  // User Info struct
  struct UserInfo{
      bytes twiUserName;
      address bindAddress;
      uint256 bindDate;
      uint256 balance;
  }
  
  // Verification record struct
  struct VerifyObj{
    address bindAddress;
    bytes twiUserName;
  }
  
  // Username_lowercase > twiToInfo
  mapping(bytes => UserInfo) private twiToInfo;
  // Address > username_lowercase
  mapping(address => bytes) private addrTotwi;
  // Address > Binding time
  mapping(address => uint256) private addressBindTime;
  // RequestId > VerifyObj
  mapping(bytes32 => VerifyObj) private bindRecord;

  uint256 constant SEC_PER_DAY = 86400;


    // Initialize contract
    constructor (){
        bindTagName = "bindMyTwiCoin";
        setNameAndSymbol("Twi Coin","TICO");
        _mint(_msgSender(),10000000000000000000000000000);
    }

    // Modify configuration parameters
    function setVerifyConfig(
        uint256 verifyCoolDays_,
        uint256 verifyBalanceLimit_,
        bool verifyAccessible_,
        string calldata bindTagName_,
        uint256 twiUserNameMinLength_,
        uint256 twiUserNameMaxLength_) public virtual onlyOwner{
        verifyCoolDays = verifyCoolDays_;
        verifyBalanceLimit = verifyBalanceLimit_;
        verifyAccessible = verifyAccessible_;
        bindTagName = bindTagName_;
        twiUserNameMinLength = twiUserNameMinLength_;
        twiUserNameMaxLength = twiUserNameMaxLength_;
    }

    // ---------------------------twi coin---------------------------

    // Verify availability
    modifier _verifyAccessible(){
        
        require(verifyAccessible,"203");

        require(balanceOf(_msgSender()) >= verifyBalanceLimit,"204");

        if(addressBindTime[_msgSender()] != 0){
          uint256 coolDownTime = addressBindTime[_msgSender()].add(verifyCoolDays.mul(SEC_PER_DAY));
          require(block.timestamp > coolDownTime,"205");
        }

        _;

    }

    // Verify approved link or not
    modifier _verifyApprove(){

        require(defaultFee > 0,"206");
        require(IERC20(linkToken).balanceOf(_msgSender()) >= defaultFee,"207");
        require(getLinkTokenAllowance(_msgSender()) >= defaultFee,"208");

        _;

    }
        
    // Verify whether Twitter is bound
    function _isBound(string calldata twi_string_) view private {
        address bindAddress = twiToInfo[toLowercase(bytes(twi_string_))].bindAddress;
        require(bindAddress != _msgSender(),"201");
        require(bindAddress == address(0),"202");
    }

    /**
    * @dev Get Link Token Allowances
    * @param address_  wallet address
    * @return Approved amount 
    */
    function getLinkTokenAllowance(address address_) view public returns(uint256){
        return IERC20(linkToken).allowance(address_,address(this));
    }

    /**
    * @dev Unbind
    */
    function unbind() override public virtual{

        bytes memory twi_bytes = addrTotwi[_msgSender()];

        if(twi_bytes.length > 0){
            emit Unbind(_msgSender(),twi_bytes);

            delete twiToInfo[twi_bytes];
            delete addrTotwi[_msgSender()];
        }

    }

    /**
    * @dev Bind
    * @param twi_string_  Twitter username in string format
    */
    function bind(string calldata twi_string_) override public
        _isStrValid(twi_string_, twiUserNameMinLength, twiUserNameMaxLength, NOT_ALL_NUM) 
        _verifyAccessible(){

        _isBound(twi_string_);

        addressBindTime[_msgSender()] = block.timestamp;
        
        VerifyObj memory verifyObj = VerifyObj ({
            bindAddress: _msgSender(),
            twiUserName: bytes(twi_string_)
        });
        
        bindRecord[requestVerify(twi_string_, addressToString(_msgSender()), bindTagName)] = verifyObj;
        
    }

    /**
    * @dev Pay link tokens for twitter account verification
    * @param twi_string_  Twitter username in string format
    */
    function payBind(string calldata twi_string_) override public
        _isStrValid(twi_string_, twiUserNameMinLength, twiUserNameMaxLength, NOT_ALL_NUM) 
        _verifyApprove(){
            
        require(verifyAccessible,"203");

        _isBound(twi_string_);

        // Deduct binding fee here
        require(IERC20(linkToken).transferFrom(_msgSender(),address(this),defaultFee),"209");

        addressBindTime[_msgSender()] = block.timestamp;
        
        VerifyObj memory verifyObj = VerifyObj ({
            bindAddress: _msgSender(),
            twiUserName: bytes(twi_string_)
        });
        
        bindRecord[requestVerify(twi_string_, addressToString(_msgSender()), bindTagName)] = verifyObj;
        
    }

    /**
    * @dev Bind a twitter account
    * @param bindAddress  Address to bind
    * @param twiBytes  Twitter username to bind
    */
    function _doBind(address bindAddress, bytes memory twiBytes) private{

        unbind();

        bytes memory twiUserName  = copyBytesValue(twiBytes);

        twiBytes = toLowercase(twiBytes);

        addrTotwi[bindAddress] = twiBytes;
        
        if(twiToInfo[twiBytes].balance > 0){
            _transferFromDepositer(bindAddress, twiToInfo[twiBytes].balance);
        }

        UserInfo memory userInfoObj = UserInfo ({
            balance: 0,
            twiUserName: twiUserName,
            bindAddress: bindAddress,
            bindDate: block.timestamp
        });

        twiToInfo[twiBytes] = userInfoObj;

        emit Bind(bindAddress, twiUserName);

    }

    /**
    * @dev Get twitter username by address
    * @param address_  Address
    * @return twitter_username
    */
    function getTwiByAddr(address address_) override public virtual view returns (string memory){
        return string(twiToInfo[addrTotwi[address_]].twiUserName);
    }

    /**
    * @dev Get address by twitter username
    * @param twi_string_  Twitter username in string format
    * @return bound_address
    */
    function getAddrByTwi(string memory twi_string_) override public virtual 
        _isStrValid(twi_string_, twiUserNameMinLength, twiUserNameMaxLength, NOT_ALL_NUM) 
        view returns (address){
        return twiToInfo[toLowercase(bytes(twi_string_))].bindAddress;
    }

    /**
    * @dev Transfer to twitter username
    * @param twi_string_  Twitter username in string format
    * @param amount Amount
    * @return transfer result
    */
    function transferToTwi(
        string memory twi_string_, 
        uint256 amount) 
        _isStrValid(twi_string_, twiUserNameMinLength, twiUserNameMaxLength, NOT_ALL_NUM) 
        override public virtual returns (bool){
                              
        bytes memory twiUserName_bytes = toLowercase(bytes(twi_string_));
        address toAddress = getAddrByTwi(twi_string_);
        
        if(toAddress != address(0)){
            transfer(toAddress, amount);
        }
        else{
            address fromAddress = _msgSender();
            
            _transferToDepositer(fromAddress,amount);
            twiToInfo[twiUserName_bytes].balance = twiToInfo[twiUserName_bytes].balance.add(amount);

        }

        emit TransferToTwi(_msgSender(),twiUserName_bytes,amount);

        return true;
    }

    /**
    * @dev Get balance of twitter user
    * @param twi_string_  Twitter username in string format
    * @return balance of twitter user
    */
    function getBalanceByTwi(string memory twi_string_) 
        _isStrValid(twi_string_, twiUserNameMinLength, twiUserNameMaxLength, NOT_ALL_NUM) 
        override public virtual view returns (uint256 balance){
            
        bytes memory twi_bytes = toLowercase(bytes(twi_string_));
        address twi_address = getAddrByTwi(twi_string_);
        if(twi_address != address(0)){
            return balanceOf(twi_address);
        }
        else{
            return twiToInfo[twi_bytes].balance;
        }
    }

    // ---------------------------twi coin---------------------------


    //---------------------------Chainlink Oracle---------------------------

    // Event: fillBackResult
    event FillBackResult(address indexed binder, bytes indexed twiUserName);

    /**
    * @dev Fill back verification result
    * @param requestId_  Request ID
    * @param verifyResult_  Validation results
    */
    function fillBackResult(bytes32 requestId_, bool verifyResult_) override internal {
         
        address bindAddress = bindRecord[requestId_].bindAddress;
        require(bindAddress != address(0),"301");

        bytes memory twiUserName = bindRecord[requestId_].twiUserName;
        delete bindRecord[requestId_];

        require(verifyResult_,"302");
        _doBind(bindAddress,twiUserName);

        emit FillBackResult(bindAddress, twiUserName);
    }

    //---------------------------Chainlink Oracle---------------------------
    
    //---------------------------Tip Coin---------------------------

    /**
    * @dev Check whether the recipient has been verified
    * @param callerAddress  callerAddress
    * @return result
    */
    function checkVerifiedReceiver(address callerAddress) override view internal returns(bool){
        return addrTotwi[callerAddress].length == 0? false:true;
    }

    /**
    * @dev get twitter username by caller's address
    * @return twitter username
    */
    function getTwiByCaller() override view internal returns(bytes memory){
        return twiToInfo[addrTotwi[_msgSender()]].twiUserName;
    }
    
    //---------------------------Tip Coin---------------------------


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract ContractTools{

    // Check whether the string is valid
    modifier _isStrValid(string memory str,uint256 minLength,uint256 maxLength,bool notAllNum) {
        bytes memory strBytes = bytes(str);
        require(strBytes.length >= minLength && strBytes.length <= maxLength,"ERROR:Invalid string length");
        require(onlyValidCharacter(str),"ERROR:What you entered can only contain letters, numbers and '_'");
        if(notAllNum){
            require(checkNumbersCount(str),"ERROR:What you entered must include a non-number character");
        }
        _;
    }

    // Bytes to lowcase
    function toLowercase(bytes memory src) internal pure returns(bytes memory){
        for(uint i=0;i<src.length;i++){
            bytes1 b = src[i];
            if(b >= 'A' && b <= 'Z'){
                b |= 0x20;
                src[i] = b;
            }
        }
        return src;
    }

    // Copy bytes value
    function copyBytesValue(bytes memory src) pure internal returns(bytes memory){
        bytes memory res = new bytes(src.length);
        for (uint i = 0; i< src.length; i++){
            res[i] = src[i];
        }
        return res;
    }

    // Only number, letter and '_'
    function onlyValidCharacter(string memory src) internal pure returns(bool){
        bytes memory srcb = bytes(src);
        for(uint i=0;i<srcb.length;i++){
            bytes1 b = srcb[i];
            if((b >= 'A' && b <= 'Z')||(b >= 'a' && b <= 'z')||(b >= '0' && b <= '9')||b =='_'){
                continue;
            }
            else{
                return false;
            }
        }
        return true;
    }

    // Cannot be all numbers
    function checkNumbersCount(string memory src) internal pure returns(bool){
        bytes memory srcb = bytes(src);
        for(uint i=0;i<srcb.length;i++){
            bytes1 b = srcb[i];
            if(b < '0' || b > '9'){
                return true;
            }
        }
        return false;
    }

    // Convert addr to string
    function addressToString(address addr) internal pure returns(string memory){
        bytes memory strBytes = new bytes(42);
        // Convert addr to bytes
        bytes20 value = bytes20(uint160(addr));
        // Encode hex prefix
        strBytes[0] = '0';
        strBytes[1] = 'x';
        // Encode bytes usig hex encoding
        for(uint i=0;i<20;i++){
            uint8 byteValue = uint8(value[i]);
            strBytes[2 + (i<<1)] = encode((byteValue >> 4) & 0x0f);
            strBytes[3 + (i<<1)] = encode(byteValue & 0x0f);
        }
        return string(strBytes);
    }

    // Get a random number
    function random(uint num) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % num;
    }

    //-----------HELPER METHOD--------------//

    // Num represents a number from 0-15 and returns ascii representing [0-9A-Fa-f]
    function encode(uint8 num) private pure returns(bytes1){
        // 0-9 -> 0-9
        if(num >= 0 && num <= 9){
            return bytes1(num + 48);
        }
        // 10-15 -> a-f
        return bytes1(num + 87);
    }
        
    // Asc represents one of the char:[0-9A-Fa-f] and returns consperronding value from 0-15
    function decode(bytes1 asc) private pure returns(uint8){
        uint8 val = uint8(asc);
        // 0-9
        if(val >= 48 && val <= 57){
            return val - 48;
        }
        // A-F
        if(val >= 65 && val <= 70){
            return val - 55;
        }
        // a-f
        return val - 87;
    }
   

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMathForUint256: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMathForUint256: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMathForUint256: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMathForUint256: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMathForUint256: division by zero");
        uint256 c = a % b;
        return c;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./utils/Context.sol";
import "./utils/ContractTools.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

abstract contract VERIFY is Context, ChainlinkClient, ConfirmedOwner {
    
    //chainlink parameters
    using Chainlink for Chainlink.Request;
    uint256 public defaultFee = 1 * LINK_DIVISIBILITY; // 1 * 10**18
    address public linkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;//0xb0897686c545045aFc77CF20eC7A532E3120E0F1
    address private oracleAddress;
    bytes32 private jobId;

    constructor() ConfirmedOwner(_msgSender()) {
        setChainlinkToken(linkToken);
    }

    //Callback events after validation
    event RequestVerify(bytes32 indexed requestId, bool indexed data);

    /**
     * @notice Request from the oracle
     */
    function requestVerify(
        string memory userName,
        string memory keyWord,
        string memory bindTagName
    ) internal returns(bytes32 requestId) {

        Chainlink.Request memory req = buildOperatorRequest(jobId, this.fulfill.selector);
        req.add("userName", userName);
        req.add("keyWord", keyWord);
        req.add("tagName", bindTagName);
        req.addInt('times', 10**18);

        return sendOperatorRequestTo(oracleAddress, req, defaultFee);

    }

    /**
     * @notice Fulfillment function for variable bytes, This is called by the oracle. recordChainlinkFulfillment must be used.
     */
    function fulfill(bytes32 _requestId, bool verifyResult_) public recordChainlinkFulfillment(_requestId)
    {
        return fillBackResult(_requestId,verifyResult_);
    }

    /**
     * @notice fillBacResult
     */
    function fillBackResult(bytes32 _requestId, bool verifyResult_) virtual internal;

    /**
     * @notice Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(_msgSender(), link.balanceOf(address(this))), 'Unable to transfer');
    }

    /**
     * @notice Set Oracle Request Info
     */
    function setOracleRequest(
        address oracleAddress_,
        bytes32 jobId_,
        uint256 defaultFee_) public onlyOwner {
            
        oracleAddress = oracleAddress_;
        jobId = jobId_;
        defaultFee = defaultFee_;
    }

}