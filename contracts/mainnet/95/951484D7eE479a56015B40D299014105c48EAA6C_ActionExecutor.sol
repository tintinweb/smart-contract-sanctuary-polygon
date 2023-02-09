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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IActionDataStructures } from './interfaces/IActionDataStructures.sol';
import { IGateway } from './crosschain/interfaces/IGateway.sol';
import { IGatewayClient } from './crosschain/interfaces/IGatewayClient.sol';
import { IRegistry } from './interfaces/IRegistry.sol';
import { ISettings } from './interfaces/ISettings.sol';
import { ITokenMint } from './interfaces/ITokenMint.sol';
import { IVariableBalanceRecords } from './interfaces/IVariableBalanceRecords.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { CallerGuard } from './CallerGuard.sol';
import { Pausable } from './Pausable.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TokenMintError, ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './helpers/GasReserveHelper.sol' as GasReserveHelper;
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

contract ActionExecutor is
    SystemVersionId,
    Pausable,
    ReentrancyGuard,
    CallerGuard,
    BalanceManagement,
    IGatewayClient,
    ISettings,
    IActionDataStructures
{
    IRegistry public registry;
    IVariableBalanceRecords public variableBalanceRecords;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    event ActionSource(
        uint256 indexed actionId,
        uint256 indexed targetChainId,
        address indexed sourceSender,
        address targetRecipient,
        uint256 gatewayType,
        address sourceToken,
        address targetToken,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    event ActionTarget(
        uint256 indexed actionId,
        uint256 indexed sourceChainId,
        bool indexed isSuccess,
        uint256 timestamp
    );

    event ActionLocal(
        uint256 indexed actionId,
        address indexed sender,
        address recipient,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 toTokenFee,
        uint256 timestamp
    );

    event SourceProcessed(
        uint256 indexed actionId,
        bool indexed isLocal,
        address indexed sender,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event TargetProcessed(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    event VariableBalanceAllocated(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 vaultType,
        uint256 amount
    );

    event SetRegistry(address indexed registryAddress);
    event SetVariableBalanceRecords(address indexed recordsAddress);

    error OnlyGatewayError();
    error OnlySelfError();

    error SameChainIdError();
    error SameTokenError();

    error GatewayNotSetError();
    error RouterNotSetError();
    error VaultNotSetError();

    error MessageFeeError();
    error SwapAmountMaxError();
    error SwapAmountMinError();
    error SwapError();
    error TargetSwapInfoError();

    modifier onlyGateway() {
        if (!registry.isGatewayAddress(msg.sender)) {
            revert OnlyGatewayError();
        }

        _;
    }

    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }

        _;
    }

    constructor(
        IRegistry _registry,
        IVariableBalanceRecords _variableBalanceRecords,
        uint256 _actionIdOffset,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setRegistry(_registry);
        _setVariableBalanceRecords(_variableBalanceRecords);

        lastActionId += _actionIdOffset;

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    receive() external payable {}

    fallback() external {}

    function setRegistry(IRegistry _registry) external onlyManager {
        _setRegistry(_registry);
    }

    function setVariableBalanceRecords(
        IVariableBalanceRecords _variableBalanceRecords
    ) external onlyManager {
        _setVariableBalanceRecords(_variableBalanceRecords);
    }

    function executeLocal(
        LocalAction calldata _localAction
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        if (_localAction.fromTokenAddress == _localAction.toTokenAddress) {
            revert SameTokenError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        LocalSettings memory settings = registry.localSettings(
            msg.sender,
            _localAction.swapInfo.routerType
        );

        (uint256 processedAmount, ) = _processSource(
            actionId,
            true,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo,
            settings.router,
            settings.routerTransfer
        );

        address recipient = _localAction.recipient == address(0)
            ? msg.sender
            : _localAction.recipient;

        uint256 recipientAmount = _calculateLocalAmount(
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(recipient, recipientAmount);
        } else {
            TransferHelper.safeTransfer(_localAction.toTokenAddress, recipient, recipientAmount);
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - recipientAmount;

        if (systemFeeAmount > 0) {
            address feeCollector = settings.feeCollectorLocal;

            if (feeCollector != address(0)) {
                if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                    TransferHelper.safeTransferNative(feeCollector, systemFeeAmount);
                } else {
                    TransferHelper.safeTransfer(
                        _localAction.toTokenAddress,
                        feeCollector,
                        systemFeeAmount
                    );
                }
            } else if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                initialBalance += systemFeeAmount; // Keep at the contract address
            }
        }

        // - - -

        // - - - Extra balance transfer - - -

        _transferExtraBalance(initialBalance);

        // - - -

        emit ActionLocal(
            actionId,
            msg.sender,
            recipient,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo.fromAmount,
            recipientAmount,
            systemFeeAmount,
            block.timestamp
        );
    }

    function execute(
        Action calldata _action
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        if (_action.targetChainId == block.chainid) {
            revert SameChainIdError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        SourceSettings memory settings = registry.sourceSettings(
            msg.sender,
            _action.targetChainId,
            _action.gatewayType,
            _action.sourceSwapInfo.routerType,
            _action.vaultType
        );

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        address vaultAsset = IVault(settings.vault).asset();

        (uint256 processedAmount, uint256 nativeTokenSpent) = _processSource(
            actionId,
            false,
            _action.sourceTokenAddress,
            vaultAsset,
            _action.sourceSwapInfo,
            settings.router,
            settings.routerTransfer
        );

        uint256 targetVaultAmountMax = _calculateVaultAmount(
            settings.sourceVaultDecimals,
            settings.targetVaultDecimals,
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength == 0) {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        } else {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;

                    break;
                }
            }

            if (targetSwapInfo.fromAmount == 0) {
                revert TargetSwapInfoError();
            }
        }

        uint256 sourceVaultAmount = DecimalsHelper.convertDecimals(
            settings.targetVaultDecimals,
            settings.sourceVaultDecimals,
            targetSwapInfo.fromAmount
        );

        uint256 normalizedAmount = DecimalsHelper.convertDecimals(
            settings.sourceVaultDecimals,
            Constants.DECIMALS_DEFAULT,
            sourceVaultAmount
        );

        if (!settings.isWhitelist) {
            _checkSwapAmountLimits(
                normalizedAmount,
                settings.swapAmountMin,
                settings.swapAmountMax
            );
        }

        // - - - Transfer to vault - - -

        TransferHelper.safeTransfer(vaultAsset, settings.vault, sourceVaultAmount);

        // - - -

        bytes memory targetMessageData = abi.encode(
            TargetMessage({
                actionId: actionId,
                sourceSender: msg.sender,
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: _action.targetRecipient == address(0)
                    ? msg.sender
                    : _action.targetRecipient
            })
        );

        _sendMessage(settings, _action, targetMessageData, msg.value - nativeTokenSpent);

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - sourceVaultAmount;

        if (systemFeeAmount > 0 && settings.feeCollector != address(0)) {
            TransferHelper.safeTransfer(vaultAsset, settings.feeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        _transferExtraBalance(initialBalance);

        // - - -

        _emitActionSourceEvent(
            actionId,
            _action,
            normalizedAmount,
            DecimalsHelper.convertDecimals(
                settings.sourceVaultDecimals,
                Constants.DECIMALS_DEFAULT,
                systemFeeAmount
            )
        );
    }

    function claimVariableToken(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, false);
    }

    function convertVariableBalanceToVaultAsset(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, true);
    }

    function messageFeeEstimate(
        uint256 _gatewayType,
        uint256 _targetChainId,
        bytes[] calldata _targetRouterDataOptions,
        bytes calldata _gatewaySettings
    ) external view returns (uint256) {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        MessageFeeEstimateSettings memory settings = registry.messageFeeEstimateSettings(
            _gatewayType
        );

        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 result = 0;

        if (_targetRouterDataOptions.length == 0) {
            result = IGateway(settings.gateway).messageFee(
                _targetChainId,
                _blankMessage(new bytes(0)),
                _gatewaySettings
            );
        } else {
            for (uint256 index; index < _targetRouterDataOptions.length; index++) {
                bytes memory messageData = _blankMessage(_targetRouterDataOptions[index]);

                uint256 value = IGateway(settings.gateway).messageFee(
                    _targetChainId,
                    messageData,
                    _gatewaySettings
                );

                if (value > result) {
                    result = value;
                }
            }
        }

        return result;
    }

    function calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        LocalAmountCalculationSettings memory settings = registry.localAmountCalculationSettings(
            msg.sender
        );

        return
            _calculateLocalAmount(
                _fromAmount,
                _isForward,
                settings.systemFee,
                settings.isWhitelist
            );
    }

    function calculateVaultAmount(
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        VaultAmountCalculationSettings memory settings = registry.vaultAmountCalculationSettings(
            msg.sender,
            _vaultType,
            _fromChainId,
            _toChainId
        );

        return
            _calculateVaultAmount(
                settings.fromDecimals,
                settings.toDecimals,
                _fromAmount,
                _isForward,
                settings.systemFee,
                settings.isWhitelist
            );
    }

    function variableBalance(address _account, uint256 _vaultType) public view returns (uint256) {
        return variableBalanceRecords.getAccountBalance(_account, _vaultType);
    }

    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external whenNotPaused onlyGateway {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        TargetSettings memory settings = registry.targetSettings(
            targetMessage.vaultType,
            targetMessage.targetSwapInfo.routerType
        );

        bool selfCallSuccess;

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            settings.gasReserve
        );

        if (hasGasReserve) {
            try this.selfCallTarget{ gas: gasAllowed }(settings, targetMessage) {
                selfCallSuccess = true;
            } catch {}
        }

        if (!selfCallSuccess) {
            _targetAllocateVariableBalance(targetMessage);
        }

        emit ActionTarget(
            targetMessage.actionId,
            _messageSourceChainId,
            selfCallSuccess,
            block.timestamp
        );
    }

    function selfCallTarget(
        TargetSettings calldata settings,
        TargetMessage calldata _targetMessage
    ) external onlySelf {
        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        // - - - Transfer from vault - - -

        address assetAddress = IVault(settings.vault).requestAsset(
            _targetMessage.targetSwapInfo.fromAmount,
            address(this),
            false
        );

        // - - -

        _processTarget(
            settings,
            _targetMessage.actionId,
            assetAddress,
            _targetMessage.targetTokenAddress,
            _targetMessage.targetSwapInfo,
            _targetMessage.targetRecipient
        );
    }

    function _processSource(
        uint256 _actionId,
        bool _isLocal,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _sourceSwapInfo,
        address _routerAddress,
        address _routerTransferAddress
    ) private returns (uint256 resultAmount, uint256 nativeTokenSpent) {
        uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

        if (_fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            if (_routerAddress == address(0)) {
                revert RouterNotSetError();
            }

            // - - - Source swap (native token) - - -

            (bool routerCallSuccess, ) = payable(_routerAddress).call{
                value: _sourceSwapInfo.fromAmount
            }(_sourceSwapInfo.routerData);

            if (!routerCallSuccess) {
                revert SwapError();
            }

            // - - -

            nativeTokenSpent = _sourceSwapInfo.fromAmount;
        } else {
            TransferHelper.safeTransferFrom(
                _fromTokenAddress,
                msg.sender,
                address(this),
                _sourceSwapInfo.fromAmount
            );

            if (_fromTokenAddress != _toTokenAddress) {
                if (_routerAddress == address(0)) {
                    revert RouterNotSetError();
                }

                // - - - Source swap (non-native token) - - -

                TransferHelper.safeApprove(
                    _fromTokenAddress,
                    _routerTransferAddress,
                    _sourceSwapInfo.fromAmount
                );

                (bool routerCallSuccess, ) = _routerAddress.call(_sourceSwapInfo.routerData);

                if (!routerCallSuccess) {
                    revert SwapError();
                }

                TransferHelper.safeApprove(_fromTokenAddress, _routerTransferAddress, 0);

                // - - -
            }

            nativeTokenSpent = 0;
        }

        resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;

        emit SourceProcessed(
            _actionId,
            _isLocal,
            msg.sender,
            _sourceSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _sourceSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _processTarget(
        TargetSettings memory settings,
        uint256 _actionId,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _targetSwapInfo,
        address _targetRecipient
    ) private {
        uint256 resultAmount;

        if (_toTokenAddress == _fromTokenAddress) {
            resultAmount = _targetSwapInfo.fromAmount;
        } else {
            if (settings.router == address(0)) {
                revert RouterNotSetError();
            }

            uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

            // - - - Target swap - - -

            TransferHelper.safeApprove(
                _fromTokenAddress,
                settings.routerTransfer,
                _targetSwapInfo.fromAmount
            );

            (bool success, ) = settings.router.call(_targetSwapInfo.routerData);

            if (!success) {
                revert SwapError();
            }

            TransferHelper.safeApprove(_fromTokenAddress, settings.routerTransfer, 0);

            // - - -

            resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;
        }

        if (_toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(_targetRecipient, resultAmount);
        } else {
            TransferHelper.safeTransfer(_toTokenAddress, _targetRecipient, resultAmount);
        }

        emit TargetProcessed(
            _actionId,
            _targetRecipient,
            _targetSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _targetSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _targetAllocateVariableBalance(TargetMessage memory _targetMessage) private {
        address tokenRecipient = _targetMessage.targetRecipient;
        uint256 vaultType = _targetMessage.vaultType;
        uint256 tokenAmount = _targetMessage.targetSwapInfo.fromAmount;

        variableBalanceRecords.increaseBalance(tokenRecipient, vaultType, tokenAmount);

        emit VariableBalanceAllocated(
            _targetMessage.actionId,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _processVariableBalanceRepayment(
        uint256 _vaultType,
        bool _convertToVaultAsset
    ) private {
        VariableBalanceRepaymentSettings memory settings = registry
            .variableBalanceRepaymentSettings(_vaultType);

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        uint256 tokenAmount = variableBalanceRecords.getAccountBalance(msg.sender, _vaultType);

        variableBalanceRecords.clearBalance(msg.sender, _vaultType);

        if (tokenAmount > 0) {
            if (_convertToVaultAsset) {
                IVault(settings.vault).requestAsset(tokenAmount, msg.sender, true);
            } else {
                address variableTokenAddress = IVault(settings.vault).checkVariableTokenState();

                bool mintSuccess = ITokenMint(variableTokenAddress).mint(msg.sender, tokenAmount);

                if (!mintSuccess) {
                    revert TokenMintError();
                }
            }
        }
    }

    function _setRegistry(IRegistry _registry) private {
        AddressHelper.requireContract(address(_registry));

        registry = _registry;

        emit SetRegistry(address(_registry));
    }

    function _setVariableBalanceRecords(IVariableBalanceRecords _variableBalanceRecords) private {
        AddressHelper.requireContract(address(_variableBalanceRecords));

        variableBalanceRecords = _variableBalanceRecords;

        emit SetVariableBalanceRecords(address(_variableBalanceRecords));
    }

    function _sendMessage(
        SourceSettings memory settings,
        Action calldata _action,
        bytes memory _messageData,
        uint256 _availableValue
    ) private {
        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 messageFee = IGateway(settings.gateway).messageFee(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );

        if (_availableValue < messageFee) {
            revert MessageFeeError();
        }

        IGateway(settings.gateway).sendMessage{ value: messageFee }(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );
    }

    function _transferExtraBalance(uint256 _initialBalance) private {
        uint256 extraBalance = address(this).balance - _initialBalance;

        if (extraBalance > 0) {
            TransferHelper.safeTransferNative(msg.sender, extraBalance);
        }
    }

    function _emitActionSourceEvent(
        uint256 _actionId,
        Action calldata _action,
        uint256 _amount,
        uint256 _fee
    ) private {
        emit ActionSource(
            _actionId,
            _action.targetChainId,
            msg.sender,
            _action.targetRecipient,
            _action.gatewayType,
            _action.sourceTokenAddress,
            _action.targetTokenAddress,
            _amount,
            _fee,
            block.timestamp
        );
    }

    function _checkSwapAmountLimits(
        uint256 _normalizedAmount,
        uint256 _swapAmountMin,
        uint256 _swapAmountMax
    ) private pure {
        if (_normalizedAmount < _swapAmountMin) {
            revert SwapAmountMinError();
        }

        if (_normalizedAmount > _swapAmountMax) {
            revert SwapAmountMaxError();
        }
    }

    function _calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        if (_isWhitelist || _systemFee == 0) {
            return _fromAmount;
        }

        return
            _isForward
                ? (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFee)) /
                    Constants.MILLIPERCENT_FACTOR
                : (_fromAmount * Constants.MILLIPERCENT_FACTOR) /
                    (Constants.MILLIPERCENT_FACTOR - _systemFee);
    }

    function _calculateVaultAmount(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        bool isZeroFee = _isWhitelist || _systemFee == 0;

        uint256 amountToConvert = (!_isForward || isZeroFee)
            ? _fromAmount
            : (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFee)) /
                Constants.MILLIPERCENT_FACTOR;

        uint256 convertedAmount = DecimalsHelper.convertDecimals(
            _fromDecimals,
            _toDecimals,
            amountToConvert
        );

        result = (_isForward || isZeroFee)
            ? convertedAmount
            : (convertedAmount * Constants.MILLIPERCENT_FACTOR) /
                (Constants.MILLIPERCENT_FACTOR - _systemFee);
    }

    function _blankMessage(bytes memory _targetRouterData) private pure returns (bytes memory) {
        bytes memory messageData = abi.encode(
            TargetMessage({
                actionId: uint256(0),
                sourceSender: address(0),
                vaultType: uint256(0),
                targetTokenAddress: address(0),
                targetSwapInfo: SwapInfo({
                    fromAmount: uint256(0),
                    routerType: uint256(0),
                    routerData: _targetRouterData
                }),
                targetRecipient: address(0)
            })
        );

        return messageData;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

abstract contract BalanceManagement is ManagerRole {
    error ReservedTokenError();

    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    function isReservedToken(address /*_tokenAddress*/) public view virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './DataStructures.sol' as DataStructures;

abstract contract CallerGuard is ManagerRole {
    enum CallerGuardMode {
        ContractForbidden,
        ContractList,
        ContractAllowed
    }

    CallerGuardMode public callerGuardMode = CallerGuardMode.ContractForbidden;

    address[] public listedCallerGuardContractList;
    mapping(address => DataStructures.OptionalValue) public listedCallerGuardContractIndexMap;

    event SetCallerGuardMode(CallerGuardMode indexed callerMode);
    event SetListedCallerGuardContract(address indexed contractAddress, bool indexed isListed);

    error CallerGuardError(address caller);

    modifier checkCaller() {
        if (msg.sender != tx.origin) {
            bool condition = (callerGuardMode == CallerGuardMode.ContractAllowed ||
                (callerGuardMode == CallerGuardMode.ContractList &&
                    isListedCallerGuardContract(msg.sender)));

            if (!condition) {
                revert CallerGuardError(msg.sender);
            }
        }

        _;
    }

    function setCallerGuardMode(CallerGuardMode _callerGuardMode) external onlyManager {
        callerGuardMode = _callerGuardMode;

        emit SetCallerGuardMode(_callerGuardMode);
    }

    function setListedCallerGuardContracts(
        DataStructures.AccountToFlag[] calldata _items
    ) external onlyManager {
        for (uint256 index; index < _items.length; index++) {
            DataStructures.AccountToFlag calldata item = _items[index];

            if (item.flag) {
                AddressHelper.requireContract(item.account);
            }

            DataStructures.uniqueAddressListUpdate(
                listedCallerGuardContractList,
                listedCallerGuardContractIndexMap,
                item.account,
                item.flag
            );

            emit SetListedCallerGuardContract(item.account, item.flag);
        }
    }

    function listedCallerGuardContractCount() public view returns (uint256) {
        return listedCallerGuardContractList.length;
    }

    function fullListedCallerGuardContractList() public view returns (address[] memory) {
        return listedCallerGuardContractList;
    }

    function isListedCallerGuardContract(address _account) public view returns (bool) {
        return listedCallerGuardContractIndexMap[_account].isSet;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

uint256 constant DECIMALS_DEFAULT = 18;
uint256 constant INFINITY = type(uint256).max;
uint256 constant MILLIPERCENT_FACTOR = 100_000;
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IGateway {
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable;

    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IGatewayClient {
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

struct OptionalValue {
    bool isSet;
    uint256 value;
}

struct KeyToValue {
    uint256 key;
    uint256 value;
}

struct KeyToAddressValue {
    uint256 key;
    address value;
}

struct AccountToFlag {
    address account;
    bool flag;
}

function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key);
    }

    _map[_key] = _value;
}

function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error TokenBurnError();
error TokenMintError();
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error NonContractAddressError(address account);

function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

function convertDecimals(
    uint256 _fromDecimals,
    uint256 _toDecimals,
    uint256 _fromAmount
) pure returns (uint256) {
    if (_toDecimals == _fromDecimals) {
        return _fromAmount;
    } else if (_toDecimals > _fromDecimals) {
        return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
    } else {
        return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

function checkGasReserve(
    uint256 _gasReserve
) view returns (bool hasGasReserve, uint256 gasAllowed) {
    uint256 gasLeft = gasleft();

    hasGasReserve = gasLeft >= _gasReserve;
    gasAllowed = hasGasReserve ? gasLeft - _gasReserve : 0;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

error SafeApproveError();
error SafeTransferError();
error SafeTransferFromError();
error SafeTransferNativeError();

function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IActionDataStructures {
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
        bytes gatewaySettings;
    }

    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { ISettings } from './ISettings.sol';

interface IRegistry is ISettings {
    function isGatewayAddress(address _account) external view returns (bool);

    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory);

    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory);

    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory);

    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory);

    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory);

    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory);

    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory);

    function swapAmountLimits(
        uint256 _vaultType
    ) external view returns (uint256 swapAmountMin, uint256 swapAmountMax);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ISettings {
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFee;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    struct MessageFeeEstimateSettings {
        address gateway;
    }

    struct LocalAmountCalculationSettings {
        uint256 systemFee;
        bool isWhitelist;
    }

    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenBalance {
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface ITokenMint {
    function mint(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IVariableBalanceRecords {
    function increaseBalance(address _tokenRecipient, uint256 _vaultType, uint256 _amount) external;

    function clearBalance(address _tokenRecipient, uint256 _vaultType) external;

    function getAccountBalance(
        address _account,
        uint256 _vaultType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

interface IVault {
    function asset() external view returns (address);

    function checkVariableTokenState() external view returns (address);

    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external returns (address assetAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

abstract contract Pausable is PausableBase, ManagerRole {
    function pause() public onlyManager whenNotPaused {
        _pause();
    }

    function unpause() public onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    event SetManager(address indexed account, bool indexed value);
    event RenounceManagerRole(address indexed account);

    error OnlyManagerError();

    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    function renounceManagerRole() public onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function managerCount() public view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    function fullManagerList() public view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

import '../DataStructures.sol' as DataStructures;

abstract contract RoleBearers {
    mapping(bytes32 => address[]) private roleBearerTable;
    mapping(bytes32 => mapping(address => DataStructures.OptionalValue))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.17;

abstract contract SystemVersionId {
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('Test 2023-02-09 A'));
}