// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {CBOR, Buffer} from "../vendor/solidity-cborutils/2.0.0/CBOR.sol";

/**
 * @title Library for Chainlink Functions
 */
library Functions {
  uint256 internal constant DEFAULT_BUFFER_SIZE = 256;

  using CBOR for Buffer.buffer;

  enum Location {
    Inline,
    Remote
  }

  enum CodeLanguage {
    JavaScript
    // In future version we may add other languages
  }

  struct Request {
    Location codeLocation;
    Location secretsLocation;
    CodeLanguage language;
    string source; // Source code for Location.Inline or url for Location.Remote
    bytes secrets; // Encrypted secrets blob for Location.Inline or url for Location.Remote
    string[] args;
  }

  error EmptySource();
  error EmptyUrl();
  error EmptySecrets();
  error EmptyArgs();
  error NoInlineSecrets();

  /**
   * @notice Encodes a Request to CBOR encoded bytes
   * @param self The request to encode
   * @return CBOR encoded bytes
   */
  function encodeCBOR(Request memory self) internal pure returns (bytes memory) {
    CBOR.CBORBuffer memory buffer;
    Buffer.init(buffer.buf, DEFAULT_BUFFER_SIZE);

    CBOR.writeString(buffer, "codeLocation");
    CBOR.writeUInt256(buffer, uint256(self.codeLocation));

    CBOR.writeString(buffer, "language");
    CBOR.writeUInt256(buffer, uint256(self.language));

    CBOR.writeString(buffer, "source");
    CBOR.writeString(buffer, self.source);

    if (self.args.length > 0) {
      CBOR.writeString(buffer, "args");
      CBOR.startArray(buffer);
      for (uint256 i = 0; i < self.args.length; i++) {
        CBOR.writeString(buffer, self.args[i]);
      }
      CBOR.endSequence(buffer);
    }

    if (self.secrets.length > 0) {
      if (self.secretsLocation == Location.Inline) {
        revert NoInlineSecrets();
      }
      CBOR.writeString(buffer, "secretsLocation");
      CBOR.writeUInt256(buffer, uint256(self.secretsLocation));
      CBOR.writeString(buffer, "secrets");
      CBOR.writeBytes(buffer, self.secrets);
    }

    return buffer.buf.buf;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Sets the codeLocation and code on the request
   * @param self The uninitialized request
   * @param location The user provided source code location
   * @param language The programming language of the user code
   * @param source The user provided source code or a url
   */
  function initializeRequest(
    Request memory self,
    Location location,
    CodeLanguage language,
    string memory source
  ) internal pure {
    if (bytes(source).length == 0) revert EmptySource();

    self.codeLocation = location;
    self.language = language;
    self.source = source;
  }

  /**
   * @notice Initializes a Chainlink Functions Request
   * @dev Simplified version of initializeRequest for PoC
   * @param self The uninitialized request
   * @param javaScriptSource The user provided JS code (must not be empty)
   */
  function initializeRequestForInlineJavaScript(Request memory self, string memory javaScriptSource) internal pure {
    initializeRequest(self, Location.Inline, CodeLanguage.JavaScript, javaScriptSource);
  }

  /**
   * @notice Adds Remote user encrypted secrets to a Request
   * @param self The initialized request
   * @param encryptedSecretsURLs Encrypted comma-separated string of URLs pointing to off-chain secrets
   */
  function addRemoteSecrets(Request memory self, bytes memory encryptedSecretsURLs) internal pure {
    if (encryptedSecretsURLs.length == 0) revert EmptySecrets();

    self.secretsLocation = Location.Remote;
    self.secrets = encryptedSecretsURLs;
  }

  /**
   * @notice Adds args for the user run function
   * @param self The initialized request
   * @param args The array of args (must not be empty)
   */
  function addArgs(Request memory self, string[] memory args) internal pure {
    if (args.length == 0) revert EmptyArgs();

    self.args = args;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Functions.sol";
import "../interfaces/FunctionsClientInterface.sol";
import "../interfaces/FunctionsOracleInterface.sol";

/**
 * @title The Chainlink Functions client contract
 * @notice Contract writers can inherit this contract in order to create Chainlink Functions requests
 */
abstract contract FunctionsClient is FunctionsClientInterface {
  FunctionsOracleInterface internal s_oracle;
  mapping(bytes32 => address) internal s_pendingRequests;

  event RequestSent(bytes32 indexed id);
  event RequestFulfilled(bytes32 indexed id);

  error SenderIsNotRegistry();
  error RequestIsAlreadyPending();
  error RequestIsNotPending();

  constructor(address oracle) {
    setOracle(oracle);
  }

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function getDONPublicKey() external view override returns (bytes memory) {
    return s_oracle.getDONPublicKey();
  }

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit,
    uint256 gasPrice
  ) public view returns (uint96) {
    return s_oracle.estimateCost(subscriptionId, Functions.encodeCBOR(req), gasLimit, gasPrice);
  }

  /**
   * @notice Sends a Chainlink Functions request to the stored oracle address
   * @param req The initialized Functions.Request
   * @param subscriptionId The subscription ID
   * @param gasLimit gas limit for the fulfillment callback
   * @return requestId The generated request ID
   */
  function sendRequest(
    Functions.Request memory req,
    uint64 subscriptionId,
    uint32 gasLimit
  ) internal returns (bytes32) {
    bytes32 requestId = s_oracle.sendRequest(subscriptionId, Functions.encodeCBOR(req), gasLimit);
    s_pendingRequests[requestId] = s_oracle.getRegistry();
    emit RequestSent(requestId);
    return requestId;
  }

  /**
   * @notice User defined function to handle a response
   * @param requestId The request ID, returned by sendRequest()
   * @param response Aggregated response from the user code
   * @param err Aggregated error from the user code or from the execution pipeline
   * Either response or error parameter will be set, but never both
   */
  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual;

  /**
   * @inheritdoc FunctionsClientInterface
   */
  function handleOracleFulfillment(
    bytes32 requestId,
    bytes memory response,
    bytes memory err
  ) external override recordChainlinkFulfillment(requestId) {
    fulfillRequest(requestId, response, err);
  }

  /**
   * @notice Sets the stored Oracle address
   * @param oracle The address of Functions Oracle contract
   */
  function setOracle(address oracle) internal {
    s_oracle = FunctionsOracleInterface(oracle);
  }

  /**
   * @notice Gets the stored address of the oracle contract
   * @return The address of the oracle contract
   */
  function getChainlinkOracleAddress() internal view returns (address) {
    return address(s_oracle);
  }

  /**
   * @notice Allows for a request which was created on another contract to be fulfilled
   * on this contract
   * @param oracleAddress The address of the oracle contract that will fulfill the request
   * @param requestId The request ID used for the response
   */
  function addExternalRequest(address oracleAddress, bytes32 requestId) internal notPendingRequest(requestId) {
    s_pendingRequests[requestId] = oracleAddress;
  }

  /**
   * @dev Reverts if the sender is not the oracle that serviced the request.
   * Emits RequestFulfilled event.
   * @param requestId The request ID for fulfillment
   */
  modifier recordChainlinkFulfillment(bytes32 requestId) {
    if (msg.sender != s_pendingRequests[requestId]) {
      revert SenderIsNotRegistry();
    }
    delete s_pendingRequests[requestId];
    emit RequestFulfilled(requestId);
    _;
  }

  /**
   * @dev Reverts if the request is already pending
   * @param requestId The request ID for fulfillment
   */
  modifier notPendingRequest(bytes32 requestId) {
    if (s_pendingRequests[requestId] != address(0)) {
      revert RequestIsAlreadyPending();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions billing subscription registry interface.
 */
interface FunctionsBillingRegistryInterface {
  struct RequestBilling {
    // a unique subscription ID allocated by billing system,
    uint64 subscriptionId;
    // the client contract that initiated the request to the DON
    // to use the subscription it must be added as a consumer on the subscription
    address client;
    // customer specified gas limit for the fulfillment callback
    uint32 gasLimit;
    // the expected gas price used to execute the transaction
    uint256 gasPrice;
  }

  enum FulfillResult {
    USER_SUCCESS,
    USER_ERROR,
    INVALID_REQUEST_ID
  }

  /**
   * @notice Get configuration relevant for making requests
   * @return uint32 global max for request gas limit
   * @return address[] list of registered DONs
   */
  function getRequestConfig() external view returns (uint32, address[] memory);

  /**
   * @notice Determine the charged fee that will be paid to the Registry owner
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(
    bytes calldata data,
    FunctionsBillingRegistryInterface.RequestBilling memory billing
  ) external view returns (uint96);

  /**
   * @notice Estimate the total cost to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param gasLimit Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasPrice The request's billing configuration
   * @param donFee Fee charged by the DON that is paid to Oracle Node
   * @param registryFee Fee charged by the DON that is paid to Oracle Node
   * @return costEstimate Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint32 gasLimit,
    uint256 gasPrice,
    uint96 donFee,
    uint96 registryFee
  ) external view returns (uint96);

  /**
   * @notice Initiate the billing process for an Functions request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing Billing configuration for the request
   * @return requestId - A unique identifier of the request. Can be used to match a request to a response in fulfillRequest.
   * @dev Only callable by a node that has been approved on the Registry
   */
  function startBilling(bytes calldata data, RequestBilling calldata billing) external returns (bytes32);

  /**
   * @notice Finalize billing process for an Functions request by sending a callback to the Client contract and then charging the subscription
   * @param requestId identifier for the request that was generated by the Registry in the beginBilling commitment
   * @param response response data from DON consensus
   * @param err error from DON consensus
   * @param transmitter the Oracle who sent the report
   * @param signers the Oracles who had a part in generating the report
   * @param signerCount the number of signers on the report
   * @param reportValidationGas the amount of gas used for the report validation. Cost is split by all fulfillments on the report.
   * @param initialGas the initial amount of gas that should be used as a baseline to charge the single fulfillment for execution cost
   * @return result fulfillment result
   * @dev Only callable by a node that has been approved on the Registry
   * @dev simulated offchain to determine if sufficient balance is present to fulfill the request
   */
  function fulfillAndBill(
    bytes32 requestId,
    bytes calldata response,
    bytes calldata err,
    address transmitter,
    address[31] memory signers, // 31 comes from OCR2Abstract.sol's maxNumOracles constant
    uint8 signerCount,
    uint256 reportValidationGas,
    uint256 initialGas
  ) external returns (FulfillResult);

  /**
   * @notice Gets subscription owner.
   * @param subscriptionId - ID of the subscription
   * @return owner - owner of the subscription.
   */
  function getSubscriptionOwner(uint64 subscriptionId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * @title Chainlink Functions client interface.
 */
interface FunctionsClientInterface {
  /**
   * @notice Returns the DON's secp256k1 public key used to encrypt secrets
   * @dev All Oracles nodes have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Chainlink Functions response handler called by the designated transmitter node in an OCR round.
   * @param requestId The requestId returned by FunctionsClient.sendRequest().
   * @param response Aggregated response from the user code.
   * @param err Aggregated error either from the user code or from the execution pipeline.
   * Either response or error parameter will be set, but never both.
   */
  function handleOracleFulfillment(bytes32 requestId, bytes memory response, bytes memory err) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./FunctionsBillingRegistryInterface.sol";

/**
 * @title Chainlink Functions oracle interface.
 */
interface FunctionsOracleInterface {
  /**
   * @notice Gets the stored billing registry address
   * @return registryAddress The address of Chainlink Functions billing registry contract
   */
  function getRegistry() external view returns (address);

  /**
   * @notice Sets the stored billing registry address
   * @param registryAddress The new address of Chainlink Functions billing registry contract
   */
  function setRegistry(address registryAddress) external;

  /**
   * @notice Returns the DON's secp256k1 public key that is used to encrypt secrets
   * @dev All nodes on the DON have the corresponding private key
   * needed to decrypt the secrets encrypted with the public key
   * @return publicKey the DON's public key
   */
  function getDONPublicKey() external view returns (bytes memory);

  /**
   * @notice Sets DON's secp256k1 public key used to encrypt secrets
   * @dev Used to rotate the key
   * @param donPublicKey The new public key
   */
  function setDONPublicKey(bytes calldata donPublicKey) external;

  /**
   * @notice Sets a per-node secp256k1 public key used to encrypt secrets for that node
   * @dev Callable only by contract owner and DON members
   * @param node node's address
   * @param publicKey node's public key
   */
  function setNodePublicKey(address node, bytes calldata publicKey) external;

  /**
   * @notice Deletes node's public key
   * @dev Callable only by contract owner or the node itself
   * @param node node's address
   */
  function deleteNodePublicKey(address node) external;

  /**
   * @notice Return two arrays of equal size containing DON members' addresses and their corresponding
   * public keys (or empty byte arrays if per-node key is not defined)
   */
  function getAllNodePublicKeys() external view returns (address[] memory, bytes[] memory);

  /**
   * @notice Determine the fee charged by the DON that will be split between signing Node Operators for servicing the request
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param billing The request's billing configuration
   * @return fee Cost in Juels (1e18) of LINK
   */
  function getRequiredFee(
    bytes calldata data,
    FunctionsBillingRegistryInterface.RequestBilling calldata billing
  ) external view returns (uint96);

  /**
   * @notice Estimate the total cost that will be charged to a subscription to make a request: gas re-imbursement, plus DON fee, plus Registry fee
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return billedCost Cost in Juels (1e18) of LINK
   */
  function estimateCost(
    uint64 subscriptionId,
    bytes calldata data,
    uint32 gasLimit,
    uint256 gasPrice
  ) external view returns (uint96);

  /**
   * @notice Sends a request (encoded as data) using the provided subscriptionId
   * @param subscriptionId A unique subscription ID allocated by billing system,
   * a client can make requests from different contracts referencing the same subscription
   * @param data Encoded Chainlink Functions request data, use FunctionsClient API to encode a request
   * @param gasLimit Gas limit for the fulfillment callback
   * @return requestId A unique request identifier (unique per DON)
   */
  function sendRequest(uint64 subscriptionId, bytes calldata data, uint32 gasLimit) external returns (bytes32);
}

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.4;

/**
 * @dev A library for working with mutable byte buffers in Solidity.
 *
 * Byte buffers are mutable and expandable, and provide a variety of primitives
 * for appending to them. At any time you can fetch a bytes object containing the
 * current contents of the buffer. The bytes object should not be stored between
 * operations, as it may change due to resizing of the buffer.
 */
library Buffer {
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
      let fpm := add(32, add(ptr, capacity))
      if lt(fpm, ptr) {
        revert(0, 0)
      }
      mstore(0x40, fpm)
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
   * @dev Appends len bytes of a byte string to a buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to copy.
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data, uint256 len) internal pure returns (buffer memory) {
    require(len <= data.length);

    uint256 off = buf.buf.length;
    uint256 newCapacity = off + len;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
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
      if gt(newCapacity, buflen) {
        mstore(bufptr, newCapacity)
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
      uint256 mask = (256 ** (32 - len)) - 1;
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
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes memory data) internal pure returns (buffer memory) {
    return append(buf, data, data.length);
  }

  /**
   * @dev Appends a byte to the buffer. Resizes if doing so would exceed the
   *      capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendUint8(buffer memory buf, uint8 data) internal pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 offPlusOne = off + 1;
    if (off >= buf.capacity) {
      resize(buf, offPlusOne * 2);
    }

    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + off
      let dest := add(add(bufptr, off), 32)
      mstore8(dest, data)
      // Update buffer length if we extended it
      if gt(offPlusOne, mload(bufptr)) {
        mstore(bufptr, offPlusOne)
      }
    }

    return buf;
  }

  /**
   * @dev Appends len bytes of bytes32 to a buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to write (left-aligned).
   * @return The original buffer, for chaining.
   */
  function append(buffer memory buf, bytes32 data, uint256 len) private pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 newCapacity = len + off;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
    }

    unchecked {
      uint256 mask = (256 ** len) - 1;
      // Right-align data
      data = data >> (8 * (32 - len));
      assembly {
        // Memory address of the buffer data
        let bufptr := mload(buf)
        // Address = buffer address + sizeof(buffer length) + newCapacity
        let dest := add(bufptr, newCapacity)
        mstore(dest, or(and(mload(dest), not(mask)), data))
        // Update buffer length if we extended it
        if gt(newCapacity, mload(bufptr)) {
          mstore(bufptr, newCapacity)
        }
      }
    }
    return buf;
  }

  /**
   * @dev Appends a bytes20 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chhaining.
   */
  function appendBytes20(buffer memory buf, bytes20 data) internal pure returns (buffer memory) {
    return append(buf, bytes32(data), 20);
  }

  /**
   * @dev Appends a bytes32 to the buffer. Resizes if doing so would exceed
   *      the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @return The original buffer, for chaining.
   */
  function appendBytes32(buffer memory buf, bytes32 data) internal pure returns (buffer memory) {
    return append(buf, data, 32);
  }

  /**
   * @dev Appends a byte to the end of the buffer. Resizes if doing so would
   *      exceed the capacity of the buffer.
   * @param buf The buffer to append to.
   * @param data The data to append.
   * @param len The number of bytes to write (right-aligned).
   * @return The original buffer.
   */
  function appendInt(buffer memory buf, uint256 data, uint256 len) internal pure returns (buffer memory) {
    uint256 off = buf.buf.length;
    uint256 newCapacity = len + off;
    if (newCapacity > buf.capacity) {
      resize(buf, newCapacity * 2);
    }

    uint256 mask = (256 ** len) - 1;
    assembly {
      // Memory address of the buffer data
      let bufptr := mload(buf)
      // Address = buffer address + sizeof(buffer length) + newCapacity
      let dest := add(bufptr, newCapacity)
      mstore(dest, or(and(mload(dest), not(mask)), data))
      // Update buffer length if we extended it
      if gt(newCapacity, mload(bufptr)) {
        mstore(bufptr, newCapacity)
      }
    }
    return buf;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../../@ensdomains/buffer/0.1.0/Buffer.sol";

/**
 * @dev A library for populating CBOR encoded payload in Solidity.
 *
 * https://datatracker.ietf.org/doc/html/rfc7049
 *
 * The library offers various write* and start* methods to encode values of different types.
 * The resulted buffer can be obtained with data() method.
 * Encoding of primitive types is staightforward, whereas encoding of sequences can result
 * in an invalid CBOR if start/write/end flow is violated.
 * For the purpose of gas saving, the library does not verify start/write/end flow internally,
 * except for nested start/end pairs.
 */

library CBOR {
  using Buffer for Buffer.buffer;

  struct CBORBuffer {
    Buffer.buffer buf;
    uint256 depth;
  }

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

  uint8 private constant CBOR_FALSE = 20;
  uint8 private constant CBOR_TRUE = 21;
  uint8 private constant CBOR_NULL = 22;
  uint8 private constant CBOR_UNDEFINED = 23;

  function create(uint256 capacity) internal pure returns (CBORBuffer memory cbor) {
    Buffer.init(cbor.buf, capacity);
    cbor.depth = 0;
    return cbor;
  }

  function data(CBORBuffer memory buf) internal pure returns (bytes memory) {
    require(buf.depth == 0, "Invalid CBOR");
    return buf.buf.buf;
  }

  function writeUInt256(CBORBuffer memory buf, uint256 value) internal pure {
    buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_BIGNUM));
    writeBytes(buf, abi.encode(value));
  }

  function writeInt256(CBORBuffer memory buf, int256 value) internal pure {
    if (value < 0) {
      buf.buf.appendUint8(uint8((MAJOR_TYPE_TAG << 5) | TAG_TYPE_NEGATIVE_BIGNUM));
      writeBytes(buf, abi.encode(uint256(-1 - value)));
    } else {
      writeUInt256(buf, uint256(value));
    }
  }

  function writeUInt64(CBORBuffer memory buf, uint64 value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_INT, value);
  }

  function writeInt64(CBORBuffer memory buf, int64 value) internal pure {
    if (value >= 0) {
      writeFixedNumeric(buf, MAJOR_TYPE_INT, uint64(value));
    } else {
      writeFixedNumeric(buf, MAJOR_TYPE_NEGATIVE_INT, uint64(-1 - value));
    }
  }

  function writeBytes(CBORBuffer memory buf, bytes memory value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_BYTES, uint64(value.length));
    buf.buf.append(value);
  }

  function writeString(CBORBuffer memory buf, string memory value) internal pure {
    writeFixedNumeric(buf, MAJOR_TYPE_STRING, uint64(bytes(value).length));
    buf.buf.append(bytes(value));
  }

  function writeBool(CBORBuffer memory buf, bool value) internal pure {
    writeContentFree(buf, value ? CBOR_TRUE : CBOR_FALSE);
  }

  function writeNull(CBORBuffer memory buf) internal pure {
    writeContentFree(buf, CBOR_NULL);
  }

  function writeUndefined(CBORBuffer memory buf) internal pure {
    writeContentFree(buf, CBOR_UNDEFINED);
  }

  function startArray(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_ARRAY);
    buf.depth += 1;
  }

  function startFixedArray(CBORBuffer memory buf, uint64 length) internal pure {
    writeDefiniteLengthType(buf, MAJOR_TYPE_ARRAY, length);
  }

  function startMap(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_MAP);
    buf.depth += 1;
  }

  function startFixedMap(CBORBuffer memory buf, uint64 length) internal pure {
    writeDefiniteLengthType(buf, MAJOR_TYPE_MAP, length);
  }

  function endSequence(CBORBuffer memory buf) internal pure {
    writeIndefiniteLengthType(buf, MAJOR_TYPE_CONTENT_FREE);
    buf.depth -= 1;
  }

  function writeKVString(CBORBuffer memory buf, string memory key, string memory value) internal pure {
    writeString(buf, key);
    writeString(buf, value);
  }

  function writeKVBytes(CBORBuffer memory buf, string memory key, bytes memory value) internal pure {
    writeString(buf, key);
    writeBytes(buf, value);
  }

  function writeKVUInt256(CBORBuffer memory buf, string memory key, uint256 value) internal pure {
    writeString(buf, key);
    writeUInt256(buf, value);
  }

  function writeKVInt256(CBORBuffer memory buf, string memory key, int256 value) internal pure {
    writeString(buf, key);
    writeInt256(buf, value);
  }

  function writeKVUInt64(CBORBuffer memory buf, string memory key, uint64 value) internal pure {
    writeString(buf, key);
    writeUInt64(buf, value);
  }

  function writeKVInt64(CBORBuffer memory buf, string memory key, int64 value) internal pure {
    writeString(buf, key);
    writeInt64(buf, value);
  }

  function writeKVBool(CBORBuffer memory buf, string memory key, bool value) internal pure {
    writeString(buf, key);
    writeBool(buf, value);
  }

  function writeKVNull(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    writeNull(buf);
  }

  function writeKVUndefined(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    writeUndefined(buf);
  }

  function writeKVMap(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    startMap(buf);
  }

  function writeKVArray(CBORBuffer memory buf, string memory key) internal pure {
    writeString(buf, key);
    startArray(buf);
  }

  function writeFixedNumeric(CBORBuffer memory buf, uint8 major, uint64 value) private pure {
    if (value <= 23) {
      buf.buf.appendUint8(uint8((major << 5) | value));
    } else if (value <= 0xFF) {
      buf.buf.appendUint8(uint8((major << 5) | 24));
      buf.buf.appendInt(value, 1);
    } else if (value <= 0xFFFF) {
      buf.buf.appendUint8(uint8((major << 5) | 25));
      buf.buf.appendInt(value, 2);
    } else if (value <= 0xFFFFFFFF) {
      buf.buf.appendUint8(uint8((major << 5) | 26));
      buf.buf.appendInt(value, 4);
    } else {
      buf.buf.appendUint8(uint8((major << 5) | 27));
      buf.buf.appendInt(value, 8);
    }
  }

  function writeIndefiniteLengthType(CBORBuffer memory buf, uint8 major) private pure {
    buf.buf.appendUint8(uint8((major << 5) | 31));
  }

  function writeDefiniteLengthType(CBORBuffer memory buf, uint8 major, uint64 length) private pure {
    writeFixedNumeric(buf, major, length);
  }

  function writeContentFree(CBORBuffer memory buf, uint8 value) private pure {
    buf.buf.appendUint8(uint8((MAJOR_TYPE_CONTENT_FREE << 5) | value));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRaCoToUserGov {
  function isUserWhitelisted(address _owner) external view returns (bool);

  function getgeoJSON(address _owner) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

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
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITreasury {
  function addTreasury(address _userAddress, bytes32 _requestId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// imports regarding chainlink functions
import {Functions, FunctionsClient} from "./dev/functions/FunctionsClient.sol";
import {IERC20} from "./Interface/IERC20.sol";
import {ITreasury} from "./Interface/ITreasury.sol";
import {IRaCoToUserGov} from "./Interface/Governance/IRaCoToUserGov.sol";

/**
 * @title Main Rainforest Token Management Contract
 * @notice This contract is for event emitting and minitng tokens
 */

contract RaCoTo is FunctionsClient {
  using Functions for Functions.Request;

  bytes32 public latestRequestId;
  bytes public latestResponse;
  bytes public latestError;
  bytes32 public jsSourceHash;

  uint256 public decimalVal = 18;
  address private treasuryAddress;
  address public raCoTokenAddress;
  address public raCoOwnerAddress;

  string[] public arguments;

  IERC20 public raCoTokenInstance;
  ITreasury public treasuryInstance;
  IRaCoToUserGov public userGovInstance;

  mapping(address => uint256) private tokensNeededToClaimByUser;
  mapping(address => uint256) private previousTokenClaimedByUser;

  event OCRResponse(bytes32 indexed requestId, bytes result, bytes err);

  error NotEnoughEth();
  error InvalidJSFile();

  constructor(
    address oracle,
    address _treasuryAddress,
    address _raCoTokenAddress,
    address _userGovAddress,
    bytes32 _jsSourceHash
  ) FunctionsClient(oracle) {
    treasuryAddress = _treasuryAddress;
    raCoTokenAddress = _raCoTokenAddress;
    raCoTokenInstance = IERC20(_raCoTokenAddress);
    treasuryInstance = ITreasury(_treasuryAddress);
    userGovInstance = IRaCoToUserGov(_userGovAddress);
    jsSourceHash = _jsSourceHash;
  }

  modifier onlyWhitelistedOwner(address _owner) {
    require(userGovInstance.isUserWhitelisted(_owner), "Method not allowed (only whitelisted)");
    _;
  }

  /**
   * @notice Send a simple request
   *
   * @param source JavaScript source code
   * @param secrets Encrypted secrets payload
   * @param args List of arguments accessible from within the source code
   * @param subscriptionId Funtions billing subscription ID
   * @param gasLimit Maximum amount of gas used to call the client contract's `handleOracleFulfillment` function
   * @return Functions request ID
   */

  function executeRequest(
    string calldata source,
    bytes calldata secrets,
    string[] calldata args,
    uint64 subscriptionId,
    uint32 gasLimit
  ) public returns (bytes32) {
    Functions.Request memory req;
    req.initializeRequest(Functions.Location.Inline, Functions.CodeLanguage.JavaScript, source);
    if (secrets.length > 0) {
      req.addRemoteSecrets(secrets);
    }
    if (args.length > 0) req.addArgs(args);

    bytes32 assignedReqID = sendRequest(req, subscriptionId, gasLimit);
    latestRequestId = assignedReqID;
    return assignedReqID;
  }

  /**
   * @notice This function will run as a callback for the request made to the DON (Decentralised Oracle Network)
   *
   * @param requestId - Request ID of the DON.
   * @param response - Request response
   * @param err - Request error

   * @notice function will either return response or error but never both 
   */

  function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
    latestResponse = response;
    latestError = err;

    if (response.length != 0) {
      uint256 numberOfTokensToMint = uint256(bytes32(response)) * 10 ** decimalVal;
      (uint256 numberOfTokenTreasury, uint256 numberOfTokenUser) = _getTokenSplit(numberOfTokensToMint);
      // managing the token requests
      previousTokenClaimedByUser[raCoOwnerAddress] = tokensNeededToClaimByUser[raCoOwnerAddress];
      tokensNeededToClaimByUser[raCoOwnerAddress] = numberOfTokenUser;
      // Transferring tokens to the treasury
      raCoTokenInstance.transfer(treasuryAddress, numberOfTokenTreasury);
      raCoOwnerAddress = address(0);
    }

    emit OCRResponse(requestId, response, err);
  }

  /**
   * @notice User function to claim the tokens
   */
  function claimToken() public onlyWhitelistedOwner(msg.sender) {
    uint256 token = (tokensNeededToClaimByUser[msg.sender]);
    require(token != 0, "No Tokens Claimable");

    raCoTokenInstance.transfer(msg.sender, token);
    // treasuryInstance.addTreasury(msg.sender, _requestId);
    delete tokensNeededToClaimByUser[msg.sender];
  }

  /**
   * @notice To calculate the total token split
   *
   * @param _totalTokenValue - This is the total tokens to be minted
   */
  function _getTokenSplit(uint256 _totalTokenValue) private pure returns (uint256, uint256) {
    uint256 numberOfTokenInTreasury = _totalTokenValue / 100;
    uint256 numberOfTokenToUser = (_totalTokenValue * 99) / 100;
    return (numberOfTokenInTreasury, numberOfTokenToUser);
  }

  /**
   * @notice Utility function to convert a uint256 to string
   *
   * @param value - uint256 value that will be converted to string
   */

  function uint256ToString(uint256 value) internal pure returns (string memory) {
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
    uint256 index = digits - 1;

    while (value != 0) {
      buffer[index--] = bytes1(uint8(48 + (value % 10)));
      value /= 10;
    }

    return string(buffer);
  }
}