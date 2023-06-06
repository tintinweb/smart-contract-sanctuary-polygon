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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./IDafNFT.sol";


// struct Sales Information
struct SalesInformation {
    uint256 initialAmount;
    uint256 sold;
    uint256 priceUSD;
    bool active;
}


// struct for purchase history
struct History {
    uint256 timestamp;
    uint256 amount;
    uint256 payedAmount;
    Coin coin;
    uint256 tokenId;
}

// enum for pay type
enum Coin { USDC, ETH, WBTC }

contract DafSales is Ownable {

    // max possible supply
    uint256 public constant maxSupply = 200_000_000 * 10**18;

    // hedge start in days
    uint256 public constant hedgeStart = 5 minutes;

    // hedge claim duration
    uint256 public constant hedgeClaimDuration = 20 minutes;

    // price decimals
    uint256 public constant priceDecimals = 8;

    // current coins for Sale
    uint256 public totalSale = 0;

    // added sale batches by owner
    uint256 public batchCount = 0;

    // sales mapping
    mapping(uint256=>SalesInformation) public batches;

    // USDC / USD price contract address
    AggregatorV3Interface public immutable USDCtoUSD;

    // WBTC / USD price contract address
    AggregatorV3Interface public immutable WBTCtoUSD;

    // ETH / USD price contract address
    AggregatorV3Interface public immutable ETHtoUSD;

    // price of hedging for BTC, decimals should be in 1000
    uint256 public BTCHedgingPercent = 100;

    // price of hedging for eth, decimals should be in 1000
    uint256 public ETHHedgingPercent = 100;

    // decimals of percentage
    uint256 public constant percentageDecimals = 3;

    // DafNFT instance
    IDafNFT public immutable dafNft;

    address public immutable USDCAddress;

    address public immutable WBTCAddress;

    address public dafWalletAddress;

    // purchase History
    mapping(address => History[]) public history;

    // ERC20 daf coin instance
    ERC20 public immutable dafCoin;

    /**
      * @dev Constructing the DafCoin contract
    */
    constructor(
        address USDCtoUSD_,
        address BWTCtoUSD_,
        address ETHtoUSD_,
        address USDCAddress_,
        address WBTCAddress_,
        address DAFNFTAddress_,
        address DAFCoinAddress_
    )
    {
        USDCtoUSD = AggregatorV3Interface(USDCtoUSD_);
        WBTCtoUSD = AggregatorV3Interface(BWTCtoUSD_);
        ETHtoUSD = AggregatorV3Interface(ETHtoUSD_);
        USDCAddress = USDCAddress_;
        WBTCAddress = WBTCAddress_;
        dafNft = IDafNFT(DAFNFTAddress_);

        dafCoin = ERC20(DAFCoinAddress_);
    }

    /**
     * @dev adding new sale batch
     * @param _coinCount - coin amount in sale
     * @param _priceUSD - coin price in USD for sale. price decimals is 8, so if user want price 0.01 it would be 0.01 * 10**8
    */

    function addSale(uint256 _coinCount, uint256 _priceUSD)
    external
    onlyOwner
    {
        totalSale += _coinCount;
        require(totalSale <= maxSupply, "Daf: max supply exceed");
        batches[batchCount++] = SalesInformation(_coinCount, 0, _priceUSD, true);
    }

    /**
     * @dev gets the batch information
     * @param _batch - target batch
    */

    function getBatch(uint256 _batch) external view returns (SalesInformation memory) {
        return batches[_batch];
    }

    /**
     * @dev gets the all batches
    */

    function getAllBatches() external view returns (SalesInformation[] memory) {
        SalesInformation[] memory batchesArray = new SalesInformation[](batchCount);

        for (uint256 k = 0; k < batchCount; ++ k) {
            batchesArray[k] = batches[k];
        }

        return batchesArray;
    }

    /**
     * @dev gets the batch information
     * @param _batch - target batch
     * @param active - active boolean of batch sale
    */

    function changeStatus(uint256 _batch, bool active) external onlyOwner {
        require(_batch < batchCount, "Daf: invalid batch number");
        batches[_batch].active = active;
    }

    /**
     * @dev gets the batch information
     * @param _batch - target batch
     * @param priceUSD - price for this batch Decimal in 8
    */

    function changeBatchPrice(uint256 _batch, uint256 priceUSD) external onlyOwner {
        require(_batch < batchCount, "Daf: invalid batch number");
        batches[_batch].priceUSD = priceUSD;
    }

    /**
     * @dev gets the batch information
     * @param _batch - target batch
     * @param _amount - batch coin amount
    */

    function changeBatchAmount(uint256 _batch, uint256 _amount) external onlyOwner {
        require(_batch < batchCount, "Daf: invalid batch number");
        require(_amount >= batches[_batch].sold, "Daf: amount should not be less than sold tokens");

        totalSale = totalSale + _amount - batches[_batch].initialAmount;
        require(totalSale <= maxSupply, "Daf: max supply exceed");

        batches[_batch].initialAmount = _amount;
    }

    /// @dev view function to get latest price for ETH to USD
    function getLatestETHPrice() public view returns (uint256) {
        (,int price,,,) = ETHtoUSD.latestRoundData();
        return uint256(price);
    }

    /// @dev view function to get latest price for WBTC to USD
    function getLatestWBTCPrice() public view returns (uint256) {
        (,int price,,,) = WBTCtoUSD.latestRoundData();
        return uint256(price);
    }

    /// @dev view function to get latest price for USDC to USD
    function getLatestUSDCPrice() public view returns (uint256) {
        (,int price,,,) = USDCtoUSD.latestRoundData();
        return uint256(price);
    }

    /// @dev view function to get buy history
    function getHistory(address account) public view returns (History[] memory) {
        return history[account];
    }

    /**
     * @dev buys from batch
     * @param _batcheIds - target sale batches
     * @param _amount - coin amount
     * @param _maxPayTokenAmount - max tokens which should be used
     * @param coinType - payed token type
    */

    function buy(uint256[] memory _batcheIds, uint256 _amount, uint256 _maxPayTokenAmount, Coin coinType) external payable {
        require(dafWalletAddress != address(0), "Daf: daf wallet address should not be zero address");
         uint256 amount;
        if (coinType == Coin.ETH) {
            amount = spendAllUSD(_batcheIds, _maxPayTokenAmount * getLatestETHPrice());
            require(msg.value >= _maxPayTokenAmount, "Daf: insufficient balance of ethereum");
            require(amount >= _amount, "Daf: can't buy minimum amount");
            payable(dafWalletAddress).transfer(msg.value);
        }
        else if (coinType == Coin.WBTC) {
            uint256 USDAmount = _maxPayTokenAmount * getLatestWBTCPrice() * 10 ** dafCoin.decimals()
                        / 10 ** ERC20(WBTCAddress).decimals();
            amount = spendAllUSD(_batcheIds, USDAmount);
            require(amount >= _amount, "Daf: can't buy minimum amount");
            ERC20(WBTCAddress).transferFrom(msg.sender, dafWalletAddress, _maxPayTokenAmount);
        }
        else if (coinType == Coin.USDC) {
            uint256 USDAmount = _maxPayTokenAmount * getLatestUSDCPrice() * 10 ** dafCoin.decimals()
            / 10 ** ERC20(USDCAddress).decimals();
            amount = spendAllUSD(_batcheIds, USDAmount);
            require(amount >= _amount, "Daf: can't buy minimum amount");
            ERC20(USDCAddress).transferFrom(msg.sender, dafWalletAddress, _maxPayTokenAmount);
        }

        dafCoin.transfer(msg.sender, amount);
        history[msg.sender].push(
            History(
                block.timestamp,
                amount,
                _maxPayTokenAmount,
                coinType,
                0
            )
        );
        return;
    }

    /**
     * @dev buys from batch
     * @param _batcheIds - target sale batches
     * @param _amount - coin amount
     * @param _maxPayTokenAmount - max tokens which should be used
     * @param coinType - payed token type
    */

    function hedge(uint256[] memory _batcheIds, uint256 _amount, uint256 _maxPayTokenAmount, HedgeCoin coinType) external payable {
        require(dafWalletAddress != address(0), "Daf: daf wallet address should not be zero address");

        uint256 payedAmount = 0;
        uint256 value = 0;
        uint256 amount = 0;
        uint256 hedgingFee = 0;

        Coin historyCoin;
        if (coinType == HedgeCoin.WBTC) {
            payedAmount = 10 ** percentageDecimals * _maxPayTokenAmount / (BTCHedgingPercent + 10 ** percentageDecimals);
            hedgingFee = _maxPayTokenAmount - payedAmount;
            uint256 USDAmount = payedAmount * getLatestWBTCPrice() * 10 ** dafCoin.decimals()
                    / 10 ** ERC20(WBTCAddress).decimals();
            amount = spendAllUSD(_batcheIds, USDAmount);
            historyCoin = Coin.WBTC;

            // fee should be transferred into Daf contract wallet
            ERC20(WBTCAddress).transferFrom(msg.sender, dafWalletAddress, hedgingFee);
            ERC20(WBTCAddress).transferFrom(msg.sender, address(dafNft), payedAmount);
        } else {
            historyCoin = Coin.ETH;
            payedAmount = 10 ** percentageDecimals * _maxPayTokenAmount / (BTCHedgingPercent + 10 ** percentageDecimals);
            hedgingFee = _maxPayTokenAmount - payedAmount;

            amount = spendAllUSD(_batcheIds, payedAmount * getLatestETHPrice());

            require(hedgingFee + payedAmount <= msg.value, "Daf: insufficient eth balance");
            // fee should be transferred into Daf contract wallet

            payable(dafWalletAddress).transfer(hedgingFee);
            value = payedAmount;
        }

        require(amount >= _amount, "Daf: can't buy minimum amount");

        uint256 tokenId = dafNft.mint{value: value}(
            msg.sender,
            amount,
            coinType,
            payedAmount,
            block.timestamp,
            hedgeStart,
            hedgeClaimDuration
        );

        // add in history
        history[msg.sender].push(
            History(
                block.timestamp,
                amount,
                payedAmount + hedgingFee,
                historyCoin,
                tokenId
            )
        );

        dafCoin.transfer(msg.sender, amount);
    }


    function spendAllUSD(uint256[] memory _batcheIds, uint256 _payUSDAmount) internal returns(uint256) {
        uint256 current = _payUSDAmount;
        uint256 dafAmount = 0;

        for (uint256 k = 0; k < _batcheIds.length; ++ k ) {
            uint256 _batchNumber = _batcheIds[k];
            require(_batchNumber < batchCount, "Daf: invalid batch number");
            SalesInformation storage batch = batches[_batchNumber];
            require(batch.active, "Daf: batch sale is not active");

            uint256 currentBatchBuyAmount = current / batch.priceUSD;
            // checking if we can buy all in current batch
            if (batch.sold + currentBatchBuyAmount <= batch.initialAmount) {
                dafAmount += currentBatchBuyAmount;
                batch.sold = batch.sold + currentBatchBuyAmount;
                current = 0;
                break;
            }

            // if we can't buy in current batch
            uint256 buyAmount = batch.initialAmount - batch.sold;
            dafAmount += buyAmount;
            batch.sold = batch.initialAmount;
            current -= buyAmount * batch.priceUSD;
        }

        require(current == 0, "Daf: can't spend whole amount");

        return dafAmount;
    }

    /**
     * @dev transfers batch coins into daf wallet address
     * @param _batchNumber - target sale batch number
    */

    function takeBatchCoins(uint256 _batchNumber) external onlyOwner {
        require(_batchNumber < batchCount, "Daf: invalid batch number");
        require(dafWalletAddress != address(0), "Daf: daf wallet address should not be zero address");

        SalesInformation storage batch = batches[_batchNumber];
        uint256 amount = batch.initialAmount - batch.sold;
        dafCoin.transfer(dafWalletAddress, amount);

        batch.sold += amount;
        batch.active = false;
    }

    /**
     * @dev daf wallet address
     * @param dafWalletAddress_ wallet address
    */

    function setDafWalletAddress(address dafWalletAddress_) external onlyOwner {
        dafWalletAddress = dafWalletAddress_;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
    interface for DafNT
*/

// enum for pay type
enum HedgeCoin { ETH, WBTC }

interface IDafNFT {

    /**
     * @dev minting the token on certain address
     * @param to receiver address
     * @param amount amount of coins
     * @param targetCoin target coin type
     * @param hedgeCoinAmount hedging amount
     * @param startDate hedge start date
     * @param duration hedge start duration
     * @param claimDuration hedge claim duration
    */

    function mint(
        address to,
        uint256 amount,
        HedgeCoin targetCoin,
        uint256 hedgeCoinAmount,
        uint256 startDate,
        uint256 duration,
        uint256 claimDuration
    )
    external
    payable
    returns (uint256);

    /**
     * @dev gets the ownerOf certain tokenId
     * @param tokenId id of token
    */

    function ownerOf(uint256 tokenId) external view returns(address);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
    */

    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev stopping all active hedge for address
     * @param account user address
     * @param balance user's balance
    */

    function stopUserHedges(address account, uint256 balance) external;

    // @dev gets users whole hedge balance
    function userHedgingBalance(address account) external view returns(uint256);
}