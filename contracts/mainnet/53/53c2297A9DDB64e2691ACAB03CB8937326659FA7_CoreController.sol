// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib dependencies */
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
/* models */
import { VaultModel } from "../common/model/VaultModel.sol";
import { AccountModel } from "../common/model/AccountModel.sol";
/* interfaces */
import { IPriceOracle } from "../common/interface/IPriceOracle.sol";
import { ICoreController } from "../common/interface/ICoreController.sol";
import { ILendingRateOracle } from "../common/interface/ILendingRateOracle.sol";
import { IWrappedNativeToken } from "../common/interface/IWrappedNativeToken.sol";
import { IStableCreditToken } from "../common/interface/IStableCredit.sol";
import { IVariableCreditToken } from "../common/interface/IVariableCredit.sol";

import { IAccessController } from "../common/interface/IAccessController.sol";
/* controllers */
import { VaultController } from "../common/controller/VaultController.sol";
import { AccountController } from "../common/controller/AccountController.sol";
import { VaultConfigController } from "../common/controller/VaultConfigController.sol";
/* logics */
import { CoreLogic } from "../common/logic/CoreLogic.sol";

contract CoreController is Initializable, UUPSUpgradeable, ICoreController {
	/* using deps */
	using SafeERC20Upgradeable for IERC20Upgradeable;
	using VaultController for VaultModel.Data;
	using VaultConfigController for VaultModel.Config;
	using AccountController for AccountModel.Config;

	/* data mapping */
	mapping(uint256 => address) private _accountIDs; // account ID list can be used by/for various utilities, e.g liquidation-bots
	mapping(address => VaultModel.Data) private _vaults;
	mapping(address => AccountModel.Data) private _accounts;

	mapping(address => bool) private _paused;
	mapping(address => uint256) private _flashMintFee; //flash mint fee, in %
	mapping(address => uint256) private _maxFlashMintPercent; //max flash mint amount, % of underlying(available) liquidity

	/* list */
	address[] private _vaultsList;

	/* variable decls */
	uint256 public lastAccountID;
	uint256 private _maxStaticCreditPercent; //fixed & stable

	/* external utilities */
	IPriceOracle private _priceOracle;
	IAccessController private _accessController;
	// ILendingRateOracle private _fixedRateOracle;
	ILendingRateOracle private _stableRateOracle;
	IWrappedNativeToken private _wrappedNativeToken;

	/* partners */
	address private _burner;
	address private _lendingCore;
	address private _savingsCore;
	address private _swapController;
	address private _rewardController;

	function initialize(IAccessController accessController)
		external
		initializer
	{
		// initialize deps
		__UUPSUpgradeable_init();

		_accessController = accessController;

		//oracle settings
		// _stableRateOracle = lendingRateOracle_;
		// _priceOracle = priceOracle_;

		// credit settings
		_maxStaticCreditPercent = 2500; //fixed & stable max allowed to be utilized

		/* skip setSavings and setLendingCore until after initialization */

		//create first account
		lastAccountID = 100000;
		_accountIDs[lastAccountID] = msg.sender;
		_accounts[msg.sender].id = lastAccountID;
	}

	/* modifiers below */
	modifier onlyPauser() {
		_onlyPauser();
		_;
	}

	modifier onlyGroup() {
		_onlyGroup();
		_;
	}

	modifier onlyConfigurator() {
		_onlyConfigurator();
		_;
	}

	modifier onlyGroupOrConfigurator() {
		_onlyGroupOrConfigurator();
		_;
	}

	/* protocol utilities below */

	///@inheritdoc ICoreController
	function tryCreateAccount(address account) external override onlyGroup {
		AccountModel.Data storage storedAccount = _accounts[account];
		// is ID registered?
		if (storedAccount.id == 0) {
			// register
			CoreLogic.executeCreateAccount(
				account,
				storedAccount,
				_accountIDs,
				// use the next Available ID
				++lastAccountID
			);
		}
	}

	function pullAsset(
		address asset,
		address from,
		address to,
		uint256 amount
	) external override onlyGroup {
		IERC20Upgradeable(asset).safeTransferFrom(
			from, /*usually msg.sender */
			to, /*to vaultToken, mostly */
			amount
		);
	}

	function onInterestRateUpdate(
		address asset,
		uint256 liquidityRate,
		uint256 stableCreditRate,
		uint256 variableCreditRate,
		uint256 liquidityIndex,
		uint256 variableCreditIndex
	) external override onlyGroup {
		emit VaultDataUpdated(
			asset,
			liquidityRate,
			stableCreditRate,
			variableCreditRate,
			liquidityIndex,
			variableCreditIndex
		);
	}

	/* Vault related getters below */

	///@inheritdoc ICoreController
	function getVaultData(address asset)
		public
		view
		override
		returns (VaultModel.Data memory)
	{
		return _vaults[asset];
	}

	///@inheritdoc ICoreController
	function getVaultLiquidityData(address asset)
		external
		view
		override
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableCreditRate,
			uint256 stableCreditRate,
			uint256 averageStableCreditRate,
			uint256 liquidityIndex,
			uint256 variableCreditIndex,
			uint40 lastUpdateTimestamp
		)
	{
		VaultModel.Data memory vault = _vaults[asset];
		IStableCreditToken stableCreditToken = IStableCreditToken(
			vault.stableCreditToken
		);

		return (
			IERC20Upgradeable(asset).balanceOf(vault.vaultToken),
			stableCreditToken.totalSupply(),
			IERC20Upgradeable(vault.variableCreditToken).totalSupply(),
			vault.currentLiquidityRate,
			vault.currentVariableCreditRate,
			vault.currentStableCreditRate,
			stableCreditToken.getAverageRate(),
			vault.liquidityIndex,
			vault.variableCreditIndex,
			vault.lastUpdateTimestamp
		);
	}

	///@inheritdoc ICoreController
	function getVaultConfig(address asset)
		external
		view
		override
		returns (VaultModel.Config memory)
	{
		return _vaults[asset].config;
	}

	///@inheritdoc ICoreController
	function getVaultNormalizedIncome(address asset)
		external
		view
		override
		returns (uint256)
	{
		return _vaults[asset].getNormalizedIncome();
	}

	///@inheritdoc ICoreController
	function getVaultConfigData(address asset)
		external
		view
		override
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool enabledAsCollateral,
			bool creditEnabled,
			bool stableCreditEnabled,
			bool isActive,
			bool isFrozen
		)
	{
		VaultModel.Config memory vaultConfig = _vaults[asset].config;

		(
			ltv,
			liquidationThreshold,
			liquidationBonus,
			decimals,
			reserveFactor
		) = vaultConfig.getParams();

		(isActive, isFrozen, creditEnabled, stableCreditEnabled) = vaultConfig
			.getFlags();

		enabledAsCollateral = liquidationThreshold > 0;
	}

	///@inheritdoc ICoreController
	function getVaults() external view override returns (address[] memory) {
		return _vaultsList;
	}

	/* account-related getters below */

	///@inheritdoc ICoreController
	function getAccountConfig(address account)
		external
		view
		override
		returns (AccountModel.Config memory)
	{
		return _accounts[account].config;
	}

	///@inheritdoc ICoreController
	function getAccountData(address account)
		external
		view
		override
		returns (AccountModel.Data memory)
	{
		return _accounts[account];
	}

	///@inheritdoc ICoreController
	function getAccountLiquidityData(address account)
		external
		view
		override
		returns (
			uint256 savingsBalanceInBaseCurrency,
			uint256 outstandingDebtInBaseCurrency,
			uint256 availableCreditInBaseCurrency,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		)
	{
		(
			savingsBalanceInBaseCurrency,
			outstandingDebtInBaseCurrency,
			availableCreditInBaseCurrency,
			currentLiquidationThreshold,
			ltv,
			healthFactor
		) = CoreLogic.executeGetAccountData(
			this,
			account,
			_accounts[account].config,
			_vaultsList,
			address(_priceOracle)
		);
	}

	function getAccountVaultData(address account, address asset)
		external
		view
		override
		returns (
			uint256 currentVaultBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableCreditRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool enabledAsCollateral
		)
	{
		VaultModel.Data memory vault = _vaults[asset];

		AccountModel.Config memory accountConfig = _accounts[account].config;

		currentVaultBalance = IERC20Upgradeable(vault.vaultToken).balanceOf(
			account
		);
		currentVariableDebt = IERC20Upgradeable(vault.variableCreditToken)
			.balanceOf(account);
		currentStableDebt = IERC20Upgradeable(vault.stableCreditToken)
			.balanceOf(account);
		principalStableDebt = IStableCreditToken(vault.stableCreditToken)
			.principalBalanceOf(account);
		scaledVariableDebt = IVariableCreditToken(vault.variableCreditToken)
			.scaledBalanceOf(account);
		liquidityRate = vault.currentLiquidityRate;
		stableCreditRate = IStableCreditToken(vault.stableCreditToken)
			.getAccountStableRate(account);
		stableRateLastUpdated = IStableCreditToken(vault.stableCreditToken)
			.getAccountLastUpdated(account);
		enabledAsCollateral = accountConfig.vaultIsCollateral(vault.id);
	}

	///@inheritdoc ICoreController
	function findAddressByID(uint256 accountID)
		external
		view
		override
		returns (address)
	{
		return _accountIDs[accountID];
	}

	///@inheritdoc ICoreController
	function getAddressByID(uint256 accountID)
		external
		view
		override
		returns (address account)
	{
		if ((account = _accountIDs[accountID]) == address(0))
			revert NoSuchAccountID();
	}

	///@inheritdoc ICoreController
	function findIDByAddress(address account)
		external
		view
		override
		returns (uint256)
	{
		return _accounts[account].id;
	}

	///@inheritdoc ICoreController
	function getIDByAddress(address account)
		external
		view
		override
		returns (uint256 accountID)
	{
		if ((accountID = _accounts[account].id) == 0) {
			revert NoSuchAccountID();
		}
	}

	/* reward-related getters below */

	/* setters zone */
	///@inheritdoc ICoreController
	function updateAccountConfig(address account, uint256 config)
		external
		override
		onlyGroup
	{
		_accounts[account].config.data = config;
	}

	///@inheritdoc ICoreController
	function updateVaultConfig(address asset, uint256 config)
		external
		override
		onlyGroupOrConfigurator
	{
		_vaults[asset].config.data = config;
	}

	function updateVault(address asset, VaultModel.Data memory data)
		external
		override
		onlyGroupOrConfigurator
	{
		_vaults[asset] = data;
	}

	///@inheritdoc ICoreController
	function updateVaultInterestRateModel(address asset, address model)
		external
		override
		onlyConfigurator
	{
		_vaults[asset].interestRateModel = model;
	}

	/* controller config setters & getters below */

	///@inheritdoc ICoreController
	function pause(address partner) external override onlyPauser {
		_paused[partner] = true;

		if (partner == address(this)) {
			emit PausedGroup(msg.sender);
		} else {
			emit PausedPartner(msg.sender, partner);
		}
	}

	///@inheritdoc ICoreController
	function unpause(address partner) external override onlyPauser {
		_paused[partner] = false;

		if (partner == address(this)) {
			emit UnpausedGroup(msg.sender);
		} else {
			emit UnpausedPartner(msg.sender, partner);
		}
	}

	/* core necessities */

	///@inheritdoc ICoreController
	function paused(address partner) external view override returns (bool) {
		return _paused[address(this)] || _paused[partner];
	}

	///@inheritdoc ICoreController
	function initializeVault(
		address underlyingAsset, //Skipped IERC20 to avoid incompatibility issues with bytes32(name & symbol)
		address vaultToken,
		address stableCreditToken,
		address variableCreditToken,
		address interestRateModel
	) external override onlyConfigurator {
		CoreLogic.executeInitializeVault(
			underlyingAsset,
			vaultToken,
			stableCreditToken,
			variableCreditToken,
			interestRateModel,
			_vaultsList,
			_vaults[underlyingAsset]
		);
	}

	function setRewardController(address rewardController)
		external
		override
		onlyConfigurator
	{
		_rewardController = rewardController;
	}

	function setNativeToken(IWrappedNativeToken wrappedNativeToken)
		external
		override
		onlyConfigurator
	{
		_wrappedNativeToken = wrappedNativeToken;
	}

	function setBurner(address burner) external override onlyConfigurator {
		_burner = burner;
	}

	function setLendingCore(address addr) external override onlyConfigurator {
		_lendingCore = addr;
	}

	function setSavingsCore(address addr) external override onlyConfigurator {
		_savingsCore = addr;
	}

	function setSwapController(address addr)
		external
		override
		onlyConfigurator
	{
		_swapController = addr;
	}

	function setPriceOracle(IPriceOracle priceOracle)
		external
		override
		onlyConfigurator
	{
		_priceOracle = priceOracle;
		emit PriceOracleUpdated(address(priceOracle));
	}

	function setStableRateOracle(ILendingRateOracle lendingRateOracle)
		external
		override
		onlyConfigurator
	{
		_stableRateOracle = lendingRateOracle;
		emit LendingRateOracleUpdated(address(lendingRateOracle));
	}

	function setStaticPercent(uint256 ratePercent)
		external
		override
		onlyConfigurator
	{
		_maxStaticCreditPercent = ratePercent; //fixed and stable combined
	}

	function setFlashMintMaxPercent(address asset, uint256 inPercent)
		external
		override
		onlyConfigurator
	{
		address vaultToken = _vaults[asset].vaultToken;

		_maxFlashMintPercent[vaultToken] = inPercent; //max flash mint percent of totalSupply
	}

	function setFlashMintFee(address asset, uint256 inPercent)
		external
		override
		onlyConfigurator
	{
		address vaultToken = _vaults[asset].vaultToken;

		_flashMintFee[vaultToken] = inPercent; //max flash mint percent of totalSupply
	}

	function getFlashMintMaxPercent(address asset)
		external
		view
		override
		returns (uint256)
	{
		address vaultToken = _vaults[asset].vaultToken;
		return _maxFlashMintPercent[vaultToken];
	}

	function getFlashMintFee(address asset)
		external
		view
		override
		returns (uint256)
	{
		address vaultToken = _vaults[asset].vaultToken;
		return _flashMintFee[vaultToken];
	}

	function getStaticPercent() external view override returns (uint256) {
		return _maxStaticCreditPercent;
	}

	function getACL() external view override returns (address) {
		return address(_accessController);
	}

	function getBurner() external view override returns (address) {
		return _burner;
	}

	function getNativeToken() external view override returns (address) {
		return address(_wrappedNativeToken);
	}

	function getRewardController() external view override returns (address) {
		return address(_rewardController);
	}

	function getLendingCore() external view override returns (address) {
		return _lendingCore;
	}

	function getSavingsCore() external view override returns (address) {
		return _savingsCore;
	}

	function getSwapController() external view override returns (address) {
		return _swapController;
	}

	function getPriceOracle() external view override returns (address) {
		return address(_priceOracle);
	}

	function getStableRateOracle() external view override returns (address) {
		return address(_stableRateOracle);
	}

	/* modifier helpers */
	function _onlyPauser() internal view {
		if (!_accessController.isPauser(msg.sender)) revert NotPauser();
	}

	function _onlyGroup() internal view {
		if (!_accessController.isGroup(msg.sender)) revert NotGroup();
	}

	function _onlyConfigurator() internal view {
		if (!_accessController.isConfigurator(msg.sender))
			revert NotConfigurator();
	}

	function _onlyGroupOrConfigurator() internal view {
		if (!_accessController.isGroupOrConfigurator(msg.sender))
			revert NotGroupOrConfigurator();
	}

	/* upgrader */
	function _authorizeUpgrade(address) internal view override {
		if (!_accessController.isUpgrader(msg.sender)) {
			revert NotUpgrader();
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VaultModel library
 * @author eaZI
 * @notice Implements bitmap structure and variables to handle vault data, configurations and structures
 */
library VaultModel {
	struct Data {
		//stores the vault configuration
		Config config;
		//the liquidity index. Expressed in ray
		uint128 liquidityIndex;
		//variable credit index. Expressed in ray
		uint128 variableCreditIndex;
		//the current supply rate. Expressed in ray
		uint128 currentLiquidityRate;
		//the current variable credit rate. Expressed in ray
		uint128 currentVariableCreditRate;
		//the current stable credit rate. Expressed in ray
		uint128 currentStableCreditRate;
		uint40 lastUpdateTimestamp;
		/* tokens */
		address vaultToken;
		address stableCreditToken;
		address variableCreditToken;
		address fixedCreditToken;
		address interestRateModel; // interest rate model
		uint8 id; //vault ID
	}

	struct Config {
		//bit 0-15: LTV
		//bit 16-31: Liq. threshold
		//bit 32-47: Liq. bonus
		//bit 48-55: Decimals
		//bit 56: vault is active
		//bit 57: vault is frozen
		//bit 58: borrowing is enabled
		//bit 59: stable rate borrowing enabled
		//bit 60-63: reserved
		//bit 64-79: reserve factor
		uint256 data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title AccountModel library
 * @author eaZI
 * @notice Implements bitmap structure and variables to handle account data, configurations and structures
 */
library AccountModel {
	struct Data {
		Config config; //configuration data in bits
		uint256 id; //Account ID or Number
	}

	struct Config {
		uint256 data;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IPriceOracle interface
 * @notice Interface for the Price oracle.
 **/

interface IPriceOracle {
	/**
	 * @dev returns the asset price in Base Currency
	 * @param asset The asset
	 * @return the Base Currency price of the asset
	 **/
	function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/* Models */
import { AccountModel } from "../model/AccountModel.sol";
import { VaultModel } from "../model/VaultModel.sol";
/* interfaces */
import { IPriceOracle } from "./IPriceOracle.sol";
import { ILendingRateOracle } from "./ILendingRateOracle.sol";
import { IWrappedNativeToken } from "./IWrappedNativeToken.sol";

interface ICoreController {
	struct AssetSymbol {
		string symbol;
		address asset;
	}

	struct PartnersEmissions {
		address asset; // underlying asset whose emissionPerSecond are checked
		uint256 vaultTokenEPS; // vaultToken Emission per second
		uint256 variableCreditTokenEPS; // variableCreditToken Emission per second
	}

	/* errors */
	/// Can only be called by partner group
	error NotGroup();

	/// Can only be called by pauser
	error NotPauser();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Can only be called by configurator
	error NotConfigurator();

	/// Can only be called by partner group or configurator
	error NotGroupOrConfigurator();

	/// Inconsistent parameter length
	error InconsistentParameterLength();

	/// Invalid to address(usually 0x address)
	error InvalidToAddress();

	/// No such account ID exists(or registered) on eaZI
	error NoSuchAccountID();

	/// Vault already initialized
	error VaultAlreadyInitialized();

	/* events */

	/**
	 * @dev Emitted when the Price Oracle address is updated
	 */
	event PriceOracleUpdated(address indexed newAddress);

	/**
	 * @dev Emitted when the Lending Rate Oracle address is updated
	 */
	event LendingRateOracleUpdated(address indexed newAddress);

	/**
	 * @dev Emitted when the whole group(the conglomerate) pause is triggered by `by`
	 */
	event PausedGroup(address by);

	/**
	 * @dev Emitted when the whole group(the conglomerate) pause is lifted by `by`
	 */
	event UnpausedGroup(address by);

	/**
	 * @dev Emitted when a partner(vault, any core, token, etc part of the group) pause is triggered by `by`
	 */
	event PausedPartner(address by, address partner);

	/**
	 * @dev Emitted when a partner(vault, any core, token, etc part of the group) pause is lifted by `by`
	 */
	event UnpausedPartner(address by, address partner);

	/**
	 * @dev Emitted when the state of a vault is updated
	 * @param asset The underlying asset of the vault
	 * @param liquidityRate The new liquidity rate
	 * @param stableCreditRate The new stable credit rate
	 * @param variableCreditRate The new variable credit rate
	 * @param liquidityIndex The new liquidity index
	 * @param variableCreditIndex The new variable credit index
	 **/
	event VaultDataUpdated(
		address indexed asset,
		uint256 liquidityRate,
		uint256 stableCreditRate,
		uint256 variableCreditRate,
		uint256 liquidityIndex,
		uint256 variableCreditIndex
	);

	/**
	 * @dev Emitted when a new `account` get created and assigned `accountID`
	 **/
	event AccountCreated(address indexed account, uint256 indexed accountID);

	/* methods */

	/**
	 * @dev Create eaZI account, assigning it an ID then returning it
	 * @notice Throws when account Exist
	 * - Only callable by the group(s) contract
	 * @param account The account being created
	 * @return newAccountId New account ID created
	 **/
	// function createAccount(address account) external returns (uint256);

	/**
	 * @dev Create eaZI account, but not returning it, useful where the ID value doesn't matter
	 * @notice - Only callable by the group(s) contract
	 * @param account The account being created
	 **/
	function tryCreateAccount(address account) external;

	function pullAsset(
		address asset,
		address from,
		address to,
		uint256 amount
	) external;

	function onInterestRateUpdate(
		address asset,
		uint256 liquidityRate,
		uint256 stableCreditRate,
		uint256 variableCreditRate,
		uint256 liquidityIndex,
		uint256 variableCreditIndex
	) external;

	/**
	 * @dev Initializes a vault, activating it, assigning vaultToken, credit tokens and an interest rate model
	 * @param asset The underlying asset of the vault
	 * @param vaultToken The vaultToken that will be assigned to the vault
	 * @param stableCreditToken The StableCreditToken that will be assigned to the vault
	 * @param variableCreditToken The VariableCreditToken that will be assigned to the vault
	 * @param interestRateModel The interest rate model contract
	 **/
	function initializeVault(
		address asset, //Skipped IERC20 to avoid incompatibility issues with bytes32(name & symbol)
		address vaultToken,
		address stableCreditToken,
		address variableCreditToken,
		address interestRateModel
	) external;

	/* controller config setters & getters below */

	/* setters below */
	/**
	 * @dev Pause a `partner`, can trigger global pause by making `partner` address(of CoreController, this contract)
	 * @param partner The partner to pause
	 */
	function pause(address partner) external;

	/**
	 * @dev Unpause a `partner`, even address of CoreController(this contract)
	 * @param partner The partner to unpause
	 */
	function unpause(address partner) external;

	// function updateAccount(address account, AccountModel.Data memory data)
	// 	external;

	/**
	 * @dev Sets the configuration bitmap of an account as a whole
	 * - Only callable by the group(s) contract
	 * @param account The account being updated
	 * @param config The new configuration bitmap
	 **/
	function updateAccountConfig(address account, uint256 config) external;

	function updateVault(address asset, VaultModel.Data memory data) external;

	/**
	 * @dev Sets the configuration bitmap of the vault as a whole
	 * - Only callable by the group(s) contract or configurator
	 * @param asset The underlying asset of the vault
	 * @param config The new configuration bitmap
	 **/
	function updateVaultConfig(address asset, uint256 config) external;

	/**
	 * @dev Updates a vault interest rate Model
	 * @param asset The underlying asset of the vault
	 * @param model The interest rate Model
	 **/
	function updateVaultInterestRateModel(address asset, address model)
		external;

	function setNativeToken(IWrappedNativeToken wrappedNativeToken) external;

	function setBurner(address burner) external;

	function setStaticPercent(uint256 ratePercent) external;

	function setRewardController(address rewardController) external;

	function setFlashMintMaxPercent(address asset, uint256 inPercent) external;

	function setFlashMintFee(address asset, uint256 inPercent) external;

	function setLendingCore(address addr) external;

	function setSavingsCore(address addr) external;

	function setSwapController(address addr) external;

	function setPriceOracle(IPriceOracle priceOracle) external;

	function setStableRateOracle(ILendingRateOracle lendingRateOracle) external;

	/* getters */

	function paused(address partner) external view returns (bool);

	/**
	 * @dev find eaZI account's ID by its address
	 * - returns 0x if no such account registered
	 * @param account The account native address(e.g Ethereum address)
	 * @return accountID The account ID or 0 if not registered
	 **/
	function findIDByAddress(address account) external view returns (uint256);

	/**
	 * @dev find an eaZI account's address by its ID
	 * - returns 0x if no such account registered
	 * @param accountID The account ID
	 * @return The account address or 0x if not registered
	 **/
	function findAddressByID(uint256 accountID) external view returns (address);

	/**
	 * @dev get an eaZI account's address by its ID
	 * - throws/reverts if no such account registered
	 * @param accountID The account ID
	 * @return account The account address
	 **/
	function getAddressByID(uint256 accountID)
		external
		view
		returns (address account);

	/**
	 * @dev get eaZI account's ID by its address
	 * - throws/reverts if no such account registered
	 * @param account The account native address(e.g Ethereum address)
	 * @return accountID The account ID
	 **/
	function getIDByAddress(address account)
		external
		view
		returns (uint256 accountID);

	/**
	 * @dev Returns `account` configuration
	 * @param account The account holder
	 * @return The account config
	 **/
	function getAccountConfig(address account)
		external
		view
		returns (AccountModel.Config memory);

	/**
	 * @dev Returns `account` data state
	 * @param account The account holder
	 * @return The account data
	 **/
	function getAccountData(address account)
		external
		view
		returns (AccountModel.Data memory);

	function getAccountVaultData(address account, address asset)
		external
		view
		returns (
			uint256 currentVaultBalance,
			uint256 currentStableDebt,
			uint256 currentVariableDebt,
			uint256 principalStableDebt,
			uint256 scaledVariableDebt,
			uint256 stableCreditRate,
			uint256 liquidityRate,
			uint40 stableRateLastUpdated,
			bool enabledAsCollateral
		);

	/**
	 * @dev Returns liquidity data across all vaults and various partners
	 * @param account The account
	 * @return savingsBalanceInBaseCurrency The total savings balance of the account in Base Currency
	 * @return outstandingDebtInBaseCurrency the outstanding debt of the account in Base Currency
	 * @return availableCreditInBaseCurrency The available credit limit of the account in Base Currency
	 * @return currentLiquidationThreshold The liquidation threshold of the account
	 * @return ltv the loan to value of the account
	 * @return healthFactor the current health factor of the account, as represented internally
	 **/
	function getAccountLiquidityData(address account)
		external
		view
		returns (
			uint256 savingsBalanceInBaseCurrency,
			uint256 outstandingDebtInBaseCurrency,
			uint256 availableCreditInBaseCurrency,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		);

	/**
	 * @dev Returns the list of the initialized vaults
	 **/
	function getVaults() external view returns (address[] memory);

	/**
	 * @dev Returns `asset` vault state and configuration
	 * @param asset The vault underlying asset
	 * @return The vault state
	 **/
	function getVaultData(address asset)
		external
		view
		returns (VaultModel.Data memory);

	/**
	 * @dev Returns `asset` vault liquidity(including rates) data
	 * @param asset The vault underlying asset
	 * @return availableLiquidity vault available liquidity
	 * @return totalStableDebt vault total stable debt
	 * @return totalVariableDebt vault total variable debt
	 * @return liquidityRate vault liquidity rate
	 * @return variableCreditRate variable credit rate
	 * @return stableCreditRate stable credit rate
	 * @return averageStableCreditRate average stable credit rate
	 * @return liquidityIndex liquidity index
	 * @return variableCreditIndex variable credit index
	 * @return lastUpdateTimestamp vault last updated timestamp
	 **/
	function getVaultLiquidityData(address asset)
		external
		view
		returns (
			uint256 availableLiquidity,
			uint256 totalStableDebt,
			uint256 totalVariableDebt,
			uint256 liquidityRate,
			uint256 variableCreditRate,
			uint256 stableCreditRate,
			uint256 averageStableCreditRate,
			uint256 liquidityIndex,
			uint256 variableCreditIndex,
			uint40 lastUpdateTimestamp
		);

	/**
	 * @dev Returns `asset` vault configuration
	 * @param asset The vault underlying asset
	 * @return The vault config
	 **/
	function getVaultConfig(address asset)
		external
		view
		returns (VaultModel.Config memory);

	/**
	 * @dev Returns `asset` vault configuration data
	 * @param asset The vault underlying asset
	 * @return decimals vault decimals
	 * @return ltv vault loan to value
	 * @return liquidationThreshold vault liquidation threshold
	 * @return liquidationBonus vault liquidation bonus
	 * @return reserveFactor vault reserve factor
	 * @return enabledAsCollateral is `asset` accepted as collateral
	 * @return creditEnabled is `asset` enabled for credit borrowing
	 * @return stableCreditEnabled is `asset` enabled for Stable Credit borrowing
	 * @return isActive is Vault Active
	 * @return isFrozen is Vault frozen
	 **/
	function getVaultConfigData(address asset)
		external
		view
		returns (
			uint256 decimals,
			uint256 ltv,
			uint256 liquidationThreshold,
			uint256 liquidationBonus,
			uint256 reserveFactor,
			bool enabledAsCollateral,
			bool creditEnabled,
			bool stableCreditEnabled,
			bool isActive,
			bool isFrozen
		);

	/**
	 * @dev Returns the normalized income per unit of asset
	 * @param asset The underlying asset of the vault
	 * @return The vault's normalized income
	 */
	function getVaultNormalizedIncome(address asset)
		external
		view
		returns (uint256);

	function getACL() external view returns (address);

	function getBurner() external view returns (address);

	function getNativeToken() external view returns (address);

	function getLendingCore() external view returns (address);

	function getSavingsCore() external view returns (address);

	function getSwapController() external view returns (address);

	function getPriceOracle() external view returns (address);

	function getStableRateOracle() external view returns (address);

	function getRewardController() external view returns (address);

	function getStaticPercent() external view returns (uint256);

	function getFlashMintMaxPercent(address asset)
		external
		view
		returns (uint256);

	function getFlashMintFee(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ILendingRateOracle interface
 * @notice Interface for the credit rate oracle.
 * Provides the average credit rate to be used as a base for the stable/fixed credit rate calculations
 **/

interface ILendingRateOracle {
	event CreditRateSet(address indexed asset, uint256 rate);

	/**
    @dev returns the credit rate in ray
    **/
	function getCreditRate(address asset) external view returns (uint256);

	/**
    @dev sets the credit rate. Rate value must be in ray
    **/
	function setCreditRate(address asset, uint256 rate) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWrappedNativeToken {
	function deposit() external payable;

	function withdraw(uint256) external;

	function approve(address guy, uint256 wad) external returns (bool);

	function transferFrom(
		address src,
		address dst,
		uint256 wad
	) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICreditToken.sol";

interface IStableCreditToken is ICreditToken {
	/**
	 * @dev Emitted after stable credit is issued
	 * @param account The account who triggered the minting
	 * @param onBehalfOf The recipient of stable credit tokens
	 * @param amount The amount minted
	 * @param currentBalance The current balance of the account
	 * @param balanceIncrease The increase in balance since the last action of the account
	 * @param newRate The rate of the debt after the minting
	 * @param avgStableRate The new average stable rate after the minting
	 * @param newTotalSupply The new total supply of the stable credit token after the action
	 **/
	event Minted(
		address indexed account,
		address indexed onBehalfOf,
		uint256 amount,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 newRate,
		uint256 avgStableRate,
		uint256 newTotalSupply
	);

	/**
	 * @dev Emitted after stable debt is burnt
	 * @param account The account
	 * @param amount The amount being burned
	 * @param currentBalance The current balance of the account
	 * @param balanceIncrease The the increase in balance since the last action of the account
	 * @param avgStableRate The new average stable rate after the burning
	 * @param newTotalSupply The new total supply of the stable credit token after the action
	 **/
	event Burnt(
		address indexed account,
		uint256 amount,
		uint256 currentBalance,
		uint256 balanceIncrease,
		uint256 avgStableRate,
		uint256 newTotalSupply
	);

	/**
	 * @dev Mints credit token to the `onBehalfOf` address.
	 * - The resulting rate is the weighted average between the rate of the new debt
	 * and the rate of the previous debt
	 * @param account The account receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The account receiving the credit tokens
	 * @param amount The amount of credit tokens to mint
	 * @param rate The rate of the debt being minted
	 **/
	function mint(
		address account,
		address onBehalfOf,
		uint256 amount,
		uint256 rate
	) external returns (bool);

	/**
	 * @dev Burns debt of `account`
	 * - The resulting rate is the weighted average between the rate of the new debt
	 * and the rate of the previous debt
	 * @param account The account getting its debt burned
	 * @param amount The amount of credit tokens getting burned
	 **/
	function burn(address account, uint256 amount) external;

	/**
	 * @dev Returns the average rate of all the stable rate loans.
	 * @return The average stable rate
	 **/
	function getAverageRate() external view returns (uint256);

	/**
	 * @dev Returns the stable rate of the account debt
	 * @return The stable rate of the account
	 **/
	function getAccountStableRate(address account)
		external
		view
		returns (uint256);

	/**
	 * @dev Returns the timestamp of the last update of the account
	 * @return The timestamp
	 **/
	function getAccountLastUpdated(address account)
		external
		view
		returns (uint40);

	/**
	 * @dev Returns the principal, the total supply and the average stable rate
	 **/
	function getSupplyData()
		external
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint40
		);

	/**
	 * @dev Returns the timestamp of the last update of the total supply
	 * @return The timestamp
	 **/
	function getTotalSupplyLastUpdated() external view returns (uint40);

	/**
	 * @dev Returns the total supply and the average stable rate
	 **/
	function getTotalSupplyAndAvgRate()
		external
		view
		returns (uint256, uint256);

	/**
	 * @dev Returns the principal debt balance of the account
	 * @return The debt balance of the account since the last burn/mint action
	 **/
	function principalBalanceOf(address account)
		external
		view
		returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ICreditToken.sol";

interface IVariableCreditToken is ICreditToken {
	/**
	 * @dev Emitted after variable credit is issued
	 * @param from The account performing the mint
	 * @param onBehalfOf The account on which behalf minting has been performed
	 * @param value The amount to be minted
	 * @param index The last index of the vault
	 **/
	event Minted(
		address indexed from,
		address indexed onBehalfOf,
		uint256 value,
		uint256 index
	);

	/**
	 * @dev Mints credit token to the `onBehalfOf` address
	 * @param account The account receiving the borrowed underlying, being the delegatee in case
	 * of credit delegate, or same as `onBehalfOf` otherwise
	 * @param onBehalfOf The account receiving the credit tokens
	 * @param amount The amount of debt being minted
	 * @param index The variable debt index of the vault
	 * @return `true` if the the previous balance of the account is 0
	 **/
	function mint(
		address account,
		address onBehalfOf,
		uint256 amount,
		uint256 index
	) external returns (bool);

	/**
	 * @dev Emitted when variable debt is burnt
	 * @param account The account which debt has been burned
	 * @param amount The amount of debt being burned
	 * @param index The index of the account
	 **/
	event Burnt(address indexed account, uint256 amount, uint256 index);

	/**
	 * @dev Burns `account` variable debt
	 * @param account The account which debt is burnt
	 * @param index The variable debt index of the vault
	 **/
	function burn(
		address account,
		uint256 amount,
		uint256 index
	) external;

	/**
	 * @dev Returns the scaled balance of the account. The scaled balance is the sum of all the
	 * updated stored balance divided by the vault's liquidity index at the moment of the update
	 * @param account The account whose balance is calculated
	 * @return The scaled balance of the account
	 **/
	function scaledBalanceOf(address account) external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the account and the scaled total supply.
	 * @param account The account
	 * @return The scaled balance of the account
	 * @return The scaled balance and the scaled total supply
	 **/
	function getScaledAccountBalanceAndSupply(address account)
		external
		view
		returns (uint256, uint256);

	/**
	 * @dev Returns the scaled total supply of the variable credit token. Represents sum(debt/index)
	 * @return The scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IAccessController is IAccessControlUpgradeable {
	/* errors */
	/// Can only be called by upgrader
	error NotUpgrader();

	/* methods */
	function isPauser(address pauser) external view returns (bool);

	function isRiskAdmin(address admin) external view returns (bool);

	function isGroup(address group) external view returns (bool);

	function isConfigurator(address configurator) external view returns (bool);

	function isGroupOrConfigurator(address groupOrConfigurator)
		external
		view
		returns (bool);

	function isUpgrader(address upgrader) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* math utils */
import { WadRayMath } from "../utils/WadRayMath.sol";
import { PercentageMath } from "../utils/PercentageMath.sol";
import { InterestMath } from "../utils/InterestMath.sol";
/* models */
import { VaultModel } from "../model/VaultModel.sol";
/* controllers */
import { VaultConfigController } from "./VaultConfigController.sol";
/* interests */
import { IInterestRateModel } from "../interface/IInterestRateModel.sol";
/* token interfaces */
import { IStableCreditToken } from "../interface/IStableCredit.sol";
import { IVariableCreditToken } from "../interface/IVariableCredit.sol";
import { IVaultToken } from "../interface/IVaultToken.sol";

/**
 * @title VaultController library
 * @author eaZI
 * @notice Implements bitmap logic to handle account data, configurations and structure
 */
library VaultController {
	/// Liquidity index overflows uint128
	error LiquidityIndexOverflow();

	/// Liquidity rate overflows uint128
	error LiquidityRateOverflow();

	/// Stable credit rate overflows uint128
	error StableCreditRateOverflow();

	/// Variable credit rate overflows uint128
	error VariableCreditRateOverflow();

	/// Variable credit index overflows uint128
	error VariableCreditIndexOverflow();

	using WadRayMath for uint256;
	using PercentageMath for uint256;
	using VaultConfigController for VaultModel.Config;

	/**
	 * @dev Returns the ongoing normalized income for the vault
	 * A value of 1e27 means there is no income. As time passes, the income is accrued
	 * A value of 2*1e27 means for each unit of asset one unit of income has been accrued
	 * @param vaultData The vault data
	 * @return the normalized income. expressed in ray
	 **/
	function getNormalizedIncome(VaultModel.Data memory vaultData)
		internal
		view
		returns (uint256)
	{
		uint40 timestamp = vaultData.lastUpdateTimestamp;

		//solhint-disable-next-line not-rely-on-time
		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return vaultData.liquidityIndex;
		}

		//cumulated interest
		return
			InterestMath
				.linearInterest(vaultData.currentLiquidityRate, timestamp)
				.rMul(vaultData.liquidityIndex);
	}

	/**
	 * @dev Returns the ongoing normalized variable debt for the vault
	 * A value of 1e27 means there is no debt. As time passes, the income is accrued
	 * A value of 2*1e27 means that for each unit of debt, one unit worth of interest has been accumulated
	 * @param vaultData The vault data
	 * @return The normalized variable debt. expressed in ray
	 **/
	function getNormalizedDebt(VaultModel.Data memory vaultData)
		internal
		view
		returns (uint256)
	{
		uint40 timestamp = vaultData.lastUpdateTimestamp;

		//solhint-disable-next-line not-rely-on-time
		if (timestamp == uint40(block.timestamp)) {
			//if the index was updated in the same block, no need to perform any calculation
			return vaultData.variableCreditIndex;
		}

		//cumulated interest
		return
			InterestMath
				.compoundInterest(
					vaultData.currentVariableCreditRate,
					timestamp
				)
				.rMul(vaultData.variableCreditIndex);
	}

	/**
	 * @dev Updates the liquidity cumulative index and the variable credit index.
	 * @param vaultData the vault data
	 **/
	function updateState(VaultModel.Data memory vaultData) internal {
		uint256 scaledVariableDebt = IVariableCreditToken(
			vaultData.variableCreditToken
		).scaledTotalSupply();
		uint256 previousVariableCreditIndex = vaultData.variableCreditIndex;
		uint256 previousLiquidityIndex = vaultData.liquidityIndex;
		uint40 lastUpdatedTimestamp = vaultData.lastUpdateTimestamp;

		(
			uint256 newLiquidityIndex,
			uint256 newVariableCreditIndex
		) = _updateIndexes(
				vaultData,
				scaledVariableDebt,
				previousLiquidityIndex,
				previousVariableCreditIndex,
				lastUpdatedTimestamp
			);

		_accrueToTreasury(
			vaultData,
			scaledVariableDebt,
			previousVariableCreditIndex,
			newLiquidityIndex,
			newVariableCreditIndex,
			lastUpdatedTimestamp
		);
	}

	/**
	 * @dev Accumulates a predefined amount of asset to the vault as a fixed, instantaneous income. Used for example to accumulate
	 * the flashloan fee to the vault, and spread it between all the depositors
	 * @param vaultData The vault data
	 * @param totalLiquidity The total liquidity available in the vault
	 * @param amount The amount to accomulate
	 **/
	function cumulateToLiquidityIndex(
		VaultModel.Data memory vaultData,
		uint256 totalLiquidity,
		uint256 amount
	) internal pure {
		uint256 amountToLiquidityRatio = amount.wadToRay().rDiv(
			totalLiquidity.wadToRay()
		);

		uint256 result = amountToLiquidityRatio + WadRayMath.ray();

		result = result.rMul(vaultData.liquidityIndex);
		if (result > type(uint128).max) {
			revert LiquidityIndexOverflow();
		}

		vaultData.liquidityIndex = uint128(result);
	}

	struct UpdateInterestRatesLocalVars {
		address stableCreditToken;
		uint256 availableLiquidity;
		uint256 totalStableDebt;
		uint256 newLiquidityRate;
		uint256 newStableRate;
		uint256 newVariableRate;
		uint256 avgStableRate;
		uint256 totalVariableDebt;
		uint256 reserveFactor;
	}

	/**
	 * @dev Updates the vault current stable credit rate, the current variable credit rate and the current liquidity rate
	 * @param vaultData The vault to be updated
	 * @param liquidityAdded The amount of liquidity added to the protocol (deposited or repaid) in the previous action
	 * @param liquidityTaken The amount of liquidity taken from the protocol (withdrawn or borrowed)
	 **/
	function updateInterestRates(
		VaultModel.Data memory vaultData,
		address vaultAddress,
		address vaultToken,
		uint256 liquidityAdded,
		uint256 liquidityTaken,
		function(address, uint256, uint256, uint256, uint256, uint256)
			external onInterestRateUpdate
	) internal {
		UpdateInterestRatesLocalVars memory vars;

		vars.stableCreditToken = vaultData.stableCreditToken;

		(vars.totalStableDebt, vars.avgStableRate) = IStableCreditToken(
			vars.stableCreditToken
		).getTotalSupplyAndAvgRate();

		//calculates the total variable debt locally using the scaled total supply instead
		//of totalSupply(), as it's noticeably cheaper. Also, the index has been
		//updated by the previous updateState() call
		vars.totalVariableDebt = IVariableCreditToken(
			vaultData.variableCreditToken
		).scaledTotalSupply().rMul(vaultData.variableCreditIndex);
		vars.reserveFactor = vaultData.config.getReserveFactor();

		(
			vars.newLiquidityRate,
			vars.newStableRate,
			vars.newVariableRate
		) = IInterestRateModel(vaultData.interestRateModel)
			.calculateInterestRates(
				vaultAddress,
				vaultToken,
				liquidityAdded,
				liquidityTaken,
				vars.totalStableDebt,
				vars.totalVariableDebt,
				vars.avgStableRate,
				vars.reserveFactor
			);

		if (vars.newLiquidityRate > type(uint128).max)
			revert LiquidityRateOverflow();
		if (vars.newStableRate > type(uint128).max)
			revert StableCreditRateOverflow();

		if (vars.newVariableRate > type(uint128).max)
			revert VariableCreditRateOverflow();

		vaultData.currentLiquidityRate = uint128(vars.newLiquidityRate);
		vaultData.currentStableCreditRate = uint128(vars.newStableRate);
		vaultData.currentVariableCreditRate = uint128(vars.newVariableRate);

		onInterestRateUpdate(
			vaultAddress,
			vars.newLiquidityRate,
			vars.newStableRate,
			vars.newVariableRate,
			vaultData.liquidityIndex,
			vaultData.variableCreditIndex
		);
	}

	struct AccrueToTreasuryLocalVars {
		uint256 currentStableDebt;
		uint256 principalStableDebt;
		uint256 previousStableDebt;
		uint256 currentVariableDebt;
		uint256 previousVariableDebt;
		uint256 avgStableRate;
		uint256 cumulatedStableInterest;
		uint256 totalDebtAccrued;
		uint256 amountToMint;
		uint256 reserveFactor;
		uint40 stableSupplyUpdatedTimestamp;
	}

	/**
	 * @dev Mints part of the repaid interest to the vault treasury as a function of the reserveFactor for the
	 * specific asset.
	 * @param vaultData The vault to be updated
	 * @param scaledVariableDebt The current scaled total variable debt
	 * @param previousVariableCreditIndex The variable credit index before the last accumulation of the interest
	 * @param newLiquidityIndex The new liquidity index
	 * @param newVariableCreditIndex The variable credit index after the last accumulation of the interest
	 **/
	function _accrueToTreasury(
		VaultModel.Data memory vaultData,
		uint256 scaledVariableDebt,
		uint256 previousVariableCreditIndex,
		uint256 newLiquidityIndex,
		uint256 newVariableCreditIndex,
		uint40 timestamp
	) internal {
		AccrueToTreasuryLocalVars memory vars;

		vars.reserveFactor = vaultData.config.getReserveFactor();

		if (vars.reserveFactor == 0) {
			return;
		}

		//fetching the principal, total stable debt and the avg stable rate
		(
			vars.principalStableDebt,
			vars.currentStableDebt,
			vars.avgStableRate,
			vars.stableSupplyUpdatedTimestamp
		) = IStableCreditToken(vaultData.stableCreditToken).getSupplyData();

		//calculate the last principal variable debt
		vars.previousVariableDebt = scaledVariableDebt.rMul(
			previousVariableCreditIndex
		);

		//calculate the new total supply after accumulation of the index
		vars.currentVariableDebt = scaledVariableDebt.rMul(
			newVariableCreditIndex
		);

		//calculate the stable debt until the last timestamp update
		vars.cumulatedStableInterest = InterestMath.compoundInterest(
			vars.avgStableRate,
			vars.stableSupplyUpdatedTimestamp,
			timestamp
		);

		vars.previousStableDebt = vars.principalStableDebt.rMul(
			vars.cumulatedStableInterest
		);

		//debt accrued is the sum of the current debt minus the sum of the debt at the last update
		vars.totalDebtAccrued =
			vars.currentVariableDebt +
			vars.currentStableDebt -
			vars.previousVariableDebt -
			vars.previousStableDebt;

		vars.amountToMint = vars.totalDebtAccrued.percentMul(
			vars.reserveFactor
		);

		if (vars.amountToMint != 0) {
			IVaultToken(vaultData.vaultToken).accrueToTreasury(
				vars.amountToMint,
				newLiquidityIndex
			);
		}
	}

	/**
	 * @dev Updates the vault indexes and the timestamp of the update
	 * @param vaultData The vault to be updated
	 * @param scaledVariableDebt The scaled variable debt
	 * @param liquidityIndex The last stored liquidity index
	 * @param variableCreditIndex The last stored variable credit index
	 **/
	function _updateIndexes(
		VaultModel.Data memory vaultData,
		uint256 scaledVariableDebt,
		uint256 liquidityIndex,
		uint256 variableCreditIndex,
		uint40 timestamp
	) internal view returns (uint256, uint256) {
		uint256 currentLiquidityRate = vaultData.currentLiquidityRate;

		uint256 newLiquidityIndex = liquidityIndex;
		uint256 newVariableCreditIndex = variableCreditIndex;

		//only cumulating if there is any income being produced
		if (currentLiquidityRate > 0) {
			uint256 cumulatedLiquidityInterest = InterestMath.linearInterest(
				currentLiquidityRate,
				timestamp
			);
			newLiquidityIndex = cumulatedLiquidityInterest.rMul(liquidityIndex);

			if (newLiquidityIndex > type(uint128).max)
				revert LiquidityIndexOverflow();

			vaultData.liquidityIndex = uint128(newLiquidityIndex);

			//as the liquidity rate might come only from stable rate loans, we need to ensure
			//that there is actual variable debt before accumulating
			if (scaledVariableDebt != 0) {
				uint256 cumulatedVariableBorrowInterest = InterestMath
					.compoundInterest(
						vaultData.currentVariableCreditRate,
						timestamp
					);
				newVariableCreditIndex = cumulatedVariableBorrowInterest.rMul(
					variableCreditIndex
				);
				if (newVariableCreditIndex > type(uint128).max)
					revert VariableCreditIndexOverflow();

				vaultData.variableCreditIndex = uint128(newVariableCreditIndex);
			}
		}

		//solhint-disable-next-line not-rely-on-time
		vaultData.lastUpdateTimestamp = uint40(block.timestamp);
		return (newLiquidityIndex, newVariableCreditIndex);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/AccountModel.sol";

/**
 * @title Account Controller library
 * @author eaZI
 * @notice Implements Accounts configuration setters & getters on all group protocols(e.g Savings and Credit)
 */
library AccountController {
	uint256 internal constant IS_BORROWING_MASK =
		0x5555555555555555555555555555555555555555555555555555555555555555;

	/**
	 * @dev Sets if the account is borrowing from the vault `vaultID`
	 * @param self The config data
	 * @param vaultID The vault index
	 * @param borrowing True if the account is borrowing from the vault, false otherwise
	 **/
	function isBorrowingFromVault(
		AccountModel.Config memory self,
		uint256 vaultID,
		bool borrowing
	) internal pure {
		self.data =
			(self.data & ~(1 << (vaultID * 2))) |
			(uint256(borrowing ? 1 : 0) << (vaultID * 2));
	}

	/**
	 * @dev Used to check if account is borrowing from vault
	 * @param self The config data
	 * @param vaultID The vault ID
	 * @return True if `account` use `vaultID` for borrowing, false otherwise
	 **/
	function isBorrowingFromVault(
		AccountModel.Config memory self,
		uint256 vaultID
	) internal pure returns (bool) {
		return (self.data >> (vaultID * 2)) & 1 != 0;
	}

	/**
	 * @dev Sets if the account is using the vault `vaultID` as collateral
	 * @param self The config data
	 * @param vaultID The vault ID
	 * @param usingAsCollateral True enables account as using the vault as collateral, false otherwise
	 **/
	function vaultIsCollateral(
		AccountModel.Config memory self,
		uint256 vaultID,
		bool usingAsCollateral
	) internal pure {
		self.data =
			(self.data & ~(1 << (vaultID * 2 + 1))) |
			(uint256(usingAsCollateral ? 1 : 0) << (vaultID * 2 + 1));
	}

	/**
	 * @dev Used to validate if an account has been using the vault as collateral
	 * @param self The config data
	 * @param vaultID The vault ID
	 * @return True if `account` use vault as collateral, false otherwise
	 **/
	function vaultIsCollateral(AccountModel.Config memory self, uint256 vaultID)
		internal
		pure
		returns (bool)
	{
		return (self.data >> (vaultID * 2 + 1)) & 1 != 0;
	}

	/**
	 * @dev Used to validate if an account has been using the vault for borrowing or as collateral
	 * @param self The config data
	 * @param vaultID The vault ID
	 * @return True if `account` use `vaultID` for borrowing or as collateral, false otherwise
	 **/
	function isVaultCollateralOrBorrowedFrom(
		AccountModel.Config memory self,
		uint256 vaultID
	) internal pure returns (bool) {
		return (self.data >> (vaultID * 2)) & 3 != 0;
	}

	/**
	 * @dev Used to validate if an account has been borrowing from any vault
	 * @param self The config data
	 * @return True if the account has been borrowing from any vault, false otherwise
	 **/
	function isBorrowingAny(AccountModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return self.data & IS_BORROWING_MASK != 0;
	}

	/**
	 * @dev Used to validate if an account has not been using any vault
	 * @param self The config data
	 * @return True if the account has been using any vault, false otherwise
	 **/
	function isEmpty(AccountModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return self.data == 0;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../model/VaultModel.sol";

/**
 * @title Vault Config Controller library
 * @author eaZI
 * @notice Implements Vault(e.g Savings and Credit, etc) configuration setters & getters
 */
library VaultConfigController {
	/// Invalid LTV
	error InvalidLTV();

	/// Invalid Liquidation Threshold
	error InvalidLiquidationThreshold();

	/// Invalid Liquidation Bonus
	error InvalidLiquidationBonus();

	/// Invalid Decimals
	error InvalidDecimals();

	/// Invalid Reserve Factor
	error InvalidReserveFactor();

	uint256 internal constant LTV_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000;
	uint256 internal constant LIQUIDATION_THRESHOLD_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF;
	uint256 internal constant LIQUIDATION_BONUS_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF;
	uint256 internal constant DECIMALS_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF;
	uint256 internal constant ACTIVE_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF;
	uint256 internal constant FROZEN_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF;
	uint256 internal constant CREDIT_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF;
	uint256 internal constant STABLE_CREDIT_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF;
	uint256 internal constant RESERVE_FACTOR_MASK =
		0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;

	/// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
	uint256 internal constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
	uint256 internal constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
	uint256 internal constant VAULT_DECIMALS_START_BIT_POSITION = 48;
	uint256 internal constant IS_ACTIVE_START_BIT_POSITION = 56;
	uint256 internal constant IS_FROZEN_START_BIT_POSITION = 57;
	uint256 internal constant CREDIT_ENABLED_START_BIT_POSITION = 58;
	uint256 internal constant STABLE_CREDIT_ENABLED_START_BIT_POSITION = 59;
	uint256 internal constant RESERVE_FACTOR_START_BIT_POSITION = 64;

	uint256 internal constant MAX_VALID_LTV = 65535;
	uint256 internal constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
	uint256 internal constant MAX_VALID_LIQUIDATION_BONUS = 65535;
	uint256 internal constant MAX_VALID_DECIMALS = 255;
	uint256 internal constant MAX_VALID_RESERVE_FACTOR = 65535;

	/**
	 * @dev Sets the Loan to Value of the vault
	 * @param self The vault configuration
	 * @param ltv the new ltv
	 **/
	function setLtv(VaultModel.Config memory self, uint256 ltv) internal pure {
		if (ltv > MAX_VALID_LTV) {
			revert InvalidLTV();
		}

		self.data = (self.data & LTV_MASK) | ltv;
	}

	/**
	 * @dev Gets the Loan to Value of the vault
	 * @param self The vault configuration
	 * @return The loan to value
	 **/
	function getLtv(VaultModel.Config memory self)
		internal
		pure
		returns (uint256)
	{
		return self.data & ~LTV_MASK;
	}

	/**
	 * @dev Sets the liquidation threshold of the vault
	 * @param self The vault configuration
	 * @param threshold The new liquidation threshold
	 **/
	function setLiquidationThreshold(
		VaultModel.Config memory self,
		uint256 threshold
	) internal pure {
		if (threshold > MAX_VALID_LIQUIDATION_THRESHOLD) {
			revert InvalidLiquidationThreshold();
		}

		self.data =
			(self.data & LIQUIDATION_THRESHOLD_MASK) |
			(threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation threshold of the vault
	 * @param self The vault configuration
	 * @return The liquidation threshold
	 **/
	function getLiquidationThreshold(VaultModel.Config memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
			LIQUIDATION_THRESHOLD_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the liquidation bonus of the vault
	 * @param self The vault configuration
	 * @param bonus The new liquidation bonus
	 **/
	function setLiquidationBonus(VaultModel.Config memory self, uint256 bonus)
		internal
		pure
	{
		if (bonus > MAX_VALID_LIQUIDATION_BONUS) {
			revert InvalidLiquidationBonus();
		}

		self.data =
			(self.data & LIQUIDATION_BONUS_MASK) |
			(bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the liquidation bonus of the vault
	 * @param self The vault configuration
	 * @return The liquidation bonus
	 **/
	function getLiquidationBonus(VaultModel.Config memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~LIQUIDATION_BONUS_MASK) >>
			LIQUIDATION_BONUS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the decimals of the underlying asset of the vault
	 * @param self The vault configuration
	 * @param decimals The decimals
	 **/
	function setDecimals(VaultModel.Config memory self, uint256 decimals)
		internal
		pure
	{
		if (decimals > MAX_VALID_DECIMALS) {
			revert InvalidDecimals();
		}

		self.data =
			(self.data & DECIMALS_MASK) |
			(decimals << VAULT_DECIMALS_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the decimals of the underlying asset of the vault
	 * @param self The vault configuration
	 * @return The decimals of the asset
	 **/
	function getDecimals(VaultModel.Config memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~DECIMALS_MASK) >> VAULT_DECIMALS_START_BIT_POSITION;
	}

	/**
	 * @dev Sets the active state of the vault
	 * @param self The vault configuration
	 * @param active The active state
	 **/
	function setActive(VaultModel.Config memory self, bool active)
		internal
		pure
	{
		self.data =
			(self.data & ACTIVE_MASK) |
			(uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the active state of the vault
	 * @param self The vault configuration
	 * @return The active state
	 **/
	function getActive(VaultModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~ACTIVE_MASK) != 0;
	}

	/**
	 * @dev Sets the frozen state of the vault
	 * @param self The vault configuration
	 * @param frozen The frozen state
	 **/
	function setFrozen(VaultModel.Config memory self, bool frozen)
		internal
		pure
	{
		self.data =
			(self.data & FROZEN_MASK) |
			(uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the frozen state of the vault
	 * @param self The vault configuration
	 * @return The frozen state
	 **/
	function getFrozen(VaultModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~FROZEN_MASK) != 0;
	}

	/**
	 * @dev Enables or disables credit on the vault
	 * @param self The vault configuration
	 * @param enabled True if the credit needs to be enabled, false otherwise
	 **/
	function setCreditEnabled(VaultModel.Config memory self, bool enabled)
		internal
		pure
	{
		self.data =
			(self.data & CREDIT_MASK) |
			(uint256(enabled ? 1 : 0) << CREDIT_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the credit state of the vault
	 * @param self The vault configuration
	 * @return The credit state
	 **/
	function getCreditEnabled(VaultModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~CREDIT_MASK) != 0;
	}

	/**
	 * @dev Enables or disables stable credit on the vault
	 * @param self The vault configuration
	 * @param enabled True if the stable credit needs to be enabled, false otherwise
	 **/
	function setStableCreditEnabled(VaultModel.Config memory self, bool enabled)
		internal
		pure
	{
		self.data =
			(self.data & STABLE_CREDIT_MASK) |
			(uint256(enabled ? 1 : 0) <<
				STABLE_CREDIT_ENABLED_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the stable credit state of the vault
	 * @param self The vault configuration
	 * @return The stable credit state
	 **/
	function getStableCreditEnabled(VaultModel.Config memory self)
		internal
		pure
		returns (bool)
	{
		return (self.data & ~STABLE_CREDIT_MASK) != 0;
	}

	/**
	 * @dev Sets the vault factor of the vault
	 * @param self The vault configuration
	 * @param reserveFactor The vault factor
	 **/
	function setReserveFactor(
		VaultModel.Config memory self,
		uint256 reserveFactor
	) internal pure {
		if (reserveFactor > MAX_VALID_RESERVE_FACTOR) {
			revert InvalidReserveFactor();
		}

		self.data =
			(self.data & RESERVE_FACTOR_MASK) |
			(reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
	}

	/**
	 * @dev Gets the vault factor of the vault
	 * @param self The vault configuration
	 * @return The vault factor
	 **/
	function getReserveFactor(VaultModel.Config memory self)
		internal
		pure
		returns (uint256)
	{
		return
			(self.data & ~RESERVE_FACTOR_MASK) >>
			RESERVE_FACTOR_START_BIT_POSITION;
	}

	/**
	 * @dev Gets the configuration flags of the vault
	 * @param self The vault configuration
	 * @return The state flags representing active, frozen, credit enabled, stableRateCredit enabled
	 **/
	function getFlags(VaultModel.Config memory self)
		internal
		pure
		returns (
			bool,
			bool,
			bool,
			bool
		)
	{
		return (
			(self.data & ~ACTIVE_MASK) != 0,
			(self.data & ~FROZEN_MASK) != 0,
			(self.data & ~CREDIT_MASK) != 0,
			(self.data & ~STABLE_CREDIT_MASK) != 0
		);
	}

	/**
	 * @dev Gets the configuration paramters of the vault
	 * @param self The vault configuration
	 * @return The state params representing ltv, liquidation threshold, liquidation bonus, the vault decimals
	 **/
	function getParams(VaultModel.Config memory self)
		internal
		pure
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		return (
			self.data & ~LTV_MASK,
			(self.data & ~LIQUIDATION_THRESHOLD_MASK) >>
				LIQUIDATION_THRESHOLD_START_BIT_POSITION,
			(self.data & ~LIQUIDATION_BONUS_MASK) >>
				LIQUIDATION_BONUS_START_BIT_POSITION,
			(self.data & ~DECIMALS_MASK) >> VAULT_DECIMALS_START_BIT_POSITION,
			(self.data & ~RESERVE_FACTOR_MASK) >>
				RESERVE_FACTOR_START_BIT_POSITION
		);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* math utils */
import { WadRayMath } from "../utils/WadRayMath.sol";
/* models */
import { VaultModel } from "../model/VaultModel.sol";
import { AccountModel } from "../model/AccountModel.sol";
/* vaildators */
import { AccountValidator } from "../validator/AccountValidator.sol";
/* interfaces */
import { ICoreController } from "../interface/ICoreController.sol";
/* types */
import { SharedTypes } from "../type/SharedTypes.sol";

/**
 * @title CoreLogic library
 * @author eazi
 * @notice Implements the base logic for all the core actions related to the Group
 */
library CoreLogic {
	/* errors */
	/// Vault has already been initialized
	error VaultAlreadyExist();

	/// Vault already initialized
	error VaultAlreadyInitialized();

	/* events */
	event AccountCreated(address indexed account, uint256 indexed accountID);

	/**
	 * @notice Implements the account numbering feature of the Group.
	 * @dev Emits the `AccountCreated()` event.
	 */
	function executeCreateAccount(
		address account,
		AccountModel.Data storage storedAccount,
		mapping(uint256 => address) storage accountIDs,
		uint256 newAccountID
	) external returns (uint256) {
		// create ID and assign to account
		accountIDs[newAccountID] = account;

		storedAccount.id = newAccountID;

		emit AccountCreated(account, newAccountID);

		return newAccountID;
	}

	/**
	 * @notice Implements the vault initialization feature of the Group.
	 * @dev Initializes a vault
	 * @param vaultData The vault data
	 * @param vaultToken The overlying token
	 * @param interestRateModel The interest rate model
	 */
	function executeInitializeVault(
		address asset, //Skipped IERC20 to avoid incompatibility issues with bytes32(name & symbol)
		address vaultToken,
		address stableCreditToken,
		address variableCreditToken,
		address interestRateModel,
		address[] storage _vaultsList,
		VaultModel.Data storage vaultData
	) external {
		// mapping(address => VaultModel.Data) storage _vaults
		if (vaultData.vaultToken != address(0)) {
			revert VaultAlreadyExist();
		}

		vaultData.liquidityIndex = uint128(WadRayMath.ray());
		vaultData.variableCreditIndex = uint128(WadRayMath.ray());
		vaultData.vaultToken = vaultToken;
		vaultData.stableCreditToken = stableCreditToken;
		vaultData.variableCreditToken = variableCreditToken;
		vaultData.interestRateModel = interestRateModel;

		bool vaultExists = vaultData.id != 0;
		bool isFirstVault = _vaultsList.length > 0 && _vaultsList[0] == asset;

		if (vaultExists || isFirstVault) {
			revert VaultAlreadyInitialized();
		}

		_vaultsList.push(asset);
		vaultData.id = uint8(_vaultsList.length - 1);
	}

	function executeGetAccountData(
		ICoreController coreController,
		address account,
		AccountModel.Config memory accountConfig,
		address[] memory vaults,
		address oracle
	)
		external
		view
		returns (
			/* Savings Data */
			uint256 savingsBalanceInBaseCurrency,
			/* Credit Data */
			uint256 outstandingDebtInBaseCurrency,
			uint256 availableCreditInBaseCurrency,
			uint256 currentLiquidationThreshold,
			uint256 ltv,
			uint256 healthFactor
		)
	{
		(
			savingsBalanceInBaseCurrency,
			outstandingDebtInBaseCurrency,
			ltv,
			currentLiquidationThreshold,
			healthFactor
		) = AccountValidator.calculateAccountData(
			account,
			coreController.getVaultData,
			accountConfig,
			vaults,
			oracle
		);

		availableCreditInBaseCurrency = AccountValidator
			.calculateAvailableCreditsInBaseCurrency(
				savingsBalanceInBaseCurrency,
				outstandingDebtInBaseCurrency,
				ltv
			);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISuperERC20.sol";
import "./ICoreController.sol";

interface ICreditToken is ISuperERC20 {
	/* errors */
	/// ERC20 Interface Not Supported
	/// emitted when unsupported ERC20 interfaces get called
	error InterfaceNotSupported();

	/// Credit Allowance not enough
	error AllowanceNotEnough();

	/// Invalid delegator
	error InvalidDelegator();

	/// Permit signature expired
	error SignatureExpired();

	/// Invalid signature
	error InvalidSignature();

	/* events */
	event CreditAllowanceDelegated(
		address indexed from,
		address indexed to,
		address asset,
		uint256 amount
	);

	/**
	 * @dev delegates credit power to `to` on this credit token
	 * @param to the account receiving the delegated credit power
	 * @param amount the maximum amount being delegated. Delegation will still
	 * respect the liquidation constraints (even if delegated, a delegatee cannot
	 * force a delegator HF to go below 1)
	 **/
	function delegateCredit(address to, uint256 amount) external;

	/**
	 * @dev returns the credit allowance of the `spender`
	 * @param owner The account owner who is giving allowance
	 * @param spender The spender account who receives allowance to borrow on behalf of `owner`
	 * @return the current credit allowance of `spender`
	 **/
	function creditAllowance(address owner, address spender)
		external
		view
		returns (uint256);

	/**
	 * @dev Credit delegation with ERC712 signature
	 * @param owner The credit delegator
	 * @param spender The spender of the credit
	 * @param value The credit amount
	 * @param deadline The deadline timestamp, type(uint256).max for max deadline
	 * @param v Signature param
	 * @param s Signature param
	 * @param r Signature param
	 */
	function delegateCreditBySig(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/// @title erc20.super() contract acting as a base for ERC20 with rewards distribution callback
/// @author eaZI
interface ISuperERC20 is IERC20Upgradeable {
	/// Token is Paused
	error IsPaused();

	/// Can only be called by partner group
	error NotGroup();

	/// Can only be called by configurator
	error NotConfigurator();

	/// Can only be called by upgrader
	error NotUpgrader();

	/// Invalid amount to mint
	error InvalidMintAmount();

	/// Invalid amount to burn
	error InvalidBurnAmount();

	/**
	 * @dev Emitted after the mint action
	 * @param to The account minted to
	 * @param amount The amount being minted
	 * @param index The vault's new liquidity index
	 **/
	event Mint(address indexed to, uint256 amount, uint256 index);

	/**
	 * @dev Emitted after vaultTokens are burned
	 * @param from The owner of the vaultTokens getting burned
	 * @param to The account that will receive the underlying token
	 * @param amount The amount being burned
	 * @param index The vault's new liquidity index
	 **/
	event Burn(
		address indexed from,
		address indexed to,
		uint256 amount,
		uint256 index
	);

	/**
	 * @dev Emitted during vault transfer action
	 * @param from The account whose vault tokens are being transferred
	 * @param to The recipient
	 * @param amount The amount being transferred
	 * @param index The vault's new liquidity index
	 **/
	event VaultTransfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		uint256 index
	);

	function underlying() external view returns (address);

	function underlyingSymbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.0;

/**
 * @title WadRayMath library
 * @author eaZI
 * @notice DSMath library for uint256
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
	/* errors */
	/// Multiplication Overflow
	error MultiplicationOverflow();
	/// Division by Zero
	error DivisionByZero();
	/// Addition Overflow
	error AdditionOverflow();

	uint256 internal constant WAD = 1e18;
	uint256 internal constant halfWAD = WAD / 2;

	uint256 internal constant RAY = 1e27;
	uint256 internal constant halfRAY = RAY / 2;

	uint256 internal constant WAD_RAY_RATIO = 1e9;

	/**
	 * @return One ray, 1e27
	 **/
	function ray() internal pure returns (uint256) {
		return RAY;
	}

	/**
	 * @return One wad, 1e18
	 **/

	function wad() internal pure returns (uint256) {
		return WAD;
	}

	/**
	 * @return Half ray, 1e27/2
	 **/
	function halfRay() internal pure returns (uint256) {
		return halfRAY;
	}

	/**
	 * @return Half ray, 1e18/2
	 **/
	function halfWad() internal pure returns (uint256) {
		return halfWAD;
	}

	/**
	 * @dev Multiplies two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a*b, in wad
	 **/
	function wMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		if (a > (type(uint256).max - halfWAD) / b)
			revert MultiplicationOverflow();

		return (a * b + halfWAD) / WAD;
	}

	/**
	 * @dev Divides two wad, rounding half up to the nearest wad
	 * @param a Wad
	 * @param b Wad
	 * @return The result of a/b, in wad
	 **/
	function wDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		if (b == 0) revert DivisionByZero();

		uint256 halfB = b / 2;

		if (a > (type(uint256).max - halfB) / WAD)
			revert MultiplicationOverflow();

		return (a * WAD + halfB) / b;
	}

	/**
	 * @dev Multiplies two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a*b, in ray
	 **/
	function rMul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0 || b == 0) {
			return 0;
		}

		if (a > (type(uint256).max - halfRAY) / b)
			revert MultiplicationOverflow();

		return (a * b + halfRAY) / RAY;
	}

	/**
	 * @dev Divides two ray, rounding half up to the nearest ray
	 * @param a Ray
	 * @param b Ray
	 * @return The result of a/b, in ray
	 **/
	function rDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		if (b == 0) revert DivisionByZero();

		uint256 halfB = b / 2;

		if (a > (type(uint256).max - halfB) / RAY)
			revert MultiplicationOverflow();

		return (a * RAY + halfB) / b;
	}

	/**
	 * @dev Casts ray down to wad
	 * @param a Ray
	 * @return a casted to wad, rounded half up to the nearest wad
	 **/
	function rayToWad(uint256 a) internal pure returns (uint256) {
		uint256 halfRatio = WAD_RAY_RATIO / 2;
		uint256 result = halfRatio + a;
		if (result < halfRatio) revert AdditionOverflow();

		return result / WAD_RAY_RATIO;
	}

	/**
	 * @dev Converts wad up to ray
	 * @param a Wad
	 * @return a converted in ray
	 **/
	function wadToRay(uint256 a) internal pure returns (uint256) {
		uint256 result = a * WAD_RAY_RATIO;
		if (result / WAD_RAY_RATIO != a) revert MultiplicationOverflow();

		return result;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title PercentageMath library
 * @author eaZI
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00).
 * The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/
library PercentageMath {
	/* errors */
	/// Percentage Multiplication Overflow
	error PercentageMultiplicationOverflow();
	/// Percentage Division by Zero
	error PercentageDivisionByZero();

	uint256 internal constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
	uint256 internal constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

	/**
	 * @dev Executes a percentage multiplication
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The percentage of value
	 **/
	function percentMul(uint256 value, uint256 percentage)
		internal
		pure
		returns (uint256)
	{
		if (value == 0 || percentage == 0) {
			return 0;
		}

		if (value > (type(uint256).max - HALF_PERCENT) / percentage)
			revert PercentageMultiplicationOverflow();

		return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
	}

	/**
	 * @dev Executes a percentage division
	 * @param value The value of which the percentage needs to be calculated
	 * @param percentage The percentage of the value to be calculated
	 * @return The value divided the percentage
	 **/
	function percentDiv(uint256 value, uint256 percentage)
		internal
		pure
		returns (uint256)
	{
		if (percentage == 0) {
			revert PercentageDivisionByZero();
		}

		uint256 halfPercentage = percentage / 2;

		if (value > (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR)
			revert PercentageMultiplicationOverflow();

		return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./WadRayMath.sol";

/// @title InterestMath library
/// @author eaZI
/// @notice Interest Rate Calculator with linear and compound mode
library InterestMath {
	using WadRayMath for uint256;

	/// @dev Ignoring leap years
	uint256 internal constant A_YEAR = 365 days;

	/**
	 * @dev Function to calculate the interest accumulated using a linear interest rate formula
	 * @param rate The interest rate, in ray
	 * @param lastUpdateTimestamp The timestamp of the last update of the interest
	 * @return The interest rate linearly accumulated during the timeDelta, in ray
	 **/

	function linearInterest(uint256 rate, uint40 lastUpdateTimestamp)
		internal
		view
		returns (uint256)
	{
		//solhint-disable-next-line not-rely-on-time
		uint256 timeDifference = block.timestamp - uint256(lastUpdateTimestamp);

		return ((rate * timeDifference) / A_YEAR) + WadRayMath.ray();
	}

	/**
	 * @dev Function to calculate the interest using a compounded interest rate formula
	 * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
	 *
	 *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
	 *
	 * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
	 * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
	 *
	 * @param rate The interest rate, in ray
	 * @param lastUpdateTimestamp The timestamp of the last update of the interest
	 * @return The interest rate compounded during the timeDelta, in ray
	 **/
	function compoundInterest(
		uint256 rate,
		uint40 lastUpdateTimestamp,
		uint256 currentTimestamp
	) internal pure returns (uint256) {
		//solhint-disable-next-line not-rely-on-time
		uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

		if (exp == 0) {
			return WadRayMath.ray();
		}

		uint256 expMinusOne = exp - 1;

		uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

		uint256 ratePerSecond = rate / A_YEAR;

		uint256 basePowerTwo = ratePerSecond.rMul(ratePerSecond);
		uint256 basePowerThree = basePowerTwo.rMul(ratePerSecond);

		uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
		uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6; // prettier-ignore

		return
			WadRayMath.ray() + (ratePerSecond * exp) + secondTerm + thirdTerm;
	}

	/**
	 * @dev Calculates the compounded interest between the timestamp of the last update and the current block timestamp
	 * @param rate The interest rate (in ray)
	 * @param lastUpdateTimestamp The timestamp from which the interest accumulation needs to be calculated
	 **/
	function compoundInterest(uint256 rate, uint40 lastUpdateTimestamp)
		internal
		view
		returns (uint256)
	{
		//solhint-disable-next-line not-rely-on-time
		return compoundInterest(rate, lastUpdateTimestamp, block.timestamp);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IInterestRateModel interface
 * @dev Interest Rate Model
 * @author eaZI
 */
interface IInterestRateModel {
	function baseVariableCreditRate() external view returns (uint256);

	function getMaxVariableCreditRate() external view returns (uint256);

	function calculateInterestRates(
		address vault,
		uint256 availableLiquidity,
		uint256 totalStableDebt,
		uint256 totalVariableDebt,
		uint256 averageStableCreditRate,
		uint256 reserveFactor
	)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function calculateInterestRates(
		address vault,
		address vaultToken,
		uint256 liquidityAdded,
		uint256 liquidityTaken,
		uint256 totalStableDebt,
		uint256 totalVariableDebt,
		uint256 averageStableCreditRate,
		uint256 reserveFactor
	)
		external
		view
		returns (
			uint256 liquidityRate,
			uint256 stableCreditRate,
			uint256 variableCreditRate
		);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* interfaces */
import "./ISuperERC20.sol"; //erc20.super()
import "./ICoreController.sol";

interface IVaultToken is ISuperERC20 {
	/* errors */
	/// Invalid owner, usually when 0x address is used
	error InvalidOwner();

	/// Flash loan amount exceeded max allowed
	error MaxFlashLoanExceeded();

	/// Flash loan repayment(loaned amount + fee) not approved
	error RepaymentNotApproved();

	/// Unexpected flash loan token, `token` should always be this vaultToken
	error UnExpectedToken();

	/// Unexpected flash loan callback value
	error UnExpectedCallbackValue();

	/// Method locked for reentrancy
	error ReentrancyGuard();

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	function mint(
		address to,
		uint256 amount,
		uint256 index
	) external returns (bool);

	function burn(
		address from,
		address to,
		uint256 amount,
		uint256 index
	) external;

	function accrueToTreasury(uint256 amount, uint256 index) external;

	/**
	 * @dev Transfers the underlying asset to `target`. Used by the group to transfer
	 * underlying assets in borrow(), withdraw() and flashLoan()
	 * @param to The recipient of the vaultTokens
	 * @param amount The amount getting transferred
	 **/
	function transferUnderlying(address to, uint256 amount) external;

	/**
	 * @dev callback on Repayment to execute actions on the vaultToken after a repayment.
	 * @param account The account executing the repayment
	 * @param amount The amount getting repaid
	 **/
	function onRepayment(address account, uint256 amount) external;

	/**
	 * @dev callback on vaultToken in the event of a credit being liquidated,
	 * in case the liquidator claims the vaultToken
	 * @param from The account getting liquidated, current owner of the vaultToken
	 * @param to The recipient
	 * @param value The amount of tokens getting transferred
	 **/
	function onLiquidation(
		address from,
		address to,
		uint256 value
	) external;

	/**
	 * @dev Returns the scaled balance of the account and the scaled total supply.
	 * @param account The account checked
	 * @return The scaled balance of the account
	 * @return The scaled total supply
	 **/
	function getScaledAccountBalanceAndSupply(address account)
		external
		view
		returns (uint256, uint256);

	/**
	 * @dev calculates the total supply of the specific vaultToken
	 * since the balance of every single account increases over time, the total supply
	 * does that too.
	 * @return the current total supply
	 **/
	// function totalSupply() external view override returns (uint256);

	/**
	 * @dev Returns the scaled total supply of the vault token. Represents sum(debt/index)
	 * @return the scaled total supply
	 **/
	function scaledTotalSupply() external view returns (uint256);

	/**
	 * @dev Returns the scaled balance of the `account`.
	 * @return the scaled balance
	 **/
	function scaledBalanceOf(address account) external view returns (uint256);

	function reserve() external view returns (address);

	function controller() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* lib deps */
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
/* math utils */
import { WadRayMath } from "../utils/WadRayMath.sol";
import { PercentageMath } from "../utils/PercentageMath.sol";
/* models */
import { VaultModel } from "../model/VaultModel.sol";
import { AccountModel } from "../model/AccountModel.sol";
/* controllers */
import { VaultController } from "../controller/VaultController.sol";
import { AccountController } from "../controller/AccountController.sol";
import { VaultConfigController } from "../controller/VaultConfigController.sol";
/* interfaces */
import { IPriceOracle } from "../interface/IPriceOracle.sol";

/**
 * @title AccountValidator library
 * @author eaZI
 * @notice Implements protocol-level controller to calculate and validate account's states
 */
library AccountValidator {
	using VaultController for VaultModel.Data;
	using WadRayMath for uint256;
	using PercentageMath for uint256;
	using VaultConfigController for VaultModel.Config;
	using AccountController for AccountModel.Config;

	uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

	struct BalanceDeductionAllowedLocalVars {
		uint256 decimals;
		uint256 liquidationThreshold;
		uint256 totalSavingsInBaseCurrency;
		uint256 totalDebtInBaseCurrency;
		uint256 avgLiquidationThreshold;
		uint256 amountToDecreaseInBaseCurrency;
		uint256 collateralBalanceAfterDecrease;
		uint256 liquidationThresholdAfterDecrease;
		uint256 healthFactorAfterDecrease;
	}

	/**
	 * @dev Checks if a specific balance decrease is allowed
	 * (i.e. doesn't bring the account borrow position health factor under HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
	 * @param asset The underlying asset of the vault
	 * @param account The account
	 * @param amount The amount to decrease
	 * @param vaultsData The data of all the vaults
	 * @param accountConfig The account configuration
	 * @param vaults The list of all the active vaults
	 * @param oracle The oracle contract
	 * @return true if the decrease of the balance is allowed
	 **/
	function balanceDeductionAllowed(
		address asset,
		address account,
		uint256 amount,
		function(address)
			external
			view
			returns (VaultModel.Data memory) vaultsData,
		AccountModel.Config calldata accountConfig,
		address[] memory vaults,
		address oracle
	) external view returns (bool) {
		VaultModel.Data memory cachedVaultData = vaultsData(asset);
		if (
			!accountConfig.isBorrowingAny() ||
			!accountConfig.vaultIsCollateral(cachedVaultData.id)
		) return true;

		BalanceDeductionAllowedLocalVars memory vars;

		(, vars.liquidationThreshold, , vars.decimals, ) = cachedVaultData
			.config
			.getParams();

		if (vars.liquidationThreshold == 0) {
			return true;
		}

		(
			vars.totalSavingsInBaseCurrency,
			vars.totalDebtInBaseCurrency,
			,
			vars.avgLiquidationThreshold,

		) = calculateAccountData(
			account,
			vaultsData,
			accountConfig,
			vaults,
			oracle
		);

		if (vars.totalDebtInBaseCurrency == 0) {
			return true;
		}

		vars.amountToDecreaseInBaseCurrency =
			(IPriceOracle(oracle).getAssetPrice(asset) * amount) /
			10**vars.decimals;

		vars.collateralBalanceAfterDecrease =
			vars.totalSavingsInBaseCurrency -
			vars.amountToDecreaseInBaseCurrency;

		//if there is a debt, there can't be 0 collateral
		if (vars.collateralBalanceAfterDecrease == 0) {
			return false;
		}

		vars.liquidationThresholdAfterDecrease =
			(vars.totalSavingsInBaseCurrency * vars.avgLiquidationThreshold) -
			(vars.amountToDecreaseInBaseCurrency * vars.liquidationThreshold) /
			vars.collateralBalanceAfterDecrease;

		uint256 healthFactorAfterDecrease = calculateHealthFactorFromBalances(
			vars.collateralBalanceAfterDecrease,
			vars.totalDebtInBaseCurrency,
			vars.liquidationThresholdAfterDecrease
		);

		return
			healthFactorAfterDecrease >=
			AccountValidator.HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
	}

	struct CalculateAccountDataVars {
		uint256 i;
		uint256 vaultUnitPrice;
		uint256 assetUnit;
		uint256 compoundedLiquidityBalance;
		uint256 compoundedDebt;
		uint256 decimals;
		uint256 ltv;
		uint256 liquidationThreshold;
		uint256 healthFactor;
		uint256 totalSavingsInBaseCurrency;
		uint256 totalDebtInBaseCurrency;
		uint256 avgLtv;
		uint256 avgLiquidationThreshold;
		address currentAsset;
	}

	/**
	 * @dev Calculates the account data across the vaults.
	 * this includes the total liquidity/collateral/borrow balances in Base Currency,
	 * the average Loan To Value, the average Liquidation Ratio, and the Health factor.
	 * @param account The account
	 * @param vaultsData Data of all the vaults
	 * @param accountConfig The account configuration
	 * @param vaults The list of the available vaults
	 * @param oracle The price oracle
	 * @return The total collateral and total debt of the account in Base Currency, the avg ltv, liquidation threshold and the HF
	 **/
	function calculateAccountData(
		address account,
		function(address)
			external
			view
			returns (VaultModel.Data memory) vaultsData,
		AccountModel.Config memory accountConfig,
		address[] memory vaults,
		address oracle
	)
		public
		view
		returns (
			uint256,
			uint256,
			uint256,
			uint256,
			uint256
		)
	{
		if (accountConfig.isEmpty()) {
			return (0, 0, 0, 0, type(uint256).max);
		}
		CalculateAccountDataVars memory vars;

		for (vars.i = 0; vars.i < vaults.length; vars.i++) {
			if (!accountConfig.isVaultCollateralOrBorrowedFrom(vars.i)) {
				continue;
			}

			vars.currentAsset = vaults[vars.i];
			VaultModel.Data memory currentvault = vaultsData(vars.currentAsset);

			(
				vars.ltv,
				vars.liquidationThreshold,
				,
				vars.decimals,

			) = currentvault.config.getParams();

			unchecked {
				vars.assetUnit = 10**vars.decimals;
			}
			vars.vaultUnitPrice = IPriceOracle(oracle).getAssetPrice(
				vars.currentAsset
			);

			if (
				vars.liquidationThreshold != 0 &&
				accountConfig.vaultIsCollateral(vars.i)
			) {
				vars.compoundedLiquidityBalance = IERC20Upgradeable(
					currentvault.vaultToken
				).balanceOf(account);

				uint256 liquidityBalanceInBaseCurrency = (vars.vaultUnitPrice *
					vars.compoundedLiquidityBalance) / vars.assetUnit;

				//TODO +=
				vars.totalSavingsInBaseCurrency =
					vars.totalSavingsInBaseCurrency +
					liquidityBalanceInBaseCurrency;

				//TODO +=
				vars.avgLtv =
					vars.avgLtv +
					(liquidityBalanceInBaseCurrency * vars.ltv);

				//TODO +=
				vars.avgLiquidationThreshold =
					vars.avgLiquidationThreshold +
					(liquidityBalanceInBaseCurrency *
						vars.liquidationThreshold);
			}

			if (accountConfig.isBorrowingFromVault(vars.i)) {
				vars.compoundedDebt = IERC20Upgradeable(
					currentvault.stableCreditToken
				).balanceOf(account);

				vars.compoundedDebt += IERC20Upgradeable(
					currentvault.variableCreditToken
				).balanceOf(account);

				vars.totalDebtInBaseCurrency =
					vars.totalDebtInBaseCurrency +
					((vars.vaultUnitPrice * vars.compoundedDebt) /
						vars.assetUnit);
			}
		}

		unchecked {
			vars.avgLtv = vars.totalSavingsInBaseCurrency != 0
				? vars.avgLtv / vars.totalSavingsInBaseCurrency
				: 0;
			vars.avgLiquidationThreshold = vars.totalSavingsInBaseCurrency != 0
				? vars.avgLiquidationThreshold / vars.totalSavingsInBaseCurrency
				: 0;
		}

		vars.healthFactor = calculateHealthFactorFromBalances(
			vars.totalSavingsInBaseCurrency,
			vars.totalDebtInBaseCurrency,
			vars.avgLiquidationThreshold
		);
		return (
			vars.totalSavingsInBaseCurrency,
			vars.totalDebtInBaseCurrency,
			vars.avgLtv,
			vars.avgLiquidationThreshold,
			vars.healthFactor
		);
	}

	/**
	 * @dev Calculates the health factor from the corresponding balances
	 * @param totalSavingsInBaseCurrency The total savings in Base Currency
	 * @param totalDebtInBaseCurrency The total debt in Base Currency
	 * @param liquidationThreshold The avg liquidation threshold
	 * @return The health factor calculated from the balances provided
	 **/
	function calculateHealthFactorFromBalances(
		uint256 totalSavingsInBaseCurrency,
		uint256 totalDebtInBaseCurrency,
		uint256 liquidationThreshold
	) public pure returns (uint256) {
		if (totalDebtInBaseCurrency == 0) {
			return type(uint256).max;
		}

		return
			(totalSavingsInBaseCurrency.percentMul(liquidationThreshold)).wDiv(
				totalDebtInBaseCurrency
			);
	}

	/**
	 * @dev Calculates the equivalent amount in Base Currency that an account can borrow,
	 * based on the available savings and the average Loan To Value
	 * @param totalSavingsInBaseCurrency The total savings balance in Base Currency
	 * @param totalDebtInInBaseCurrency The total debt in Base Currency
	 * @param ltv The average loan to value
	 * @return the amount available to borrow in Base Currency for the account
	 **/
	function calculateAvailableCreditsInBaseCurrency(
		uint256 totalSavingsInBaseCurrency,
		uint256 totalDebtInInBaseCurrency,
		uint256 ltv
	) public pure returns (uint256) {
		uint256 availableCreditInBaseCurrency = totalSavingsInBaseCurrency
			.percentMul(ltv);

		if (availableCreditInBaseCurrency < totalDebtInInBaseCurrency) {
			return 0;
		}

		availableCreditInBaseCurrency =
			availableCreditInBaseCurrency -
			totalDebtInInBaseCurrency;

		return availableCreditInBaseCurrency;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedTypes {
	/* Core */
	enum InterestRateMode {
		STABLE,
		VARIABLE
	}

	struct PermitSignature {
		uint256 amount;
		uint256 deadline;
		uint8 v;
		bytes32 r;
		bytes32 s;
	}

	/* SavungsCore */

	struct ExecuteWithdrawParams {
		address asset;
		uint256 amount;
		address to;
	}

	struct ValidateTransferParams {
		address asset;
		address from;
		address to;
		uint256 amount;
		uint256 balanceFromBefore;
		uint256 balanceToBefore;
	}

	/* LendingCore */
	struct ExecuteBorrowParams {
		address asset;
		address account;
		address onBehalfOf;
		address oracle;
		uint256 amount;
		uint256 interestRateMode;
	}

	struct ExecuteRepayParams {
		address asset;
		uint256 amount;
		uint256 rateMode;
		address onBehalfOf;
	}

	/* WalletCore */
	/**
	 * @dev Struct containing swap and repayment parameters
	 * @param initiator initiator account
	 * @param asset Savings asset to pull from Vault
	 * @param creditAsset credit token to repay
	 * @param amount Amount of Savings `asset` to pull
	 * @param amountToRepay Amount of the debt to be repaid, or maximum amount when repaying entire debt
	 * @param rateMode Rate mode of the debt to be repaid
	 * @param amountOffset Set to offset of fromAmount in Augustus calldata if wanting to swap all balance, otherwise 0
	 * @param swapData Paraswap data
	 * @param fee flash loan fee
	 * @param permitSignature struct containing the permit signature
	 */
	struct SwapAndRepayParams {
		uint256 fee;
		uint256 amount;
		uint256 amountOffset;
		uint256 amountToRepay;
		uint256 rateMode;
		bytes swapData;
		address initiator;
		address asset;
		address creditAsset;
		PermitSignature permitSignature;
	}

	/* Flashloan */
	struct ExecuteFlashLoanParams {
		address receiver;
		address asset;
		uint256 amount;
		bytes data;
	}

	struct ExecuteMultiFlashLoanParams {
		address receiver;
		address[] assets;
		uint256[] amounts;
		bytes data;
	}

	struct FlashLoanRepaymentParams {
		uint256 premium;
		uint256 amount;
		uint256 totalPremium;
		address asset;
		address receiver;
		address vaultToken;
	}

	/* GroupValidator */

	struct ValidateBorrowParams {
		address asset;
		address account;
		uint256 amount;
		uint256 amountInBaseCurrency;
		uint256 interestRateMode;
		uint256 maxStaticLoanPercent;
		address oracle;
		address[] vaults;
	}

	struct ValidateWithdrawParams {
		uint256 amount;
		uint256 accountBalance;
		address asset;
		address oracle;
		address[] vaults;
	}
}