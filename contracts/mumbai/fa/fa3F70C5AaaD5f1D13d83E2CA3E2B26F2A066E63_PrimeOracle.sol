//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../oracle/interfaces/IPrimeOracle.sol";
import "../oracle/interfaces/IPrimeOracleGetter.sol";
import "../oracle/interfaces/IPTokenOracle.sol";
import "../../satellite/pToken/interfaces/IPToken.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";

contract PrimeOracle is IPrimeOracle, IPTokenOracle {

    // Map of asset price feeds (asset => priceSource)
    mapping(IERC20 => IPrimeOracleGetter) private primaryFeeds;
    mapping(IERC20 => IPrimeOracleGetter) private secondaryFeeds;

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
    /// @param assets list of addresses of the assets
    /// @param _primaryFeeds The address of the priamry feed of each asset
    /// @param _secondaryFeeds The Address of the secondary feed of each asset
    constructor(
        IERC20[] memory assets,
        IPrimeOracleGetter[] memory _primaryFeeds,
        IPrimeOracleGetter[] memory _secondaryFeeds,
        IERC20 _pusdAddress,
        IERC20 _usdcAddress,
        address _denomCurrency,
        uint256 _denomCurrencyUnit
    ) {
        admin = msg.sender;
        pusdAddress = _pusdAddress;
        usdcAddress = _usdcAddress;
        denomCurrency = _denomCurrency;
        denomCurrencyUnit = _denomCurrencyUnit;
        _setPrimaryFeeds(assets, _primaryFeeds);
        _setSecondaryFeeds(assets, _secondaryFeeds);
    }

    function _getAssetPrices(IERC20[] memory assets)
        internal
        view
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            prices[i] = primaryFeeds[assets[i]].getAssetPrice(assets[i],usdcAddress);
            if (prices[i] == 0){
                prices[i] = secondaryFeeds[assets[i]].getAssetPrice(assets[i],usdcAddress);
            }
        }
        return prices;
    }

    /// @inheritdoc IPrimeOracle
    function getAssetPrices(IERC20[] calldata assets)
        external
        view
        override
        returns (uint256[] memory)
    {
       return _getAssetPrices(assets);
    }

    /// @inheritdoc IPrimeOracle
    function getPrimaryFeedOfAsset(IERC20 asset) external view override returns (address) {
        return address(primaryFeeds[asset]);
    }

    /// @inheritdoc IPrimeOracle
    function getSecondaryFeedOfAsset(IERC20 asset) external view override returns (address) {
        return address(secondaryFeeds[asset]);
    }

    function getPusdAddress() external view returns(address) {
        return address(pusdAddress);
    }

    function getPusdPrice() external view returns (uint256) {
        IERC20[] memory assets = new IERC20[](1);
        assets[0] = pusdAddress;
        return _getAssetPrices(assets)[0];
    }

    /// @inheritdoc IPrimeOracle
    function setPrimaryFeeds(IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin
    {
        _setPrimaryFeeds(assets, feeds);
    }

    /// @inheritdoc IPrimeOracle
    function setSecondaryFeeds(IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds)
        external
        override
        onlyAdmin
    {
        _setSecondaryFeeds(assets, feeds);
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
    function _setPrimaryFeeds(IERC20[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        for (uint256 i; i < assets.length; i++) {
            primaryFeeds[assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit PrimaryFeedUpdated(assets[i], address(primaryFeeds[assets[i]]));
        }
    }

    /**
    * @notice Internal function to set the feeds for each asset
    * @param assets The addresses of the assets
    * @param feeds The address of the feed of each asset
    */
    function _setSecondaryFeeds(IERC20[] memory assets, IPrimeOracleGetter[] memory feeds) internal {
        require(assets.length == feeds.length, "ERROR: Length mismatch between 'assets' and 'feeds'");
        for (uint256 i; i < assets.length; i++) {
            secondaryFeeds[assets[i]] = IPrimeOracleGetter(feeds[i]);
            emit SecondaryFeedUpdated(assets[i], address(secondaryFeeds[assets[i]]));
        }
    }

    function getUnderlyingPrice(IERC20 pToken) external view override returns (uint256) {
        IERC20[] memory assets = new IERC20[](1);
        assets[0] = IERC20(pToken);
        return _getAssetPrices(assets)[0];
    }

    function getUnderlyingPriceBorrow(ILoanAgent loanAgent) external view override returns (uint256) {
        return 1e8;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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
   * @param feed The price feed of the asset
   */
  event PrimaryFeedUpdated(IERC20 indexed asset, address indexed feed);

    /**
   * @dev Emitted after the price data feed of an asset is updated
   * @param asset The address of the asset
   * @param feed The price feed of the asset
   */
  event SecondaryFeedUpdated(IERC20 indexed asset, address indexed feed);

  /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setPrimaryFeeds(IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

    /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setSecondaryFeeds(IERC20[] calldata assets, IPrimeOracleGetter[] calldata feeds) external;

  /**
   * @notice Returns a list of prices from a list of assets addresses
   * @param assets The list of assets addresses
   * @return The prices of the given assets
   */
  function getAssetPrices(IERC20[] calldata assets) external view returns (uint256[] memory);

  /**
   * @notice Returns the address of the primary price feed for an asset address
   * @param asset The address of the asset
   * @return The address of the price feed
   */
  function getPrimaryFeedOfAsset(IERC20 asset) external view returns (address);

  /**
   * @notice Returns the address of the secondary price feed for an asset address
   * @param asset The address of the asset
   * @return The address of the price feed
   */
  function getSecondaryFeedOfAsset(IERC20 asset) external view returns (address);

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
pragma solidity ^0.8.13;

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
  event AssetFeedUpdated(IERC20 indexed asset, address indexed feed);

  /**
   * @notice Gets the price feed of an asset
   * @param asset The addresses of the asset
   * @return address of asset feed
  */
  function getAssetFeed(IERC20 asset) external view returns (address);

    /**
   * @notice Sets or replaces price feeds of assets
   * @param assets The addresses of the assets
   * @param feeds The addresses of the price feeds
   */
  function setAssetFeeds(IERC20[] calldata assets, address[] calldata feeds) external;

  /**
   * @notice Returns the price data in the denom currency
   * @param quoteToken A token to return price data for
   * @param denomToken A token to price quoteToken against
   * @return return price of the asset from the oracle
   **/
  function getAssetPrice(IERC20 quoteToken, IERC20 denomToken) external view returns (uint256);

  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../../satellite/pToken/interfaces/IPToken.sol";
import "../../../satellite/loanAgent/interfaces/ILoanAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IPTokenOracle {
    /**
     * @notice Get the underlying price of a cToken asset
     * @param pToken The pToken to get the underlying price of
     * @return The underlying asset price.
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPrice(IERC20 pToken) external view returns (uint256);

    /**
     * @notice Get the underlying borrow price of a pToken asset
     * @param loanAgent The loanAgent associated with the pToken
     * @return The underlying borrow price
     *  Zero means the price is unavailable.
     */
    function getUnderlyingPriceBorrow(ILoanAgent loanAgent) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

abstract contract IPToken {

    function mint(uint256 amount) external virtual payable;

    function redeemUnderlying(uint256 redeemAmount) external virtual payable;


    function setMidLayer(address _middleLayer) external virtual;

    function setMasterCID(uint256 _cid) external virtual;

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
pragma solidity ^0.8.13;

import "../LoanAgentStorage.sol";
import "../../../interfaces/IHelper.sol";

abstract contract ILoanAgent is LoanAgentStorage {
    function initialize(address _ecc) external virtual;

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

    function setMidLayer(address _middleLayer) external virtual;

    function setMasterCID(uint256 _cid) external virtual;
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
pragma solidity ^0.8.13;

import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../ecc/interfaces/IECC.sol";

abstract contract LoanAgentStorage {
    /**
    * @notice Administrator for this contract
    */
    address payable public admin;

    address internal PUSD;

    IMiddleLayer internal middleLayer;

    IECC internal ecc;

    uint256 internal masterCID;

    uint256 public borrowIndex;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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
        address _route
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory payload
    ) external virtual;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

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