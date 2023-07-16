// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Presale is Ownable {
    struct PresaleStruct {
        ERC20 token;
        ERC20 purchaseToken;
        address creator;
        bool whitelistedEnabled;
        bool burnOrRefund;
        bool burnedOrRefunded;
        bool vestingEnabled;
        bool devFeeInToken;
        uint256 softCap;
        uint256 hardCap;
        uint256 presaleRate;
        uint256 moneyRaised;
        uint256 tokensSold;
        uint256 devCommission;
        uint256 devCommissionInToken;
        uint256 affiliateCommissionAmount;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 startTime;
        uint256 endTime;
        uint256 affiliateRate;
        uint256 firstReleasePercentage;
        uint256 vestingPeriod;
        uint256 cycleReleasePercentage;
        uint256 liquidityAdditionPercent;
        uint256 liquidityUnlockTime;
        uint256 listingRate;
        mapping(address => bool) whitelisted;
        mapping(address => uint256) tokensPurchased;
        mapping(address => uint256) tokensInvested;
        mapping(address => uint256) affiliateCommission;
        mapping(address => uint256) tokensVested;
        mapping(address => uint256) lastClaimedCycle;
    }

    uint256 public devFeeInTokenPercentage = 2; // 2%
    uint256 public devFee = 5; // 5%
    PresaleStruct[] public presales;

    function updateDevFee(uint256 _newFee) external onlyOwner {
        require(_newFee >= 0 && _newFee <= 5, "Must be less than 5%");
        devFee = _newFee;
    }

    function createPresale(
        address _tokenAddress,
        address _purchaseTokenAddress,
        bool _whitelistedEnabled,
        bool _burnOrRefund,
        bool _vestingEnabled,
        bool _devFeeInToken,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _presaleRate,
        uint256 _minBuy,
        uint256 _maxBuy,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _affiliateRate,
        uint256 _firstReleasePercentage,
        uint256 _vestingPeriod,
        uint256 _cycleReleasePercentage,
        uint256 _liquidityAdditionPercent,
        uint256 _liquidityUnlockTime,
        uint256 _listingRate
    ) external payable {
        require(
            _tokenAddress != address(0),
            "tokenAddress can't be zero address"
        );
        require(
            _softCap >= _hardCap / 4,
            "Softcap must be more than 25% of hardcap"
        );
        require(_minBuy < _maxBuy, "Min buy !>= max buy");
        require(_startTime >= block.timestamp, "Start Time can't be in past");
        require(
            _endTime - _startTime <= 30 days,
            "Presale duration can't exceed one month"
        );
        require(_affiliateRate <= 5, "Affiliate Rate can't exceed 5%");
        if (_vestingEnabled == true) {
            require(
                _firstReleasePercentage + _cycleReleasePercentage <= 100,
                "Invalid Release %"
            );
        }
        require(msg.value == 1 ether, "Creation fee invalid");

        ERC20 token = ERC20(_tokenAddress);

        if (_devFeeInToken) {
            uint256 tokensForDevFee = (_presaleRate *
                _hardCap *
                devFeeInTokenPercentage) / 100;
            require(
                token.allowance(msg.sender, address(this)) >=
                    tokensForDevFee + (_presaleRate * _hardCap),
                "Check the token allowance"
            );
            token.transferFrom(
                msg.sender,
                address(this),
                _presaleRate * _hardCap + tokensForDevFee
            );
        } else {
            require(
                token.allowance(msg.sender, address(this)) >=
                    _presaleRate * _hardCap,
                "Check the token allowance"
            );
            token.transferFrom(
                msg.sender,
                address(this),
                _presaleRate * _hardCap
            );
        }
        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Transfer failed");

        presales.push();
        PresaleStruct storage newPresale = presales[presales.length - 1];
        newPresale.token = ERC20(_tokenAddress);
        newPresale.purchaseToken = ERC20(_purchaseTokenAddress);
        newPresale.creator = msg.sender;
        newPresale.whitelistedEnabled = _whitelistedEnabled;
        newPresale.burnOrRefund = _burnOrRefund;
        newPresale.vestingEnabled = _vestingEnabled;
        newPresale.devFeeInToken = _devFeeInToken;
        newPresale.softCap = _softCap;
        newPresale.hardCap = _hardCap;
        newPresale.presaleRate = _presaleRate;
        newPresale.minBuy = _minBuy;
        newPresale.maxBuy = _maxBuy;
        newPresale.startTime = _startTime;
        newPresale.endTime = _endTime;
        newPresale.affiliateRate = _affiliateRate;
        newPresale.firstReleasePercentage = _firstReleasePercentage;
        newPresale.vestingPeriod = _vestingPeriod;
        newPresale.cycleReleasePercentage = _cycleReleasePercentage;
        newPresale.liquidityAdditionPercent = _liquidityAdditionPercent;
        newPresale.liquidityUnlockTime = _liquidityUnlockTime;
        newPresale.listingRate = _listingRate;
    }

    function whitelistAddress(uint256 _presaleIndex, address _buyer) external {
        PresaleStruct storage presale = presales[_presaleIndex];
        require(
            presale.whitelistedEnabled == true,
            "Whitelisting is not enabled"
        );
        require(msg.sender == presale.creator, "Only creator can whitelist");
        require(block.timestamp < presale.endTime, "Presale has ended");
        presale.whitelisted[_buyer] = true;
    }

    function buyToken(
        uint256 _presaleIndex,
        uint256 _amount,
        address _affiliate
    ) external payable {
        PresaleStruct storage presale = presales[_presaleIndex];
        require(
            _affiliate != msg.sender,
            "Buyer cannot be their own affiliate"
        );
        require(
            block.timestamp >= presale.startTime &&
                block.timestamp <= presale.endTime,
            "Presale not active"
        );
        if (presale.whitelistedEnabled) {
            require(presale.whitelisted[msg.sender], "Address not whitelisted");
        }
        require(
            _amount >= presale.minBuy && _amount <= presale.maxBuy,
            "Invalid amount"
        );
        require(
            presale.moneyRaised + _amount <= presale.hardCap,
            "Hard cap reached"
        );

        uint256 tokensToBuy = _amount * presale.presaleRate;
        uint256 affiliateShare = (_amount * presale.affiliateRate) / 100;
        uint256 devShare;
        uint256 devShareInToken;
        if (presale.devFeeInToken) {
            devShare = (_amount * devFeeInTokenPercentage) / 100;
            devShareInToken = (tokensToBuy * devFeeInTokenPercentage) / 100;
        } else {
            devShare = (_amount * devFee) / 100;
        }

        if (address(presale.purchaseToken) == address(0)) {
            require(msg.value >= _amount, "Not enough AVAX provided");
        } else {
            require(
                presale.purchaseToken.allowance(msg.sender, address(this)) >=
                    _amount,
                "Check the token allowance"
            );
            presale.purchaseToken.transferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        presale.devCommission += devShare;
        if (affiliateShare != 0 && _affiliate != address(0)) {
            presale.affiliateCommissionAmount += affiliateShare;
            presale.affiliateCommission[_affiliate] += affiliateShare;
        }
        if (devShareInToken != 0)
            presale.devCommissionInToken += devShareInToken;
        presale.tokensPurchased[msg.sender] += tokensToBuy;
        presale.tokensInvested[msg.sender] += _amount;
        presale.moneyRaised += _amount;
        presale.tokensSold += tokensToBuy;
    }

    function refundInvestment(uint256 _presaleId) external {
        PresaleStruct storage presale = presales[_presaleId];

        require(block.timestamp > presale.endTime, "Presale has not ended yet");
        require(presale.moneyRaised < presale.softCap, "SoftCap was reached");
        if (msg.sender == presale.creator) {
            presale.token.transfer(
                presale.creator,
                presale.token.balanceOf(address(this))
            );
        } else {
            require(
                presale.tokensInvested[msg.sender] > 0,
                "No investment to refund"
            );
            uint256 investmentToRefund = presale.tokensInvested[msg.sender];
            presale.tokensInvested[msg.sender] = 0;

            if (address(presale.purchaseToken) == address(0)) {
                (bool success, ) = payable(msg.sender).call{
                    value: investmentToRefund
                }("");
                require(success, "Transfer failed");
            } else {
                presale.purchaseToken.transfer(msg.sender, investmentToRefund);
            }
        }
    }

    function claimTokens(uint256 _presaleId) external {
        PresaleStruct storage presale = presales[_presaleId];
        require(
            block.timestamp >= presale.endTime,
            "Presale has not ended yet"
        );
        require(presale.moneyRaised >= presale.softCap, "SoftCap not reached");
        require(
            presale.tokensPurchased[msg.sender] >
                presale.tokensVested[msg.sender],
            "No tokens left to claim"
        );

        if (presale.vestingEnabled) {
            uint256 cyclesPassed = ((block.timestamp - presale.endTime) /
                (presale.vestingPeriod * 1 days)) + 1;

            uint256 toVest;

            if (presale.lastClaimedCycle[msg.sender] == 0) {
                if (cyclesPassed == 1) {
                    toVest =
                        (presale.tokensPurchased[msg.sender] *
                            presale.firstReleasePercentage) /
                        100;
                } else {
                    toVest =
                        ((presale.tokensPurchased[msg.sender] *
                            presale.firstReleasePercentage) / 100) +
                        (((cyclesPassed - 1) *
                            presale.tokensPurchased[msg.sender] *
                            presale.cycleReleasePercentage) / 100);
                }
            } else {
                require(
                    presale.lastClaimedCycle[msg.sender] < cyclesPassed,
                    "Tokens for this cycle already claimed"
                );
                uint256 toVestTotal = (((cyclesPassed - 1) *
                    (presale.tokensPurchased[msg.sender])) / 100) *
                    presale.cycleReleasePercentage;
                toVest = toVestTotal;
            }

            uint256 tokensLeft = presale.tokensPurchased[msg.sender] -
                presale.tokensVested[msg.sender];
            if (toVest > tokensLeft) {
                toVest = tokensLeft;
            }

            require(toVest > 0, "No tokens to claim");
            presale.tokensVested[msg.sender] += toVest;
            presale.token.transfer(msg.sender, toVest);
            presale.lastClaimedCycle[msg.sender] = cyclesPassed;
        } else {
            uint256 tokensToClaim = presale.tokensPurchased[msg.sender] -
                presale.tokensVested[msg.sender];
            presale.tokensVested[msg.sender] += tokensToClaim;
            presale.token.transfer(msg.sender, tokensToClaim);
        }
    }

    function handleAfterSale(uint256 _presaleId) external {
        PresaleStruct storage presale = presales[_presaleId];

        require(
            msg.sender == presale.creator,
            "Only the presale creator can call"
        );
        require(block.timestamp > presale.endTime, "Presale has not ended yet");
        require(
            presale.moneyRaised >= presale.softCap,
            "Presale was unsuccessful"
        );
        require(!presale.burnedOrRefunded, "This action has already been done");

        presale.burnedOrRefunded = true;

        uint256 unsoldTokens = (presale.presaleRate * presale.hardCap) -
            presale.tokensSold;

        if (unsoldTokens != 0) {
            if (presale.burnOrRefund) {
                presale.token.transfer(presale.creator, unsoldTokens);
            } else {
                presale.token.transfer(
                    0x000000000000000000000000000000000000dEaD,
                    unsoldTokens
                );
            }
        }

        uint256 fundsToCollect = presale.moneyRaised -
            presale.devCommission -
            presale.affiliateCommissionAmount;
        require(fundsToCollect > 0, "No funds to collect");

        if (address(presale.purchaseToken) == address(0)) {
            (bool success, ) = payable(presale.creator).call{
                value: fundsToCollect
            }("");
            require(success, "Transfer failed");
        } else {
            presale.purchaseToken.transfer(presale.creator, fundsToCollect);
        }
    }

    function collectDevCommission(uint256 _presaleId) external onlyOwner {
        PresaleStruct storage presale = presales[_presaleId];

        require(block.timestamp > presale.endTime, "Presale has not ended yet");
        require(presale.moneyRaised >= presale.softCap, "SoftCap not reached");

        uint256 commission = presale.devCommission;
        presale.devCommission = 0;

        if (presale.devFeeInToken) {
            uint commisionInToken = presale.devCommissionInToken;
            presale.devCommissionInToken = 0;
            presale.token.transfer(owner(), commisionInToken);
        }

        if (address(presale.purchaseToken) == address(0)) {
            (bool success, ) = payable(owner()).call{value: commission}("");
            require(success, "Transfer failed");
        } else {
            presale.purchaseToken.transfer(owner(), commission);
        }
    }

    function collectAffiliateCommission(uint256 _presaleId) external {
        PresaleStruct storage presale = presales[_presaleId];

        require(block.timestamp > presale.endTime, "Presale has not ended yet");
        require(presale.moneyRaised >= presale.softCap, "SoftCap not reached");
        require(
            presale.affiliateCommission[msg.sender] != 0,
            "No Affiliate Commission"
        );

        uint256 commission = presale.affiliateCommission[msg.sender];
        presale.affiliateCommission[msg.sender] = 0;

        if (address(presale.purchaseToken) == address(0)) {
            (bool success, ) = payable(msg.sender).call{value: commission}("");
            require(success, "Transfer failed");
        } else {
            presale.purchaseToken.transfer(msg.sender, commission);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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