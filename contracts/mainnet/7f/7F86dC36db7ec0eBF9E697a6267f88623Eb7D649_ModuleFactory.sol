// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "RevokeModule.sol";
import "AaveWithdrawModule.sol";
import "UniswapWithdrawModule.sol";

import "ISafe.sol";

/// @title   ModuleFactory
/// @dev  Allows deploying easily a module targeting a specific safe environment
contract ModuleFactory {
    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error NoSupportedModuleType(ModuleType moduleType, address deployer);

    error NotSigner(address safe, address executor);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event ModuleDeployed(
        address module,
        ModuleType moduleType,
        address deployer,
        uint256 timestamp
    );

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////

    enum ModuleType {
        REVOKE_MODULE,
        AAVE_WITHDRAW,
        UNISWAP_WITHDRAW
    }

    /// @dev Given a specific enum value will deploy different module
    /// @notice Deploys a new module
    /// @param safe target safe contract which the module is targeting
    /// @param modType identifier of the module to be deployed
    function createModuleAndEnable(ISafe safe, ModuleType modType) external {
        if (modType == ModuleType.REVOKE_MODULE) {
            RevokeModule module = new RevokeModule(safe);
            emit ModuleDeployed(
                address(module),
                ModuleType.REVOKE_MODULE,
                msg.sender,
                block.timestamp
            );
        } else if (modType == ModuleType.AAVE_WITHDRAW) {
            AaveWithdrawModule module = new AaveWithdrawModule(safe);
            emit ModuleDeployed(
                address(module),
                ModuleType.AAVE_WITHDRAW,
                msg.sender,
                block.timestamp
            );
        } else if (modType == ModuleType.UNISWAP_WITHDRAW) {
            UniswapWithdrawModule module = new UniswapWithdrawModule(safe);
            emit ModuleDeployed(
                address(module),
                ModuleType.UNISWAP_WITHDRAW,
                msg.sender,
                block.timestamp
            );
        } else {
            revert NoSupportedModuleType(modType, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";
import "ISafe.sol";
import "INotification.sol";

import {BaseModule} from "BaseModule.sol";

contract RevokeModule is BaseModule {
    ////////////////////////////////////////////////////////////////////////////
    // INMUTABLE VARIABLES
    ////////////////////////////////////////////////////////////////////////////
    ISafe public immutable safe;

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event Revoked(
        address safe,
        address token,
        address spender,
        address signer,
        uint256 timestamp
    );

    constructor(ISafe _safe) {
        safe = ISafe(_safe);
    }

    /// @notice sets allowance to zero for specific token and spender
    /// @param token token address which we will trigger the revoking
    /// @param spender address which allowance is going to be set to zero
    function revoke(address token, address spender) external isSigner(safe) {
        if (!safe.isModuleEnabled(address(this))) revert ModuleMisconfigured();

        uint256 allowanceAmount = IERC20(token).allowance(
            address(safe),
            spender
        );
        if (allowanceAmount > 0) {
            _checkTransactionAndExecute(
                safe,
                token,
                abi.encodeCall(IERC20.approve, (spender, 0))
            );
            emit Revoked(
                address(safe),
                token,
                spender,
                msg.sender,
                block.timestamp
            );
            _sendPushNotification(token, spender);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @dev internal method to facilitate push notification to our channel
    /// @param token address of the token we trigger the revoke against
    /// @param spender address against we set the allowance to zero
    function _sendPushNotification(address token, address spender) internal {
        bytes memory message = bytes(
            string(
                abi.encodePacked(
                    "0",
                    "+",
                    "3",
                    "+",
                    "Emergency Token Revoke",
                    "+",
                    "Withdraw from token ",
                    addressToString(token),
                    "revoke allowance from spender ",
                    addressToString(spender)
                )
            )
        );
        _checkTransactionAndExecute(
            safe,
            PUSH_COMM,
            abi.encodeCall(
                INotification.sendNotification,
                (address(safe), address(safe), message)
            )
        );
    }
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

// SPDX-License-Identifier: LGPL-3.0-only
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. !!
pragma solidity >=0.7.0 <0.9.0;

interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    event AddedOwner(address indexed owner);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event ChangedFallbackHandler(address indexed handler);
    event ChangedGuard(address indexed guard);
    event ChangedThreshold(uint256 threshold);
    event DisabledModule(address indexed module);
    event EnabledModule(address indexed module);
    event ExecutionFailure(bytes32 indexed txHash, uint256 payment);
    event ExecutionFromModuleFailure(address indexed module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionSuccess(bytes32 indexed txHash, uint256 payment);
    event RemovedOwner(address indexed owner);
    event SafeReceived(address indexed sender, uint256 value);
    event SafeSetup(
        address indexed initiator,
        address[] owners,
        uint256 threshold,
        address initializer,
        address fallbackHandler
    );
    event SignMsg(bytes32 indexed msgHash);

    fallback() external;

    function VERSION() external view returns (string memory);

    function addOwnerWithThreshold(address owner, uint256 _threshold) external;

    function approveHash(bytes32 hashToApprove) external;

    function approvedHashes(address, bytes32) external view returns (uint256);

    function changeThreshold(uint256 _threshold) external;

    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) external view;

    function disableModule(address prevModule, address module) external;

    function domainSeparator() external view returns (bytes32);

    function enableModule(address module) external;

    function encodeTransactionData(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes memory);

    function execTransaction(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success);

    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success, bytes memory returnData);

    function getChainId() external view returns (uint256);

    function getModulesPaginated(
        address start,
        uint256 pageSize
    ) external view returns (address[] memory array, address next);

    function getOwners() external view returns (address[] memory);

    function getStorageAt(
        uint256 offset,
        uint256 length
    ) external view returns (bytes memory);

    function getThreshold() external view returns (uint256);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes memory data,
        uint8 operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function isModuleEnabled(address module) external view returns (bool);

    function isOwner(address owner) external view returns (bool);

    function nonce() external view returns (uint256);

    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) external;

    function setFallbackHandler(address handler) external;

    function setGuard(address guard) external;

    function setup(
        address[] memory _owners,
        uint256 _threshold,
        address to,
        bytes memory data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address paymentReceiver
    ) external;

    function signedMessages(bytes32) external view returns (uint256);

    function simulateAndRevert(
        address targetContract,
        bytes memory calldataPayload
    ) external;

    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INotification {
    event AddDelegate(address channel, address delegate);
    event ChannelAlias(
        string _chainName,
        uint256 indexed _chainID,
        address indexed _channelOwnerAddress,
        string _ethereumChannelAddress
    );
    event PublicKeyRegistered(address indexed owner, bytes publickey);
    event RemoveDelegate(address channel, address delegate);
    event SendNotification(
        address indexed channel,
        address indexed recipient,
        bytes identity
    );
    event Subscribe(address indexed channel, address indexed user);
    event Unsubscribe(address indexed channel, address indexed user);
    event UserNotifcationSettingsAdded(
        address _channel,
        address _user,
        uint256 _notifID,
        string _notifSettings
    );

    function DOMAIN_TYPEHASH() external view returns (bytes32);

    function EPNSCoreAddress() external view returns (address);

    function NAME_HASH() external view returns (bytes32);

    function SEND_NOTIFICATION_TYPEHASH() external view returns (bytes32);

    function SUBSCRIBE_TYPEHASH() external view returns (bytes32);

    function UNSUBSCRIBE_TYPEHASH() external view returns (bytes32);

    function addDelegate(address _delegate) external;

    function batchSubscribe(address[] memory _channelList)
        external
        returns (bool);

    function batchUnsubscribe(address[] memory _channelList)
        external
        returns (bool);

    function broadcastUserPublicKey(bytes memory _publicKey) external;

    function chainID() external view returns (uint256);

    function chainName() external view returns (string memory);

    function changeUserChannelSettings(
        address _channel,
        uint256 _notifID,
        string memory _notifSettings
    ) external;

    function completeMigration() external;

    function delegatedNotificationSenders(address, address)
        external
        view
        returns (bool);

    function getWalletFromPublicKey(bytes memory _publicKey)
        external
        pure
        returns (address wallet);

    function governance() external view returns (address);

    function initialize(address _pushChannelAdmin, string memory _chainName)
        external
        returns (bool);

    function isMigrationComplete() external view returns (bool);

    function isUserSubscribed(address _channel, address _user)
        external
        view
        returns (bool);

    function mapAddressUsers(uint256) external view returns (address);

    function migrateSubscribeData(
        uint256 _startIndex,
        uint256 _endIndex,
        address[] memory _channelList,
        address[] memory _usersList
    ) external returns (bool);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function pushChannelAdmin() external view returns (address);

    function removeDelegate(address _delegate) external;

    function sendNotifBySig(
        address _channel,
        address _recipient,
        address _signer,
        bytes memory _identity,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function sendNotification(
        address _channel,
        address _recipient,
        bytes memory _identity
    ) external returns (bool);

    function setEPNSCoreAddress(address _coreAddress) external;

    function setGovernanceAddress(address _governanceAddress) external;

    function subscribe(address _channel) external returns (bool);

    function subscribeBySig(
        address channel,
        address subscriber,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function subscribeViaCore(address _channel, address _user)
        external
        returns (bool);

    function transferPushChannelAdminControl(address _newAdmin) external;

    function unSubscribeViaCore(address _channel, address _user)
        external
        returns (bool);

    function unsubscribe(address _channel) external returns (bool);

    function unsubscribeBySig(
        address channel,
        address subscriber,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function userToChannelNotifs(address, address)
        external
        view
        returns (string memory);

    function users(address)
        external
        view
        returns (
            bool userActivated,
            bool publicKeyRegistered,
            uint256 userStartBlock,
            uint256 subscribedCount
        );

    function usersCount() external view returns (uint256);

    function verifyChannelAlias(string memory _channelAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ISafe.sol";

contract BaseModule {
    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////
    address internal constant PUSH_COMM =
        0xb3971BCef2D791bc4027BbfedFb47319A4AAaaAa;

    // https://docs.gelato.network/developer-services/relay/quick-start/erc-2771#3.-re-deploy-your-contract-and-whitelist-gelatorelayerc2771
    address internal GELATO_TRUSTED_FORWARDED =
        0xaBcC9b596420A9E9172FD5938620E265a0f9Df92;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error ExecutionFailure(address to, bytes data, uint256 timestamp);

    error ModuleMisconfigured();

    error NotSigner(address safe, address executor);

    error NotTrustedForwarded(address forwarded);

    ////////////////////////////////////////////////////////////////////////////
    // MODIFIER
    ////////////////////////////////////////////////////////////////////////////

    modifier isSigner(ISafe safe) {
        address[] memory signers = safe.getOwners();
        bool isOwner;
        for (uint256 i; i < signers.length; i++) {
            if (
                signers[i] == msg.sender ||
                GELATO_TRUSTED_FORWARDED == msg.sender
            ) {
                isOwner = true;
                break;
            }
        }
        if (!isOwner) revert NotSigner(address(safe), msg.sender);
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    function _checkTransactionAndExecute(
        ISafe safe,
        address to,
        bytes memory data
    ) internal {
        if (data.length >= 4) {
            bool success = safe.execTransactionFromModule(
                to,
                0,
                data,
                ISafe.Operation.Call
            );
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
        }
    }

    /// @notice Allows executing specific calldata into an address thru a gnosis-safe, which have enable this contract as module.
    /// @param to Contract address where we will execute the calldata.
    /// @param data Calldata to be executed within the boundaries of the `allowedFunctions`.
    /// @return bytes data containing the return data from the method in `to` with the payload `data`
    function _checkTransactionAndExecuteReturningData(
        ISafe safe,
        address to,
        bytes memory data
    ) internal returns (bytes memory) {
        if (data.length >= 4) {
            (bool success, bytes memory returnData) = safe
                .execTransactionFromModuleReturnData(
                    to,
                    0,
                    data,
                    ISafe.Operation.Call
                );
            if (!success) revert ExecutionFailure(to, data, block.timestamp);
            return returnData;
        }
    }

    /// @dev Helper function to convert address to string
    function addressToString(
        address _address
    ) internal pure returns (string memory) {
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";
import "ISafe.sol";
import {DataTypes, IAaveV3Pool} from "IAaveV3Pool.sol";
import "IAToken.sol";
import "INotification.sol";

import {BaseModule} from "BaseModule.sol";

contract AaveWithdrawModule is BaseModule {
    ////////////////////////////////////////////////////////////////////////////
    // INMUTABLE VARIABLES
    ////////////////////////////////////////////////////////////////////////////
    ISafe public immutable safe;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////

    IAaveV3Pool AAVE_POOL =
        IAaveV3Pool(0x7b5C526B7F8dfdff278b4a3e045083FBA4028790);

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error CollateralNotSupported(
        address collateral,
        address signer,
        uint256 timestamp
    );

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event EmergencyWithdraw(
        address asset,
        uint256 amount,
        address signer,
        uint256 timestamp
    );

    constructor(ISafe _safe) {
        safe = ISafe(_safe);
    }

    /// @notice signers can call withdraw as a 1/n signers. Used in emergencies
    /// @param collateral address of the collateral that the safe owners had deposit into AaveV3
    function aaveV3Withdraw(address collateral) external isSigner(safe) {
        if (!safe.isModuleEnabled(address(this))) revert ModuleMisconfigured();

        DataTypes.ReserveData memory reserveData = AAVE_POOL.getReserveData(
            collateral
        );

        address aTokenAddress = reserveData.aTokenAddress;
        if (aTokenAddress == address(0))
            revert CollateralNotSupported(
                collateral,
                msg.sender,
                block.timestamp
            );

        uint256 collateralBal = IAToken(aTokenAddress).balanceOf(address(safe));
        if (collateralBal > 0) {
            _checkTransactionAndExecute(
                safe,
                address(AAVE_POOL),
                abi.encodeCall(
                    IAaveV3Pool.withdraw,
                    (collateral, type(uint256).max, address(safe))
                )
            );
            emit EmergencyWithdraw(
                collateral,
                collateralBal,
                msg.sender,
                block.timestamp
            );
            _sendPushNotification(aTokenAddress);
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @dev internal method to facilitate push notification to our channel
    /// @param _aTokenAddress address of the aToken which we withdraw from
    function _sendPushNotification(address _aTokenAddress) internal {
        bytes memory message = bytes(
            string(
                abi.encodePacked(
                    "0",
                    "+",
                    "3",
                    "+",
                    "Emergency Aave Withdrawal",
                    "+",
                    "Withdraw from aToken ",
                    addressToString(_aTokenAddress)
                )
            )
        );
        _checkTransactionAndExecute(
            safe,
            PUSH_COMM,
            abi.encodeCall(
                INotification.sendNotification,
                (address(safe), address(safe), message)
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAaveV3Pool {
    event BackUnbacked(
        address indexed reserve,
        address indexed backer,
        uint256 amount,
        uint256 fee
    );
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint8 interestRateMode,
        uint256 borrowRate,
        uint16 indexed referralCode
    );
    event FlashLoan(
        address indexed target,
        address initiator,
        address indexed asset,
        uint256 amount,
        uint8 interestRateMode,
        uint256 premium,
        uint16 indexed referralCode
    );
    event IsolationModeTotalDebtUpdated(
        address indexed asset,
        uint256 totalDebt
    );
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );
    event MintUnbacked(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event MintedToTreasury(address indexed reserve, uint256 amountMinted);
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount,
        bool useATokens
    );
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event Supply(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referralCode
    );
    event SwapBorrowRateMode(
        address indexed reserve,
        address indexed user,
        uint8 interestRateMode
    );
    event UserEModeSet(address indexed user, uint8 categoryId);
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    function ADDRESSES_PROVIDER() external view returns (address);

    function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint128);

    function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint128);

    function MAX_NUMBER_RESERVES() external view returns (uint16);

    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    function POOL_REVISION() external view returns (uint256);

    function backUnbacked(
        address asset,
        uint256 amount,
        uint256 fee
    ) external returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function configureEModeCategory(
        uint8 id,
        DataTypes.EModeCategory memory category
    ) external;

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function dropReserve(address asset) external;

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory interestRateModes,
        address onBehalfOf,
        bytes memory params,
        uint16 referralCode
    ) external;

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params,
        uint16 referralCode
    ) external;

    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function getEModeCategoryData(uint8 id)
        external
        view
        returns (DataTypes.EModeCategory memory);

    function getReserveAddressById(uint16 id) external view returns (address);

    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    function getReservesList() external view returns (address[] memory);

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function getUserEMode(address user) external view returns (uint256);

    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function initialize(address provider) external;

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function mintToTreasury(address[] memory assets) external;

    function mintUnbacked(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function rebalanceStableBorrowRate(address asset, address user) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf
    ) external returns (uint256);

    function repayWithATokens(
        address asset,
        uint256 amount,
        uint256 interestRateMode
    ) external returns (uint256);

    function repayWithPermit(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        address onBehalfOf,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256);

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    function resetIsolationModeTotalDebt(address asset) external;

    function setConfiguration(
        address asset,
        DataTypes.ReserveConfigurationMap memory configuration
    ) external;

    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    function setUserEMode(uint8 categoryId) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function supplyWithPermit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function swapBorrowRateMode(address asset, uint256 interestRateMode)
        external;

    function updateBridgeProtocolFee(uint256 protocolFee) external;

    function updateFlashloanPremiums(
        uint128 flashLoanPremiumTotal,
        uint128 flashLoanPremiumToProtocol
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface DataTypes {
    struct EModeCategory {
        uint16 ltv;
        uint16 liquidationThreshold;
        uint16 liquidationBonus;
        address priceSource;
        string label;
    }

    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 currentLiquidityRate;
        uint128 variableBorrowIndex;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        uint16 id;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint128 accruedToTreasury;
        uint128 unbacked;
        uint128 isolationModeTotalDebt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IAToken {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event BalanceTransfer(
        address indexed from,
        address indexed to,
        uint256 value,
        uint256 index
    );
    event Burn(
        address indexed from,
        address indexed target,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );
    event Initialized(
        address indexed underlyingAsset,
        address indexed pool,
        address treasury,
        address incentivesController,
        uint8 aTokenDecimals,
        string aTokenName,
        string aTokenSymbol,
        bytes params
    );
    event Mint(
        address indexed caller,
        address indexed onBehalfOf,
        uint256 value,
        uint256 balanceIncrease,
        uint256 index
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function ATOKEN_REVISION() external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function EIP712_REVISION() external view returns (bytes memory);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function POOL() external view returns (address);

    function RESERVE_TREASURY_ADDRESS() external view returns (address);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function burn(
        address from,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function getIncentivesController() external view returns (address);

    function getPreviousIndex(address user) external view returns (uint256);

    function getScaledUserBalanceAndSupply(address user)
        external
        view
        returns (uint256, uint256);

    function handleRepayment(
        address user,
        address onBehalfOf,
        uint256 amount
    ) external;

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function initialize(
        address initializingPool,
        address treasury,
        address underlyingAsset,
        address incentivesController,
        uint8 aTokenDecimals,
        string memory aTokenName,
        string memory aTokenSymbol,
        bytes memory params
    ) external;

    function mint(
        address caller,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    function mintToTreasury(uint256 amount, uint256 index) external;

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function rescueTokens(
        address token,
        address to,
        uint256 amount
    ) external;

    function scaledBalanceOf(address user) external view returns (uint256);

    function scaledTotalSupply() external view returns (uint256);

    function setIncentivesController(address controller) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    function transferUnderlyingTo(address target, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "IERC20.sol";
import "ISafe.sol";
import {IUniswapV2Router02} from "IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "IUniswapV2Pair.sol";
import {IWETH9} from "IWETH9.sol";
import {BaseModule} from "BaseModule.sol";
import "INotification.sol";

contract UniswapWithdrawModule is BaseModule {
    ////////////////////////////////////////////////////////////////////////////
    // INMUTABLE VARIABLES
    ////////////////////////////////////////////////////////////////////////////
    ISafe public immutable safe;

    ////////////////////////////////////////////////////////////////////////////
    // CONSTANTS
    ////////////////////////////////////////////////////////////////////////////

    IUniswapV2Router02 internal constant UNIV2_ROUTER2 =
        IUniswapV2Router02(payable(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D));
    IWETH9 internal constant WETH =
        IWETH9(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6);

    uint256 MAX_BPS = 10_000;
    uint256 SLIPPAGE_BPS = 50;

    ////////////////////////////////////////////////////////////////////////////
    // ERRORS
    ////////////////////////////////////////////////////////////////////////////

    error LpNotSupported(address lp, address signer, uint256 timestamp);
    error ZeroBalance(address token, address signer, uint256 timestamp);

    ////////////////////////////////////////////////////////////////////////////
    // EVENTS
    ////////////////////////////////////////////////////////////////////////////

    event EmergencyWithdraw(
        address asset,
        uint256 amount,
        address signer,
        uint256 timestamp
    );

    constructor(ISafe _safe) {
        safe = ISafe(_safe);
    }

    function uniswapV2Withdraw(address lp) external isSigner(safe) {
        // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02#removeliquidity
        IUniswapV2Pair ULP = IUniswapV2Pair(lp);
        address token0 = ULP.token0();
        address token1 = ULP.token1();

        if ((token0 == address(0)) || (token1 == address(0))) {
            revert LpNotSupported(lp, msg.sender, block.timestamp);
        }

        // TODO: see L99
        // uint256 wethBefore = WETH.balanceOf(address(safe));

        // assume withdrawal of total balance
        uint256 ulpAmount = ULP.balanceOf(address(safe));

        if (ulpAmount == 0) {
            revert ZeroBalance(lp, msg.sender, block.timestamp);
        }

        (uint256 reserves0, uint256 reserves1, ) = ULP.getReserves();
        uint256 expectedAsset0 = (reserves0 * ulpAmount) / ULP.totalSupply();
        uint256 expectedAsset1 = (reserves1 * ulpAmount) / ULP.totalSupply();

        _checkTransactionAndExecute(
            safe,
            address(ULP),
            abi.encodeCall(
                IUniswapV2Pair.approve,
                (address(UNIV2_ROUTER2), ulpAmount)
            )
        );
        _checkTransactionAndExecute(
            safe,
            address(UNIV2_ROUTER2),
            abi.encodeCall(
                IUniswapV2Router02.removeLiquidity,
                (
                    token0,
                    token1,
                    ulpAmount,
                    (expectedAsset0 * (MAX_BPS - SLIPPAGE_BPS)) / MAX_BPS,
                    (expectedAsset1 * (MAX_BPS - SLIPPAGE_BPS)) / MAX_BPS,
                    address(safe),
                    block.timestamp
                )
            )
        );
        // TODO: gnosis safe has bugged fallback
        // uint256 wethAfter = WETH.balanceOf(address(safe));
        // if (wethAfter > wethBefore) {
        //     _checkTransactionAndExecute(
        //         safe,
        //         address(WETH),
        //         abi.encodeCall(IWETH9.withdraw, wethAfter - wethBefore)
        //     );
        // }
        emit EmergencyWithdraw(lp, ulpAmount, msg.sender, block.timestamp);
        _sendPushNotification(lp);
    }

    ////////////////////////////////////////////////////////////////////////////
    // INTERNAL
    ////////////////////////////////////////////////////////////////////////////

    /// @dev internal method to facilitate push notification to our channel
    /// @param _lp address of the uniswap lp which we withdraw from
    function _sendPushNotification(address _lp) internal {
        bytes memory message = bytes(
            string(
                abi.encodePacked(
                    "0",
                    "+",
                    "3",
                    "+",
                    "Emergency Uniswap Withdrawal",
                    "+",
                    "Withdraw from LP ",
                    addressToString(_lp)
                )
            )
        );
        _checkTransactionAndExecute(
            safe,
            PUSH_COMM,
            abi.encodeCall(
                INotification.sendNotification,
                (address(safe), address(safe), message)
            )
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.6;

interface IUniswapV2Router02 {
    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function factory() external view returns (address);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    receive() external payable;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.16;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function MINIMUM_LIQUIDITY() external view returns (uint256);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function decimals() external view returns (uint8);

    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );

    function initialize(address _token0, address _token1) external;

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function skim(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function symbol() external view returns (string memory);

    function sync() external;

    function token0() external view returns (address);

    function token1() external view returns (address);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.19;

interface IWETH9 {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    // function() external payable;
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
}