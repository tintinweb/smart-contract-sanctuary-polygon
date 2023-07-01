/**
 *Submitted for verification at polygonscan.com on 2023-06-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.18;

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

contract Governance {
    event GovernanceTransferred(
        address indexed previousGovernance,
        address indexed newGovernance
    );

    modifier onlyGovernance() {
        _checkGovernance();
        _;
    }

    function _checkGovernance() internal view virtual {
        require(governance == msg.sender, "!governance");
    }

    // Address that can set the defualt base fee and provider
    address public governance;

    constructor(address _governance) {
        governance = _governance;
    }

    /**
     * @notice Sets a new address as the governance of the contract.
     * @dev Throws if the caller is not current governance.
     * @param _newGovernance The new governance address.
     */
    function transferGovernance(
        address _newGovernance
    ) external onlyGovernance {
        require(_newGovernance != address(0), "ZERO ADDRESS");
        address oldGovernance = governance;
        governance = _newGovernance;

        emit GovernanceTransferred(oldGovernance, _newGovernance);
    }
}

interface IFactory {
    function api_version() external view returns (string memory);

    function vault_blueprint() external view returns (address);

    function deploy_new_vault(
        ERC20 asset,
        string calldata name,
        string calldata symbol,
        address roleManager,
        uint256 profitMaxUnlockTime
    ) external returns (address);
}


contract ReleaseRegistry is Governance {
    event NewRelease(
        uint256 indexed releaseId,
        address indexed factory,
        string apiVersion
    );

    // The total number of releases that have been deployed
    uint256 public numReleases;

    // Mapping of release id starting at 0 to the address
    // of the corresponding factory for that release.
    mapping(uint256 => address) public factories;

    // Mapping of the API version for a specific release to the
    // place in the order it was released.
    mapping(string => uint256) public releaseTargets;

    constructor(address _governance) Governance(_governance) {}

    /**
     * @notice Returns the latest factory.
     * @dev Throws if no releases are registered yet.
     * @return The address of the factory for the latest release.
     */
    function latestFactory() external view returns (address) {
        return factories[numReleases - 1];
    }

    /**
     * @notice Returns the api version of the latest release.
     * @dev Throws if no releases are registered yet.
     * @return The api version of the latest release.
     */
    function latestRelease() external view returns (string memory) {
        return IFactory(factories[numReleases - 1]).api_version(); // dev: no release
    }

    /**
     * @notice Issue a new release using a deployed factory.
     * @dev Stores the factory address in `factories` and the release
     * target in `releaseTargests` with its associated API version.
     *
     *   Throws if caller isn't `governance`.
     *   Throws if the api version is the same as the previous release.
     *   Emits a `NewRelease` event.
     *
     * @param _factory The factory that will be used create new vaults.
     */
    function newRelease(address _factory) external onlyGovernance {
        // Check if the release is different from the current one
        uint256 releaseId = numReleases;

        string memory apiVersion = IFactory(_factory).api_version();

        if (releaseId > 0) {
            // Make sure this isnt the same as the last one
            require(
                keccak256(
                    bytes(IFactory(factories[releaseId - 1]).api_version())
                ) != keccak256(bytes(apiVersion)),
                "ReleaseRegistry: same api version"
            );
        }

        // Update latest release.
        factories[releaseId] = _factory;

        // Set the api to the target.
        releaseTargets[apiVersion] = releaseId;

        // Increase our number of releases.
        numReleases = releaseId + 1;

        // Log the release for external listeners
        emit NewRelease(releaseId, _factory, apiVersion);
    }
}

interface IVault {
    function asset() external view returns (address);

    function api_version() external view returns (string memory);
}

interface IStrategy {
    function asset() external view returns (address);

    function apiVersion() external view returns (string memory);
}

contract Registry is Governance {
    event NewEndorsedVault(
        address indexed vault,
        address indexed asset,
        uint256 releaseVersion
    );

    event NewEndorsedStrategy(
        address indexed strategy,
        address indexed asset,
        uint256 releaseVersion
    );

    // Struct stored for every endorsed vault or strategy for
    // off chain use to easily retreive info.
    struct Info {
        // The token thats being used.
        address asset;
        // The release number corresponding to the release registries version.
        uint256 releaseVersion;
        // Time when the vault was deployed for easier indexing.
        uint256 deploymentTimeStamp;
        // String so that mangement to tag a vault with any info for FE's.
        string tag;
    }

    // Custom name for this Registry.
    string public name;

    // Address used to get the specific versions from.
    address public immutable releaseRegistry;

    // Array of all tokens used as the underlying.
    address[] public assets;

    // Mapping to check if a specific `asset` has a vault.
    mapping(address => bool) public assetIsUsed;

    // asset => array of all endorsed vaults.
    mapping(address => address[]) internal _endorsedVaults;

    // asset => array of all endorsed strategies.
    mapping(address => address[]) internal _endorsedStrategies;

    // asset => release number => array of endorsed vaults
    mapping(address => mapping(uint256 => address[]))
        internal _endorsedVaultsByVersion;

    // asset => release number => array of endorsed strategies
    mapping(address => mapping(uint256 => address[]))
        internal _endorsedStrategiesByVersion;

    // vault/strategy address => Info stuct.
    mapping(address => Info) public info;

    /**
     * @param _governance Address to set as owner of the Registry.
     * @param _name The custom string for this custom registry to be called.
     * @param _releaseRegistry The Permisionless releaseRegistry to deploy vaults through.
     */
    constructor(
        address _governance,
        string memory _name,
        address _releaseRegistry
    ) Governance(_governance) {
        // Set name.
        name = _name;
        // Set releaseRegistry.
        releaseRegistry = _releaseRegistry;
    }

    /**
     * @notice Returns the total numer of assets being used as the underlying.
     * @return The amount of assets.
     */
    function numAssets() external view returns (uint256) {
        return assets.length;
    }

    /**
     * @notice Get the full array of tokens being used.
     * @return The full array of underlying tokens being used/.
     */
    function getAssets() external view returns (address[] memory) {
        return assets;
    }

    /**
     * @notice The amount of endorsed vaults for a specific token.
     * @return The amount of endorsed vaults.
     */
    function numEndorsedVaults(address _asset) public view returns (uint256) {
        return _endorsedVaults[_asset].length;
    }

    /**
     * @notice The amount of endorsed strategies for a specific token.
     * @return The amount of endorsed strategies.
     */
    function numEndorsedStrategies(
        address _asset
    ) public view returns (uint256) {
        return _endorsedStrategies[_asset].length;
    }

    /**
     * @notice Get the array of vaults endorsed for an `_asset`.
     * @param _asset The underlying token used by the vaults.
     * @return The endorsed vaults.
     */
    function getEndorsedVaults(
        address _asset
    ) external view returns (address[] memory) {
        return _endorsedVaults[_asset];
    }

    /**
     * @notice Get the array of strategies endorsed for an `_asset`.
     * @param _asset The underlying token used by the strategies.
     * @return The endorsed strategies.
     */
    function getEndorsedStrategies(
        address _asset
    ) external view returns (address[] memory) {
        return _endorsedStrategies[_asset];
    }

    /**
     * @notice Get the number of endorsed vaults for an asset of a specific API version.
     * @return The amount of endorsed vaults.
     */
    function numEndorsedVaultsByVersion(
        address _asset,
        uint256 _versionDelta
    ) public view returns (uint256) {
        uint256 version = ReleaseRegistry(releaseRegistry).numReleases() -
            1 -
            _versionDelta;
        return _endorsedVaultsByVersion[_asset][version].length;
    }

    /**
     * @notice Get the number of endorsed strategies for an asset of a specific API version.
     * @return The amount of endorsed strategies.
     */
    function numEndorsedStrategiesByVersion(
        address _asset,
        uint256 _versionDelta
    ) public view returns (uint256) {
        uint256 version = ReleaseRegistry(releaseRegistry).numReleases() -
            1 -
            _versionDelta;
        return _endorsedStrategiesByVersion[_asset][version].length;
    }

    /**
     * @notice Get the array of vaults endorsed for an `_asset` of a specific API.
     * @param _asset The underlying token used by the vaults.
     * @param _versionDelta The difference from the most recent API version.
     * @return The endorsed vaults.
     */
    function getEndorsedVaultsByVersion(
        address _asset,
        uint256 _versionDelta
    ) public view returns (address[] memory) {
        uint256 version = ReleaseRegistry(releaseRegistry).numReleases() -
            1 -
            _versionDelta;
        return _endorsedVaultsByVersion[_asset][version];
    }

    /**
     * @notice Get the array of strategies endorsed for an `_asset` of a specific API.
     * @param _asset The underlying token used by the strategies.
     * @param _versionDelta The difference from the most recent API version.
     * @return The endorsed strategies.
     */
    function getEndorsedStrategiesByVersion(
        address _asset,
        uint256 _versionDelta
    ) public view returns (address[] memory) {
        uint256 version = ReleaseRegistry(releaseRegistry).numReleases() -
            1 -
            _versionDelta;
        return _endorsedStrategiesByVersion[_asset][version];
    }

    /**
     * @notice Get all endorsed vaults deployed using the Registry.
     * @dev This will return a nested array of all vaults deployed
     * seperated by their underlying asset.
     *
     * This is only meant for off chain viewing and should not be used during any
     * on chain tx's.
     *
     * @return allEndorsedVaults A nested array containing all vaults.
     */
    function getAllEndorsedVaults()
        external
        view
        returns (address[][] memory allEndorsedVaults)
    {
        address[] memory allAssets = assets;
        uint256 length = assets.length;

        allEndorsedVaults = new address[][](length);
        for (uint256 i; i < length; ++i) {
            allEndorsedVaults[i] = _endorsedVaults[allAssets[i]];
        }
    }

    /**
     * @notice Get all strategies endorsed through this registry.
     * @dev This will return a nested array of all endorsed strategies
     * seperated by their underlying asset.
     *
     * This is only meant for off chain viewing and should not be used during any
     * on chain tx's.
     *
     * @return allEndorsedStrategies A nested array containing all strategies.
     */
    function getAllEndorsedStrategies()
        external
        view
        returns (address[][] memory allEndorsedStrategies)
    {
        address[] memory allAssets = assets;
        uint256 length = assets.length;

        allEndorsedStrategies = new address[][](length);
        for (uint256 i; i < length; ++i) {
            allEndorsedStrategies[i] = _endorsedStrategies[allAssets[i]];
        }
    }

    /**
     * @notice
     *    Create a new vault for the given asset using a given release in the
     *     release registry.
     * @dev
     *   Throws if caller isn't `owner`.
     *   Throws if no releases are registered yet.
     *   Emits a `NewEndorsedVault` event.
     * @param _asset The asset that may be deposited into the new Vault.
     * @param _name Specify a custom Vault name. .
     * @param _symbol Specify a custom Vault symbol name.
     * @param _roleManager The address authorized for guardian interactions in the new Vault.
     * @param _profitMaxUnlockTime The time strategy profits will unlock over.
     * @param _releaseDelta The number of releases prior to the latest to use as a target. NOTE: Set to 0 for latest.
     * @return _vault address of the newly-deployed vault
     */
    function newEndorsedVault(
        address _asset,
        string memory _name,
        string memory _symbol,
        address _roleManager,
        uint256 _profitMaxUnlockTime,
        uint256 _releaseDelta
    ) public onlyGovernance returns (address _vault) {
        // Get the target release based on the delta given.
        uint256 _releaseTarget = ReleaseRegistry(releaseRegistry)
            .numReleases() -
            1 -
            _releaseDelta;

        // Get the factory address for that specific Api version.
        address factory = ReleaseRegistry(releaseRegistry).factories(
            _releaseTarget
        );

        // Make sure we got an actual factory
        require(factory != address(0), "Registry: unknown release");

        // Deploy New vault.
        _vault = IFactory(factory).deploy_new_vault(
            ERC20(_asset),
            _name,
            _symbol,
            _roleManager,
            _profitMaxUnlockTime
        );

        // Register the vault with this Registry
        _registerVault(_vault, _asset, _releaseTarget, block.timestamp);
    }

    /**
     * @notice
     *    Adds an existing vault to the list of "endorsed" vaults for that asset.
     * @dev
     *    Throws if caller isn't `owner`.
     *    Throws if no releases are registered yet.
     *    Throws if `vault`'s api version does not match the release specified.
     *    Emits a `NewEndorsedVault` event.
     * @param _vault The vault that will be endorsed by the Registry.
     * @param _releaseDelta Specify the number of releases prior to the latest to use as a target.
     * @param _deploymentTimestamp The timestamp of when the vault was deployed for FE use.
     */
    function endorseVault(
        address _vault,
        uint256 _releaseDelta,
        uint256 _deploymentTimestamp
    ) public onlyGovernance {
        // Will underflow if no releases created yet, or targeting prior to release history
        uint256 releaseTarget = ReleaseRegistry(releaseRegistry).numReleases() -
            1 -
            _releaseDelta; // dev: no releases

        // Get the API version for the target specified
        string memory apiVersion = IFactory(
            ReleaseRegistry(releaseRegistry).factories(releaseTarget)
        ).api_version();

        require(
            keccak256(bytes(IVault(_vault).api_version())) ==
                keccak256(bytes((apiVersion))),
            "Wrong API Version"
        );

        // Add to the end of the list of vaults for asset
        _registerVault(
            _vault,
            IVault(_vault).asset(),
            releaseTarget,
            _deploymentTimestamp
        );
    }

    /**
     * @notice Endorse an already deployed vault.
     * @dev To be used with default values for `_releaseDelta` and
     * `_deploymentTimestamp`.
     *
     * @param _vault Address of the vault to endorse.
     */
    function endorseVault(address _vault) external {
        endorseVault(_vault, 0, 0);
    }

    function _registerVault(
        address _vault,
        address _asset,
        uint256 _releaseTarget,
        uint256 _deploymentTimestamp
    ) internal {
        // Add to the endorsed vaults arrays.
        _endorsedVaults[_asset].push(_vault);
        _endorsedVaultsByVersion[_asset][_releaseTarget].push(_vault);

        // Set the Info struct for this vault
        info[_vault] = Info({
            asset: _asset,
            releaseVersion: _releaseTarget,
            deploymentTimeStamp: _deploymentTimestamp,
            tag: ""
        });

        if (!assetIsUsed[_asset]) {
            // We have a new asset to add
            assets.push(_asset);
            assetIsUsed[_asset] = true;
        }

        emit NewEndorsedVault(_vault, _asset, _releaseTarget);
    }

    /**
     * @notice
     *    Adds an existing strategy to the list of "endorsed" strategies for that asset.
     * @dev
     *    Throws if caller isn't `owner`.
     *    Throws if no releases are registered yet.
     *    Throws if `strategies`'s api version does not match the release specified.
     *    Emits a `NewEndorsedStrategy` event.
     * @param _strategy The strategy that will be endorsed by the Registry.
     * @param _releaseDelta Specify the number of releases prior to the latest to use as a target.
     * @param _deploymentTimestamp The timestamp of when the strategy was deployed for FE use.
     */
    function endorseStrategy(
        address _strategy,
        uint256 _releaseDelta,
        uint256 _deploymentTimestamp
    ) public onlyGovernance {
        // Will underflow if no releases created yet, or targeting prior to release history
        uint256 _releaseTarget = ReleaseRegistry(releaseRegistry)
            .numReleases() -
            1 -
            _releaseDelta; // dev: no releases

        // Get the API version for this release
        string memory apiVersion = IFactory(
            ReleaseRegistry(releaseRegistry).factories(_releaseTarget)
        ).api_version();

        // Make sure the API versions match
        require(
            keccak256(bytes((IStrategy(_strategy).apiVersion()))) ==
                keccak256(bytes((apiVersion))),
            "Wrong API Version"
        );

        address _asset = IStrategy(_strategy).asset();

        _endorsedStrategies[_asset].push(_strategy);
        _endorsedStrategiesByVersion[_asset][_releaseTarget].push(_strategy);

        info[_strategy] = Info({
            asset: _asset,
            releaseVersion: _releaseTarget,
            deploymentTimeStamp: _deploymentTimestamp,
            tag: ""
        });

        if (!assetIsUsed[_asset]) {
            // We have a new asset to add
            assets.push(_asset);
            assetIsUsed[_asset] = true;
        }

        emit NewEndorsedStrategy(_strategy, _asset, _releaseTarget);
    }

    /**
     * @notice Endorse an already deployed strategy.
     * @dev To be used with default values for `_releaseDelta` and
     * `_deploymentTimestamp`.
     *
     * @param _strategy Address of the strategy to endorse.
     */
    function endorseStrategy(address _strategy) external {
        endorseStrategy(_strategy, 0, 0);
    }

    /**
     * @notice Tag a vault with a specific string.
     * @dev This is available to governance to tag any vault or strategy
     * on chain if desired to arbitrarily classify any vaults.
     *   i.e. Certain credit ratings ("AAA") / Vault status ("Shutdown") etc.
     *
     * @param _vault Address of the vault or strategy to tag.
     * @param _tag The string to tag the vault or strategy with.
     */
    function tagVault(
        address _vault,
        string memory _tag
    ) external onlyGovernance {
        require(info[_vault].asset != address(0), "!Endorsed");
        info[_vault].tag = _tag;
    }
}


contract RegistryFactory {
    event NewRegistry(
        address indexed newRegistry,
        address indexed governance,
        string name
    );

    address public immutable releaseRegistry;

    constructor(address _releaseRegistry) {
        releaseRegistry = _releaseRegistry;
    }

    function name() external pure returns (string memory) {
        return "Custom Vault Registry Factory";
    }

    function createNewRegistry(string memory _name) external returns (address) {
        return createNewRegistry(msg.sender, _name);
    }

    function createNewRegistry(
        address _governance,
        string memory _name
    ) public returns (address) {
        Registry newRegistry = new Registry(
            _governance,
            _name,
            releaseRegistry
        );

        emit NewRegistry(address(newRegistry), _governance, _name);
        return address(newRegistry);
    }
}