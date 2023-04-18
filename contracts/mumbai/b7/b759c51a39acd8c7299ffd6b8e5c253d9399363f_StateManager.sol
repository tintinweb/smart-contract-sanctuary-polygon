// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

pragma solidity 0.8.17;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {IPRouter} from "../interfaces/IPRouter.sol";
import {IPToken} from "../interfaces/IPToken.sol";
import {IPFactory} from "../interfaces/IPFactory.sol";
import {IStateManager} from "../interfaces/IStateManager.sol";
import {Roles} from "../libraries/Roles.sol";
import {Errors} from "../libraries/Errors.sol";
import {Constants} from "../libraries/Constants.sol";
import {Utils} from "../libraries/Utils.sol";

contract StateManager is IStateManager, Context, ReentrancyGuard {
    mapping(bytes32 => OperationData) private _operationsData;

    address public immutable factory;
    uint32 public immutable queueTime;

    constructor(address _factory, uint32 _queueTime) {
        factory = _factory;
        queueTime = _queueTime;
    }

    function operationIdOf(Operation memory operation) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    operation.originBlockHash,
                    operation.originTransactionHash,
                    operation.originNetworkId,
                    operation.nonce,
                    operation.destinationAccount,
                    operation.destinationNetworkId,
                    operation.underlyingAssetName,
                    operation.underlyingAssetSymbol,
                    operation.underlyingAssetDecimals,
                    operation.underlyingAssetTokenAddress,
                    operation.underlyingAssetNetworkId,
                    operation.amount,
                    operation.userData,
                    operation.optionsMask
                )
            );
    }

    function protocolCancelOperation(Operation calldata operation) external {
        bytes32 operationId = operationIdOf(operation);

        OperationData storage operationData = _operationsData[operationId];

        if (operationData.status != Constants.OPERATION_QUEUED) {
            revert Errors.OperationNotQueued(operationId);
        }

        operationData.status = Constants.OPERATION_CANCELLED;
        emit OperationCancelled(operation);
    }

    function protocolExecuteOperation(Operation calldata operation) external nonReentrant {
        bytes32 operationId = operationIdOf(operation);

        OperationData storage operationData = _operationsData[operationId];
        bytes1 operationStatus = operationData.status;
        if (operationStatus == Constants.OPERATION_EXECUTED) {
            revert Errors.OperationAlreadyExecuted(operationId);
        }
        if (operationStatus == Constants.OPERATION_EXECUTED) {
            revert Errors.OperationCancelled(operationId);
        }

        uint64 executeTimestamp = operationData.executeTimestamp;
        if (uint64(block.timestamp) < executeTimestamp) {
            revert Errors.ExecuteTimestampNotReached(executeTimestamp);
        }

        if (operation.amount > 0) {
            address pTokenAddress = IPFactory(factory).getPTokenAddress(
                operation.underlyingAssetName,
                operation.underlyingAssetSymbol,
                operation.underlyingAssetDecimals,
                operation.underlyingAssetTokenAddress,
                operation.underlyingAssetNetworkId
            );

            address destinationAddress = Utils.parseAddress(operation.destinationAccount);
            IPToken(pTokenAddress).stateManagedProtocolMint(destinationAddress, operation.amount);

            if (Utils.isBitSet(operation.optionsMask, 1)) {
                if (!Utils.isCurrentNetwork(operation.underlyingAssetNetworkId)) {
                    revert Errors.InvalidNetwork(operation.underlyingAssetNetworkId);
                }
                IPToken(pTokenAddress).stateManagedProtocolBurn(destinationAddress, operation.amount);
            }
        }

        if (operation.userData.length > 0) {
            /*
            try {
                (destinationAccount)._receiveUserData(userData)
            } catch() {}  
            */
        }

        operationData.status = Constants.OPERATION_EXECUTED;

        emit OperationExecuted(operation);
    }

    function protocolQueueOperation(Operation calldata operation) external {
        _queueOperation(_msgSender(), operation);
    }

    function _queueOperation(address relayer, Operation calldata operation) internal {
        bytes32 operationId = operationIdOf(operation);

        if (_operationsData[operationId].status != Constants.OPERATION_NULL) {
            revert Errors.OperationAlreadyQueued(operationId);
        }

        _operationsData[operationId] = OperationData(
            relayer,
            uint64(block.timestamp + queueTime),
            Constants.OPERATION_QUEUED
        );

        emit OperationQueued(operation);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPFactory
 * @author pNetwork
 *
 * @notice
 */
interface IPFactory {
    event PTokenDeployed(address pTokenAddress);

    function deploy(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external payable returns (address);

    function getBytecode(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (bytes memory);

    function getPTokenAddress(
        string memory underlyingAssetName,
        string memory underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId
    ) external view returns (address);

    function setRouter(address _router) external;

    function setStateManager(address _stateManager) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPRouter
 * @author pNetwork
 *
 * @notice
 */
interface IPRouter {
    event UserOperation(
        uint256 nonce,
        string destinationAccount,
        bytes4 destinationNetworkId,
        string underlyingAssetName,
        string underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        bytes userData,
        bytes32 optionsMask
    );

    function userSend(
        string calldata destinationAccount,
        bytes4 destinationNetworkId,
        string calldata underlyingAssetName,
        string calldata underlyingAssetSymbol,
        uint256 underlyingAssetDecimals,
        address underlyingAssetTokenAddress,
        bytes4 underlyingAssetNetworkId,
        address assetTokenAddress,
        uint256 assetAmount,
        bytes calldata userData,
        bytes32 optionsMask
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IPToken
 * @author pNetwork
 *
 * @notice
 */
interface IPToken {
    function routedUserMint(address account, uint256 amount) external;

    function routedUserMintAndBurn(address account, uint256 amount) external;

    function routedUserBurn(address account, uint256 amount) external;

    function stateManagedProtocolMint(address account, uint256 amount) external;

    function stateManagedProtocolBurn(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title IStateManager
 * @author pNetwork
 *
 * @notice
 */
interface IStateManager {
    struct Operation {
        bytes32 originBlockHash;
        bytes32 originTransactionHash;
        bytes32 optionsMask;
        uint256 nonce;
        uint256 underlyingAssetDecimals;
        uint256 amount;
        address underlyingAssetTokenAddress;
        bytes4 originNetworkId;
        bytes4 destinationNetworkId;
        bytes4 underlyingAssetNetworkId;
        string destinationAccount;
        string underlyingAssetName;
        string underlyingAssetSymbol;
        bytes userData;
    }

    struct OperationData {
        address relayer;
        uint64 executeTimestamp;
        bytes1 status;
    }

    event OperationQueued(Operation operation);

    event OperationExecuted(Operation operation);

    event OperationCancelled(Operation operation);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Constants {
    bytes1 public constant OPERATION_NULL = 0x00;
    bytes1 public constant OPERATION_QUEUED = 0x01;
    bytes1 public constant OPERATION_EXECUTED = 0x02;
    bytes1 public constant OPERATION_CANCELLED = 0x03;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Errors {
    error OperationAlreadyQueued(bytes32 operationId);
    error OperationAlreadyExecuted(bytes32 operationId);
    error OperationCancelled(bytes32 operationId);
    error OperationNotQueued(bytes32 operationId);
    error ExecuteTimestampNotReached(uint64 executeTimestamp);
    error InvalidUnderlyingAssetName(string underlyingAssetName, string expectedUnderlyingAssetName);
    error InvalidUnderlyingAssetSymbol(string underlyingAssetSymbol, string expectedUnderlyingAssetSymbol);
    error InvalidUnderlyingAssetDecimals(uint256 underlyingAssetDecimals, uint256 expectedUnderlyingAssetDecimals);
    error InvalidAssetParameters(uint256 assetAmount, address assetTokenAddress);
    error SenderIsNotRouter();
    error SenderIsNotStateManager();
    error InvalidUserOperation();
    error NoUserOperation();
    error PTokenNotCreated(address pTokenAddress);
    error InvalidNetwork(bytes4 networkId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Roles {
    bytes32 public constant UPGRADE_ROLE = keccak256("UPGRADE_ROLE");
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library Utils {
    function isCurrentNetwork(bytes4 networkId) internal view returns (bool) {
        uint256 currentchainId;
        assembly {
            currentchainId := chainid()
        }

        bytes1 version = 0x01;
        bytes1 networkType = 0x01;
        bytes1 extraData = 0x00;
        bytes4 currentNetworkId = bytes4(sha256(abi.encode(version, networkType, currentchainId, extraData)));
        return currentNetworkId == networkId;
    }

    function isBitSet(bytes32 b, uint pos) internal pure returns (bool) {
        return (bytes32(b) & bytes32(1 << (pos + 64))) != 0;
    }

    function normalizeAmount(uint256 amount, uint256 decimals, bool use) internal pure returns (uint256) {
        uint256 difference = (10 ** (18 - decimals));
        return use ? amount * difference : amount / difference;
    }

    function parseAddress(string memory addr) internal pure returns (address) {
        bytes memory tmp = bytes(addr);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }
}