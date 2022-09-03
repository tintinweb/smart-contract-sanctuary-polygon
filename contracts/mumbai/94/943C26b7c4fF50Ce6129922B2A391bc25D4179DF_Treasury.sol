//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ITreasury.sol";
import "./TreasuryAdmin.sol";
import "../loanAsset/LoanAsset.sol";
import "../../util/SafeTransfers.sol";

contract Treasury is ITreasury, TreasuryAdmin, CommonModifiers, SafeTransfers {
    constructor() {
        admin = msg.sender;
    }

    /// @inheritdoc ITreasury
    function mintLoanAsset(
        address payable loanAsset,
        address tradeAsset,
        uint256 tradeAmount
    ) external payable override /* nonReentrant() */ returns (bool) {
        if (tradeAsset == address(0)) {
            if (msg.value == 0) revert ExpectedValue();
            if (msg.value != tradeAmount) revert UnexpectedValueDelta();
        }
        if (tradeAmount == 0) revert ExpectedTradeAmount();
        if (!supportedTradeAssets[loanAsset][tradeAsset]) revert PairNotSupported(loanAsset, tradeAsset);

        ERC20 _tradeAsset = ERC20(tradeAsset);
        uint8 tradeAssetDecimals = 18;
        if (tradeAsset != address(0)) tradeAssetDecimals = _tradeAsset.decimals();

        LoanAsset _loanAsset = LoanAsset(loanAsset);
        uint8 loanAssetDecimals = _loanAsset.decimals();

        uint256 exchangeAmount = (tradeAmount * 10**loanAssetDecimals) / 10**tradeAssetDecimals;
        uint256 mintAmount = exchangeAmount * 10**FACTOR_DECIMALS / localLoanAsset[loanAsset][tradeAsset].mintPrice;
        
        assetReserves[tradeAsset] += tradeAmount;
        if (tradeAsset != address(0) && !_tradeAsset.transferFrom(msg.sender, address(this), tradeAmount)) revert TransferFailed(msg.sender, address(this));

        _loanAsset.mint(msg.sender, mintAmount);

        return true;
    }

    /// @inheritdoc ITreasury
    function burnLoanAsset(
        address payable loanAsset,
        address tradeAsset,
        uint256 burnAmount
    ) external override /* nonReentrant() */ returns (bool) {
        if (burnAmount == 0) revert ExpectedTradeAmount();
        if (!supportedTradeAssets[loanAsset][tradeAsset]) revert PairNotSupported(loanAsset, tradeAsset);

        ERC20 _tradeAsset = ERC20(tradeAsset);
        uint8 tradeAssetDecimals = 18;
        if (tradeAsset != address(0)) tradeAssetDecimals = _tradeAsset.decimals();

        LoanAsset _loanAsset = LoanAsset(loanAsset);
        uint8 loanAssetDecimals = _loanAsset.decimals();

        uint256 exchangeAmount = burnAmount * 10**tradeAssetDecimals / 10**loanAssetDecimals;
        uint256 tradeAmount = exchangeAmount * 10**FACTOR_DECIMALS / localLoanAsset[loanAsset][tradeAsset].burnPrice;

        uint256 tradeAssetReserves;
        if (tradeAsset == address(0)) tradeAssetReserves = address(this).balance;
        else tradeAssetReserves = _tradeAsset.balanceOf(address(this));

        if (assetReserves[tradeAsset] > tradeAssetReserves) revert UnexpectedDelta();
        if (tradeAssetReserves < tradeAmount) revert NotEnoughBalance(tradeAsset, address(this));

        assetReserves[tradeAsset] = tradeAssetReserves - tradeAmount;
        _loanAsset.burnFrom(msg.sender, burnAmount);

        if (tradeAsset == address(0)) payable(msg.sender).transfer(tradeAmount);
        else if (!_tradeAsset.transfer(msg.sender, tradeAmount)) revert TransferFailed(msg.sender, address(this));

        return true;
    }

    /*
     * NOTE: This is only used for test cases:
     *     'should transfer in a given loanAsset asset for a given supported tradeAsset (networkToken)'
     *     'admin should be able to withdraw deposited tradeAsset (networkToken)'
    **/
    receive() external payable {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/*
    Tokens in the treasury are divided between three buckets: reserves, insurance, and surplus.

    Reserve tokens accrue from the result of arbitrageurs buying PUSD from the treasury.

    Insurance tokens are held in for the event where a liquidation does not fully cover an outstanding loan.
    If an incomplete liquidation occurs, insurance tokens are transferred to reserves to back the newly outstanding PUSD
    When sufficient insurance tokens are accrued, newly recieved tokens are diverted to surplus.

    Surplus tokens are all remaining tokens that aren't backing or insuring ourstanding Loan Asset.
    When profit accrues, the value of surplus tokens is distributed to xPrime stakers.
*/

abstract contract ITreasury {
    /**
     * @notice Deposit Loan Asset from the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the Loan Asset peg
     * @param loanAsset address of the loanAsset to mint to the user
     * @param tradeAsset address of the trade asset the given user will pay
     * @param tradeAmount Amount of the tradeAsset the user will pay
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function mintLoanAsset(
        address payable loanAsset,
        address tradeAsset,
        uint256 tradeAmount
    ) external payable virtual returns (bool);

    /**
     * @notice Burn Loan Asset via the treasury at the guaranteed exchange rate
     * @dev This is called by an arbitrageur seeking to stabilize the loanAssets peg
     * @param loanAsset address of the loanAsset to burn from the user
     * @param tradeAsset Address of the trade asset the given user will receive
     * @param burnAmount Amount of loanAsset to burn from the user
     * @return (bool, true if completed successfully) Note: should change this so a real error is returned
     */
    function burnLoanAsset(
        address payable loanAsset,
        address tradeAsset,
        uint256 burnAmount
    ) external virtual returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TreasuryModifiers.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract TreasuryAdmin is TreasuryModifiers {
    function withdraw(
        address assetAddress,
        uint256 amount,
        address recipient
    ) external onlyAdmin() /* nonReentrant() */ {
        if (amount == 0) revert ExpectedWithdrawAmount();

        uint256 _assetReserves;
        if (assetAddress == address(0)) _assetReserves = address(this).balance;
        else _assetReserves = ERC20(assetAddress).balanceOf(address(this));

        if (assetReserves[assetAddress] > _assetReserves) revert UnexpectedDelta();
        if (_assetReserves < amount) revert NotEnoughBalance(assetAddress, address(this));

        assetReserves[assetAddress] = _assetReserves - amount;

        if (assetAddress == address(0)) payable(recipient).transfer(amount);
        else if (!ERC20(assetAddress).transfer(recipient, amount)) revert TransferFailed(recipient, address(this));
    }

    function supportLoanAsset(
        address _localLoanAsset,
        address _tradeAsset,
        uint256 _mintPrice,
        uint256 _burnPrice
    ) external onlyAdmin() {
        unchecked {
            /* Min: 1e8 */
            /* Max: 105e6 */
            if (_mintPrice - 1e8 > 5e6) revert ParamOutOfBounds();
            if (_burnPrice - 1e8 > 5e6) revert ParamOutOfBounds();
        }
        supportedTradeAssets[_localLoanAsset][_tradeAsset] = true;
        localLoanAsset[_localLoanAsset][_tradeAsset].mintPrice = _mintPrice;
        localLoanAsset[_localLoanAsset][_tradeAsset].burnPrice = _burnPrice;
    }

    function removeTradeAssetToLoanAsset(
        address _localLoanAsset,
        address _tradeAsset
    ) external onlyAdmin() {
        supportedTradeAssets[_localLoanAsset][_tradeAsset] = false;
        localLoanAsset[_localLoanAsset][_tradeAsset].mintPrice = 0;
        localLoanAsset[_localLoanAsset][_tradeAsset].burnPrice = 0;
    }

    function modifyTradeAsset(
        address _localLoanAsset,
        address _tradeAsset,
        uint256 _mintPrice,
        uint256 _burnPrice
    ) external onlyAdmin() {
        unchecked {
            /* Min: 1e8 */
            /* Max: 105e6 */
            if (_mintPrice - 1e8 > 5e6) revert ParamOutOfBounds();
            if (_burnPrice - 1e8 > 5e6) revert ParamOutOfBounds();
        }
        if (_mintPrice != 0) localLoanAsset[_localLoanAsset][_tradeAsset].mintPrice = _mintPrice;
        if (_burnPrice != 0) localLoanAsset[_localLoanAsset][_tradeAsset].burnPrice = _burnPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../../middleLayer/interfaces/IMiddleLayer.sol";
import "../../interfaces/IHelper.sol";
import "./LoanAssetStorage.sol";
import "./LoanAssetMessageHandler.sol";
import "./LoanAssetAdmin.sol";

contract LoanAsset is LoanAssetAdmin, LoanAssetMessageHandler {
    constructor(
        string memory _tknName,
        string memory _tknSymbol,
        uint8 __decimals
    ) ERC20(_tknName, _tknSymbol) {
        if (bytes(_tknName).length == 0) revert NameExpected();
        if (bytes(_tknSymbol).length == 0) revert SymbolExpected();

        admin = msg.sender;
        _decimals = __decimals;
    }

    function mint(
        address to,
        uint256 amount
    ) external override onlyMintAuth() {
        if (amount == 0) revert ExpectedMintAmount();

        _mint(to, amount);
    }

    /**
     * @notice Burn tokens on the local chain and mint on the destination chain
     * @dev Accrues interest whether or not the operation succeeds, unless reverted
     * @param dstChainId Destination chain to mint
     * @param receiver Wallet that is sending/burning loanAsset
     * @param amount Amount to burn locally/mint on the destination chain
     */
    function sendTokensToChain(
        address receiver,
        address route,
        uint256 dstChainId,
        uint256 amount
    ) external payable {
        if (paused) revert TransferPaused();
        if (amount == 0) revert ExpectedTransferAmount();

        _sendTokensToChain(receiver, route, dstChainId, amount);
    }

    fallback() external payable {}

    receive() payable external {}
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CommonErrors.sol";

abstract contract SafeTransfers is CommonErrors {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
     */
    // slither-disable-next-line assembly
    function _doTransferIn(
        address underlying,
        uint256 amount
    ) internal virtual returns (uint256) {
        if (underlying == address(0)) {
            if (msg.value < amount) revert TransferFailed(msg.sender, address(this));
            return amount;
        }
        IERC20 token = IERC20(underlying);
        uint256 balanceBefore = IERC20(underlying).balanceOf(address(this));
        
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transferFrom(msg.sender, address(this), amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(msg.sender, address(this));

        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(underlying).balanceOf(address(this));

        return balanceAfter - balanceBefore; // underflow already checked above, just subtract
    }

    /**
    * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
    *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
    *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
    *      it is >= amount, this should not revert in normal conditions.
    *
    *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
    *            See here: https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
    */
    // slither-disable-next-line assembly
    function _doTransferOut(
        address to,
        address underlying,
        uint256 amount
    ) internal virtual {
        if (underlying == address(0)) {
            if (address(this).balance < amount) revert TransferFailed(address(this), to);
            payable(to).transfer(amount);
            return;
        }
        IERC20 token = IERC20(underlying);
        // ? We are checking the transfer, but since we are doing so in an assembly block
        // ? Slither does not pick up on that and results in a hit
        // slither-disable-next-line unchecked-transfer
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := 1 // set success to true
            }
            case 32 {
                // This is a complaint ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                success := 0
            }
        }
        if (!success) revert TransferFailed(address(this), msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./TreasuryStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract TreasuryModifiers is TreasuryStorage, CommonErrors {
    modifier onlyAdmin() {
        if (msg.sender != admin) revert OnlyAdmin();
        _;
    }
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

abstract contract TreasuryStorage {
    address public admin;

    uint256 public constant FACTOR_DECIMALS = 8;

    /*
     * Mapping of addesss of accepted stablecoin to amount held in reserve
     */
    mapping(address => uint256) public assetReserves;

    // Addresses of stablecoins that can be swapped for localLoanAsset at the guaranteed rate
    mapping(address /* localLoanAsset */ => mapping(address /* tradeAsset */ => bool)) public supportedTradeAssets;

    struct LoanMarket {
        uint256 mintPrice; // Exchange rate at which a trader can mint given loanAsset via the treasury. Should be more than 1
        uint256 burnPrice; // Exchange rate at which a trader can burn given loanAsset via the treasury. Should be less than 1
    }

    mapping(address /* localLoanAsset */ => mapping(address /* tradeAsset */ => LoanMarket)) public localLoanAsset;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract CommonErrors {
    error AccountNoAssets(address account);
    error AddressExpected();
    error AlreadyInitialized();
    error EccMessageAlreadyProcessed();
    error EccFailedToValidate();
    error ExpectedMintAmount();
    error ExpectedBridgeAmount();
    error ExpectedBorrowAmount();
    error ExpectedWithdrawAmount();
    error ExpectedRepayAmount();
    error ExpectedTradeAmount();
    error ExpectedDepositAmount();
    error ExpectedTransferAmount();
    error InsufficientReserves();
    error InvalidPayload();
    error InvalidPrice();
    error InvalidPrecision();
    error InvalidSelector();
    error MarketExists();
    error LoanMarketIsListed(bool status);
    error MarketIsPaused();
    error MarketNotListed();
    error MsgDataExpected();
    error NameExpected();
    error NothingToWithdraw();
    error NotInMarket(uint256 chainId, address token);
    error OnlyAdmin();
    error OnlyAuth();
    error OnlyGateway();
    error OnlyMiddleLayer();
    error OnlyMintAuth();
    error OnlyRoute();
    error OnlyRouter();
    error OnlyMasterState();
    error ParamOutOfBounds();
    error RouteExists();
    error Reentrancy();
    error EnterLoanMarketFailed();
    error EnterCollMarketFailed();
    error ExitLoanMarketFailed();
    error ExitCollMarketFailed();
    error RepayTooMuch(uint256 repayAmount, uint256 maxAmount);
    error WithdrawTooMuch();
    error NotEnoughBalance(address token, address who);
    error LiquidateDisallowed();
    error SeizeTooMuch();
    error SymbolExpected();
    error RouteNotSupported(address route);
    error MiddleLayerPaused();
    error PairNotSupported(address loanAsset, address tradeAsset);
    error TransferFailed(address from, address dest);
    error TransferPaused();
    error UnknownRevert();
    error UnexpectedValueDelta();
    error ExpectedValue();
    error UnexpectedDelta();
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract IMiddleLayer {
    /**
     * @notice routes and encodes messages for you
     * @param _params - abi.encode() of the struct related to the selector, used to generate _payload
     * all params starting with '_' are directly sent to the 'send()' function
     */
    function msend(
        uint256 _dstChainId,
        bytes memory _params,
        address payable _refundAddress,
        address _fallbackAddress,
        bool _shouldPayGas
    ) external payable virtual;

    function mreceive(
        uint256 _srcChainId,
        bytes memory _payload
    ) external virtual;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

interface IHelper {
    enum Selector {
        MASTER_DEPOSIT,
        MASTER_WITHDRAW_ALLOWED,
        FB_WITHDRAW,
        MASTER_REPAY,
        MASTER_BORROW_ALLOWED,
        FB_BORROW,
        SATELLITE_LIQUIDATE_BORROW,
        LOAN_ASSET_BRIDGE
    }

    // !!!!
    // @dev
    // an artificial uint256 param for metadata should be added
    // after packing the payload
    // metadata can be generated via call to ecc.preRegMsg()

    struct MDeposit {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_DEPOSIT
        address user;
        address pToken;
        uint256 exchangeRate;
        uint256 depositAmount;
    }

    struct MWithdrawAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_WITHDRAW_ALLOWED
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct FBWithdraw {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_WITHDRAW
        address pToken;
        address user;
        uint256 withdrawAmount;
        uint256 exchangeRate;
    }

    struct MRepay {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_REPAY
        address borrower;
        uint256 amountRepaid;
        address loanMarketAsset;
    }

    struct MBorrowAllowed {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.MASTER_BORROW_ALLOWED
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct FBBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.FB_BORROW
        address user;
        uint256 borrowAmount;
        address loanMarketAsset;
    }

    struct SLiquidateBorrow {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.SATELLITE_LIQUIDATE_BORROW
        address borrower;
        address liquidator;
        uint256 seizeTokens;
        address pToken;
    }


    struct LoanAssetBridge {
        uint256 metadata; // LEAVE ZERO
        Selector selector; // = Selector.LOAN_ASSET_BRIDGE
        address minter;
        bytes32 loanAssetNameHash;
        uint256 amount;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../middleLayer/interfaces/IMiddleLayer.sol";

abstract contract LoanAssetStorage {

    /**
     * @notice Administrator for this contract
     */
    address public admin;

    /**
     * @notice Underlying asset for this contract
     */
    address public underlyingAsset;

    /**
     * @notice Underlying chain id for this contract
     */
    uint256 public underlyingChainId;
    
    /**
     * @notice Indicates whether the loanAsset is currently bridgeable
     */
    bool internal paused;

    /**
     * @notice Synthetic Asset Decimals
     */
    uint8 internal _decimals;

    /**
     * @notice MiddleLayer Interface
     */
    IMiddleLayer internal middleLayer;

    /**
     * @notice Mapping of minting permissions
     */    
    mapping(address /* facilitator */ => bool /* isAuth */) public mintAuth;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./LoanAssetStorage.sol";
import "./LoanAssetAdmin.sol";
import "../../interfaces/IHelper.sol";
import "../../util/CommonModifiers.sol";

abstract contract LoanAssetMessageHandler is
    LoanAssetStorage,
    LoanAssetAdmin,
    ERC20Burnable,
    CommonModifiers
{

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // slither-disable-next-line assembly
    function _sendTokensToChain(
        address receiver,
        address route,
        uint256 _dstChainId,
        uint256 amount
    ) internal {
        // burn senders loanAsset locally
        _burn(msg.sender, amount);

        bytes memory payload = abi.encode(
            IHelper.LoanAssetBridge({
                metadata: uint256(0),
                selector: IHelper.Selector.LOAN_ASSET_BRIDGE,
                minter: receiver,
                loanAssetNameHash: keccak256(abi.encode(this.symbol())),
                amount: amount
            })
        );

        middleLayer.msend{ value: msg.value }(
            _dstChainId,
            payload,
            payable(receiver), // refund address
            route,
            true
        );

        emit SentToChain(receiver, _dstChainId, amount);
    }

    function mintFromChain(
        IHelper.LoanAssetBridge memory params,
        uint256 srcChain
    ) external onlyMid() {
        _mint(params.minter, params.amount);

        emit ReceiveFromChain(params.minter, srcChain, params.amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/ILoanAsset.sol";
import "./LoanAssetModifiers.sol";
import "./LoanAssetEvents.sol";

abstract contract LoanAssetAdmin is ILoanAsset, LoanAssetModifiers, LoanAssetEvents {
    
    function pauseSendTokens(
        bool newPauseStatus
    ) external onlyAdmin() {
        emit Paused(paused, newPauseStatus);

        paused = newPauseStatus;
    }

    function setMiddleLayer(
        address newMiddleLayer
    ) external onlyAdmin() {
        if (newMiddleLayer == address(0)) revert AddressExpected();

        emit SetMiddleLayer(address(middleLayer), newMiddleLayer);

        middleLayer = IMiddleLayer(newMiddleLayer);
    }

    function changeMintAuth(
        address minter,
        bool isAuth
    ) external onlyAdmin() {
        mintAuth[minter] = isAuth;

        emit ChangeMintAuth(minter, isAuth);
    }

    function changeAdmin(
        address newAdmin
    ) external onlyAdmin() {
        if (newAdmin == address(0)) revert AddressExpected();
        
        emit ChangeAdmin(admin, newAdmin);
        
        admin = newAdmin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
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
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./CommonErrors.sol";

abstract contract CommonModifiers is CommonErrors {

    /**
    * @dev Guard variable for re-entrancy checks
    */
    bool internal entered;

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    */
    modifier nonReentrant() {
        if (entered) revert Reentrancy();
        entered = true;
        _;
        entered = false; // get a gas-refund post-Istanbul
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface ILoanAsset {
    function mint(address to, uint256 amount) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./LoanAssetStorage.sol";
import "../../util/CommonErrors.sol";

abstract contract LoanAssetModifiers is LoanAssetStorage, CommonErrors {

    modifier onlyMintAuth() {
        if (!mintAuth[msg.sender]) revert OnlyMintAuth();
        _;
    }

    modifier onlyAdmin() {
        if(msg.sender != admin) revert OnlyAdmin();
        _;
    }

    modifier onlyMid() {
        if (msg.sender != address(middleLayer)) revert OnlyMiddleLayer();
        _;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

abstract contract LoanAssetEvents {

    /*** User Events ***/

    /**
     * @notice Event emitted when LoanAsset is sent cross-chain
     */
    event SentToChain(
        address toAddress,
        uint256 destChainId,
        uint256 amount
    );

    /**
     * @notice Event emitted when LoanAsset is received cross-chain
     */
    event ReceiveFromChain(
        address toAddress,
        uint256 srcChainId,
        uint256 amount
    );

    /*** Admin Events ***/

    event Paused(
        bool previousStatus,
        bool newStatus
    );

    event SetMiddleLayer(
        address oldMiddleLayer,
        address newMiddleLayer
    );

    event ChangeMintAuth(
        address minter,
        bool auth
    );

    event ChangeAdmin(
        address oldAdmin,
        address newAdmin
    );
}