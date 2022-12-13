// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./VaultFactory.sol";

/// @title Saffron Fixed Income Vault Factory (Restricted)
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice This factory restricts vault and adapter creation to the factory's owner
contract RestrictedVaultFactory is VaultFactory {
  /// @inheritdoc VaultFactory
  function createVault(uint256 _vaultType, address _adapter) public override onlyOwner {
    super.createVault(_vaultType, _adapter);
  }

  /// @inheritdoc VaultFactory
  function createAdapter(uint256 _adapterType, address _base, bytes calldata _data) public override onlyOwner {
    super.createAdapter(_adapterType, _base, _data);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IAdapter.sol";

/// @title Saffron Fixed Income Vault Factory
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Configure and deploy vault implementations; allow owner to add new vault and adapter types
contract VaultFactory is Ownable {
  /// @notice Incrementing vault ID
  uint256 public nextVaultId = 1;

  /// @notice Incrementing vault type ID
  uint256 public nextVaultTypeId = 1;

  /// @notice Incrementing adapter ID
  uint256 public nextDeployedAdapterId = 1;

  /// @notice Incrementing adapter type ID
  uint256 public nextAdapterTypeId = 1;

  /// @notice Protocol fee in basis points (one basis point = 1/100 of 1%)
  uint256 public feeBps;

  /// @notice Address that collects protocol fees
  address public feeReceiver;

  /// @notice Default deposit tolerance in basis points set on adapter
  uint256 public defaultDepositTolerance = 100;

  struct VaultInfo {
    address creatorAddress;
    address addr;
    address adapterAddress;
    uint256 vaultTypeId;
  }

  /// @notice Info about vault, mapped by vault ID
  mapping(uint256 => VaultInfo) public vaultInfo;

  /// @notice ID of vault, mapped by vault address
  mapping(address => uint256) public vaultAddrToId;

  /// @notice Vault bytecode, mapped by vault ID
  mapping(uint256 => bytes) public vaultTypeByteCode;

  struct AdapterInfo {
    uint256 adapterTypeId;
    address creatorAddress;
    address addr;
  }

  /// @notice Adapter info, mapped by adapter ID
  mapping(uint256 => AdapterInfo) public deployedAdapterInfo;

  /// @notice Adapter ID, mapped by Adapter address
  mapping(address => uint256) public deployedAdapterAddrToId;

  /// @notice Adapter bytecode, mapped by Adapter ID
  mapping(uint256 => bytes) public adapterTypeByteCode;

  /// @notice Emitted when a new vault is deployed
  /// @param vaultId ID of vault
  /// @param vaultTypeId ID of vault type
  /// @param adapter Address of adapter
  /// @param creator Address of vault creator
  /// @param vault Address of vault
  event VaultCreated(uint256 vaultId, uint256 indexed vaultTypeId, address adapter, address indexed creator, address indexed vault);

  /// @notice Emitted when a new vault is initialized
  /// @param srCapacity Maximum capacity of senior tranche
  /// @param jrCapacity Maximum capacity of junior tranche
  /// @param duration How long the vault will be locked once started, in seconds
  /// @param jrAsset Address of the junior base asset
  /// @param adapter Address of vault's corresponding adapter
  /// @param feeBps Protocol fee in basis points
  /// @param feeReceiver Address that collects protocol fee
  /// @param creator Address of vault creator
  /// @param vault Address of vault
  event VaultInitialized(
    uint256 duration,
    address adapter,
    uint256 srCapacity,
    uint256 jrCapacity,
    address jrAsset,
    uint256 feeBps,
    address feeReceiver,
    address indexed creator,
    address indexed vault
  );

  /// @notice Emitted when an adapter is deployed
  /// @param id ID of adapter
  /// @param adapterTypeId Type ID of adapter
  /// @param pool Address of adapter's Uniswap V3 pool
  /// @param creator Address of creator
  /// @param adapter Address of adapter
  event AdapterCreated(uint256 id, uint256 indexed adapterTypeId, address pool, address indexed creator, address indexed adapter);

  /// @notice Emitted when a new adapter type is added
  /// @param id ID of new adapter type
  /// @param creator Address of creator
  event AdapterTypeAdded(uint256 id, address indexed creator);

  /// @notice Emitted when a new vault type is added
  /// @param id ID of new vault type
  /// @param creator Address of creator
  event VaultTypeAdded(uint256 id, address indexed creator);

  /// @notice Emitted when an adapter type is revoked
  /// @param id ID of revoked adapter type
  /// @param revoker Address of revoker
  event AdapterTypeRevoked(uint256 id, address indexed revoker);

  /// @notice Emitted when a vault type is revoked
  /// @param id ID of revoked vault type
  /// @param revoker Address of revoker
  event VaultTypeRevoked(uint256 id, address indexed revoker);

  /// @notice Emitted when the fee is updated
  /// @param feeBps New fee basis points
  /// @param setter Address of setter
  event FeeBpsSet(uint256 feeBps, address indexed setter);

  /// @notice Emitted when the fee receiver is updated
  /// @param feeReceiver New fee receiver
  /// @param setter Address of setter
  event FeeReceiverSet(address feeReceiver, address indexed setter);

  /// @notice Emitted when the default deposit tolerance is updated
  /// @param defaultDepositTolerance New default deposit tolerance
  /// @param setter Address of setter
  event DefaultDepositToleranceSet(uint256 defaultDepositTolerance, address indexed setter);

  constructor() {
    feeReceiver = msg.sender;
  }

  /// @notice Deploys a new vault
  /// @param _vaultTypeId ID of vault type to use
  /// @param _adapterAddress Address of the adapter to use
  /// @dev Adapter must be created before calling this function
  function createVault(uint256 _vaultTypeId, address _adapterAddress) virtual public {
    // Get bytecode for the vault we want to deploy
    bytes memory bytecode = vaultTypeByteCode[_vaultTypeId];
    require(bytecode.length != 0, "BV");

    // Get adapter at address specified and make sure msg.sender is the same as adapter's deployer
    uint256 adapterId = deployedAdapterAddrToId[_adapterAddress];
    require(adapterId != 0, "AND");
    AdapterInfo memory _adapterInfo = deployedAdapterInfo[adapterId];
    require(_adapterInfo.creatorAddress == msg.sender, "AWC");

    // Deploy vault (Note: this does not run constructor)
    uint256 vaultId = nextVaultId++;
    address vaultAddress;
    assembly {
      vaultAddress := create(0, add(bytecode, 32), mload(bytecode))
    }

    // Store vault info
    VaultInfo memory _vaultInfo = VaultInfo({
      creatorAddress: msg.sender,
      addr: vaultAddress,
      adapterAddress: _adapterAddress,
      vaultTypeId: _vaultTypeId
    });
    vaultInfo[vaultId] = _vaultInfo;
    vaultAddrToId[vaultAddress] = vaultId;

    emit VaultCreated(vaultId, _vaultTypeId, _adapterAddress, msg.sender, vaultAddress);
  }

  /// @notice Initializes a vault
  /// @param vaultId Vault ID to initialize
  /// @param srCapacity Maximum capacity of senior tranche
  /// @param jrCapacity Maximum capacity of junior tranche
  /// @param duration How long the vault will be locked once started, in seconds
  /// @param jrAsset Address of the junior base asset
  function initializeVault(
    uint256 vaultId,
    uint256 srCapacity,
    uint256 jrCapacity,
    uint256 duration,
    address jrAsset
  ) public {
    // Get vault info for the vault we want to initialize and make sure msg.sender is the creator
    VaultInfo memory _vaultInfo = vaultInfo[vaultId];
    require(_vaultInfo.creatorAddress == msg.sender, "CMI");

    // Initialize vault and assign its corresponding adapter
    IVault(_vaultInfo.addr).initialize(vaultId, duration, _vaultInfo.adapterAddress, srCapacity, jrCapacity, jrAsset, feeBps, feeReceiver);
    IAdapter adapter = IAdapter(_vaultInfo.adapterAddress);
    adapter.setVault(_vaultInfo.addr);

    emit VaultInitialized(
      duration,
      _vaultInfo.adapterAddress,
      srCapacity,
      jrCapacity,
      jrAsset,
      feeBps,
      feeReceiver,
      msg.sender,
      _vaultInfo.addr
    );
  }

  /// @notice Adds a new vault bytecode, indexed by an auto-incremented vault type ID
  /// @param bytecode Bytecode of new vault type
  /// @return New vault type ID
  /// @dev Vault should satisfy IVault interface to be a valid vault
  function addVaultType(bytes calldata bytecode) external onlyOwner returns (uint256) {
    require(bytecode.length > 0, "NEI");
    uint256 vtId = nextVaultTypeId++;
    vaultTypeByteCode[vtId] = bytecode;
    emit VaultTypeAdded(vtId, msg.sender);
    return vtId;
  }

  /// @notice Removes a vault type, preventing new vault deployments from using this type
  /// @param id ID of vault type to revoke
  function revokeVaultType(uint256 id) external onlyOwner {
    require(id < nextVaultTypeId, "IVT");
    vaultTypeByteCode[id] = "";
    emit VaultTypeRevoked(id, msg.sender);
  }

  /// @notice Deploys a new Adapter
  /// @param adapterTypeId ID of adapter type to use
  /// @param poolAddress Pool address for the adapter
  /// @param data Data to pass to adapter initializer, implementation dependent
  function createAdapter(
    uint256 adapterTypeId,
    address poolAddress,
    bytes calldata data
  ) public virtual {
    require(defaultDepositTolerance > 0, "DDT");

    // Get bytecode for the adapter we want to deploy
    bytes memory bytecode = adapterTypeByteCode[adapterTypeId];
    require(bytecode.length != 0, "BA");

    // Deploy adapter (Note: this does not run constructor)
    address adapterAddress;
    assembly {
      adapterAddress := create(0, add(bytecode, 32), mload(bytecode))
    }

    // Initialize adapter
    uint256 adapterId = nextDeployedAdapterId++;
    IAdapter(adapterAddress).initialize(adapterId, poolAddress, defaultDepositTolerance, data);

    // Store adapter info
    AdapterInfo memory ai = AdapterInfo({creatorAddress: msg.sender, addr: adapterAddress, adapterTypeId: adapterTypeId});
    deployedAdapterInfo[adapterId] = ai;
    deployedAdapterAddrToId[adapterAddress] = adapterId;

    emit AdapterCreated(adapterId, adapterTypeId, poolAddress, msg.sender, adapterAddress);
  }

  /// @notice Adds a new adapter bytecode, indexed by an auto-incremented adapter type ID
  /// @param bytecode Bytecode of new adapter type
  /// @return New adapter type ID
  function addAdapterType(bytes calldata bytecode) external onlyOwner returns (uint256) {
    require(bytecode.length > 0, "NEI");
    uint256 atId = nextAdapterTypeId++;
    adapterTypeByteCode[atId] = bytecode;
    emit AdapterTypeAdded(atId, msg.sender);
    return atId;
  }

  /// @notice Removes an adapter type, preventing new vault deployments from using this type
  /// @param id ID of adapter type to revoke
  function revokeAdapterType(uint256 id) external onlyOwner {
    require(id < nextAdapterTypeId, "IAT");
    adapterTypeByteCode[id] = "";
    emit AdapterTypeRevoked(id, msg.sender);
  }

  /// @notice Check to see if a given vault or adapter address was deployed by this factory
  /// @return True if address matches a vault or adapter deployed by this factory
  function wasDeployedByFactory(address addr) external view returns (bool) {
    return vaultAddrToId[addr] != 0 || deployedAdapterAddrToId[addr] != 0;
  }

  /// @notice Set protocol fee basis points
  /// @param _feeBps New basis points value to set as protocol fee
  function setFeeBps(uint256 _feeBps) external onlyOwner {
    require(_feeBps < 10_000, "IBP");
    feeBps = _feeBps;
    emit FeeBpsSet(_feeBps, msg.sender);
  }

  /// @notice Set new address to collect protocol fees
  /// @param _feeReceiver New address to set as fee receiver
  function setFeeReceiver(address _feeReceiver) external onlyOwner {
    require(_feeReceiver != address(0x0), "IFR");
    feeReceiver = _feeReceiver;
    emit FeeReceiverSet(_feeReceiver, msg.sender);
  }

  /// @notice Set new default deposit tolerance to be configured on newly deployed adapters
  /// @param _defaultDepositTolerance New default deposit tolerance in basis points
  function setDefaultDepositTolerance(uint256 _defaultDepositTolerance) external onlyOwner {
    require(_defaultDepositTolerance != 0, "NEI");
    require(_defaultDepositTolerance <= 10000, "IBP");
    defaultDepositTolerance = _defaultDepositTolerance;
    emit DefaultDepositToleranceSet(_defaultDepositTolerance, msg.sender);
  }

  /// @notice Disable ownership renunciation
  function renounceOwnership() public override {}
}

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Saffron Fixed Income Vault Interface
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Base interface for vaults
/// @dev When implementing new vault types, extend the abstract contract Vault
interface IVault {
  /// @notice Capacity of the senior tranche
  /// @return Total capacity of the senior tranche
  function srCapacity() external view returns (uint256);

  /// @notice Vault initializer, runs upon vault creation
  /// @param _vaultId ID of the vault
  /// @param _duration How long the vault will be locked, once started, in seconds
  /// @param _adapter Address of the vault's corresponding adapter
  /// @param _srCapacity Maximum capacity of the senior tranche
  /// @param _jrCapacity Maximum capacity of the junior tranche
  /// @param _jrAsset Address of the junior base asset
  /// @param _feeBps Protocol fee in basis points
  /// @param _feeReceiver Address that collects the protocol fee
  /// @dev This is called by the parent factory's initializeVault function. Make sure that only the factory can call
  function initialize(
    uint256 _vaultId,
    uint256 _duration,
    address _adapter,
    uint256 _srCapacity,
    uint256 _jrCapacity,
    address _jrAsset,
    uint256 _feeBps,
    address _feeReceiver
  ) external;

  /// @notice Deposit assets into the vault
  /// @param amount Amount of asset to deposit
  /// @param tranche ID of tranche to deposit into
  /// @param data Data to pass, vault implementation dependent
  function deposit(
    uint256 amount,
    uint256 tranche,
    bytes calldata data
  ) external;

  /// @notice Withdraw assets out of the vault
  /// @param tranche ID of tranche to withdraw from
  /// @param data Data to pass, vault implementation dependent
  function withdraw(uint256 tranche, bytes calldata data) external;

  /// @notice Boolean indicating whether or not the vault has settled its earnings
  /// @return True if earnings are settled
  function earningsSettled() external view returns (bool);

  /// @notice Vault started state
  /// @return True if started
  function isStarted() external view returns (bool);
}

interface IUniV3Vault is IVault {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/// @title Saffron Fixed Income Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages funds deposited into vaults to generate yield
interface IAdapter {
  /// @notice Used to determine whether the asset balance that is returned from holdings() is representative of all the funds that this adapter maintains
  /// @return True if holdings() is all-inclusive
  function hasAccurateHoldings() external view returns (bool);

  /// @notice Sets the vault ID that this adapter maintains assets for
  /// @param _vault Address of vault
  /// @dev Make sure this is only callable by the vault factory
  function setVault(address _vault) external;

  /// @notice Initializes the adapter
  /// @param id ID of adapter
  /// @param pool Address of Uniswap V3 pool
  /// @param data Data to pass, adapter implementation dependent
  /// @dev Make sure this is only callable by the vault creator
  function initialize(
    uint256 id,
    address pool,
    uint256 depositTolerance,
    bytes calldata data
  ) external;
}

/// @title Saffron Fixed Income Uniswap V3 Adapter
/// @author psykeeper, supafreq, everywherebagel, maze, rx
/// @notice Manages a pair of assets deposited into Uniswap V3 vaults
interface IUniV3Adapter is IAdapter {
  /// @notice Deposit assets into Uniswap V3 position
  /// @param user Address of user depositing assets
  /// @param data Used for data required to mint a Uniswap V3 position
  /// @return amount0 Amount of token0 deployed
  /// @return amount1 Amount of token1 deployed
  /// @dev User should approve this adapter to spend the appropriate amounts before calling
  function deployCapital(address user, bytes calldata data) external returns (uint256 amount0, uint256 amount1);

  /// @notice Return assets back to user that have been withdrawn from Uniswap V3 position
  /// @param to User to receive assets
  /// @param amount0 Amount of token0 user will receive
  /// @param amount1 Amount of token1 user will receive
  /// @param tranche ID of tranche
  /// @dev Should only be callable by the vault, and should only be called during the withdraw process
  function returnCapital(
    address to,
    uint256 amount0,
    uint256 amount1,
    uint256 tranche
  ) external;

  /// @notice Return asset back to user before vault starts
  /// @param to User to receive assets
  /// @param tranche ID of tranche
  /// @dev This is needed because senior depositors are entitled to any earnings generated before the vault starts
  function earlyReturnCapital(
    address to,
    uint256 tranche,
    bytes calldata data
  ) external returns (uint256, uint256);

  /// @notice Expected holdings, estimated due to lack of guarantees
  /// @return estimate0 Estimated amount of token0 holdings
  /// @return estimate1 Estimated amount of token1 holdings
  /// @dev Do not depend on these values to be guaranteed! In cases where exact holdings can be known, simply return holdings()
  function estimatedHoldings() external view returns (uint256 estimate0, uint256 estimate1);

  /// @notice Exact holdings values
  /// @return amount0 Exact amount of token0 holdings
  /// @return amount1 Exact amount of token1 holdings
  /// @dev If guaranteed values cannot be determined, an error should be thrown
  function holdings() external view returns (uint256 amount0, uint256 amount1);

  /// @notice Contract addresses of token0 and token1
  /// @return token0 Address of token0
  /// @return token1 Address of token1
  function assetAddresses() external view returns (address token0, address token1);

  /// @notice Get current earnings for token0 and token1
  /// @return token0 earnings
  /// @return token1 earnings
  function getEarnings() external view returns (uint256, uint256);

  /// @notice Collect earnings from Uniswap V3 position and finalize earnings balance
  /// @return Total earnings of token0 to be distributed to vault participants
  /// @return Total earnings of token1 to be distributed to vault participants
  /// @dev Gets called during first vault interaction after endTime
  function settleEarnings() external returns (uint256, uint256);

  /// @notice Removes liquidity from Uniswap V3 position
  /// @param to Receiver of liquidity
  /// @param data Data passed to Uniswap V3 needed to remove liquidity
  function removeLiquidity(address to, bytes calldata data) external returns (uint256, uint256);
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