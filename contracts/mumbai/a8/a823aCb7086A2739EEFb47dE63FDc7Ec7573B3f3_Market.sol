// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IDapp {
    function iReceive(
        string memory requestSender,
        bytes memory packet,
        string memory srcChainId
    ) external returns (bytes memory);

    function iAck(uint256 requestIdentifier, bool execFlags, bytes memory execData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    // requestMetadata = abi.encodePacked(
    //     uint256 destGasLimit;
    //     uint256 destGasPrice;
    //     uint256 ackGasLimit;
    //     uint256 ackGasPrice;
    //     uint256 relayerFees;
    //     uint8 ackType;
    //     bool isReadCall;
    //     bytes asmAddress;
    // )

    function iSend(
        uint256 version,
        uint256 routeAmount,
        string calldata routeRecipient,
        string calldata destChainId,
        bytes calldata requestMetadata,
        bytes calldata requestPacket
    ) external payable returns (uint256);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint256);

    function crossChainRequestDefaultFee() external view returns (uint256 fees);

    function currentVersion() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Utils {
    // This is used purely to avoid stack too deep errors
    // represents everything about a given validator set
    struct ValsetArgs {
        // the validators in this set, represented by an Ethereum address
        address[] validators;
        // the powers of the given validators in the same order as above
        uint64[] powers;
        // the nonce of this validator set
        uint256 valsetNonce;
    }

    struct RequestPayload {
        uint256 routeAmount;
        uint256 requestIdentifier;
        uint256 requestTimestamp;
        string srcChainId;
        address routeRecipient;
        string destChainId;
        address asmAddress;
        string requestSender;
        address handlerAddress;
        bytes packet;
        bool isReadCall;
    }

    struct CrossChainAckPayload {
        uint256 requestIdentifier;
        uint256 ackRequestIdentifier;
        string destChainId;
        address requestSender;
        bytes execData;
        bool execFlag;
    }

    // This represents a validator signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    enum AckType {
        NO_ACK,
        ACK_ON_SUCCESS,
        ACK_ON_ERROR,
        ACK_ON_BOTH
    }

    error IncorrectCheckpoint();
    error InvalidValsetNonce(uint256 newNonce, uint256 currentNonce);
    error MalformedNewValidatorSet();
    error MalformedCurrentValidatorSet();
    error InsufficientPower(uint64 cumulativePower, uint64 powerThreshold);
    error InvalidSignature();
    // constants
    string constant MSG_PREFIX = "\x19Ethereum Signed Message:\n32";
    // The number of 'votes' required to execute a valset
    // update or batch execution, set to 2/3 of 2^32
    uint64 constant constantPowerThreshold = 2791728742;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IXERC721 {
  function transferCrossChain(
    string calldata chainId,
    uint256 tokenId,
    address recipient
  ) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @title Market
/// @author Kravtsov Dmitriy
/// @notice A cross-chain nft marketplace smart contract
contract Market is IDapp {
  // address of the owner
  address public owner;

 // name of the chain
  string public ChainId;

  // address of the gateway contract
  IGateway public gatewayContract;

  // set contract on source and destination chain
  mapping(string => string) public ourContractOnChains;

  // request identifier to loked value
  mapping(uint256 => LockedValue) public lockedValue;

  struct LockedValue {
    address owner;
    address buyer;
    uint256 value;
  }

  constructor(
    string memory chainId,
    address getewayAddress,
    string memory feePayerAddress
  ) {
    ChainId = chainId;
    gatewayContract = IGateway(getewayAddress);
    owner = msg.sender;

    // setting metadata for dapp
    gatewayContract.setDappMetadata(feePayerAddress);
  }

  /// @notice function to set the fee payer address on Router Chain.
  /// @param feePayerAddress address of the fee payer on Router Chain.
  function setDappMetadata(string memory feePayerAddress) external {
    require(msg.sender == owner, "only owner");
    gatewayContract.setDappMetadata(feePayerAddress);
  }

  /// @notice function to set the Router Gateway Contract.
  /// @param gateway address of the gateway contract.
  function setGateway(address gateway) external {
    require(msg.sender == owner, "only owner");
    gatewayContract = IGateway(gateway);
  }

  /// @notice function to set the address of our contracts on different chains.
  /// This will help in access control when a cross-chain request is received.

  function setContractOnChain(
    string calldata chainId,
    string calldata contractAddress
  ) external {
    require(msg.sender == owner, "only owner");
    
    ourContractOnChains[chainId] = contractAddress;
  }

  struct OrderData {
    string orderChain;
    address owner;
    address collection;
    uint256 token_id;
    uint256 nonce;
    string[] chainsIds;
    uint256[] priceOnChains;
  }

  struct RecieveOrder {
    OrderData order;
    address buyer;
  }

  function _getPriceOnThisChain(
    string[] memory chainsIds, 
    uint256[] memory priceOnChains
  ) internal view returns (uint256) {
    require(chainsIds.length == priceOnChains.length, "Invalid order (price length)");
    for (uint256 i = 0; i < chainsIds.length; i++) {
      if (keccak256(bytes(chainsIds[i])) == keccak256(bytes(ChainId))) {
        return priceOnChains[i];
      }
    }
    revert("Price no found");
  }

  function _resolveOrderCommon(OrderData calldata order) internal {
    IXERC721(order.collection).transferFrom(order.owner, msg.sender, order.token_id);
  }

  function _resolveOrderCrossChain(OrderData memory order, string memory dstChain, address buyer) internal {
    IXERC721(order.collection).transferCrossChain(dstChain, order.token_id, buyer);
  }

  function buyNft(OrderData calldata order, string calldata signature) external payable {
    require(_getPriceOnThisChain(order.chainsIds, order.priceOnChains) == msg.value, "Invalid value");
    // add signature verification
    if (keccak256(bytes(order.orderChain)) == keccak256(bytes(ChainId))) {
      _resolveOrderCommon(order);
    } else {
      _sendCrossChainRequest(RecieveOrder(order, msg.sender), msg.value);
    }
  }

  function _sendCrossChainRequest(RecieveOrder memory requestOrder, uint256 value) internal {
    string memory destChainId = requestOrder.order.orderChain;
    require(
      keccak256(bytes(ourContractOnChains[destChainId])) !=
        keccak256(bytes("")),
      "contract on dest not set"
    );

    // sending the order struct to the destination chain as payload.
    bytes memory packet = abi.encode(requestOrder);
    bytes memory requestPacket = abi.encode(
      ourContractOnChains[destChainId],
      packet
    );

    uint256 requestIdentifier = gatewayContract.iSend{ value: 0 }(
      1,
      0,
      string(""),
      destChainId,
      hex"000000000007a12000000006fc23ac00000000000007a12000000006fc23ac00000000000000000000000000000000000300",
      requestPacket
    );

    lockedValue[requestIdentifier] = LockedValue(requestOrder.order.owner, requestOrder.buyer, value);
  }
  

  /// @notice function to get the request metadata to be used while initiating cross-chain request
  /// @return requestMetadata abi-encoded metadata according to source and destination chains
  function getRequestMetadata(
    uint64 destGasLimit,
    uint64 destGasPrice,
    uint64 ackGasLimit,
    uint64 ackGasPrice,
    uint128 relayerFees,
    uint8 ackType,
    bool isReadCall,
    string calldata asmAddress
  ) public pure returns (bytes memory) {
    bytes memory requestMetadata = abi.encodePacked(
      destGasLimit,
      destGasPrice,
      ackGasLimit,
      ackGasPrice,
      relayerFees,
      ackType,
      isReadCall,
      asmAddress
    );
    return requestMetadata;
  }

  function toBytes(address a) public pure returns (bytes memory b){
    assembly {
        let m := mload(0x40)
        a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
        mstore(0x40, add(m, 52))
        b := m
    }
 }

  /// @notice function to handle the cross-chain request received from some other chain.
  /// @param requestSender address of the contract on source chain that initiated the request.
  /// @param packet the payload sent by the source chain contract when the request was created.
  /// @param srcChainId chain ID of the source chain in string.
  function iReceive(
    string memory requestSender,
    bytes memory packet,
    string memory srcChainId
  ) external override returns (bytes memory) {
    require(msg.sender == address(gatewayContract), "only gateway");
    require(
      keccak256(bytes(ourContractOnChains[srcChainId])) ==
        keccak256(bytes(requestSender))
    );

    // decoding our payload
    RecieveOrder memory recieveOrder = abi.decode(packet, (RecieveOrder));
    
    _resolveOrderCrossChain(recieveOrder.order, srcChainId, recieveOrder.buyer);

    return "";
  }

  /// @notice function to handle the acknowledgement received from the destination chain
  /// back on the source chain.
  /// @param requestIdentifier event nonce which is received when we create a cross-chain request
  /// We can use it to keep a mapping of which nonces have been executed and which did not.
  /// @param execFlag a boolean value suggesting whether the call was successfully
  /// executed on the destination chain.
  /// @param execData returning the data returned from the handleRequestFromSource
  /// function of the destination chain.
  function iAck(
    uint256 requestIdentifier,
    bool execFlag,
    bytes memory execData
  ) external override {
    require(msg.sender == address(gatewayContract), "only gateway");
    
    LockedValue memory currentLockedValue = lockedValue[requestIdentifier];
    if (execFlag) {
      (bool success, ) = currentLockedValue.owner.call{value: currentLockedValue.value}("");
      require(success, "Payment failed.");
    } else {
      (bool success, ) = currentLockedValue.buyer.call{value: currentLockedValue.value}("");
      require(success, "Payment failed.");
    }

    delete lockedValue[requestIdentifier];
  }

  /// @notice Function to convert bytes to address
  /// @param _bytes bytes to be converted
  /// @return addr address pertaining to the bytes
  function toAddress(bytes memory _bytes) internal pure returns (address addr) {
    bytes20 srcTokenAddress;
    assembly {
      srcTokenAddress := mload(add(_bytes, 0x20))
    }
    addr = address(srcTokenAddress);
  }
}