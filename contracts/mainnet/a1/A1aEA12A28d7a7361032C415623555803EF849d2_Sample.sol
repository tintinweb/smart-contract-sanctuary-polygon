// SPDX-License-Identifier: PROPRIETARY - Lameni

pragma solidity 0.8.16;

import "./ERC20.sol";
import "./IPancake.sol";
import "./GasHelper.sol";
import "./SwapHelper.sol";

contract Sample is GasHelper, ERC20 {
  string public constant URL = "https://www.SAMPLE.com";

  address constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address constant ZERO = 0x0000000000000000000000000000000000000000;
  // address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; // ? PROD
  // address constant WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd; // ? TESTNET
  address constant WBNB = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // ? POLYGON
  

  // address constant PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // ? PROD
  // address constant PANCAKE_ROUTER = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // ? TESTNET
  address constant PANCAKE_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // ? POLYGON

  string constant NAME = "SAMPLE";
  string constant SYMBOL = "SAMPLE";

  uint constant MAX_SUPPLY = 300_000_000e18;

  // Wallets limits
  uint public maxTxAmount = MAX_SUPPLY;
  uint public maxAccountAmount = MAX_SUPPLY;
  uint public minAmountToAutoSwap = 1000 * (10**decimals()); // 100

  // Fees
  uint public feePool = 400;
  uint public feeBurnRate = 200;
  uint public feeAdministrationWallet = 200;
  uint public feeMarketingWallet = 200;

  uint constant MAX_TOTAL_FEE = 1000;

  mapping(address => uint) public specialFeesByWalletSender;
  mapping(address => uint) public specialFeesByWalletReceiver;

  // Helpers
  bool private _noReentrance;

  bool public disablePoolFeeSwap;
  bool public disableAdminFeeSwap;
  bool public disableMarketingFeeSwap;
  bool public disabledAutoLiquidity;

  // Counters
  uint public accumulatedToAdmin;
  uint public accumulatedToMarketing;
  uint public accumulatedToPool;

  // Liquidity Pair
  address public liquidityPool;

  // Wallets
  address public administrationWallet;
  address public marketingWallet;

  address public swapHelperAddress;

  receive() external payable {}

  constructor() ERC20(NAME, SYMBOL) {
    PancakeRouter router = PancakeRouter(PANCAKE_ROUTER);
    liquidityPool = address(PancakeFactory(router.factory()).createPair(WBNB, address(this)));

    uint baseAttributes = 0;
    baseAttributes = _setExemptAmountLimit(baseAttributes, true);
    _attributeMap[liquidityPool] = baseAttributes;

    baseAttributes = _setExemptTxLimit(baseAttributes, true);
    _attributeMap[DEAD] = baseAttributes;
    _attributeMap[ZERO] = baseAttributes;

    baseAttributes = _setExemptFeeSender(baseAttributes, true);
    _attributeMap[address(this)] = baseAttributes;

    baseAttributes = _setExemptSwapperMaker(baseAttributes, true);
    baseAttributes = _setExemptFeeReceiver(baseAttributes, true);

    _attributeMap[_msgSender()] = baseAttributes;

    SwapHelper swapHelper = new SwapHelper();
    swapHelper.safeApprove(WBNB, address(this), type(uint).max);
    swapHelper.transferOwnership(_msgSender());
    swapHelperAddress = address(swapHelper);

    _attributeMap[swapHelperAddress] = baseAttributes;

    _mint(_msgSender(), MAX_SUPPLY);
  }

  // ----------------- Public Views -----------------

  function getFeeTotal() public view returns (uint) {
    return feePool + feeBurnRate + feeAdministrationWallet + feeMarketingWallet;
  }

  function getSpecialWalletFee(address target, bool isSender)
    public
    view
    returns (
      uint pool,
      uint burnRate,
      uint adminFee,
      uint marketingFee
    )
  {
    uint composedValue = isSender ? specialFeesByWalletSender[target] : specialFeesByWalletReceiver[target];
    pool = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    burnRate = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    adminFee = composedValue % 1e4;
    composedValue = composedValue / 1e4;
    marketingFee = composedValue % 1e4;
  }

  // ----------------- Authorized Methods -----------------

  function setLiquidityPool(address newPair) external onlyOwner {
    require(newPair != ZERO, "Invalid address");
    liquidityPool = newPair;
  }

  function setSwapPoolFeeDisabled(bool state) external onlyOwner {
    disablePoolFeeSwap = state;
  }

  function setSwapAdminFeeDisabled(bool state) external onlyOwner {
    disableAdminFeeSwap = state;
  }

  function setSwapMarketingFeeDisabled(bool state) external onlyOwner {
    disableMarketingFeeSwap = state;
  }

  function setDisabledAutoLiquidity(bool state) external onlyOwner {
    disabledAutoLiquidity = state;
  }

  // ----------------- Wallets Settings -----------------
  function setAdministrationWallet(address account) public onlyOwner {
    require(account != ZERO, "Invalid address");
    administrationWallet = account;
  }

  function setMarketingWallet(address account) public onlyOwner {
    require(account != ZERO, "Invalid address");
    marketingWallet = account;
  }

  // ----------------- Fee Settings -----------------
  function setFees(
    uint pool,
    uint burnRate,
    uint administration,
    uint feeMarketing
  ) external onlyOwner {
    feePool = pool;
    feeBurnRate = burnRate;
    feeAdministrationWallet = administration;
    feeMarketingWallet = feeMarketing;
    require(getFeeTotal() <= MAX_TOTAL_FEE, "All fee together must be lower than 10%");
  }

  function setSpecialWalletFeeOnSend(
    address target,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public onlyOwner {
    _setSpecialWalletFee(target, true, pool, burnRate, adminFee, marketingFee);
  }

  function setSpecialWalletFeeOnReceive(
    address target,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) public onlyOwner {
    _setSpecialWalletFee(target, false, pool, burnRate, adminFee, marketingFee);
  }

  function _setSpecialWalletFee(
    address target,
    bool isSender,
    uint pool,
    uint burnRate,
    uint adminFee,
    uint marketingFee
  ) private {
    uint total = pool + burnRate + adminFee + marketingFee;
    require(total <= MAX_TOTAL_FEE, "All rates and fee together must be lower than 10%");
    uint composedValue = (pool) + (burnRate * 1e4) + (adminFee * 1e8) + (marketingFee * 1e12);
    if (isSender) {
      specialFeesByWalletSender[target] = composedValue;
    } else {
      specialFeesByWalletReceiver[target] = composedValue;
    }
  }

  // ----------------- Token Flow Settings -----------------
  function setMaxTxAmount(uint maxTxAmount_) public onlyOwner {
    require(maxTxAmount_ >= MAX_SUPPLY / 100_000, "Amount must be bigger then 0.001% tokens");
    maxTxAmount = maxTxAmount_;
  }

  function setMaxAccountAmount(uint maxAccountAmount_) public onlyOwner {
    require(maxAccountAmount_ >= MAX_SUPPLY / 100_000, "Amount must be bigger then 0.001% tokens");
    maxAccountAmount = maxAccountAmount_;
  }

  function setMinAmountToAutoSwap(uint amount) public onlyOwner {
    minAmountToAutoSwap = amount;
  }

  struct Receivers {
    address wallet;
    uint amount;
  }

  function multiTransfer(address[] calldata wallets, uint[] calldata amount) external {
    uint length = wallets.length;
    require(amount.length == length, "Invalid size os lists");
    for (uint i = 0; i < length; i++) transfer(wallets[i], amount[i]);
  }

  // ----------------- External Methods -----------------
  function burn(uint amount) external {
    _burn(_msgSender(), amount);
  }

  // ----------------- Internal CORE -----------------
  function _transfer(
    address sender,
    address receiver,
    uint amount
  ) internal override {
    require(amount > 0, "Invalid Amount");
    require(!_noReentrance, "ReentranceGuard Alert");
    _noReentrance = true;

    uint senderAttributes = _attributeMap[sender];
    uint receiverAttributes = _attributeMap[receiver];

    // Initial Checks
    require(sender != ZERO && receiver != ZERO, "transfer from / to the zero address");
    require(amount <= maxTxAmount || _isExemptTxLimit(senderAttributes), "Exceeded the maximum transaction limit");

    uint senderBalance = _balances[sender];
    require(senderBalance >= amount, "Transfer amount exceeds your balance");
    senderBalance -= amount;
    _balances[sender] = senderBalance;

    uint adminFee;
    uint poolFee;
    uint burnFee;
    uint marketingFee;
    uint feeAmount;

    // Calculate Fees
    if (!_isExemptFeeSender(senderAttributes) && !_isExemptFeeReceiver(receiverAttributes)) {
      if (_isSpecialFeeWalletSender(senderAttributes)) {
        (poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(sender, true); // Check special wallet fee on sender
      } else if (_isSpecialFeeWalletReceiver(receiverAttributes)) {
        (poolFee, burnFee, adminFee, marketingFee) = getSpecialWalletFee(receiver, false); // Check special wallet fee on receiver
      } else {
        adminFee = feeAdministrationWallet;
        poolFee = feePool;
        burnFee = feeBurnRate;
        marketingFee = feeMarketingWallet;
      }
      feeAmount = ((poolFee + burnFee + adminFee + marketingFee) * amount) / 10_000;
    }

    if (feeAmount != 0) _splitFee(feeAmount, sender, adminFee, poolFee, burnFee, marketingFee);
    if ((!disablePoolFeeSwap || !disableAdminFeeSwap || !disableMarketingFeeSwap) && !_isExemptSwapperMaker(senderAttributes)) _autoSwap(sender);

    // Update Recipient Balance
    uint newRecipientBalance = _balances[receiver] + (amount - feeAmount);
    _balances[receiver] = newRecipientBalance;
    require(newRecipientBalance <= maxAccountAmount || _isExemptAmountLimit(receiverAttributes), "Exceeded the maximum tokens an wallet can hold");

    _noReentrance = false;
    emit Transfer(sender, receiver, amount - feeAmount);
  }

  function _operateSwap(
    address liquidityPair,
    address swapHelper,
    uint amountIn
  ) private returns (uint) {
    (uint112 reserve0, uint112 reserve1) = _getTokenReserves(liquidityPair);
    bool reversed = _isReversed(liquidityPair, WBNB);

    if (reversed) {
      uint112 temp = reserve0;
      reserve0 = reserve1;
      reserve1 = temp;
    }

    _balances[liquidityPair] += amountIn;
    uint wbnbAmount = _getAmountOut(amountIn, reserve1, reserve0);
    if (!reversed) {
      _swapToken(liquidityPair, wbnbAmount, 0, swapHelper);
    } else {
      _swapToken(liquidityPair, 0, wbnbAmount, swapHelper);
    }
    return wbnbAmount;
  }

  function _autoSwap(address sender) private {
    // --------------------- Execute Auto Swap -------------------------
    address liquidityPair = liquidityPool;
    address swapHelper = swapHelperAddress;

    if (sender == liquidityPair) return;

    uint poolAmount = disabledAutoLiquidity ? accumulatedToPool : (accumulatedToPool / 2);
    uint adminAmount = accumulatedToAdmin;
    uint marketingAmount = accumulatedToMarketing;
    uint totalAmount = poolAmount + adminAmount + marketingAmount;

    if (totalAmount < minAmountToAutoSwap) return;

    // Execute auto swap
    uint amountOut = _operateSwap(liquidityPair, swapHelper, totalAmount);

    // --------------------- Add Liquidity -------------------------
    if (poolAmount > 0) {
      if (!disabledAutoLiquidity) {
        uint amountToSend = (amountOut * poolAmount) / (totalAmount);
        (uint112 reserve0, uint112 reserve1) = _getTokenReserves(liquidityPair);
        bool reversed = _isReversed(liquidityPair, WBNB);
        if (reversed) {
          uint112 temp = reserve0;
          reserve0 = reserve1;
          reserve1 = temp;
        }

        uint amountA;
        uint amountB;
        {
          uint amountBOptimal = (amountToSend * reserve1) / reserve0;
          if (amountBOptimal <= poolAmount) {
            (amountA, amountB) = (amountToSend, amountBOptimal);
          } else {
            uint amountAOptimal = (poolAmount * reserve0) / reserve1;
            assert(amountAOptimal <= amountToSend);
            (amountA, amountB) = (amountAOptimal, poolAmount);
          }
        }
        _tokenTransferFrom(WBNB, swapHelper, liquidityPair, amountA);
        _balances[liquidityPair] += amountB;
        IPancakePair(liquidityPair).mint(address(this));
      } else {
        uint amountToSend = (amountOut * poolAmount) / (totalAmount);
        _tokenTransferFrom(WBNB, swapHelper, address(this), amountToSend);
      }
    }

    // --------------------- Transfer Swapped Amount -------------------------
    if (adminAmount > 0) {
      uint amountToSend = (amountOut * adminAmount) / (totalAmount);
      _tokenTransferFrom(WBNB, swapHelper, administrationWallet, amountToSend);
    }
    if (marketingAmount > 0) {
      uint amountToSend = (amountOut * marketingAmount) / (totalAmount);
      _tokenTransferFrom(WBNB, swapHelper, marketingWallet, amountToSend);
    }

    accumulatedToPool = 0;
    accumulatedToAdmin = 0;
    accumulatedToMarketing = 0;
  }

  function _splitFee(
    uint incomingFeeAmount,
    address sender,
    uint adminFee,
    uint poolFee,
    uint burnFee,
    uint marketingFee
  ) private {
    uint totalFee = adminFee + poolFee + burnFee + marketingFee;

    //Burn
    if (burnFee > 0) {
      uint burnAmount = (incomingFeeAmount * burnFee) / totalFee;
      _balances[address(this)] += burnAmount;
      _burn(address(this), burnAmount);
    }

    // Administrative distribution
    if (adminFee > 0) {
      accumulatedToAdmin += (incomingFeeAmount * adminFee) / totalFee;
      if (disableAdminFeeSwap) {
        address wallet = administrationWallet;
        _balances[wallet] += accumulatedToAdmin;
        emit Transfer(sender, wallet, accumulatedToAdmin);
        accumulatedToAdmin = 0;
      }
    }

    // Marketing distribution
    if (marketingFee > 0) {
      accumulatedToMarketing += (incomingFeeAmount * marketingFee) / totalFee;
      if (disableMarketingFeeSwap) {
        address wallet = marketingWallet;
        _balances[wallet] += accumulatedToMarketing;
        emit Transfer(sender, wallet, accumulatedToMarketing);
        accumulatedToMarketing = 0;
      }
    }

    // Pool Distribution
    if (poolFee > 0) {
      accumulatedToPool += (incomingFeeAmount * poolFee) / totalFee;
      if (disablePoolFeeSwap) {
        _balances[address(this)] += accumulatedToPool;
        emit Transfer(sender, address(this), accumulatedToPool);
        accumulatedToPool = 0;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)
// Modified version to provide _balances as internal instead private

pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
    mapping(address => uint256) internal _balances;

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

pragma solidity 0.8.16;

interface PancakeFactory {
  function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface PancakeRouter {
  function factory() external pure returns (address);
}

interface IPancakePair {
  function mint(address to) external returns (uint liquidity);
}

// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "./AttributeMap.sol";

contract GasHelper is AttributeMap {
  // uint internal swapFee = 25; // BSC (PANCAKE)
  uint internal swapFee = 30; // POLYGON (SUSHI)

  function setSwapFee(uint amount) external onlyOwner {
    swapFee = amount;
  }

  function _getAmountOut(
    uint amountIn,
    uint reserveIn,
    uint reserveOut
  ) internal view returns (uint amountOut) {
    require(amountIn > 0, "Insufficient amount in");
    require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");
    uint amountInWithFee = amountIn * (10000 - swapFee);
    uint numerator = amountInWithFee * reserveOut;
    uint denominator = (reserveIn * 10000) + amountInWithFee;
    amountOut = numerator / denominator;
  }

  function _isReversed(address pair, address tokenA) internal view returns (bool) {
    address token0;
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x0dfe168100000000000000000000000000000000000000000000000000000000)
      failed := iszero(staticcall(gas(), pair, emptyPointer, 0x04, emptyPointer, 0x20))
      token0 := mload(emptyPointer)
    }
    if (failed) revert("Unable to check tokens direction");
    return token0 != tokenA;
  }

  // gas optimization on transfer from token method
  function _tokenTransferFrom(
    address token,
    address from,
    address recipient,
    uint amount
  ) internal {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), from)
      mstore(add(emptyPointer, 0x24), recipient)
      mstore(add(emptyPointer, 0x44), amount)
      failed := iszero(call(gas(), token, 0, emptyPointer, 0x64, 0, 0))
    }
    if (failed) revert("Unable to transferFrom token");
  }

  // gas optimization on swap operation using a liquidity pool
  function _swapToken(
    address pair,
    uint amount0Out,
    uint amount1Out,
    address receiver
  ) internal {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x022c0d9f00000000000000000000000000000000000000000000000000000000)
      mstore(add(emptyPointer, 0x04), amount0Out)
      mstore(add(emptyPointer, 0x24), amount1Out)
      mstore(add(emptyPointer, 0x44), receiver)
      mstore(add(emptyPointer, 0x64), 0x80)
      mstore(add(emptyPointer, 0x84), 0)
      failed := iszero(call(gas(), pair, 0, emptyPointer, 0xa4, 0, 0))
    }
    if (failed) revert("Unable to swap Pair");
  }

  // gas optimization on get reserves from liquidity pool
  function _getTokenReserves(address pairAddress) internal view returns (uint112 reserve0, uint112 reserve1) {
    bool failed = false;
    assembly {
      let emptyPointer := mload(0x40)
      mstore(emptyPointer, 0x0902f1ac00000000000000000000000000000000000000000000000000000000)
      failed := iszero(staticcall(gas(), pairAddress, emptyPointer, 0x4, emptyPointer, 0x40))
      reserve0 := mload(emptyPointer)
      reserve1 := mload(add(emptyPointer, 0x20))
    }
    if (failed) revert("Unable to get reserves from pair");
  }
}

// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SwapHelper is Ownable {
  constructor() {}

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external onlyOwner {
    IERC20(token).approve(spender, amount);
  }

  function safeWithdraw() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
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

// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "./Authorized.sol";

contract AttributeMap is Authorized {
  mapping(address => uint) internal _attributeMap;

  // ------------- Public Views -------------
  function isExemptFeeSender(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 0);
  }

  function isExemptFeeReceiver(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 1);
  }

  function isExemptTxLimit(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 2);
  }

  function isExemptAmountLimit(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 3);
  }

  function isExemptSwapperMaker(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 4);
  }

  function isSpecialFeeWalletSender(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 5);
  }

  function isSpecialFeeWalletReceiver(address target) external view returns (bool) {
    return _checkMapAttribute(_attributeMap[target], 6);
  }

  // ------------- Internal PURE GET Functions -------------
  function _checkMapAttribute(uint mapValue, uint8 shift) internal pure returns (bool) {
    return (mapValue >> shift) & 1 == 1;
  }

  function _isExemptFeeSender(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 0);
  }

  function _isExemptFeeReceiver(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 1);
  }

  function _isExemptTxLimit(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 2);
  }

  function _isExemptAmountLimit(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 3);
  }

  function _isExemptSwapperMaker(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 4);
  }

  function _isSpecialFeeWalletSender(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 5);
  }

  function _isSpecialFeeWalletReceiver(uint mapValue) internal pure returns (bool) {
    return _checkMapAttribute(mapValue, 6);
  }

  // ------------- Internal PURE SET Functions -------------
  function _setMapAttribute(
    uint mapValue,
    uint8 shift,
    bool include
  ) internal pure returns (uint) {
    return include ? _applyMapAttribute(mapValue, shift) : _removeMapAttribute(mapValue, shift);
  }

  function _applyMapAttribute(uint mapValue, uint8 shift) internal pure returns (uint) {
    return (1 << shift) | mapValue;
  }

  function _removeMapAttribute(uint mapValue, uint8 shift) internal pure returns (uint) {
    return (1 << shift) ^ (type(uint).max & mapValue);
  }

  // ------------- Public Internal SET Functions -------------
  function _setExemptFeeSender(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 0, operation);
  }

  function _setExemptFeeReceiver(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 1, operation);
  }

  function _setExemptTxLimit(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 2, operation);
  }

  function _setExemptAmountLimit(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 3, operation);
  }

  function _setExemptSwapperMaker(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 4, operation);
  }

  function _setSpecialFeeWallet(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 5, operation);
  }

  function _setSpecialFeeWalletReceiver(uint mapValue, bool operation) internal pure returns (uint) {
    return _setMapAttribute(mapValue, 6, operation);
  }

  // ------------- Public Authorized SET Functions -------------
  function setExemptFeeSender(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptFeeSender(_attributeMap[target], operation);
  }

  function setExemptFeeReceiver(address target, bool operation) public {
    _attributeMap[target] = _setExemptFeeReceiver(_attributeMap[target], operation);
  }

  function setExemptTxLimit(address target, bool operation) public {
    _attributeMap[target] = _setExemptTxLimit(_attributeMap[target], operation);
  }

  function setExemptAmountLimit(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptAmountLimit(_attributeMap[target], operation);
  }

  function setExemptSwapperMaker(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setExemptSwapperMaker(_attributeMap[target], operation);
  }

  function setSpecialFeeWallet(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setSpecialFeeWallet(_attributeMap[target], operation);
  }

  function setSpecialFeeWalletReceiver(address target, bool operation) public onlyOwner {
    _attributeMap[target] = _setSpecialFeeWalletReceiver(_attributeMap[target], operation);
  }
}

// SPDX-License-Identifier: PROPRIETARY

pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Authorized is Ownable {
  constructor() {}

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external onlyOwner {
    IERC20(token).approve(spender, amount);
  }

  function safeTransfer(
    address token,
    address receiver,
    uint amount
  ) external onlyOwner {
    IERC20(token).transfer(receiver, amount);
  }

  function safeWithdraw() external onlyOwner {
    payable(_msgSender()).transfer(address(this).balance);
  }
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