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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// import "hardhat/console.sol";

contract Futuria is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter _tokenIdCounter;

    bool isTestnet = block.chainid == 80001;

    struct EarningsItem {
        address addr;
        uint256 earningsWithoutIndirectCommissions;
        uint256 indirectCommissions;
    }

    address public tokenAddress =
        isTestnet
            ? 0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832
            : 0xc2132D05D31c914a87C6611C10748AEb04B58e8F; // USDT
    address admin = 0x0D0095Ac3d4E5F01c6B625A971bA893b42E5AEf6;
    address defaultReferralAccount = 0x2198354afa0bCb24ddd0344d69D89a88B8876674;

    uint256 public subscriptionPercentage = 97;
    uint256 public matchingBonus = 10;
    uint256 public championBonus = 3;
    uint256 public minWeeklyTurnoverPerLeg = isTestnet ? 1 ether : 200 ether;
    uint256 public weekTurnover = 0;
    uint256 public globalCap = 53;
    uint256 public championBonusMinAmount = 2000 ether;

    uint256[] public directSalesPercentage = [20, 22, 25, 27, 30];
    uint256[] public binaryPercentage = [10, 12, 15, 17, 20];

    // User addresses
    address[] public addresses;
    mapping(address => bool) public hasAddress;

    // Volume
    mapping(address => uint256) public addressToDirectCustomersVolume;
    mapping(address => uint256) public addressToWeeklyDirectCustomersVolume;
    mapping(address => uint256) public addressToPurchases;
    mapping(address => uint256) public addressToWeeklyPurchases;
    mapping(address => uint256) public addressToEarnings;
    mapping(address => uint256) public addressToMinRank;
    uint256[] public minParity = [
        1500 ether,
        5000 ether,
        25000 ether,
        100000 ether
    ];
    uint256[] public salesToAchieveRank = [
        1500 ether,
        5000 ether,
        25000 ether,
        50000 ether
    ];

    // Extra bonus
    uint256[] public extraBonusMinAmount = [150 ether, 300 ether, 1500 ether];
    uint256[] public extraBonusPerc = [3, 5, 10];

    // Legs
    mapping(address => address) public addressToSponsor;
    mapping(address => address) public addressToLeg1Address;
    mapping(address => address) public addressToLeg2Address;
    mapping(address => bool) public addressToIsRightLegSelected;
    mapping(address => uint256) public addressToLeftTurnover;
    mapping(address => uint256) public addressToRightTurnover;
    mapping(address => uint256) public addressToLegPosition; // 1 for left, 2 for right

    // Price
    mapping(uint256 => uint256) public tokenIdToPrice;

    // Subscriptions
    mapping(address => uint256) public subscriberToTimestamp;
    mapping(address => uint256) public addressToPenalty;
    mapping(uint256 => uint256) public tokenIdToSubsLength;

    mapping(address => bool) public isFounder;
    uint256 public remainingFounders = 250;
    uint256 public founderBonusPercentage = 1;

    constructor() {
        saveAddressIfNeeded(defaultReferralAccount);
        saveAddressIfNeeded(admin);

        subscriberToTimestamp[defaultReferralAccount] =
            block.timestamp +
            9000 days;
        addFounderIfPossible(defaultReferralAccount);

        safeMint(1, admin, 400 ether, 365 days);
        safeMint(1, admin, 250 ether, 182 days);
        safeMint(1, admin, 60 ether, 30 days);
        safeMint(1, admin, 150 ether, 91 days);

        if (isTestnet) {
            safeMint(1, msg.sender, 1 ether, 30 days);
        }

        address NHTPGOA6 = 0xab41875E5C9Ec3d72c3EFf6d6e37BAc32a06e816;
        address SXZEWWRV = 0x33c3511f05f72624aa9c0cfC817966e3535A597A;
        address Twolions = 0x7d096F8E9C1ff08b7AE0EF7b0FA22CB0270763Cf;
        address Micetta = 0x9089dde89113552031b635939B65e36FA9C3b0a7;
        address SISIYQEN = 0xc0C3CE0C4791e573fFb978e951F55463aD0d4A30;
        address Eagle = 0x88c6c349458466b9b2e87A56e64FD59604B7f7C1;
        address superman65 = 0xdC446dcc8E9A35ee7Ac01ea35Dbd056b1d5ce978;
        address Icarino = 0xbd0E044D526FCec8A8a31510DB3431727da26F4E;
        address Dario2022 = 0x60E97738D3B3325fFbE53fBaA7e8bA2b32Ed4b1F;
        address Musina = 0x04885FDC5ff37Ed9E6703A02bc17E06627D58A81;
        address Elektra = 0xD5d0BC2Cc60Ca085f6E3962EA0ECB6E5Fe5b30f9;
        address Gladiatore66 = 0x9d4Dc2a438040336Be41f94E2FC9002D3B1b6703;
        address Tatina = 0x9f4A6E4c48ed9e409195718A7B8cF09BaAb3e05c;

        addressToIsRightLegSelected[NHTPGOA6] = true;

        address[24] memory addressList = [
            Eagle,
            address(0),
            SISIYQEN,
            0x30E46028A50853e215973ca368B1d9B0109310f6, //9Q2VH7AX
            NHTPGOA6,
            0xC45Ca52f499117EFd9AfDa391f9ea800CD56A5cb, // Ricdelco
            0xEc9228Cabaf4A35dD223629A0Ca18a6C8B20eD81, // SCK1AYMO
            0x4693c8dddb03fAFda20D24b468CAd74c56816A33, // BXA5AXBN
            SXZEWWRV,
            address(0),
            Twolions,
            0x7aBCBc97408daa9B7A698b4866d3027E0488c150, // 1FNSU0ML
            0x166e3BfbFEeF8Ae0daC3897bC789652A768019bF, // Z5OOXUS0
            0x26867b4b58005b8E9c62535f29a3B5fDaD1F7e0C, // SOR6ULJA
            0x4703C8aB372A9a795b02BC6a159ae63134B998c5, // APFFRFII
            0x166a6E5aB19b36E75915C5b8Df5BA65a34Cc4c48, // N06RKQUV
            0x3569dB61A67E8F766BA72b8e1C53AC7EA225ada3, // QVAQU9KD
            0x84a480C49D52d2A3e5787cE86Fd2E13583E2792F, // My Name
            0x2767f7e860bEa617C584584D616d5e9B32a6360C, // H7O2X2NZ
            Dario2022,
            Icarino,
            Musina,
            Elektra,
            0xf667E305Ca5c79648462d3566d842f45092bea20 // Myfox
        ];

        for (uint256 i; i < addressList.length; i++) {
            if (addressList[i] == address(0)) {
                addressToIsRightLegSelected[
                    defaultReferralAccount
                ] = !addressToIsRightLegSelected[defaultReferralAccount];
            } else if (addressList[i] == SXZEWWRV) {
                addToTreeOnlyAdmin(NHTPGOA6, addressList[i]);
            } else if (addressList[i] == Icarino) {
                addToTreeOnlyAdmin(Dario2022, addressList[i]);
            } else if (addressList[i] == Elektra) {
                addToTreeOnlyAdmin(Musina, addressList[i]);
            } else {
                addToTreeOnlyAdmin(defaultReferralAccount, addressList[i]);
            }
        }

        addressToIsRightLegSelected[Twolions] = true;
        addToTreeOnlyAdmin(Twolions, Micetta);

        addToTreeOnlyAdmin(Micetta, 0xeB6116008F28517aC27F17E3F8BD72416565D165); // Pepito64
        addToTreeOnlyAdmin(Micetta, 0xa84618B3DD8D6EbC98Eb18B50e78f1bd6B786F96); // full65
        addToTreeOnlyAdmin(Micetta, superman65);
        addressToIsRightLegSelected[Micetta] = true;
        addToTreeOnlyAdmin(Micetta, Gladiatore66);

        addToTreeOnlyAdmin(Gladiatore66, Tatina);
        addToTreeOnlyAdmin(
            Gladiatore66,
            0x8f5Ac48b4D34EdCB678d83680115B4B018C43188
        );
        addToTreeOnlyAdmin(
            Gladiatore66,
            0xf674181DE7c02Df2DbacCc6d14374698A6aC5191
        );
        addressToIsRightLegSelected[Gladiatore66] = true;
        addToTreeOnlyAdmin(
            Gladiatore66,
            0xd8e5669f092e84fC2b61Bf91F2df36BF5E640b6E // Clio
        );
        addToTreeOnlyAdmin(
            Gladiatore66,
            0x96E22c2708Aefc500648F0dd338091ACe963fbDD // Max300566
        );
    }

    modifier onlyAdmin() {
        require(isAdmin());
        _;
    }

    // View functions
    function checkIfActiveSubscription(
        address addr
    ) public view returns (bool) {
        return subscriberToTimestamp[addr] >= block.timestamp;
    }

    function allowanceToken(
        address owner,
        address spender
    ) public view returns (uint256) {
        return ERC20(tokenAddress).allowance(owner, spender);
    }

    function getTreeSum(
        address rootAddress,
        uint256 count
    ) public view virtual returns (uint256) {
        address leg1Address = addressToLeg1Address[rootAddress];
        address leg2Address = addressToLeg2Address[rootAddress];
        uint256 sum = addressToWeeklyPurchases[rootAddress];

        if (count > 800) {
            return sum;
        }

        if (leg1Address != address(0)) {
            sum += getTreeSum(leg1Address, count + 1);
        }

        if (leg2Address != address(0)) {
            sum += getTreeSum(leg2Address, count + 1);
        }

        return sum;
    }

    function hasMatchingBonus(address addr) public view returns (bool) {
        bool hasActiveSubs = checkIfActiveSubscription(addr);

        if (!hasActiveSubs || rankOf(addr) < 2) {
            return false;
        }

        return true;
    }

    function hasChampionBonus(address addr) public view returns (bool) {
        bool hasActiveSubs = checkIfActiveSubscription(addr);
        uint256 profits = addressToEarnings[addr];
        uint256 rank = rankOf(addr);

        if (!hasActiveSubs || profits < championBonusMinAmount || rank < 3) {
            return false;
        }

        return true;
    }

    function getChampionBonusAmount() public view returns (uint256) {
        return (weekTurnover * championBonus) / 100;
    }

    function getFoundersBonusAmount() public view returns (uint256) {
        return (weekTurnover * founderBonusPercentage) / 100;
    }

    function getDirectSalesPercentage(
        address addr
    ) public view returns (uint256) {
        return directSalesPercentage[rankOf(addr) - 1];
    }

    function getDirectCommissions(address addr) public view returns (uint256) {
        uint256 weeklyDirectCustomersVolume = addressToWeeklyDirectCustomersVolume[
                addr
            ];
        return
            (weeklyDirectCustomersVolume * getDirectSalesPercentage(addr)) /
            100;
    }

    function getIndirectCommissions(
        address addr
    ) public view returns (uint256) {
        bool hasActiveSubs = checkIfActiveSubscription(addr);
        uint256 parity = getParity(addr);

        if (!hasActiveSubs || parity < minWeeklyTurnoverPerLeg) {
            return 0;
        }

        uint256 rank = rankOf(addr);
        uint256 binaryPerc = binaryPercentage[rank - 1];
        uint256 binaryExtraBonus = getBinaryExtraBonus(addr);
        uint256 percentage = binaryExtraBonus + binaryPerc;

        return (parity * percentage) / 100;
    }

    function getWeeklyLegsTurnover(
        address rootAddress
    ) public view returns (uint256[] memory) {
        address leg1Address = addressToLeg1Address[rootAddress];
        address leg2Address = addressToLeg2Address[rootAddress];
        uint256[] memory weeklyLegsTurnover = new uint256[](2);

        weeklyLegsTurnover[0] =
            getTreeSum(leg1Address, 0) +
            addressToLeftTurnover[rootAddress];
        weeklyLegsTurnover[1] =
            getTreeSum(leg2Address, 0) +
            addressToRightTurnover[rootAddress];

        return weeklyLegsTurnover;
    }

    function getBinaryExtraBonus(address addr) public view returns (uint256) {
        uint256 weeklyVolume = addressToWeeklyDirectCustomersVolume[addr];

        if (weeklyVolume >= extraBonusMinAmount[2]) {
            return extraBonusPerc[2];
        } else if (weeklyVolume >= extraBonusMinAmount[1]) {
            return extraBonusPerc[1];
        } else if (weeklyVolume >= extraBonusMinAmount[0]) {
            return extraBonusPerc[0];
        }

        return 0;
    }

    function getParity(address addr) public view returns (uint256) {
        uint256[] memory weeklyLegsTurnover = getWeeklyLegsTurnover(addr);
        uint256 leftTurnover = weeklyLegsTurnover[0];
        uint256 rightTurnover = weeklyLegsTurnover[1];

        return leftTurnover >= rightTurnover ? rightTurnover : leftTurnover;
    }

    function rankOf(address addr) public view returns (uint256) {
        uint256 sales = addressToDirectCustomersVolume[addr];
        uint256 salesToAchieveRank2 = salesToAchieveRank[0];
        uint256 salesToAchieveRank3 = salesToAchieveRank[1];
        uint256 salesToAchieveRank4 = salesToAchieveRank[2];
        uint256 salesToAchieveRank5 = salesToAchieveRank[3];
        uint256 rankPenalty = addressToPenalty[addr];
        uint256 rank = 1;
        uint256 minRank = addressToMinRank[addr];
        uint256 parity = getParity(addr);

        if (sales >= salesToAchieveRank5 || parity >= minParity[3]) {
            rank = 5;
        } else if (sales >= salesToAchieveRank4 || parity >= minParity[2]) {
            rank = 4;
        } else if (sales >= salesToAchieveRank3 || parity >= minParity[1]) {
            rank = 3;
        } else if (
            sales >= salesToAchieveRank2 ||
            isFounder[addr] ||
            parity >= minParity[0]
        ) {
            rank = 2;
        }

        if (minRank > rank) {
            rank = minRank;
        }

        rank = rank - rankPenalty;

        if (rank < 1) {
            return 1;
        }

        return rank;
    }

    function claim() public payable {
        uint256 tokenAmountInWei = addressToEarnings[msg.sender];
        uint256 tokenBalance = ERC20(tokenAddress).balanceOf(address(this));

        require(tokenAmountInWei > 0, "0 amount");
        require(tokenBalance > 0, "No tokens");

        addressToEarnings[msg.sender] = 0;
        saveAddressIfNeeded(msg.sender);
        transferToken(tokenAmountInWei);
    }

    function updateSubscription(
        uint256 tokenId,
        uint256 price,
        uint256 subsLength
    ) external onlyAdmin {
        tokenIdToSubsLength[tokenId] = subsLength;
        tokenIdToPrice[tokenId] = price;
    }

    function subscribe(
        uint256 tokenId,
        address referralAddress
    ) external payable {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addToTreeIfNeeded(referralAddress);

        if (sponsor != address(0)) {
            updateDirectCustomersVolume(sponsor, volume);
        }

        subscriberToTimestamp[msg.sender] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        updatePurchases(msg.sender, volume);
        addFounderIfPossible(msg.sender);
        transferFromToken(msg.sender, address(this), subsPrice);
    }

    function subscribeOnlyAdmin(
        uint256 tokenId,
        address subscriber
    ) external onlyAdmin {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addressToSponsor[subscriber];

        if (sponsor != address(0)) {
            updateDirectCustomersVolume(sponsor, volume);
        }

        subscriberToTimestamp[subscriber] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        updatePurchases(subscriber, volume);
        addFounderIfPossible(subscriber);
    }

    function setSelectedLeg(
        bool isRightLegSelected,
        address referralAddress
    ) external payable {
        addressToIsRightLegSelected[msg.sender] = isRightLegSelected;
        saveAddressIfNeeded(msg.sender);
        addToTreeIfNeeded(referralAddress);
    }

    // Admin functions
    function setPercentages(
        uint256[] calldata _directSalesPercentage,
        uint256[] calldata _binaryPercentage,
        uint256[] calldata _salesToAchieveRank,
        uint256 _minWeeklyTurnoverPerLeg,
        uint256 _globalCap,
        uint256 _subscriptionPercentage,
        uint256 _matchingBonus,
        uint256 _championBonus
    ) external onlyAdmin {
        directSalesPercentage = _directSalesPercentage;
        binaryPercentage = _binaryPercentage;
        salesToAchieveRank = _salesToAchieveRank;
        championBonus = _championBonus;
        minWeeklyTurnoverPerLeg = _minWeeklyTurnoverPerLeg;
        globalCap = _globalCap;
        subscriptionPercentage = _subscriptionPercentage;
        matchingBonus = _matchingBonus;
    }

    function addFounderIfPossibleOnlyAdmin(address addr) external onlyAdmin {
        addFounderIfPossible(addr);
    }

    function addToTreeOnlyAdmin(
        address rootAddress,
        address newUser
    ) public onlyAdmin {
        bool isRightLegSelected = addressToIsRightLegSelected[rootAddress];
        addressToSponsor[newUser] = rootAddress;
        addToTree(rootAddress, newUser, isRightLegSelected, 0);
    }

    function safeMint(
        uint256 quantity,
        address to,
        uint256 price,
        uint256 subsLength
    ) public payable onlyAdmin {
        for (uint256 i; i < quantity; i++) {
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            tokenIdToPrice[tokenId] = price;
            tokenIdToSubsLength[tokenId] = subsLength;
        }

        saveAddressIfNeeded(to);
    }

    function setWeeklyEarnings(EarningsItem[] memory items) external onlyAdmin {
        for (uint i = 0; i < items.length; i++) {
            addressToEarnings[items[i].addr] += items[i]
                .earningsWithoutIndirectCommissions;
            setIndirectCommissions(items[i].addr, items[i].indirectCommissions);
        }

        resetWeek();
    }

    function setAddressToEarnings(
        address addr,
        uint256 earnings
    ) external onlyAdmin {
        addressToEarnings[addr] = earnings;
    }

    function setIndirectCommissionsOnlyAdmin(
        address addr,
        uint256 earnings
    ) external onlyAdmin {
        setIndirectCommissions(addr, earnings);
    }

    function stopSubscription(
        address addr,
        uint256 rankPenalty
    ) external onlyAdmin {
        subscriberToTimestamp[addr] = 0;
        setPenalty(addr, rankPenalty);
    }

    function setSubscriberToTimestamp(
        address addr,
        uint256 timestamp
    ) external onlyAdmin {
        subscriberToTimestamp[addr] = timestamp;
    }

    function setMinParity(uint256[] calldata _minParity) external onlyAdmin {
        minParity = _minParity;
    }

    function setChampionBonusMinAmount(
        uint256 _championBonusMinAmount
    ) external onlyAdmin {
        championBonusMinAmount = _championBonusMinAmount;
    }

    function setWeekTurnover(uint256 _weekTurnover) external onlyAdmin {
        weekTurnover = _weekTurnover;
    }

    function resetWeekOnlyAdmin() external onlyAdmin {
        resetWeek();
    }

    function renewSubscription(
        address addr,
        uint256 tokenId
    ) external onlyAdmin {
        uint256 subsPrice = tokenIdToPrice[tokenId];
        uint256 volume = (subsPrice * subscriptionPercentage) / 100;
        address sponsor = addressToSponsor[addr];

        weekTurnover += volume;
        subscriberToTimestamp[addr] =
            block.timestamp +
            tokenIdToSubsLength[tokenId];
        saveAddressIfNeeded(addr);
        updateDirectCustomersVolume(sponsor, volume);
        updatePurchases(addr, volume);
        transferFromToken(addr, address(this), subsPrice);
    }

    function setPenalty(address addr, uint256 rankPenalty) public onlyAdmin {
        addressToPenalty[addr] = rankPenalty;
        saveAddressIfNeeded(addr);
    }

    function updateDirectCustomersVolumeOnlyAdmin(
        address sponsor,
        uint256 amount
    ) external onlyAdmin {
        updateDirectCustomersVolume(sponsor, amount);
    }

    function setAddressToWeeklyPurchases(
        address addr,
        uint256 amountInWei
    ) external onlyAdmin {
        saveAddressIfNeeded(addr);
        addressToWeeklyPurchases[addr] = amountInWei;
    }

    function setLegs(
        address rootAddress,
        address leg1Address,
        address leg2Address
    ) external onlyAdmin {
        require(
            rootAddress != leg1Address && leg1Address != leg2Address,
            "invalid addr"
        );

        if (leg1Address != address(0)) {
            addressToLeg1Address[rootAddress] = leg1Address;
        }

        if (leg2Address != address(0)) {
            addressToLeg2Address[rootAddress] = leg2Address;
        }

        saveAddressIfNeeded(rootAddress);
        saveAddressIfNeeded(leg1Address);
        saveAddressIfNeeded(leg2Address);
    }

    function setWeeklyDirectCustomersVolume(
        address addr,
        uint256 amountInWei
    ) external onlyAdmin {
        saveAddressIfNeeded(addr);
        addressToWeeklyDirectCustomersVolume[addr] = amountInWei;
    }

    function setAddressToMinRank(
        address addr,
        uint256 rank
    ) external onlyAdmin {
        addressToMinRank[addr] = rank;
    }

    function setAddressToLeftTurnover(
        address addr,
        uint256 turnover
    ) external onlyAdmin {
        addressToLeftTurnover[addr] = turnover;
    }

    function setAddressToRightTurnover(
        address addr,
        uint256 turnover
    ) external onlyAdmin {
        addressToRightTurnover[addr] = turnover;
    }

    function setAddressToSponsor(
        address addr,
        address sponsor
    ) external onlyAdmin {
        addressToSponsor[addr] = sponsor;
    }

    function setAddressToLeg1Address(
        address addr1,
        address addr2
    ) external onlyAdmin {
        addressToLeg1Address[addr1] = addr2;
    }

    function setAddressToLeg2Address(
        address addr1,
        address addr2
    ) external onlyAdmin {
        addressToLeg2Address[addr1] = addr2;
    }

    function setExtraBonus(
        uint256[] calldata _extraBonusMinAmount,
        uint256[] calldata _extraBonusPerc
    ) external virtual onlyAdmin {
        extraBonusMinAmount = _extraBonusMinAmount;
        extraBonusPerc = _extraBonusPerc;
    }

    function setAdmin(address _admin) external virtual onlyAdmin {
        if (admin != _admin) {
            admin = _admin;
        }
    }

    function setDefaultReferralAccount(
        address _defaultReferralAccount
    ) external virtual onlyAdmin {
        defaultReferralAccount = _defaultReferralAccount;
    }

    function setFounderBonusPercentage(
        uint256 _founderBonusPercentage
    ) external virtual onlyAdmin {
        founderBonusPercentage = _founderBonusPercentage;
    }

    function updateTokenAddress(
        address _tokenAddress
    ) external virtual onlyAdmin {
        tokenAddress = _tokenAddress;
    }

    function withdrawMatic() external payable onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawToken(
        uint256 tokenAmountInWei
    ) external payable onlyAdmin {
        if (tokenAmountInWei > 0) {
            transferToken(tokenAmountInWei);
        }
    }

    function saveLegPositionOnlyAdmin(
        address newUser,
        uint256 leg
    ) external onlyAdmin {
        saveLegPosition(newUser, leg);
    }

    // Internal
    function transferToken(uint256 amount) internal {
        ERC20(tokenAddress).transfer(msg.sender, amount);
    }

    function isAdmin() internal view returns (bool) {
        return
            msg.sender == owner() ||
            msg.sender == admin ||
            msg.sender == defaultReferralAccount;
    }

    function addToTreeIfNeeded(
        address referralAddress
    ) internal returns (address) {
        bool isDefaultReferralAccount = msg.sender == defaultReferralAccount;
        address sponsor = addressToSponsor[msg.sender];

        if (!isDefaultReferralAccount) {
            if (referralAddress == address(0)) {
                referralAddress = defaultReferralAccount;
            }

            require(referralAddress != msg.sender, "invalid addr");

            if (sponsor == address(0)) {
                addressToSponsor[msg.sender] = referralAddress;
                addToTree(
                    referralAddress,
                    msg.sender,
                    addressToIsRightLegSelected[referralAddress],
                    0
                );

                return referralAddress;
            }
        }

        return sponsor;
    }

    function updatePurchases(address addr, uint256 volume) internal {
        saveAddressIfNeeded(addr);

        addressToPurchases[addr] += volume;
        addressToWeeklyPurchases[addr] += volume;
        weekTurnover += volume;
    }

    function resetWeek() internal {
        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];

            if (rankOf(addr) > addressToMinRank[addr]) {
                addressToMinRank[addr] = rankOf(addr);
            }
        }

        weekTurnover = 0;

        for (uint256 i; i < addresses.length; i++) {
            address addr = addresses[i];

            addressToWeeklyDirectCustomersVolume[addr] = 0;
            addressToWeeklyPurchases[addr] = 0;
        }
    }

    function setIndirectCommissions(address addr, uint256 earnings) internal {
        uint256[] memory weeklyLegsTurnover = getWeeklyLegsTurnover(addr);
        uint256 leftTurnover = weeklyLegsTurnover[0];
        uint256 rightTurnover = weeklyLegsTurnover[1];

        if (earnings == 0) {
            addressToLeftTurnover[addr] = leftTurnover;
            addressToRightTurnover[addr] = rightTurnover;
        } else if (leftTurnover >= rightTurnover) {
            addressToLeftTurnover[addr] = leftTurnover - rightTurnover;
            addressToRightTurnover[addr] = 0;
        } else {
            addressToLeftTurnover[addr] = 0;
            addressToRightTurnover[addr] = rightTurnover - leftTurnover;
        }

        addressToEarnings[addr] += earnings;
    }

    function saveLegPosition(address newUser, uint256 leg) internal {
        require(leg == 1 || leg == 2);
        addressToLegPosition[newUser] = leg;
    }

    function saveLegPositionIfNeeded(address newUser, uint256 leg) internal {
        if (addressToLegPosition[newUser] == 0) {
            saveLegPosition(newUser, leg);
        }
    }

    function saveLegData(
        address rootAddress,
        address newUser,
        uint256 leg
    ) internal {
        saveAddressIfNeeded(rootAddress);
        saveAddressIfNeeded(newUser);
        saveLegPositionIfNeeded(newUser, leg);
    }

    function addToTree(
        address rootAddress,
        address newUser,
        bool isRightLegSelected,
        uint256 count
    ) internal {
        address leftLegAddr = addressToLeg1Address[rootAddress];
        address rightLegAddr = addressToLeg2Address[rootAddress];
        uint256 leftLeg = 1;
        uint256 rightLeg = 2;

        if (count > 800) {
            return;
        }

        if (!isRightLegSelected) {
            if (leftLegAddr == address(0)) {
                saveLegData(rootAddress, newUser, leftLeg);
                addressToLeg1Address[rootAddress] = newUser;
            } else {
                // 2 legs occupied
                saveLegPositionIfNeeded(newUser, leftLeg);
                addToTree(leftLegAddr, newUser, isRightLegSelected, count + 1);
            }
        } else {
            if (rightLegAddr == address(0)) {
                saveLegData(rootAddress, newUser, rightLeg);
                addressToLeg2Address[rootAddress] = newUser;
            } else {
                // 2 legs occupied
                saveLegPositionIfNeeded(newUser, rightLeg);
                addToTree(rightLegAddr, newUser, isRightLegSelected, count + 1);
            }
        }
    }

    function addFounderIfPossible(address addr) internal {
        if (remainingFounders > 0) {
            isFounder[addr] = true;
            remainingFounders--;
        }
    }

    function transferFromToken(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(allowanceToken(sender, recipient) >= amount, "allowance");

        ERC20(tokenAddress).transferFrom(sender, recipient, amount);
    }

    function saveAddressIfNeeded(address addr) internal {
        if (!hasAddress[addr] && addr != address(0)) {
            hasAddress[addr] = true;
            addresses.push(addr);
        }
    }

    function updateDirectCustomersVolume(
        address sponsor,
        uint256 amount
    ) internal {
        saveAddressIfNeeded(sponsor);
        addressToDirectCustomersVolume[sponsor] += amount;
        addressToWeeklyDirectCustomersVolume[sponsor] += amount;
    }
}