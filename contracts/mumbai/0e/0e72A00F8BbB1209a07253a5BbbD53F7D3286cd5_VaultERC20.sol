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
pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IApplication {
    function handleRequestFromRouter(string memory sender, bytes memory payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Utils.sol";

/**
 * @dev Interface of the Gateway Self External Calls.
 */
interface IGateway {
    function requestToRouter(
        uint256 routeAmount,
        string memory routeRecipient,
        bytes memory payload,
        string memory routerBridgeContract,
        uint256 gasLimit,
        bytes memory asmAddress
    ) external payable returns (uint64);

    function setDappMetadata(string memory feePayerAddress) external payable returns (uint64);

    function executeHandlerCalls(
        string memory sender,
        bytes[] memory handlers,
        bytes[] memory payloads,
        bool isAtomic
    ) external returns (bool[] memory, bytes[] memory);

    function requestToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckType ackType,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function readQueryToDest(
        Utils.RequestArgs memory requestArgs,
        Utils.AckGasParams memory ackGasParams,
        Utils.DestinationChainParams memory destChainParams,
        Utils.ContractCalls memory contractCalls
    ) external payable returns (uint64);

    function requestToRouterDefaultFee() external view returns (uint256 fees);

    function requestToDestDefaultFee() external view returns (uint256 fees);
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
        uint64 valsetNonce;
    }

    // This is being used purely to avoid stack too deep errors
    struct RouterRequestPayload {
        //route
        uint256 routeAmount;
        bytes routeRecipient;
        // the sender address
        string routerBridgeAddress;
        string relayerRouterAddress;
        bool isAtomic;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        // The user contract address
        bytes asmAddress;
        bytes[] handlers;
        bytes[] payloads;
        uint64 outboundTxNonce;
    }

    struct AckGasParams {
        uint64 gasLimit;
        uint64 gasPrice;
    }

    struct InboundSourceInfo {
        uint256 routeAmount;
        string routeRecipient;
        uint64 eventNonce;
        uint64 srcChainType;
        string srcChainId;
    }

    struct SourceChainParams {
        uint64 crossTalkNonce;
        uint64 expTimestamp;
        bool isAtomicCalls;
        uint64 chainType;
        string chainId;
    }
    struct SourceParams {
        bytes caller;
        uint64 chainType;
        string chainId;
    }

    struct DestinationChainParams {
        uint64 gasLimit;
        uint64 gasPrice;
        uint64 destChainType;
        string destChainId;
        bytes asmAddress;
    }

    struct RequestArgs {
        uint64 expTimestamp;
        bool isAtomicCalls;
    }

    struct ContractCalls {
        bytes[] payloads;
        bytes[] destContractAddresses;
    }

    struct CrossTalkPayload {
        string relayerRouterAddress;
        bool isAtomic;
        uint64 eventIdentifier;
        uint64 chainTimestamp;
        uint64 expTimestamp;
        uint64 crossTalkNonce;
        bytes asmAddress;
        SourceParams sourceParams;
        ContractCalls contractCalls;
        bool isReadCall;
    }

    struct CrossTalkAckPayload {
        string relayerRouterAddress;
        uint64 crossTalkNonce;
        uint64 eventIdentifier;
        uint64 destChainType;
        string destChainId;
        bytes srcContractAddress;
        bool[] execFlags;
        bytes[] execData;
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
    error InvalidValsetNonce(uint64 newNonce, uint64 currentNonce);
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
import "@routerprotocol/evm-gateway-contracts/contracts/IApplication.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract VaultERC20 is IApplication {
    IGateway public gateway;
    IERC20 public erc20Token;
    //can create mapping of whitelisted middlewareContract but
    //for current usecase this variable can work.
    string public middlewareContract;

    constructor(
        address gatewayAddress,
        string memory _middlewareContract,
        address _erc20
    ) {
        gateway = IGateway(gatewayAddress);
        middlewareContract = _middlewareContract;
        erc20Token = IERC20(_erc20);
    }

    event XTransferEvent(
        address indexed sender,
        string indexed recipient,
        uint256 amount,
        string middlewareContract
    );

    event UnlockERC20Event(address indexed recipient, uint256 amount);
    event xBuyEvent(
        address indexed sender,
        uint256 amount,
        string middlewareContract
    );

    //xTransferERC20 function handles for locking of ERC20 token in this contract and
    //invoke call for minting on router chain
    //CONSTANT FEE DEDUCT
    function xTransferERC20(
        string memory recipient,
        uint256 amount,
        uint64 rGasLimit
    ) public payable {
        erc20Token.transferFrom(msg.sender, address(this), amount);
        bytes memory innerPayload = abi.encode(amount, msg.sender, recipient);
        bytes memory payload = abi.encode(100,innerPayload);
        // gateway.requestToRouter(innerPayload, middlewareContract);
        gateway.requestToRouter(0, "", payload, middlewareContract, rGasLimit, "");
        emit XTransferEvent(msg.sender, recipient, amount, middlewareContract);
    }

    //xBuy function handles for locking of ERC20 token in this contract and
    //invoke call for swapping in router chain
    //Approval required
    //CONSTANT FEE DEDUCT
    function xBuy(
        address recipient,
        string memory binaryPayload,
        address destVaultAddress,
        uint256 amount,
        uint64 rGasLimit
    ) public {
        erc20Token.transferFrom(msg.sender, address(this), amount);
        bytes memory innerPayload = abi.encode(
            amount,
            msg.sender,
            recipient,
            destVaultAddress,
            binaryPayload
        );
        bytes memory payload = abi.encode(101, innerPayload);
        // gateway.requestToRouter(innerPayload, middlewareContract);
        gateway.requestToRouter(0, "", payload, middlewareContract, rGasLimit, "");
        emit xBuyEvent(msg.sender, amount, middlewareContract);
    }

    //ADMIN FUNC (REMOVING PERMISSION FOR TESTING PURPOSE)
    function updateMiddlewareContract(
        string memory newMiddlewareContract
    ) external {
        middlewareContract = newMiddlewareContract;
    }

    function updateERC20Address(address newERC20Address) external {
        erc20Token = IERC20(newERC20Address);
    }

    //handleRequestFromRouter handles incoming request from router chain
    function handleRequestFromRouter(
        string memory sender,
        bytes memory payload
    ) public {
        require(msg.sender == address(gateway));
        require(
            keccak256(abi.encode(sender)) ==
                keccak256(abi.encode(middlewareContract)),
            "The origin router bridge contract is different"
        );
        (address payable recipient, uint256 amount) = abi.decode(
            payload,
            (address, uint256)
        );
        _handleUnlockERC20(recipient, amount);
    }

    //_handleUnlockERC20 function unlocks ERC20 token locked in contract
    function _handleUnlockERC20(
        address payable recipient,
        uint256 amount
    ) internal {
        erc20Token.transfer(recipient, amount);
        emit UnlockERC20Event(recipient, amount);
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}