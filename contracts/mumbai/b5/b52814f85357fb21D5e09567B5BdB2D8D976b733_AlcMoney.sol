// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/core/IStablesManager.sol";
import "../interfaces/core/IManager.sol";

/// @title AlcBox stablecoin
/// @author Cosmin Grigore (@gcosmintech)
/// @notice Based on MagicInternetMoney (MIM) implementation
contract AlcMoney is ERC20 {
    /// @notice token's symbol
    string private constant SYMBOL = "AMY";
    /// @notice token's name
    string private constant NAME = "AlcBox Money";
    /// @notice token's decimals
    uint8 private constant DECIMALS = 18;

    /// @notice Mint info property
    struct Minting {
        uint256 time;
        uint256 amount;
    }

    /// @notice storage for last minting info
    Minting public lastMint;

    /// @notice manager's address
    IManager public manager;

    address private _owner;
    uint256 private constant MINTING_PERIOD = 24 hours;
    uint256 private constant MINTING_INCREASE = 15000;
    uint256 private constant MINTING_PRECISION = 1e5;

    /// @notice creates the AlcMoney contract
    /// @param _manager manager's address
    constructor(address _manager) ERC20(NAME, SYMBOL) {
        require(_manager != address(0), "ERR: INVALID MANAGER");
        manager = IManager(_manager);
        _owner = msg.sender;
    }

    /// @notice mint tokens
    /// @dev no need to check if '_to' is a valid address if the '_mint' method is used
    /// @param _to address of the user receiving minted tokens
    /// @param _amount the amount to be minted
    function mint(address _to, uint256 _amount)
        external
        onlyOwnerOrStablesManager
        validAmount(_amount)
    {
        // Limits the amount minted per period to a convergence function, with the period duration restarting on every mint
        uint256 totalMintedAmount = 0;
        if (lastMint.time >= block.timestamp - MINTING_PERIOD) {
            totalMintedAmount = lastMint.amount;
            totalMintedAmount += _amount;
        }
        require(
            totalSupply() == 0 ||
                ((totalSupply() * MINTING_INCREASE) / MINTING_PRECISION) >=
                totalMintedAmount
        );

        lastMint.time = block.timestamp;
        lastMint.amount = totalMintedAmount;

        _mint(_to, _amount);
    }

    /// @notice burns token from sender
    /// @param _amount the amount of tokens to be burnt
    function burn(uint256 _amount) external validAmount(_amount) {
        _burn(msg.sender, _amount);
    }

    /// @notice burns token from an address
    /// @param _user the user to burn it from
    /// @param _amount the amount of tokens to be burnt
    function burnFrom(address _user, uint256 _amount)
        external
        validAmount(_amount)
        onlyOwnerOrStablesManager
    {
        _burn(_user, _amount);
    }

    modifier validAddress(address _val) {
        require(_val != address(0), "ERR: INVALID ADDRESS");
        _;
    }
    modifier validAmount(uint256 _val) {
        require(_val > 0, "ERR: INVALID AMOUNT");
        _;
    }
    modifier onlyOwnerOrStablesManager() {
        require(
            _owner == msg.sender || msg.sender == manager.stablesManager(),
            "ERR: UNAUTHORIZED"
        );
        _;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for stables manager
/// @author Cosmin Grigore (@gcosmintech)
/// @dev based on MIM implementation
interface IStablesManager {
    /// @notice event emitted when collateral was registered
    event AddedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when collateral was unregistered
    event RemovedCollateral(
        address indexed user,
        address indexed token,
        uint256 amount
    );
    /// @notice event emitted when a borrow action was performed
    event Borrowed(address indexed user, uint256 amount, uint256 part);
    /// @notice event emitted when a repay action was performed
    event Repayed(address indexed user, uint256 amount, uint256 part);

    /// @notice Returns amount to share transformation
    /// @param _token token for which the exchange is done
    /// @param _amount token's amount
    /// @param _roundUp if the resulted shares are rounded up
    /// @return _share obtained shares
    function toShare(
        IERC20 _token,
        uint256 _amount,
        bool _roundUp
    ) external view returns (uint256 _share);

    /// @dev Returns share to amount transformation
    /// @param _token token for which the exchange is done
    /// @param _share amount of shares
    /// @param _roundUp if the resulted amount is rounded up
    /// @return _amount obtained amount
    function toAmount(
        IERC20 _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256 _amount);

    /// @notice Returns true if user is solvent for the specified token
    /// @param _token the token for which the check is done
    /// @param _user the user address
    /// @param _collateral the amount of collateral the user has
    /// @param _collateralizationRate the collateralization rate for the specified token
    /// @return true/false
    function isUserSolvent(
        address _token,
        address _user,
        uint256 _collateral,
        uint256 _collateralizationRate
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Interface for a the manager contract
/// @author Cosmin Grigore (@gcosmintech)
interface IManager {
    /// @notice emitted when the dex manager is set
    event DexManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the strategy manager is set
    event StrategyManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the holding manager is set
    event HoldingManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the stablecoin manager is set
    event StablecoinManagerUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token address is changed
    event ProtocolTokenUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );

    /// @notice emitted when the protocol token reward for minting is updated
    event MintingTokenRewardUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the max amount of available holdings is updated
    event MaxAvailableHoldingsUpdated(
        uint256 indexed oldFee,
        uint256 indexed newFee
    );

    /// @notice emitted when the fee address is changed
    event FeeAddressUpdated(
        address indexed oldAddress,
        address indexed newAddress
    );
    /// @notice emitted when the default fee is updated
    event PerformanceFeeUpdated(uint256 indexed oldFee, uint256 indexed newFee);

    /// @notice emitted when a new contract is whitelisted
    event ContractWhitelisted(address indexed contractAddress);

    /// @notice emitted when a contract is removed from the whitelist
    event ContractBlacklisted(address indexed contractAddress);

    /// @notice emitted when a new token is whitelisted
    event TokenWhitelisted(address indexed token);

    /// @notice emitted when a new token is removed from the whitelist
    event TokenRemoved(address indexed token);

    /// @notice returns true/false for contracts' whitelist status
    function isContractWhitelisted(address _contract)
        external
        view
        returns (bool);

    /// @notice returns true/false for token's whitelist status
    function isTokenWhitelisted(address _token) external view returns (bool);

    /// @notice returns holding manager address
    function holdingManager() external view returns (address);

    /// @notice returns stablecoin manager address
    function stablesManager() external view returns (address);

    /// @notice returns the available strategy manager
    function strategyManager() external view returns (address);

    /// @notice returns the available dex manager
    function dexManager() external view returns (address);

    /// @notice returns the protocol token address
    function protocolToken() external view returns (address);

    /// @notice returns the default performance fee
    function performanceFee() external view returns (uint256);

    /// @notice returns the amount of protocol tokens
    ///         rewarded for pre-minting a holding contract
    function mintingTokenReward() external view returns (uint256);

    /// @notice returns the max amount of available holdings
    function maxAvailableHoldings() external view returns (uint256);

    /// @notice returns the fee address
    function feeAddress() external view returns (address);

    /// @notice updates the fee address
    /// @param _fee the new address
    function setFeeAddress(address _fee) external;

    /// @notice updates the strategy manager address
    /// @param _strategy strategy manager's address
    function setStrategyManager(address _strategy) external;

    /// @notice updates the dex manager address
    /// @param _dex dex manager's address
    function setDexManager(address _dex) external;

    /// @notice sets the holding manager address
    /// @param _holding strategy's address
    function setHoldingManager(address _holding) external;

    /// @notice sets the protocol token address
    /// @param _protocolToken protocol token address
    function setProtocolToken(address _protocolToken) external;

    /// @notice sets the stablecoin manager address
    /// @param _stables strategy's address
    function setStablecoinManager(address _stables) external;

    /// @notice sets the performance fee
    /// @param _fee fee amount
    function setPerformanceFee(uint256 _fee) external;

    /// @notice sets the protocol token reward for pre-minting holdings
    /// @param _amount protocol token amount
    function setMintingTokenReward(uint256 _amount) external;

    /// @notice sets the max amount of available holdings
    /// @param _amount max amount of available holdings
    function setMaxAvailableHoldings(uint256 _amount) external;

    /// @notice whitelists a contract
    /// @param _contract contract's address
    function whitelistContract(address _contract) external;

    /// @notice removes a contract from the whitelisted list
    /// @param _contract contract's address
    function blacklistContract(address _contract) external;

    /// @notice whitelists a token
    /// @param _token token's address
    function whitelistToken(address _token) external;

    /// @notice removes a token from whitelist
    /// @param _token token's address
    function removeToken(address _token) external;
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