// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Blacklistable.sol";
import "./Mintable.sol";
import "./Burnable.sol";
import "./Pausable.sol";
import "./Presignable.sol";
import "./AccessControlUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ERC20Upgradeable.sol";

contract Token is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, Presignable, Burnable, Mintable, Blacklistable, Pausable {
    /// @notice Number of decimals
    uint8 _decimals;
    /// @notice Addresses of delegates
    mapping (address => bool) private _delegates;
    /// @notice Mapping of owner addresses to the allowances granted to delegates
    mapping (address => uint256) private _delegateAllowances;
    /// @notice Roles for delegate management
    bytes32 public constant DELEGATE_MANAGER_ROLE = keccak256("DELEGATE_MANAGER_ROLE");
    bytes32 public constant DELEGATE_MANAGER_ADMIN_ROLE = keccak256("DELEGATE_MANAGER_ADMIN_ROLE");

    /**
     * @dev Emitted when `delegate` is added as a delegate.
     */
    event DelegateAdded(address indexed delegate);

    /**
     * @dev Emitted when `delegate` is removed as a delegate.
     */
    event DelegateRemoved(address indexed delegate);

    /**
     * @dev Emitted when `value` allowance is granted by `owner` to delegates.
     */
    event DelegatedApproval(address indexed owner, uint256 value);

    /**
     * @dev Emitted when a delegate `delegate` transfers `value` tokens from
     * `owner` to `recipient.
     */
    event DelegatedTransfer(address indexed delegate, address indexed owner, address indexed recipient, uint256 value);


    function __GO_init_unchained(uint8 decimals_) internal initializer {
        _decimals = decimals_;
        _setRoleAdmin(DELEGATE_MANAGER_ROLE, DELEGATE_MANAGER_ADMIN_ROLE);
    }

    /**
     * @dev Initialises the token contract.
     */
    function initialize(string memory name_, string memory symbol_, uint8 decimals_) public initializer {
        __ERC20_init(name_, symbol_);
        __Ownable_init();
        __AccessControl_init_unchained();
        __Presignable_init_unchained(name_, "1");
        __Burnable_init_unchained();
        __Mintable_init_unchained();
        __Blacklistable_init_unchained();
        __Pausable_init_unchained();

        __GO_init_unchained(decimals_);

        _setupRole(BLACKLISTER_ADMIN_ROLE, _msgSender());
        _setupRole(BURNER_ADMIN_ROLE, _msgSender());
        _setupRole(DELEGATE_MANAGER_ADMIN_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Throws if the caller is not a delegate
     */
    modifier onlyDelegate() {
        require(isDelegate(_msgSender()), "caller is not delegate");
        _;
    }

    /**
     * @dev Add a delegate
     * @param delegate Address of new delegate.
     *
     * Emits an {DelegateAdded} with `delegate` set according to the supplied
     * argument.
     *
     * Requirements:
     *
     * - caller must have delegate manager role.
     */
    function addDelegate(address delegate) public onlyRole(DELEGATE_MANAGER_ROLE) {
        if (!_delegates[delegate]) {
            _delegates[delegate] = true;
            emit DelegateAdded(delegate);
        }
    }

    /**
     * @dev Grant allowance to delegates.
     * @param value Allowance to grant.
     *
     * Emits a {DelegatedApproval} event with `owner` set to the caller and
     * `value` set according to the supplied argument.
     *
     */
    function approveDelegate(uint256 value) public returns (bool) {
        _approveDelegate(_msgSender(), value);
        return true;
    }

    /**
     * @dev Returns the allowance that `owner` has granted to delegates.
     * @param owner Address of token owner.
     * @return Delegate allowance.
     */
    function delegateAllowance(address owner) public view returns (uint256) {
        return _delegateAllowances[owner];
    }

    /**
     * @dev Delegated transfer using the granted allowance.
     * @param owner Address of token owner.
     * @param recipient Address of recipient.
     * @param value Amount of tokens being sent.
     *
     * Emits an {DelegatedTransfer} event with `delegate` set to the caller, and
     * `owner`, `recipient`, and `value` set according to the supplied
     * arguments.
     *
     * Requirements:
     *
     * - caller must be a delegate.
     * - contract must not be paused.
     * - `owner` must not be blacklisted.
     * - caller must have sufficient allowance.
     */
    function delegatedTransferFrom(
        address owner,
        address recipient,
        uint256 value
    ) public notPaused onlyDelegate notBlacklisted(owner) returns (bool) {
        uint256 currentAllowance = _delegateAllowances[owner];
        require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");

        _transfer(owner, recipient, value);
        unchecked {
            _approveDelegate(owner, currentAllowance - value);
        }

        emit DelegatedTransfer(_msgSender(), owner, recipient, value);
        return true;
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must not be blacklisted.
     * - contract must not be paused.
     * - caller must have burner role.
     */
    function burn(uint256 value) public override notPaused notBlacklisted(_msgSender()) onlyRole(BURNER_ROLE) {
        super.burn(value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must have burner role.
     * - `account` must not be blacklisted.
     * - contract must not be paused.
     */
    function burnFrom(
        address account,
        uint256 value
    ) public override notPaused notBlacklisted(account) onlyRole(BURNER_ROLE) {
        super.burnFrom(account, value);
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
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Check if `delegate` is a delegate address
     * @param delegate Address to check for delegate status.
     * @return true if `delegate` is a delegate address.
     */
    function isDelegate(address delegate) public view returns (bool) {
        return _delegates[delegate];
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must have minter role.
     * - contract must not be paused.
     */
    function mint(address account, uint256 value) public override notPaused onlyRole(MINTER_ROLE) {
        super.mint(account, value);
    }

    /**
     * @dev Remove a delegate
     * @param delegate Address of delegate to remove.
     *
     * Emits an {DelegateRemoved} with `delegate` set according to the supplied
     * argument.
     *
     * Requirements:
     *
     * - caller must have delegate manager role.
     */
    function removeDelegate(address delegate) public onlyRole(DELEGATE_MANAGER_ROLE) {
        if (_delegates[delegate]) {
            _delegates[delegate] = false;
            emit DelegateRemoved(delegate);
        }
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - caller must not be blacklisted.
     * - contract must not be paused.
     */
    function transfer(
        address recipient,
        uint256 value
    ) public override notPaused notBlacklisted(_msgSender()) returns (bool) {
        return super.transfer(recipient, value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 value
    ) public override notPaused notBlacklisted(sender) returns (bool) {
        return super.transferFrom(sender, recipient, value);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        uint256 nonce,
        bytes memory signature
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, nonce, signature);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        bytes memory signature
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, signature);
    }

    /**
     * @dev Overriden to add modifiers
     *
     * Requirements:
     *
     * - `sender` must not be blacklisted.
     * - contract must not be paused.
     */
    function transferPresigned(
        address sender,
        address recipient,
        uint256 value,
        uint256 fee,
        address feeRecipient,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public override notPaused notBlacklisted(sender) {
        super.transferPresigned(sender, recipient, value, fee, feeRecipient, deadline, v, r, s);
    }

    /**
     * @dev Grant allowance to delegates.
     * @param owner Address of token owner.
     * @param value Allowance to grant.
     *
     * Emits a {DelegatedApproval} event with `owner` and `value` set according
     * to the supplied arguments.
     *
     * Requirements:
     *
     * - `owner` must not be the zero address.
     */
    function _approveDelegate(address owner, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        _delegateAllowances[owner] = value;
        emit DelegatedApproval(owner, value);
    }

}