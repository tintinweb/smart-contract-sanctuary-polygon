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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ICollectoNFT {
  function addNewAsset (string memory _uri) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IOnboarding {
  function totalShareholders() external view returns (uint);
  function shareholderByIndex(uint _index) external view returns (address, uint);
  function wmatic() external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IOnboardingFactory {
  function isOnboardingValid(address _onboarding) external view returns (bool);
  function wmatic() external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol"; 
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import "./interfaces/ICollectoNFT.sol";
import "./interfaces/IOnboarding.sol";
import "./interfaces/IOnboardingFactory.sol";
import "./interfaces/IWETH.sol";

contract Onboarding is IOnboarding, Ownable {

  /////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  ISwapRouter public constant router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
  address public immutable override wmatic;

  uint public maxSupply;
  uint public totalShares;
  uint public override totalShareholders;
  uint public preSaleStart;
  uint public preSaleEnd;
  uint public preSaleMinimumTarget;
  uint public sharePrice;
  IERC20 public paymentToken;
  ICollectoNFT public collectoNFT;
  string public uri;
  address public treasuryAddress;

  mapping (address => uint) public shares;

  address[] public shareholders;

  /////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  /**
   * @notice Constructor
   * @param _collectoNFT Address of the Collecto NFT
   * @param _uri Uri of the asset
   * @param _maxSupply Maximum number of tokens
   * @param _preSaleStart Start timestamp of the presale
   * @param _preSaleEnd End timestamp of the presale
   * @param _preSaleMinimumTarget Minimum number of payment tokens in order to
              consider the pre sale successful
   * @param _sharePrice Price of a single share (with decimals)
   * @param _paymentToken Address of the selected payment token (with decimals).
              For native payments use address(0)
   * @param _treasury Treasury address
   */
  constructor (
    address _collectoNFT,
    string memory _uri,
    uint _maxSupply,
    uint _preSaleStart,
    uint _preSaleEnd,
    uint _preSaleMinimumTarget,
    uint _sharePrice,
    address _paymentToken,
    address _treasury
  ) { 
    uri = _uri;

    collectoNFT = ICollectoNFT(_collectoNFT);
    maxSupply = _maxSupply;

    preSaleStart = _preSaleStart;
    preSaleEnd = _preSaleEnd;
    preSaleMinimumTarget = _preSaleMinimumTarget;
    sharePrice = _sharePrice;

    paymentToken = IERC20(_paymentToken);
    treasuryAddress = _treasury;

    // Damn, stack too deep hit hard here
    wmatic = IOnboardingFactory(msg.sender).wmatic();
  }

  /////////////////////////////////////////////////////////////////////////////
  // PUBLIC FUNCTIONS
  /**
   * @notice Buy shares
   * @param _buyerToken Address of the token the buyer wants to use
   * @param _buyerTokenAmount Amount of the buyer token to spend
   * @param _shares Number of shares to buy
   * @dev Buyer must approve the transfer of _buyerTokenAmount to this smart contract 
          before calling this function. Also, you should consider a bit of slippage
   */
  function buyShares(address _buyerToken, uint _buyerTokenAmount, uint _shares) external payable {
    require (isPreSaleActive(), "Presale not active");
    require (totalShares + _shares <= maxSupply, "Shares exceed max supply");

    uint price = _shares * sharePrice;
    processPaymentFrom(_buyerToken, _buyerTokenAmount, price);

    if (shares[msg.sender] == 0) {
      totalShareholders += 1;
      shareholders.push(msg.sender);
    }

    shares[msg.sender] += _shares;
    totalShares += _shares;
  }

  /**
   * @notice Refund shareholder if campaign is unsuccessful
   * @param _shares Number of shares to refund
   */
  function refundIfUnsuccessful (uint _shares) external {
    require (block.timestamp > preSaleEnd, "Pre sale not yet ended");
    require (! isPreSaleSuccessful(), "Pre sale is successful");

    require (shares[msg.sender] >= _shares, "Invalid number of shares");
    shares[msg.sender] -= _shares;
    totalShares -= _shares;

    uint refund = _shares * sharePrice;
    processPaymentTo(msg.sender, refund);
  }

  /**
   * @notice Returns the number of shares of a shareholder and its address
   * @param _index Shareholder index 
   */
  function shareholderByIndex(uint _index) external view returns (address, uint) {
    return (shareholders[_index], shares[shareholders[_index]]);
  }

  /////////////////////////////////////////////////////////////////////////////
  // PRIVILEGED FUNCTIONS
  function onboard() external onlyOwner {
    require (block.timestamp > preSaleEnd, "Pre sale not yet ended");
    require (isPreSaleSuccessful(), "Pre sale is unsuccessful");

    uint balance = getBalance();
    processPaymentTo(treasuryAddress, balance);

    collectoNFT.addNewAsset(uri);
  }

  /**
   * @notice Buy shares with external payment
   * @param _receiver Address that is going to receive the shares
   * @param _shares Number of shares to buy
   */
  function buySharesWithExternalPayment(address _receiver, uint _shares) external payable onlyOwner {
    require (isPreSaleActive(), "Presale not active");
    require (totalShares + _shares <= maxSupply, "Shares exceed max supply");

    if (shares[_receiver] == 0) {
      totalShareholders += 1;
      shareholders.push(_receiver);
    }

    shares[_receiver] += _shares;
    totalShares += _shares;
  }

  /////////////////////////////////////////////////////////////////////////////
  // INTERNAL FUNCTIONS
  /**
   * @notice Returns true if the pre sale is active, false otherwise
   */
  function isPreSaleActive() internal view returns (bool) {
    return (block.timestamp >= preSaleStart && block.timestamp <= preSaleEnd);
  }

  function isPreSaleSuccessful() internal view returns (bool) {
    return (totalShares * sharePrice >= preSaleMinimumTarget);
  }


  /**
   * @notice Process incoming payment 
   * @param _buyerToken Address of the token the buyer wants to use
   * @param _buyerTokenAmount Amount of the buyer token to spend
   * @param _amount Minimum payment expected
   * @dev Refunds excess tokens, if any.
   */
  function processPaymentFrom(address _buyerToken, uint _buyerTokenAmount, uint _amount) internal {
    // case 1: buyer token is the same as the payment token
    if (_buyerToken == address(paymentToken)) {
      // Native crypto payment
      if (address(paymentToken) == address(0)) {
        require (msg.value >= _amount, "Not enough funds");

        // Process refund
        uint diff = msg.value - _amount;
        if (diff > 0) {
          payable(msg.sender).transfer(diff);
        }
      }

      // Token payments
      else {
        IERC20(_buyerToken).transferFrom(msg.sender, address(this), _amount);
      }
    }

    // case 2: buyer token != payment token and payment token is WMATIC / MATIC
    else if (_buyerToken != address(paymentToken) && (address(paymentToken) == wmatic || address(paymentToken) == address(0))) {
      swapSingle(address(this), _buyerToken, wmatic, _buyerTokenAmount, _amount, 3000);

      // unwrap matic
      if (address(paymentToken) == address(0)) {
        IWETH(wmatic).withdraw(_amount);
        payable(address(this)).transfer(_amount);
      }
    }

    // case 3: buyer token != payment token and payment token is not WMATIC / MATIC
    else {
      swap(address(this), _buyerToken, address(paymentToken), _buyerTokenAmount, _amount, 3000, 3000);
    }
  } 

  /**
   * @notice Process outgoing payment 
   * @param _to Address that will receive the payment
   * @param _amount Amount to transfer
   */
  function processPaymentTo(address _to, uint _amount) internal {
    // Native crypto payment
    if (address(paymentToken) == address(0)) {
      payable(msg.sender).transfer(_amount);
    }

    // Token payments
    else {
      paymentToken.transfer(_to, _amount);
    }
  } 

  /**
   * @notice Returns the balance of the contract
   */
  function getBalance() internal view returns (uint) {
    uint balance;

    // Native crypto
    if (address(paymentToken) == address(0)) {
      balance = address(this).balance;
    }

    // Token
    else {
      balance = paymentToken.balanceOf(address(this));
    }
    return balance;
  }

  /////////////////////////////////////////////////////////////////////////////
  // INTERNAL FUNCTIONS
  function swap(address _recipient, address _tokenIn, address _tokenOut, uint _maxAmountIn, uint _amountOut, uint24 _poolFeeIn, uint24 _poolFeeOut) internal {
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _maxAmountIn);
    IERC20(_tokenIn).approve(address(router), _maxAmountIn);

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
        path: abi.encodePacked(
            _tokenIn,
            _poolFeeIn,
            wmatic,
            _poolFeeOut,
            _tokenOut
        ),
        deadline: block.timestamp,
        recipient: _recipient,
        amountIn: _maxAmountIn,
        amountOutMinimum: _amountOut
    });

    router.exactInput(params);
  }

  function swapSingle(address _recipient, address _tokenIn, address _tokenOut, uint _maxAmountIn, uint _amountOut, uint24 _poolFee) internal {
    IERC20(_tokenIn).transferFrom(msg.sender, address(this), _maxAmountIn);
    IERC20(_tokenIn).approve(address(router), _maxAmountIn);

    ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: _recipient,
            deadline: block.timestamp,
            amountIn: _maxAmountIn,
            amountOutMinimum: _amountOut,
            sqrtPriceLimitX96: 0
        });

    router.exactInputSingle(params);
  }

  // fallback
  fallback() external payable {}
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IOnboardingFactory.sol";
import "./Onboarding.sol";

contract OnboardingFactory is Ownable, IOnboardingFactory {

  /////////////////////////////////////////////////////////////////////////////
  // MODIFIERS  
  modifier onlyDAO () {
    require (msg.sender == dao, "Not allowed");
    _;
  }

  /////////////////////////////////////////////////////////////////////////////
  // VARIABLES
  address public immutable override wmatic;

  uint public totalOnboardings;
  address public collectoNFT;
  address public treasury;
  address public dao;

  address[] public onboardings;

  mapping (address => bool) public override isOnboardingValid;

  /////////////////////////////////////////////////////////////////////////////
  // CONSTRUCTOR

  /**
   * @notice Constructor
   * @param _collectoNFT Address of the Collecto NFT
   * @param _treasury Treasury address
   */
  constructor (
    address _collectoNFT,
    address _treasury,
    address _wmatic
  ) { 
    collectoNFT = _collectoNFT;
    treasury = _treasury;
    wmatic = _wmatic;
  }

  /////////////////////////////////////////////////////////////////////////////
  // PUBLIC FUNCTIONS

  /**
   * @notice Return all onboardings
   */
  function getOnboardings() external view returns (address[] memory) {
    return onboardings;
  }

  /////////////////////////////////////////////////////////////////////////////
  // PRIVILEGED FUNCTIONS
  
  /**
   * @notice Create new onboarding
   * @param _uri Uri of the asset
   * @param _maxShares Maximum number of tokens
   * @param _preSaleStart Start timestamp of the presale
   * @param _preSaleEnd End timestamp of the presale
   * @param _minimumTarget Minimum number of payment tokens in order to
              consider the pre sale successful
   * @param _sharePrice Price of a single share (with decimals)
   * @param _paymentToken Address of the selected payment token (with decimals).
              For native payments use address(0)
   * @dev Can only be called by the DAO
   */
  function createOnboarding(
    string memory _uri,
    uint _maxShares,
    uint _preSaleStart,
    uint _preSaleEnd,
    uint _minimumTarget,
    uint _sharePrice,
    address _paymentToken
  ) external onlyOwner {
    // Deploy new onboarding
    Onboarding newOboarding = new Onboarding(
      collectoNFT, _uri, _maxShares, _preSaleStart, _preSaleEnd, 
      _minimumTarget, _sharePrice, _paymentToken, treasury);

    totalOnboardings += 1;
    onboardings.push(address(newOboarding));
    isOnboardingValid[address(newOboarding)] = true;

    newOboarding.transferOwnership(owner());
  }
}