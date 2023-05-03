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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Vault is IDapp {
    IGateway public gateway;
    //can create mapping of whitelisted middlewareContract but
    //for current usecase this variable can work.
    string public middlewareContract;

    constructor(address gatewayAddress, string memory _middlewareContract,string memory feePayer) {
        gateway = IGateway(gatewayAddress);
        middlewareContract = _middlewareContract;
        gateway.setDappMetadata(feePayer);
    }

    event XTransferEvent(
        address indexed sender,
        string indexed recipient,
        uint256 amount,
        string middlewareContract
    );
    event XSwapEvent(
        address indexed sender,
        uint256 amount,
        string middlewareContract
    );
    event UnlockEvent(address indexed recipient, uint256 amount);

    //xTransfer function handles for locking of native token in this contract and
    //invoke call for minting on router chain
    //CONSTANT FEE DEDUCT
    //mapped id: 100
    function xTransfer(string memory recipient, bytes calldata requestMetadata) public payable {
        require(msg.value > 0, "no fund transferred to vault");
        bytes memory innerPayload = abi.encode(
            msg.value,
            msg.sender,
            recipient
        );
        bytes memory payload = abi.encode(100, innerPayload);
         bytes memory requestPayload = abi.encode(middlewareContract, payload);
        gateway.iSend(1, 0, string(""),"router_9000-1", requestMetadata, requestPayload);
        emit XTransferEvent(
            msg.sender,
            recipient,
            msg.value,
            middlewareContract
        );
    }

    //xSwap function handles for locking of native token in this contract and
    //invoke call for swapping in router chain
    //CONSTANT FEE DEDUCT
    //mapped id: 101
    function xSwap(
        address recipient,
        string memory binaryPayload,
        address destVaultAddress,
        bytes calldata requestMetadata
    ) public payable {
        bytes memory innerPayload = abi.encode(
            msg.value,
            msg.sender,
            recipient,
            destVaultAddress,
            binaryPayload
        );
        bytes memory payload = abi.encode(101, innerPayload);
        bytes memory requestPayload = abi.encode(middlewareContract, payload);
        gateway.iSend(1, 0, string(""),"router_9000-1", requestMetadata, requestPayload);
        emit XSwapEvent(msg.sender, msg.value, middlewareContract);
    }

    //ADMIN FUNC (REMOVING PERMISSION FOR TESTING PURPOSE)
    function updateMiddlewareContract(
        string memory newMiddlewareContract
    ) external {
        middlewareContract = newMiddlewareContract;
    }

    //iReceive handles incoming request from router chain
    function iReceive(
    string memory requestSender,
    bytes memory packet,
    string memory srcChainId
  ) external override returns (bytes memory) {
        require(msg.sender == address(gateway));
        require(
            keccak256(abi.encode(requestSender)) ==
                keccak256(abi.encode(middlewareContract)),
            "The origin router bridge contract is different"
        );
        (address payable recipient, uint256 amount) = abi.decode(
            packet,
            (address, uint256)
        );
        _handleUnlock(recipient, amount);

        return "0x";
    }

//iAck handles ack request from router chain
    function iAck(uint256 requestIdentifier, bool execFlags, bytes memory execData) external {

    }

    //_handleUnlock function unlocks native token locked in contract
    function _handleUnlock(address payable recipient, uint256 amount) internal {
        (bool success, ) = recipient.call{value: amount}(new bytes(0));
        require(success, "Native transfer failed");
        emit UnlockEvent(recipient, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
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
    bytes memory asmAddress
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
    receive() external payable {}
}