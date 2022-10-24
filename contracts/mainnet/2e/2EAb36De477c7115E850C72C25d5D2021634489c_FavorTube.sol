// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC223/IERC223.sol";
import "./ERC223/IERC223Recipient.sol";
import "./TokenTax.sol";
import "./utils/Address.sol";
import "./LockBalance.sol";

contract FavorTube is IERC223Recipient, TokenTax, Ownable, LockBalance, ReentrancyGuard {

    struct PayInfo {
        address account;
        uint rate;
        uint amount;
    }

    event $subInfo(uint value, address sender, uint32 expire, PayInfo[3] subInfo);
    event $subscribe(address channel, address licensee, uint32 expire);
    event $setUserConfig(address channel, uint256 price, uint mode);

    struct UserConfig {
        uint256 price;
        uint mode;
    }

    mapping(address => UserConfig) _userConfig;
    mapping(address => bool) _isSetConfig;

    UserConfig public _defaultUserConfig;

    uint32 public subscribeBlock;

    address public immutable _token;

    constructor(uint8[5] memory taxRate, uint256 price, uint32 subscribeBlock_, address ERC223Token, uint interval) TokenTax(taxRate) LockBalance(interval) {
        require(Address.isContract(ERC223Token));

        _token = ERC223Token;

        subscribeBlock = subscribeBlock_;

        _defaultUserConfig = UserConfig(price, 0);
    }

    function setPeriodData(uint value) external override onlyOwner {
        _setPeriodData(value);
    }

    function exchange() external override nonReentrant {
        uint amount = exchangeableAmount();

        require(amount != 0, "Insufficient balance");

        _exchange(_msgSender(), amount);

        require(IERC223(_token).transfer(_msgSender(), amount), "Withdrawal Failure");
    }

    function userConfig() external view returns (UserConfig memory) {
        return userConfig(_msgSender());
    }

    function tokenReceived(address _sender, uint _value, bytes memory _data) external override {

        require(_msgSender() == _token, 'Incorrect contract address');

        address channel;
        address subscriber;
        address sharer;

        (channel, subscriber, sharer) = decodeCallbackData(_data);

        require(channel != address(0) && subscriber != address(0) && subscriber != sharer,"Address Error");

        UserConfig memory config = userConfig(channel);

        if (_value < config.price)
            revert("paid price is too low");


        bool isZeroAddress = sharer == address(0);

        uint8[3] memory computedTaxRate = getComputedTaxRate(isZeroAddress, taxRateMap[config.mode]);

        uint[3] memory computedAmount = [
        (computedTaxRate[0] * _value) / 100,
        (computedTaxRate[1] * _value) / 100,
        (computedTaxRate[2] * _value) / 100
        ];

        _lock(channel, computedAmount[0]);
        _lock(subscriber, computedAmount[1]);
        if (!isZeroAddress) _lock(sharer, computedAmount[2]);

        uint32 expire = computeExpire(subscribeBlock);

        emit $subscribe(channel, subscriber, expire);

        emit $subInfo(
            _value,
            _sender,
            expire,
            [PayInfo(channel, computedAmount[0], computedTaxRate[0]),
            PayInfo(subscriber, computedAmount[1], computedTaxRate[1]),
            PayInfo(sharer, computedAmount[2], computedTaxRate[2])]);
    }

    function getComputedTaxRate(bool isZeroAddress, uint8[5] memory taxRate) pure internal returns (uint8[3] memory){
        return [
        isZeroAddress ? taxRate[0] : taxRate[2],
        isZeroAddress ? taxRate[1] : taxRate[3],
        taxRate[4]
        ];
    }

    function setSubscribeBlock(uint32 subscribeBlock_) external onlyOwner {
        subscribeBlock = subscribeBlock_;
    }

    function setDefaultUserConfig(uint256 price, uint mode) external onlyOwner {
        _defaultUserConfig = UserConfig(price, mode);
    }

    function setUserConfig(uint256 price, uint mode) external {
        require(taxRateMap[mode].length != 0 && price >= 100, "mode does not exist");
        _userConfig[_msgSender()] = UserConfig(price, mode);
        _isSetConfig[_msgSender()] = true;

        emit $setUserConfig(_msgSender(), price, mode);
    }

    function userConfig(address account) internal view returns (UserConfig memory) {
        return _isSetConfig[account] ? _userConfig[account] : _defaultUserConfig;
    }

    function decodeCallbackData(bytes memory data) internal pure returns (address, address, address) {
        return abi.decode(data, (address, address, address));
    }

    function computeExpire(uint32 value) internal view returns (uint32) {
        uint result = uint(value) + block.number;

        if (result >= uint(type(uint32).max)) {
            return type(uint32).max;
        }

        return uint32(result);
    }

    function setTaxRate(uint mode, uint8[5] memory taxRate_) external override onlyOwner returns (bool success) {
        return _setTaxRate(mode, taxRate_);
    }

    function withdrawTax(address account, uint value) external override onlyOwner returns (bool success) {
        return transferToken(_token, account, value);
    }

    function transferToken(address token, address account, uint value) public onlyOwner returns (bool success){
        return IERC223(token).transfer(account, value);
    }

    function transferChain(address account) payable external onlyOwner {
        payable(account).transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TokenTax {

    mapping(uint => uint8[5]) taxRateMap;
    uint[] taxRateKey;

    constructor(uint8[5] memory taxRate_) {
        _setTaxRate(0, taxRate_);
    }

    function getTaxRate(uint mode) external view returns (uint8[5] memory) {
        return taxRateMap[mode];
    }

    function getTaxRateKey() external view returns (uint[] memory) {
        return taxRateKey;
    }

    function _setTaxRate(uint mode, uint8[5] memory taxRate_) internal returns (bool success) {
        taxRateMap[mode] = taxRate_;
        taxRateKey.push(mode);
        return true;
    }

    function setTaxRate(uint mode, uint8[5] memory newRate) external virtual returns (bool success);

    function withdrawTax(address account, uint value) external virtual returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract LockBalance {

    event $exchange(address addr, uint amount);

    struct PeriodData {
        uint startBlockNumber;
        uint periodTime;
        uint periodNumber;
    }

    struct Data {
        uint round;
        uint amount;
    }

    PeriodData public periodData;

    struct LockRound {
        Data last;
        Data current;
    }

    mapping(address => LockRound) lockBalance;
    mapping(address => uint) public lockTotal;

    constructor(uint interval){
        periodData = PeriodData(block.number, interval, 1);
    }

    function getCurrentRound() public view returns (uint){
        uint round;
        if (block.number < periodData.startBlockNumber) {
            round = periodData.periodNumber - 1;
        }
        else if (block.number == periodData.startBlockNumber) {
            round = periodData.periodNumber;
        }
        else {
            round = (block.number - periodData.startBlockNumber - 1) / periodData.periodTime + periodData.periodNumber;
        }
        return round;
    }

    function exchangeableAmount() public view returns (uint) {
        uint round = getCurrentRound();

        uint amount = lockTotal[msg.sender];

        LockRound memory data = lockBalance[msg.sender];

        if (round == data.current.round) {
            amount -= (data.current.amount + data.last.amount);
        } else if (round == data.current.round + 1) {
            amount -= data.current.amount;
        }

        return amount;
    }

    function _lock(address addr, uint amount) internal {
        if (amount > 0) {
            uint round = getCurrentRound();
            LockRound storage data = lockBalance[addr];

            if (data.current.round == round) {
                data.current.amount += amount;
            } else {
                data.last = data.current.round == round - 1 ? data.current : Data(round - 1, 0);
                data.current.round = round;
                data.current.amount = amount;
            }
            lockTotal[addr] += amount;
        }
    }

    function _setPeriodData(uint value) internal {
        if (block.number < periodData.startBlockNumber) {
            periodData.periodTime = value;
        } else {
            uint startBlockNumber = block.number + periodData.periodTime - (block.number - periodData.startBlockNumber) % periodData.periodTime;
            uint period = (startBlockNumber - periodData.startBlockNumber) / periodData.periodTime;

            //            uint period = (block.number - periodData.startBlockNumber + periodData.periodTime - 1) / periodData.periodTime;
            //            uint startBlockNumber = periodData.startBlockNumber + period * periodData.periodTime;
            periodData = PeriodData(startBlockNumber, value, period + periodData.periodNumber);
        }
    }

    function _exchange(address addr, uint amount) internal {
        lockTotal[addr] -= amount;
        emit $exchange(addr, amount);
    }

    function setPeriodData(uint value) external virtual;

    function exchange() external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title Contract that will work with ERC223 tokens.
 */

abstract contract IERC223Recipient {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction metadata.
     */
    function tokenReceived(address _from, uint _value, bytes memory _data) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../utils/Address.sol";
import "./IERC223Recipient.sol";

/**
 * @dev Interface of the ERC223 standard token as defined in the EIP.
 */

abstract contract IERC223 is ERC20 {

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    /**
      * @dev Transfers `value` tokens from `msg.sender` to `to` address with `data` parameter
     * and returns `true` on success.
     */
    function transfer(address to, uint amount, bytes calldata data) external virtual returns (bool success);

    /**
     * @dev See {ERC20-_transfer}. Allow pass some custom data to function.
     */
    function _transfer(address from, address to, uint256 amount, bytes memory data) internal virtual {
        _beforeTokenTransfer(from, to, amount, data);

        super._transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount, data);
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}. Allow pass some custom data to function.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev See {ERC20-_afterTokenTransfer}. Allow pass some custom data to function.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount,
        bytes memory data
    ) internal virtual {}
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