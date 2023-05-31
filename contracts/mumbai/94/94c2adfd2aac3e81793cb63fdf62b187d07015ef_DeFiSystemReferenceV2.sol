// SPDX-License-Identifier: MIT
/*
██████╗ ███████╗███████╗██╗    ███████╗██╗   ██╗███████╗████████╗███████╗███╗   ███╗
██╔══██╗██╔════╝██╔════╝██║    ██╔════╝╚██╗ ██╔╝██╔════╝╚══██╔══╝██╔════╝████╗ ████║
██║  ██║█████╗  █████╗  ██║    ███████╗ ╚████╔╝ ███████╗   ██║   █████╗  ██╔████╔██║
██║  ██║██╔══╝  ██╔══╝  ██║    ╚════██║  ╚██╔╝  ╚════██║   ██║   ██╔══╝  ██║╚██╔╝██║
██████╔╝███████╗██║     ██║    ███████║   ██║   ███████║   ██║   ███████╗██║ ╚═╝ ██║
╚═════╝ ╚══════╝╚═╝     ╚═╝    ╚══════╝   ╚═╝   ╚══════╝   ╚═╝   ╚══════╝╚═╝     ╚═╝

███████╗ ██████╗ ██████╗     ██████╗ ███████╗███████╗███████╗██████╗ ███████╗███╗   ██╗ ██████╗███████╗
██╔════╝██╔═══██╗██╔══██╗    ██╔══██╗██╔════╝██╔════╝██╔════╝██╔══██╗██╔════╝████╗  ██║██╔════╝██╔════╝
█████╗  ██║   ██║██████╔╝    ██████╔╝█████╗  █████╗  █████╗  ██████╔╝█████╗  ██╔██╗ ██║██║     █████╗
██╔══╝  ██║   ██║██╔══██╗    ██╔══██╗██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══╝
██║     ╚██████╔╝██║  ██║    ██║  ██║███████╗██║     ███████╗██║  ██║███████╗██║ ╚████║╚██████╗███████╗
╚═╝      ╚═════╝ ╚═╝  ╚═╝    ╚═╝  ╚═╝╚══════╝╚═╝     ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
Version 2.0
Developed by the same team of systemdefi.crypto, rsd.cash and timetoken.finance
Integrates TIME Token and some of its contracts with RSD + SDR system
---------------------------------------------------------------------------------------

REVERT/REQUIRE CODE ERRORS:
DSRv2_01: please refer you can call this function only once at a time until it is fully executed
DSRv2_02: you should allow D2 to be spent before calling the function
DSRv2_03: TIME amount sent must match with the ETH amount sent
DSRv2_04: D2 contract does not have enough ETH amount to perform the operation
DSRv2_05: the pool does not have a sufficient amount to trade
DSRv2_06: there is no enough tokens to sell
DSRv2_07: there is no enough tokens to burn
DSRv2_08: only D2Helper can call this function
DSRv2_09: get out of here dude!
DSRv2_10: borrowed amount must be less or equal to total supply
DSRv2_11: not enough to cover expenses
DSRv2_12: please do not forget to call payFlashMintFee() function and pay the flash mint
---------------------------------------------------------------------------------------
*/
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./ID2HelperBase.sol";
import "./IEmployer.sol";
import "./IReferenceSystemDeFi.sol";
import "./ITimeToken.sol";
import "./ID2FlashMintBorrower.sol";

contract DeFiSystemReferenceV2 is IERC20, Ownable {
    using Math for uint256;

    bool private _isFlashMintPaid;
    bool private _isFlashMintStarted;
    bool private _isInternalLP;
    bool private _isOperationLocked;
    bool private _isTryingPoBet;

    address public constant DONATION_ADDRESS = 0xbF616B8b8400373d53EC25bB21E2040adB9F927b;

    address payable public immutable employerAddress;
    address public immutable exchangeRouterAddress;

    string private _name;
    string private _symbol;

    uint256 private constant FACTOR = 10 ** 18;
    uint256 private constant SHARES = 7;

    uint256 public constant COMISSION_RATE = 100;
    uint256 public constant DONATION_RATE = 50;
    uint256 public constant FLASH_MINT_FEE = 100;

    uint256 private _currentBlockTryingPoBet;
    uint256 private _totalSupply;
    uint256 private _totalForDividend;

    uint256 public arbitrageCount;
    uint256 public currentFlashMintFee;
    uint256 public dividendPerToken;
    uint256 public poolBalance;
    uint256 public toBeShared;
    uint256 public totalEarned;
    uint256 public totalEarnedFromFlashMintFee;
    uint256 public totalEmployed;
    uint256 public totalTimeBoughtAndBurned;
    uint256 public totalTimeBoughtInNative;

    ID2HelperBase public d2Helper;
    ITimeToken private timeToken;
    IReferenceSystemDeFi private rsd;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _consumedDividendPerToken;

    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(
        string memory name_,
        string memory symbol_,
        address _d2HelperAddress,
        address _employerAddress,
        address _exchangeRouterAddress,
        address _timeTokenAddress,
        address _rsdTokenAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        employerAddress = payable(_employerAddress);
        exchangeRouterAddress = _exchangeRouterAddress;
        timeToken = ITimeToken(payable(_timeTokenAddress));
        rsd = IReferenceSystemDeFi(_rsdTokenAddress);
        d2Helper = ID2HelperBase(_d2HelperAddress);
        renounceOwnership();
    }

    /**
     * @dev This modifier is called when a flash mint is performed. It modifies the internal state of the contract to avoid share calculation when flash mint is running
     *
     */
    modifier performFlashMint() {
        require(!_isFlashMintStarted, "DSRv2_09");
        _isFlashMintPaid = false;
        _isFlashMintStarted = true;
        _;
        _isFlashMintStarted = false;
    }

    /**
     * @dev This modifier helps to avoid calling functions which access the internal liquidity pool of the contract
     *
     */
    modifier isInternalLP() {
        _isInternalLP = true;
        _;
        _isInternalLP = false;
    }

    /**
     * @dev This modifier helps to avoid/mitigate reentrancy attacks
     *
     */
    modifier nonReentrant() {
        require(!_isOperationLocked || msg.sender == address(d2Helper), "DSRv2_01");
        _isOperationLocked = true;
        _;
        _isOperationLocked = false;
    }

    /**
     * @dev Performs state update when receiving funds from any source
     *
     */
    receive() external payable {
        _receive();
    }

    /**
     * @dev Fallback function to call in any situation
     *
     */
    fallback() external payable {
        require(msg.data.length == 0 || msg.sender == address(timeToken) || msg.sender == address(d2Helper));
        _receive();
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
        if (!_isInternalLP) {
            tryPoBet(uint256(sha256(abi.encodePacked(from, to, amount))));
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
        _credit(from);
        _credit(to);
    }

    /**
     * @dev Add liquidity for the D2/ETH pair LP in third party exchange (based on UniswapV2)
     * @param amount The amount in ETH to add to the LP
     * @param d2Amount The amount in D2 to add to the LP
     *
     */
    function _addLiquidityD2Native(uint256 amount, uint256 d2Amount) private isInternalLP {
        require(address(this).balance >= amount, "DSRv2_04");
        if (d2Amount > 0) {
            _mint(address(d2Helper), d2Amount);
            bool success = d2Helper.addLiquidityD2Native{ value: amount }(d2Amount);
            if (!success && _balances[address(d2Helper)] > 0) {
                _burn(address(d2Helper), _balances[address(d2Helper)]);
                _mint(address(this), d2Amount);
            }
        }
    }

    /**
     * @dev Add liquidity for the D2/SDR pair LP in third party exchange (based on UniswapV2)
     * @param d2Amount The amount in D2 to add to the LP
     *
     */
    function _addLiquidityD2Sdr(uint256 d2Amount) private isInternalLP {
        if (d2Amount > 0) {
            _mint(address(d2Helper), d2Amount);
            try d2Helper.addLiquidityD2Sdr() returns (bool success) {
                if (!success && _balances[address(d2Helper)] > 0) {
                    _burn(address(d2Helper), _balances[address(d2Helper)]);
                }
            } catch { }
        }
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
        require(owner != address(0), "ERC20 D2: approve from the zero address");
        require(spender != address(0), "ERC20 D2: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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
        require(account != address(0), "ERC20 D2: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20 D2: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Use part of the funds to generate value for TIME Token, buying some amount
     * @param amount The amount to buy
     */
    function _buyAndBurnTime(uint256 amount) private {
        require(address(this).balance >= amount, "DSRv2_04");
        totalTimeBoughtInNative += amount;
        uint256 timeAmount = timeToken.balanceOf(address(this));
        address(timeToken).call{ value: amount }("");
        totalTimeBoughtAndBurned += (timeToken.balanceOf(address(this)) - timeAmount);
        timeToken.burn(timeToken.balanceOf(address(this)));
    }

    /**
     * @dev Use part of the funds to generate value for the RSD and SDR tokens. Also, it provides external liquidity to the D2/SDR pair
     * @param amount The amount used to buy RSD first
     *
     */
    function _buyRsdSdrAndAddLiquidity(uint256 amount) private {
        require(address(this).balance >= amount, "DSRv2_04");
        try d2Helper.buyRsd{ value: amount }() {
            try d2Helper.buySdr() {
                _addLiquidityD2Sdr(_queryD2AmountOptimal(amount));
            } catch { }
        } catch { }
    }

    /**
     * @dev Calculate comission value over the provided amount
     * @return uint256 Comission value
     *
     */
    function _calculateComissionOverAmount(uint256 amount) private pure returns (uint256) {
        return amount.mulDiv(COMISSION_RATE, 10_000);
    }

    /**
     * @dev Check for arbitrage opportunities and perform them if they are profitable. Profit is shared with D2 token holders
     *
     */
    function _checkAndPerformArbitrage() private {
        try d2Helper.checkAndPerformArbitrage() returns (bool success) {
            if (success) {
                arbitrageCount++;
            }
        } catch { }
    }

    /**
     * @dev Calculate the amount some address has to claim and credit for it
     * @param account The account address
     *
     */
    function _credit(address account) private {
        uint256 amount = accountShareBalance(account);
        if (amount > 0) {
            _balances[account] += amount;
            emit Transfer(address(0), account, amount);
        }
        _consumedDividendPerToken[account] = dividendPerToken;
    }

    /**
     * @dev Send ETH to the Employer as reward to investors
     * @param amount Value to send to the Employer
     */
    function _feedEmployer(uint256 amount) private {
        require(address(this).balance >= amount, "DSRv2_04");
        totalEmployed += amount;
        employerAddress.call{ value: amount }("");
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20 D2: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _totalForDividend += (account != address(d2Helper) && account != address(this)) ? amount : 0;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Returns the optimal amount, in terms of D2 tokens, for the native amount passed
     * @param amountNative The native amount to be converted
     * @return uint256 The D2 optimal amount from native amount informed
     *
     */
    function _queryD2AmountOptimal(uint256 amountNative) private view returns (uint256) {
        uint256 externalLP = queryD2AmountExternalLP(amountNative);
        uint256 internalLP = queryD2AmountInternalLP(amountNative);
        if (externalLP >= internalLP) {
            return (msg.sender == address(d2Helper)) ? externalLP : internalLP;
        } else {
            return (msg.sender == address(d2Helper)) ? internalLP : externalLP;
        }
    }

    /**
     * @dev Returns the native amount for the amount of D2 tokens passed
     * @param d2Amount The amount of D2 tokens to be converted
     * @return uint256 The amount of native tokens correspondent to the D2 tokens amount
     *
     */
    function _queryNativeAmount(uint256 d2Amount) private view returns (uint256) {
        return d2Amount.mulDiv(queryPriceInverse(d2Amount), FACTOR);
    }

    /**
     * @dev Private receive function. Called when the external receive() or fallback() functions receive funds
     *
     */
    function _receive() private {
        totalEarned += msg.value;
        toBeShared += msg.value.mulDiv((SHARES - 1), SHARES);
        _updatePoolBalance();
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
            require(currentAllowance >= amount, "ERC20 D2: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Private function called when the system needs to split shares among D2 holders
     * @notice SHARES:
     *   1. msg.sender - D2 minted | LP Internal
     *   2. Buy TIME + RSD
     *   3. Employer Feed
     *   4. LP External (plus 1/4 of a share)
     *   5. LP Internal (plus 1/4 of a share)
     *   6. Dividends | LP Internal
     *   7. Donation Address (half of a share)
     */
    function _splitSharesDinamically() private {
        uint256 share = toBeShared / SHARES;
        uint256 halfShare = share / 2;
        if (address(rsd) != address(0)) {
            _buyAndBurnTime(halfShare);
            _buyRsdSdrAndAddLiquidity(halfShare);
        } else {
            _buyAndBurnTime(share);
        }
        _feedEmployer(share);
        payable(DONATION_ADDRESS).call{ value: halfShare }("");
        uint256 halfHalfShare = halfShare / 2;
        uint256 d2ShareForLiquidity = _queryD2AmountOptimal(share + halfHalfShare);
        _addLiquidityD2Native(share + halfHalfShare, d2ShareForLiquidity);
        _mint(address(this), d2ShareForLiquidity);

        // Calculates dividend to be shared among D2 holders and add it to the total supply
        uint256 currentDividend = dividendPerToken;
        dividendPerToken += queryD2AmountInternalLP(share).mulDiv(FACTOR, _totalForDividend);
        uint256 t = _totalForDividend.mulDiv(dividendPerToken - currentDividend, FACTOR);
        _totalSupply += t;
        _totalForDividend += t;

        toBeShared = 0;
        _checkAndPerformArbitrage();
        _updatePoolBalance();
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
        require(from != address(0), "ERC20 D2: transfer from the zero address");
        require(to != address(0), "ERC20 D2: transfer to the zero address");

        _checkAndPerformArbitrage();

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20 D2: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Updates the state of the internal pool balance
     *
     */
    function _updatePoolBalance() private {
        poolBalance = address(this).balance > toBeShared ? address(this).balance - toBeShared : 0;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view virtual returns (string memory) {
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
    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account] + accountShareBalance(account);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) external virtual returns (bool) {
        if (to == address(this)) {
            sellD2(amount);
        } else {
            _transfer(msg.sender, to, amount);
        }
        return true;
        // address owner = msg.sender;
        // _transfer(owner, to, amount);
        // return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
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
    function approve(address spender, uint256 amount) external virtual returns (bool) {
        address owner = msg.sender;
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
    function transferFrom(address from, address to, uint256 amount) external virtual returns (bool) {
        address spender = msg.sender;
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
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        address owner = msg.sender;
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
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20 D2: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Show the amount an account address can credit to itself
     * @notice Shares are not calculated when running flash mint
     * @param account The address of some account
     * @return The claimable amount
     *
     */
    function accountShareBalance(address account) public view returns (uint256) {
        if (
            account != address(this) && account != d2Helper.pairD2Eth() && account != d2Helper.pairD2Sdr()
                && account != address(d2Helper) && account != exchangeRouterAddress && !_isFlashMintStarted
        ) {
            return _balances[account].mulDiv(dividendPerToken - _consumedDividendPerToken[account], FACTOR);
        } else {
            return 0;
        }
    }

    /**
     * @dev External function to burn D2 tokens. Sometimes is useful when you want to throw your money away... Who knows?
     * @param amount The amount of D2 tokens to be burned
     *
     */
    function burn(uint256 amount) external {
        require(amount <= balanceOf(msg.sender), "DSRv2_07");
        _burn(msg.sender, amount);
    }

    /**
     * @dev Main function of the D2 contract. Called whenever someone needs to generate tokens under the required conditions
     * @param timeAmount The amount of TIME Tokens an investor wants to use in order to mint more D2 tokens
     *
     */
    function mintD2(uint256 timeAmount) external payable nonReentrant {
        // It must burn TIME Token in order to mint additional D2 tokens
        require(timeToken.allowance(msg.sender, address(this)) >= timeAmount, "DSRv2_02");
        uint256 timeAmountNativeValue = queryNativeFromTimeAmount(timeAmount);
        require(msg.value >= timeAmountNativeValue && msg.value > 0, "DSRv2_03");
        if (timeAmount > 0) {
            timeToken.transferFrom(msg.sender, address(this), timeAmount);
            timeToken.burn(timeAmount);
        }
        uint256 share = msg.value / SHARES;
        d2Helper.kickBack{ value: msg.value }();
        _mint(msg.sender, queryD2AmountOptimal(share + timeAmountNativeValue));
        _splitSharesDinamically();
    }

    /**
     * @dev It creates and returns a random address
     * @param someNumber Used as seed number to improve randomness
     *
     */
    function obtainRandomWalletAddress(uint256 someNumber) public view returns (address) {
        if (address(rsd) != address(0)) {
            return address(
                bytes20(
                    sha256(
                        abi.encodePacked(
                            block.timestamp,
                            block.number,
                            block.difficulty,
                            block.coinbase,
                            _totalSupply,
                            msg.sender,
                            rsd.totalSupply(),
                            someNumber
                        )
                    )
                )
            );
        } else {
            return address(
                bytes20(
                    sha256(
                        abi.encodePacked(
                            block.timestamp,
                            block.number,
                            block.difficulty,
                            block.coinbase,
                            _totalSupply,
                            msg.sender,
                            someNumber
                        )
                    )
                )
            );
        }
    }

    /**
     * @dev Queries for the external amount, in terms of D2 tokens, given an informed native amount
     * @notice It queries for the external LP
     * @param amountNative The native amount
     * @return uint256 The amount of D2 tokens
     *
     */
    function queryD2AmountExternalLP(uint256 amountNative) public view returns (uint256) {
        uint256 d2AmountExternalLP = amountNative.mulDiv(queryRate(), FACTOR);
        return (d2AmountExternalLP == 0) ? amountNative : d2AmountExternalLP;
    }

    /**
     * @dev Queries for the internal amount, in terms of D2 tokens, given an informed native amount
     * @notice It queries for the internal LP
     * @param amountNative The native amount
     * @return uint256 The amount of D2 tokens
     *
     */
    function queryD2AmountInternalLP(uint256 amountNative) public view returns (uint256) {
        uint256 d2AmountInternalLP = amountNative.mulDiv(queryPriceNative(amountNative), FACTOR);
        return (d2AmountInternalLP == 0) ? amountNative : d2AmountInternalLP;
    }

    /**
     * @dev Queries for the optimal amount, in terms of D2 tokens, given an informed native amount
     * @param amountNative The native amount
     * @return uint256 The amount of D2 tokens
     *
     */
    function queryD2AmountOptimal(uint256 amountNative) public view returns (uint256) {
        uint256 d2AmountOptimal = _queryD2AmountOptimal(amountNative);
        return (d2AmountOptimal - _calculateComissionOverAmount(d2AmountOptimal));
    }

    /**
     * @dev Queries for the native amount value given some D2 tokens informed
     * @param d2Amount The amount of D2 tokens
     * @return uint256 The native amount
     *
     */
    function queryNativeAmount(uint256 d2Amount) external view returns (uint256) {
        uint256 d2AmountNativeValue = _queryNativeAmount(d2Amount);
        return (d2AmountNativeValue - _calculateComissionOverAmount(d2AmountNativeValue));
    }

    /**
     * @dev Queries for the native amount value given some TIME Token amount passed
     * @param timeAmount The amount of TIME Tokens informed
     * @return uint256 The native amount
     *
     */
    function queryNativeFromTimeAmount(uint256 timeAmount) public view returns (uint256) {
        if (timeAmount != 0) {
            return timeAmount.mulDiv(timeToken.swapPriceTimeInverse(timeAmount), FACTOR);
        } else {
            return 0;
        }
    }

    /**
     * @dev Query for the Aave Pool Address Provider contract's address
     * @return address The address of the Aave Pool Address Provider
     *
     */
    function queryPoolAddress() external view returns (address) {
        return d2Helper.queryPoolAddress();
    }

    /**
     * @dev Query for market price before swap, in D2/ETH, in terms of native cryptocurrency (ETH)
     * @notice Constant Function Market Maker
     * @param amountNative The amount of ETH a user wants to exchange
     * @return Local market price, in D2/ETH, given the amount of ETH a user informed
     *
     */
    function queryPriceNative(uint256 amountNative) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 ratio = poolBalance.mulDiv(FACTOR, amountNative + 1);
            uint256 deltaSupply =
                _balances[address(this)].mulDiv(amountNative.mulDiv(ratio, 1), poolBalance + amountNative);
            return deltaSupply / poolBalance;
        } else {
            return FACTOR;
        }
    }

    /**
     * @dev Query for market price before swap, in ETH/D2, in terms of ETH currency
     * @param d2Amount The amount of D2 a user wants to exchange
     * @return Local market price, in ETH/D2, given the amount of D2 a user informed
     *
     */
    function queryPriceInverse(uint256 d2Amount) public view returns (uint256) {
        if (poolBalance > 0 && _balances[address(this)] > 0) {
            uint256 ratio = _balances[address(this)].mulDiv(FACTOR, d2Amount + 1);
            uint256 deltaBalance = poolBalance.mulDiv(d2Amount.mulDiv(ratio, 1), _balances[address(this)] + d2Amount);
            return deltaBalance / _balances[address(this)];
        } else {
            return 1;
        }
    }

    /**
     * @dev Query the rate D2/ETH in the external LP
     *
     */
    function queryRate() public view returns (uint256) {
        return d2Helper.queryD2Rate();
    }

    /**
     * @dev Queries the amount to be paid to callers of the splitSharesDinamicallyWithReward() function
     * @return uint256 The amount to be paid
     *
     */
    function queryPublicReward() public view returns (uint256) {
        return toBeShared.mulDiv(DONATION_RATE, 10_000);
    }

    /**
     * @dev Returns native amount back to the D2 contract when it is not desired to share the amount with holders. Usually called by D2Helper
     * @return bool Just a silly response
     *
     */
    function returnNativeWithoutSharing() external payable nonReentrant returns (bool) {
        _updatePoolBalance();
        return true;
    }

    /**
     * @dev Splits the share (earned amount) among the D2 token holders and pays a reward for the caller
     * @notice This function should be called sometimes in order to make the contract works as desired
     *
     */
    function splitSharesDinamicallyWithReward() external nonReentrant {
        if (toBeShared > 0) {
            uint256 reward = queryPublicReward();
            toBeShared -= reward;
            _splitSharesDinamically();
            payable(msg.sender).transfer(reward);
            _updatePoolBalance();
        }
    }

    /**
     * @dev Tries to earn some RSD tokens in the PoBet system. The earned amount is exchanged with SDR, which is then locked in D2/SDR LP
     * @param someNumber Seed number to improve randomness
     */
    function tryPoBet(uint256 someNumber) public {
        if (!_isTryingPoBet && address(rsd) != address(0)) {
            _isTryingPoBet = true;
            if (_currentBlockTryingPoBet != block.number) {
                _currentBlockTryingPoBet = block.number;
                uint256 rsdBalance = rsd.balanceOf(address(this));
                try rsd.transfer(obtainRandomWalletAddress(someNumber), rsdBalance) {
                    uint256 newRsdBalance = rsd.balanceOf(address(this));
                    // it means we have won the PoBet prize! Woo hoo! So, now we exchange RSD for SDR with this earned amount!
                    if (rsdBalance < newRsdBalance) {
                        rsd.transfer(address(d2Helper), newRsdBalance);
                        try d2Helper.buySdr() {
                            _addLiquidityD2Sdr(d2Helper.queryD2AmountFromSdr());
                        } catch { }
                    }
                } catch { }
                // we also help to improve randomness of the RSD token contract after trying the PoBet system
                rsd.generateRandomMoreThanOnce();
            }
            _isTryingPoBet = false;
        }
    }

    /**
     * @dev Investor send native cryptocurrency in exchange for D2 tokens. Here, he sends some amount and the contract calculates the equivalent amount in D2 units
     * @notice msg.value - The amount of D2 in terms of ETH an investor wants to buy
     * @return success If the operation was performed well
     */
    function buyD2() external payable nonReentrant isInternalLP returns (bool success) {
        if (msg.value > 0) {
            uint256 nativeAmountD2Value = _queryD2AmountOptimal(msg.value);
            require(nativeAmountD2Value <= _balances[address(this)], "DSRv2_05");
            if (msg.sender == address(d2Helper)) {
                _transfer(address(this), msg.sender, nativeAmountD2Value);
            } else {
                _transfer(
                    address(this), msg.sender, nativeAmountD2Value - _calculateComissionOverAmount(nativeAmountD2Value)
                );
            }
            _updatePoolBalance();
            success = true;
        }
        return success;
    }

    /**
     * @dev Investor send D2 tokens in exchange for native cryptocurrency
     * @param d2Amount The amount of D2 tokens for exchange
     * @return success Informs if the sell was performed well
     */
    function sellD2(uint256 d2Amount) public nonReentrant isInternalLP returns (bool success) {
        require(!_isFlashMintStarted, "DSRv2_09");
        require(balanceOf(msg.sender) >= d2Amount, "DSRv2_06");
        uint256 d2AmountNativeValue = _queryNativeAmount(d2Amount);
        require(d2AmountNativeValue <= poolBalance, "DSRv2_05");
        _transfer(msg.sender, address(this), d2Amount);
        if (msg.sender == address(d2Helper)) {
            payable(msg.sender).transfer(d2AmountNativeValue);
        } else {
            uint256 comission = _calculateComissionOverAmount(d2AmountNativeValue);
            payable(msg.sender).transfer(d2AmountNativeValue - comission);
            d2Helper.kickBack{ value: comission }();
        }
        _updatePoolBalance();
        return success;
    }

    /**
     * @dev Performs flash mint of D2 tokens for msg.sender address, limited to the _totalSupply amount
     * @notice The user must implement his logic inside the doSomething() function. The fee for flash mint must be paid in native tokens by calling and passing the value for the payFlashMintFee() function from the doSomething() function
     * @param d2AmountToBorrow The amount of D2 tokens the user wants to borrow
     * @param data Arbitrary data the user wants to pass to its doSomething() function
     *
     */
    function flashMint(uint256 d2AmountToBorrow, bytes calldata data) external nonReentrant performFlashMint {
        require(d2AmountToBorrow <= _totalSupply, "DSRv2_10");
        uint256 earnedBefore = totalEarnedFromFlashMintFee;
        currentFlashMintFee = _queryNativeAmount(d2AmountToBorrow).mulDiv(FLASH_MINT_FEE, 10_000);
        _mint(msg.sender, d2AmountToBorrow);
        // Here the borrower should perform some action with the borrowed D2 amount
        ID2FlashMintBorrower(msg.sender).doSomething(d2AmountToBorrow, currentFlashMintFee, data);
        require((totalEarnedFromFlashMintFee - earnedBefore) >= currentFlashMintFee, "DSRv2_11");
        require(_isFlashMintPaid, "DSRv2_12");
        _burn(msg.sender, d2AmountToBorrow);
    }

    /**
     * @dev Function called inside the doSomething() function to pay fees for the flash minted amount
     *
     */
    function payFlashMintFee() external payable {
        require(_isFlashMintStarted, "DSRv2_09");
        require(msg.value >= currentFlashMintFee, "DSRv2_11");
        totalEarned += msg.value;
        totalEarnedFromFlashMintFee += msg.value;
        toBeShared += msg.value.mulDiv((SHARES - 1), SHARES);
        _updatePoolBalance();
        _isFlashMintPaid = true;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

interface ID2HelperBase {
    function addLiquidityD2Native(uint256 d2Amount) external payable returns (bool);
    function addLiquidityD2Sdr() external returns (bool);
    function buyRsd() external payable returns (bool);
    function buySdr() external returns (bool);
    function checkAndPerformArbitrage() external returns (bool);
    function kickBack() external payable;
    function pairD2Eth() external view returns (address);
    function pairD2Sdr() external view returns (address);
    function queryD2AmountFromSdr() external view returns (uint256);
    function queryD2Rate() external view returns (uint256);
    function queryPoolAddress() external view returns (address);
    function setD2(address d2TokenAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEmployer {
    function DEVELOPER_ADDRESS() external returns (address);
    function TIME_TOKEN_ADDRESS() external returns (address);
    function D() external returns (uint256);
    function FACTOR() external returns (uint256);
    function FIRST_BLOCK() external returns (uint256);
    function ONE_YEAR() external returns (uint256);
    function availableNative() external returns (uint256);
    function currentDepositedNative() external returns (uint256);
    function totalAnticipatedTime() external returns (uint256);
    function totalBurnedTime() external returns (uint256);
    function totalDepositedNative() external returns (uint256);
    function totalDepositedTime() external returns (uint256);
    function totalEarnedNative() external returns (uint256);
    function totalTimeSaved() external returns (uint256);
    function anticipationEnabled(address account) external returns (bool);
    function deposited(address account) external returns (uint256);
    function earned(address account) external view returns (uint256);
    function lastBlock(address account) external returns (uint256);
    function remainingTime(address account) external returns (uint256);
    function anticipate(uint256 timeAmount) external payable;
    function anticipationFee() external view returns (uint256);
    function compound(uint256 timeAmount, bool mustAnticipateTime) external;
    function deposit(uint256 timeAmount, bool mustAnticipateTime) external payable;
    function earn() external;
    function enableAnticipation() external payable;
    function getCurrentROI() external view returns (uint256);
    function getCurrentROIPerBlock() external view returns (uint256);
    function getROI() external view returns (uint256);
    function getROIPerBlock() external view returns (uint256);
    function queryAnticipatedEarnings(address depositant, uint256 anticipatedTime) external view returns (uint256);
    function queryEarnings(address depositant) external view returns (uint256);
    function withdrawEarnings() external;
    function withdrawDeposit() external;
    function withdrawDepositEmergency() external;
    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReferenceSystemDeFi is IERC20 {
    function burn(uint256 amount) external;
    function generateRandomMoreThanOnce() external;
    function getCrowdsaleDuration() external view returns (uint128);
    function getExpansionRate() external view returns (uint16);
    function getSaleRate() external view returns (uint16);
    function log_2(uint256 x) external pure returns (uint256 y);
    function mintForStakeHolder(address stakeholder, uint256 amount) external;
    function obtainRandomNumber(uint256 modulus) external;
    function withdrawSales(address to) external;
    function updateMaxTxInterval(uint16 maxTxInterval) external;
    function updateMinTxInterval(uint16 minTxInterval) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITimeToken {
    function DEVELOPER_ADDRESS() external view returns (address);
    function BASE_FEE() external view returns (uint256);
    function COMISSION_RATE() external view returns (uint256);
    function SHARE_RATE() external view returns (uint256);
    function TIME_BASE_LIQUIDITY() external view returns (uint256);
    function TIME_BASE_FEE() external view returns (uint256);
    function TOLERANCE() external view returns (uint256);
    function dividendPerToken() external view returns (uint256);
    function firstBlock() external view returns (uint256);
    function isMiningAllowed(address account) external view returns (bool);
    function liquidityFactorNative() external view returns (uint256);
    function liquidityFactorTime() external view returns (uint256);
    function numberOfHolders() external view returns (uint256);
    function numberOfMiners() external view returns (uint256);
    function sharedBalance() external view returns (uint256);
    function poolBalance() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
    function averageMiningRate() external view returns (uint256);
    function donateEth() external payable;
    function enableMining() external payable;
    function enableMiningWithTimeToken() external;
    function fee() external view returns (uint256);
    function feeInTime() external view returns (uint256);
    function mining() external;
    function saveTime() external payable returns (bool success);
    function spendTime(uint256 timeAmount) external returns (bool success);
    function swapPriceNative(uint256 amountNative) external view returns (uint256);
    function swapPriceTimeInverse(uint256 amountTime) external view returns (uint256);
    function accountShareBalance(address account) external view returns (uint256);
    function withdrawableShareBalance(address account) external view returns (uint256);
    function withdrawShare() external;
    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ID2FlashMintBorrower {
    function doSomething(uint256 amountD2, uint256 fee, bytes calldata data) external;
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