// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Avalant.sol";
import "./AvalantItems.sol";

contract AntGold is Initializable, ERC20Upgradeable, AccessControlUpgradeable {
    // Suga, boss, avalant contracts addresses
    bytes32 public constant ANT_CONTRACTS_ROLE = keccak256("ANT_CONTRACTS_ROLE");

    address public AVALANT_CONTRACT;
    address public SUGA_CONTRACT;
    uint public BASE_ANTG_BY_ANT_PER_DAY;
    uint public BASE_ANTG_BY_ANT_PER_DAY_PER_STAGE;

    mapping(uint => bool) public antStaked;
    // ant staked from timestamp
    mapping(uint => uint) public antStakedFromTime;
    mapping(uint => uint) private antLastClaim;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    event Minted(address minter, uint antGold);

    // VERSION 1.1
    address public ITEMS_CONTRACT;

    function initialize(
        address _avalantContract,
        uint _baseAntgByAnt, // 7.5 so 7500000000000000000
        uint _baseAntgByAntByStage // 2.5 so 2500000000000000000
    ) initializer public {
        __ERC20_init("AntGold", "ANTG");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ANT_CONTRACTS_ROLE, _avalantContract);
        AVALANT_CONTRACT = _avalantContract;
        BASE_ANTG_BY_ANT_PER_DAY = _baseAntgByAnt;
        BASE_ANTG_BY_ANT_PER_DAY_PER_STAGE = _baseAntgByAntByStage;
    }

    function claimableView(uint256 tokenId) public view returns (uint) {
        Avalant a = Avalant(AVALANT_CONTRACT);
        (,,uint colonyStage,,) = a.allAvalants(tokenId);
        if (antStaked[tokenId] == false) {
            return 0;
        } else {
            AvalantItems i = AvalantItems(ITEMS_CONTRACT);
            // Calculator increase gain by 40%
            uint multiplyTotal = 10;
            if (i.doesAntHaveCalculator(tokenId)) {
                multiplyTotal = 14;
            }
            uint goldPerDay = ((BASE_ANTG_BY_ANT_PER_DAY_PER_STAGE * colonyStage) +
                BASE_ANTG_BY_ANT_PER_DAY) * multiplyTotal / 10;
            uint deltaSeconds = block.timestamp - antLastClaim[tokenId];
            // 10% additional if ant is staked for 10 days
            if (block.timestamp - antStakedFromTime[tokenId] >= 864000) {
                return goldPerDay * deltaSeconds / 86400 * 105 / 100;
            }
            return deltaSeconds * (goldPerDay / 86400);
        }
    }

    function myClaimableView() public view returns (uint) {
        Avalant a = Avalant(AVALANT_CONTRACT);
        uint ants = a.balanceOf(msg.sender);
        if (ants == 0) return 0;
        uint totalClaimable = 0;
        for (uint i = 0; i < ants; i++) {
            uint tokenId = a.tokenOfOwnerByIndex(msg.sender, i);
            totalClaimable += claimableView(tokenId);
        }
        return totalClaimable;
    }

    function claimAntGold(uint[] calldata tokenIds) external {
        Avalant a = Avalant(AVALANT_CONTRACT);
        uint totalNewAntg = 0;
        // if it fails its ok, empty array not authorized
        address ownerOfAnt = a.ownerOf(tokenIds[0]);
        for (uint i = 0; i < tokenIds.length; i++) {
            require(a.ownerOf(tokenIds[i]) == msg.sender || hasRole(ANT_CONTRACTS_ROLE, msg.sender), "Not ur ant");
            uint claimableAntGold = claimableView(tokenIds[i]);
            if (claimableAntGold > 0) {
                totalNewAntg += claimableAntGold;
                antLastClaim[tokenIds[i]] = uint(block.timestamp);
            }
        }
        if (totalNewAntg > 0) {
            _mint(ownerOfAnt, totalNewAntg);
            emit Minted(ownerOfAnt, totalNewAntg);
        }
    }

    function stakeAnt(uint tokenId) public {
        Avalant a = Avalant(AVALANT_CONTRACT);
        require(a.ownerOf(tokenId) == msg.sender, "Not ur ant");
        require(antStaked[tokenId] == false, "Already staked");
        antStaked[tokenId] = true;
        antStakedFromTime[tokenId] = block.timestamp;
        antLastClaim[tokenId] = block.timestamp;
    }

    function stakeAnts(uint[] calldata tokenIds) external {
        for (uint i = 0; i < tokenIds.length; i++) {
            stakeAnt(tokenIds[i]);
        }
    }

    function unstakeAntWithoutClaim(uint tokenId) external {
        Avalant a = Avalant(AVALANT_CONTRACT);
        address ownerOfAnt = a.ownerOf(tokenId);
        require(ownerOfAnt == msg.sender || hasRole(ANT_CONTRACTS_ROLE, msg.sender), "Not ur ant");

        antStaked[tokenId] = false;
    }

    function burn(address acc, uint amount) public onlyRole(ANT_CONTRACTS_ROLE) {
        _burn(acc, amount);
    }

    function mint(address to, uint amount) public {
        require(hasRole(ANT_CONTRACTS_ROLE, msg.sender) || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not authorized");
        _mint(to, amount);
    }

    // <AdminStuff>
    function setSugaAddress(address _sugaAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (SUGA_CONTRACT != address(0)) {
            _revokeRole(ANT_CONTRACTS_ROLE, SUGA_CONTRACT);
        }
        SUGA_CONTRACT = _sugaAddress;
        _grantRole(ANT_CONTRACTS_ROLE, _sugaAddress);
    }

    function airdrop(address[] calldata addresses, uint amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < addresses.length; i++) {
            _mint(addresses[i], amount);
        }
    }

    function setItemsContractAddress(address _itemsAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (ITEMS_CONTRACT != address(0)) {
            _revokeRole(ANT_CONTRACTS_ROLE, ITEMS_CONTRACT);
        }
        ITEMS_CONTRACT = _itemsAddress;
        _grantRole(ANT_CONTRACTS_ROLE, _itemsAddress);
    }
    // </AdminStuff>
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "./AntGold.sol";
import "./Suga.sol";
import "./AntBosses.sol";

interface AvalantBoxes {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Avalant is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address public AVALANT_BOXES_CONTRACT;
    address public ANTG_CONTRACT;
    address public SUGA_CONTRACT;
    address public BOSSES_CONTRACT;

    // Whitelist
    bytes32 private merkleRoot;
    mapping(address => uint) public boughtByWL;
    mapping(address => bool) public lateWhitelisted;
    uint public presaleRestrictedNumber;
    uint public quantityMintedByWLs;
    uint public constant MAX_SUPPLY_PRESALE = 2500;

    string public baseURI;
    address public royaltiesAddr;
    uint public royaltyFees;

    uint public constant MAX_SUPPLY = 10000;
    bool public openForPresale;
    bool public openForPublic;
    uint public mintFeeAmountWL;
    uint public mintFeeAmount;
    mapping(uint => bool) public alreadyOpenedBoxes;

    uint public feesToChangeName;

    struct Ant {
        uint tokenId;
        address pickedBy;
        uint colonyStage;
        string name;
        uint restUntil;
    }

    // map tokenId to Avalant struct
    mapping(uint => Ant) public allAvalants;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // --- EVENTS
    event OpenBox(uint boxId, uint numberOfAnts);
    event NameChange(uint antId, string name);
    event AntDug(uint antId, uint colonyStage);

    // VERSION 1.2
    // a => b, a is the antId, b is 0, 1, 2, 3, 4, 5 or 6
    // 5 is mythical, 4 is legendary, 3 is epic, 2 is rare, 1 is uncommon
    // 6 is unique
    mapping(uint => uint) public antRarity;

    // VERSION 1.3
    address public ITEMS_CONTRACT;

    function initialize(
        address _royaltiesAddr,
        address _avalantBoxesContractAddr,
        string memory _baseURIMetadata,
        bytes32 _merkleRoot,
        uint _presaleRestrictedNumber, // 5 at first 10 after an hour
        uint _royaltyFees // 5%
    ) public initializer {
        __ERC721_init("Avalant", "ANT");
        __ERC721Enumerable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        openForPresale = false;
        openForPublic = false;
        mintFeeAmountWL = 0.8 ether;
        mintFeeAmount = 1.2 ether;
        feesToChangeName = 500 ether; // 500 ANTG
        AVALANT_BOXES_CONTRACT = _avalantBoxesContractAddr;
        royaltiesAddr = _royaltiesAddr;
        baseURI = _baseURIMetadata;
        merkleRoot = _merkleRoot;
        presaleRestrictedNumber = _presaleRestrictedNumber;
        royaltyFees = _royaltyFees;
    }

    // <MintStuff>
    function isOpenBox(uint tokenId) public view returns (bool) {
        return alreadyOpenedBoxes[tokenId];
    }

    function openBox(uint boxTokenId) public {
        require(openForPresale == true || openForPublic == true, "Cannot open yet");
        AvalantBoxes ab = AvalantBoxes(AVALANT_BOXES_CONTRACT);
        address ownerOfBox = ab.ownerOf(boxTokenId);
        require(ownerOfBox == msg.sender, "Its not your box");
        require(alreadyOpenedBoxes[boxTokenId] != true, "Box already opened");
        alreadyOpenedBoxes[boxTokenId] = true;
        uint antToGive = 2;
        if (boxTokenId >= 900) antToGive = 3;
        if (boxTokenId < 600) antToGive = 1;
        require(totalSupply() + antToGive <= MAX_SUPPLY, "Ant escaped the box, sorry");
        for (uint i = 1; i <= antToGive; i++) {
            _mint(msg.sender);
        }
        emit OpenBox(boxTokenId, antToGive);
    }

    function _mint(address to) private {
        uint nextTokenId = totalSupply();
        Ant memory newAnt = Ant(nextTokenId, to, 1, string(abi.encodePacked("Ant #", StringsUpgradeable.toString(nextTokenId))), 0);
        allAvalants[nextTokenId] = newAnt;
        _safeMint(to, nextTokenId);
    }

    // <Whitelist Stuff>
    function _isWhitelist(address account, bytes32[] calldata proof) internal view returns(bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        if (MerkleProofUpgradeable.verify(proof, merkleRoot, leaf)) {
            return true;
        }
        if (lateWhitelisted[account] == true) {
            return true;
        }
        return false;
    }

    function isWhitelisted(address account, bytes32[] calldata proof) public view returns(bool) {
        return _isWhitelist(account, proof);
    }

    function pickAntsWhitelist(uint numberOfAnts, bytes32[] calldata proof) external payable {
        require(openForPresale == true, "Whitelist sale is not open");
        require(_isWhitelist(msg.sender, proof), "Not whitelisted");
        require(quantityMintedByWLs + numberOfAnts <= MAX_SUPPLY_PRESALE, "Presale supply is full");
        require(boughtByWL[msg.sender] + numberOfAnts <= presaleRestrictedNumber, "Too many ants");

        boughtByWL[msg.sender] += numberOfAnts;
        uint price = mintFeeAmountWL * numberOfAnts;
        require(msg.value >= price, "Not enough avax");

        for (uint i = 1; i <= numberOfAnts; i++) {
            quantityMintedByWLs += 1;
            _mint(msg.sender);
        }
        (bool sent,) = payable(royaltiesAddr).call{value: msg.value}("");
        require(sent, "Failed to pay royalties");
    }
    // </Whitelist Stuff>

    function pickAnts(uint numberOfAnts) external payable {
        require(openForPublic == true, "Sale is not open");
        require(numberOfAnts <= 10, "Trying to buy too many ants");
        require(totalSupply() + numberOfAnts <= MAX_SUPPLY, "Ants supply is full");

        uint price = mintFeeAmount * numberOfAnts;
        require(msg.value >= price, "Not enough avax");

        for (uint i = 1; i <= numberOfAnts; i++) {
            _mint(msg.sender);
        }
        (bool sent,) = payable(royaltiesAddr).call{value: msg.value}("");
        require(sent, "Failed to pay royalties");
    }
    // </MintStuff>

    function changeName(uint _tokenId, string memory newName) external {
        require(address(ANTG_CONTRACT) != address(0), "Change name not open yet");
        address ownerOfAnt = ownerOf(_tokenId);
        // backdoor to change name in case of racism or something
        require(ownerOfAnt == msg.sender || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not ur ant");
        AntGold ag = AntGold(ANTG_CONTRACT);
        uint256 available = ag.balanceOf(msg.sender);
        require(available >= feesToChangeName, "Not enough ANTG");
        ag.burn(msg.sender, feesToChangeName);
        allAvalants[_tokenId].name = newName;
        emit NameChange(_tokenId, newName);
    }

    function dig(uint _tokenId) public {
        require(ownerOf(_tokenId) == msg.sender, "Not ur ant");
        require(block.timestamp >= allAvalants[_tokenId].restUntil, "Ant is too tired to dig");
        AntBosses b = AntBosses(BOSSES_CONTRACT);
        require(b.isBossAliveAtStage(allAvalants[_tokenId].colonyStage) == false, "Blocked by boss");
        uint currentStage = allAvalants[_tokenId].colonyStage;
        AvalantItems i = AvalantItems(ITEMS_CONTRACT);
        // Armor reduce sugarToDig to 30%
        uint multiplyTotalSugarToDig = 10;
        if (i.doesAntHaveArmor(_tokenId)) {
            multiplyTotalSugarToDig = 7;
        }
        uint sugarToDig = (currentStage**2 * 20) * 1e17 * multiplyTotalSugarToDig;

        Suga s = Suga(SUGA_CONTRACT);
        // if not enough suga, it will fail inside
        s.burn(msg.sender, sugarToDig);
        AntGold ag = AntGold(ANTG_CONTRACT);
        uint[] memory tmp = new uint[](1);
        tmp[0] = _tokenId;
        ag.claimAntGold(tmp);
        allAvalants[_tokenId].colonyStage += 1;

        // Digging into stage 2 will require 2 hours of resting
        // Helmet reduce cooldown by 80%
        uint multiplyTotalCooldown = 10;
        if (i.doesAntHaveHelmet(_tokenId)) {
            multiplyTotalCooldown = 2;
        }
        allAvalants[_tokenId].restUntil = block.timestamp + 60*60*(currentStage + 1) * multiplyTotalCooldown / 10;
        emit AntDug(_tokenId, allAvalants[_tokenId].colonyStage);
    }

    function digMultipleAnts(uint[] calldata _tokenIds) public {
        for (uint i = 0; i < _tokenIds.length; i++) {
            dig(_tokenIds[i]);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenId), ".json"));
    }

    // <AdminStuff>
    function setMintPrice(uint _publicPrice, uint _wlPrice) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFeeAmount = _publicPrice;
        mintFeeAmountWL = _wlPrice;
    }

    function setPresaleRestrictedNumber(uint _presaleRestrictedNumber) public onlyRole(DEFAULT_ADMIN_ROLE) {
        presaleRestrictedNumber = _presaleRestrictedNumber;
    }

    function openPublic(bool _open) public onlyRole(DEFAULT_ADMIN_ROLE) {
        openForPublic = _open;
    }

    function openPresale(bool _open) public onlyRole(DEFAULT_ADMIN_ROLE) {
        openForPresale = _open;
    }

    function setBaseURI(string memory newURI) public onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newURI;
    }

    function setRoyaltyFees(uint _royaltyFees) public onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyFees = _royaltyFees;
    }

    function addLateWhitelist(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        lateWhitelisted[_account] = true;
    }

    function setContractAddresses(address _antGoldContract, address _sugaContract, address _bossesContract) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ANTG_CONTRACT = _antGoldContract;
        SUGA_CONTRACT = _sugaContract;
        BOSSES_CONTRACT = _bossesContract;
    }

    function updateMerkleRoot(bytes32 _merkleRoot) external onlyRole(DEFAULT_ADMIN_ROLE) {
        merkleRoot = _merkleRoot;
    }

    function changeRoyaltyAddress(address _royaltiesAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltiesAddr = _royaltiesAddress;
    }

    function changeFeeToChangeName(uint _feesToChangeName) external onlyRole(DEFAULT_ADMIN_ROLE) {
        feesToChangeName = _feesToChangeName;
    }

    function setAntsRarity(uint _rarity, uint[] calldata _antIds) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _antIds.length; i++) {
            antRarity[_antIds[i]] = _rarity;
        }
    }

    function setItemsContractAddress(address _itemsAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ITEMS_CONTRACT = _itemsAddress;
    }
    // </AdminStuff>

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesAddr, _salePrice * royaltyFees / 100);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        if (address(ANTG_CONTRACT) != address(0) && address(from) != address(0)) {
            AntGold ag = AntGold(ANTG_CONTRACT);
            ag.unstakeAntWithoutClaim(tokenId);
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "./AntGold.sol";
import "./Avalant.sol";

contract AvalantItems is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant ANT_CONTRACTS_ROLE = keccak256("ANT_CONTRACTS_ROLE");
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    // Avalant needed to allow de-equipping items on transfer
    address public AVALANT_CONTRACT;
    // ANTG contract for the mint
    address public ANTG_CONTRACT;

    string public baseURI;
    address public royaltiesAddr;
    uint public royaltyFees;
    bool public openForPublic;
    uint public mintFeeAmount;
    uint public cooldownToWithdraw;

    uint public MAX_SUPPLY_TOTAL;
    uint public constant MAX_SUPPLY_PER_ITEMS = 500;

    uint public constant HELMET = 1;
    uint public constant ARMOR = 2;
    uint public constant MANDIBLES = 3;
    uint public constant CALCULATOR = 4;

    // if item id 4 is an armor, it will be 4->2
    mapping(uint => uint) public idToItemType;

    // to withdraw item or to equip it again
    // this is shit.. fuck. useless variable but we
    // need to keep it because of upgradeables..
    mapping(address => uint) public ownerToItemId;

    // equipped items to ants
    mapping(uint => uint) public antIdToItemId;

    // ------------ Version 1.1 ------------
    // Used when unequiped but not yet withdrawn
    mapping(uint => address) public itemIdToOwner;

    mapping(uint => uint) public itemToCooldown;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    // --- EVENTS ---
    event ItemEquipped(uint itemId, uint antId);
    event ItemDeequipped(uint itemId, uint antId);
    event ItemWithdrew(uint itemId);

    function initialize(
        address _avalantContract,
        address _antGContract,
        address _royaltiesAddr,
        string memory _baseURI,
        uint _royaltyFees // 5%
    ) public initializer {
        __ERC721_init("Avalant Items", "ITEM");
        __ERC721Enumerable_init();
        __AccessControl_init();

        openForPublic = false;
        mintFeeAmount = 1500 ether;
        cooldownToWithdraw = 21600; // 6 hours in seconds
        MAX_SUPPLY_TOTAL = 2000;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ANT_CONTRACTS_ROLE, _avalantContract);

        AVALANT_CONTRACT = _avalantContract;
        ANTG_CONTRACT = _antGContract;
        royaltiesAddr = _royaltiesAddr;
        baseURI = _baseURI;
        royaltyFees = _royaltyFees;
    }

    // <GameStuff>
    function _antHasItemType(uint _antId, uint _itemType) internal view returns (bool) {
        uint itemId = antIdToItemId[_antId];
        if (itemId == 0) {
            return false;
        }
        return idToItemType[itemId] == _itemType;
    }
    function doesAntHaveArmor(uint _antId) public view returns (bool) {
        return _antHasItemType(_antId, ARMOR);
    }
    function doesAntHaveHelmet(uint _antId) public view returns (bool) {
        return _antHasItemType(_antId, HELMET);
    }
    function doesAntHaveMandibles(uint _antId) public view returns (bool) {
        return _antHasItemType(_antId, MANDIBLES);
    }
    function doesAntHaveCalculator(uint _antId) public view returns (bool) {
        return _antHasItemType(_antId, CALCULATOR);
    }

    function equipItem(uint _itemId, uint _antId) external {
        require(ownerOf(_itemId) == msg.sender || itemIdToOwner[_itemId] == msg.sender, "Must be your item");
        require(antIdToItemId[_antId] == 0, "Ant already has an item");
        Avalant a = Avalant(AVALANT_CONTRACT);
        require(a.ownerOf(_antId) == msg.sender, "Ant must be yours");

        // First equip
        if (ownerOf(_itemId) == msg.sender) {
            _beforeTokenTransfer(msg.sender, address(this), _itemId);
            _balances[msg.sender] -= 1;
            _balances[address(this)] += 1;
            _owners[_itemId] = address(this);
            itemIdToOwner[_itemId] = msg.sender;

            emit Transfer(msg.sender, address(this), _itemId);
        } else {
            require(itemToCooldown[_itemId] < block.timestamp, "In cooldown or already equiped");
        }
        antIdToItemId[_antId] = _itemId;
        itemToCooldown[_itemId] = 4110469179; // 2122

        if (idToItemType[_itemId] == CALCULATOR) {
            AntGold ag = AntGold(ANTG_CONTRACT);
            uint[] memory tmp = new uint[](1);
            tmp[0] = _antId;
            ag.claimAntGold(tmp);
        }

        emit ItemEquipped(_itemId, _antId);
    }

    function unequipItem(uint _itemId, uint _antId) external {
        require(itemIdToOwner[_itemId] == msg.sender, "Must be your item");
        Avalant a = Avalant(AVALANT_CONTRACT);
        require(a.ownerOf(_antId) == msg.sender && antIdToItemId[_antId] == _itemId, "Item must be equipped on the ant of owner");
        require(antIdToItemId[_antId] == _itemId, "Ant must have the item");

        itemToCooldown[_itemId] = block.timestamp + cooldownToWithdraw;
        antIdToItemId[_antId] = 0;

        emit ItemDeequipped(_itemId, _antId);
    }

    function withDrawItem(uint _itemId) external {
        require(itemIdToOwner[_itemId] == msg.sender, "Must be your item");
        require(itemToCooldown[_itemId] < block.timestamp, "In cooldown");

        _beforeTokenTransfer(address(this), msg.sender, _itemId);
        _balances[address(this)] -= 1;
        _balances[msg.sender] += 1;
        _owners[_itemId] = msg.sender;

        itemIdToOwner[_itemId] = address(0);
        emit Transfer(address(this), msg.sender, _itemId);
        emit ItemWithdrew(_itemId);
    }
    // </GameStuff>

    // <MintStuff>
    function mintItemRandom(uint quantity) external {
        require(totalSupply() + quantity <= MAX_SUPPLY_TOTAL, "Total supply exceeded");
        require(openForPublic, "Not open yet");
        require(quantity <= 10, "Too many items at once");

        AntGold ag = AntGold(ANTG_CONTRACT);
        // if not enough ANTG from the user, it will fail
        ag.burn(msg.sender, mintFeeAmount * quantity);

        for (uint i = 1; i <= quantity; i++) {
            uint newItemId = totalSupply() + 1;
            _safeMint(msg.sender, newItemId);
            ownerToItemId[msg.sender] = newItemId; // only useful for equipped items
        }
        setApprovalForAll(address(this), true);
    }
    // </MintStuff>

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        require(_exists(tokenId), "URI query for nonexistent token");
        uint _typeId = idToItemType[tokenId];
        return string(abi.encodePacked(baseURI, StringsUpgradeable.toString(tokenId), "?typeid=", StringsUpgradeable.toString(_typeId)));
    }

    // <AdminStuff>
    function setMintPrice(uint _price) external onlyRole(DEFAULT_ADMIN_ROLE) {
        mintFeeAmount = _price;
    }

    function openPublic(bool _open) external onlyRole(DEFAULT_ADMIN_ROLE) {
        openForPublic = _open;
    }

    function setBaseURI(string memory newURI) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = newURI;
    }

    function setRoyaltyFees(uint _royaltyFees) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltyFees = _royaltyFees;
    }

    function changeRoyaltyAddress(address _royaltiesAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        royaltiesAddr = _royaltiesAddress;
    }

    function setCooldownToWithdraw(uint _cooldown) external onlyRole(DEFAULT_ADMIN_ROLE) {
        cooldownToWithdraw = _cooldown;
    }

    function setItemType(uint _type, uint[] calldata _ids) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _ids.length; i++) {
            idToItemType[_ids[i]] = _type;
        }
    }

    function airdropItems(address[] calldata _receivers) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < _receivers.length; i++) {
            uint newItemId = totalSupply() + 1;
            _safeMint(_receivers[i], newItemId);
            ownerToItemId[_receivers[i]] = newItemId; // only useful for equipped items
        }
    }
    // </AdminStuff>

    // Called by Avalant Contract on transfer
    function unequippedAnt(uint _antId) external onlyRole(ANT_CONTRACTS_ROLE) {
        uint _itemId = antIdToItemId[_antId];
        if (_itemId != 0) {
            itemToCooldown[_itemId] = block.timestamp + cooldownToWithdraw;
            antIdToItemId[_antId] = 0;
            emit ItemDeequipped(_itemId, _antId);
        }
    }

    function royaltyInfo(uint256, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesAddr, _salePrice * royaltyFees / 100);
    }

    // The following function is an override required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;

    // Mapping owner address to token count
    mapping(address => uint256) public _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Avalant.sol";
import "./AntGold.sol";

contract Suga is Initializable, ERC20Upgradeable, AccessControlUpgradeable {
    bytes32 public constant ANT_CONTRACTS_ROLE = keccak256("ANT_CONTRACTS_ROLE");

    // Avalant needed to allow burning
    address public AVALANT_CONTRACT;
    // Antg needed to burn AntG
    address public ANTG_CONTRACT;
    // Bosses needed to allow burning Suga
    address public BOSSES_CONTRACT;

    uint public MAX_SUPPLY;
    uint public ANTG_RATIO;
    uint public ANTG_STAKE_DAY_RATIO;

    uint public totalAntgStaking;
    mapping(address => uint) public antgStaked;
    mapping(address => uint) private antgStakedFrom;

    // keeping them here so we can batch claim
    address[] public antgStakers;
    // index only useful for deleting user from array
    mapping(address => uint) private _stakerIndex;
    // same as Enumerable from openzeppelin

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    event AntGSwap(address swaper, uint antg);
    event UnstakedAntG(address staker, uint antg);
    event StakedAntG(address staker, uint antg);

    // Version 1.1
    mapping(address => bool) public whitelistTransfer;

    // Version 1.2
    // JLP Staking needed to allow for minting Suga
    address public JLP_STAKING_CONTRACT;

    function initialize(
        address _avalantContract,
        address _antGContract,
        address _bossesContract,
        uint _maxSupply, // 25_000_000_000 SUGA (**18)
        uint _antGRatio, // 18
        uint _antGStakeDayRatio // 2
    ) initializer public {
        __ERC20_init("Sugar", "SUGA");
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ANT_CONTRACTS_ROLE, _avalantContract);
        _grantRole(ANT_CONTRACTS_ROLE, _antGContract);
        _grantRole(ANT_CONTRACTS_ROLE, _bossesContract);
        AVALANT_CONTRACT = _avalantContract;
        ANTG_CONTRACT = _antGContract;
        BOSSES_CONTRACT = _bossesContract;
        MAX_SUPPLY = _maxSupply;
        ANTG_RATIO = _antGRatio;
        ANTG_STAKE_DAY_RATIO = _antGStakeDayRatio;
    }

    function _mintSuga(address account, uint256 amount) internal {
        require(totalSupply() + amount <= MAX_SUPPLY, "Max supply reached");
        _mint(account, amount);
    }

    function swapAntGForSuga(uint amount) external {
        require(amount > 0, "Amount must be greater than 0");
        AntGold ag = AntGold(ANTG_CONTRACT);
        ag.burn(msg.sender, amount);
        _mintSuga(msg.sender, amount * ANTG_RATIO);
        emit AntGSwap(msg.sender, amount);
    }

    function claimableView(address account) public view returns(uint) {
        uint _antgStaked = antgStaked[account];
        // need to multiply by 10000000000 to get decimal during days
        return
            ((_antgStaked * ANTG_STAKE_DAY_RATIO) *
                ((block.timestamp - antgStakedFrom[account]) * 10000000000) / 86400) /
            10000000000;
    }

    function claimSuga() public {
        uint claimable = claimableView(msg.sender);
        if (claimable > 0) {
            antgStakedFrom[msg.sender] = block.timestamp;
            _mintSuga(msg.sender, claimable);
        }
    }

    function stakeAntg(uint amount) external {
        require(amount > 0, "Amount must be greater than 0");
        AntGold ag = AntGold(ANTG_CONTRACT);
        // we burn AntG from wallet, minting again on unstake
        // if not enough AntG it will fail in the AntG contract burn
        ag.burn(msg.sender, amount);
        claimSuga(); // atleast try, no harm in claimable 0
        totalAntgStaking += amount;
        if (antgStaked[msg.sender] == 0) { // first staking of user
            antgStakers.push(msg.sender);
            _stakerIndex[msg.sender] = antgStakers.length - 1;
        }
        antgStaked[msg.sender] += amount;
        antgStakedFrom[msg.sender] = block.timestamp;
        emit StakedAntG(msg.sender, amount);
    }

    function unstakeAntg(uint amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(antgStaked[msg.sender] >= amount, "Not enough AntG staked");
        claimSuga();
        antgStaked[msg.sender] -= amount;
        if (antgStaked[msg.sender] == 0) {
            _removeStaker(msg.sender);
        }
        totalAntgStaking -= amount;
        uint antgToMint = (amount * 9) / 10; // losing 10% at unstake
        AntGold ag = AntGold(ANTG_CONTRACT);
        ag.mint(msg.sender, antgToMint);
        emit UnstakedAntG(msg.sender, antgToMint);
    }

    function getAmountOfStakers() public view returns(uint) {
        return antgStakers.length;
    }

    function _removeStaker(address staker) internal {
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/extensions/ERC721Enumerable.sol#L144
        uint stakerIndex = _stakerIndex[staker];
        uint lastStakerIndex = antgStakers.length - 1;
        address lastStaker = antgStakers[lastStakerIndex];
        antgStakers[stakerIndex] = lastStaker;
        _stakerIndex[lastStaker] = stakerIndex;
        delete _stakerIndex[staker];
        antgStakers.pop();
    }

    function burn(address acc, uint amount) public onlyRole(ANT_CONTRACTS_ROLE) {
        _burn(acc, amount);
    }

    function mint(address acc, uint amount) public onlyRole(ANT_CONTRACTS_ROLE) {
        _mintSuga(acc, amount);
    }

    // <AdminStuff>
    function updateRatios(uint _antGRatio, uint _antGStakeDayRatio) external onlyRole(DEFAULT_ADMIN_ROLE) {
        ANTG_RATIO = _antGRatio;
        ANTG_STAKE_DAY_RATIO = _antGStakeDayRatio;
    }

    function airdropSuga(address account, uint amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _mintSuga(account, amount);
    }

    function claimForPeople(uint256 from, uint256 to) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = from; i <= to; i++) {
            address account = antgStakers[i];
            uint claimable = claimableView(account);
            if (claimable > 0) {
                antgStakedFrom[account] = block.timestamp;
                _mintSuga(account, claimable);
            }
        }
    }

    function addWhitelistAddress(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        whitelistTransfer[account] = true;
    }

    function setFarmRole(address _jlpStakingContract) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (JLP_STAKING_CONTRACT != address(0)) {
            _revokeRole(ANT_CONTRACTS_ROLE, JLP_STAKING_CONTRACT);
        }
        JLP_STAKING_CONTRACT = _jlpStakingContract;
        _grantRole(ANT_CONTRACTS_ROLE, _jlpStakingContract);
    }
    // </AdminStuff>

    function transfer(address recipient, uint256 amount) public virtual override(ERC20Upgradeable) returns (bool) {
        // Preventing the SUGA trading until gen1
        require(whitelistTransfer[msg.sender] && whitelistTransfer[recipient], "No transfers allowed for the moment");
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override(ERC20Upgradeable) returns (bool) {
        // Preventing the SUGA trading until gen1
        require(whitelistTransfer[sender] && whitelistTransfer[recipient], "No transfers allowed for the moment");
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./Suga.sol";
import "./AvalantItems.sol";

contract AntBosses is Initializable, AccessControlUpgradeable {
    bytes32 public constant ANT_CONTRACTS_ROLE = keccak256("ANT_CONTRACTS_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    address public SUGA_CONTRACT;
    address public AVALANT_CONTRACT;

    struct Boss {
        uint id;
        uint totalLife;
        uint currentLife;
        uint colonyStage;
        string name;
        uint numberOfFighters; // easier to get than .length
    }

    uint public numberOfBosses;
    mapping(uint => Boss) public bosses;
    mapping(uint => uint[]) public stageToBosses;
    mapping(uint => uint[]) public bossFighters;
    mapping(uint => uint[]) public damagesGivenToBoss;
    mapping(uint => uint[3]) public bossMvps;
    mapping(uint => mapping(uint => uint)) public antIndexInBossDamages;
    mapping(uint => mapping(uint => bool)) public hasHitBoss;

    // <Events>
    event BossCreated(uint id, string name, uint colonyStage, uint totalLife);
    event BossHit(uint bossId, uint antId, uint damage);
    event BossDied(uint bossId);
    // </Events>

    // VERSION 1.1
    uint public damageRatio;

    // VERSION 1.2
    address public ITEMS_CONTRACT;

    function initialize(address _avalantContrat) initializer public {
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        AVALANT_CONTRACT = _avalantContrat;
    }

    function createBoss(uint _life, uint _colonyStage, string memory _name) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Boss storage boss = bosses[numberOfBosses];
        boss.id = numberOfBosses;
        boss.totalLife = _life;
        boss.currentLife = _life;
        boss.colonyStage = _colonyStage;
        boss.name = _name;
        bossMvps[numberOfBosses] = [10001, 10001, 10001];
        boss.numberOfFighters = 0;
        stageToBosses[boss.colonyStage].push(numberOfBosses);
        numberOfBosses += 1;
        emit BossCreated(boss.id, boss.name, boss.colonyStage, boss.totalLife);
    }

    // damageRatio is 10 for no change, 20 for double damage.
    function getRatio(uint _antId) public view returns (uint) {
        Avalant a = Avalant(AVALANT_CONTRACT);
        uint antRarity = a.antRarity(_antId);
        AvalantItems i = AvalantItems(ITEMS_CONTRACT);
        uint additionalDamage = 10;
        if (i.doesAntHaveMandibles(_antId)) {
            additionalDamage = 14;
        }
        uint8[7] memory rarityToRatio = [10, 11, 12, 13, 14, 15, 16];
        return damageRatio * rarityToRatio[antRarity] * additionalDamage / 10;
    }

    function _updateMvp(uint _bossId, uint _antId) internal {
        Boss storage boss = bosses[_bossId];
        if (boss.numberOfFighters == 1) {
            bossMvps[_bossId][0] = _antId;
            return;
        }
        uint bestAnt = bossMvps[_bossId][0];
        uint secondBestAnt = bossMvps[_bossId][1];
        uint thirdBestAnt = bossMvps[_bossId][2];

        if (bestAnt == _antId) {
            return;
        }

        if (damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][_antId]] > damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][bestAnt]]) {
            bossMvps[_bossId][0] = _antId;
            bossMvps[_bossId][1] = bestAnt;
            bossMvps[_bossId][2] = secondBestAnt == _antId ? thirdBestAnt : secondBestAnt;
        } else if (boss.numberOfFighters == 2 || damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][_antId]] > damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][secondBestAnt]]) {
            bossMvps[_bossId][1] = _antId;
            bossMvps[_bossId][2] = secondBestAnt;
        } else if (boss.numberOfFighters == 3 || damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][_antId]] > damagesGivenToBoss[_bossId][antIndexInBossDamages[_bossId][thirdBestAnt]]) {
            if (secondBestAnt == _antId) {
                return;
            }
            bossMvps[_bossId][2] = _antId;
        }
    }

    function hitBoss(uint _damage, uint _antId, uint _bossId) external {
        Boss storage boss = bosses[_bossId];
        Avalant a = Avalant(AVALANT_CONTRACT);
        (,,uint colonyStage,,) = a.allAvalants(_antId);
        require(colonyStage == boss.colonyStage, "Boss not in range of ant");
        require(boss.currentLife > 0, "Boss is already dead");
        require(a.ownerOf(_antId) == msg.sender, "Not your ant");
        Suga s = Suga(SUGA_CONTRACT);

        uint ratio = getRatio(_antId);
        uint trueDamage = _damage * ratio / 100;

        if (trueDamage < boss.currentLife) {
            boss.currentLife -= trueDamage;
            s.burn(msg.sender, _damage);
        } else {
            trueDamage = boss.currentLife;
            s.burn(msg.sender, boss.currentLife / ratio * 100);
            boss.currentLife = 0;
        }

        // first hit of this ant
        if (hasHitBoss[_bossId][_antId] == false) {
            antIndexInBossDamages[_bossId][_antId] = boss.numberOfFighters;
            damagesGivenToBoss[_bossId].push(trueDamage);
            bossFighters[_bossId].push(_antId);
            boss.numberOfFighters += 1;
            hasHitBoss[_bossId][_antId] = true;
        } else {
            // update damages
            uint index = antIndexInBossDamages[_bossId][_antId];
            damagesGivenToBoss[_bossId][index] += trueDamage;
        }
        _updateMvp(_bossId, _antId);
        emit BossHit(_bossId, _antId, trueDamage);
        if (boss.currentLife == 0) {
            emit BossDied(_bossId);
        }
    }

    function isBossAliveAtStage(uint _stage) public view returns (bool) {
        if (stageToBosses[_stage].length == 0) {
            return false;
        }
        bool res = false;
        for (uint i = 0; i < stageToBosses[_stage].length; i++) {
            if (bosses[stageToBosses[_stage][i]].currentLife > 0) {
                res = true;
            }
        }
        return res;
    }

    // <AdminStuff>
    function setContractAddress(address _sugaAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ANT_CONTRACTS_ROLE, _sugaAddress);

        SUGA_CONTRACT = _sugaAddress;
    }

    function setRatio(uint _ratio) external onlyRole(DEFAULT_ADMIN_ROLE) {
        damageRatio = _ratio;
    }

    function setItemsContractAddress(address _itemsAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        ITEMS_CONTRACT = _itemsAddress;
    }
    // </AdminStuff>
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}