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
    uint64 constant CONSTANT_POWER_THRESHOLD = 2791728742;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@routerprotocol/evm-gateway-contracts/contracts/IGateway.sol";
import "@routerprotocol/evm-gateway-contracts/contracts/IDapp.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";
// 0x76b71BDC9f179d57E34a03740c62F2e88b7AA6A8
// router1ahlwqthue0z6r9d4ph5n9kmkqwzvhqz9asmwrd
// 0x1687DF89145c0530161A36f8b26733f6584FE25e
// "router_9601-1"
// 0x00000000000f42400000000002faf08000000000000f424000000006fc23ac00000000000000000000000000000000000200
contract Vault is IDapp, Ownable {
    IGateway public gateway;
    //can create mapping of whitelisted middlewareContract but
    //for current usecase this variable can work.
    string public middlewareContract;
    string public routerChainId;

    mapping(uint256 => DepositDetails) public depositDetails;

    struct DepositDetails {
        address user;
        uint256 amount;
    }

    constructor(address gatewayAddress, string memory _middlewareContract,string memory feePayer, string memory _routerChainId) {
        gateway = IGateway(gatewayAddress);
        middlewareContract = _middlewareContract;
        gateway.setDappMetadata(feePayer);
        routerChainId = _routerChainId;
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
        uint256 requestIdentifier = gateway.iSend(1, 0, string(""), routerChainId, requestMetadata, requestPayload);
        depositDetails[requestIdentifier] = DepositDetails(msg.sender, msg.value);
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
        uint256 requestIdentifier = gateway.iSend(1, 0, string(""),"router_9601-1", requestMetadata, requestPayload);
        depositDetails[requestIdentifier] = DepositDetails(msg.sender, msg.value);
        emit XSwapEvent(msg.sender, msg.value, middlewareContract);
    }

    function updateMiddlewareContract(string memory newMiddlewareContract) external onlyOwner()  {
        middlewareContract = newMiddlewareContract;
    }

    /// @notice Used to withdraw fee
    /// @param recipient Address to withdraw tokens to.
    function withdrawFee(address recipient) external onlyOwner() {
        // default fee for "sendCrossChainRequest"
        payable(recipient).transfer(address(this).balance);
    }

    function updateFeePayer(string memory feePayer) external onlyOwner() {
        gateway.setDappMetadata(feePayer);
    }

    //iReceive handles incoming request from router chain
    function iReceive(
    string memory requestSender,
    bytes memory packet,
    string memory
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
    function iAck(uint256 requestIdentifier, bool execFlags, bytes memory) external {
        require(msg.sender == address(gateway));
        if(!execFlags) {
            DepositDetails memory details= depositDetails[requestIdentifier];
            payable(details.user).transfer(details.amount);
        }
        delete depositDetails[requestIdentifier];
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