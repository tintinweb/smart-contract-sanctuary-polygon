// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISWIX.sol";
import "./interfaces/ISwixEcosystem.sol";

import "./abstracts/SwixContract.sol";

contract SwixToken is
    ERC20,
    ISWIX,
    SwixContract
{
    /* =====================================================
                          CONSTRUCTOR
     ===================================================== */

    constructor(ISwixEcosystem setEcosystem)
        ERC20("Swix", "SWIX")
        SwixContract(setEcosystem)
    {}


    /* =====================================================
                        USER FUNCTIONS
     ===================================================== */

    function burn(uint256 amount)
        external
        override
    {
        _burn(msg.sender, amount);
    }

    // TODO verify access control
    function burnFrom(address account, uint256 amount)
        external
        override
    {
        _burnFrom(account, amount);
    }


    /* =====================================================
                        TOKENBACK FUNCTIONS
     ===================================================== */

    function mint(address account, uint256 amount)
        external
        override
        onlyTokenback
    {
        _mint(account, amount);
    }


    /* =====================================================
                        INTERNAL FUNCTIONS
     ===================================================== */

    function _burnFrom(address account, uint256 amount)
        internal
    {
        require(allowance(account, msg.sender) > amount, "ERC20: burn amount exceeds allowance");

        uint256 decreasedAllowance_ = allowance(account, msg.sender) - amount;

        _approve(account, msg.sender, decreasedAllowance_);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISWIX is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
interface ISwixEcosystem is IAccessControlEnumerable {

    function currentEcosystem() external returns (ISwixEcosystem);
    function initialize() external;
    function ecosystemInitialized() external returns (bool);
    function updateGovernance(address newGovernance) external;
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function checkRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "../interfaces/ISWIX.sol";
import "../interfaces/ITokenback.sol";
import "../interfaces/ISwixEcosystem.sol";
import "../interfaces/IBookingManager.sol";
import "../interfaces/ICancelPolicyManager.sol";
import "../interfaces/IRevenueSplitCalculator.sol";

import "../abstracts/SwixRoles.sol";

abstract contract SwixContract is
    SwixRoles
{
    
    /* =====================================================
                        STATE VARIABLES
     ===================================================== */

    /// Stores address of current Ecosystem
    ISwixEcosystem public ecosystem;

    /// Marks if the contract has been initialized
    bool public initialized;
    /// Timestamp when the ecosystem addreses were updated last time
    uint256 public lastUpdated;


    /* =====================================================
                      CONTRACT MODIFIERS
     ===================================================== */

    modifier onlySwix() {
        ecosystem.checkRole(SWIX_TOKEN_CONTRACT, msg.sender);
        _;
    }

    modifier onlyLeaseAgreement() {
        ecosystem.checkRole(LEASE_AGREEMENT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCity() {
        ecosystem.checkRole(CITY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyBookingManager() {
        ecosystem.checkRole(BOOKING_MANAGER_CONTRACT, msg.sender);
        _;
    }

    modifier onlyCancelPolicy() {
        ecosystem.checkRole(CANCEL_POLICY_CONTRACT, msg.sender);
        _;
    }

    modifier onlyRevenueSplit() {
        ecosystem.checkRole(REVENUE_SPLIT_CONTRACT, msg.sender);
        _;
    }

    modifier onlyTokenback() {
        ecosystem.checkRole(TOKENBACK_CONTRACT, msg.sender);
        _;
    }

    /* =====================================================
                        ROLE MODIFIERS
     ===================================================== */

    modifier onlyGovernance() {
        ecosystem.checkRole(GOVERNANCE_ROLE, msg.sender);
        _;
    }

    modifier onlyLeaseManager() {
        ecosystem.checkRole(LEASE_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyLeasePolicy() {
        ecosystem.checkRole(LEASE_POLICY_ROLE, msg.sender);
        _;
    }

    modifier onlyCostManager() {
        ecosystem.checkRole(COST_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyCancelPolicyManager() {
        ecosystem.checkRole(CANCEL_POLICY_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyContractManager() {
        ecosystem.checkRole(CONTRACT_MANAGER_ROLE, msg.sender);
        _;
    }

    modifier onlyBookingMaster() {
        ecosystem.checkRole(BOOKING_MASTER_ROLE, msg.sender);
        _;
    }

    modifier onlyGovernanceOrContractManager() {
        require(ecosystem.hasRole(GOVERNANCE_ROLE, msg.sender) || ecosystem.hasRole(CONTRACT_MANAGER_ROLE, msg.sender));
        _;
    }

    modifier ecosystemInitialized() {
        require(ecosystem.ecosystemInitialized());
        _;
    }
    

    /* =====================================================
                        CONSTRUCTOR
     ===================================================== */

    constructor(ISwixEcosystem setSwixEcosystem) {
        ecosystem = setSwixEcosystem.currentEcosystem();
        emit EcosystemUpdated(ecosystem);
    }


    /* =====================================================
                        GOVERNOR FUNCTIONS
     ===================================================== */

    function updateEcosystem()
        external
        onlyContractManager
    {
        ecosystem = ecosystem.currentEcosystem();
        require(ecosystem.ecosystemInitialized());

        lastUpdated = block.timestamp;

        emit EcosystemUpdated(ecosystem);
    }

    
    /* =====================================================
                        VIEW FUNCTIONS
    ===================================================== */

    /// Return currently used SwixToken contract
    function _swixToken()
        internal
        view
        returns (ISWIX)
    {
        return ISWIX(ecosystem.getRoleMember(SWIX_TOKEN_CONTRACT, 0));
    }

    /// Return currently used DAI contract
    function _stablecoinToken()
        internal
        view
        returns (IERC20)
    {
        return IERC20(ecosystem.getRoleMember(STABLECOIN_TOKEN_CONTRACT, 0));
    }

    /// Return BookingManager contract
    function _bookingManager()
        internal
        view
        returns (IBookingManager)
    {
        return IBookingManager(ecosystem.getRoleMember(BOOKING_MANAGER_CONTRACT, 0));
    }
    
    /// Return currently used CancelPolicyManager contract
    function _cancelPolicyManager()
        internal
        view
        returns (ICancelPolicyManager)
    {
        return ICancelPolicyManager(ecosystem.getRoleMember(CANCEL_POLICY_CONTRACT, 0));
    }


    /// Return currently used RevenueSplitCalculator contract
    function _revenueSplitCalculator()
        internal
        view
        returns (IRevenueSplitCalculator)
    {
        return IRevenueSplitCalculator(ecosystem.getRoleMember(REVENUE_SPLIT_CONTRACT, 0));
    }
    
    /// return tokenback contract
    function _tokenback()
        internal
        view
        returns (ITokenback)
    {
        return ITokenback(ecosystem.getRoleMember(TOKENBACK_CONTRACT, 0));
    }

    /// return DAO address
    function _dao()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(DAO_ROLE, 0);
    }

    /// return expenseWallet address
    function _expenseWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(EXPENSE_WALLET_ROLE, 0);
    }

    /// return expenseWallet address
    function _refundWallet()
        internal
        view
        returns (address)
    {
        return ecosystem.getRoleMember(REFUND_WALLET_ROLE, 0);
    }


    /* =====================================================
                            EVENTS
     ===================================================== */

    event EcosystemUpdated(ISwixEcosystem indexed ecosystem);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ITokenback {
    function tokenback(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IBooking.sol";
import "./ISwixCity.sol";

interface IBookingManager is IBooking {
    function book(
        ISwixCity city,
        uint256 leaseIndex,
        uint256[] memory nights,
        uint256 cancelPolicy
    ) external;
    function cancel(uint256 bookingIndex) external;
    function claimTokenback(uint256 bookingIndex) external;
    function getBookingIndex(ISwixCity city, uint256 leaseIndex, uint256 startNight) external returns (uint256);

    /* =====================================================
                          EVENTS
    ===================================================== */
    
    event Book(
        address indexed city,
        uint256 indexed leaseIndex,
        uint256 startNight,
        uint256 endNight,
        uint256 bookingIndex,
        Booking booking
    );
    event Cancel(uint256 indexed bookingIndex);
    event ClaimTokenback(uint256 indexed bookingIndex);
    event BookingIndexUpdated(uint256 indexed newBookingIndex, uint256 indexed oldBoookingIndex);
    event ReleaseFunds(uint256 indexed bookingIndex);
    event Reject(uint256 indexed bookingIndex);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

interface ICancelPolicyManager {

    function getCancelTimes(uint256 policyIndex, uint256 start)
        external
        returns (uint256, uint256);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./IFinancialParams.sol";

interface IRevenueSplitCalculator is IFinancialParams {


    function getProfitRates(FinancialParams memory params, uint256 amount) external returns (FinancialParams memory, uint256 );

}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

abstract contract SwixRoles {
    /* =====================================================
                            CONTRACTS
     ===================================================== */
    /// All contracts within Swix Ecosystem are tracked here
    
    /// SWIX Token contract
    bytes32 constant public SWIX_TOKEN_CONTRACT         = keccak256("SWIX_TOKEN_CONTRACT");
    /// DAI Token contract
    bytes32 constant public STABLECOIN_TOKEN_CONTRACT   = keccak256("STABLECOIN_TOKEN_CONTRACT");

    /// Booking Manager. This contract is responsible for reserving, storing and cancelling bookings.
    bytes32 constant public BOOKING_MANAGER_CONTRACT    = keccak256("BOOKING_MANAGER_CONTRACT");
    /// Swix City. Each contract represents a city in which Swix is operating as a Real World Business.
    bytes32 constant public CITY_CONTRACT               = keccak256("CITY_CONTRACT");
    /// Lease Agreements. Each contract represents a property.
    bytes32 constant public LEASE_AGREEMENT_CONTRACT    = keccak256("LEASE_AGREEMENT_CONTRACT");

    /// Cancellation Policy. This contract calculates refund deadlines based on given policy parameters.
    bytes32 constant public CANCEL_POLICY_CONTRACT      = keccak256("CANCEL_POLICY_CONTRACT");
    /// Revenue Split Calculator. This contract directs the split of revenue throughout Swix Ecosystem.
    bytes32 constant public REVENUE_SPLIT_CONTRACT      = keccak256("REVENUE_SPLIT_CONTRACT");

    /// Simplified implementation of SWIX tokenback. During MVP test will have rights to mint SWIX tokens.
    bytes32 constant public TOKENBACK_CONTRACT          = keccak256("TOKENBACK_CONTRACT");


    /* =====================================================
                              ROLES
     ===================================================== */
    /// All roles within Swix Ecosystem are tracked here

    /// Community Governance. This is the most powerful role and represents the voice of the community.
    bytes32 constant public GOVERNANCE_ROLE             = keccak256("GOVERNANCE_ROLE");

    /// Lease Manager. This role is responsible for deploying new Leases and adding them to a corresponding city.
    bytes32 constant public LEASE_MANAGER_ROLE          = keccak256("LEASE_MANAGER_ROLE");
    /// Lease Policy Counseal. This role is responsible for setting and adjusting rates related to Real World Business.
    bytes32 constant public LEASE_POLICY_ROLE           = keccak256("LEASE_POLICY_ROLE");

    /// Cost Manager. This role is responsible for adding global and city costs.
    bytes32 constant public COST_MANAGER_ROLE           = keccak256("COST_MANAGER_ROLE");

    /// Cancellation Policy Manager. This role is responsible for adding and removing cancellation policies.
    bytes32 constant public CANCEL_POLICY_MANAGER_ROLE  = keccak256("CANCEL_POLICY_MANAGER_ROLE");

    /// Contract Manager. This role is responsible for adding and removing contracts from Swix Ecosystem.
    bytes32 constant public CONTRACT_MANAGER_ROLE       = keccak256("CONTRACT_MANAGER_ROLE");

    /// DAO Reserves. This account will receive all profit going to DAO
    bytes32 constant public DAO_ROLE                    = keccak256("DAO_ROLE");

    /// Expense Wallet. This account will receive all funds going to Real World Business
    bytes32 constant public EXPENSE_WALLET_ROLE         = keccak256("EXPENSE_WALLET_ROLE");

    /// Booking Master. This account will be handling booking rejections
    bytes32 constant public BOOKING_MASTER_ROLE         = keccak256("BOOKING_MASTER_ROLE");

    /// Booking Master. This account will be funding booking rejections
    bytes32 constant public REFUND_WALLET_ROLE         = keccak256("REFUND_WALLET_ROLE");
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ISwixCity.sol";
interface IBooking {
    struct Booking {
        /// Contract of city in which the booking takes place
        ISwixCity city;
        /// Index of Lease in the chosen City
        uint256 leaseIndex;
        /// Start night number
        uint256 start;
        /// End night number
        uint256 end;
        /// Timestamp until which user will get full refund on cancellation
        uint256 fullRefundUntil;
        /// Timestamp until which user will get 50% refund on cancellation
        uint256 halfRefundUntil;
        /// Total price of booking
        uint256 bookingPrice;
        /// Percentage rate of tokenback, 100 = 1%
        uint256 tokenbackRate;
        /// User's address
        address user;
        /// Marker if funds were released from booking
        bool released;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseStructs.sol";

interface ISwixCity is ILeaseStructs {

    function getLease(uint256 leaseIndex) external view returns(Lease memory);
    function addLease( ILeaseAgreement leaseContract, uint256 target, uint256 tokenbackRate, bool[] calldata cancelPolicies) external;
    function updateAvailability( uint256 leaseIndex, uint256[] memory nights, bool available) external;
    function updateFinancials(uint256 leaseIndex, uint256 newCost, uint256 newProfit) external;
    function getPriceOfStay(uint256 leaseIndex, uint256[] memory nights) external view returns (uint256);
    function getFinancialParams(uint256 leaseIndex) external view returns ( uint256, uint256, uint256, uint256, uint256);

    /* =====================================================
                            EVENTS
    ===================================================== */

    event AddLease(address indexed leaseContract, uint256 indexed newLeaseIndex);
    event UpdateNights(address indexed leaseContract, uint256[] indexed nights, uint256[] indexed prices, bool[] availabilities);
    event UpdateCancelPolicy(uint256 indexed leaseIndex, uint256 cancelPolicy, bool allow);
    event UpdateAvailability(uint256 indexed leaseIndex, uint256[] indexed nights, bool indexed available);
    // TODO change to capital letter in the beginning
    event UpdatedPriceManager(address indexed newPriceManager);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

import "./ILeaseAgreement.sol";

interface ILeaseStructs {
    struct Lease {
        /// unique identifier for the Lease and it's contract address
        ILeaseAgreement leaseContract;
        /// Current tokenback rate given to guests on purchase
        uint256 tokenbackRate;
        /// Target profit for the Lease, adjusted by hurdleRate
        uint256 target;
        /// Profit earned on the Lease
        uint256 profit;
        /// Available cancellation policies for this lease
        bool[] cancelPolicies;
    }

    struct LeaseIndex {
        uint256 index;
        bool exists;
    }

    struct Night {
        /// Price of a night in US dollars
        uint256 price;
        /// Setting to 'true' will publish the night for booking and update availability
        bool available;
    }
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;

/// ERC1155 token representation of a booking; used to confirm at LeaseManager when burnt.
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface ILeaseAgreement is IERC1155 {
    function START_TIMESTAMP() external view returns (uint256);
    function swixCity() external view returns (address);
    function duration() external view returns (uint256);
    
    function initialize() external;

    event LeaveCity(address oldSwixCity);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
// PROTECTED INTERNATIONALLY BY PATENT LAW, PATENT PENDING

pragma solidity ^0.8.0;
interface IFinancialParams {
    struct FinancialParams {
        /// global operation cost to be collected before spliting profit to DAO
        uint256 globalCosts;
        /// cityCosts to be collected before spliting profit to DAO
        uint256 cityCosts;
        /// final rate for spliting profit once profit of a lease reaches target
        uint256 hurdleRate;
        /// current rate for spliting profit
        uint256 daoProfitRate;
        /// target profit for each lease
        uint256 target;
        /// accumulative profit for each lease
        uint256 profit;
    }
}