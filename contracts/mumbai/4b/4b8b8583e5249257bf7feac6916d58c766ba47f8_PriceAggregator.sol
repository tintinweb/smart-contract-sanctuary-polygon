// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {HubOwnable} from "../base/HubOwnable.sol";
import {IPriceAggregator} from "../interfaces/IPriceAggregator.sol";

/// @title Drem Price Aggregator
/// Version 1.0.0

contract PriceAggregator is HubOwnable, UUPSUpgradeable, IPriceAggregator {
    // Chainlink price feeds that are denominated in ETH use 18 decimals
    // Reference: https://polygonscan.com/address/0x327e23A4855b6F663a28c5161541d69Af8973302#readContract#F3
    uint256 private constant CHAINLINK_ETH_UNITS = 1e18;

    // 'Heartbeats' for Chainlink's Polygon USD Aggregators are 30 seconds
    // 'Heartbeats' for Chainlink's Polygon ETH Aggregators are 24 hours
    // Reference:
    //  - https://docs.chain.link/data-feeds#check-the-timestamp-of-the-latest-answer
    //  - https://data.chain.link/polygon/mainnet/crypto-usd
    uint256 public constant STALE_USD_PRICE_LIMIT = 300;
    uint256 public constant STALE_ETH_PRICE_LIMIT = 24 hours;

    AggregatorV3Interface public immutable ETH_TO_USD_AGGREGATOR;

    mapping(address => DataTypes.SupportedAssetInfo) private assetToInfo;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    constructor(address _dremHub, address _ethToUSDAggregator) HubOwnable(_dremHub) {
        if (address(_ethToUSDAggregator) == address(0)) revert Errors.ZeroAddress();
        _validateAggregator(AggregatorV3Interface(_ethToUSDAggregator), DataTypes.RateAsset.USD);
        ETH_TO_USD_AGGREGATOR = AggregatorV3Interface(_ethToUSDAggregator);
        _disableInitializers();
    }

    ////////////////////
    ///     Admin    ///
    ////////////////////

    /**
     * @dev Admin function to add supported assets
     * @param _assets the addresses of the supported assets to add
     * @param _aggregators the addresses of the aggregators corresponding to each asset
     * @param _rateAssets the rate assets for the corresponding aggregators
     */
    function addSupportedAssets(
        address[] calldata _assets,
        AggregatorV3Interface[] calldata _aggregators,
        DataTypes.RateAsset[] calldata _rateAssets
    ) external onlyHubOwner {
        uint256 len = _assets.length;

        if (len == 0) revert Errors.EmptyArray();
        if (len != _aggregators.length || len != _rateAssets.length) revert Errors.InvalidAssetArrays();

        for (uint256 i; i < len;) {
            _addSupportedAsset(_assets[i], _aggregators[i], _rateAssets[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Admin function to remove supported assets
     * @param _assets the addresses of the supported assets to remove
     */
    function removeSupportedAssets(address[] calldata _assets) external onlyHubOwner {
        uint256 len = _assets.length;

        if (len == 0) revert Errors.EmptyArray();

        for (uint256 i; i < len;) {
            _removeSupportedAsset(_assets[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _addSupportedAsset(address _asset, AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset)
        internal
    {
        if (_asset == address(0) || address(_aggregator) == address(0)) revert Errors.ZeroAddress();

        _validateAggregator(_aggregator, _rateAsset);

        uint256 _units = 10 ** (ERC20(_asset).decimals());

        assetToInfo[_asset] =
            DataTypes.SupportedAssetInfo({aggregator: _aggregator, rateAsset: _rateAsset, units: _units});

        emit Events.SupportedAssetAdded(_asset, _aggregator, _rateAsset);
    }

    function _removeSupportedAsset(address _asset) internal {
        if (_asset == address(0)) revert Errors.ZeroAddress();

        DataTypes.SupportedAssetInfo memory _info = assetToInfo[_asset];

        delete assetToInfo[_asset];

        emit Events.SupportedAssetRemoved(_asset, _info.aggregator, _info.rateAsset);
    }

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Converts given amounts of input assets into an output asset
     * @param _inputAmounts the amounts of the input assets to convert
     * @param _inputAssets the input assets
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAssets(uint256[] calldata _inputAmounts, address[] calldata _inputAssets, address _outputAsset)
        external
        view
        returns (uint256)
    {
        if (_inputAmounts.length != _inputAssets.length) revert Errors.InvalidInputArrays();
        _validateAsset(_outputAsset);

        uint256 totalConversion;

        for (uint256 i; i < _inputAssets.length;) {
            _validateAsset(_inputAssets[i]);

            if (_inputAmounts[i] == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            uint256 conversion = _convert(_inputAmounts[i], _inputAssets[i], _outputAsset);

            totalConversion = totalConversion + conversion;

            unchecked {
                ++i;
            }
        }

        return totalConversion;
    }

    /**
     * @notice Converts amount of an input asset into an output asset
     * @param _inputAmount the amount of the input asset to convert
     * @param _inputAsset the input asset
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAsset(uint256 _inputAmount, address _inputAsset, address _outputAsset)
        external
        view
        returns (uint256)
    {
        if (_inputAmount == 0) return 0;

        _validateAsset(_inputAsset);
        _validateAsset(_outputAsset);

        uint256 conversion = _convert(_inputAmount, _inputAsset, _outputAsset);

        return conversion;
    }

    /**
     * @notice returns whether or not an asset is supported
     * @return returns true if an asset is supported, false otherwise
     */
    function isAssetSupported(address _asset) external view returns (bool) {
        return _isAssetSupported(_asset);
    }

    /**
     * @notice Returns the supported asset's info
     * @param _asset the asset to get the info for
     * @return the supported asset info
     */
    function getSupportedAssetInfo(address _asset) external view returns (DataTypes.SupportedAssetInfo memory) {
        return assetToInfo[_asset];
    }

    /////////////////////////////////
    ///     Internal Functions    ///
    /////////////////////////////////

    /**
     * @dev calculates and returns the conversion of a '_amount' of the '_inputAsset' into the '_outputAsset'
     * The input rate and output rate will should the same number of decimals when using Chainlink
     * However, the units of each asset will be different.  Therefore, need to multiply the amount by the output asset units
     */
    function _convert(uint256 _amount, address _inputAsset, address _outputAsset) internal view returns (uint256) {
        DataTypes.SupportedAssetInfo memory inputInfo = assetToInfo[_inputAsset];
        DataTypes.SupportedAssetInfo memory outputInfo = assetToInfo[_outputAsset];

        uint256 inputRate = _getLatestRate(inputInfo.aggregator, inputInfo.rateAsset);
        uint256 outputRate = _getLatestRate(outputInfo.aggregator, outputInfo.rateAsset);

        // Case A: Both rate assets are the same
        if (inputInfo.rateAsset == outputInfo.rateAsset) {
            return (_amount * inputRate * outputInfo.units) / (outputRate * inputInfo.units);
        }

        uint256 ethToUSDRate = _getLatestRate(ETH_TO_USD_AGGREGATOR, DataTypes.RateAsset.USD);

        // Note: The arithmetic for cases B and C are split into two calculations to account for overflow

        // Note: Rounding errors can occurs for cases B and C
        // If the output units are small, such as 10^6, too small of an input may produce a rounding error
        // For example, take the overflow adjusted amount for Case B:
        // uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
        // Chainlink units = 10^8 for USD rates.  Assume the following:
        // - The inputRate is 10^8
        // - The output units are 10^6
        // - The input units are 10^18
        // Any value for amount below 10^4 will produce a rounding error

        // These edgecases will be extremely rare considering that 10^4 of the input token will be a very small dollar amount

        // Case B: Input asset has a rate asset of USD, Output asset has a rate asset of ETH
        if (inputInfo.rateAsset == DataTypes.RateAsset.USD) {
            uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
            return (overflowAdjustment * CHAINLINK_ETH_UNITS) / (outputRate * ethToUSDRate);
        }
        // Case C: Input asset has a rate of ETH, Output asset has a rate asset of USD
        else {
            uint256 overflowAdjustment = (_amount * inputRate * outputInfo.units) / inputInfo.units;
            return (overflowAdjustment * ethToUSDRate) / (outputRate * CHAINLINK_ETH_UNITS);
        }
    }

    function _getLatestRate(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset)
        internal
        view
        returns (uint256)
    {
        (, int256 _answer,, uint256 _updatedAt,) = AggregatorV3Interface(_aggregator).latestRoundData();
        _validateRate(_answer, _updatedAt, _rateAsset);
        return uint256(_answer);
    }

    function _validateAsset(address _asset) internal view {
        if (!(_isAssetSupported(_asset))) revert Errors.AssetNotSupported();
    }

    function _isAssetSupported(address _asset) internal view returns (bool) {
        return address(assetToInfo[_asset].aggregator) != address(0);
    }

    function _validateAggregator(AggregatorV3Interface _aggregator, DataTypes.RateAsset _rateAsset) internal view {
        (, int256 _answer,, uint256 _updatedAt,) = AggregatorV3Interface(_aggregator).latestRoundData();
        _validateRate(_answer, _updatedAt, _rateAsset);
    }

    function _validateRate(int256 _answer, uint256 _updatedAt, DataTypes.RateAsset _rateAsset) internal view {
        if (!(_answer > 0)) revert Errors.InvalidAggregatorRate();

        if (_rateAsset == DataTypes.RateAsset.USD) {
            if ((block.timestamp - _updatedAt) > STALE_USD_PRICE_LIMIT) revert Errors.StaleUSDRate();
        }
        // _rateAsset == DataTypes.RateAsset.ETH
        else {
            if ((block.timestamp - _updatedAt) > STALE_ETH_PRICE_LIMIT) revert Errors.StaleEthRate();
        }
    }

    function _authorizeUpgrade(address) internal override onlyHubOwner {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

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
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
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
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";

// To Do: Order alphabetically
library DataTypes {
    /////////////////////////////
    ///   Global Data Types   ///
    ////////////////////////////

    // basic step routing information
    struct StepInfo {
        address interactionAddress;
        uint8 parentIndex;
        uint256 windPercent;
        bytes fixedArgData;
    }

    // user expectations for the withdrawal assets (can't check with oracles in worst-case)
    // note: the amount is not being stored or used often, so best to keep it as a uint256 in case users have a ton of a bespoke token
    struct AssetExpectation {
        address assetAddress;
        uint256 amount;
    }

    /**
     *  Unpaused: All protocol actions enabled
     *  Paused: Creation of new trade paused.  Copying and exiting trades still possible.
     *  Frozen: Copying and creating new trades paused.  Exiting trades still possible
     */
    enum ProtocolState {
        Unpaused,
        Paused,
        Frozen
    }

    /**
     *  Disabled: No functionality
     *  Deprecated: Unwind existing strategies
     *  Legacy: Wind and unwind existing strategies
     *  Enabled: Wind, unwind, create new strategies
     */
    enum StepState {
        Disabled,
        Deprecated,
        Legacy,
        Enabled
    }

    ///////////////////////////////////////
    ///   Price Aggregator Data Types   ///
    ///////////////////////////////////////

    enum RateAsset {
        USD,
        ETH
    }

    struct SupportedAssetInfo {
        AggregatorV3Interface aggregator;
        RateAsset rateAsset;
        uint256 units;
    }

    /////////////////////////////////////
    ///   Fee Controller Data Types   ///
    /////////////////////////////////////

    struct FeeInfo {
        uint24 entranceFee;
        uint24 exitFee;
        uint24 performanceFee;
        uint24 managementFee;
        address collector;
    }

    struct FeesPayable {
        uint256 dremFee;
        uint256 adminFee;
    }

    /////////////////////////////////////
    ///   Vault Deployer Data Types   ///
    /////////////////////////////////////

    struct DeploymentInfo {
        address admin;
        string name;
        string symbol;
        address denominationAsset;
        StepInfo[] steps;
        FeeInfo feeInfo;
    }

    //////////////////////////////////
    ///   Global Step Data Types   ///
    //////////////////////////////////

    struct UnwindInfo {
        uint256 sharesRedeemed;
        uint256 totalSupply;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    /////////////////////////
    ///   Global Errors   ///
    /////////////////////////

    /**
     *  Asset passed into removeDenominationAssets() is not a denomination asset
     */
    error AssetNotDenominationAsset();

    /**
     *  Asset passed into removeWhitelistedAssets() is not a whitelisted asset
     */
    error AssetNotWhitelisted();

    /**
     *  Asset is not supported (i.e. does not have an aggregator in Price Aggregator)
     */
    error AssetNotSupported();

    /**
     * Empty array
     */
    error EmptyArray();

    /**
     *  Multiple cases...
     */
    error StepNotWhitelisted();

    /**
     *  Input is address(0)
     */
    error ZeroAddress();

    ////////////
    /// Base ///
    ////////////

    /**
     * Msg sender is not hub owner
     */
    error NotHubOwner();

    /**
     * Protocol is paused or frozen
     */
    error ProtocolPausedOrFrozen();

    /**
     * Protocol is frozen
     */
    error ProtocolFrozen();

    //////////////////
    ///  Drem Hub  ///
    //////////////////

    /**
     *  Invalid step parameters passed in
     */
    error InvalidParam();

    /**
     * Passed in Vault Deployer address is not a contract
     */
    error InvalidVaultDeployerAddress();

    /**
     *  'isTradingnAllowed' is set to false
     */
    error TradingDisabled();

    /////////////////
    ///   Vault   ///
    /////////////////

    /**
     * Wind did not create value
     */
    error EndValueLessThanStartValue();

    /**
     * Low level call failed in execute
     */
    error ExecuteCallFailed();

    /**
     * msg.sender is not the Drem Hub
     */
    error MsgSenderIsNotHub();

    /**
     * msg.sender is not a step
     */
    error MsgSenderIsNotStep();

    /**
     * Invalid number of steps
     */
    error InvalidNumberOfSteps();

    /**
     * Step is disabled or not whitelisted
     */
    error InvalidStep();

    /**
     * The initial deposit was too small
     */
    error InsufficcientInitialDeposit();

    /**
     * Steps array and args array is not the same length
     */
    error StepsAndArgsNotSameLength();

    error EmptyFixedArgData();

    error UntrackedStep();
    /**
     * int too big & too small (need room for cumulative mappings)
     */
    error TooManyShares();
    error TooFewShares();

    error ValueTooLarge();

    /**
     * Not the vault admin
     */
    error NotVaultAdmin();

    // Fee Controller

    /**
     * Invalid Fee (more than the decimals)
     */
    error InvalidFee();

    /**
     * Invalid collector (address(0))
     */
    error InvalidCollector();

    /**
     * Fees have already been set (cannot change after setting)
     */
    error FeesAlreadySet();

    ////////////////////////////
    ///   Price Aggregator   ///
    ////////////////////////////

    /**
     * Answer from Chainlink Oracle is <= 0
     */
    error InvalidAggregatorRate();

    /**
     * Total conversion comes out to zero
     */
    error InvalidConversion();

    /**
     *  Asset, aggregator, and rate asset arrays do not match in length
     */
    error InvalidAssetArrays();

    /**
     * Input ammounts and input asset arrays do not match in length
     */
    error InvalidInputArrays();

    /**
     * Output asset is not supported
     */
    error InvalidOutputAsset();

    /**
     * USD rate is stale (updated at more than 30 seconds ago)
     */
    error StaleUSDRate();

    /**
     * ETH rate is stale (updated at more than 24 hours ago)
     */
    error StaleEthRate();

    ////////////////////////////
    ///    Asset Registry    ///
    ////////////////////////////

    /**
     *  Asset passed into addDenominationAssets() is already a denomination asset
     */
    error AssetAlreadyDenominationAsset();

    /**
     *  Asset passed into whitelistAssets() is already a whitelisted asset
     */
    error AssetAlreadyWhitelisted();

    ////////////////////////////////
    ///    Global Step Errors    ///
    ////////////////////////////////

    /**
     * The approval of a token amount failed when calling vault.execute() from a step
     */
    error ApprovalFailed();

    /**
     *  Initialization of step used invalid index for the step's position
     */
    error InvalidStepPosition();

    /**
     *  The vault balance percent, which is used to determine what % of the vault's balance
     *  to use for the step, is invalid (i.e. 0 or > PRECISION_FACTOR)
     */
    error InvalidVaultBalancePercent();

    /**
     * Step is disabled
     */
    error StepDisabled();

    /**
     * Step is deprecated
     */
    error StepDeprecated();

    /**
     * Step is legacied
     */
    error StepLegacied();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "./DataTypes.sol";

library Events {
    /////////////////////////////
    //     Drem Hub Events     //
    /////////////////////////////

    /**
     * @dev Emitted when global trading is set
     * @param setting the new setting
     */
    event GlobalTradingSet(bool setting);

    /**
     * @dev Emitted when protocol state is set
     * @param state the new protocol state
     */
    event ProtocolStateSet(DataTypes.ProtocolState state);

    /**
     * @dev Emitted when a step's state is set
     */
    event StepStateSet(address indexed step, DataTypes.StepState setting);

    /**
     * @dev Emitted when whitelisted step is added
     * @param interactionAddress the contract address associated with the step
     */
    event WhitelistedStepAdded(address interactionAddress);

    /**
     * @dev Emitted when whitelisted step is removed
     * @param interactionAddress the contract address associated with the step
     */
    event WhitelistedStepRemoved(address interactionAddress);

    /////////////////////////////////////
    //     Price Aggregator Events     //
    /////////////////////////////////////
    /**
     * @dev Emitted when the EthToUSDAggregator is reset
     * @param ethToUSDAggregator the newly set aggregator
     */
    event EthToUSDAggregatorSet(AggregatorV3Interface ethToUSDAggregator);

    /**
     *
     */
    event SupportedAssetAdded(address indexed asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);

    /**
     *
     */
    event SupportedAssetRemoved(address indexed asset, AggregatorV3Interface aggregator, DataTypes.RateAsset rateAsset);

    ///////////////////////////////////
    //     Asset Registry Events     //
    ///////////////////////////////////
    event DenominationAssetsAdded(address[] denominationAssets);
    event DenominationAssetsRemoved(address[] denominationAssets);
    event WhitelistedAssetsAdded(address[] whitelistedAssets);
    event WhitelistedAssetsRemoved(address[] whitelistedAssets);

    ///////////////////////////////////
    //     Fee Controller Events     //
    ///////////////////////////////////
    /**
     * @dev Emitted when the Drem fees are collected from the fee collector
     * @param asset the asset the fees were collected in
     * @param amount the amount of fees collected
     */
    event DremFeesCollected(address indexed asset, uint256 amount);

    /**
     * @dev Emitted when the Drem fees are set
     * @param stepLen the corresponding step length for the drem fees
     * @param dremEntranceFee the new drem entrance fee
     * @param dremExitFee the new drem exit fee
     * @param dremPerformanceFee the new drem performance fee
     * @param dremManagementFee the new drem management fee
     */
    event DremFeesSet(
        uint256 indexed stepLen,
        uint24 dremEntranceFee,
        uint24 dremExitFee,
        uint24 dremPerformanceFee,
        uint24 dremManagementFee
    );

    /**
     * @dev Emitted when the max vault fees are set
     * @param maxEntranceFee the new max entrance fee
     * @param maxExitFee the new max exit fee
     * @param maxPerformanceFee the new max performance fee
     * @param maxManagementFee the new max management fee
     */
    event MaxVaultFeesSet(uint24 maxEntranceFee, uint24 maxExitFee, uint24 maxPerformanceFee, uint24 maxManagementFee);

    /**
     * @dev Emitted when the vault fees are set during initialization
     * @param vault the vault the fees are being set for
     * @param entranceFee the entrance fee
     * @param exitFee the exit fee
     * @param performanceFee the performance fee
     * @param managementFee the management fee
     */
    event VaultFeesSet(
        address indexed vault, uint24 entranceFee, uint24 exitFee, uint24 performanceFee, uint24 managementFee
    );

    /**
     * @dev Emitted when the vault collector is set after initialization
     * @param vault the vault the collector is being set for
     * @param collector the new collector
     */
    event VaultCollectorSet(address vault, address collector);

    ///////////////////////////////////
    //     Vault Deployer Events     //
    ///////////////////////////////////
    event VaultDeployed(address indexed creator, address vault, string name, string symbol);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../libraries/Errors.sol";
import {HubAware} from "./HubAware.sol";

abstract contract HubOwnable is HubAware {
    constructor(address _dremHub) HubAware(_dremHub) {}

    modifier onlyHubOwner() {
        _validateMsgSenderHubOwner();
        _;
    }

    function _validateMsgSenderHubOwner() internal view {
        if (msg.sender != DREM_HUB.owner()) revert Errors.NotHubOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {DataTypes} from "../libraries/DataTypes.sol";

interface IPriceAggregator {
    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Converts given amounts of input assets into an output asset
     * @param _inputAmounts the amounts of the input assets to convert
     * @param _inputAssets the input assets
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAssets(uint256[] calldata _inputAmounts, address[] calldata _inputAssets, address _outputAsset)
        external
        view
        returns (uint256);

    /**
     * @notice Converts amount of an input asset into an output asset
     * @param _inputAmount the amount of the input asset to convert
     * @param _inputAsset the input asset
     * @param _outputAsset the output asset
     * @return the output amount denominated in the output asset
     */
    function convertAsset(uint256 _inputAmount, address _inputAsset, address _outputAsset)
        external
        view
        returns (uint256);

    /**
     * @notice returns the ETH to USD aggregator
     * @return the ETH to USD aggregator as an AggregatorV3Interface
     */
    function ETH_TO_USD_AGGREGATOR() external view returns (AggregatorV3Interface);

    /**
     * @notice Returns whether or not an asset is supported
     * @return returns true if an asset is supported, false otherwise
     */
    function isAssetSupported(address _asset) external view returns (bool);

    /**
     * @notice Returns the supported asset's aggregator, rate asset, and units
     * @param _asset the asset to get the info for
     * @return the supported asset info
     */
    function getSupportedAssetInfo(address _asset) external view returns (DataTypes.SupportedAssetInfo memory);

    ////////////////////
    ///     Admin    ///
    ////////////////////
    /**
     * @dev Admin function to add supported assets
     * @param _assets the addresses of the supported assets to add
     * @param _aggregators the addresses of the aggregators corresponding to each asset
     * @param _rateAssets the rate assets for the corresponding aggregators
     */
    function addSupportedAssets(
        address[] calldata _assets,
        AggregatorV3Interface[] calldata _aggregators,
        DataTypes.RateAsset[] calldata _rateAssets
    ) external;

    /**
     * @dev Admin function to remove supported assets
     * @param _assets the addresses of the supported assets to remove
     */
    function removeSupportedAssets(address[] calldata _assets) external;
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDremHub} from "../interfaces/IDremHub.sol";
import {DremHub} from "../core/DremHub.sol";
import {Errors} from "../libraries/Errors.sol";

abstract contract HubAware {
    DremHub public immutable DREM_HUB;

    constructor(address _hub) {
        if (_hub == address(0)) revert Errors.ZeroAddress();
        DREM_HUB = DremHub(_hub);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDremHub {
    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Transfer hook used by DremERC20s. Reverts transfers if trading is disabled or the protocol state is frozen
     */
    function dremHubBeforeTransferHook() external view;

    /**
     * @notice Checks if a step is whitelisted
     * @param _step the address of the step
     * @return returns true if the step is whitelisted. False otherwise
     */
    function isStepWhitelisted(address _step) external view returns (bool);

    /**
     * @notice Returns the Drem protocol's state
     * @return the protocol state
     */
    function getProtocolState() external view returns (DataTypes.ProtocolState);

    /**
     * @notice Returns a step's state
     * @param _step the address of the step
     * @return the step state
     */
    function getStepState(address _step) external view returns (DataTypes.StepState);

    // price aggregator
    function priceAggregator() external view returns (address);

    ////////////////////
    ///     Admin    ///
    ////////////////////

    /**
     * @dev Admin function to add a whitelisted step. Sets the step's state to enabled
     * @param _step the address of the step to add
     */
    function addWhitelistedStep(address _step) external;

    /**
     * @dev Admin function to remove a whitelisted step. Set's the step's state to disabled
     * @param _step the address of the step to disable
     */
    function removeWhitelistedStep(address _step) external;

    /**
     * @dev Admin function to enable or disable trading of Vault ERC20s
     * @param _isTradingAllowed the new setting for global trading
     */
    function setGlobalTrading(bool _isTradingAllowed) external;

    /**
     * @dev Admin function to set the protocol's state
     * @param _state the new setting of the protocol's state
     */
    function setProtocolState(DataTypes.ProtocolState _state) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Ownable2StepUpgradeable} from "@openzeppelin-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IDremHub} from "../interfaces/IDremHub.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";

/**
 *  Invariants:
 *  - If an address is not whitelisted, it should have a disabled step state
 *  - Only whitelisted addresses can have a step state that is not disabled
 */

// Initializable is inherited from Ownable2StepUpgradeable
contract DremHub is Ownable2StepUpgradeable, UUPSUpgradeable, IDremHub {
    // just checking if it is a drem-verified step contract
    mapping(address => bool) private whitelistedSteps;
    mapping(address => DataTypes.StepState) private stepToStepState;

    bool private isTradingAllowed;
    address private vaultDeployer;
    DataTypes.ProtocolState private protocolState;

    // keep the price aggregator here, so we don't need to store it in every vault
    address public priceAggregator;
    address public assetRegistry;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;

    constructor() {
        _disableInitializers();
    }

    function init() external initializer {
        __Ownable2Step_init();
        // Technically unnecessary but good practice...
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Admin function to enable or disable trading of Vault ERC20s
     * @param _isTradingAllowed the new setting for global trading
     */
    function setGlobalTrading(bool _isTradingAllowed) external onlyOwner {
        isTradingAllowed = _isTradingAllowed;
        emit Events.GlobalTradingSet(_isTradingAllowed);
    }

    /**
     * @dev Admin function to add a whitelisted step. Sets the step's state to enabled
     * @param _step the address of the step to add
     */
    function addWhitelistedStep(address _step) external onlyOwner {
        _setWhitelistedStep(_step, true);
        _setStepState(_step, DataTypes.StepState.Enabled);
        emit Events.WhitelistedStepAdded(_step);
    }

    /**
     * @dev Admin function to remove a whitelisted step. Set's the step's state to disabled
     * @param _step the address of the step to disable
     */
    function removeWhitelistedStep(address _step) external onlyOwner {
        _setWhitelistedStep(_step, false);
        _setStepState(_step, DataTypes.StepState.Disabled);
        emit Events.WhitelistedStepRemoved(_step);
    }

    /**
     * @dev Admin function to set a step's state
     * @param _step the address of the step
     */
    function setStepState(address _step, DataTypes.StepState _setting) external onlyOwner {
        if (!(_isStepWhitelisted(_step))) revert Errors.StepNotWhitelisted();
        _setStepState(_step, _setting);
    }

    // Unpaused: Anything is possible!
    // Paused: Deposits and withdrawls enabled. No new trades can be opened
    // Frozen: New trades and deposits are disabled.  Withdraws enabled

    /**
     * @dev Admin function to set the protocol's state
     * @param _state the new setting of the protocol's state
     */
    function setProtocolState(DataTypes.ProtocolState _state) external onlyOwner {
        protocolState = _state;
        emit Events.ProtocolStateSet(_state);
    }

    ////////////////////////////////
    ///     Internal Function    ///
    ////////////////////////////////
    function _isStepWhitelisted(address _step) internal view returns (bool) {
        return whitelistedSteps[_step];
    }

    function _setStepState(address _step, DataTypes.StepState _setting) internal {
        stepToStepState[_step] = _setting;
        emit Events.StepStateSet(_step, _setting);
    }

    function _setWhitelistedStep(address _step, bool _setting) internal {
        whitelistedSteps[_step] = _setting;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /////////////////////////////
    ///     View Functions    ///
    /////////////////////////////

    /**
     * @notice Transfer hook used by DremERC20s. Reverts transfers if trading is disabled or the protocol state is frozen
     */
    function dremHubBeforeTransferHook() external view {
        if ((!(isTradingAllowed)) || protocolState == DataTypes.ProtocolState.Frozen) revert Errors.TradingDisabled();
    }

    /**
     * @notice Checks if a step is valid
     * @param _step the address of the step
     * @return returns true if the step is whitelisted and the step's state is not disabled. False otherwise
     */
    function isValidStep(address _step) external view returns (bool) {
        return _isStepWhitelisted(_step) && (stepToStepState[_step] != DataTypes.StepState.Disabled);
    }

    /**
     * @notice Checks if a step is whitelisted
     * @param _step the address of the step
     * @return returns true if the step is whitelisted. False otherwise
     */
    function isStepWhitelisted(address _step) external view returns (bool) {
        return _isStepWhitelisted(_step);
    }

    /**
     * @notice Returns the Drem protocol's state
     * @return the protocol state
     */
    function getProtocolState() external view returns (DataTypes.ProtocolState) {
        return protocolState;
    }

    /**
     * @notice Returns a step's state
     * @param _step the address of the step
     * @return the step state
     */
    function getStepState(address _step) external view returns (DataTypes.StepState) {
        return stepToStepState[_step];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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