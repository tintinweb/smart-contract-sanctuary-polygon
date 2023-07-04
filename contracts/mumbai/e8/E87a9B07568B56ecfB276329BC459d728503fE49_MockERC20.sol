//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "../interfaces/IChainlinkAggregatorV3.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";

/**
 * @title ChainlinkAdapter
 * @notice Price oracle that uses Chainlink's price feeds
 * @dev This contract is meant to be used with the Router contract
 */
contract ChainlinkAdapter is IPriceOracleGetter, Ownable {
    mapping(address => AggregatorV3Interface) public oracleByAsset;

    /**
     * @notice Registers a new price feed
     * @param _asset ERC-20 token address
     * @param _priceFeed Chainlink's price feed address
     */
    function registerPriceFeed(address _asset, address _priceFeed)
        external
        onlyOwner
    {
        require(_asset != address(0), "NO_ASSET");
        require(_priceFeed != address(0), "NO_FEED");

        // Just to check if the address is a valid price feed
        AggregatorV3Interface(_priceFeed).latestRoundData();

        oracleByAsset[_asset] = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice Unregisters a price feed
     * @param _asset ERC-20 token address
     */
    function unregisterPriceFeed(address _asset)
        external
        onlyOwner
    {
        require(_asset != address(0), "NO_ASSET");
        delete oracleByAsset[_asset];
    }

    /**
     * @notice Returns the asset price in USD
     * @param _asset ERC-20 token address
     * @return _price Asset price in USD
     */
    function getAssetPrice(address _asset)
        external
        view
        returns (uint256 _price)
    {
        AggregatorV3Interface _oracle = oracleByAsset[_asset];
        require(address(_oracle) != address(0), "NO_ORACLE");

        (, int256 _signedPrice, , , ) = _oracle.latestRoundData();
        _price = uint256(_signedPrice);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// Source: https://github.com/smartcontractkit/chainlink/blob/b88c0e508671aa0ca4f509bc3752f05b8bd6f430/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol
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

// Based on AAVE protocol
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IPriceOracleGetter interface
interface IPriceOracleGetter {
    /// @dev returns the asset price in USD
    function getAssetPrice(address _asset) external view returns (uint256);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";

contract MockOracle is IPriceOracleGetter {
    mapping(address => uint256) currentPrices;

    constructor(address _asset, uint256 _price) {
        currentPrices[_asset] = _price;
    }

    function updateCurrentPrices(address _asset, uint256 _price)
        external
        returns (uint256)
    {
        return currentPrices[_asset] = _price;
    }

    /// @dev returns the asset price in ETH
    function getAssetPrice(address _asset) external view returns (uint256) {
        return currentPrices[_asset];
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    SafeERC20
} from "contracts/@chain/ethereum/token/SafeERC20.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {ISwapPoolPermissioned} from "../interfaces/ISwapPool.sol";
import "../interfaces/IRouter.sol";

contract Router is Pausable, ReentrancyGuard, Ownable, IRouterPermissioned {
    using SafeERC20 for IERC20;

    mapping(address => ISwapPoolPermissioned) public poolByAsset;
    mapping(address => IPriceOracleGetter) public oracleByAsset;

    /**
     * @notice Changes the pools priceOracle. Can only be set by the contract owner.
     * @param _priceOracle new pool's priceOracle addres
     */
    function setPriceOracle(address _asset, address _priceOracle)
        external
        onlyOwner
    {
        require(_asset != address(0), "NO_ASSET");
        require(_priceOracle != address(0), "NO_ORACLE");
        oracleByAsset[_asset] = IPriceOracleGetter(_priceOracle);
    }

    /**
     * @notice Registers a newly created swap pool.
     */
    function registerPool(address _asset, address _swapPool)
        external
        onlyOwner
    {
        require(_asset != address(0), "NO_ASSET");
        require(_swapPool != address(0), "NO_POOL");
        require(address(oracleByAsset[_asset]) != address(0), "NO_ORACLE");

        poolByAsset[_asset] = ISwapPoolPermissioned(_swapPool);
        IERC20(_asset).approve(_swapPool, 2**256  - 1);

        emit SwapPoolRegistered(_swapPool, _asset);
    }

    /**
     * @notice Disable all swaps
     */
    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    /**
     * @notice Resume all swaps
     */
    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    /**
     * @notice Swap some `_fromToken` tokens for `_toToken` tokens,
     *         ensures `_amountOutMin` and `_deadline`, sends funds to `_to` address
     * @notice `msg.sender` needs to grant the chef contract a sufficient allowance beforehand
     * @param _amountIn     The amount of input tokens to swap
     * @param _amountOutMin The minimum amount that the user will accept
     * @param _tokenInOut   Array of size two, indicating the in and out token
     * @param _to           The recipient of the output tokens
     * @param _deadline     Unix timestamp after which the transaction will revert
     * @return _amounts     Array of size two, containing the input and output amount
     */
    function swapExactTokensForTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _tokenInOut,
        address _to,
        uint _deadline
    )
        external
        whenNotPaused
        returns (uint256[] memory _amounts)
    {
        require(block.timestamp <= _deadline, "ROUTER: EXPIRED");

        uint _amountOut = _swapExactTokensForTokens(_amountIn, _tokenInOut, _to);
        require(_amountOut >= _amountOutMin, "ROUTER: BELOW_MINIMUM");

        _amounts = new uint256[](2);
        _amounts[0] = _amountIn;
        _amounts[1] = _amountOut;

        emit Swap(
            msg.sender,
            _amountIn,
            _amountOut,
            _tokenInOut[0],
            _tokenInOut[1],
            _to
        );
    }

    function _swapExactTokensForTokens(
        uint _amountIn,
        address[] calldata _tokenInOut,
        address _to
    )
        internal
        returns (uint256 _amountOut)
    {
        require(_tokenInOut.length == 2, "ROUTER: TOKEN_ARRAY_SIZE");
        require(_tokenInOut[0] != _tokenInOut[1], "ROUTER: TOKEN_ARRAY_DUPLICATE");

        address _fromToken = _tokenInOut[0];
        address _toToken = _tokenInOut[1];

        require(
            address(poolByAsset[_fromToken]) != address(0) &&
                address(poolByAsset[_toToken]) != address(0),
            "ROUTER: ASSET_NOT_REGISTERED"
        );

        uint256 _tokenPriceFrom = oracleByAsset[_fromToken].getAssetPrice(_fromToken);
        uint256 _tokenPriceTo = oracleByAsset[_toToken].getAssetPrice(_toToken);
        uint256 _offsetFrom = 10**(18 - ERC20(_fromToken).decimals());

        // send user funds
        IERC20(_fromToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amountIn
        );

        // explicit block scoping to prevent "stack too deep" error when reading `_amountIn`
        {
            // user funds into swap pool
            uint256 _effectiveAmountIn = poolByAsset[_fromToken]
                .swapIntoFromRouter(_amountIn);

            // calculate actual price
            uint256 _totalPriceFrom = (
                _effectiveAmountIn *
                _offsetFrom *
                _tokenPriceFrom
            );

            // calculate pay-out amount
            uint256 _rawOutAmount = (_totalPriceFrom / _tokenPriceTo) / _offsetFrom;

            // send funds to user
            _amountOut = poolByAsset[_toToken]
                .swapOutFromRouter(_rawOutAmount);
        }

        IERC20(_toToken).safeTransfer(_to, _amountOut);
    }

    /**
     * @notice Get a quote for how many `_toToken` tokens `_amountIn` many `tokenIn`
     *         tokens can currently be swapped for.
     * @param _amountIn     The amount of input tokens to swap
     * @param _tokenInOut   Array of size two, indicating the in and out token
     * @return _amountOut   Number of `_toToken` tokens that such a swap would yield right now
     */
    function getAmountOut(
        uint _amountIn,
        address[] calldata _tokenInOut
    )
        external
        view
        returns (uint256 _amountOut)
    {
        require(_tokenInOut.length == 2, "ROUTER: TOKEN_ARRAY_SIZE");
        require(_tokenInOut[0] != _tokenInOut[1], "ROUTER: TOKEN_ARRAY_DUPLICATE");

        address _fromToken = _tokenInOut[0];
        address _toToken = _tokenInOut[1];

        uint256 _tokenPriceFrom = oracleByAsset[_fromToken].getAssetPrice(_fromToken);
        uint256 _tokenPriceTo = oracleByAsset[_toToken].getAssetPrice(_toToken);
        uint256 _offsetFrom = 10**(18 - ERC20(_fromToken).decimals());

        // user funds into swap pool
        uint256 _effectiveAmountIn = poolByAsset[_fromToken].quoteSwapInto(_amountIn);

        // calculate actual price
        uint256 _totalPriceFrom = (
            _effectiveAmountIn *
            _offsetFrom *
            _tokenPriceFrom
        );

        // calculate pay-out amount
        uint256 _rawOutAmount = (_totalPriceFrom / _tokenPriceTo) / _offsetFrom;

        _amountOut = poolByAsset[_toToken].quoteSwapOut(_rawOutAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IBackstopPool} from "./IBackstopPool.sol";
import {IPool} from "./IPool.sol";
import {IRouter} from "./IRouter.sol";

/**
 * @notice Public functions of the SwapPool.
 */
interface ISwapPool is IPool {
    /**
     * @notice emitted on every withdrawal
     * @notice special case withdrawal using backstop liquidiity: amountPrincipleWithdrawn = 0
     */
    event Burn(
        address indexed sender,
        uint poolSharesBurned,
        uint amountPrincipleWithdrawn
    );

    /**
     * @notice Tracks the exact amounts of individual fees paid during a swap
     */
    event ChargedSwapFees(
        uint lpFees,
        uint backstopFees,
        uint protocolFees
    );

    /**
     * @notice emitted on every deposit
     */
    event Mint(
        address indexed sender,
        uint poolSharesMinted,
        uint amountPrincipleDeposited
    );

    function backstop()
        external
        view
        returns (IBackstopPool _pool);

    function protocolTreasury()
        external
        view
        returns (address);

    function quoteSwapInto(uint256 _amount)
        external
        view
        returns (uint256 _effectiveAmount);

    function quoteSwapOut(uint256 _amount)
        external
        view
        returns (uint256 _effectiveAmount);

    function router()
        external
        view
        returns (IRouter _router);

    /// @notice get swap fees (applied when swapping liquidity out), in basis points (0.01%)
    function swapFees()
        external
        view
        returns (uint256 _lpFeeBps, uint256 _backstopFeeBps, uint256 _protocolFeeBps);
}

/**
 * @notice Access-restricted functions of the SwapPool.
 */
interface ISwapPoolPermissioned is ISwapPool {
    /**
     * @notice emitted when a backstop pool LP withdraws liquidity from swap pool
     * @notice only possible if swap pool coverage ratio remains >= 100%
     */
    event BackstopDrain(
        address recipient,
        uint256 amountSwapTokens
    );

    /// @notice for swap pool LP backstop withdrawal
    /// @param shares    number of lp tokens to burn
    function backstopBurn(address owner, uint256 shares)
        external
        returns (uint256 amount);

    /// @notice for backstop pool to withdraw liquidity if swap pool's coverage ratio > 100%
    /// @param amount   amount of swap pool reserves to withdraw
    function backstopDrain(uint256 amount, address recipient)
        external;

    /// @notice update the fees that the pool charges on every swap
    /// @param lpFeeBps         fee that benefits the pool's LPers, in basis points
    /// @param backstopFeeBps   fee that benefits the backstop pool, in basis points
    /// @param protocolFeeBps   fee that benefits the protocol, in basis points
    function setSwapFees(uint256 lpFeeBps, uint256 backstopFeeBps, uint256 protocolFeeBps)
        external;

    function swapIntoFromRouter(uint256 amount)
        external
        returns (uint256 effectiveAmount);

    function swapOutFromRouter(uint256 amount)
        external
        returns (uint256 effectiveAmount);

    function pause()
        external;

    function unpause()
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {ISwapPoolPermissioned} from "../interfaces/ISwapPool.sol";

interface IRouter {
    /**
     * Emitted on each swap
     */
    event Swap(
        address indexed sender,
        uint amountIn,
        uint amountOut,
        address tokenIn,
        address tokenOut,
        address indexed to
    );

    /**
     * Emitted when a new pool is registered
     */
    event SwapPoolRegistered(
        address pool,
        address asset
    );

    function oracleByAsset(address asset) external view returns (IPriceOracleGetter);
    function poolByAsset(address asset) external view returns (ISwapPoolPermissioned);

    function swapExactTokensForTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _tokenInOut,
        address _to,
        uint _deadline
    )
        external
        returns (uint256[] memory _amounts);

    function getAmountOut(
        uint _amountIn,
        address[] calldata _tokenInOut
    )
        external
        view
        returns (uint256 _amountOut);
}

interface IRouterPermissioned is IRouter {
    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {IPool} from "./IPool.sol";
import {IRouter} from "./IRouter.sol";

/**
 * @notice Public functions of the backstop pool.
 */
interface IBackstopPool is IPool {
    /**
     * @notice emitted on every withdrawal
     * @notice special case withdrawal using swap liquidiity: amountPrincipleWithdrawn = 0
     */
    event Burn(
        address indexed sender,
        uint poolSharesBurned,
        uint amountPrincipleWithdrawn
    );

    /**
     * @notice emitted when a swap pool LP withdraws from backstop pool
     */
    event CoverSwapWithdrawal(
        address indexed owner,
        address swapPool,
        uint256 amountSwapShares,
        uint256 amountSwapTokens,
        uint256 amountBackstopTokens
    );

    /**
     * @notice emitted on every deposit
     */
    event Mint(
        address indexed sender,
        uint256 poolSharesMinted,
        uint256 amountPrincipleDeposited
    );

    /**
     * @notice emitted when a backstop pool LP withdraws liquidity from swap pool
     */
    event WithdrawSwapLiquidity(
        address indexed owner,
        address swapPool,
        uint256 amountSwapTokens,
        uint256 amountBackstopTokens
    );

    function redeemSwapPoolShares(
        address swapPool,
        uint256 shares,
        uint256 minAmount
    )
        external
        returns (uint256 amount);

    function withdrawExcessSwapLiquidity(
        address swapPool,
        uint256 shares,
        uint256 minAmount
    )
        external
        returns (uint256 amount);

    function getBackedPool(uint256 index)
        external
        view
        returns (address swapPool);

    function getBackedPoolCount()
        external
        view
        returns (uint256 count);

    function getInsuranceFee(address swapPool)
        external
        view
        returns (uint256 feeBps);

    function getTotalPoolWorth()
        external
        view
        returns (uint256 value);

    function router()
        external
        view
        returns (IRouter _router);
}

interface IBackstopPoolPermissioned is IBackstopPool {
    function addSwapPool(address swapPool, uint256 insuranceFeeBps)
        external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IGenericPoolPermissioned} from "./IGenericPool.sol";

/**
 * @notice Public functions of ERC20 pool interface.
 */
interface IPool is IGenericPoolPermissioned {
    function coverage()
        external
        view
        returns (uint256 reserves, uint256 liabilities);

    function deposit(uint256 amount)
        external
        returns (uint256 poolShares, int256 fee);

    function withdraw(uint256 shares, uint256 minimumAmount)
        external
        returns (uint256 finalAmount, int256 fee);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @notice Generic ERC20 pool interface, public functions.
 */
interface IGenericPool {
    function asset()
        external
        view
        returns (address _token);

    function poolCap()
        external
        view
        returns (uint256 _maxTokens);

    function sharesTargetWorth(uint256 _shares)
        external
        view
        returns (uint256 _amount);

    // _deposit() & _withdraw() not declared here as Solidity doesn't allow
    // interfaces to declare private/internal functions
}

/**
 * @notice Access-restricted functions of the IGenericPool.
 */
interface IGenericPoolPermissioned is IGenericPool {
    function setPoolCap(uint256 _maxTokens)
        external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    SafeERC20
} from "contracts/@chain/ethereum/token/SafeERC20.sol";
import {
    SafeCast
} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ISlippageCurve} from "../interfaces/ISlippageCurve.sol";
import {GenericPool} from "./GenericPool.sol";
import "../interfaces/IBackstopPool.sol";
import "../interfaces/ISwapPool.sol";

/**
 * @notice Swap pool contract. May or may not be covered by a backstop pool.
 * @notice Conceptionally, there are two ways to temporarily disable a pool:
 *         The owner can either pause the pool, disabling deposits, swaps & backstop,
 *         or the owner can set the pool cap to zero which only prevents deposits.
 *         The former is for security incidents, the latter for phasing out a pool.
 */
contract SwapPool is
    GenericPool,
    Pausable,
    ReentrancyGuard,
    Ownable,
    ISwapPool,
    ISwapPoolPermissioned
{
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    struct SwapFees {
        uint32 lpFeeBps;
        uint32 backstopFeeBps;
        uint32 protocolFeeBps;
    }

    // Track total historic slippage, since we need reserves excl. slippage to calculate slippage
    uint256 public accumulatedSlippage = 0;

    // Duration of non-withdrawal after deposit, in blocks
    uint256 public insuranceWithdrawalTimelock = 1_000;

    // Address of the treasury account
    address public protocolTreasury;

    IBackstopPool public immutable backstop;
    IRouter public immutable router;

    // Must be immutable (also includes params!)
    ISlippageCurve public immutable slippageCurve;

    // Used for backstop withdrawal time lock
    mapping(address => uint256) private latestDepositAtBlockNo;

    // Fee charged when swapping tokens out of the pool
    SwapFees private swapFeeConfig;

    modifier onlyBackstop() {
        require(msg.sender == address(backstop), "SwapPool: ONLY_BACKSTOP");
        _;
    }

    modifier onlyRouter() {
        require(msg.sender == address(router), "SwapPool: ONLY_ROUTER");
        _;
    }

    constructor(
        address _asset,
        address _slippageCurve,
        address _router,
        address _backstop,
        address _protocolTreasury,
        string memory _name,
        string memory _symbol
    )
        GenericPool(_asset, _name, _symbol)
    {
        backstop = IBackstopPool(_backstop);
        router = IRouter(_router);
        protocolTreasury = _protocolTreasury;
        slippageCurve = ISlippageCurve(_slippageCurve);

        if (_backstop != address(0)) {
            require(_router == address(backstop.router()), "constructor():BACKSTOP_ROUTER_MISMATCH");
        }
    }

    /**
     * @notice Deposits amount of tokens into pool
     * @notice Will change cov ratio of pool, will increase delta to 0
     * @param _amount The amount to be deposited
     * @return _poolShares Total number of pool lp tokens minted
     */
    function deposit(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 _poolShares, int256 _fee)
    {
        latestDepositAtBlockNo[msg.sender] = block.number;

        _fee = _depositFee(_amount);
        _poolShares = _deposit(msg.sender, _amount, _fee);

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _fee).toUint256();

        emit Mint(msg.sender, _poolShares, _amount);
    }

    /**
     * @notice Set new insurance withdrawal time lock.
     * @notice Can only be called by the owner
     * @param _durationInBlocks New time lock duration in blocks
     */
    function setInsuranceWithdrawalTimelock(uint256 _durationInBlocks)
        external
        onlyOwner
    {
        require(_durationInBlocks > 0, "setInsuranceWithdrawalTimelock: INVALID_DURATION");
        insuranceWithdrawalTimelock = _durationInBlocks;
    }

    /**
     * @notice Set new upper limit of pool reserves. Will disable deposits when reached.
     * @notice Can always set to an amount < current reserves to temporarily restrict deposits.
     * @param _maxTokens    New limit how many `poolAsset` tokens can be deposited
     */
    function setPoolCap(uint256 _maxTokens)
        external
        onlyOwner
    {
        poolCap = _maxTokens;
    }

    /**
     * @notice Set swap fees (applied when swapping funds out of the pool)
     * @param _lpFeeBps         Fee that benefits the pool's LPers, in basis points
     * @param _backstopFeeBps   Fee that benefits the backstop pool, in basis points
     * @param _protocolFeeBps   Fee that benefits the protocol, in basis points
     */
    function setSwapFees(uint256 _lpFeeBps, uint256 _backstopFeeBps, uint256 _protocolFeeBps)
        external
        onlyOwner
    {
        // don't allow swap fees >= 30% (essentially fraud)
        require(
            _lpFeeBps + _backstopFeeBps + _protocolFeeBps < 30_00,
            "setSwapFees: FEES_TOO_HIGH"
        );

        swapFeeConfig = SwapFees({
            lpFeeBps: _lpFeeBps.toUint32(),
            backstopFeeBps: _backstopFeeBps.toUint32(),
            protocolFeeBps: _protocolFeeBps.toUint32()
        });
    }

    /**
     * @notice Withdraws liquidity amount of asset ensuring minimum amount required
     * @param _shares The liquidity to be withdrawn
     * @param _minimumAmount The minimum amount that will be accepted by user
     * @return _finalAmount     Amount withdrawn after applying withdrawal fee
     * @return _fee             Charged fee, negative fee indicates a reward
     */
    function withdraw(uint256 _shares, uint256 _minimumAmount)
        external
        nonReentrant
        returns (uint256 _finalAmount, int256 _fee)
    {
        uint _amountBeforeFees = sharesTargetWorth(_shares);

        _fee = _withdrawalFee(_amountBeforeFees);
        _finalAmount = _withdraw(msg.sender, _shares, _amountBeforeFees, _fee);

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _fee).toUint256();

        require(
            _finalAmount >= _minimumAmount,
            "withdraw: MINIMUM_AMOUNT"
        );

        emit Burn(msg.sender, _shares, _finalAmount);
    }

    /**
     * @notice Burns LP tokens of owner, will get compensated using backstop liquidity
     * @notice Can only be invoked by backstop pool, disabled when pool is paused
     * @param _owner The LP's address whose LP tokens should be burned
     * @param _shares The number of LP tokens to burn
     * @return _amount The amount of `asset()` tokens that the burned shares were worth
     */
    function backstopBurn(address _owner, uint256 _shares)
        external
        onlyBackstop
        nonReentrant
        whenNotPaused
        returns (uint256 _amount)
    {
        require(balanceOf(_owner) >= _shares, "SwapPool#backstopBurn: BALANCE_TOO_LOW");
        require(_amount <= totalLiabilities, "SwapPool#backstopBurn: EXCESS_AMOUNT");
        require(
            block.number - latestDepositAtBlockNo[_owner] >= insuranceWithdrawalTimelock,
            "SwapPool#backstopBurn: TIMELOCK"
        );

        _amount = sharesTargetWorth(_shares);
        _burn(_owner, _shares);
        totalLiabilities -= _amount;
    }

    /**
     * @notice For backstop pool to withdraw liquidity if swap pool's coverage ratio > 100%
     * @notice Can only be invoked by backstop pool
     * @param _amount The amount of `asset()` tokens to be moved out of swap pool
     * @param _recipient Address to send the funds to
     */
    function backstopDrain(uint256 _amount, address _recipient)
        external
        onlyBackstop
        nonReentrant
    {
        poolAsset.safeTransfer(_recipient, _amount);

        // check that we didn't cross below 100% coverage as only excess liquidity is drainable
        require(
            poolAsset.balanceOf(address(this)) >= totalLiabilities,
            "SwapPool#backstopDrain: COVERAGE_RATIO"
        );

        emit BackstopDrain(_recipient, _amount);
    }

    /**
     * @notice Get called by Router to deposit an amount of pool asset
     * @notice Can only be called by Router
     * @param _amount The amount of asset to swap into the pool
     * @return _effectiveAmount Effective amount, incl. slippage and fees
     */
    function swapIntoFromRouter(uint256 _amount)
        external
        onlyRouter
        whenNotPaused
        nonReentrant
        returns (uint256 _effectiveAmount)
    {
        int _slippage;
        (_effectiveAmount, _slippage) = _quoteSwapInto(_amount);

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _slippage).toUint256();
        poolAsset.safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice get called by Router to withdraw amount of pool asset
     * @notice Can only be called by Router
     * @param _amount The amount of asset to withdraw
     * @return _effectiveAmount actual withdraw amount
     */
    function swapOutFromRouter(uint256 _amount)
        external
        onlyRouter
        whenNotPaused
        nonReentrant
        returns (uint256 _effectiveAmount)
    {
        uint256 _lpFee;
        uint256 _backstopFee;
        uint256 _protocolFee;

        (uint256 _amountWithSlippage, int _slippage) = _quoteSwapOut(_amount);
        (_effectiveAmount, _lpFee, _backstopFee, _protocolFee) = _applySwapFee(_amountWithSlippage);

        require(
            _effectiveAmount <= poolAsset.balanceOf(address(this)),
            "SwapPool#swapOutFromRouter: OUT_OF_FUNDS"
        );

        // LP fee: Only increase `totalLiabilities`, so all LPers' pool shares are worth more
        // Backstop fee: Just keep fee in the pool reserve (incr. excess liq. / decr. liq. gap)
        // Protocol fee: Transfer to treasury

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _slippage).toUint256();
        totalLiabilities += _lpFee;

        emit ChargedSwapFees(_lpFee, _backstopFee, _protocolFee);
        poolAsset.safeTransfer(msg.sender, _effectiveAmount);

        if (_protocolFee > 0) {
            poolAsset.safeTransfer(protocolTreasury, _protocolFee);
        }
    }

    /**
     * @notice Pause deposits and swaps
     */
    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    /**
     * @notice Resume deposits and swaps
     */
    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    /**
     * @notice returns pool coverage ratio
     * @return _reserves    current amount of `asset` in this pool
     * @return _liabilities total amount of `asset` deposited by liquidity providers
     */
    function coverage()
        external
        view
        returns (uint256 _reserves, uint256 _liabilities)
    {
        _liabilities = totalLiabilities;
        _reserves = poolAsset.balanceOf(address(this));
    }

    /**
     * @notice Return the earliest block no that insurance withdrawals are possible.
     * @param _liquidityProvider    Address of some account, usually the caller
     * @return _unlockedOnBlockNo   Block number of the first block after time lock runs out
     */
    function insuranceWithdrawalUnlock(address _liquidityProvider)
        external
        view
        returns (uint256 _unlockedOnBlockNo)
    {
        _unlockedOnBlockNo = (
            latestDepositAtBlockNo[_liquidityProvider] + insuranceWithdrawalTimelock
        );
    }

    /**
     * @notice Get a quote for the effective amount of tokens, incl. slippage and fees
     * @param _amount The amount of asset to swap into the pool
     * @return _effectiveAmount Effective amount, incl. slippage and fees
     */
    function quoteSwapInto(uint256 _amount)
        public
        view
        returns (uint256 _effectiveAmount)
    {
        (_effectiveAmount,) = _quoteSwapInto(_amount);
        // do not apply swap fee for swaps into the pool
    }

    /**
     * @notice Get a quote for the effective amount of tokens, incl. slippage and fees
     * @param _amount The amount of asset to swap out of the pool
     * @return _effectiveAmount Effective amount, incl. slippage and fees
     */
    function quoteSwapOut(uint256 _amount)
        public
        view
        returns (uint256 _effectiveAmount)
    {
        (uint256 _amountWithSlippage,) = _quoteSwapOut(_amount);
        (_effectiveAmount,,,) = _applySwapFee(_amountWithSlippage);
    }

    /**
     * @notice Return the configured swap fees for this pool
     * @return _lpFeeBps         Fee that benefits the pool's LPers, in basis points
     * @return _backstopFeeBps   Fee that benefits the backstop pool, in basis points
     * @return _protocolFeeBps   Fee that benefits the protocol, in basis points
     */
    function swapFees()
        public
        view
        returns (uint256 _lpFeeBps, uint256 _backstopFeeBps, uint256 _protocolFeeBps)
    {
        SwapFees memory _fees = swapFeeConfig;
        _lpFeeBps = _fees.lpFeeBps;
        _backstopFeeBps = _fees.backstopFeeBps;
        _protocolFeeBps = _fees.protocolFeeBps;
    }

    /**
     * @notice Charge swap fee from an amount
     * @param _inputAmount  Arbitrary input amount, before fee
     * @return _remaining   Input amount after applying the fee
     * @return _lpFee       Fee charged, benefitting the pool's LPers
     * @return _backstopFee Fee charged, benefitting the backstop pool
     * @return _protocolFee Fee charged, benefitting the protocol
     */
    function _applySwapFee(uint256 _inputAmount)
        internal
        view
        returns (uint256 _remaining, uint256 _lpFee, uint256 _backstopFee, uint256 _protocolFee)
    {
        SwapFees memory _fees = swapFeeConfig;
        _lpFee = _inputAmount * _fees.lpFeeBps / 100_00;
        _backstopFee = _inputAmount * _fees.backstopFeeBps / 100_00;
        _protocolFee = _inputAmount * _fees.protocolFeeBps / 100_00;
        _remaining = _inputAmount - _lpFee - _backstopFee - _protocolFee;
    }

    /**
     * @notice see whitepaper, section 2.5.1
     */
    function _depositFee(uint256 _depositAmount)
        internal
        view
        returns (int256 _fee)
    {
        _fee = _depositAmount.toInt256() - slippageCurve.effectiveDeposit(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _depositAmount
        ).toInt256();
    }

    /**
     * @notice see whitepaper, section 2.5.2
     */
    function _withdrawalFee(uint256 _withdrawalAmount)
        internal
        view
        returns (int256 _fee)
    {
        _fee = _withdrawalAmount.toInt256() - slippageCurve.effectiveWithdrawal(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _withdrawalAmount
        ).toInt256();
    }

    /**
     * @notice Get a quote for the effective amount of tokens, incl. slippage and fees
     * @param _amount The amount of asset to swap into the pool
     * @return _effectiveAmount Effective amount, incl. slippage and fees
     * @return _slippage        Resulting slippage, negative no. indicates reward
     */
    function _quoteSwapInto(uint256 _amount)
        private
        view
        returns (uint256 _effectiveAmount, int256 _slippage)
    {
        _effectiveAmount = slippageCurve.effectiveSwapIn(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _amount
        );

        _slippage = _amount.toInt256() - _effectiveAmount.toInt256();
    }

    /**
     * @notice Get a quote for the effective amount of tokens, incl. slippage and fees
     * @param _amount The amount of asset to swap out of the pool
     * @return _effectiveAmount Effective amount, incl. slippage and fees
     * @return _slippage        Resulting slippage, negative no. indicates reward
     */
    function _quoteSwapOut(uint256 _amount)
        private
        view
        returns (uint256 _effectiveAmount, int256 _slippage)
    {
        _effectiveAmount = slippageCurve.effectiveSwapOut(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _amount
        );

        _slippage = _amount.toInt256() - _effectiveAmount.toInt256();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

/**
 * @notice configured instance of a slippage curve implementation
 */
interface ISlippageCurve {
    /**
     * @notice adjusts deposit amount by slippage for a pool of a given coverage ratio
     * @param _reservesBefore           pool reserves before deposit
     * @param _liabilitiesBefore        total principle provided to pool by all its LPers
     * @param _accumulatedPoolSlippage  total slippage pool has ever charged minus total rewards
     * @param _depositAmount            increase in pool reserves
     * @return _effectiveLiability      deposited principle credited to the LPer
     */
    function effectiveDeposit(
        uint256 _reservesBefore,
        uint256 _liabilitiesBefore,
        uint256 _accumulatedPoolSlippage,
        uint256 _depositAmount
    )
        external
        view
        returns (uint256 _effectiveLiability);

    /**
     * @notice adjusts amount by slippage for a swap adding liquidity to this pool
     * @notice total swap fee is the sum of the swap fees of each pool involved
     * @param _reservesBefore           pool reserves before deposit
     * @param _liabilitiesBefore        total principle provided to pool by all its LPers
     * @param _accumulatedPoolSlippage  total slippage pool has ever charged minus total rewards
     * @param _deltaAmount              liquidity added to pool
     * @return _effectiveAmount         liquidity considered for conversion into another token
     */
    function effectiveSwapIn(
        uint256 _reservesBefore,
        uint256 _liabilitiesBefore,
        uint256 _accumulatedPoolSlippage,
        uint256 _deltaAmount
    )
        external
        view
        returns (uint256 _effectiveAmount);

    /**
     * @notice adjusts amount by slippage for a swap draining liquidity from this pool
     * @notice total swap fee is the sum of the swap fees of each pool involved
     * @param _reservesBefore           pool reserves before deposit
     * @param _liabilitiesBefore        total principle provided to pool by all its LPers
     * @param _accumulatedPoolSlippage  total slippage pool has ever charged minus total rewards
     * @param _deltaAmount              liquidity intended to be taken from pool
     * @return _effectiveAmount         liquidity actually to be removed, adjusted by slippage
     */
    function effectiveSwapOut(
        uint256 _reservesBefore,
        uint256 _liabilitiesBefore,
        uint256 _accumulatedPoolSlippage,
        uint256 _deltaAmount
    )
        external
        view
        returns (uint256 _effectiveAmount);

    /**
     * @notice adjusts withdrawal amount by slippage for a pool of a given coverage ratio
     * @param _reservesBefore           pool reserves before deposit
     * @param _liabilitiesBefore        total principle provided to pool by all its LPers
     * @param _accumulatedPoolSlippage  total slippage pool has ever charged minus total rewards
     * @param _withdrawalAmount         decrease in pool reserves
     * @return _effectivePayout         principle to be paid to the LPer
     */
    function effectiveWithdrawal(
        uint256 _reservesBefore,
        uint256 _liabilitiesBefore,
        uint256 _accumulatedPoolSlippage,
        uint256 _withdrawalAmount
    )
        external
        view
        returns (uint256 _effectivePayout);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "contracts/@chain/ethereum/token/SafeERC20.sol";
import {
    SafeCast
} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IGenericPoolPermissioned} from "../interfaces/IGenericPool.sol";

/**
 * @notice Abstract contract containing common logic for all pools
 */
abstract contract GenericPool is ERC20, IGenericPoolPermissioned {
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /// @notice Asset held by the pool
    IERC20 internal immutable poolAsset;

    /// @notice Maximum amount of `poolAsset` that can be deposited into this pool
    uint256 public poolCap = 2**256 - 1;

    // Cannot just use totalSupply() as that would require a fixed share:principle ratio
    uint256 internal totalLiabilities = 0;

    modifier checkPoolCap(uint256 _additionalDeposit) {
        require(
            poolAsset.balanceOf(address(this)) + _additionalDeposit <= poolCap,
            "deposit: CAP_EXCEEDED"
        );
        _;
    }

    constructor(
        address _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        poolAsset = IERC20(_asset);
    }

    /**
     * @notice Returns the pooled token's address
     * @return _token   Address of the pooled asset
     */
    function asset()
        public
        view
        returns (address _token)
    {
        _token = address(poolAsset);
    }

    /**
     * @notice Returns the worth of an amount of pool shares (LP tokens) in underlying principle
     * @param _shares The number of LP tokens to burn
     * @return _amount The amount of `asset()` tokens that the shares are worth
     */
    function sharesTargetWorth(uint256 _shares)
        public
        view
        returns (uint256 _amount)
    {
        _amount = _shares * totalLiabilities / totalSupply();
    }

    /**
     * @notice Returns the amount of LP tokens to mint for a given deposit
     * @dev    Deposit amount and fees are passed individually, so that
     *         a contract that overrides the function can treat them differently
     * @param _depositAmount    Volume of the deposit
     * @param _fee              Potential fee, negative value indicates a reward
     * @return _poolShares      Number of LP tokens to mint
     */
    function _sharesToMint(uint256 _depositAmount, int256 _fee)
        internal
        virtual
        view
        returns(uint256 _poolShares)
    {
        uint256 _supplyBefore = totalSupply();
        uint256 _liabilitiesBefore = totalLiabilities;

        uint256 _netAmount = (_depositAmount.toInt256() - _fee).toUint256();

        _poolShares = _supplyBefore > 0
            ? _netAmount * _supplyBefore / _liabilitiesBefore
            : _netAmount;
    }

    /**
     * @notice Deposits amount of tokens into pool (low-level)
     * @notice Will change cov ratio of pool, will increase delta to 0
     * @param _user             Address of the depositing liquidity provider
     * @param _amount           The amount to be deposited
     * @param _poolSharesToMint The number of LP tokens to mint and credit to the LPer
     * @param _fee              Potential fee, negative value indicates a reward
     */
    function _processDeposit(
        address _user,
        uint256 _amount,
        uint256 _poolSharesToMint,
        int256 _fee
    )
        internal
        checkPoolCap(_amount)
    {
        require(_poolSharesToMint > 0, "deposit: ZERO_DEPOSIT");
        totalLiabilities += (_amount.toInt256() - _fee).toUint256();

        _mint(_user, _poolSharesToMint);
        poolAsset.safeTransferFrom(_user, address(this), _amount);
    }

    /**
     * @notice Deposits amount of tokens into pool
     * @notice Will change cov ratio of pool, will increase delta to 0
     * @param _user        The depositing account
     * @param _amount      The amount to be deposited
     * @param _fee         Potential fee that applies to this deposit, negative value = reward
     * @return _poolShares Total number of pool lp tokens minted
     */
    function _deposit(address _user, uint256 _amount, int256 _fee)
        internal
        returns (uint256 _poolShares)
    {
        _poolShares = _sharesToMint(_amount, _fee);
        _processDeposit(_user, _amount, _poolShares, _fee);
    }

    /**
     * @notice Withdraws liquidity amount of asset (low-level)
     * @param _user             Address of the withdrawing liquidity provider
     * @param _shares           The liquidity to be withdrawn
     * @param _grossAmount      Amount withdrawn, before applying withdrawal fee
     * @param _fee              Withdrawal fee to apply
     * @return _payoutAmount    Amount withdrawn after applying withdrawal fee
     */
    function _withdraw(
        address _user,
        uint256 _shares,
        uint256 _grossAmount,
        int256 _fee
    )
        internal
        returns (uint256 _payoutAmount)
    {
        require(balanceOf(_user) >= _shares, "withdraw: INSUFFICIENT_BALANCE");

        // need to revise this section, as not known if this case is possible
        require(int256(_grossAmount) > _fee, "withdraw: FEE_TOO_HIGH");

        _payoutAmount = (_grossAmount.toInt256() - _fee).toUint256();

        _burn(_user, _shares);
        IERC20(poolAsset).safeTransfer(_user, _payoutAmount);

        totalLiabilities -= _grossAmount;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {
    ReentrancyGuard
} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {
    SafeERC20
} from "contracts/@chain/ethereum/token/SafeERC20.sol";
import {
    SafeCast
} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IPriceOracleGetter} from "../interfaces/IPriceOracleGetter.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {ISlippageCurve} from "../interfaces/ISlippageCurve.sol";
import {GenericPool} from "./GenericPool.sol";
import "../interfaces/IBackstopPool.sol";
import "../interfaces/ISwapPool.sol";

/**
 * @notice The backstop pool takes most of the risk of a set of swap pools
 *         backed by it. Whenever a swap pool is low on reserves and a LPer
 *         wants to withdraw some liquidity, they can conduct an insurance
 *         withdrawal (burn swap pool shares, reimbursed in backstop liquidity)
 *         to avoid paying a high slippage.
 *         The backstop pool owns all excess liquidity in its swap pools,
 *         but is also liable for potential liquidity gaps.
 *         In return, the backstop pool receives a cut of the swap fees.
 */
contract BackstopPool is
    GenericPool,
    Pausable,
    ReentrancyGuard,
    Ownable,
    IBackstopPool
{
    using SafeCast for int256;
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    // Need to set some cap as we need to iterate them all for some operations
    uint256 constant private MAX_POOL_COUNT = 30;

    // Optimization: Copy that value into this contract, don't query on each access
    uint256 private immutable poolAssetMantissa;

    IRouter public immutable router;
    ISlippageCurve public immutable slippageCurve;

    // Track total historic slippage, since we need reserves excl. slippage to calculate slippage
    uint256 public accumulatedSlippage = 0;

    address[] private swapPools;
    mapping(address => uint256) private swapPoolInsuranceFeeBps;
    mapping(address => bool) private swapPoolCovered;

    constructor(
        address _router,
        address _asset,
        address _curve,
        string memory _name,
        string memory _symbol
    )
        GenericPool(_asset, _name, _symbol)
    {
        require(_asset != address(0), "NO_ASSET");
        require(_curve != address(0), "NO_CURVE");
        require(_router != address(0), "NO_ROUTER");

        router = IRouter(_router);
        slippageCurve = ISlippageCurve(_curve);
        swapPools = new address[](MAX_POOL_COUNT);

        poolAssetMantissa = 10 ** IERC20Metadata(address(poolAsset)).decimals();
    }

    /**
     * @notice Deposits amount of tokens into pool
     * @notice Will change cov ratio of pool, will increase delta to 0
     * @param _amount The amount to be deposited
     * @return _poolShares Total number of pool lp tokens minted
     */
    function deposit(uint256 _amount)
        external
        whenNotPaused
        nonReentrant
        returns (uint256 _poolShares, int256 _fee)
    {
        _fee = _depositFee(_amount);
        _poolShares = _deposit(msg.sender, _amount, _fee);

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _fee).toUint256();

        emit Mint(msg.sender, _poolShares, _amount);
    }

    /**
     * @notice Set new upper limit of pool reserves. Will disable deposits when reached.
     * @notice Can always set to an amount < current reserves to temporarily restrict deposits.
     * @param _maxTokens    New limit how many `poolAsset` tokens can be deposited
     */
    function setPoolCap(uint256 _maxTokens)
        external
        onlyOwner
    {
        poolCap = _maxTokens;
    }

    // TODO: Why do we override this to use the reserves rather than liabilities as base?
    function _sharesToMint(uint256 _depositAmount, int256 _fee)
        internal
        override
        view
        returns(uint256 _poolShares)
    {
        uint256 _supply = totalSupply();

        if (_supply == 0) {
            _poolShares = _depositAmount;
        } else {
            uint256 _reservesBefore = poolAsset.balanceOf(address(this));
            _poolShares = (
                (_depositAmount * _supply / _reservesBefore).toInt256() - _fee
            ).toUint256();
        }
    }

    /**
     * @notice Withdraws liquidity amount of asset ensuring minimum amount required
     * @notice Slippage is applied (withdrawal fee)
     * @param _shares           The liquidity to be withdrawn
     * @param _minimumAmount    Reject withdrawal if resulting amount is below
     * @return _finalAmount     Amount withdrawn after applying withdrawal fee
     * @return _fee             Charged fee, negative fee indicates a reward
     */
    function withdraw(uint256 _shares, uint256 _minimumAmount)
        external
        nonReentrant
        returns (uint256 _finalAmount, int256 _fee)
    {
        require(_shares <= balanceOf(msg.sender), "withdraw: INSUFFICIENT_BALANCE");

        uint _amountBeforeFees = sharesTargetWorth(_shares);

        _fee = _withdrawalFee(_amountBeforeFees);
        _finalAmount = _withdraw(msg.sender, _shares, _amountBeforeFees, _fee);

        accumulatedSlippage = (accumulatedSlippage.toInt256() + _fee).toUint256();

        require(
            _finalAmount >= _minimumAmount,
            "withdraw: MINIMUM_AMOUNT"
        );

        emit Burn(msg.sender, _shares, _finalAmount);
    }

    /**
     * @notice Make this backstop pool cover another swap pool
     * @notice Beware: Adding a swap pool holding the same token as the backstop pool
     *         can easily cause undesirable conditions and must be secured (i.e. long time lock)!
     * @param _swapPool         Swap pool to add
     * @param _insuranceFeeBps  Relative fee on insurance withdrawals, in basis points (0.01%)
     */
    function addSwapPool(address _swapPool, uint256 _insuranceFeeBps)
        external
        onlyOwner
    {
        for (uint _index = 0; _index < swapPools.length; _index++) {
            require(
                swapPools[_index] != _swapPool,
                "addSwapPool():DUPLICATE_SWAP_POOL"
            );
        }

        swapPools.push(_swapPool);
        swapPoolCovered[_swapPool] = true;

        _setInsuranceFee(_swapPool, _insuranceFeeBps);

        // Invariant violation
        require(
            address(ISwapPool(_swapPool).backstop()) == address(this),
            "addSwapPool():BACKSTOP_MISMATCH"
        );
    }

    /**
     * @notice Change a swap pool's insurance withdrawal fee
     * @param _swapPool         Swap pool to add
     * @param _insuranceFeeBps  Relative fee on insurance withdrawals, in basis points (0.01%)
     */
    function setInsuranceFee(address _swapPool, uint256 _insuranceFeeBps)
        external
        onlyOwner
    {
        _setInsuranceFee(_swapPool, _insuranceFeeBps);
    }

    /**
     * @notice Change a swap pool's insurance withdrawal fee
     * @param _swapPool         Swap pool to add
     * @param _insuranceFeeBps  Relative fee on insurance withdrawals, in basis points (0.01%)
     */
    function _setInsuranceFee(address _swapPool, uint256 _insuranceFeeBps)
        internal
    {
        require(_swapPool != address(0), "_setInsuranceFee: NO_POOL");

        // reject fees > 30% (essentially fraud)
        require(_insuranceFeeBps <= 30_00, "_setInsuranceFee: EXCESSIVE_FEE");

        swapPoolInsuranceFeeBps[_swapPool] = _insuranceFeeBps;
    }

    /**
     * @notice withdraw from a swap pool using backstop liquidity without slippage
     * @notice only possible if swap pool's coverage ratio < 100%
     * @param _swapPool     swap pool address
     * @param _shares       number of swap pool shares to redeem
     * @param _minAmount    minimum amount of backstop liquidity to receive
     * @return _netAmount   amount of backstop liquidity paid-out
     */
    function redeemSwapPoolShares(
        address _swapPool,
        uint256 _shares,
        uint256 _minAmount
    )
        external
        nonReentrant
        returns (uint256 _netAmount)
    {
        require(swapPoolCovered[_swapPool], "redeemSwapPoolShares():NO_COVER");

        uint256 _poolAssetPrice = router
            .oracleByAsset(address(poolAsset))
            .getAssetPrice(address(poolAsset));

        // TODO: Should the user rather call the swap pool to call the backstop pool?
        // TODO: Could swapPool.backstopBurn() impact _getBackstopValue() (?) (-> does not seem to)
        uint256 _swapLiquidity = ISwapPool(_swapPool).sharesTargetWorth(_shares);
        address _swapToken = ISwapPool(_swapPool).asset();

        (uint256 _swapReserves, uint256 _swapLiabilities) = ISwapPool(_swapPool).coverage();
        require(_swapReserves < _swapLiabilities, "redeemSwapPoolShares():SWAP_COVERAGE");

        uint256 _amount = _getBackstopValue(_swapToken, _swapLiquidity, _poolAssetPrice);

        uint256 _actualSwapLiquidity = ISwapPoolPermissioned(_swapPool)
            .backstopBurn(msg.sender, _shares);
        require(_actualSwapLiquidity == _swapLiquidity, "redeemSwapPoolShares():SWAP_LIQ_MISMATCH");

        uint256 _fee = _amount * swapPoolInsuranceFeeBps[_swapPool] / 100_00;
        _netAmount = _amount - _fee;

        require(_netAmount >= _minAmount, "redeemSwapPoolShares():MIN_AMOUNT");

        poolAsset.safeTransfer(msg.sender, _netAmount);
        emit CoverSwapWithdrawal(msg.sender, _swapPool, _shares, _swapLiquidity, _amount);
    }

    /**
     * @notice withdraw from backstop pool, but receive excess liquidity
     *         of a swap pool without slippage, instead of backstop liquidity
     * @param _swapPool     swap pool address, must have a coverage ratio > 100%
     * @param _shares       number of backstop pool shares to redeem
     * @param _minAmount    minimum amount of swap pool liquidity to receive
     * @return _swapAmount  amount of swap pool liquidity paid-out
     */
    function withdrawExcessSwapLiquidity(
        address _swapPool,
        uint256 _shares,
        uint256 _minAmount
    )
        external
        nonReentrant
        returns (uint256 _swapAmount)
    {
        require(swapPoolCovered[_swapPool], "withdrawExcessSwapLiquidity():NO_COVER");
        require(balanceOf(msg.sender) >= _shares, "withdrawExcessSwapLiquidity():BALANCE");

        address _swapToken = ISwapPool(_swapPool).asset();
        uint256 _backstopAmount = totalLiabilities * _shares / totalSupply();

        _swapAmount = _convertToSwapAmount(_swapToken, _backstopAmount);
        ISwapPoolPermissioned(_swapPool).backstopDrain(_swapAmount, msg.sender);

        require(_swapAmount >= _minAmount, "withdrawExcessSwapLiquidity():MIN_AMOUNT");

        totalLiabilities -= _backstopAmount;
        _burn(msg.sender, _shares);

        emit WithdrawSwapLiquidity(
            msg.sender,
            _swapPool,
            _swapAmount,
            _backstopAmount
        );
    }

    /**
     * @notice returns pool coverage ratio
     * @return _reserves    current amount of `asset` in this pool
     * @return _liabilities total amount of `asset` deposited by liquidity providers
     */
    function coverage()
        external
        view
        returns (uint256 _reserves, uint256 _liabilities)
    {
        _liabilities = totalLiabilities;
        _reserves = poolAsset.balanceOf(address(this));
    }

    /**
     * @notice enumerate swap pools backed by this backstop pool
     * @return _swapPool swap pool address
     */
    function getBackedPool(uint256 _index)
        external
        view
        returns (address _swapPool)
    {
        require(swapPools.length > 0 && _index < swapPools.length, "getBackedPool():INVALID_INDEX");
        return address(swapPools[_index]);
    }

    /**
     * @notice get swap pool count backed by this backstop pool
     * @return _count number of swap pools
     */
    function getBackedPoolCount()
        external
        view
        returns (uint256 _count)
    {
        return swapPools.length;
    }

    /**
     * @notice get insurance withdrawal fee for a given swap pool
     * @param _swapPool address of the swap pool
     * @return _feeBps  insurance witdrawal fee, in basis points (0.01%)
     */
    function getInsuranceFee(address _swapPool)
        external
        view
        returns (uint256 _feeBps)
    {
        _feeBps = swapPoolInsuranceFeeBps[_swapPool];
    }

    /**
     * @notice return worth of the whole backstop pool in `asset()`, incl. all
     *         swap pools' excess liquidity and the backstop pool's liabilities
     * @return _value   total value of all backstop pool shares, in `asset()`
     * @dev    ignoring if pools are paused or not, since liabilities still apply
     *         and we don't want the backstop pool worth to jump
     */
    function getTotalPoolWorth()
        public
        view
        returns (uint256 _value)
    {
        uint256 _reserveTokenPrice = router
            .oracleByAsset(address(poolAsset))
            .getAssetPrice(address(poolAsset));

        int256 _subtotal = poolAsset.balanceOf(address(this)).toInt256();

        require(_reserveTokenPrice > 0, "getTotalPoolWorth(): RESERVE_PRICE_ZERO");

        for (uint _index = 0; _index < swapPools.length; _index++) {
            ISwapPool _swapPool = ISwapPool(swapPools[_index]);
            address _swapReserveToken = _swapPool.asset();
            if (_swapReserveToken == address(0)) {
                continue;
            }
            int256 _excessLiquidity = _getSwapPoolExcessLiquidity(_swapPool);
            uint256 _excessLiquidityValue = _getBackstopValue(
                _swapReserveToken,
                (_excessLiquidity < 0 ? -_excessLiquidity : _excessLiquidity).toUint256(),
                _reserveTokenPrice
            );

            if (_excessLiquidity < 0) {
                _subtotal -= _excessLiquidityValue.toInt256();
            } else {
                _subtotal += _excessLiquidityValue.toInt256();
            }
        }

        _value = _subtotal > 0 ? _subtotal.toUint256() : 0;
    }

    /**
     * @notice converts an amount of backstop liquidity into some other token amount
     * @param _token            ERC20 token contract address
     * @param _backstopAmount   amount in backstop liquidity
     * @return _swapAmount      amount of `_token` resembling the value of `_backstopAmount`
     */
    function _convertToSwapAmount(address _token, uint256 _backstopAmount)
        internal
        view
        returns (uint256 _swapAmount)
    {
        uint256 _poolAssetPrice = router
            .oracleByAsset(address(poolAsset))
            .getAssetPrice(address(poolAsset));

        uint256 _tokenPrice = router.oracleByAsset(_token).getAssetPrice(_token);

        require(_tokenPrice > 0, "_convertToSwapAmount(): TOKEN_PRICE_ZERO");

        _swapAmount = (
            _backstopAmount
                * _poolAssetPrice
                / _tokenPrice
                * (10 ** IERC20Metadata(_token).decimals())
                / poolAssetMantissa
        );
    }

    /**
     * @notice returns the value of some token position in backstop reserve tokens
     * @param _token            ERC20 token contract address
     * @param _amount           amount of `_token`
     * @param _poolAssetPrice   current price of `poolAsset`
     * @return _value           value of input converted into backstop tokens
     */
    function _getBackstopValue(address _token, uint256 _amount, uint256 _poolAssetPrice)
        internal
        view
        returns (uint256 _value)
    {
        uint256 _tokenPrice = router.oracleByAsset(_token).getAssetPrice(_token);

        require(_poolAssetPrice > 0, "_getBackstopValue(): ASSET_PRICE_ZERO");
        require(_tokenPrice > 0, "_getBackstopValue(): TOKEN_PRICE_ZERO");

        _value = (
            _amount
                * _tokenPrice
                / _poolAssetPrice
                * poolAssetMantissa
                / (10 ** IERC20Metadata(_token).decimals())
        );
    }

    /**
     * @notice returns a swap pool's total reserves minus its LPs' liabilities
     * @param _swapPool         swap pool to query
     * @return _excessTokens    excess liquidity in swap pool's reserve tokens,
     *                          negative if swap pool's coverage ratio < 100%
     */
    function _getSwapPoolExcessLiquidity(ISwapPool _swapPool)
        internal
        view
        returns (int256 _excessTokens)
    {
        (uint256 _reserves, uint256 _liabilities) = _swapPool.coverage();
        _excessTokens = _reserves.toInt256() - _liabilities.toInt256();
    }

    /**
     * @notice determines the deposit fee to charge
     * @param _depositAmount    amount to deposit
     * @return _fee             fee to be charged, negative fee indicates a reward
     */
    function _depositFee(uint256 _depositAmount)
        internal
        view
        returns (int256 _fee)
    {
        _fee = _depositAmount.toInt256() - slippageCurve.effectiveDeposit(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _depositAmount
        ).toInt256();
    }

    /**
     * @notice determines the withdrawal fee to charge
     * @param _withdrawalAmount amount to withdrawal
     * @return _fee             fee to be charged, negative fee indicates a reward
     */
    function _withdrawalFee(uint256 _withdrawalAmount)
        internal
        view
        returns (int256 _fee)
    {
        _fee = _withdrawalAmount.toInt256() - slippageCurve.effectiveWithdrawal(
            poolAsset.balanceOf(address(this)),
            totalLiabilities,
            accumulatedSlippage,
            _withdrawalAmount
        ).toInt256();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    function mint(address _to, uint256 _amount) public virtual {
        _mint(_to, _amount);
    }

    function burn(address from, uint256 _amount) public virtual {
        _burn(from, _amount);
    }
}