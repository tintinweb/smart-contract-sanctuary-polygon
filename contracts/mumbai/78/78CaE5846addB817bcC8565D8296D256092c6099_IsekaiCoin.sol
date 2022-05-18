// SPDX-License-Identifier: MIT

/**
 * All fees are adjustable by the contract owner but can not be
 * over 5% for each fee type (max 20%)
 *
 * The Fees only apply on buys and sells, not on normal transfers.
 * On normal transfers, there are 0% fees
 *
 * Tokenomics:
 *
 * Liquidity        4%
 * Reward           3%
 * Marketing        1%
 * Anime            2%
 */

pragma solidity ^0.8.0;

import "./IsekaiCoinImports.sol";

// import "hardhat/console.sol";

abstract contract Tokenomics is Ownable {
    using SafeMath for uint256;

    // --------------------- Token Settings ------------------- //

    //TODO: Update name and symbol
    string internal constant NAME = "IsekaiCoin";
    string internal constant SYMBOL = "ISSEKAI";

    uint16 internal constant FEES_DIVISOR = 10**3;
    uint8 internal constant DECIMALS = 9;
    uint256 internal constant ZEROES = 10**DECIMALS;

    uint256 internal TOTAL_SUPPLY = 10000 * 10**6 * ZEROES;

    /**
     * @dev Set the maximum transaction amount allowed in a transfer. Set to 0.3% of total supply
     *
     * NOTE: set the value to `TOTAL_SUPPLY` to have an unlimited max, i.e.
     * `maxTransactionAmount = TOTAL_SUPPLY;`
     */
    uint256 internal maxTransactionAmount = (TOTAL_SUPPLY * 3) / 1000; // 0.3% of the total supply

    /**
     * @dev Set the maximum allowed balance in a wallet. Set to 5% of the total supply
     *
     * NOTE: set the value to 0 to have an unlimited max.
     *
     * IMPORTANT: This value MUST be greater than `numberOfTokensToSwapToLiquidity` set below,
     * otherwise the liquidity swap will never be executed
     */
    uint256 internal maxWalletBalance = TOTAL_SUPPLY / 20; // 5% of the total supply

    /**
     * @dev Set the number of tokens to swap and add to liquidity.
     *
     * Whenever the contract's balance reaches this number of tokens, swap & liquify will be
     * executed in the very next transfer (via the `_beforeTokenTransfer`)
     *
     * This value can be altered by the owner through the changeNumberOfTokensToSwapToLiquidity function below
     *
     * If the `FeeType.Liquidity` is enabled in `FeesSettings`, the given % of each transaction will be first
     * sent to the contract address. Once the contract's balance reaches `numberOfTokensToSwapToLiquidity` the
     * `swapAndLiquify` of `Liquifier` will be executed. Half of the tokens will be swapped for ETH
     * (or BNB on BSC) and together with the other half converted into a Token-ETH/Token-BNB LP Token.
     *
     * See: `Liquifier`
     */
    uint256 internal numberOfTokensToSwapToLiquidity = TOTAL_SUPPLY / 1000; // 0.1% of the total supply

    // --------------------- Fees Settings ------------------- //

    /**
     * @dev To add/edit/remove fees scroll down to the `addFees` function below
     */

    address internal rewardAddress = 0x4bE569348cd829C5816b1622144349D1b3868512;
    address internal marketingAddress =
        0xb9856A4128d762E008948E393DADA7c0C80f546f;
    address internal animeAddress = 0x868Bc583305405130Cb8B1692DAa3bA0e3Be5CDb;

    enum FeeType {
        Liquidity,
        External
    }
    struct Fee {
        FeeType name;
        uint256 value;
        address recipient;
        uint256 total;
    }

    Fee[] internal fees;
    uint256 internal sumOfFees;

    constructor() {
        _addFees();
    }

    function _addFee(
        FeeType name,
        uint256 value,
        address recipient
    ) private {
        fees.push(Fee(name, value, recipient, 0));
        sumOfFees += value;
    }

    function _addFees() private {
        /**
         * The value of fees is given in part per 1000 (based on the value of FEES_DIVISOR),
         * e.g. for 5% use 50, for 3.5% use 35, etc.
         */
        _addFee(FeeType.Liquidity, 40, address(this));
        _addFee(FeeType.External, 30, rewardAddress);
        _addFee(FeeType.External, 10, marketingAddress);
        _addFee(FeeType.External, 20, animeAddress);
    }

    /**
     * @dev This function can be used to change maxTxAmount and value should be percentage * 10
     * @param maxTxPercent The new max transaction percentage
     */
    function setMaxTransactionPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent <= 1000, "Invalid percent");
        maxTransactionAmount = (TOTAL_SUPPLY * maxTxPercent) / 1000;
    }

    /**
     * @dev This function can be used to change Max Wallet balance and value should be percentage * 10
     * @param maxWalletPercent The new max wallet percentage
     */
    function setMaxWalletBalance(uint256 maxWalletPercent) external onlyOwner {
        require(maxWalletPercent <= 1000, "Invalid percent");
        maxWalletBalance = (TOTAL_SUPPLY * maxWalletPercent) / 1000;
    }

    /**
     * @dev The contract can not add new fees, but it can change the values for existing ones
     *
     * Each fee can not go over 5%. The max fee this contract can have is 20%
     */
    function changeLiquidityFee(uint256 value) external onlyOwner {
        require(value <= 50, "Fee can't be over 5%");
        uint256 sumWithoutLiquidity = sumOfFees - fees[0].value;
        fees[0].value = value;
        sumOfFees = sumWithoutLiquidity + value;
    }

    function changeRewardWalletFee(uint256 value) external onlyOwner {
        require(value <= 50, "Fee can't be over 5%");
        uint256 sumWithoutReward = sumOfFees - fees[1].value;
        fees[1].value = value;
        sumOfFees = sumWithoutReward + value;
    }

    function changeRewardWalletAddress(address account) external onlyOwner {
        fees[1].recipient = account;
    }

    function changeMarketingFee(uint256 value) external onlyOwner {
        require(value <= 50, "Fee can't be over 5%");
        uint256 sumWithoutMarketing = sumOfFees - fees[2].value;
        fees[2].value = value;
        sumOfFees = sumWithoutMarketing + value;
    }

    function changeMarketingAddress(address account) external onlyOwner {
        fees[2].recipient = account;
    }

    function changeAnimeFee(uint256 value) external onlyOwner {
        require(value <= 50, "Fee can't be over 5%");
        uint256 sumWithoutAnime = sumOfFees - fees[3].value;
        fees[3].value = value;
        sumOfFees = sumWithoutAnime + value;
    }

    function changeAnimeAddress(address account) external onlyOwner {
        fees[3].recipient = account;
    }

    function _getFeesCount() internal view returns (uint256) {
        return fees.length;
    }

    function _getFeeStruct(uint256 index) private view returns (Fee storage) {
        require(
            index >= 0 && index < fees.length,
            "FeesSettings._getFeeStruct: Fee index out of bounds"
        );
        return fees[index];
    }

    function getFee(uint256 index)
        public
        view
        returns (
            FeeType,
            uint256,
            address,
            uint256
        )
    {
        Fee memory fee = _getFeeStruct(index);
        return (fee.name, fee.value, fee.recipient, fee.total);
    }

    function _addFeeCollectedAmount(uint256 index, uint256 amount) internal {
        Fee storage fee = _getFeeStruct(index);
        fee.total = fee.total.add(amount);
    }

    function getCollectedFeeTotal(uint256 index)
        external
        view
        returns (uint256)
    {
        Fee memory fee = _getFeeStruct(index);
        return fee.total;
    }
}

abstract contract AntiSnipe is Ownable {
    uint256 internal deadBlocks = 5;
    uint256 internal launchedAt = 0;
    bool internal isInPresale;

    function launched() public view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        if (launchedAt == 0) {
            launchedAt = block.number;
        }
    }

    function setDeadBlocks(uint256 _deadBlocks) public onlyOwner {
        require(_deadBlocks > 0 && _deadBlocks < 11);
        deadBlocks = _deadBlocks;
    }

    function setPresaleEnabled(bool value) external onlyOwner {
        if (!isInPresale) {
            require(!launched(), "Contract has already been launched");
        }
        isInPresale = value;
    }
}

abstract contract Blacklist is Ownable {
    mapping(address => bool) public isBlacklisted;

    function blacklistAddress(address _blacklistAddress, bool _blacklist)
        external
        onlyOwner
    {
        isBlacklisted[_blacklistAddress] = _blacklist;
    }
}

abstract contract ERC20 is
    IERC20,
    IERC20Metadata,
    Tokenomics,
    AntiSnipe,
    Blacklist
{
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    mapping(address => bool) internal _isExcludedFromMaxBalance;
    mapping(address => bool) internal _isExcludedFromFee;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        _balances[owner()] = TOTAL_SUPPLY;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude staking wallet and dev wallet from max balance
        _isExcludedFromMaxBalance[
            0x06AC76657Bd3157F47a9e839AaA648B5C34A7D0A
        ] = true; // staking wallet
        _isExcludedFromMaxBalance[
            0x0FeBc88E7C4b8F231F071770e2b1D8b64b70f47B
        ] = true; // dev wallet

        emit Transfer(address(0), owner(), TOTAL_SUPPLY);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return NAME;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return SYMBOL;
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
        return DECIMALS;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(
            currentAllowance >= amount,
            "ERC20: burn amount exceeds allowance"
        );
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }

    function setExcludedFromFee(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = value;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludeFromMaxBalance(address account, bool value)
        external
        onlyOwner
    {
        _isExcludedFromMaxBalance[account] = value;
    }

    function isExcludedFromMaxBalance(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromMaxBalance[account];
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            launched() || _isExcludedFromFee[sender] || isInPresale,
            "Pre-Launch Protection"
        );
        require(
            !isBlacklisted[recipient] && !isBlacklisted[sender],
            "Blacklisted address involved"
        );

        // indicates wether anti snipe has been triggered
        bool antiSnipeTriggered = false;

        // indicates whether or not feee should be deducted from the transfer
        bool takeFee = true;

        if (launched() && (launchedAt + deadBlocks) > block.number) {
            antiSnipeTriggered = true;
        }

        if (isInPresale) {
            takeFee = false;
        } else {
            /**
             * Check the amount is within the max allowed limit as long as a
             * unlimited sender/recepient is not involved in the transaction
             */
            if (
                amount > maxTransactionAmount &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient)
            ) {
                revert("Transfer amount exceeds the maxTxAmount.");
            }
            /**
             * The pair needs to excluded from the max wallet balance check;
             * selling tokens is sending them back to the pair (without this
             * check, selling tokens would not work if the pair's balance
             * was over the allowed max)
             *
             * Note: This does NOT take into account the fees which will be deducted
             *       from the amount. As such it could be a bit confusing
             */
            if (
                maxWalletBalance > 0 &&
                !_isUnlimitedSender(sender) &&
                !_isUnlimitedRecipient(recipient) &&
                !_isV2Pair(recipient) &&
                !isExcludedFromMaxBalance(recipient)
            ) {
                uint256 recipientBalance = balanceOf(recipient);
                require(
                    recipientBalance + amount <= maxWalletBalance,
                    "New balance would exceed the maxWalletBalance"
                );
            }
        }

        // launch if liquidity is being added
        if (!launched() && _isV2Pair(recipient)) {
            require(!isInPresale, "Pre-sale still enabled");
            require(balanceOf(sender) > 0, "Balance too low");
            launch();
        }

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        bool isBuyOrSell = _isV2Pair(recipient) || _isV2Pair(sender);

        _beforeTokenTransfer(sender, recipient, amount);
        _transferTokens(
            sender,
            recipient,
            amount,
            takeFee,
            antiSnipeTriggered,
            isBuyOrSell
        );
    }

    function _transferTokens(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee,
        bool antiSnipeTriggered,
        bool isBuyOrSell
    ) private {
        /**
         * We don't need to know anything about the individual fees here
         *  All that is required for the transfer is the sum of all fees to
         * calculate the % of the total transaction amount which should be
         * transferred to the recipient.
         *
         * If anti-snipe has been triggered, fees will be 99% (to liquidity)
         *
         * The `_takeFees` call will/should take care of the individual fees
         */
        uint256 _sumOfFees = antiSnipeTriggered
            ? 990
            : getSumOfFees(sender, isBuyOrSell, amount);

        if (!takeFee) {
            _sumOfFees = 0;
        }

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        uint256 feeAmount = (amount * _sumOfFees) / FEES_DIVISOR;
        uint256 recipientAmount = amount - feeAmount;

        _balances[recipient] += recipientAmount;

        _takeFees(sender, amount, _sumOfFees, antiSnipeTriggered, isBuyOrSell);
        emit Transfer(sender, recipient, recipientAmount);
    }

    function _takeFees(
        address sender,
        uint256 amount,
        uint256 _sumOfFees,
        bool antiSnipeTriggered,
        bool isBuyOrSell
    ) private {
        if (
            _sumOfFees > 0 &&
            !isInPresale &&
            (isBuyOrSell || antiSnipeTriggered)
        ) {
            _takeTransactionFees(sender, amount, antiSnipeTriggered);
        }
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
        TOTAL_SUPPLY -= amount;

        emit Transfer(account, address(0), amount);
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

    function _isUnlimitedSender(address account) internal view returns (bool) {
        // the owner should be the only whitelisted sender
        return (account == owner());
    }

    function _isUnlimitedRecipient(address account)
        internal
        view
        returns (bool)
    {
        // the owner should be a white-listed recipient
        // and anyone should be able to burn as many tokens as
        // he/she wants
        return (account == owner());
    }

    /**
     * @dev Returns the total sum of fees to be processed in each transaction.
     *
     * To separate concerns this contract (class) will take care of ONLY handling RFI, i.e.
     * changing the rates and updating the holder's balance (via `_redistribute`).
     * It is the responsibility of the dev/user to handle all other fees and taxes
     * in the appropriate contracts (classes).
     */
    function getSumOfFees(
        address sender,
        bool isBuyOrSell,
        uint256 amount
    ) public view virtual returns (uint256);

    /**
     * @dev A delegate which should return true if the given address is the V2 Pair and false otherwise
     */
    function _isV2Pair(address account) internal view virtual returns (bool);

    /**
     * @dev Hook that is called before the `Transfer` event is emitted if fees are enabled for the transfer
     */
    function _takeTransactionFees(
        address sender,
        uint256 amount,
        bool antiSnipeTriggered
    ) internal virtual;
}

abstract contract Liquifier is IERC20, Ownable {
    enum Env {
        TestnetBsc,
        TestnetRinkeby,
        MainnetBscV2,
        MainnetPolygonV2,
        MainnetEthV2
    }
    Env private _env;

    // Uniswap V2 rinkeby
    address private _testnetRinkebyRouterAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // PancakeSwap V2
    address private _mainnetBscRouterV2Address =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    // Uniswap V2 Ethereum
    address private _mainnetEthereumRouterV2Address =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // Quickswap V2 Polygon
    address private _mainnetPolygonRouterV2Address =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
    // Testnet
    // address private _testnetRouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    // PancakeSwap Testnet = https://pancake.kiemtienonline360.com/
    address private _testnetBscRouterAddress =
        0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    IERC20 private _usdtContract;

    IPancakeV2Router internal _router;
    address internal _pair;

    bool private inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;

    uint256 private maxTransactionAmount;
    uint256 private numberOfTokensToSwapToLiquidity;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event RouterSet(address indexed router);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event LiquidityAdded(
        uint256 tokenAmountSent,
        uint256 ethAmountSent,
        uint256 liquidity
    );

    receive() external payable {}

    function initializeLiquiditySwapper(
        Env env,
        IERC20 usdtContract,
        uint256 maxTx,
        uint256 liquifyAmount
    ) internal {
        _env = env;
        _usdtContract = usdtContract;
        if (_env == Env.TestnetRinkeby) {
            _setRouterAddress(
                _testnetRinkebyRouterAddress,
                address(usdtContract)
            );
        } else if (_env == Env.MainnetBscV2) {
            _setRouterAddress(
                _mainnetBscRouterV2Address,
                address(usdtContract)
            );
        } else if (_env == Env.MainnetPolygonV2) {
            _setRouterAddress(
                _mainnetPolygonRouterV2Address,
                address(usdtContract)
            );
        } else if (_env == Env.MainnetEthV2) {
            _setRouterAddress(
                _mainnetEthereumRouterV2Address,
                address(usdtContract)
            );
        }
        /*(_env == Env.Testnet)*/
        else {
            _setRouterAddress(_testnetBscRouterAddress, address(usdtContract));
        }

        maxTransactionAmount = maxTx;
        numberOfTokensToSwapToLiquidity = liquifyAmount;
    }

    /**
     * NOTE: passing the `contractTokenBalance` here is preferred to creating `balanceOfDelegate`
     */
    function liquify(uint256 contractTokenBalance, address sender) internal {
        if (contractTokenBalance >= maxTransactionAmount)
            contractTokenBalance = maxTransactionAmount;

        bool isOverRequiredTokenBalance = (contractTokenBalance >=
            numberOfTokensToSwapToLiquidity);

        /**
         * - first check if the contract has collected enough tokens to swap and liquify
         * - then check swap and liquify is enabled
         * - then make sure not to get caught in a circular liquidity event
         * - finally, don't swap & liquify if the sender is the uniswap pair
         */
        if (
            isOverRequiredTokenBalance &&
            swapAndLiquifyEnabled &&
            !inSwapAndLiquify &&
            (sender != _pair)
        ) {
            _swapAndLiquify(contractTokenBalance);
        }
    }

    /**
     * @dev sets the router address and created the router, factory pair to enable
     * swapping and liquifying (contract) tokens
     */
    function _setRouterAddress(address router, address usdt) private {
        IPancakeV2Router _newPancakeRouter = IPancakeV2Router(router);
        _pair = IPancakeV2Factory(_newPancakeRouter.factory()).createPair(
            address(this),
            usdt
        );
        _router = _newPancakeRouter;
        emit RouterSet(router);
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = amount / 2;
        uint256 otherHalf = amount - half;

        // capture the contract's current USDT balance.
        // this is so that we can capture exactly the amount of USDT that the
        // swap creates, and not make the liquidity event include any USDT that
        // has been manually sent to the contract
        uint256 initialBalance = _usdtContract.balanceOf(address(this));

        // swap tokens for USDT
        _swapTokensForUsdt(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much USDT did we just swap into?
        uint256 newBalance = _usdtContract.balanceOf(address(this)) -
            initialBalance;

        // add liquidity to pancakeswaps
        _addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    /**
     * @dev We have to swap the ECCHI into USDT, this is not possible directly
     * because the uniswap router does not allow swapping tokens from the token
     * contract itself.
     *
     * To work around this, we first swap the ECCHI into wBNB, and then swap the
     * wBNB into USDT, to add to liquidity
     */
    function _swapTokensForUsdt(uint256 tokenAmount) private {
        // get contract's BNB balance
        uint256 initialBnbBalance = address(this).balance;

        // generate the pancakeswap pair path of ECCHI -> USDT -> wBNB
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = address(_usdtContract);
        path[2] = _router.WETH();

        // generate the pancakeswap pair path of wBNB -> USDT
        address[] memory secondPath = new address[](2);
        secondPath[0] = _router.WETH();
        secondPath[1] = address(_usdtContract);

        _approveDelegate(address(this), address(_router), tokenAmount);

        // make the first swap
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            path,
            address(this),
            block.timestamp
        );

        // how much BNB did we just swap into?
        uint256 newBnbBalance = address(this).balance - initialBnbBalance;

        // make the second swap
        _router.swapExactETHForTokens{value: newBnbBalance}(
            // The minimum amount of output tokens that must be received for the transaction not to revert.
            // 0 = accept any amount (slippage is inevitable)
            0,
            secondPath,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 usdtAmount) private {
        // approve token transfer to cover all possible scenarios
        _approveDelegate(address(this), address(_router), tokenAmount);
        _usdtContract.approve(address(_router), usdtAmount);

        // add the liquidity
        (uint256 tokenAmountSent, uint256 usdtAmountSent, uint256 liquidity) = _router
            .addLiquidity(
                address(this),
                address(_usdtContract),
                tokenAmount,
                usdtAmount,
                // Bounds the extent to which the USDT/token price can go up before the transaction reverts.
                // Must be <= amountTokenDesired; 0 = accept any amount (slippage is inevitable)
                0,
                // Bounds the extent to which the token/USDT price can go up before the transaction reverts.
                // 0 = accept any amount (slippage is inevitable)
                0,
                address(this),
                block.timestamp
            );

        emit LiquidityAdded(tokenAmountSent, usdtAmountSent, liquidity);
    }

    /**
     * @dev Sets the uniswapV2 pair (router & factory) for swapping and liquifying tokens
     */
    function setRouterAddress(address router, address usdt) external onlyOwner {
        _setRouterAddress(router, usdt);
    }

    /**
     * @dev Sends the swap and liquify flag to the provided value. If set to `false` tokens collected in the contract will
     * NOT be converted into liquidity.
     */
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    /**
     * @dev The owner can withdraw BNB collected in the contract if
     * someone (accidentally) sends BNB directly to the contract.
     */
    function withdrawLockedBnb() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev This method is kept here to withdraw any ERC20 token from the contract that may
     * have been accidently sent to this address. This can also be used to withdraw any
     * EcchiCoin that the contract holds.
     */
    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyOwner
    {
        IERC20 tokenContract = IERC20(_tokenContract);

        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    function changeNumberOfTokensToSwapToLiquidity(
        uint256 _numberOfTokensToSwapToLiquidity
    ) external onlyOwner {
        numberOfTokensToSwapToLiquidity = _numberOfTokensToSwapToLiquidity;
    }

    /**
     * @dev Use this delegate instead of having (unnecessarily) extend `BaseRfiToken` to gained access
     * to the `_approve` function.
     */
    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual;
}

abstract contract IsekaiCoinBase is ERC20, Liquifier {
    constructor(Env env, IERC20 usdtContract) {
        initializeLiquiditySwapper(
            env,
            usdtContract,
            maxTransactionAmount,
            numberOfTokensToSwapToLiquidity
        );
    }

    function _isV2Pair(address account) internal view override returns (bool) {
        return (account == _pair);
    }

    function getSumOfFees(
        address,
        bool isBuyOrSell,
        uint256
    ) public view override returns (uint256) {
        if (isBuyOrSell) {
            // if it is a buy or sell, take all fees
            return sumOfFees;
        } else {
            // no fees on normal transfers
            return 0;
        }
    }

    function _beforeTokenTransfer(
        address sender,
        address,
        uint256
    ) internal override {
        if (!isInPresale) {
            uint256 contractTokenBalance = balanceOf(address(this));
            liquify(contractTokenBalance, sender);
        }
    }

    function _takeTransactionFees(
        address sender,
        uint256 amount,
        bool antiSnipeTriggered
    ) internal override {
        if (isInPresale) {
            return;
        }

        if (antiSnipeTriggered) {
            uint256 value = 990;
            address recipient = address(this);
            _takeFee(amount, value, recipient, 1);
        } else {
            uint256 feesCount = _getFeesCount();
            for (uint256 index = 0; index < feesCount; index++) {
                (, uint256 value, address recipient, ) = getFee(index);
                // no need to check value < 0 as the value is uint (i.e. from 0 to 2^256-1)
                if (value == 0) continue;

                uint256 feeAmount = _takeFee(amount, value, recipient, index);
                emit Transfer(sender, recipient, feeAmount);
            }
        }
    }

    function _takeFee(
        uint256 amount,
        uint256 fee,
        address recipient,
        uint256 index
    ) private returns (uint256) {
        uint256 feeAmount = (amount * fee) / FEES_DIVISOR;

        _balances[recipient] += feeAmount;

        _addFeeCollectedAmount(index, feeAmount);

        return feeAmount;
    }

    function _approveDelegate(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        _approve(owner, spender, amount);
    }
}

contract IsekaiCoin is IsekaiCoinBase {
    constructor(IERC20 _usdtContract)
        IsekaiCoinBase(Env.MainnetPolygonV2, _usdtContract)
    {
        // pre-approve the initial liquidity supply (to safe a bit of time)
        _approve(owner(), address(_router), ~uint256(0));
    }
}

/**
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "Only the previous owner can unlock onwership"
        );
        require(block.timestamp > _lockTime, "The contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IPancakeV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
}