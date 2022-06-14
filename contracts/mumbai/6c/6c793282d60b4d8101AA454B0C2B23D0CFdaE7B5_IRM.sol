//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "../irm/interfaces/IIRM.sol";
import "../irm/IRMStorage.sol";
import "../oracle/interfaces/IPrimeOracle.sol";

contract IRM is IIRM, IRMStorage {

    modifier onlyAdmin() {
        require(msg.sender == admin, "Unauthorized user");
        _;
    }

    function initialize(
        uint256 _borrowInterestRatePerYear,
        uint256 _basisPointsTickSizePerYear,
        uint256 _basisPointsUpperTickPerYear,
        uint256 _pusdLowerTargetPrice,
        uint256 _pusdUpperTargetPrice,
        uint256 _blocksPerYear,
        address _primeOracle
    ) public onlyAdmin() {
        primeOracle = IPrimeOracle(_primeOracle);

        blocksPerYear = _blocksPerYear;
        borrowInterestRatePerBlock = _borrowInterestRatePerYear / blocksPerYear;

        uint256 basisPointsTickSizePerYear = _basisPointsTickSizePerYear;
        basisPointsTickSize = basisPointsTickSizePerYear / blocksPerYear;
        basisPointsUpperTick = _basisPointsUpperTickPerYear / blocksPerYear;
        basisPointsLowerTick = 0;
        pusdLowerTargetPrice = _pusdLowerTargetPrice;
        pusdUpperTargetPrice = _pusdUpperTargetPrice;
        observationPeriod = 0;
    }

    /**
    * @notice Calculates the current borrow interest rate per block
    * @return The borrow rate per block (as a percentage, and scaled by 1e18)
    */
    function getBorrowRate() external view returns (uint256) {
        return borrowInterestRatePerBlock;
    }

    function setBorrowRate() external returns (uint256) {
        uint256 elapsedTime = block.timestamp - lastObservationTimestamp;

        if (elapsedTime <= observationPeriod) {
            return borrowInterestRatePerBlock;
        }

        uint256 priorBorrowInterestRatePerBlock = borrowInterestRatePerBlock;
        uint256 pusdPrice = primeOracle.getPusdPrice();
        //999e4 and 1001e3 based on feedback
        if (pusdPrice > pusdUpperTargetPrice) {
            if (borrowInterestRatePerBlock < basisPointsUpperTick) {
                borrowInterestRatePerBlock -= basisPointsTickSize;
            }
        } 
        else if (pusdPrice < pusdLowerTargetPrice) {
            if (borrowInterestRatePerBlock * blocksPerYear >= basisPointsTickSize) {
                borrowInterestRatePerBlock += basisPointsTickSize;
            }
        }

        lastObservationTimestamp = block.timestamp;

        return priorBorrowInterestRatePerBlock;
    }

    function getBasisPointsTickSize() external view returns (uint256) {
        return basisPointsTickSize;
    }

    function getBasisPointsUpperTick() external view returns (uint256) {
        return basisPointsUpperTick;
    }

    function getBasisPointsLowerTick() external view returns (uint256) {
        return basisPointsLowerTick;
    }

    function getPusdLowerTargetPrice() external view returns (uint256) {
        return pusdLowerTargetPrice;
    }

    function getPusdUpperTargetPrice() external view returns (uint256) {
        return pusdUpperTargetPrice;
    }

    function setBasisPointsTickSize(
        uint256 _basisPointsTickSize
    ) external onlyAdmin returns (uint256) {
        basisPointsTickSize = _basisPointsTickSize;
        return basisPointsTickSize;
    }

    function setBasisPointsUpperTick(
        uint256 _basisPointsUpperTick
    ) external onlyAdmin returns (uint256) {
        basisPointsUpperTick = _basisPointsUpperTick;
        return basisPointsUpperTick;
    }

    function setBasisPointsLowerTick(
      uint256 _basisPointsLowerTick
    ) external onlyAdmin returns (uint256) {
        basisPointsLowerTick = _basisPointsLowerTick;
        return basisPointsLowerTick;
    }

    function setPusdLowerTargetPrice(
        uint256 _pusdLowerTargetPrice
    ) external onlyAdmin returns (uint256) {
        pusdLowerTargetPrice = _pusdLowerTargetPrice;
        return pusdLowerTargetPrice;
    }

    function setPusdUpperTargetPrice(
        uint256 _pusdUpperTargetPrice
    ) external onlyAdmin returns (uint256) {
        pusdUpperTargetPrice = _pusdUpperTargetPrice;
        return pusdUpperTargetPrice;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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
pragma solidity ^0.8.13;

import "../oracle/interfaces/IPrimeOracle.sol";

abstract contract IRMStorage {
    bool public constant IS_IRM = true;

    address public admin;

    IPrimeOracle public primeOracle;

    uint256 public borrowInterestRatePerBlock;
    uint256 public basisPointsTickSize;
    uint256 public basisPointsUpperTick;
    uint256 public basisPointsLowerTick;
    uint256 public pusdLowerTargetPrice;
    uint256 public pusdUpperTargetPrice;
    uint256 public lastObservationTimestamp;
    uint256 public observationPeriod;
    uint256 public blocksPerYear;
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