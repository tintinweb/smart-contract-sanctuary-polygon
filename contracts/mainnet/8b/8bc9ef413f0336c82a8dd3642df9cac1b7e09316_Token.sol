/**
 *Submitted for verification at polygonscan.com on 2023-03-07
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/library/Constants.sol

// 
pragma solidity ^0.8.17;

library Constants {
    
    /**************************************** ROLES FOR LUCKY DRAW MARKET *******************************************/

    // keccak256("allow.to.list.nfts.official");
    bytes32 internal constant ALLOW_TO_LIST_NFTS_OFFICIAL = 0x1336eaab2c23a242761be4619bfe6e9fcacac0c8b6e2199089a7babfc6d725dd;

    // keccak256("allow.to.list.nfts.partners");
    bytes32 internal constant ALLOW_TO_LIST_NFTS_PARTNERS = 0x48f46bf24dccb183027a54b49b85c73eb9afb2e5bf5d206c4ca7a222f40e7edf;


    /**************************************** ROLES FOR TOKEN *******************************************************/

    // keccak256("minter.role")
    bytes32 internal constant MINTER_ROLE = 0xb7400b17e52d343f741138df9e91f7b1f847b285f261edc36ddf5d104892f80d;

    // keccak256("burner.role")
    bytes32 internal constant BURNER_ROLE = 0x67ddb8e48ce0d66032a44701598dde318e9e357db26bb3a846b15f87ffdb8369;

    
    /**************************************** ROLES FOR BLACKLIST ***************************************************/

    // keccak256("from.address.in.blacklist.role")
    bytes32 internal constant FROM_ADDRESS_IN_BLACKLIST_ROLE = 0x5b7ec5d4fcac2373c2ddbed4dc5e92feff2ade3f3efa955ae823c824a0e4a99f;

    // keccak256("to.address.in.blacklist.role")
    bytes32 internal constant TO_ADDRESS_IN_BLACKLIST_ROLE = 0xef12d2e5ca9b413ea49a3996230e8b34b4f6dff754d63ab1babcbd82cb2464b8;

    // keccak256("sender.address.in.blacklist.role")
    bytes32 internal constant SENDER_ADDRESS_IN_BLACKLIST_ROLE = 0x3f87c815cb3a14f86ebffe5a83e62ee634f84791d7e530d70ba6954bb4407aae;

    // keccak256("nftowner.in.luckydraw.blacklist.role")
    bytes32 internal constant NFTOWNER_IN_LUCKYDRAW_BLACKLIST_ROLE = 0x8dc1d3cd76d9e0ef9ea306e060cbb3a2ef49d1a176080b85ef1173ff02483de7;

    // keccak256("participant.in.luckydraw.blacklist.role")
    bytes32 internal constant PARTICIPANT_IN_LUCKYDRAW_BLACKLIST_ROLE = 0xbfc919c8c3e23c1c80f7eb08fd938f64af8be57ac0addfa0e12a075947159a5b;


    /**************************************** KEY NAMES FOR CONTRACT ADDRESSES *****************************************************/

    // keccak256("luckydraw.market.contract")
    bytes32 internal constant LUCKYDRAW_MARKET_CONTRACT = 0x4fc3012371a38258b501254c493b2f7d04db88f4ee0338a4d87ca610d656a92c;

    // keccak256("stake.pool.contract")
    bytes32 internal constant STAKE_POOL_CONTRACT = 0x3d7192433145bc05fece21357ccd7794fe2afd1b1a7706761d86379d62d24f8c;


    /**************************************** KEY NAMES FOR MISCELLANEOUS **********************************************************/

    // keccak256("allow.to.list.nfts.anyone");
    bytes32 internal constant ALLOW_TO_LIST_NFTS_ANYONE = 0x5c21a741e74b893b846a0f1f2e03979085deeabd1bd4df8c37d2cab5ae91b650;

    // keccak256("distribution.percentage.of.luckydraw")
    bytes32 internal constant DISTRIBUTION_PERCENTAGE_OF_LUCKYDRAW = 0xeacd6f3f002a53bb2efd3309c157f89496a07654c43dcdb08feef874aa8e0800;

    // keccak256("incremental.variable.miu1")
    bytes32 internal constant INCREMENTAL_VARIABLE_MIU1 = 0xc9e982787dcbb178d7563f964b9816392fe7a639afac09ddff564209a4e54c5d;

    // keccak256("incremental.variable.miu2")
    bytes32 internal constant INCREMENTAL_VARIABLE_MIU2 = 0x6c1af36f433ba51ec699ec89aa0c203a498c19afb1e95a3d274ef360ae543640;

    // keccak256("moving.average.value.of.data.points")
    bytes32 internal constant MOVING_AVERAGE_VALUE_OF_DATA_POINTS = 0x5d7959ee07f6df1bb016025c90bd6a592b687366b46f341605024c27cd774801;


    /**************************************** KEY NAMES FOR WALLET ADDRESSES *******************************************************/

    // keccak256("team.assets.wallet")
    bytes32 internal constant TEAM_ASSET_WALLET = 0xa0f664f53186acdbd2ffd3eedb7878439901f2689ca3ca69cd75837c98dd9617;

}


// File contracts/abstract/Pausable.sol

// 
pragma solidity ^0.8.17;

abstract contract Pausable {

    event Paused(address indexed account, bool paused);

    bool private _paused;

    constructor() {
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender, true);
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Paused(msg.sender, false);
    }

    uint256[50] _gaps;
}


// File base-contract/contracts/library/[email protected]

// 
pragma solidity >=0.8.0 <0.9.0;

library Registry {

  /***************************** ROLE NAME CONSTANT VARIABLES  ***********************************/

  // SUPER_ADMIN_ROLE
  bytes32 internal constant SUPER_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000000;

  // keccak256("ADMIN_ROLE");
  bytes32 internal constant ADMIN_ROLE = 0xa49807205ce4d355092ef5a8a18f56e8913cf4a201fbe287825b095693c21775;
}


// File base-contract/contracts/config/[email protected]

// 
pragma solidity >=0.8.0 <0.9.0;

interface IConfig {
  function version() external pure returns (uint256 v);

  function getRawValue(bytes32 key) external view returns(bytes32 typeID, bytes memory data);

  function hasRole(bytes32 role, address account) external view returns(bool has);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);
  
}


// File base-contract/contracts/library/[email protected]

// 
pragma solidity >=0.8.0 <0.9.0;

library ConfigUtils {

    // keccak256("address");
    bytes32 public constant ADDRESS_HASH = 0x421683f821a0574472445355be6d2b769119e8515f8376a1d7878523dfdecf7b;

    // keccak256("uint256");
    bytes32 public constant UINT256_HASH = 0xec13d6d12b88433319b64e1065a96ea19cd330ef6603f5f6fb685dde3959a320;

    // keccak256("bool");
    bytes32 public constant BOOL_HASH = 0xc1053bdab4a5cf55238b667c39826bbb11a58be126010e7db397c1b67c24271b;


    function _checkConfig(IConfig config) internal view {
        require(config.version() > 0 || config.supportsInterface(type(IConfig).interfaceId), "Config: not a valid config contract");
    }

    function _getAddress(IConfig config, bytes32 key) internal view returns (address) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        return _bytesToAddress(typeID, data);
    }

    function _bytesToAddress(bytes32 typeID, bytes memory data) internal pure returns (address addr) {
        require(typeID == ADDRESS_HASH, "Config: wrong address typeID");
        addr = abi.decode(data, (address));
    }
    
    function _getUint256(IConfig config, bytes32 key) internal view returns (uint256) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        return _bytesToUInt256(typeID, data);
    }

    function _bytesToUInt256(bytes32 typeID, bytes memory data) internal pure returns (uint256 value) {
        require(typeID == UINT256_HASH, "Config: wrong uint256 typeID");
        value = abi.decode(data, (uint256));
    }

    function _getBoolean(IConfig config, bytes32 key) internal view returns (bool value) {
        (bytes32 typeID, bytes memory data) = config.getRawValue(key);
        require(typeID == BOOL_HASH, "Config: wrong boolean typeID");
        value = abi.decode(data, (bool));
    }

}


// File @openzeppelin/contracts/utils/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}


// File base-contract/contracts/library/[email protected]

// 
pragma solidity >=0.8.0 <0.9.0;

library ProxyConfigUtils{
    using ConfigUtils for IConfig;
    
    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.config" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _CONFIG_SLOT = 0x54c601f62ced84cb3960726428d8409adc363a3fa5c7abf6dba0c198dcc43c14;

    function _getConfig() internal view returns(IConfig addr){
        address configAddr = StorageSlot.getAddressSlot(_CONFIG_SLOT).value;
        require(configAddr != address(0x0), "SC133: config not set");
        return IConfig(configAddr);
    }

    function _setConfig(IConfig config) internal{
        ConfigUtils._checkConfig(config);
        StorageSlot.getAddressSlot(_CONFIG_SLOT).value = address(config);
    }

    function _getAddress(bytes32 key) internal view returns(address){
        return _getConfig()._getAddress(key);
    }

    function _getUint256(bytes32 key) internal view returns(uint256){
        return _getConfig()._getUint256(key);
    }
    
    function _getBoolean(bytes32 key) internal view returns(bool){
        return _getConfig()._getBoolean(key);
    }

}


// File base-contract/contracts/abstract/[email protected]

// 
pragma solidity >=0.8.0 <0.9.0;


abstract contract DABase{
  function _initBase(IConfig config_) internal {
    ProxyConfigUtils._setConfig(config_);
  }

  function getConfig() public view returns(IConfig config){
    return ProxyConfigUtils._getConfig();
  }

  function hasRole(bytes32 role, address account) internal view returns(bool has){
    return ProxyConfigUtils._getConfig().hasRole(role, account);
  }

  function isAdmin(address account) internal view returns(bool has){
    return hasRole(Registry.ADMIN_ROLE, account);
  }
}


// File contracts/token/TokenBase.sol

// 
pragma solidity ^0.8.17;




contract TokenBase is DABase, Pausable {

    /// @notice This is only for the recognition of the contract owner on Opensea, Polygonscan.com and relative platforms.
    ///         The `owner` may never have the permission to change some stuff in the sub-contracts.
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyAdmin() {
        require(hasRole(Registry.ADMIN_ROLE, msg.sender), "ERC20: not the admin role");
        _;
    }

    modifier isMinter() {
        require(hasRole(Constants.MINTER_ROLE, msg.sender), "ERC20: not the minter role");
        _;
    }

    modifier isBurner() {
        require(hasRole(Constants.BURNER_ROLE, msg.sender), "ERC20: not the burner role");
        _;
    }

    modifier fromNotInBlacklist(address addr) {
        require(!hasRole(Constants.FROM_ADDRESS_IN_BLACKLIST_ROLE, addr) || hasRole(Registry.SUPER_ADMIN_ROLE, addr), "ERC20: the from address is blacklisted");
        _;
    }

    modifier toNotInBlacklist(address addr) {
        require(!hasRole(Constants.TO_ADDRESS_IN_BLACKLIST_ROLE, addr) || hasRole(Registry.SUPER_ADMIN_ROLE, addr), "ERC20: the to address is blacklisted");
        _;
    }

    modifier senderNotInBlacklist() {
        require(!hasRole(Constants.SENDER_ADDRESS_IN_BLACKLIST_ROLE, msg.sender) || hasRole(Registry.SUPER_ADMIN_ROLE, msg.sender), "ERC20: the sender address is blacklisted");
        _;
    }

    function setPaused(bool isPaused) external onlyAdmin {
        if (isPaused) {
            _pause();
        } else {
            _unpause();
        }
    }    

}


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
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


// File @openzeppelin/contracts/utils/[email protected]

// 
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

// 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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


// File contracts/token/Token.sol

// 
pragma solidity ^0.8.17;


contract Token is TokenBase, ERC20 {

    constructor(string memory name_, string memory symbol_, address config_) ERC20(name_, symbol_) {
        _initBase(IConfig(config_));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused senderNotInBlacklist() fromNotInBlacklist(from) toNotInBlacklist(to) {
        super._beforeTokenTransfer(from, to, amount);
    }

    function mint(address account, uint256 amount) external isMinter {
        super._mint(account, amount);
    }

    function burnRegularly(uint256 amount) external isBurner {
        super._burn(msg.sender, amount);
    }
    
    function burn(uint256 amount) external {
        super._burn(msg.sender, amount);
    }

}