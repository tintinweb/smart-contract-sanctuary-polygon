//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../oracle/interfaces/IPrimeOracle.sol";
import "../oracle/interfaces/IPrimeOracleGetter.sol";
import "../oracle/interfaces/IPTokenOracle.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract PrimeOracle is IPrimeOracle, IPTokenOracle {

    // Map of asset price feeds (chainasset => priceSource)
    mapping(uint256 => mapping(IERC20 => IPrimeOracleGetter)) private primaryFeeds;
    mapping(uint256 => mapping(IERC20 => IPrimeOracleGetter)) private secondaryFeeds;

    address public immutable denomCurrency;
    uint256 public immutable denomCurrencyUnit;

    IERC20 public immutable pusdAddress;
    IERC20 public immutable usdcAddress;

    //TODO: allow transfer of ownership
    address public admin;

    /**
    * @dev Only the admin can call functions marked by this modifier.
    **/
    modifier onlyAdmin {
        require(msg.sender == admin, "Unauthorized use of function");
        _;
    }

    /// @notice constructor
    /// @param chainIdsParam list of chainIds to match assets
    /// @param assetsParam list of addresses of the assets
    /// @param primaryFeedsParam The address of the priamry feed of each asset
    /// @param secondaryFeedsParam The Address of the secondary feed of each asset
    constructor(
        uint256[] memory chainIdsParam,
        IERC20[] memory assetsParam,
        IPrimeOracleGetter[] memory primaryFeedsParam,
        IPrimeOracleGetter[] memory secondaryFeedsParam,
        IERC20 pusdAddressParam,
        IERC20 usdcAddressParam,
        address denomCurrencyParam,
        uint256 denomCurrencyUnitParam
    ) {
        require(address(pusdAddressParam) != address(0), "NON_ZEROADDRESS");
        require(address(usdcAddressParam) != address(0), "NON_ZEROADDRESS");
        require(denomCurrencyParam != address(0), "NON_ZEROADDRESS");
        admin = msg.sender;
        pusdAddress = pusdAddressParam;
        usdcAddress = usdcAddressParam;
        denomCurrency = denomCurrencyParam;
        denomCurrencyUnit = denomCurrencyUnitParam;
        _setPrimaryFeeds(chainIdsParam, assetsParam, primaryFeedsParam);
        _setSecondaryFeeds(chainIdsParam, assetsParam, secondaryFeedsParam);
    }

    function _getAssetPrices(uint256[] memory chainIds, IERC20[] memory assets)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            IPrimeOracleGetter primaryFeed =  primaryFeeds[chainIds[i]][assets[i]];
            require(address(primaryFeed) != address(0), "FATAL: missing primary feed for asset on chainId");
            prices[i] = primaryFeed.getAssetPrice(chainIds[i], assets[i],usdcAddress);
            if (prices[i] == 0){
                prices[i] = secondaryFeeds[chainIds[i]][assets[i]].getAssetPrice(chainIds[i], assets[i],usdcAddress);
            }
        }
        return prices;
    }

    /// @inheritdoc IPrimeOracle
    function getAssetPrices(uint256[] calldata chainIds, IERC20[] calldata assets)
        external
        view
        override
        returns (uint256[] memory)
    {
       return _getAssetPrices(chainIds, assets);
    }

    /// @inheritdoc IPrimeOracle
    function getPrimaryFeedOfAsset(uint256 chainId, IERC20 asset) external view override returns (address) {
        return address(primaryFeeds[chainId][asset]);
    }

    /// @inheritdoc IPrimeOracle
    function getSecondaryFeedOfAsset(uint256 chainId, IERC20 asset) external view override returns (address) {
        return address(secondaryFeeds[chainId][asset]);
    }

    function getPusdAddress() external view returns(address) {
        return address(pusdAddress);
    }

    function getPusdPrice() external view returns (uint256) {
        IERC20[] memory assets = new IERC20[](1);
        assets[0] = pusdAddress;
        uint256[] memory chainIds = new uint256[](1);
        chainIds[0] = block.chainid;
        return _getAssetPrices(chainIds, assets)[0];
    }

    /// @inheritdoc IPrimeOracle
    function setPrimaryFeeds(uint256[] calldata chainIds, IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin
    {
        _setPrimaryFeeds(chainIds, assets, feeds);
    }

    /// @inheritdoc IPrimeOracle
    function setSecondaryFeeds(uint256[] calldata chainIds, IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin
    {
        _setSecondaryFeeds(chainIds, assets, feeds);
    }

    function getDenomCurrency() external view override returns (address) {
        return denomCurrency;
    }

    function getDenomCurrencyUnit() external view override returns (uint256) {
        return denomCurrencyUnit;
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setPrimaryFeeds(uint256[] memory chainIds, IERC20[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            primaryFeeds[chainIds[i]][assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit PrimaryFeedUpdated(chainIds[i], assets[i], address(primaryFeeds[chainIds[i]][assets[i]]));
        }
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setSecondaryFeeds(uint256[] memory chainIds, IERC20[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(chainIds.length == assets.length && assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        // slither-disable-next-line uninitialized-local
        for (uint256 i; i < assets.length; i++) {
            secondaryFeeds[chainIds[i]][assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit SecondaryFeedUpdated(chainIds[i], assets[i], address(secondaryFeeds[chainIds[i]][assets[i]]));
        }
    }

    function getUnderlyingPrice(uint256 chainId, address asset) external view override returns (uint256) {
        IERC20[] memory assets = new IERC20[](1);
        uint256[] memory chainIds = new uint256[](1);
        assets[0] = IERC20(asset);
        chainIds[0] = chainId;
        return _getAssetPrices(chainIds, assets)[0];
    }

    function getUnderlyingPriceBorrow() external pure override returns (uint256) {
        //TODO: get PUSD decimals
        return 1e8;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IPrimeOracleGetter.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IPrimeOracle
 * @author Prime
 * @notice The core interface for the Prime Oracle
 */
interface IPrimeOracle {

  /**
   * @dev Emitted after the price data feed of an asset is updated
   * @param asset The address of the asset
   * @param chainId The chainId of the asset
   * @param feed The price feed of the asset
   */
  event PrimaryFeedUpdated(uint256 chainId, IERC20 indexed asset, address indexed feed);

    /**
   * @dev Emitted after the price data feed of an asset is updated
   * @param asset The address of the asset
   * @param feed The price feed of the asset
   */
  event SecondaryFeedUpdated(uint256 chainId, IERC20 indexed asset, address indexed feed);

  /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setPrimaryFeeds(uint256[] calldata chainIds, IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

    /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setSecondaryFeeds(uint256[] calldata chainIds, IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetPrices(uint256[] calldata chainIds, IERC20[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the primary price feed for an asset address
   * @param asset The address of the asset
   * @return The address of the price feed
   */
  function getPrimaryFeedOfAsset(uint256 chainId, IERC20 asset) external view returns (address);

  /**
   * @notice Returns the address of the secondary price feed for an asset address
   * @param asset The address of the asset
   * @return The address of the price feed
   */
  function getSecondaryFeedOfAsset(uint256 chainId, IERC20 asset) external view returns (address);

    /**
   * @notice Returns the address for the denomination currency
   * @dev For USD, the address should be set to 0x0.
   * @return Returns the denomination currency address.
   **/
  function getDenomCurrency() external view returns (address);

  /**
   * @notice Returns the denom currency unit
   * @dev 1e8 for USD, 1 ether for ETH.
   * @return Returns the denom currency unit.
   **/
  function getDenomCurrencyUnit() external view returns (uint256);

  /**
   * @return Returns the price of PUSD
   **/
  function getPusdPrice() external view returns (uint256);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IPrimeOracleGetter
 * @author Prime
 * @notice Interface for the Prime price oracle.
 **/
interface IPrimeOracleGetter {

  /**
    * @dev Emitted after the denom currency is set
    * @param denomCurrency The denom currency used for price quotes
    * @param denomCurrencyUnit The unit of the denom currency (1e8 for USD)
  */
  event DenomCurrencySet(address indexed denomCurrency, uint256 denomCurrencyUnit);

  /**
    * @dev Emitted after the price data feed of an asset is updated
    * @param asset The address of the asset
    * @param feed The price feed of the asset
  */
  event AssetFeedUpdated(uint256 chainId, IERC20 indexed asset, address indexed feed);

  /**
   * @notice Gets the price feed of an asset
   * @param asset The addresses of the asset
   * @return address of asset feed
  */
  function getAssetFeed(uint256 chainId, IERC20 asset) external view returns (address);

    /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setAssetFeeds(uint256[] calldata chainIds, IERC20[] calldata assets, address[] calldata feeds) external;

  /**
   * @notice Returns the price data in the denom currency
   * @param quoteToken A token to return price data for
   * @param denomToken A token to price quoteToken against
   * @return return price of the asset from the oracle
   **/
  function getAssetPrice(uint256 chainId, IERC20 quoteToken, IERC20 denomToken) external view returns (uint256);


}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "../../../satellite/pToken/interfaces/IPToken.sol";
import "../../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../../satellite/pToken/interfaces/IPToken.sol";

interface IPTokenOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param asset The PToken collateral to get the sasset price of
     * @param chainId the chainId to get an asset price for
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(uint256 chainId, address asset) external view returns (uint256);

    /**
     * @notice Get the underlying borrow price of a pToken asset
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow() external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../PTokenStorage.sol";

abstract contract IPToken is PTokenStorage {

    function mint(uint256 amount) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount) external virtual payable;


    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;

    function changeOwner(address payable _newOwner) external virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function initialize(address eccAddress) external virtual;

    function borrow(uint256 borrowAmount) external payable virtual;

    // function completeBorrow(
    //     address borrower,
    //     uint borrowAmount
    // ) external virtual;

    function repayBorrow(uint256 repayAmount) external payable virtual returns (bool);

    function repayBorrowBehalf(
        address borrower,
        uint256 repayAmount
    ) external payable virtual returns (bool);

    function borrowApproved(
        IHelper.FBBorrow memory params,
        bytes32 metadata
    ) external payable virtual;

    function setPUSD(address newPUSD) external virtual;

    function setMidLayer(address newMiddleLayer) external virtual;

    function setMasterCID(uint256 newChainId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";
import "../../master/irm/interfaces/IIRM.sol";
import "../../master/crm/interfaces/ICRM.sol";

abstract contract PTokenStorage {
    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    /**
    * @notice EIP-20 token for this PToken
    */
    address public underlying;

    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    /**
    * @notice Pending administrator for this contract
    */
    // Currently not in use, may add in future
    // address payable public pendingAdmin;

    /**
    * @notice Model which tells what the current interest rate should be
    */
    IIRM public interestRateModel;

    /**
    * @notice Model which tells whether a user may withdraw collateral or take on additional debt
    */
    ICRM public initialCollateralRatioModel;

    /**
    * @notice EIP-20 token decimals for this token
    */
    uint8 public decimals;

    /**
    * @notice Official record of token balances for each account
    */
    // slither-disable-next-line unused-state
    mapping(address => uint256) internal accountTokens;

    /**
    * @notice Approved token transfer amounts on behalf of others
    */
    // slither-disable-next-line unused-state
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    // slither-disable-next-line unused-state
    uint256 internal _totalSupply;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the lz 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory params,
        address payable _refundAddress,
        address fallbackAddress
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IECC {
    struct Metadata {
        bytes5 soph; // start of payload hash
        uint40 creation;
        uint16 nonce; // in case the same exact message is sent multiple times the same block, we increase the nonce in metadata
        address sender;
    }

    function preRegMsg(
        bytes memory payload,
        address instigator
    ) external returns (bytes32 metadata);

    function preProcessingValidation(
        bytes memory payload,
        bytes32 metadata
    ) external view returns (bool allowed);

    function flagMsgValidated(
        bytes memory payload,
        bytes32 metadata
    ) external returns (bool);

    // function rsm(uint256 messagePtr) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IIRM {

    function getBasisPointsTickSize() external returns (uint256 tickSize);
    function getBasisPointsUpperTick() external returns (uint256 tick);
    function getBasisPointsLowerTick() external returns (uint256 tick);
    function setBasisPointsTickSize(uint256 price) external returns (uint256 tickSize);
    function setBasisPointsUpperTick(uint256 upperTick) external returns (uint256 tick);
    function setBasisPointsLowerTick(uint256 lowerTick) external returns (uint256 tick);
    function setPusdLowerTargetPrice(uint256 lowerPrice) external returns (uint256 price);
    function setPusdUpperTargetPrice(uint256 upperPrice) external returns (uint256 price);
    function getBorrowRate() external returns (uint256 rate);
    function setBorrowRate() external returns (uint256 rate);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ICRM {

    event CollateralRatioModelUpdated(address asset, address collateralRatioModel);
    event AssetLtvRatioUpdated(address asset, uint256 ltvRatio);

    function getCollateralRatioModel(address asset) external returns (address model);
    function getCurrentMaxLtvRatios(address[] calldata assets) external returns (uint256[] memory ratios);
    function getCurrentMaxLtvRatio(address asset) external returns (uint256 ratio);
    function setPusdPriceCeiling(uint256 price) external returns (uint256 ceiling);
    function setPusdPriceFloor(uint256 price) external returns (uint256 floor);
    function setAbsMaxLtvRatios(address[] memory assets, uint256[] memory maxLtvRatios) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    // slither-disable-next-line unused-state
    address internal PUSD;

    // slither-disable-next-line unused-state
    IMiddleLayer internal middleLayer;

    // slither-disable-next-line unused-state
    IECC internal ecc;

    // slither-disable-next-line unused-state
    uint256 internal masterCID;

    uint256 public borrowIndex;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_REDEEM_ALLOWED,
        FB_REDEEM,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        MASTER_TRANSFER_ALLOWED,
        FB_COMPLETE_TRANSFER,
        PUSD_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 previousAmount;
        uint256 amountIncreased;
    }

    struct MRedeemAllowed {
        Selector selector; // = Selector.MASTER_REDEEM_ALLOWED
        address pToken;
        address user;
        uint256 amount;
    }

    struct FBRedeem {
        Selector selector; // = Selector.FB_REDEEM
        address pToken;
        address user;
        uint256 redeemAmount;
    }

    struct MRepay {
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
    }

    struct MBorrowAllowed {
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
    }

    struct FBBorrow {
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
    }

    struct SLiquidateBorrow {
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pTokenCollateral;
    }

    struct MTransferAllowed {
        uint8 selector; // = Selector.MASTER_TRANSFER_ALLOWED
        address pToken;
        address spender;
        address user;
        address dst;
        uint256 amount;
    }

    struct FBCompleteTransfer {
        uint8 selector; // = Selector.FB_COMPLETE_TRANSFER
        address pToken;
        address spender;
        address src;
        address dst;
        uint256 tokens;
    }

    struct PUSDBridge {
        uint8 selector; // = Selector.PUSD_BRIDGE
        address minter;
        uint256 amount;
    }
}