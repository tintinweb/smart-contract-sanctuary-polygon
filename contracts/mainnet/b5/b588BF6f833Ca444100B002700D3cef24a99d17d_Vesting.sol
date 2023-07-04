// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/core/Vesting.sol
pragma solidity >= 0.8.17;

// OpenZeppelin dependencies
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IVotes } from "@openzeppelin/contracts/governance/utils/IVotes.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Errors } from "../lib/Errors.sol";
import { VestingState, VestingSchedule } from "../lib/Types.sol";
import { Modifiers } from "../modifiers/Vesting.sol";

/**
 * @title Vesting
 * @author DAOBox | (@pythonpete32)
 * @dev This contract enables vesting of tokens over a certain period of time. It is upgradeable and protected against
 * reentrancy attacks.
 *      The contract allows an admin to initialize the vesting schedule and the beneficiary of the vested tokens. Once
 * the vesting starts, the beneficiary
 *      can claim the releasable tokens at any time. If the vesting is revocable, the admin can revoke the remaining
 * tokens and send them to a specified address.
 *      The beneficiary can also delegate their voting power to another address.
 */
contract Vesting is ReentrancyGuard, Modifiers {
    /// @notice The token being vested
    IERC20 private _token;

    /// @notice The vesting state
    VestingState private _state;

    /// @notice The beneficiary of the vested tokens
    address private _beneficiary;

    /// @notice The admin address
    address private _admin;

    /**
     * @dev Initializes the vesting contract with the provided parameters.
     *      The admin, beneficiary, token, and vesting schedule are all set during initialization.
     *      Additionally, voting power for the vested tokens is delegated to the beneficiary.
     *
     * @param admin_ The address of the admin
     * @param beneficiary_ The address of the beneficiary
     * @param token_ The address of the token
     * @param schedule_ The vesting schedule
     */
    constructor(
        address admin_,
        address beneficiary_,
        IERC20 token_,
        VestingSchedule memory schedule_,
        uint256 amountTotal_
    ) {
        _admin = admin_;

        _token = token_;
        _beneficiary = beneficiary_;
        _state = VestingState(schedule_, amountTotal_, 0, false);
    }

    /**
     * @dev Revokes the vesting schedule, if it is revocable.
     *      Any tokens that are vested but not yet released are sent to the beneficiary,
     *      and the remaining tokens are transferred to the specified address.
     *
     * @param revokeTo The address to send the remaining tokens to
     */
    function revoke(address revokeTo) external validateRevoke(_state, _admin) {
        if (!_state.schedule.revocable) revert Errors.VestingScheduleNotRevocable();
        uint256 vestedAmount = computeReleasableAmount();
        if (vestedAmount > 0) release(vestedAmount);
        uint256 unreleased = _state.amountTotal - _state.released;
        _token.transfer(revokeTo, unreleased);
        _state.revoked = true;
    }

    /**
     * @dev Releases a specified amount of tokens to the beneficiary.
     *      The amount of tokens to be released must be less than or equal to the releasable amount.
     *
     * @param amount The amount of tokens to release
     */
    function release(uint256 amount) public validateRelease(amount, computeReleasableAmount(), _state) {
        _state.released += amount;

        _token.transfer(_beneficiary, amount);
    }

    /**
     * @dev Transfers the vesting schedule to a new beneficiary.
     *
     * @param newBeneficiary_ The address of the new beneficiary
     */
    function transferVesting(address newBeneficiary_) external onlyBeneficiary(_beneficiary) {
        _beneficiary = newBeneficiary_;
    }

    /**
     * @dev Returns the token being vested.
     *
     * @return The token
     */
    function getToken() external view returns (IERC20) {
        return _token;
    }

    /**
     * @dev Returns the vesting state.
     *
     * @return The vesting state
     */
    function getState() external view returns (VestingState memory) {
        return _state;
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner if they revoke vesting
     *
     * @return The withdrawable amount
     */

    function getWithdrawableAmount() public view returns (uint256) {
        return _token.balanceOf(address(this)) - computeReleasableAmount();
    }

    /**
     * @dev Computes the amount of tokens that can be released to the beneficiary.
     *      The releasable amount is dependent on the vesting schedule and the current time.
     *
     * @return The releasable amount
     */
    function computeReleasableAmount() public view returns (uint256) {
        // If the current time is before the cliff, no tokens are releasable.
        if ((block.timestamp < _state.schedule.start + _state.schedule.cliff) || _state.revoked) {
            return 0;
        }
        // If the current time is after the vesting period, all tokens are releasable,
        // minus the amount already released.
        else if (block.timestamp >= _state.schedule.start + _state.schedule.duration) {
            return _state.amountTotal - _state.released;
        }
        // Otherwise, some tokens are releasable.
        else {
            // Compute the number of full vesting periods that have elapsed.
            uint256 timeFromStart = block.timestamp - _state.schedule.start;
            // Compute the amount of tokens that are vested.
            uint256 vestedAmount = (_state.amountTotal * timeFromStart) / _state.schedule.duration;
            // Subtract the amount already released and return.
            return vestedAmount - _state.released;
        }
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/interfaces/IBondedToken.sol
pragma solidity >=0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title IBonded Token
 * @author DAOBox | (@pythonpete32)
 * @dev
 */
interface IBondedToken is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/interfaces/IBondingCurve.sol
pragma solidity >=0.8.17;

/**
 * @title IBondingCurve
 * @author DAOBox | (@pythonpete32)
 * @dev This interface defines the necessary methods for implementing a bonding curve.
 *      Bonding curves are price functions used for automated market makers.
 *      This specific interface is used to calculate rewards for minting and refunds for burning continuous tokens.
 */
interface IBondingCurve {
    /**
     * @notice Calculates the amount of continuous tokens that can be minted for a given reserve token amount.
     * @dev Implements the bonding curve formula to calculate the mint reward.
     * @param depositAmount The amount of reserve tokens to be provided for minting.
     * @param continuousSupply The current supply of continuous tokens.
     * @param reserveBalance The current balance of reserve tokens in the contract.
     * @param reserveRatio The reserve ratio, represented in ppm (parts per million), ranging from 1 to 1,000,000.
     * @return The amount of continuous tokens that can be minted.
     */
    function getContinuousMintReward(
        uint256 depositAmount,
        uint256 continuousSupply,
        uint256 reserveBalance,
        uint32 reserveRatio
    )
        external
        view
        returns (uint256);

    /**
     * @notice Calculates the amount of reserve tokens that can be refunded for a given amount of continuous tokens.
     * @dev Implements the bonding curve formula to calculate the burn refund.
     * @param sellAmount The amount of continuous tokens to be burned.
     * @param continuousSupply The current supply of continuous tokens.
     * @param reserveBalance The current balance of reserve tokens in the contract.
     * @param reserveRatio The reserve ratio, represented in ppm (parts per million), ranging from 1 to 1,000,000.
     * @return The amount of reserve tokens that can be refunded.
     */
    function getContinuousBurnRefund(
        uint256 sellAmount,
        uint256 continuousSupply,
        uint256 reserveBalance,
        uint32 reserveRatio
    )
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */
pragma solidity ^0.8.0;

import { CurveParameters } from "../lib/Types.sol";

/**
 * @title IMarketMaker
 * @author Utrecht University
 * @notice This interface is an abstraction of MarketMaker, so the contract implementation can be changed at a later date.
 */
interface IMarketMaker {
    function hatch(uint256 initialSupply, address hatchTo) external;
    function getCurveParameters() external view returns (CurveParameters memory);
    function setGovernance(bytes32 what, bytes memory value) external;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/lib/Errors.sol
pragma solidity >=0.8.17;

library Errors {
    /// @notice Error thrown when the market is already open
    error TradingAlreadyOpened();

    /// @notice Error thrown when the initial reserve for the token contract is zero.
    error InitialReserveCannotBeZero();

    /// @notice Error thrown when the funding rate provided is greater than 10000 (100%).
    /// @param fundingRate The value of the funding rate provided.
    error FundingRateError(uint16 fundingRate);

    /// @notice Error thrown when the exit fee provided is greater than 5000 (50%).
    /// @param exitFee The value of the exit fee provided.
    error ExitFeeError(uint16 exitFee);

    /// @notice Error thrown when the initial supply for the token contract is zero.
    error InitialSupplyCannotBeZero();
    
    /// @notice Error thrown when the funding amount for the token contract is higher than it's balance.
    error FundingAmountHigherThanBalance();

    /// @notice Error thrown when the owner of the contract tries to mint tokens continuously.
    error OwnerCanNotContinuousMint();
    
    /// @notice Error thrown when the caller would receive less tokens then they specified to recieve at least.
    error WouldRecieveLessThanMinRecieve();

    /// @notice Error thrown when the owner of the contract tries to burn tokens continuously.
    error OwnerCanNotContinuousBurn();

    /// @notice Error thrown when the deposit amount provided is zero.
    error DepositAmountCannotBeZero();

    /// @notice Error thrown when the burn amount provided is zero.
    error BurnAmountCannotBeZero();

    /// @notice Error thrown when the reserve balance is less than the amount requested to burn.
    /// @param requested The amount of tokens requested to burn.
    /// @param available The available balance in the reserve.
    error InsufficientReserve(uint256 requested, uint256 available);

    /// @notice Error thrown when the balance of the sender is less than the amount requested to burn.
    /// @param sender The address of the sender.
    /// @param balance The balance of the sender.
    /// @param amount The amount requested to burn.
    error InsufficentBalance(address sender, uint256 balance, uint256 amount);

    /// @notice Error thrown when a function that requires ownership is called by an address other than the owner.
    /// @param caller The address of the caller.
    /// @param owner The address of the owner.
    error OnlyOwner(address caller, address owner);

    /// @notice Error thrown when a transfer of ether fails.
    /// @param recipient The address of the recipient.
    /// @param amount The amount of ether to transfer.
    error TransferFailed(address recipient, uint256 amount);

    /// @notice Error thrown when an invalid governance parameter is set.
    /// @param what The invalid governance parameter.
    error InvalidGovernanceParameter(bytes32 what);

    /// @notice Error thrown when addresses and values provided are not equal.
    /// @param addresses The number of addresses provided.
    /// @param values The number of values provided.
    error AddressesAmountMismatch(uint256 addresses, uint256 values);

    error AddressCannotBeZero();

    error InvalidPPMValue(uint32 value);

    error HatchingNotStarted();

    error HatchingAlreadyStarted();

    error HatchNotOpen();

    error VestingScheduleNotInitialized();

    error VestingScheduleRevoked();

    error VestingScheduleNotRevocable();

    error OnlyBeneficiary(address caller, address beneficiary);

    error NotEnoughVestedTokens(uint256 requested, uint256 available);

    error DurationCannotBeZero();

    error SlicePeriodCannotBeZero();

    error DurationCannotBeLessThanCliff();

    error ContributionWindowClosed();

    error MaxContributionReached();

    error HatchNotCanceled();

    error NoContribution();

    error NotEnoughRaised();

    error HatchOngoing();

    error MinRaiseMet();
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/lib/Types.sol
pragma solidity >=0.8.17;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IBondedToken } from "../interfaces/IBondedToken.sol";
import { IBondingCurve } from "../interfaces/IBondingCurve.sol";
import { IMarketMaker } from "../interfaces/IMarketMaker.sol";

/// @notice This struct holds the key parameters that define a bonding curve for a token.
/// @dev These parameters can be updated over time to change the behavior of the bonding curve.
struct CurveParameters {
    /// @notice  fraction of buy funds that go to the DAO.
    /// @dev This value is represented in  fraction (in PPM)
    /// The funds collected here could be used for various purposes like development, marketing, etc., depending on the
    /// DAO's decisions.
    uint32 theta;
    /// @notice  fraction of sell funds that are redistributed to the Pool.
    /// @dev This value is represented in fraction (in PPM)
    /// This "friction" is used to discourage burning and maintain stability in the token's price.
    uint32 friction;
    /// @notice The reserve ratio of the bonding curve, represented in parts per million (ppm), ranging from 1 to
    /// 1,000,000.
    /// @dev The reserve ratio corresponds to different formulas in the bonding curve:
    ///      - 1/3 corresponds to y = multiple * x^2 (exponential curve)
    ///      - 1/2 corresponds to y = multiple * x (linear curve)
    ///      - 2/3 corresponds to y = multiple * x^(1/2) (square root curve)
    /// The reserve ratio determines the price sensitivity of the token to changes in supply.
    uint32 reserveRatio;
    /// @notice The implementation of the curve.
    /// @dev This is the interface of the bonding curve contract.
    /// Different implementations can be used to change the behavior of the curve, such as linear, exponential, etc.
    IBondingCurve formula;
}

struct VestingSchedule {
    // cliff period in seconds
    uint256 cliff;
    // start time of the vesting period
    uint256 start;
    // duration of the vesting period in seconds
    uint256 duration;
    // whether or not the vesting is revocable
    bool revocable;
}

struct VestingState {
    VestingSchedule schedule;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // amount of tokens released
    uint256 released;
    // whether or not the vesting has been revoked
    bool revoked;
}

enum HatchStatus {
    OPEN,
    HATCHED,
    CANCELED
}

struct HatchParameters {
    // External token contract (Stablecurrency e.g. DAI).
    IERC20 externalToken;
    IBondedToken bondedToken;
    IMarketMaker pool;
    uint256 initialPrice;
    uint256 minimumRaise;
    uint256 maximumRaise;
    // Time (in seconds) by which the curve must be hatched since initialization.
    uint256 hatchDeadline;
}

struct HatchState {
    HatchParameters params;
    HatchStatus status;
    uint256 raised;
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

// https://github.com/DAObox/liquid-protocol/blob/main/src/modifiers/Vesting.sol
pragma solidity >=0.8.17;

import { Errors } from "../lib/Errors.sol";
import { VestingState, VestingSchedule } from "../lib/Types.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Modifiers {
    /**
     * @dev This modifier checks if the vesting schedule is not revoked.
     *      It reverts if the vesting schedule is revoked.
     */
    modifier onlyIfVestingScheduleNotRevoked(VestingState memory state) {
        if (state.revoked) revert Errors.VestingScheduleRevoked();
        _;
    }

    /**
     * @dev This modifier checks if the caller is the owner and if the vesting schedule is revocable and not already
     * revoked.
     *      It reverts if the caller is not the owner, the vesting schedule is not revocable, or the vesting schedule is
     * already revoked.
     *
     * @param state The vesting state
     * @param owner The owner's address
     */
    modifier validateRevoke(VestingState memory state, address owner) {
        if (msg.sender != owner) revert Errors.OnlyOwner(msg.sender, owner);
        if (!state.schedule.revocable) revert Errors.VestingScheduleNotRevocable();
        if (state.revoked) revert Errors.VestingScheduleRevoked();
        _;
    }

    /**
     * @dev This modifier checks if the caller is the beneficiary.
     *      It reverts if the caller is not the beneficiary.
     *
     * @param beneficiary The beneficiary's address
     */
    modifier onlyBeneficiary(address beneficiary) {
        if (msg.sender != beneficiary) revert Errors.OnlyBeneficiary(msg.sender, beneficiary);
        _;
    }

    /**
     * @dev This modifier checks if the vesting schedule is not revoked, and if the requested amount is
     * less than or equal to the releasable amount.
     *      It reverts if the vesting schedule is not initialized or revoked, or if the requested amount is greater than
     * the releasable amount.
     *
     * @param requested The requested amount
     * @param releasable The releasable amount
     * @param state The vesting state
     */
    modifier validateRelease(uint256 requested, uint256 releasable, VestingState memory state) {
        if (state.revoked) revert Errors.VestingScheduleRevoked();
        if (requested > releasable) {
            revert Errors.NotEnoughVestedTokens({ requested: requested, available: releasable });
        }
        _;
    }

    /**
     * @dev This modifier checks if the beneficiary and token addresses are not the zero address,
     *      if the duration and slice period of the vesting schedule are not zero,
     *      if the duration is not less than the cliff,
     *      if the total amount of the vesting schedule is not greater than the token balance of this contract.
     *      It reverts if any of these conditions are not met.
     *
     * @param beneficiary The beneficiary's address
     * @param token The token's address
     * @param schedule The vesting schedule
     */
    modifier validateInitialize(address beneficiary, IERC20 token, VestingSchedule memory schedule, uint256 amountTotal) {
        if (schedule.duration == 0) revert Errors.DurationCannotBeZero();
        if (schedule.duration < schedule.cliff) revert Errors.DurationCannotBeLessThanCliff();
        if (amountTotal > token.balanceOf(address(this))) {
            revert Errors.InsufficientReserve({
                requested: amountTotal,
                available: token.balanceOf(address(this))
            });
        }
        _;
    }
}