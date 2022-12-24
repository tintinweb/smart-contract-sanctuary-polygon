// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

import {OdeleToken} from "OdeleToken.sol";
import {Ownable} from "Ownable.sol"; 

import {Guard} from "Guard.sol";

/**
* @title Odele Treasury.
* @author Daccred.
* @dev  This contract handles the stakes and discount offers, 
*       w.r.t the amount of OdeleToken held by each caller.
*/
contract OdeleTreasury is Ownable, Guard {
    /// @dev OdeleToken Address.
    address public odeleToken;
    /// @dev Base platform percentage fee [0 < x <= 100].
    uint8 internal basePlatformPercentageFee;
    /// @dev Contract balance.
    uint256 ethBalance;

    /// @dev Emitted whenever the {makePayment} function is called.
    event Pay(address indexed, uint256 indexed);
    /// @dev Emitted whenever the {withdraw} function is called.
    event Withdraw(address indexed, uint256 indexed);

    /**
    * @dev  The deployer will set the Odele Token address and
    *       the base platform percentage fee for deployment.
    *
    * @notice `_basePlatformPercentageFee` runs from 0 - 100.
    *
    * @param _odeleToken                    Address of Odele Token.
    * @param _basePlatformPercentageFee     The base platform percentage.
    */
    constructor(
        address _odeleToken, 
        uint8 _basePlatformPercentageFee
    ) {
        /// @dev Ensure that OdeleToken address is not a zero address.
        require(_odeleToken != address(0), "0x0 OdeleToken!");
        /// @dev Set odele Token.
        odeleToken = _odeleToken;
        /// @dev Set base platform percentage fee.
        basePlatformPercentageFee = _basePlatformPercentageFee;
    }

    /// @dev Ensure that any money sent in to the contract is utilized.
    receive() external payable {
        /// @dev Increment the eth balance value of the contract.
        ethBalance += msg.value;
    }

    /// @dev Returns the calculated discount percentage rounded down.
    /// @return discountPercentage Calculated percentage.
    function promote() public view returns (uint256 discountPercentage) {
        /// @dev Require that the caller is not a zero address.
        require(msg.sender != address(0), "0x0 Caller!");
        /// @dev The cumulative balance of the caller.
        uint256 usersLockedTokens = OdeleToken(odeleToken).miningBalanceOf(msg.sender);
        
        /// @dev Return the discount percentage.
        discountPercentage = _calculatePercentage(usersLockedTokens);
    }

    /**
    * @dev  After discount has been calculated, this function will be called using
    *       the calculated `_expectedPrice` required to be paid by the caller 
    *       as a parameter. The `msg.value` sent by caller must be >= `_expectedPrice`.
    *       This emits the {Pay} event and returns true.
    *
    * @param `_expectedPrice` The price the caller is expected to pay.
    * 
    * @return bool.
    */
    function makePayment(uint256 _expectedPayment) public payable returns (bool) {
        /// @dev Require that the caller is not a zero address.
        require(msg.sender != address(0), "0x0 Caller!");
        /// @dev Require that the msg.value caller is >= the expected payment.
        require(msg.value >= _expectedPayment, "Payment < Expected.");

        /// @dev Increment the eth balance of the contract.
        ethBalance += msg.value;

        /// @dev Emit the {Pay} event.
        emit Pay(msg.sender, msg.value);
        /// @dev return true.
        return true;
    }

    /// @dev Allows the owner to withdraw an `_amount` of eth from the contract.
    /// @notice `ethbalance` must be >= `_amount`.
    /// @param _amount Amount to take.
    function withdraw(uint256 _amount) public onlyOwner {
        /// @dev Require that `ethbalance` must be >= `_amount`.
        require(ethBalance >= _amount, "Amount > Balance");

        /// @dev Decrement the eth balance of the contract by `_amount`.
        ethBalance -= _amount;

        /// @dev Send eth to owner wallet.
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        /// @dev Ensure that funds are sent.
        require(sent, "Funds not sent.");
        
        /// @dev emit the {Withdraw} event.
        emit Withdraw(msg.sender, _amount);
    }

    /**
    * @dev  This function calculates the percentage using the formular
    *       P * 10 ** 18 - (t/T * (P * 10 ** 18))
    *       Where:
    *           P = `basePlatformPercentageFee`
    *           t = Caller's cumulative tokens.
    *           T = Total promotion tokens in existence.
    *
    * @param _usersLockedTokens User's promotion token balance.
    */
    function _calculatePercentage(uint256 _usersLockedTokens) 
    private 
    view 
    returns (uint256 usersPercentageFee) 
    {
        /// @dev Total circulating amount of the promoter tokens.
        uint256 totalLockedTokens = OdeleToken(odeleToken).totalMiningSupply();
        /// @dev Cast platform percentage fee to uint256.
        uint256 _basePlatformPercentageFee = uint256(basePlatformPercentageFee);

        /// @dev Calculate using the formular.
        uint256 percentageDiscount = (_usersLockedTokens * (_basePlatformPercentageFee * (1e18))) / totalLockedTokens;
        usersPercentageFee = (_basePlatformPercentageFee * (1e18)) - percentageDiscount;
        // This will be divided by 1e18.
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

// Import modded ERC20 from utils.
import {ERC20} from "ERC20.sol";
import {Ownable} from "Ownable.sol"; 

import {Guard} from "Guard.sol";
import {AuthProxy} from "AuthProxy.sol";

/**
* @title Odele Token.
* @author Daccred.
* @dev A discount token for the Odele Product.
*/
contract OdeleToken is 
ERC20("OdeleToken", "OdeleTKN"),
Guard,
AuthProxy,
Ownable
{
    /**
    * @dev  Maximum token cap. This cannot be exceeded. This has been
    *       precalculated for all 3 token percentage distributions, as
    *       explained in the proposal document.
    */
    uint256 private constant CAP = 100_000_000_500_000_000 * 1e18;
    uint256 private constant MAX_TEAM_SUPPLY = (10 * CAP) / 100;    // 10%, for the team.
    uint256 private constant MAX_ECO_SUPPLY = (30 * CAP) / 100;     // 30%, for the ecosystem/growth.
    uint256 private constant MAX_MINING_SUPPLY = (60 * CAP) / 100;  // 60%, availabe for mining distributed to promoters.

    /// @dev Total number of tokens in circulation, held by team members.
    uint256 public circulatingTeamSupply;
    /// @dev Total number of tokens in circulation, distributed to the ecosystem.
    uint256 public circulatingEcoSupply;
    /// @dev Total number of tokens in circulation, distributed to promoters.
    uint256 public circulatingMiningSupply;

    mapping(address => uint256) private promoterBalances;

    /// @dev Returns the amount of token minted out to promoters.
    /// @return uint256 The circulating mining supply.
    function totalMiningSupply() public view returns (uint256) {
        /// @dev Return the total mining supply.
        return circulatingMiningSupply;
    }

    /// @dev Returns the amount of token minted out a promoter `_address`.
    /// @return uint256 The balance.
    function miningBalanceOf(address _address) public view returns (uint256) {
        /// @dev Require that the address is not a zero address.
        require(_address != address(0) ,"0x0 Address.");
        /// @dev Return the balance.
        return promoterBalances[_address];
    }

    /**
    * @dev  Mints `_amount` specifically to an address `_to` specified as a team member.
    *
    * @param _to        Address receiving token.
    * @param _amount    Number of tokens sent to `_to`.
    */
    function mintToTeam(
        address _to, 
        uint256 _amount
    ) public onlyOwner {
        /// @dev    Before mint, ensure that the max supply 
        ///         for the necessary distribution is not exceeded.
        _beforeMintTo(
            circulatingTeamSupply, 
            _amount,
            MAX_TEAM_SUPPLY
        );

        /// @dev Increment the relevant supply.
        circulatingTeamSupply += _amount;

        /// @dev Call the ERC20 `_mint()` function.
        _mint(_to, _amount);
    }

    /**
    * @dev  Mints `_amount` specifically to an address `_to` specified as part of the ecosystem.
    *
    * @param _to        Address receiving token.
    * @param _amount    Number of tokens sent to `_to`.
    */
    function mintToEcosystem(
        address _to, 
        uint256 _amount
    ) public onlyOwner {
        /// @dev    Before mint, ensure that the max supply 
        ///         for the necessary distribution is not exceeded.
        _beforeMintTo(
            circulatingEcoSupply, 
            _amount,
            MAX_ECO_SUPPLY
        );

        /// @dev Increment the relevant supply.
        circulatingEcoSupply += _amount;

        /// @dev Call the ERC20 `_mint()` function.
        _mint(_to, _amount);
    }

    /**
    * @dev  Mints `_amount` specifically to an address `_to` specified as a promoter.
    *
    * @param _to        Address receiving token.
    * @param _amount    Number of tokens sent to `_to`.
    */
    function mintToPromoter(
        address _to, 
        uint256 _amount
    ) public onlyOwner {
        /// @dev    Before mint, ensure that the max supply 
        ///         for the necessary distribution is not exceeded.
        _beforeMintTo(
            circulatingMiningSupply, 
            _amount,
            MAX_MINING_SUPPLY
        );

        /// @dev Increment the balance of the `_to`.
        promoterBalances[_to] += _amount;
        /// @dev Increment the relevant supply.
        circulatingMiningSupply += _amount;

        /// @dev Call the ERC20 `_mint()` function.
        _mint(_to, _amount);
    }

    /**
    * @dev  Before an `_amount` of token is minted to an address,
    *       it is first passed through this function to ensure that
    *       the limit of that distribution of token is not exceeded.
    *
    * @param _currentSupply Current circulating supply in the token distribution.
    * @param _amount        Amount of tokens to be minted to an address.
    * @param _maxSupply     Preset limit on token supply. 
    */
    function _beforeMintTo(
        uint256 _currentSupply,
        uint256 _amount,
        uint256 _maxSupply
    ) private view {
        /// @dev Revert if the maximum supply of the distribution is exceeded. 
        if ((_currentSupply + _amount) > _maxSupply) revert("Supply limit exceeded!");

        /// @dev Additional security to prevent oversupply.
        assert((totalSupply() + _amount) <= CAP);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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

    // To keep a permanent record of how much tokens a caller has.
    // This number is not affected by burning.
    mapping(address => uint256) private _cumulativeBalances;

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

    function cumulativeBalanceOf(address account) public view virtual override returns (uint256) {
        return _cumulativeBalances[account];
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
            _cumulativeBalances[to] += amount;
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
            _cumulativeBalances[account] += amount;
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
    * @dev  Mod: Returns the total amount of tokens ever owned by `account` since history.
    *       Token burnings will affect `balanceOf()`, but won't affect this.
    */
    function cumulativeBalanceOf(address account) external view returns (uint256);

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

import "IERC20.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    constructor() {
        _owner = msg.sender;
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
        require(owner() == _msgSender(), "Ownable_NotCaller");
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable_ZeroAddr");
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.14;

/**
* @title Guard Contract.
* @author Daccred.
*/
abstract contract Guard {
    bool locked;
    
    modifier noReentrance {
        require(!locked, "Locked");
        locked = true;
        _;
        locked = false;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

import { Authority } from "IAuthority.sol";

/// @notice a standalone Authority implementation for admin contracts
/// @dev AuthProxy can implement an NFT Gated authorization mechanism > independently
/// however in this case we will manually implenent the authorization scope based on mappings
contract AuthProxy is Authority {
    error UserNotAuthorized(address user);

    /// @dev Map of contract admins
    /// @notice a complex mapping of user => target contract => function signature
    mapping(address => mapping(address => mapping(bytes4 => bool))) private _admins;

    modifier admin() {
        /// @dev Require callers address is set to true.
        if (!_admins[msg.sender][address(this)][msg.sig] == true) {
            revert UserNotAuthorized(msg.sender);
        }
        _;
    }

    constructor() {
        ///@dev we authorize deployer to call addAdminUser
        _admins[msg.sender][address(this)][0x0281651f] = true;
    }

    function can(
        address user,
        address target,
        bytes4 func
    ) public view override returns (bool) {
        return _admins[user][target][func] || false;
        // revert UserNotAuthorized(user);
    }

    function addAdminUser(
        address user_,
        address target,
        bytes4 func
    ) public admin {
        /// @dev Require curator address is not a 0 address.
        require(user_ != address(0), "0x0 Curator");
        /// @dev Set map of the address to true;
        _admins[user_][target][func] = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

interface Authority {
    function can(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}