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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/**
    @title EternalOwnable
    @author iMe Lab
    @notice Ownable, but the owner cannot change
 */
abstract contract EternalOwnable is Context {
    error OwnershipIsMissing();

    address private immutable _theOwner;

    constructor(address owner) {
        _theOwner = owner;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function _checkOwner() internal view {
        if (_msgSender() != _theOwner) revert OwnershipIsMissing();
    }

    function _owner() internal view returns (address) {
        return _theOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICryptobox} from "./ICryptobox.sol";
import {Participation} from "./lib/Participation.sol";
import {Currency} from "./lib/Currency.sol";
import {EternalOwnable} from "./access/EternalOwnable.sol";

contract Cryptobox is ICryptobox, EternalOwnable {
    using Currency for address;

    uint32 private immutable _capacity;
    uint32 private _totalParticipated;
    bool private _active = true;
    address private immutable _signer;
    address private immutable _token;
    mapping(bytes32 => bool) private _participatedNames;
    mapping(address => bool) private _participatedAddresses;
    uint256 private immutable _prize;

    constructor(
        ICryptobox.Info memory blueprint,
        address signer,
        address owner
    ) EternalOwnable(owner) {
        require(signer != address(0));
        _token = blueprint.token;
        _prize = blueprint.prize;
        _capacity = blueprint.capacity;
        _signer = signer;
    }

    function info() external view override returns (ICryptobox.Info memory) {
        return ICryptobox.Info(_token, _capacity, _prize);
    }

    function isActive() external view override returns (bool) {
        return _active;
    }

    function participants() external view override returns (uint32) {
        return _totalParticipated;
    }

    function dispense(
        Participation.Participant memory candidate,
        Participation.Signature memory sig
    ) external override {
        require(_active);
        Participation.requireSigned(candidate, sig, address(this), _signer);
        _reward(candidate);
    }

    function dispenseMany(
        Participation.Participant[] memory candidates,
        Participation.Signature memory sig
    ) external override {
        require(candidates.length <= _candidatesLeft());
        require(_active);
        Participation.requireSigned(candidates, sig, address(this), _signer);
        _reward(candidates);
    }

    function stop() external onlyOwner {
        require(_active);
        _stop();
        _refund();
    }

    function participated(
        Participation.Participant memory participant
    ) external view override returns (bool) {
        return _participated(participant);
    }

    function _participated(
        Participation.Participant memory participant
    ) internal view returns (bool) {
        bool isAddressParticipated = _participatedAddresses[participant.addr];
        bool isNameParticipated = _participatedNames[participant.name];
        return isAddressParticipated || isNameParticipated;
    }

    function _reward(Participation.Participant memory candidate) private {
        _totalParticipated += 1;
        _tryToParticipate(candidate);
        if (_totalParticipated == _capacity) _finish();
        _token.transfer(candidate.addr, _prize);
    }

    function _reward(Participation.Participant[] memory candidates) private {
        _totalParticipated += uint32(candidates.length);
        if (_totalParticipated == _capacity) _finish();
        for (uint i = 0; i < candidates.length; i++)
            _tryToParticipate(candidates[i]);
        for (uint i = 0; i < candidates.length; i++)
            _token.transfer(candidates[i].addr, _prize);
    }

    function _tryToParticipate(
        Participation.Participant memory candidate
    ) private {
        require(!_participated(candidate));
        _participatedAddresses[candidate.addr] = true;
        _participatedNames[candidate.name] = true;
    }

    function _refund() private {
        _token.transfer(_owner(), _token.balanceOf(address(this)));
    }

    function _finish() private {
        _active = false;
        emit CryptoboxFinished();
    }

    function _stop() private {
        _active = false;
        emit CryptoboxStopped();
    }

    receive() external payable {
        require(_token == Currency.NATIVE);
        require(_active);
        require(address(this).balance == _tokensNeeded());
    }

    function _tokensNeeded() private view returns (uint256) {
        return _prize * _candidatesLeft();
    }

    function _candidatesLeft() private view returns (uint32) {
        return _capacity - _totalParticipated;
    }

    function version() external pure returns (uint8) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Currency} from "./lib/Currency.sol";
import {ICryptoboxFactory} from "./ICryptoboxFactory.sol";
import {ICryptobox} from "./ICryptobox.sol";
import {Cryptobox} from "./Cryptobox.sol";

contract CryptoboxFactory is Ownable, ICryptoboxFactory {
    using Currency for address;

    address private _feeToken;
    address private _feeDestination;
    uint256 private _participantFee;
    uint256 private _creationFee;
    uint32 private _minCapacity = 1;
    bool private _enabled = true;

    constructor() {
        _feeDestination = _msgSender();
    }

    function getFeeToken() external view override returns (address) {
        return _feeToken;
    }

    function setFeeToken(address token) external override onlyOwner {
        require(token != _feeToken);
        _feeToken = token;
        emit RulesChanged();
    }

    function getFeeDestination() external view override returns (address) {
        return _feeDestination;
    }

    function setFeeDestination(
        address destination
    ) external override onlyOwner {
        require(destination != address(0));
        require(destination != _feeDestination);
        _feeDestination = destination;
    }

    function getParticipantFee() external view override returns (uint256) {
        return _participantFee;
    }

    function setParticipantFee(uint256 fee) external override onlyOwner {
        require(fee != _participantFee);
        _participantFee = fee;
        emit RulesChanged();
    }

    function getCreationFee() external view override returns (uint256) {
        return _creationFee;
    }

    function setCreationFee(uint256 fee) external override onlyOwner {
        require(fee != _creationFee);
        _creationFee = fee;
        emit RulesChanged();
    }

    function getMinimalCapacity() external view override returns (uint32) {
        return _minCapacity;
    }

    function setMinimalCapacity(uint32 capacity) external override onlyOwner {
        require(capacity > 0);
        require(capacity != _minCapacity);
        _minCapacity = capacity;
        emit RulesChanged();
    }

    function isEnabled() external view override returns (bool) {
        return _enabled;
    }

    function enable() external override onlyOwner {
        require(!_enabled);
        _enabled = true;
        emit RulesChanged();
    }

    function disable() external override onlyOwner {
        require(_enabled);
        _enabled = false;
        emit RulesChanged();
    }

    function create(
        ICryptobox.Info memory blueprint,
        address signer
    ) external payable {
        _requireCanCreate(blueprint);
        Cryptobox cryptobox = _spawn(blueprint, signer);
        _collectFeesFor(blueprint);
        _fund(cryptobox);
    }

    function _requireCanCreate(ICryptobox.Info memory blueprint) private view {
        if (!_enabled) revert FactoryIsDisabled();
        if (blueprint.capacity < _minCapacity) revert NotEnoughParticipants();
    }

    function _collectFeesFor(ICryptobox.Info memory blueprint) private {
        uint256 fee = _creationFee + _participantFee * blueprint.capacity;
        _feeToken.take(_msgSender(), _feeDestination, fee);
    }

    function _spawn(
        ICryptobox.Info memory blueprint,
        address signer
    ) private returns (Cryptobox) {
        Cryptobox box = new Cryptobox(blueprint, signer, _msgSender());
        emit CryptoboxCreated(address(box));
        return box;
    }

    function _fund(Cryptobox box) private {
        ICryptobox.Info memory info = box.info();
        uint256 fund = info.capacity * info.prize;
        info.token.take(_msgSender(), address(box), fund);
        uint256 balance = info.token.balanceOf(address(box));
        if (balance < fund) revert CryptoboxFundingFailed();
    }

    function version() external pure returns (uint8) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Participation} from "./lib/Participation.sol";

interface ICryptobox {
    struct Info {
        address token;
        uint32 capacity;
        uint256 prize;
    }

    function info() external view returns (ICryptobox.Info memory);

    function isActive() external view returns (bool);

    function participants() external view returns (uint32);

    function participated(
        Participation.Participant calldata
    ) external view returns (bool);

    function dispense(
        Participation.Participant calldata,
        Participation.Signature calldata
    ) external;

    function dispenseMany(
        Participation.Participant[] calldata,
        Participation.Signature calldata
    ) external;

    function stop() external;

    event CryptoboxFinished();
    event CryptoboxStopped();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ICryptobox} from "./ICryptobox.sol";

/**
    @title ICryptoboxFactory 
    @author iMe Lab
    @notice Factory iMe Cryptoboxes
 */
interface ICryptoboxFactory {
    event RulesChanged();
    event CryptoboxCreated(address addr);

    error NotEnoughParticipants();
    error FactoryIsDisabled();
    error CryptoboxFundingFailed();

    function create(ICryptobox.Info memory, address) external payable;

    function getFeeToken() external view returns (address);

    function setFeeToken(address) external;

    function getFeeDestination() external view returns (address);

    function setFeeDestination(address) external;

    function getParticipantFee() external view returns (uint256);

    function setParticipantFee(uint256) external;

    function getCreationFee() external view returns (uint256);

    function setCreationFee(uint256) external;

    function getMinimalCapacity() external view returns (uint32);

    function setMinimalCapacity(uint32) external;

    function isEnabled() external view returns (bool);

    function enable() external;

    function disable() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
    @title Currency
    @author iMe Lab
    @notice Library for working with arbitrary crypto currencies
 */
library Currency {
    error CurrencyTransferFailed();

    address internal constant NATIVE = address(0);

    function balanceOf(
        address currency,
        address account
    ) internal view returns (uint256) {
        if (currency == NATIVE) return account.balance;

        return IERC20(currency).balanceOf(account);
    }

    function transfer(
        address currency,
        address account,
        uint256 amount
    ) internal {
        _safe(_transfer(currency, account, amount));
    }

    function take(
        address currency,
        address from,
        address to,
        uint256 amount
    ) internal {
        _safe(_take(currency, from, to, amount));
    }

    function _transfer(
        address currency,
        address account,
        uint256 amount
    ) private returns (bool) {
        if (currency == NATIVE) return payable(account).send(amount);

        return IERC20(currency).transfer(account, amount);
    }

    function _take(
        address currency,
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        if (currency == NATIVE) {
            // We expect to receive `amount` from `spender` via payable
            return payable(to).send(amount);
        }

        return IERC20(currency).transferFrom(from, to, amount);
    }

    function _safe(bool transferred) private pure {
        if (!transferred) revert CurrencyTransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
    @title Participation 
    @author iMe Lab
    @notice Library for working with centralized participation
 */
library Participation {
    string internal constant SIGNED_MSG_PREFIX =
        "\x19Ethereum Signed Message:\n32";
    error ParticipationNotSigned();

    struct Participant {
        address addr;
        bytes32 name;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function requireSigned(
        Participant memory participant,
        Signature memory sig,
        address issuer,
        address trustedSigner
    ) internal pure {
        bytes32 digest = _digestOf(participant, issuer);
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);

        if (signer != trustedSigner) revert ParticipationNotSigned();
    }

    function requireSigned(
        Participant[] memory participants,
        Signature memory sig,
        address issuer,
        address trustedSigner
    ) internal pure {
        bytes32 digest = _digestOf(participants, issuer);
        address signer = ecrecover(digest, sig.v, sig.r, sig.s);

        if (signer != trustedSigner) revert ParticipationNotSigned();
    }

    function _digestOf(
        Participant memory participant,
        address issuer
    ) private pure returns (bytes32) {
        bytes32 message = keccak256(
            abi.encodePacked(participant.addr, participant.name, issuer)
        );

        return keccak256(abi.encodePacked(SIGNED_MSG_PREFIX, message));
    }

    function _digestOf(
        Participant[] memory participants,
        address issuer
    ) private pure returns (bytes32) {
        bytes32 message = keccak256(abi.encodePacked(issuer, "Waterfall"));

        for (uint i = 0; i < participants.length; i++) {
            message = keccak256(
                abi.encodePacked(
                    participants[i].name,
                    message,
                    participants[i].addr
                )
            );
        }

        return keccak256(abi.encodePacked(SIGNED_MSG_PREFIX, message));
    }
}